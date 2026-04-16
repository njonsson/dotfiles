from __future__ import annotations

import sys
import unittest
from importlib import util
from pathlib import Path

if __package__ in {None, ""}:  # pragma: no cover - direct execution
    init_path = Path(__file__).resolve().parent / "__init__.py"
    spec = util.spec_from_file_location("slack2md_test_bootstrap", init_path)
    bootstrap = util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(bootstrap)  # type: ignore[attr-defined]
else:
    from importlib import import_module

    package_name = __package__ or Path(__file__).resolve().parent.name
    bootstrap = import_module(package_name)  # pragma: no cover

bootstrap.setup()

from slack2md import extract  # type: ignore  # noqa: E402

FIXTURE_DIR = Path(__file__).with_name("fixtures")


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
