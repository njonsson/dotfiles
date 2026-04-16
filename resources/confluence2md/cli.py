from __future__ import annotations

import argparse
import sys
from typing import List, Optional

from .converter import convert


USAGE_DETAILS = """\
confluence2md consumes Confluence clipboard HTML on stdin and streams Markdown to stdout.

Typical workflow (macOS):
  `pbpaste-html | confluence2md`

Key conversions:
  • Paragraphs and line breaks → Markdown paragraphs and hard line breaks
  • Headings <h1>-<h6> → # through ###### headings
  • <pre>, <code>, <tt> → fenced or inline code depending on line breaks
  • Nested block quotes → repeated > prefixes
  • Ordered / unordered / task lists → Markdown lists (supports checkboxes)
  • Images and links → Markdown image/link syntax with titles when present
  • Tables → pipe tables with alignment markers
  • <hr> → ---

stdin is used by default. When running interactively, pipe clipboard HTML using
`pbpaste-html | confluence2md`.
"""


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="confluence2md",
        description="Convert Confluence clipboard HTML into Markdown.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=USAGE_DETAILS,
    )
    return parser


def read_input(args: argparse.Namespace) -> str:
    stdin = sys.stdin
    if stdin.isatty():
        raise RuntimeError("no stdin data provided; try `pbpaste-html | confluence2md`")
    return stdin.read()


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        html_text = read_input(args)
    except RuntimeError as exc:
        if "no stdin data provided" in str(exc):
            parser.print_usage(sys.stderr)
        print(f"confluence2md: {exc}", file=sys.stderr)
        return 1
    if not html_text.strip():
        print("confluence2md: no HTML content to convert", file=sys.stderr)
        return 1
    markdown = convert(html_text)
    print(markdown, end="")
    return 0
