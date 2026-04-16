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


class ExtractTests(unittest.TestCase):
    def test_parse_slack_html_builds_messages(self) -> None:
        html_text = (FIXTURE_DIR / "slack_clipboard.html").read_text(encoding="utf-8")
        messages = extract.parse_slack_html(html_text, workspace_domain=None)
        self.assertEqual(len(messages), 2)
        first = messages[0]
        second = messages[1]
        self.assertEqual(first.author, "@nijonsso")
        self.assertGreaterEqual(len(first.attachments), 2)
        self.assertTrue(first.attachments[1].is_image)
        self.assertIsNotNone(first.timestamp)
        self.assertGreater(len(first.body_nodes), 0)
        self.assertEqual(second.author, "Nils Jonsson")
        self.assertGreater(len(second.body_nodes), 0)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
