from __future__ import annotations

import sys
import unittest
from pathlib import Path


TEST_ROOT = Path(__file__).resolve().parents[2]
MODULE_DIR = TEST_ROOT / "slack2md.d"

if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import utils  # noqa: E402


class UtilsTests(unittest.TestCase):
    def test_clean_text_preserves_nbsp(self) -> None:
        self.assertEqual(utils.clean_text("Hello&nbsp;world"), "Hello world")

    def test_normalize_workspace_domain(self) -> None:
        self.assertEqual(utils.normalize_workspace_domain("team.slack.com"), "team.slack.com")

    def test_escape_markdown_escapes_special_characters(self) -> None:
        self.assertEqual(utils.escape_markdown("*test*"), r"\*test\*")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
