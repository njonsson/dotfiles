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

from slack2md import html_nodes  # type: ignore  # noqa: E402


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
