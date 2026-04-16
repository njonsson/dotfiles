from __future__ import annotations

import sys
import unittest
from pathlib import Path


TEST_ROOT = Path(__file__).resolve().parents[2]
MODULE_DIR = TEST_ROOT / "slack2md.d"
FIXTURE_DIR = Path(__file__).with_name("fixtures")

if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import extract  # noqa: E402
import render  # noqa: E402


class RenderTests(unittest.TestCase):
    def test_build_message_markdown_renders_author_timestamp_and_attachments(self) -> None:
        html_text = (FIXTURE_DIR / "slack_clipboard.html").read_text(encoding="utf-8")
        messages = extract.parse_slack_html(html_text, workspace_domain=None)
        rendered = render.build_message_markdown(messages[0], workspace_domain=None)
        self.assertIn("*15 Apr 2026 8:55 p.m.*", rendered)
        self.assertIn("**@nijonsso:** The quick, **brown** fox jumped over the lazy dog.", rendered)
        self.assertIn("[*some notes.txt*](file://some%20notes.txt)", rendered)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
