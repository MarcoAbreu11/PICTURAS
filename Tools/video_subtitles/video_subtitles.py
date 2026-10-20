"""One model per process; durable E4 messages with heartbeat during inference."""
import concurrent.futures
import datetime
import json
import os
from pathlib import Path
import re
import time
import uuid

from subtitles_rules import SubtitleError, validate, webvtt, atomic_write
from utils.video import probe


class VideoSubtitles:
    def __init__(self, model=None, decode=None, speech=None, probe_video=probe):
        if model is None:
            from faster_whisper import WhisperModel
            from faster_whisper.audio import decode_audio
            from faster_whisper.vad import get_speech_timestamps
            model = WhisperModel("small", device="cpu", compute_type="int8")
            decode, speech = decode_audio, get_speech_timestamps
        self.model, self.decode, self.speech, self.probe = model, decode, speech, probe_video

    def process(self, request):
        params = validate(request)
        output = Path(params["outputImageURI"])
        try:
            if not self.probe(params["inputImageURI"]).get("audio_codec"):
                raise SubtitleError(2303)
            audio = self.decode(params["inputImageURI"], sampling_rate=16000)
            # Check before language detection: empty VAD input must not acquire a language.
            if not self.speech(audio):
                raise SubtitleError(2304)
            segments, info = self.model.transcribe(
                audio,
                task="translate" if params["language"] == "en" else "transcribe",
                language=params.get("detectedLanguage") or None,
                vad_filter=True, multilingual=False,
            )
            content = webvtt(list(segments))  # generator errors belong to this job
            detected = params.get("detectedLanguage") or info.language
            if not re.fullmatch(r"[a-z]{2,3}", detected or ""):
                raise SubtitleError(2301)
            atomic_write(output, content)
            return {
                "type": "text", "imageURI": str(output),
                "metadata": {
                    "videoId": params["videoId"], "requestedLanguage": params["language"],
                    "detectedLanguage": detected,
                    "trackLanguage": "en" if params["language"] == "en" else detected,
                },
            }
        except Exception as exc:
            output.with_suffix(output.suffix + ".part").unlink(missing_ok=True)
            output.unlink(missing_ok=True)
            if isinstance(exc, SubtitleError):
                raise
            raise SubtitleError(2301) from exc


def run():
    # Linux shared-volume advisory lock + receipt: a redelivery never starts a
    # second inference, even if the first connection was lost while still running.
    import fcntl
    import pika
    worker = VideoSubtitles()
    root = Path("/app/images/subtitles")
    receipts = root / "receipts"
    receipts.mkdir(parents=True, exist_ok=True)
    executor = concurrent.futures.ThreadPoolExecutor(max_workers=1)

    def execute(request):
        job = request.get("messageId", "")
        params = request.get("parameters", {})
        if not re.fullmatch(r"subtitles-[0-9a-f-]{36}", job):
            raise ValueError("Invalid subtitle job identity")
        video = params.get("videoId", "")
        if not re.fullmatch(r"[0-9a-f]{24}", video):
            raise ValueError("Invalid video identity")
        expected = root / "jobs" / job
        if (Path(params.get("inputImageURI", "")).resolve() != expected / "source"
                or Path(params.get("outputImageURI", "")).resolve() != expected / "subtitles.vtt"):
            raise ValueError("Invalid subtitle job paths")
        with (receipts / f"{video}.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            receipt = receipts / f"{job}.json"
            if receipt.exists():
                return json.loads(receipt.read_text(encoding="utf-8"))
            result = {
                "messageId": str(uuid.uuid4()), "correlationId": job,
                "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            try:
                result.update(status="success", output=worker.process(request))
            except SubtitleError as exc:
                result.update(status="error", error={"code": exc.code, "message": str(exc)})
            atomic_write(receipt, json.dumps(result, ensure_ascii=False))
            return result

    while True:
        connection = None
        try:
            connection = pika.BlockingConnection(pika.ConnectionParameters(
                host=os.environ.get("RABBITMQ_HOST", "rabbitmq"),
                port=int(os.environ.get("RABBITMQ_PORT", "5672")),
                credentials=pika.PlainCredentials(os.environ.get("RABBITMQ_USER", "user"),
                                                  os.environ.get("RABBITMQ_PASS", "password")),
                heartbeat=60, blocked_connection_timeout=300,
            ))
            channel = connection.channel()
            channel.exchange_declare(exchange="picturas", exchange_type="direct", durable=True)
            for queue in ("video_subtitles_queue", "video_subtitles_results_queue"):
                channel.queue_declare(queue=queue, durable=True)
                channel.queue_bind(exchange="picturas", queue=queue, routing_key=queue)
            channel.confirm_delivery()
            channel.basic_qos(prefetch_count=1)

            def callback(ch, method, properties, body):
                future = executor.submit(execute, json.loads(body))
                while not future.done():
                    connection.process_data_events(time_limit=1)
                try:
                    result = future.result()
                except ValueError as exc:
                    print(f"Rejected invalid subtitle message: {exc}", flush=True)
                    ch.basic_reject(method.delivery_tag, requeue=False)
                    return
                ch.basic_publish(exchange="picturas", routing_key="video_subtitles_results_queue",
                                 body=json.dumps(result), mandatory=True,
                                 properties=pika.BasicProperties(delivery_mode=2, content_type="application/json"))
                ch.basic_ack(method.delivery_tag)

            channel.basic_consume(queue="video_subtitles_queue", on_message_callback=callback, auto_ack=False)
            channel.start_consuming()
        except Exception as exc:
            print(f"Subtitle transport reconnect: {exc}", flush=True)
            if connection and connection.is_open:
                connection.close()
            time.sleep(5)


if __name__ == "__main__":
    run()
