import os
import sys
import json
import datetime
import subprocess

import pytz

from frames import frame_timestamps, validate, frame_file_name
from utils.tool_msg import ToolMSG
from utils.video import probe, ProbeError, ProgressThrottle
import utils.env as env


class FrameError(Exception):
    def __init__(self, message, error_code):
        super().__init__(message)
        self.error_code = error_code


class ExtractFrames:
    def __init__(self):
        self._tool_msg = ToolMSG('picturas-extract-frames-tool-ms',
                                 'extract_frames',
                                 env.RABBITMQ_HOST,
                                 env.RABBITMQ_PORT,
                                 env.RABBITMQ_USERNAME,
                                 env.RABBITMQ_PASSWORD)
        self._counter = 0
        self._codes = {
            'wrong_procedure': 2000,
            'error_processing': 2001,
            'invalid_video': 2002,
            'invalid_params': 2003,
        }

    def probe_duration(self, video_path):
        try:
            duration = probe(video_path)['duration']
        except ProbeError:
            duration = 0
        if duration <= 0:
            raise FrameError('The video could not be read. It may be corrupted or use an unsupported codec.',
                             self._codes['invalid_video'])
        return duration

    def extract_frame(self, video_path, t, out_path, image_format):
        quality = ['-q:v', '2'] if image_format == 'jpeg' else []

        # -ss antes de -i: procura rápida e precisa; perto do fim pode não haver frame
        # exatamente em t, por isso tenta-se meio segundo antes
        for seek in (t, max(t - 0.5, 0)):
            subprocess.run(
                ['ffmpeg', '-v', 'error', '-ss', f'{seek:.3f}', '-i', video_path,
                 '-frames:v', '1', *quality, '-y', out_path],
                capture_output=True, timeout=120,
            )
            if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
                return

        raise FrameError(f'Could not extract the frame at {t:g} s. The video may be corrupted.',
                         self._codes['invalid_video'])

    def now(self, start):
        cur = datetime.datetime.now(pytz.utc)
        return cur.isoformat(), (cur - start).total_seconds() * 1000

    def callback(self, ch, method, properties, body):
        info = json.loads(body.decode())

        msg_id = info['messageId']
        start = datetime.datetime.fromisoformat(info['timestamp'])
        procedure = info['procedure']
        params = info['parameters']
        video_path = params['inputImageURI']
        out_dir = os.path.dirname(params['outputImageURI'])
        image_format = params.get('format', 'png')

        resp_msg_id = f'extract_frames-{self._counter}-{msg_id}'
        self._counter += 1

        def send_error(code, message):
            ts, elapsed = self.now(start)
            self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'error', elapsed, None,
                                    err_code=code, err_msg=message, og_img_uri=video_path)

        if procedure != 'extract_frames':
            send_error(self._codes['wrong_procedure'], 'The procedure received does not fit into this tool')
            return

        def send_progress(pct):
            ts, _ = self.now(start)
            self._tool_msg.send_progress(msg_id, resp_msg_id, ts, pct)

        progress = ProgressThrottle(send_progress)

        files = []
        try:
            # o trabalho saiu da fila: o frontend passa de "em fila" para "em curso"
            progress(0, force=True)

            duration = self.probe_duration(video_path)

            reason = validate(params, duration)
            if reason:
                raise FrameError(reason, self._codes['invalid_params'])

            times = frame_timestamps(params, duration)

            # a pré-visualização só precisa do primeiro frame
            if msg_id.startswith('preview'):
                times = times[:1]

            os.makedirs(out_dir, exist_ok=True)
            video_name = os.path.basename(video_path)

            for i, t in enumerate(times):
                out_path = os.path.join(out_dir, frame_file_name(video_name, t, image_format))
                self.extract_frame(video_path, t, out_path, image_format)
                files.append({'imageURI': out_path, 'time': t})

                self._tool_msg.keep_alive()

                # progresso no máximo uma vez por segundo (e sempre no último frame)
                progress(round((i + 1) * 100 / len(times)), force=i == len(times) - 1)

            ts, elapsed = self.now(start)
            if msg_id.startswith('preview'):
                self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'success', elapsed, files[0]['imageURI'])
            else:
                self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'success', elapsed, files[0]['imageURI'],
                                        type='images', images=files)

        except Exception as e:
            # sem resultados parciais
            for f in files:
                try:
                    os.remove(f['imageURI'])
                except OSError:
                    pass

            if isinstance(e, FrameError):
                send_error(e.error_code, str(e))
            else:
                send_error(self._codes['error_processing'], f'Frame extraction failed: {e}')

    def exec(self, args):
        while True:
            self._tool_msg.read_msg(self.callback)


if __name__ == "__main__":
    tool = ExtractFrames()
    tool.exec(sys.argv)
