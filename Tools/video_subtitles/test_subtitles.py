import hashlib
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from subtitles_rules import SubtitleError, webvtt, timestamp, atomic_write
from video_subtitles import VideoSubtitles


class SubtitleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.source = Path(self.temp.name) / "original.mp4"
        self.source.write_bytes(b"immutable source fixture")
        self.output = Path(self.temp.name) / "subtitles.vtt"
        self.segment = SimpleNamespace(start=1.0, end=3.5, text="Olá <mundo> & amigos")
        self.model = Mock()
        self.model.transcribe.return_value = ([self.segment], SimpleNamespace(language="pt"))
        self.worker = VideoSubtitles(
            model=self.model, decode=Mock(return_value=[0.1]),
            speech=Mock(return_value=[{"start": 0, "end": 1}]),
            probe_video=Mock(return_value={"audio_codec": "aac"}),
        )
        self.request = {"procedure": "video_subtitles", "parameters": {
            "inputImageURI": str(self.source), "outputImageURI": str(self.output),
            "videoId": "video", "language": "original",
        }}
        self.before = hashlib.sha256(self.source.read_bytes()).hexdigest()

    def tearDown(self):
        self.assertEqual(self.before, hashlib.sha256(self.source.read_bytes()).hexdigest())
        self.assertFalse(self.output.with_suffix(".vtt.part").exists())

    def failure(self, code):
        with self.assertRaises(SubtitleError) as caught:
            self.worker.process(self.request)
        self.assertEqual(caught.exception.code, code)
        self.assertFalse(self.output.exists())

    def test_original_transcribes_detects_and_writes_valid_escaped_vtt(self):
        result = self.worker.process(self.request)
        self.assertEqual(result["metadata"]["detectedLanguage"], "pt")
        self.assertEqual(result["metadata"]["trackLanguage"], "pt")
        self.assertEqual(self.model.transcribe.call_args.kwargs, {
            "task": "transcribe", "language": None, "vad_filter": True, "multilingual": False})
        self.assertEqual(self.output.read_text(encoding="utf-8"),
                         "WEBVTT\n\n00:00:01.000 --> 00:00:03.500\nOlá &lt;mundo&gt; &amp; amigos\n\n")

    def test_english_first_translates_without_forcing_source_language(self):
        self.request["parameters"]["language"] = "en"
        result = self.worker.process(self.request)
        self.assertEqual(result["metadata"]["detectedLanguage"], "pt")
        self.assertEqual(result["metadata"]["trackLanguage"], "en")
        self.assertEqual(self.model.transcribe.call_args.kwargs["task"], "translate")
        self.assertIsNone(self.model.transcribe.call_args.kwargs["language"])

    def test_second_request_uses_predominant_language(self):
        self.request["parameters"].update(language="en", detectedLanguage="pt")
        self.worker.process(self.request)
        self.assertEqual(self.model.transcribe.call_args.kwargs["language"], "pt")
        self.assertFalse(self.model.transcribe.call_args.kwargs["multilingual"])

    def test_english_source_both_first_options(self):
        for language in ("original", "en"):
            self.request["parameters"]["language"] = language
            self.model.transcribe.return_value = ([self.segment], SimpleNamespace(language="en"))
            result = self.worker.process(self.request)
            self.assertEqual(result["metadata"]["detectedLanguage"], "en")

    def test_no_audio(self):
        self.worker.probe.return_value = {"audio_codec": None}
        self.failure(2303)
        self.model.transcribe.assert_not_called()

    def test_silence_before_detection(self):
        self.worker.speech.return_value = []
        self.failure(2304)
        self.model.transcribe.assert_not_called()

    def test_empty_recognition(self):
        self.model.transcribe.return_value = ([], SimpleNamespace(language="pt"))
        self.failure(2304)

    def test_whitespace_is_not_speech(self):
        self.segment.text = " \n "
        self.failure(2304)

    def test_generator_failure_does_not_publish_partial(self):
        def segments():
            yield self.segment
            raise RuntimeError("inference failure")
        self.model.transcribe.return_value = (segments(), SimpleNamespace(language="pt"))
        self.failure(2301)

    def test_write_failure_preserves_input_and_other_track(self):
        other = Path(self.temp.name) / "valid.vtt"
        other.write_text("valid")
        with patch("subtitles_rules.os.replace", side_effect=OSError("disk full")):
            self.failure(2301)
        self.assertEqual(other.read_text(), "valid")

    def test_reject_modes_srt_and_other_targets(self):
        for params in ({"language": "pt"}, {"mode": "burn"}, {"format": "srt"}, {"previewSeconds": 3}):
            with self.subTest(params=params):
                original = self.request["parameters"].copy()
                self.request["parameters"].update(params)
                self.failure(2302)
                self.request["parameters"] = original

    def test_wrong_procedure(self):
        self.request["procedure"] = "trim"
        self.failure(2300)

    def test_invalid_times(self):
        for start, end in ((-1, 2), (3, 1), (0, float("nan")), (1, 1.00001)):
            self.segment.start, self.segment.end = start, end
            self.failure(2301)

    def test_timestamp_rollover(self):
        self.assertEqual(timestamp(3600000), "01:00:00.000")

    def test_atomic_file_replacement(self):
        atomic_write(self.output, "WEBVTT\n\n")
        self.assertEqual(self.output.read_text(), "WEBVTT\n\n")


if __name__ == "__main__":
    unittest.main()
