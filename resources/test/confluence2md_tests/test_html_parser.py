from __future__ import annotations

import sys
import unittest
from importlib import util
from pathlib import Path

if __package__ in {None, ""}:  # pragma: no cover - direct execution
    init_path = Path(__file__).resolve().parent / "__init__.py"
    spec = util.spec_from_file_location("confluence2md_test_bootstrap", init_path)
    bootstrap = util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(bootstrap)  # type: ignore[attr-defined]
else:
    bootstrap = sys.modules[__package__]  # pragma: no cover

bootstrap.setup()

from confluence2md import html_parser  # type: ignore  # noqa: E402


class HtmlParserTests(unittest.TestCase):
    def test_parse_html_retains_text_nodes(self) -> None:
        root = html_parser.parse_html("<div><p>Hi <strong>there</strong></p></div>")
        document_children = root.children
        self.assertEqual("div", document_children[0].name)
        paragraph = document_children[0].children[0]
        self.assertEqual("p", paragraph.name)
        self.assertEqual(2, len(paragraph.children))
        self.assertEqual("text", paragraph.children[0].node_type)
        self.assertEqual("Hi ", paragraph.children[0].text)
        self.assertEqual("strong", paragraph.children[1].name)
