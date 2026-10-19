import datetime
import json
import os
import shutil
import tempfile

import pytz

from convert_rules import (
    MAX_DURATION_DRIFT_SECONDS, validate_params, validate_source, target_height,
    encode_args, sample_starts, extrapolate, output_path,
)
from utils.tool_msg import ToolMSG
from utils.video import probe, run_ffmpeg, ProbeError, FFmpegError, ProgressThrottle
import utils.env as env


class ConversionError(Exception):
    def __init__(self, message, code=2101):
        super().__init__(message)
        self.code = code


def read_video(path):
    try:
        return probe(path)
    except ProbeError:
        raise ConversionError("The video is corrupted or cannot be read", 2102)


class VideoConvert:
    def __init__(self):
        self.tool_msg = ToolMSG(
            "picturas-video-convert-tool-ms", "video_convert",
            env.RABBITMQ_HOST, env.RABBITMQ_PORT,
            env.RABBITMQ_USERNAME, env.RABBITMQ_PASSWORD,
        )
        self.counter = 0

    @staticmethod
    def now(started):
        now = datetime.datetime.now(pytz.utc)
        return now.isoformat(), (now - started).total_seconds() * 1000

    def encode(self, cmd, duration, on_progress=None):
        try:
            run_ffmpeg(cmd, duration, on_progress=on_progress, on_line=self.tool_msg.keep_alive)
        except FFmpegError as error:
            print(f"[video_convert] ffmpeg failed: {error.stderr}", flush=True)
            raise ConversionError(
                "The video could not be converted. It may be corrupted; the original was kept unchanged.", 2101
            )

    def validate(self, params, source):
        """Valida o pedido e o vídeo; devolve (tamanho, detalhes, altura de saída)."""
        reason = validate_params(params)
        if reason:
            raise ConversionError(reason, 2102)
        if not os.path.isfile(source):
            raise ConversionError("The source video is missing", 2102)
        size_bytes = os.path.getsize(source)
        details = read_video(source)
        reason = validate_source(size_bytes, details)
        if reason:
            raise ConversionError(reason, 2102)
        height, reason = target_height(params.get("resolution", "original"), details["height"],
                                       params.get("userType", "free"))
        if reason:
            raise ConversionError(reason, 2102)
        return size_bytes, details, height

    def estimate(self, params, source):
        """Passo 3: codifica amostras com as opções escolhidas e extrapola o tamanho (A4)."""
        size_bytes, details, height = self.validate(params, source)
        starts, length = sample_starts(details["duration"])
        workdir = tempfile.mkdtemp(prefix="picturas-estimate-")
        try:
            sample_bytes, measured = 0, 0.0
            for i, start in enumerate(starts):
                out = os.path.join(workdir, f"sample-{i}.{params['format']}")
                self.encode(encode_args(source, out, params["format"], params["quality"], height,
                                        details["height"], start=start, length=length), length)
                sample_bytes += os.path.getsize(out)
                measured += min(length, details["duration"] - start)
            return {
                "originalSizeBytes": size_bytes,
                "estimatedSizeBytes": extrapolate(sample_bytes, measured, details["duration"]),
                "duration": details["duration"],
                "width": details["width"],
                "height": details["height"],
            }
        finally:
            shutil.rmtree(workdir, ignore_errors=True)

    def callback(self, ch, method, properties, body):
        info = json.loads(body.decode())
        request_id = info["messageId"]
        started = datetime.datetime.fromisoformat(info["timestamp"])
        if started.tzinfo is None:
            started = started.replace(tzinfo=datetime.timezone.utc)
        params = info.get("parameters", {})
        source = params.get("inputImageURI", "")
        requested_output = params.get("outputImageURI", "")
        response_id = f"video_convert-{self.counter}-{request_id}"
        self.counter += 1
        preview = request_id.startswith("preview")
        generated = None

        def send_error(code, message):
            ts, elapsed = self.now(started)
            self.tool_msg.send_msg(
                request_id, response_id, ts, "error", elapsed, None,
                err_code=code, err_msg=message, og_img_uri=source,
            )

        def send_progress(pct):
            ts, _ = self.now(started)
            self.tool_msg.send_progress(request_id, response_id, ts, pct)

        if info.get("procedure") != "video_convert":
            send_error(2100, "The procedure received does not fit into this tool")
            return

        try:
            # estimativa do tamanho: pedido curto, sem ficheiro de saída nem progresso
            if params.get("mode") == "estimate":
                estimate = self.estimate(params, source)
                ts, elapsed = self.now(started)
                self.tool_msg.send_msg(request_id, response_id, ts, "success", elapsed, None,
                                       type="estimate", result_metadata=estimate)
                return

            progress = ProgressThrottle(send_progress)
            # o trabalho saiu da fila: o frontend passa de "em fila" para "em curso"
            progress(0, force=True)

            size_bytes, details, height = self.validate(params, source)
            duration = min(details["duration"], 3.0) if preview else details["duration"]
            generated = output_path(requested_output or source, params["format"])
            os.makedirs(os.path.dirname(generated), exist_ok=True)

            self.encode(encode_args(source, generated, params["format"], params["quality"], height,
                                    details["height"], length=duration if preview else None),
                        duration, on_progress=progress)
            if not os.path.isfile(generated) or os.path.getsize(generated) == 0:
                raise ConversionError("The conversion produced an empty file", 2101)
            output_bytes = os.path.getsize(generated)
            result = read_video(generated)
            # RN6 / REQ-VID-CONV-023: mesma duração (±1 s) e áudio mantido
            if not preview:
                if abs(result["duration"] - details["duration"]) > MAX_DURATION_DRIFT_SECONDS:
                    raise ConversionError("The converted video does not keep the original duration", 2101)
                if details["audio_codec"] and not result["audio_codec"]:
                    raise ConversionError("The converted video lost the original audio", 2101)
            if output_bytes > size_bytes and not params.get("allow_larger", False):
                raise ConversionError(
                    "The converted file is larger than the original. Enable confirmation to keep larger results.", 2102
                )

            ts, elapsed = self.now(started)
            self.tool_msg.send_msg(
                request_id, response_id, ts, "success", elapsed, generated,
                type="video",
                result_metadata={
                    "originalSizeBytes": size_bytes,
                    "outputSizeBytes": output_bytes,
                    "duration": result["duration"],
                    "width": result["width"],
                    "height": result["height"],
                    "videoCodec": result["video_codec"],
                    "audioCodec": result["audio_codec"],
                },
            )
        except Exception as error:
            if generated:
                try:
                    os.remove(generated)
                except OSError:
                    pass
            if isinstance(error, ConversionError):
                send_error(error.code, str(error))
            else:
                send_error(2101, f"Conversion failed: {error}")
        finally:
            self.tool_msg.keep_alive()


def main():
    tool = VideoConvert()
    tool.tool_msg.read_msg(tool.callback)


if __name__ == "__main__":
    main()
