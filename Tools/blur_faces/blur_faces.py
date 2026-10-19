import os
import sys
import json
import time
import datetime
import tempfile
import subprocess

import cv2
import pytz

from blur_faces_rules import (validate, with_defaults, expand_box, blur_kernel, pixel_cells,
                              output_name, preview_name, mux_args, duration_ok,
                              DETECT_EVERY, SCORE_THRESHOLD)
from utils.tool_msg import ToolMSG
import utils.env as env

MODEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          'models', 'face_detection_yunet_2023mar.onnx')
# a deteção corre num frame reduzido a este lado máximo (as caixas são reescaladas)
DETECT_MAX_SIDE = 640
# o desfoque é calculado numa cópia da região reduzida por este fator
BLUR_DOWNSCALE = 4


class BlurError(Exception):
    def __init__(self, message, error_code):
        super().__init__(message)
        self.error_code = error_code


class FaceDetector:
    """YuNet (OpenCV) sobre uma cópia reduzida do frame; devolve caixas no tamanho original."""

    def __init__(self, frame_w, frame_h):
        self._scale = min(1.0, DETECT_MAX_SIDE / max(frame_w, frame_h))
        self._size = (max(1, int(frame_w * self._scale)), max(1, int(frame_h * self._scale)))
        self._det = cv2.FaceDetectorYN.create(MODEL_PATH, '', self._size, SCORE_THRESHOLD)

    def detect(self, frame):
        small = frame if self._scale == 1.0 else cv2.resize(frame, self._size, interpolation=cv2.INTER_AREA)
        _, faces = self._det.detect(small)
        if faces is None:
            return []
        return [tuple(v / self._scale for v in f[:4]) for f in faces]


