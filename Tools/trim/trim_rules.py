import os

# Mesmas regras de projects/utils/trim.js
MIN_EXCERPT_SECONDS = 1

# Contentor -> codecs de saída (o contentor do original mantém-se; o vídeo é recodificado
# para o corte ser preciso, já que a cópia direta só corta em keyframes)
CODECS = {
    'webm': ['-c:v', 'libvpx-vp9', '-deadline', 'realtime', '-cpu-used', '8', '-b:v', '1M',
             '-c:a', 'libopus', '-b:a', '96k'],
    'default': ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23', '-pix_fmt', 'yuv420p',
                '-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart'],
}


def validate(params, duration):
    """None se o corte for possível, senão o motivo."""
    try:
        start = float(params['start'])
        end = float(params['end'])
    except (KeyError, TypeError, ValueError):
        return 'The start and end of the excerpt must be numbers of seconds'

    if start < 0:
        return 'The start must be zero or a positive number of seconds'
    if start >= end:
        return 'The start must be before the end'
    if end - start < MIN_EXCERPT_SECONDS:
        return f'The excerpt must be at least {MIN_EXCERPT_SECONDS} s long'
    # pequena folga: a duração lida no upload pode ter arredondamentos
    if end > duration + 0.05:
        return f'The end of the excerpt ({end:g} s) is beyond the end of the video ({duration:.0f} s)'
    return None


def output_name(video_name, start, end):
    """aula.mp4, 10, 40 -> aula_10-40s.mp4"""
    stem, ext = os.path.splitext(video_name)
    return f'{stem}_{start:g}-{end:g}s{ext}'


def ffmpeg_args(video_path, out_path, start, end):
    ext = os.path.splitext(out_path)[1].lstrip('.').lower()
    codecs = CODECS.get(ext, CODECS['default'])
    return ['ffmpeg', '-v', 'error', '-y',
            '-ss', f'{start:.3f}', '-i', video_path, '-t', f'{end - start:.3f}',
            # primeiro vídeo e, se existir, primeiro áudio
            '-map', '0:v:0', '-map', '0:a:0?',
            *codecs,
            '-progress', 'pipe:1', '-nostats',
            out_path]
