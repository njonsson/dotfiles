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

from confluence2md import html_parser, inline  # type: ignore  # noqa: E402


class InlineTests(unittest.TestCase):
    def test_render_inline_handles_basic_formatting(self) -> None:
        root = html_parser.parse_html("<div><p>Hello <strong>World</strong></p></div>")
        paragraph = root.children[0].children[0]
        rendered = inline.render_inline(paragraph.children)
        self.assertEqual("Hello **World**", rendered)

    def test_render_inline_renders_code_spans(self) -> None:
        root = html_parser.parse_html("<div><p>Use <code>x</code></p></div>")
        paragraph = root.children[0].children[0]
        rendered = inline.render_inline(paragraph.children)
        self.assertEqual("Use `x`", rendered)

    def test_render_inline_renders_button_as_bold(self) -> None:
        root = html_parser.parse_html("<div><p>Click <button>Submit</button></p></div>")
        paragraph = root.children[0].children[0]
        rendered = inline.render_inline(paragraph.children)
        self.assertEqual("Click **Submit**", rendered)

    def test_render_inline_renders_aui_lozenge_as_inline_code(self) -> None:
        root = html_parser.parse_html('<div><p>Status <span class="aui-lozenge aui-lozenge-success">Done</span></p></div>')
        paragraph = root.children[0].children[0]
        rendered = inline.render_inline(paragraph.children)
        self.assertEqual("Status `Done`", rendered)

    def test_render_inline_renders_time_elements_using_datetime(self) -> None:
        html = (
            '<div><p><time datetime="2026-04-07" class="date-past">07 Apr 2026</time>'
            " in Confluence</p></div>"
        )
        root = html_parser.parse_html(html)
        paragraph = root.children[0].children[0]
        rendered = inline.render_inline(paragraph.children)
        self.assertEqual("`🗓️ 7 Apr 2026` in Confluence", rendered)
