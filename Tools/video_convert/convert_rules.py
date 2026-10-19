"""Regras da conversão/compressão (UC-VID-005), sem FFmpeg, para se poderem testar.
Os mesmos limites estão em projects/utils/videoConvert.js, que valida antes de enviar o pedido."""
import os
import uuid

MAX_INPUT_BYTES = 500 * 1024 * 1024
MAX_DURATION_SECONDS = 600
MAX_DURATION_DRIFT_SECONDS = 1.0
MAX_OUTPUT_HEIGHT = {"free": 720, "premium": 1080}
RESOLUTIONS = ("original", 1080, 720, 480, 360)
CRF = {
    "mp4": {"high": 20, "medium": 26, "low": 32},
    "webm": {"high": 30, "medium": 36, "low": 42},
}
# estimativa: 3 amostras de 2 s (início, meio e fim), codificadas com as opções escolhidas
SAMPLE_SECONDS = 2.0


def validate_params(params):
    """None se o formato, a resolução e a qualidade forem válidos, senão o motivo."""
    fmt = params.get("format")
    if fmt not in CRF or params.get("quality") not in CRF[fmt] or params.get("resolution", "original") not in RESOLUTIONS:
        return "Choose MP4 or WebM, a supported resolution, and a quality preset"
    return None


def validate_source(size_bytes, details):
    """None se o vídeo de entrada puder ser convertido, senão o motivo (RN4)."""
    if size_bytes > MAX_INPUT_BYTES:
        return "The video exceeds the 500 MB conversion limit"
    if details["duration"] <= 0 or details["duration"] > MAX_DURATION_SECONDS:
        return "The video must be no longer than 10 minutes"
    if details["video_codec"] != "h264" or details["audio_codec"] != "aac":
        return "Only MP4 or MOV videos with H.264 video and AAC audio are supported"
    return None


def target_height(resolution, source_height, user_type):
    """Altura de saída e o motivo da recusa (ou None). Nunca aumenta o vídeo."""
    max_height = MAX_OUTPUT_HEIGHT.get(user_type, MAX_OUTPUT_HEIGHT["free"])
    height = min(source_height, max_height) if resolution == "original" else int(resolution)
    if height > max_height:
        return height, f"This account can export up to {max_height}p"
    return height, None


def encode_args(source, output, fmt, quality, height, source_height, start=None, length=None):
    """Comando ffmpeg completo, com progresso em pipe:1."""
    cmd = ["ffmpeg", "-y", "-v", "error", "-progress", "pipe:1", "-nostats"]
    if start is not None:
        cmd += ["-ss", f"{start:.3f}"]
    cmd += ["-i", source]
    if length is not None:
        cmd += ["-t", f"{length:.3f}"]
    cmd += ["-map", "0:v:0", "-map", "0:a:0?", "-sn", "-dn"]
    if height < source_height:
        cmd += ["-vf", f"scale=-2:{height}"]
    if fmt == "mp4":
        cmd += ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "fast",
                "-crf", str(CRF[fmt][quality]), "-c:a", "aac", "-b:a", "128k",
                "-movflags", "+faststart"]
    else:
        cmd += ["-c:v", "libvpx-vp9", "-b:v", "0", "-crf", str(CRF[fmt][quality]),
                "-c:a", "libopus", "-b:a", "128k"]
    return cmd + [output]


def sample_starts(duration, sample=SAMPLE_SECONDS):
    """Inícios das amostras (s), sem repetidos: início, meio e fim do vídeo."""
    length = min(sample, duration)
    starts = []
    for s in (0.0, max(0.0, duration / 2 - length / 2), max(0.0, duration - length)):
        s = round(s, 3)
        if s not in starts:
            starts.append(s)
    return starts, length


def extrapolate(sample_bytes, sample_seconds, duration):
    """Tamanho estimado do vídeo inteiro a partir dos bytes por segundo das amostras (A4)."""
    if sample_seconds <= 0:
        raise ValueError("no samples")
    return max(1, round(sample_bytes / sample_seconds * duration))


def output_path(requested_path, output_format):
    directory = os.path.dirname(requested_path)
    stem = os.path.splitext(os.path.basename(requested_path))[0]
    return os.path.join(directory, f"{stem}__converted_{uuid.uuid4().hex[:10]}.{output_format}")
