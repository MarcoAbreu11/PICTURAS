import os

# Mesmas regras de projects/utils/blurFaces.js
MODES = ('blur', 'pixelate')
MIN_STRENGTH, MAX_STRENGTH = 1, 10
MIN_PADDING, MAX_PADDING = 0, 100
DEFAULTS = {'mode': 'blur', 'strength': 5, 'padding': 20}

# Deteta a cada N frames e reutiliza as caixas nos intermédios (UC-VID-004, REQ-041)
DETECT_EVERY = 3
# Confiança mínima do YuNet para aceitar uma cara
SCORE_THRESHOLD = 0.6
# Diferença máxima entre a duração do original e a do resultado (REQ-022)
MAX_DURATION_DIFF = 1.0

# Contentor -> codecs de saída: o contentor do original mantém-se e o vídeo é recodificado,
# porque os píxeis mudam (REQ-043; os mesmos codecs que o corte, UC-VID-002)
CODECS = {
    'webm': ['-c:v', 'libvpx-vp9', '-deadline', 'realtime', '-cpu-used', '8', '-b:v', '1M',
             '-c:a', 'libopus', '-b:a', '96k'],
    'default': ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23', '-pix_fmt', 'yuv420p',
                '-c:a', 'aac', '-b:a', '128k', '-movflags', '+faststart'],
}


def with_defaults(params):
    """Parâmetros com os valores por omissão preenchidos."""
    return {**DEFAULTS, **{k: v for k, v in (params or {}).items() if v is not None}}


def validate(params):
    """None se as opções forem válidas, senão o motivo."""
    p = with_defaults(params)

    if p['mode'] not in MODES:
        return "The anonymization type must be 'blur' or 'pixelate'"

    try:
        strength = float(p['strength'])
        padding = float(p['padding'])
    except (TypeError, ValueError):
        return 'The intensity and the margin must be numbers'

    if not (MIN_STRENGTH <= strength <= MAX_STRENGTH):
        return f'The intensity must be between {MIN_STRENGTH} and {MAX_STRENGTH}'
    if not (MIN_PADDING <= padding <= MAX_PADDING):
        return f'The margin must be between {MIN_PADDING} and {MAX_PADDING} %'
    return None


def expand_box(x, y, w, h, padding, frame_w, frame_h):
    """Alarga a caixa da cara em `padding` % e corta-a aos limites do frame.
    Devolve (x0, y0, x1, y1) ou None se ficar vazia."""
    pad = int(round(max(w, h) * padding / 100))
    x0, y0 = max(0, int(x) - pad), max(0, int(y) - pad)
    x1, y1 = min(frame_w, int(x + w) + pad), min(frame_h, int(y + h) + pad)
    if x1 <= x0 or y1 <= y0:
        return None
    return x0, y0, x1, y1


def blur_kernel(strength, box_w, box_h):
    """Tamanho (ímpar) do kernel gaussiano: proporcional à cara e à intensidade."""
    k = int(max(box_w, box_h) * strength / 15)
    k = max(3, k)
    return k if k % 2 == 1 else k + 1


def pixel_cells(strength):
    """Nº de blocos por lado na pixelização: mais intensidade = menos blocos (maiores)."""
    return max(4, 22 - 2 * int(strength))


def output_name(video_name):
    """aula.mp4 -> aula_blurred.mp4"""
    stem, ext = os.path.splitext(video_name)
    return f'{stem}_blurred{ext}'


def preview_name(video_name):
    """aula.mp4 -> aula_blurred_preview.png (a pré-visualização é um só frame)"""
    stem, _ = os.path.splitext(video_name)
    return f'{stem}_blurred_preview.png'


def mux_args(frames_video, original, out_path):
    """ffmpeg: vídeo processado + áudio do original (se existir), codecs pelo contentor."""
    ext = os.path.splitext(out_path)[1].lstrip('.').lower()
    codecs = CODECS.get(ext, CODECS['default'])
    return ['ffmpeg', '-v', 'error', '-y',
            '-i', frames_video, '-i', original,
            '-map', '0:v:0', '-map', '1:a:0?',
            *codecs,
            '-shortest',
            out_path]


def duration_ok(original, result):
    return abs(float(original) - float(result)) <= MAX_DURATION_DIFF