def anonymize(frame, boxes, params):
    """Aplica desfocagem ou pixelização às caixas, no próprio frame."""
    h, w = frame.shape[:2]
    for (x, y, bw, bh) in boxes:
        box = expand_box(x, y, bw, bh, float(params['padding']), w, h)
        if box is None:
            continue
        x0, y0, x1, y1 = box
        roi = frame[y0:y1, x0:x1]
        if params['mode'] == 'pixelate':
            cells = pixel_cells(params['strength'])
            small = cv2.resize(roi, (cells, cells), interpolation=cv2.INTER_LINEAR)
            frame[y0:y1, x0:x1] = cv2.resize(small, (x1 - x0, y1 - y0), interpolation=cv2.INTER_NEAREST)
        else:
            # desfoca uma cópia reduzida da região e volta a ampliá-la: o mesmo efeito
            # (o kernel é proporcional à região) com muito menos cálculo (REQ-041)
            sw, sh = max(1, (x1 - x0) // BLUR_DOWNSCALE), max(1, (y1 - y0) // BLUR_DOWNSCALE)
            small = cv2.resize(roi, (sw, sh), interpolation=cv2.INTER_AREA)
            k = blur_kernel(float(params['strength']), sw, sh)
            small = cv2.GaussianBlur(small, (k, k), 0)
            frame[y0:y1, x0:x1] = cv2.resize(small, (x1 - x0, y1 - y0), interpolation=cv2.INTER_LINEAR)
    return frame


class BlurFaces:
    def __init__(self):
        self._tool_msg = ToolMSG('picturas-blur-faces-tool-ms',
                                 'blur_faces',
                                 env.RABBITMQ_HOST,
                                 env.RABBITMQ_PORT,
                                 env.RABBITMQ_USERNAME,
                                 env.RABBITMQ_PASSWORD)
        self._counter = 0
        self._codes = {
            'wrong_procedure': 2500,
            'invalid_video': 2501,
            'error_processing': 2502,
            'invalid_params': 2503,
        }

    def probe_duration(self, video_path):
        try:
            out = subprocess.run(
                ['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                 '-show_entries', 'format=duration', '-of', 'json', video_path],
                capture_output=True, text=True, check=True, timeout=60,
            )
            duration = float(json.loads(out.stdout)['format']['duration'])
            if duration <= 0:
                raise ValueError('empty video')
            return duration
        except Exception:
            raise BlurError('The video could not be read. It may be corrupted or use an unsupported codec.',
                            self._codes['invalid_video'])

    def open_video(self, video_path):
        cap = cv2.VideoCapture(video_path)
        w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        if not cap.isOpened() or w <= 0 or h <= 0:
            cap.release()
            raise BlurError('The video could not be decoded. It may be corrupted.',
                            self._codes['invalid_video'])
        return cap, w, h

    def preview(self, video_path, out_path, params):
        """FA2: um só frame (o do meio do vídeo) com as caras anonimizadas, em PNG."""
        cap, w, h = self.open_video(video_path)
        try:
            total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            if total > 1:
                cap.set(cv2.CAP_PROP_POS_FRAMES, total // 2)
            ok, frame = cap.read()
            if not ok:
                cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                ok, frame = cap.read()
            if not ok:
                raise BlurError('The video could not be decoded. It may be corrupted.',
                                self._codes['invalid_video'])
        finally:
            cap.release()

        boxes = FaceDetector(w, h).detect(frame)
        cv2.imwrite(out_path, anonymize(frame, boxes, params))
        return len(boxes)

    def process(self, video_path, out_path, params, duration, on_progress):
        """Deteta e anonimiza frame a frame; junta o áudio original com o ffmpeg.
        Devolve o maior nº de caras detetadas num frame."""
        cap, w, h = self.open_video(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS) or 25
        total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) or int(duration * fps)
        detector = FaceDetector(w, h)

        max_faces, frames = 0, 0
        # temporários apagados no fim, com sucesso ou falha (REQ-033)
        with tempfile.TemporaryDirectory(prefix='blur_faces_') as tmp:
            frames_video = os.path.join(tmp, 'frames.mp4')
            writer = cv2.VideoWriter(frames_video, cv2.VideoWriter_fourcc(*'mp4v'), fps, (w, h))
            try:
                boxes = []
                while True:
                    ok, frame = cap.read()
                    if not ok:
                        break
                    if frames % DETECT_EVERY == 0:
                        boxes = detector.detect(frame)
                        max_faces = max(max_faces, len(boxes))
                    writer.write(anonymize(frame, boxes, params))
                    frames += 1
                    # 0-90 %: frames; o resto é a junção com o áudio
                    on_progress(min(90, int(frames * 90 / max(total, 1))))
            finally:
                cap.release()
                writer.release()

            if frames == 0:
                raise BlurError('The video has no frames that can be decoded. It may be corrupted.',
                                self._codes['invalid_video'])

            result = subprocess.run(mux_args(frames_video, video_path, out_path),
                                    capture_output=True, text=True, timeout=3600)
            if result.returncode != 0 or not os.path.exists(out_path) or os.path.getsize(out_path) == 0:
                detail = result.stderr.strip().splitlines()[-1] if result.stderr.strip() else 'unknown error'
                raise BlurError(f'The anonymized video could not be encoded ({detail}).',
                                self._codes['error_processing'])

        # RN6 / REQ-022: mesma duração do original (±1 s)
        out_duration = self.probe_duration(out_path)
        if not duration_ok(duration, out_duration):
            raise BlurError(f'The anonymized video has {out_duration:.1f} s instead of {duration:.1f} s.',
                            self._codes['error_processing'])
        return max_faces

    def now(self, start):
        cur = datetime.datetime.now(pytz.utc)
        return cur.isoformat(), (cur - start).total_seconds() * 1000

    def callback(self, ch, method, properties, body):
        info = json.loads(body.decode())

        msg_id = info['messageId']
        started = datetime.datetime.fromisoformat(info['timestamp'])
        procedure = info['procedure']
        params = info['parameters']
        video_path = params['inputImageURI']
        out_dir = os.path.dirname(params['outputImageURI'])

        resp_msg_id = f'blur_faces-{self._counter}-{msg_id}'
        self._counter += 1

        def send_error(code, message):
            ts, elapsed = self.now(started)
            self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'error', elapsed, None,
                                    err_code=code, err_msg=message, og_img_uri=video_path)

        if procedure != 'blur_faces':
            send_error(self._codes['wrong_procedure'], 'The procedure received does not fit into this tool')
            return

        out_path = None
        try:
            reason = validate(params)
            if reason:
                raise BlurError(reason, self._codes['invalid_params'])
            options = with_defaults(params)

            duration = self.probe_duration(video_path)
            os.makedirs(out_dir, exist_ok=True)
            video_name = os.path.basename(video_path)

            # FA2: a pré-visualização processa só um frame e devolve uma imagem
            if msg_id.startswith('preview'):
                out_path = os.path.join(out_dir, preview_name(video_name))
                faces = self.preview(video_path, out_path, options)
                ts, elapsed = self.now(started)
                self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'success', elapsed, out_path,
                                        type='image', extra={'facesDetected': faces})
                return

            out_path = os.path.join(out_dir, output_name(video_name))
            last = {'t': 0.0}

            def on_progress(pct):
                self._tool_msg.keep_alive()
                # no máximo uma vez por segundo
                if time.monotonic() - last['t'] >= 1:
                    last['t'] = time.monotonic()
                    ts, _ = self.now(started)
                    self._tool_msg.send_progress(msg_id, resp_msg_id, ts, pct)

            faces = self.process(video_path, out_path, options, duration, on_progress)

            ts, _ = self.now(started)
            self._tool_msg.send_progress(msg_id, resp_msg_id, ts, 100)

            ts, elapsed = self.now(started)
            self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'success', elapsed, out_path,
                                    type='video', extra={'facesDetected': faces})

        except Exception as e:
            # sem resultados parciais (REQ-020)
            if out_path and os.path.exists(out_path):
                try:
                    os.remove(out_path)
                except OSError:
                    pass

            if isinstance(e, BlurError):
                send_error(e.error_code, str(e))
            else:
                send_error(self._codes['error_processing'], f'Face blurring failed: {e}')

    def exec(self, args):
        while True:
            self._tool_msg.read_msg(self.callback)


if __name__ == "__main__":
    tool = BlurFaces()
    tool.exec(sys.argv)
