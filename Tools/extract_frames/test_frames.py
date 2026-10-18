import unittest

from frames import frame_timestamps, validate, frame_file_name, MAX_FRAMES_PER_VIDEO


class FrameTimestampsTest(unittest.TestCase):
    def test_interval_60s_every_10s_gives_6_frames(self):
        self.assertEqual(frame_timestamps({'mode': 'interval', 'interval': 10}, 60),
                         [0, 10, 20, 30, 40, 50])

    def test_interval_rounds_fractional_steps(self):
        self.assertEqual(frame_timestamps({'mode': 'interval', 'interval': 0.1}, 0.3), [0, 0.1, 0.2])

    def test_single_returns_the_instant(self):
        self.assertEqual(frame_timestamps({'mode': 'single', 'instant': 12}, 60), [12.0])


class ValidateTest(unittest.TestCase):
    def test_instant_beyond_end_is_rejected(self):
        self.assertIsNotNone(validate({'mode': 'single', 'instant': 30}, 10))

    def test_instant_inside_video_is_accepted(self):
        self.assertIsNone(validate({'mode': 'single', 'instant': 9.5}, 10))

    def test_limit_boundary(self):
        # 600 s a cada 6 s = 100 imagens (aceite); a cada 5 s = 120 (recusado)
        self.assertIsNone(validate({'mode': 'interval', 'interval': 6}, 600))
        self.assertIsNotNone(validate({'mode': 'interval', 'interval': 5}, 600))
        self.assertEqual(len(frame_timestamps({'mode': 'interval', 'interval': 6}, 600)), MAX_FRAMES_PER_VIDEO)

    def test_invalid_mode_and_interval(self):
        self.assertIsNotNone(validate({'mode': 'other'}, 10))
        self.assertIsNotNone(validate({'mode': 'interval', 'interval': 0}, 10))


class FrameFileNameTest(unittest.TestCase):
    def test_name_contains_video_and_instant(self):
        self.assertEqual(frame_file_name('aula.mp4', 12.0, 'png'), 'aula_12s.png')
        self.assertEqual(frame_file_name('aula.mov', 2.5, 'jpeg'), 'aula_2.5s.jpg')


if __name__ == '__main__':
    unittest.main()
