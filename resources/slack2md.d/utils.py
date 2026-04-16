from __future__ import annotations

import datetime as dt
import json
import unicodedata
from typing import Iterable, Optional
from urllib.parse import unquote, urlparse

from html import unescape

from html_nodes import Node, iter_nodes


NBSP = "\u00A0"


def clean_text(value: str | None) -> str:
    if not value:
        return ""
    value = unescape(value)
    value = value.replace("\ufeff", "").replace("\u200b", "")
    result: list[str] = []
    pending_space = False
    for ch in value:
        if ch == NBSP:
            if pending_space:
                result.append(" ")
                pending_space = False
            result.append(NBSP)
            continue
        if ch in {" ", "\t", "\r", "\n", "\f", "\v"}:
            pending_space = True
            continue
        if pending_space:
            result.append(" ")
            pending_space = False
        result.append(ch)
    if pending_space:
        result.append(" ")
    cleaned = "".join(result)
    cleaned = cleaned.strip(" ")
    cleaned = cleaned.lstrip(NBSP).rstrip(NBSP)
    return cleaned


def normalize_workspace_domain(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    candidate = value if value.startswith("https://") else f"https://{value}"
    parsed = urlparse(candidate)
    return parsed.netloc or None


def normalize_slack_href(href: str, workspace_domain: Optional[str]) -> str:
    if not href:
        return href
    parsed = urlparse(href)
    if parsed.scheme in {"http", "https", "file"}:
        return href
    if parsed.scheme == "slack" and workspace_domain:
        if parsed.netloc == "channel" and parsed.path:
            return f"https://{workspace_domain}{parsed.path}"
        if parsed.netloc == "message" and parsed.path:
            return f"https://{workspace_domain}{parsed.path}"
    if not parsed.scheme and href.startswith("/") and workspace_domain:
        return f"https://{workspace_domain}{href}"
    return href


def try_parse_json(value: str) -> Optional[object]:
    try:
        return json.loads(value)
    except Exception:
        return None


def parse_timestamp_value(value: str) -> Optional[dt.datetime]:
    if not value:
        return None
    value = value.strip()
    if not value:
        return None
    numeric = value.replace(".", "", 1)
    if numeric.isdigit():
        try:
            epoch = float(value)
        except ValueError:
            epoch = None
        if epoch is not None:
            return dt.datetime.fromtimestamp(epoch, dt.timezone.utc).astimezone()
    iso_formats = [
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S.%f",
        "%Y-%m-%dT%H:%M:%S",
    ]
    for fmt in iso_formats:
        try:
            parsed = dt.datetime.strptime(value, fmt)
        except ValueError:
            continue
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=dt.timezone.utc)
        return parsed.astimezone()
    human_formats = [
        "%b %d, %Y %I:%M %p",
        "%B %d, %Y %I:%M %p",
        "%d %b %Y %I:%M %p",
        "%Y-%m-%d %H:%M",
        "%I:%M %p",
    ]
    for fmt in human_formats:
        try:
            parsed = dt.datetime.strptime(value, fmt)
        except ValueError:
            continue
        if fmt == "%I:%M %p":
            today = dt.datetime.now().astimezone()
            parsed = parsed.replace(year=today.year, month=today.month, day=today.day)
        return parsed.replace(tzinfo=dt.timezone.utc).astimezone()
    return None


def parse_timestamp_from_node(node: Node) -> tuple[Optional[dt.datetime], Optional[str]]:
    attr_keys = [
        "data-stringify-payload",
        "data-stringify-meta",
        "data-ts",
        "data-time",
        "data-timestamp",
        "data-qa-preview-ts",
        "data-slate-timestamp",
        "datetime",
        "title",
        "aria-label",
    ]
    for key in attr_keys:
        raw = node.attrs.get(key)
        if not raw:
            continue
        if key == "data-stringify-meta":
            payload = try_parse_json(raw)
            if isinstance(payload, dict) and payload.get("timestamp"):
                candidate = str(payload["timestamp"])
                parsed = parse_timestamp_value(candidate)
                if parsed:
                    return parsed, candidate
            continue
        parsed = parse_timestamp_value(raw)
        if parsed:
            return parsed, raw
    text = clean_text(node.text())
    if text:
        parsed = parse_timestamp_value(text)
        if parsed:
            return parsed, text
    return None, text or None


def decode_filename(url: str) -> str:
    parsed = urlparse(url)
    target = parsed.path or url
    return unquote(target.rsplit("/", 1)[-1])


def strip_extension(name: str) -> str:
    if "." not in name:
        return name
    return name[: name.rfind(".")]


def ensure_at_prefix(user: str) -> str:
    user = user.strip()
    if not user:
        return user
    return user if user.startswith("@") else f"@{user}"


def flatten_user_list(text: str) -> list[str]:
    if not text:
        return []
    parts = [part.strip() for part in text.replace(" and ", ",").split(",")]
    return [ensure_at_prefix(part) for part in parts if part]


def lookup_emoji(name: str) -> Optional[str]:
    slug = name.strip(":").replace("_", " ").upper()
    if not slug:
        return None
    try:
        return unicodedata.lookup(slug)
    except KeyError:
        return None


def escape_markdown(text: str) -> str:
    replacements = {
        "\\": r"\\",
        "*": r"\*",
        "_": r"\_",
        "`": r"\`",
        "[": r"\[",
        "]": r"\]",
    }
    return "".join(replacements.get(ch, ch) for ch in text)


def iter_descendants(
    node: Node,
    *,
    tag: Optional[str] = None,
    dtype: Optional[Iterable[str]] = None,
) -> Iterable[Node]:
    dtype_set = set(dtype) if dtype is not None else None
    for candidate in iter_nodes(node):
        if tag is not None and candidate.tag != tag:
            continue
        if dtype_set is not None:
            dtype_value = candidate.attrs.get("data-stringify-type")
            if dtype_value not in dtype_set:
                continue
        yield candidate
