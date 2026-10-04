"""Evidence integrity checks: missing/changed originals and unsafe output paths."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

MODULE = Path(__file__).with_name("build_results.py")


class ReportIntegrity(unittest.TestCase):
    def setUp(self):
        self.assertTrue(MODULE.exists(), "The evidence-preserving report builder is missing")
        spec = importlib.util.spec_from_file_location("report_builder", MODULE)
        self.builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.builder)

    def test_changed_original_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "original.csv").write_text("1,2\n")
            entries = [{"path": "original.csv", "sha256": self.builder.sha256(root / "original.csv")}]
            self.assertEqual(self.builder.check_preservation(root, entries)["changed"], [])
            (root / "original.csv").write_text("9,2\n")
            self.assertEqual(self.builder.check_preservation(root, entries)["changed"], ["original.csv"])

    def test_missing_original_is_reported(self):
        with tempfile.TemporaryDirectory() as folder:
            result = self.builder.check_preservation(Path(folder), [{"path": "gone.csv", "sha256": "x"}])
            self.assertEqual(result["missing"], ["gone.csv"])

    def test_json_has_no_nonstandard_nan_or_script_terminator(self):
        text = self.builder.json_for_html({"fault": float("nan"), "note": "</script><script>danger</script>"})
        self.assertNotIn("</script>", text)
        self.assertIsNone(json.loads(text)["fault"])


if __name__ == "__main__":
    unittest.main()
