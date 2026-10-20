"""UC-VID-001: request validation and atomic WebVTT publication (no encoding)."""
import html
import math
import os
from pathlib import Path

MESSAGES = {
    2300: "Procedimento de legendas inválido",
    2301: "Não foi possível gerar as legendas. Tente novamente",
    2302: "Escolha Original ou English",
    2303: "O vídeo não tem faixa de áudio",
    2304: "Não foi possível detetar fala para gerar legendas",
}


class SubtitleError(Exception):
    def __init__(self, code):
        self.code = code
        super().__init__(MESSAGES[code])


def validate(request):
    if request.get("procedure") != "video_subtitles":
        raise SubtitleError(2300)
    params = request.get("parameters", {})
    allowed = {"inputImageURI", "outputImageURI", "language", "detectedLanguage", "videoId"}
    if (params.get("language") not in ("original", "en")
            or set(params) - allowed
            or not params.get("inputImageURI") or not params.get("outputImageURI")):
        raise SubtitleError(2302)
    return params


def timestamp(ms):
    hours, rest = divmod(ms, 3600000)
    minutes, rest = divmod(rest, 60000)
    seconds, millis = divmod(rest, 1000)
    return f"{hours:02}:{minutes:02}:{seconds:02}.{millis:03}"


def webvtt(segments):
    blocks = []
    previous = 0
    for segment in segments:
        text = " ".join(segment.text.replace("\x00", "").split())
        if not text:
            continue
        if not all(math.isfinite(t) for t in (segment.start, segment.end)):
            raise SubtitleError(2301)
        start, end = round(segment.start * 1000), round(segment.end * 1000)
        if start < 0 or end <= start or start < previous:
            raise SubtitleError(2301)
        previous = start
        blocks.append(f"{timestamp(start)} --> {timestamp(end)}\n{html.escape(text, quote=False)}\n")
    if not blocks:
        raise SubtitleError(2304)
    return "WEBVTT\n\n" + "\n".join(blocks) + "\n"


def atomic_write(filename, text):
    target = Path(filename)
    temporary = target.with_suffix(target.suffix + ".part")
    try:
        with temporary.open("w", encoding="utf-8", newline="\n") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)
