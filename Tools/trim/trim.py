import os
import sys
import json
import time
import datetime
import subprocess

import pytz

from trim_rules import validate, output_name, ffmpeg_args
from utils.tool_msg import ToolMSG
import utils.env as env


class TrimError(Exception):
    def __init__(self, message, error_code):
        super().__init__(message)
        self.error_code = error_code


class Trim:
    def __init__(self):
        self._tool_msg = ToolMSG('picturas-trim-tool-ms',
                                 'trim',
                                 env.RABBITMQ_HOST,
                                 env.RABBITMQ_PORT,
                                 env.RABBITMQ_USERNAME,
                                 env.RABBITMQ_PASSWORD)
        self._counter = 0
        self._codes = {
            'wrong_procedure': 2100,
            'error_processing': 2101,
            'invalid_video': 2102,
            'invalid_params': 2103,
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
            raise TrimError('The video could not be read. It may be corrupted or use an unsupported codec.',
                            self._codes['invalid_video'])

    def cut(self, video_path, out_path, start, end, on_progress):
        """Corta com ffmpeg; on_progress(0..100) à medida que avança."""
        excerpt = end - start
        proc = subprocess.Popen(ffmpeg_args(video_path, out_path, start, end),
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # -progress pipe:1 escreve linhas key=value; out_time_us é o tempo já produzido
        for line in proc.stdout:
            key, _, value = line.strip().partition('=')
            if key == 'out_time_us' and value.isdigit() and excerpt > 0:
                on_progress(min(99, int(int(value) / 1e6 * 100 / excerpt)))

        stderr = proc.stderr.read()
        if proc.wait() != 0 or not os.path.exists(out_path) or os.path.getsize(out_path) == 0:
            detail = stderr.strip().splitlines()[-1] if stderr.strip() else 'unknown error'
            raise TrimError(f'The video could not be cut ({detail}). It may be corrupted.',
                            self._codes['invalid_video'])

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

        resp_msg_id = f'trim-{self._counter}-{msg_id}'
        self._counter += 1

        def send_error(code, message):
            ts, elapsed = self.now(started)
            self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'error', elapsed, None,
                                    err_code=code, err_msg=message, og_img_uri=video_path)

        if procedure != 'trim':
            send_error(self._codes['wrong_procedure'], 'The procedure received does not fit into this tool')
            return

        out_path = None
        try:
            duration = self.probe_duration(video_path)

            reason = validate(params, duration)
            if reason:
                raise TrimError(reason, self._codes['invalid_params'])

            start, end = float(params['start']), min(float(params['end']), duration)

            os.makedirs(out_dir, exist_ok=True)
            out_path = os.path.join(out_dir, output_name(os.path.basename(video_path), start, float(params['end'])))

            last = {'t': 0.0}

            def on_progress(pct):
                self._tool_msg.keep_alive()
                # no máximo uma vez por segundo
                if time.monotonic() - last['t'] >= 1:
                    last['t'] = time.monotonic()
                    ts, _ = self.now(started)
                    self._tool_msg.send_progress(msg_id, resp_msg_id, ts, pct)

            self.cut(video_path, out_path, start, end, on_progress)

            ts, _ = self.now(started)
            self._tool_msg.send_progress(msg_id, resp_msg_id, ts, 100)

            ts, elapsed = self.now(started)
            self._tool_msg.send_msg(msg_id, resp_msg_id, ts, 'success', elapsed, out_path, type='video')

        except Exception as e:
            # sem resultados parciais
            if out_path and os.path.exists(out_path):
                try:
                    os.remove(out_path)
                except OSError:
                    pass

            if isinstance(e, TrimError):
                send_error(e.error_code, str(e))
            else:
                send_error(self._codes['error_processing'], f'Trim failed: {e}')

    def exec(self, args):
        while True:
            self._tool_msg.read_msg(self.callback)


if __name__ == "__main__":
    tool = Trim()
    tool.exec(sys.argv)
