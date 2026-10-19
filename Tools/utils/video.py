"""FFmpeg partilhado pelas tools de vídeo (trim, extract_frames, video_convert).

Cada tool continua a ser um microserviço independente; aqui fica só o que era igual
nas três: ler o vídeo com ffprobe, correr o ffmpeg a reportar o progresso e limitar
a frequência com que esse progresso é enviado.
"""
import json
import subprocess
import time


class ProbeError(Exception):
    """O ficheiro não se consegue ler ou não tem vídeo."""


class FFmpegError(Exception):
    """O ffmpeg terminou com erro; stderr guarda a mensagem original."""

    def __init__(self, stderr):
        super().__init__(stderr or 'unknown error')
        self.stderr = stderr or ''

    @property
    def last_line(self):
        lines = self.stderr.strip().splitlines()
        return lines[-1] if lines else 'unknown error'


def probe(path, timeout=60):
    """Duração, resolução e codecs do primeiro vídeo e do primeiro áudio."""
    try:
        out = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_entries',
             'format=duration:stream=codec_type,codec_name,width,height',
             '-of', 'json', path],
            capture_output=True, text=True, check=True, timeout=timeout,
        )
        info = json.loads(out.stdout)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, json.JSONDecodeError, OSError):
        raise ProbeError(path)

    streams = info.get('streams', [])
    video = next((s for s in streams if s.get('codec_type') == 'video'), None)
    audio = next((s for s in streams if s.get('codec_type') == 'audio'), None)
    if not video:
        raise ProbeError(path)
    return {
        'duration': float(info.get('format', {}).get('duration') or 0),
        'width': int(video.get('width') or 0),
        'height': int(video.get('height') or 0),
        'video_codec': video.get('codec_name'),
        'audio_codec': audio.get('codec_name') if audio else None,
    }


def run_ffmpeg(cmd, duration, on_progress=None, on_line=None):
    """Corre cmd (um ffmpeg com '-progress pipe:1 -nostats') e chama on_progress(0..99)
    à medida que avança, em função de duration (s). on_line é chamado a cada linha lida,
    para manter viva a ligação ao RabbitMQ. Lança FFmpegError se o ffmpeg falhar."""
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
    try:
        for line in proc.stdout:
            if on_line:
                on_line()
            key, _, value = line.strip().partition('=')
            # out_time_us (e o antigo out_time_ms) estão em microssegundos
            if key in ('out_time_us', 'out_time_ms') and value.isdigit() and on_progress and duration > 0:
                on_progress(min(99, max(0, int(int(value) / 1e6 * 100 / duration))))
        stderr = proc.stderr.read()
        code = proc.wait()
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait()
    if code != 0:
        raise FFmpegError(stderr.strip())


class ProgressThrottle:
    """Envia o progresso no máximo uma vez por intervalo e só quando muda;
    force=True envia sempre (ex.: 0 % ao sair da fila, 100 % no fim)."""

    def __init__(self, send, interval=1.0, clock=time.monotonic):
        self._send = send
        self._interval = interval
        self._clock = clock
        self._last_pct = None
        self._last_at = None

    def __call__(self, pct, force=False):
        now = self._clock()
        if not force:
            if pct == self._last_pct:
                return
            if self._last_at is not None and now - self._last_at < self._interval:
                return
        self._send(pct)
        self._last_pct, self._last_at = pct, now
