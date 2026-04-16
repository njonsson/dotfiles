from __future__ import annotations

import sys
import unittest
from pathlib import Path


TEST_ROOT = Path(__file__).resolve().parents[2]
MODULE_DIR = TEST_ROOT / "slack2md.d"
FIXTURE_DIR = Path(__file__).with_name("fixtures")

if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import converter  # noqa: E402


class ConverterTests(unittest.TestCase):
    def test_convert_matches_expected_markdown(self) -> None:
        html_path = FIXTURE_DIR / "slack_clipboard.html"
        expected_path = FIXTURE_DIR / "slack_clipboard_expected.md"
        html_text = html_path.read_text(encoding="utf-8")
        expected = expected_path.read_text(encoding="utf-8").strip()
        result = converter.convert(html_text, workspace_domain=None)
        self.assertEqual(result.strip(), expected)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
