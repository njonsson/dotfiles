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

from confluence2md import html_parser, tables  # type: ignore  # noqa: E402


class TablesTests(unittest.TestCase):
    def test_render_table_generates_alignment_markers(self) -> None:
        root = html_parser.parse_html(
            """
            <table>
              <tr>
                <th align="left">Left</th>
                <th style="text-align: right;">Right</th>
                <th style="text-align: center;">Center</th>
              </tr>
              <tr>
                <td>One</td>
                <td>Two</td>
                <td>Three</td>
              </tr>
            </table>
            """
        )
        table_node = next(child for child in root.children if child.node_type == "element")
        rendered = tables.render_table(table_node)
        self.assertEqual(
            "| Left | Right | Center |\n| :--- | ---: | :---: |\n| One | Two | Three |",
            rendered,
        )

    def test_render_table_converts_paragraph_boundaries_to_double_breaks(self) -> None:
        root = html_parser.parse_html(
            """
            <table>
              <tr>
                <th>Header</th>
              </tr>
              <tr>
                <td><div><div><p>First</p><p>Second</p></div></div></td>
              </tr>
            </table>
            """
        )
        table_node = next(child for child in root.children if child.node_type == "element")
        rendered = tables.render_table(table_node)
        self.assertEqual(
            "| Header |\n| --- |\n| First<br/><br/>Second |",
            rendered,
        )
