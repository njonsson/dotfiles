from __future__ import annotations

import argparse
import sys
from typing import List, Optional

from .converter import convert
from .utils import normalize_workspace_domain


USAGE_DETAILS = """\
slack2md consumes Slack clipboard HTML on stdin and streams Markdown to stdout.

Typical workflow (macOS):
  `pbpaste-html | slack2md`

The converter preserves Slack rich text (lists, block quotes, code blocks,
inline formatting) and emits message metadata in the following layout:

  *15 Apr 2026 8:52 p.m.*  
  **@nijonsso:** The quick, brown fox jumped over the lazy dog.  
  `🦊 @janejones, @johnsmith`

Reactions render as code spans on the lines immediately following the message,
attachments appear in their own paragraphs, and image/file links are wrapped in
italic text pointing at the original file:// target.

Use --workspace-domain when Slack generates relative channel or message links
and you want them promoted to fully-qualified https:// URLs.
"""


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="slack2md",
        description="Convert Slack clipboard HTML into Markdown.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=USAGE_DETAILS,
    )
    parser.add_argument(
        "--workspace-domain",
        dest="workspace_domain",
        default=None,
        help="Slack workspace domain used to expand relative links (e.g. myteam.slack.com).",
    )
    return parser


def read_input(args: argparse.Namespace) -> str:
    stdin = sys.stdin
    if stdin.isatty():
        raise RuntimeError("no stdin data provided; try `pbpaste-html | slack2md`")
    return stdin.read()


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        html_text = read_input(args)
    except RuntimeError as exc:
        if "no stdin data provided" in str(exc):
            parser.print_usage(sys.stderr)
        print(f"slack2md: {exc}", file=sys.stderr)
        return 1
    if not html_text.strip():
        print("slack2md: no HTML content to convert", file=sys.stderr)
        return 1
    workspace_domain = normalize_workspace_domain(args.workspace_domain)
    markdown = convert(html_text, workspace_domain)
    print(markdown)
    return 0
