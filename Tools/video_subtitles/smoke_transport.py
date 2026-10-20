"""Opt-in RabbitMQ/worker test, on an isolated broker and shared test volume."""
import json
import os
from pathlib import Path
import subprocess
import time
import uuid
import pika


def main():
    connection = pika.BlockingConnection(pika.ConnectionParameters(
        host=os.environ.get("RABBITMQ_HOST", "rabbitmq"),
        credentials=pika.PlainCredentials("user", "password"),
    ))
    channel = connection.channel()
    channel.exchange_declare(exchange="picturas", exchange_type="direct", durable=True)
    for queue in ("video_subtitles_queue", "video_subtitles_results_queue"):
        channel.queue_declare(queue=queue, durable=True)
        channel.queue_bind(exchange="picturas", queue=queue, routing_key=queue)
    channel.confirm_delivery()
    job = "subtitles-" + str(uuid.uuid4())
    directory = Path("/app/images/subtitles/jobs") / job
    directory.mkdir(parents=True)
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i",
                    "color=c=black:s=160x90:r=10:d=1", "-c:v", "libx264",
                    "-f", "mp4", str(directory / "source")], check=True)
    request = {
        "messageId": job, "procedure": "video_subtitles",
        "parameters": {"inputImageURI": str(directory / "source"),
                       "outputImageURI": str(directory / "subtitles.vtt"),
                       "videoId": "111111111111111111111111", "language": "original"},
    }

    def publish():
        channel.basic_publish(exchange="picturas", routing_key="video_subtitles_queue",
                              body=json.dumps(request), mandatory=True,
                              properties=pika.BasicProperties(delivery_mode=2))

    def receive():
        deadline = time.monotonic() + 180
        while time.monotonic() < deadline:
            method, props, body = channel.basic_get("video_subtitles_results_queue", auto_ack=False)
            if method:
                response = json.loads(body)
                channel.basic_ack(method.delivery_tag)
                if response["correlationId"] == job:
                    return response
            connection.sleep(0.2)
        raise TimeoutError("No subtitle worker response")

    publish()
    first = receive()
    assert first["status"] == "error" and first["error"]["code"] == 2303, first
    publish()
    second = receive()
    assert first == second, "Redelivery must reuse the worker receipt"
    assert not (directory / "subtitles.vtt").exists()
    print("PASS real RabbitMQ + worker: 2303; durable response; duplicate reuses identical receipt.", flush=True)
    connection.close()


if __name__ == "__main__":
    main()
