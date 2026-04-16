from __future__ import annotations

import html
import re
from dataclasses import dataclass
from typing import Iterable, List, Optional

NON_BREAKING_SPACE = "\u00a0"
BULLET_SEQUENCE = ("*", "-", "+")


@dataclass
class ListState:
    kind: str  # 'ul' or 'ol'
    depth: int
    counter: int = 0


def normalize_whitespace(value: str) -> str:
    if value is None:
        return ""
    value = value.replace("\r", " ").replace("\n", " ")
    value = value.replace(NON_BREAKING_SPACE, " ")
    if not value:
        return ""
    collapsed = re.sub(r"\s+", " ", value)
    if value[0].isspace() and collapsed and not collapsed.startswith(" "):
        collapsed = " " + collapsed
    if value[-1].isspace() and collapsed and not collapsed.endswith(" "):
        collapsed = collapsed + " "
    return collapsed


def escape_markdown(text: str) -> str:
    if not text:
        return ""
    replacements = {
        "\\": "\\\\",
        "*": r"\*",
        "_": r"\_",
        "[": r"\[",
        "]": r"\]",
        "(": r"\(",
        ")": r"\)",
        "#": r"\#",
        "+": r"\+",
        "-": r"\-",
        "!": r"\!",
        "|": r"\|",
    }
    result = []
    for char in text:
        result.append(replacements.get(char, char))
    return "".join(result)


def wrap_inline_code(text: str) -> str:
    text = text.replace("`", "\\`")
    return f"`{text}`"


def unescape(text: str) -> str:
    return html.unescape(text)


def bullet_for_depth(depth: int) -> str:
    return BULLET_SEQUENCE[depth % len(BULLET_SEQUENCE)]


def language_from_class(class_value: Optional[str]) -> Optional[str]:
    if not class_value:
        return None
    classes = class_value.split()
    for item in classes:
        if item.startswith("language-"):
            return item.partition("-")[2] or None
        if item.startswith("lang-"):
            return item.partition("-")[2] or None
    return None


def language_from_attrs(attrs: dict[str, str]) -> Optional[str]:
    language = language_from_class(attrs.get("class"))
    if language:
        return language
    data_language = attrs.get("data-language") or attrs.get("data-lang")
    if data_language:
        return data_language
    return None


def add_prefix_to_lines(text: str, first_prefix: str, other_prefix: str) -> str:
    lines = text.split("\n")
    if not lines:
        return first_prefix.rstrip()
    result: List[str] = []
    for index, line in enumerate(lines):
        prefix = first_prefix if index == 0 else other_prefix
        result.append(prefix + line)
    return "\n".join(result)


def strip_surrounding_blank_lines(value: str) -> str:
    lines = value.splitlines()
    start = 0
    while start < len(lines) and not lines[start].strip():
        start += 1
    end = len(lines) - 1
    while end >= 0 and not lines[end].strip():
        end -= 1
    if start > end:
        return ""
    return "\n".join(lines[start : end + 1])


def ensure_trailing_newline(text: str) -> str:
    if not text:
        return ""
    return text if text.endswith("\n") else text + "\n"


def text_content(nodes: Iterable["Node"], preserve: bool = False) -> str:  # type: ignore[name-defined]
    segments: List[str] = []
    for node in nodes:
        if node.node_type == "text":
            segments.append(node.text)
        elif node.node_type == "element":
            segments.append(text_content(node.children, preserve=preserve))
    combined = "".join(segments)
    return combined if preserve else normalize_whitespace(combined)


def detect_checkbox_state(attrs: dict[str, str]) -> Optional[str]:
    markers = [
        attrs.get("checked"),
        attrs.get("aria-checked"),
        attrs.get("data-checked"),
        attrs.get("value"),
    ]
    for marker in markers:
        if marker is None:
            continue
        normalized = marker.strip().lower()
        if normalized in {"true", "yes", "1", "on", "checked"}:
            return "x"
        if normalized in {"false", "no", "0", "off", "unchecked"}:
            return " "
    return None


def strip_trailing_whitespace_lines(lines: List[str]) -> List[str]:
    return [line.rstrip() for line in lines]


def hard_line_break() -> str:
    return "  \n"


class NodeProtocol:
    node_type: str
    name: Optional[str]
    attrs: dict[str, str]
    children: List["NodeProtocol"]
    text: str


Node = NodeProtocol
