import unittest

from convert_rules import (
    validate_params, validate_source, target_height, encode_args, sample_starts, extrapolate, output_path,
)

MB = 1024 * 1024
OK_VIDEO = {"duration": 30, "video_codec": "h264", "audio_codec": "aac", "width": 1920, "height": 1080}


class ParamsTest(unittest.TestCase):
    def test_valid(self):
        self.assertIsNone(validate_params({"format": "webm", "quality": "low", "resolution": 360}))

    def test_invalid(self):
        self.assertIsNotNone(validate_params({"format": "avi", "quality": "low"}))
        self.assertIsNotNone(validate_params({"format": "mp4", "quality": "max"}))
        self.assertIsNotNone(validate_params({"format": "mp4", "quality": "low", "resolution": 2160}))


class SourceTest(unittest.TestCase):
    def test_limits_at_the_boundary(self):
        self.assertIsNone(validate_source(500 * MB, {**OK_VIDEO, "duration": 600}))
        self.assertIn("500 MB", validate_source(500 * MB + 1, OK_VIDEO))
        self.assertIn("10 minutes", validate_source(MB, {**OK_VIDEO, "duration": 601}))

    def test_codecs(self):
        self.assertIsNotNone(validate_source(MB, {**OK_VIDEO, "video_codec": "hevc"}))
        self.assertIsNotNone(validate_source(MB, {**OK_VIDEO, "audio_codec": None}))


class HeightTest(unittest.TestCase):
    def test_profile_limits(self):
        self.assertEqual(target_height("original", 1080, "free"), (720, None))
        self.assertEqual(target_height("original", 1080, "premium"), (1080, None))
        self.assertIsNotNone(target_height(1080, 1080, "free")[1])

    def test_never_upscales_original(self):
        self.assertEqual(target_height("original", 240, "premium"), (240, None))


class EncodeArgsTest(unittest.TestCase):
    def test_scales_only_when_smaller(self):
        self.assertIn("scale=-2:360", encode_args("in.mp4", "out.mp4", "mp4", "low", 360, 1080))
        self.assertNotIn("-vf", encode_args("in.mp4", "out.mp4", "mp4", "low", 240, 240))

    def test_codecs_per_format(self):
        webm = encode_args("in.mp4", "out.webm", "webm", "high", 720, 1080)
        self.assertIn("libvpx-vp9", webm)
        self.assertIn("libopus", webm)
        self.assertEqual(webm[-1], "out.webm")

    def test_sample_window(self):
        cmd = encode_args("in.mp4", "s.mp4", "mp4", "medium", 720, 1080, start=4.0, length=2.0)
        self.assertEqual(cmd[cmd.index("-ss") + 1], "4.000")
        self.assertEqual(cmd[cmd.index("-t") + 1], "2.000")


class EstimateTest(unittest.TestCase):
    def test_samples_start_middle_end(self):
        self.assertEqual(sample_starts(10), ([0.0, 4.0, 8.0], 2.0))

    def test_short_video_has_one_sample(self):
        self.assertEqual(sample_starts(1.5), ([0.0], 1.5))

    def test_extrapolate(self):
        self.assertEqual(extrapolate(600_000, 6.0, 60), 6_000_000)
        with self.assertRaises(ValueError):
            extrapolate(1, 0, 10)


class OutputPathTest(unittest.TestCase):
    def test_new_file_next_to_requested(self):
        out = output_path("./images/u/p/out/aula.mov", "mp4")
        self.assertTrue(out.startswith("./images/u/p/out/aula__converted_"))
        self.assertTrue(out.endswith(".mp4"))


if __name__ == "__main__":
    unittest.main()
