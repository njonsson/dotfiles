from __future__ import annotations

import argparse
import subprocess
import sys
from typing import List, Optional

from converter import convert
from utils import normalize_workspace_domain


USAGE_DETAILS = """\
slack2md consumes Slack clipboard HTML on stdin and streams Markdown to stdout.

Typical workflow (macOS):
  slack2md --clipboard

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
    parser.add_argument(
        "--clipboard",
        action="store_true",
        help="Fetch HTML from the macOS clipboard using osascript + perl when stdin is empty.",
    )
    return parser


def read_clipboard_html() -> str:
    osa_cmd = ["osascript", "-e", "the clipboard as «class HTML»"]
    try:
        osa_result = subprocess.run(
            osa_cmd,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError as exc:  # pragma: no cover - system dependent
        raise RuntimeError("osascript command not found; --clipboard requires macOS.") from exc
    if osa_result.returncode != 0:
        raise RuntimeError(
            f"osascript failed (exit {osa_result.returncode}): {osa_result.stderr.strip()}"
        )
    perl_cmd = [
        "perl",
        "-ne",
        'print chr foreach unpack("C*",pack("H*",substr($_,11,-3)))',
    ]
    try:
        perl_result = subprocess.run(
            perl_cmd,
            input=osa_result.stdout,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError as exc:  # pragma: no cover - system dependent
        raise RuntimeError("perl command not found; --clipboard requires perl on PATH.") from exc
    if perl_result.returncode != 0:
        raise RuntimeError(
            f"perl clipboard decoder failed (exit {perl_result.returncode}): {perl_result.stderr.strip()}"
        )
    return perl_result.stdout


def read_input(args: argparse.Namespace) -> str:
    if args.clipboard:
        return read_clipboard_html()
    if sys.stdin.isatty():
        raise RuntimeError("no stdin data provided")
    data = sys.stdin.read()
    if data.strip():
        return data
    return data


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        html_text = read_input(args)
    except RuntimeError as exc:
        if str(exc) == "no stdin data provided":
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
