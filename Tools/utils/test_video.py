"""Testes do módulo partilhado das tools de vídeo. Na pasta Tools: python -m unittest utils.test_video"""
import os
import shutil
import subprocess
import tempfile
import unittest

from utils.video import probe, run_ffmpeg, ProbeError, FFmpegError, ProgressThrottle


class ProgressThrottleTest(unittest.TestCase):
    def test_at_most_once_per_interval_and_only_on_change(self):
        sent, now = [], [0.0]
        p = ProgressThrottle(sent.append, interval=1.0, clock=lambda: now[0])
        p(0, force=True)
        p(10)              # < 1 s depois: não envia
        now[0] = 1.5
        p(10)              # já passou 1 s: envia
        p(10)              # igual: não envia
        now[0] = 3.0
        p(10)              # igual mesmo depois do intervalo: não envia
        p(100, force=True)
        self.assertEqual(sent, [0, 10, 100])


@unittest.skipUnless(shutil.which("ffmpeg"), "ffmpeg not installed")
class FFmpegTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.video = os.path.join(self.dir, "in.mp4")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", "testsrc=duration=3:size=320x240:rate=10",
                        "-f", "lavfi", "-i", "sine=duration=3", "-c:v", "libx264", "-pix_fmt", "yuv420p",
                        "-c:a", "aac", "-shortest", self.video], check=True)

    def tearDown(self):
        shutil.rmtree(self.dir, ignore_errors=True)

    def test_probe(self):
        info = probe(self.video)
        self.assertAlmostEqual(info["duration"], 3, delta=0.2)
        self.assertEqual((info["width"], info["height"]), (320, 240))
        self.assertEqual((info["video_codec"], info["audio_codec"]), ("h264", "aac"))

    def test_probe_rejects_unreadable_file(self):
        bad = os.path.join(self.dir, "bad.mp4")
        with open(bad, "wb") as f:
            f.write(b"not a video")
        with self.assertRaises(ProbeError):
            probe(bad)

    def test_run_ffmpeg_reports_increasing_progress(self):
        seen = []
        out = os.path.join(self.dir, "out.mp4")
        run_ffmpeg(["ffmpeg", "-y", "-v", "error", "-progress", "pipe:1", "-nostats", "-i", self.video,
                    "-c:v", "libx264", "-c:a", "aac", out], 3, on_progress=seen.append)
        self.assertTrue(os.path.getsize(out) > 0)
        self.assertTrue(seen)
        self.assertEqual(seen, sorted(seen))
        self.assertTrue(all(0 <= p <= 99 for p in seen))

    def test_run_ffmpeg_failure(self):
        with self.assertRaises(FFmpegError):
            run_ffmpeg(["ffmpeg", "-v", "error", "-progress", "pipe:1", "-i", "/missing.mp4", "/tmp/x.mp4"], 1)


if __name__ == "__main__":
    unittest.main()
