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

from confluence2md import converter  # type: ignore  # noqa: E402


class ConverterTests(unittest.TestCase):
    def assertConverts(self, html: str, expected: str) -> None:
        result = converter.convert(html)
        self.assertEqual(expected, result)

    def test_paragraphs_and_line_breaks(self) -> None:
        html = """
        <div>
          <p>Hello<br/>World</p>
          <p>Second paragraph.</p>
        </div>
        """
        expected = "Hello  \nWorld\n\nSecond paragraph.\n"
        self.assertConverts(html, expected)

    def test_headings(self) -> None:
        html = """
        <div>
          <h1>Heading One</h1>
          <h3>Heading Three</h3>
        </div>
        """
        expected = "# Heading One\n\n### Heading Three\n"
        self.assertConverts(html, expected)

    def test_blockquote_nesting(self) -> None:
        html = """
        <blockquote>
          <p>Level 1</p>
          <blockquote>
            <p>Level 2</p>
          </blockquote>
        </blockquote>
        """
        expected = "> Level 1\n\n> > Level 2\n"
        self.assertConverts(html, expected)

    def test_code_blocks_and_inline(self) -> None:
        html = """
        <div>
          <p>Inline <code>code</code> sample.</p>
          <pre><code class="language-python">print('hello')\nprint('world')</code></pre>
          <code>single line</code>
        </div>
        """
        expected = (
            "Inline `code` sample.\n\n"
            "```python\nprint('hello')\nprint('world')\n```\n\n"
            "`single line`\n"
        )
        self.assertConverts(html, expected)

    def test_lists_and_tasks(self) -> None:
        html = """
        <ul>
          <li>Item one</li>
          <li>
            <input type="checkbox" checked="checked" />
            Task done
            <ul>
              <li>Nested bullet</li>
            </ul>
          </li>
        </ul>
        <ol>
          <li>First</li>
          <li>Second</li>
        </ol>
        """
        expected = (
            "* Item one\n"
            "* [x] Task done\n"
            "  - Nested bullet\n\n"
            "1. First\n"
            "2. Second\n"
        )
        self.assertConverts(html, expected)

    def test_inline_styles(self) -> None:
        html = """
        <p>
          <strong>Bold</strong>
          <em>Italic</em>
          <u>Underline</u>
          <del>Strike</del>
          <span style="font-family: monospace">mono</span>
          <sup>sup</sup>
          <sub>sub</sub>
        </p>
        """
        expected = "**Bold** *Italic* _Underline_ ~~Strike~~ `mono` <sup>sup</sup> <sub>sub</sub>\n"
        self.assertConverts(html, expected)

    def test_links_and_images(self) -> None:
        html = """
        <p>
          <a href="https://example.com" title="Example">Example Link</a>
          <img src="https://img.example.com/pic.png" alt="Alt" title="Title" />
        </p>
        """
        expected = "[Example Link](https://example.com \"Example\") ![Alt](https://img.example.com/pic.png \"Title\")\n"
        self.assertConverts(html, expected)

    def test_table_alignment(self) -> None:
        html = """
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
        expected = (
            "| Left | Right | Center |\n"
            "| :--- | ---: | :---: |\n"
            "| One | Two | Three |\n"
        )
        self.assertConverts(html, expected)

    def test_horizontal_rule(self) -> None:
        html = "<div><p>Before</p><hr/><p>After</p></div>"
        expected = "Before\n\n---\n\nAfter\n"
        self.assertConverts(html, expected)
