"""Opt-in real-model smoke test: python smoke_inference.py (requires espeak-ng).

Uses one CC BY 4.0 Google FLEURS Portuguese recording and synthetic English.
--synthetic also synthesizes Portuguese (language detection may be unreliable).
"""
import hashlib
from pathlib import Path
import subprocess
import tempfile
import sys
import tarfile
import urllib.request
from video_subtitles import VideoSubtitles
from subtitles_rules import SubtitleError


def run(*args):
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


def main():
    worker = VideoSubtitles()
    with tempfile.TemporaryDirectory() as folder:
        root = Path(folder)
        for source, text in [
            ("pt", "Olá, este é um vídeo de teste. Hoje vamos aprender a criar legendas automáticas. "
             "O vídeo original deve ficar sempre igual. Muito obrigado pela atenção."),
            ("en", "Hello, this is a test video. Today we will learn how to create automatic subtitles. "
             "The original video must always stay unchanged. Thank you for listening."),
        ]:
            wav, video = root / f"{source}.wav", root / f"{source}.mp4"
            if source == "pt" and "--synthetic" not in sys.argv:
                # Google FLEURS, CC BY 4.0: https://huggingface.co/datasets/google/fleurs
                # Stream just the first recording, not the full archive.
                url = "https://storage.googleapis.com/xtreme_translations/FLEURS/pt_br.tar.gz"
                with urllib.request.urlopen(url) as response, tarfile.open(fileobj=response, mode="r|gz") as archive:
                    for member in archive:
                        if member.isfile() and member.name.endswith(".wav"):
                            wav.write_bytes(archive.extractfile(member).read())
                            print(f"FLEURS Portuguese fixture: {member.name}", flush=True)
                            break
            else:
                run("espeak-ng", "-v", source, "-s", "140", "-w", str(wav), text)
            run("ffmpeg", "-y", "-f", "lavfi", "-i", "color=c=black:s=320x240:r=10",
                "-i", str(wav), "-shortest", "-c:v", "libx264", "-c:a", "aac", str(video))
            before = hashlib.sha256(video.read_bytes()).hexdigest()
            for requested in ("original", "en"):
                output = root / f"{source}-{requested}.vtt"
                response = worker.process({"procedure": "video_subtitles", "parameters": {
                    "inputImageURI": str(video), "outputImageURI": str(output),
                    "videoId": "test", "language": requested,
                }})
                assert response["metadata"]["detectedLanguage"] == source, response
                contents = output.read_text()
                assert contents.startswith("WEBVTT\n\n") and " --> " in contents
                if source == "en" or "--synthetic" in sys.argv:
                    assert "legenda" in contents.lower() if source == "pt" and requested == "original" else "subtitle" in contents.lower()
                assert hashlib.sha256(video.read_bytes()).hexdigest() == before
                print(f"PASS real model {source} -> {requested}: {contents[:180]!r}", flush=True)
        for name, code, args in [
            ("silent", 2303, []),
            ("tone", 2304, ["-f", "lavfi", "-i", "sine=frequency=440:duration=3", "-c:a", "aac"]),
        ]:
            video, output = root / f"{name}.mp4", root / f"{name}.vtt"
            run("ffmpeg", "-y", "-f", "lavfi", "-i", "color=c=black:s=320x240:r=10:d=3",
                *args, "-c:v", "libx264", str(video))
            try:
                worker.process({"procedure": "video_subtitles", "parameters": {
                    "inputImageURI": str(video), "outputImageURI": str(output),
                    "videoId": "test", "language": "original",
                }})
                raise AssertionError("Expected subtitle error")
            except SubtitleError as error:
                assert error.code == code, error
                assert not output.exists()
                print(f"PASS real audio {name}: {code}", flush=True)


if __name__ == "__main__":
    main()
