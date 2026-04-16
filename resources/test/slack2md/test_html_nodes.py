from __future__ import annotations

import sys
import unittest
from pathlib import Path


TEST_ROOT = Path(__file__).resolve().parents[2]
MODULE_DIR = TEST_ROOT / "slack2md.d"

if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import html_nodes  # noqa: E402


class HtmlNodesTests(unittest.TestCase):
    def test_parse_html_preserves_entity_text(self) -> None:
        root = html_nodes.parse_html("<div id='wrap'><span>Hi&nbsp;there</span></div>")
        document_children = root.children
        self.assertEqual(len(document_children), 1)
        div = document_children[0]
        self.assertEqual(div.attrs["id"], "wrap")
        span = div.children[0]
        self.assertEqual(span.tag, "span")
        self.assertEqual(span.text(), "Hi&nbsp;there")

    def test_find_all_locates_nodes(self) -> None:
        root = html_nodes.parse_html("<div><p>a</p><p>b</p></div>")
        ps = html_nodes.find_all(root, lambda node: node.tag == "p")
        texts = [node.text() for node in ps]
        self.assertEqual(texts, ["a", "b"])


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
