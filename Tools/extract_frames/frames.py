import math

# Mesmas regras de projects/utils/frames.js
MAX_FRAMES_PER_VIDEO = 100


def frame_timestamps(params, duration):
    """Instantes (s) a extrair: 0, N, 2N, ... < duração; ou [instant]."""
    if params.get('mode') == 'single':
        return [float(params['instant'])]

    n = float(params['interval'])
    count = math.ceil(duration / n)
    return [round(i * n, 3) for i in range(count)]


def validate(params, duration):
    """None se for possível extrair, senão o motivo."""
    mode = params.get('mode')

    if mode == 'single':
        instant = float(params.get('instant', -1))
        if instant < 0:
            return 'The instant must be zero or a positive number of seconds'
        if instant >= duration:
            return f'The chosen instant ({instant:g} s) is beyond the end of the video ({duration:.0f} s)'
        return None

    if mode == 'interval':
        if float(params.get('interval', 0)) <= 0:
            return 'The interval must be a positive number of seconds'
        if len(frame_timestamps(params, duration)) > MAX_FRAMES_PER_VIDEO:
            return f'The interval generates more than {MAX_FRAMES_PER_VIDEO} images for this video'
        return None

    return "The extraction mode must be 'interval' or 'single'"


def frame_file_name(video_name, time, image_format):
    """aula.mp4, 12 s, png -> aula_12s.png"""
    stem = video_name.rsplit('.', 1)[0]
    ext = 'jpg' if image_format == 'jpeg' else 'png'
    return f'{stem}_{time:g}s.{ext}'
