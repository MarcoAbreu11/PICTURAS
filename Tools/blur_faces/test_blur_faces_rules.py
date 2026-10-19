import unittest

from blur_faces_rules import (validate, with_defaults, expand_box, blur_kernel, pixel_cells,
                              output_name, preview_name, mux_args, duration_ok)


class ValidateTest(unittest.TestCase):
    def test_defaults_are_valid(self):
        self.assertIsNone(validate({}))
        self.assertEqual(with_defaults({})['mode'], 'blur')

    def test_valid_options(self):
        self.assertIsNone(validate({'mode': 'pixelate', 'strength': 10, 'padding': 0}))
        self.assertIsNone(validate({'mode': 'blur', 'strength': 1, 'padding': 100}))

    def test_unknown_mode(self):
        self.assertIsNotNone(validate({'mode': 'emoji'}))

    def test_strength_out_of_range(self):
        self.assertIsNotNone(validate({'strength': 0}))
        self.assertIsNotNone(validate({'strength': 11}))
        self.assertIsNotNone(validate({'strength': 'forte'}))

    def test_padding_out_of_range(self):
        self.assertIsNotNone(validate({'padding': -1}))
        self.assertIsNotNone(validate({'padding': 101}))


class BoxTest(unittest.TestCase):
    def test_padding_grows_the_box(self):
        self.assertEqual(expand_box(100, 100, 50, 50, 20, 640, 480), (90, 90, 160, 160))

    def test_box_is_clipped_to_the_frame(self):
        self.assertEqual(expand_box(-10, -10, 50, 50, 20, 640, 480), (0, 0, 50, 50))
        self.assertEqual(expand_box(620, 460, 50, 50, 0, 640, 480), (620, 460, 640, 480))

    def test_box_outside_the_frame_is_ignored(self):
        self.assertIsNone(expand_box(700, 500, 50, 50, 0, 640, 480))


class AnonymizationTest(unittest.TestCase):
    def test_kernel_is_odd_and_grows_with_strength(self):
        for s in range(1, 11):
            self.assertEqual(blur_kernel(s, 120, 120) % 2, 1)
        self.assertGreater(blur_kernel(10, 120, 120), blur_kernel(1, 120, 120))

    def test_kernel_has_a_minimum(self):
        self.assertEqual(blur_kernel(1, 10, 10), 3)

    def test_more_strength_means_bigger_blocks(self):
        self.assertLess(pixel_cells(10), pixel_cells(1))
        self.assertGreaterEqual(pixel_cells(10), 4)


class OutputTest(unittest.TestCase):
    def test_names_keep_the_container(self):
        self.assertEqual(output_name('aula.mp4'), 'aula_blurred.mp4')
        self.assertEqual(output_name('clip.webm'), 'clip_blurred.webm')
        self.assertEqual(preview_name('aula.mov'), 'aula_blurred_preview.png')

    def test_codecs_follow_the_container(self):
        self.assertIn('libx264', mux_args('f.mp4', 'in.mov', 'out.mov'))
        self.assertIn('libvpx-vp9', mux_args('f.mp4', 'in.webm', 'out.webm'))

    def test_audio_comes_from_the_original(self):
        args = mux_args('frames.mp4', 'in.mp4', 'out.mp4')
        self.assertIn('1:a:0?', args)
        self.assertEqual(args[args.index('-i', args.index('-i') + 1) + 1], 'in.mp4')

    def test_duration_tolerance(self):
        self.assertTrue(duration_ok(60, 60.9))
        self.assertFalse(duration_ok(60, 58.5))


if __name__ == '__main__':
    unittest.main()
