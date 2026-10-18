import unittest

from trim_rules import validate, output_name, ffmpeg_args


class ValidateTest(unittest.TestCase):
    def test_valid_excerpt(self):
        self.assertIsNone(validate({'start': 10, 'end': 40}, 60))

    def test_start_after_end(self):
        self.assertIsNotNone(validate({'start': 40, 'end': 10}, 60))

    def test_excerpt_shorter_than_1s(self):
        self.assertIsNotNone(validate({'start': 10, 'end': 10.5}, 60))

    def test_end_beyond_video(self):
        self.assertIsNotNone(validate({'start': 0, 'end': 30}, 10))
        # folga para arredondamentos da duração
        self.assertIsNone(validate({'start': 0, 'end': 10}, 9.98))

    def test_missing_params(self):
        self.assertIsNotNone(validate({'start': 0}, 10))


class OutputTest(unittest.TestCase):
    def test_name_keeps_container_and_shows_interval(self):
        self.assertEqual(output_name('aula.mp4', 10.0, 40.0), 'aula_10-40s.mp4')
        self.assertEqual(output_name('clip.webm', 1.5, 3.0), 'clip_1.5-3s.webm')

    def test_codecs_follow_container(self):
        self.assertIn('libx264', ffmpeg_args('in.mov', 'out.mov', 0, 5))
        self.assertIn('libvpx-vp9', ffmpeg_args('in.webm', 'out.webm', 0, 5))

    def test_cut_uses_start_and_duration(self):
        args = ffmpeg_args('in.mp4', 'out.mp4', 10, 40)
        self.assertEqual(args[args.index('-ss') + 1], '10.000')
        self.assertEqual(args[args.index('-t') + 1], '30.000')


if __name__ == '__main__':
    unittest.main()
