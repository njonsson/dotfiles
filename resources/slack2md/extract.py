from __future__ import annotations

import datetime as dt
import re
from typing import Callable, Iterable, List, Optional
from urllib.parse import quote

from .html_nodes import Node, find_all, find_first, parse_html
from .model import Attachment, Message, Reaction
from .utils import (
    clean_text,
    decode_filename,
    ensure_at_prefix,
    flatten_user_list,
    iter_descendants,
    lookup_emoji,
    normalize_slack_href,
    parse_timestamp_from_node,
    strip_extension,
)


MESSAGE_DTYPE = "message"
SLACK_MESSAGE_PREFIX = "message-list_"
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tiff", ".svg"}


def looks_like_slack_file_href(href: str) -> bool:
    if not href:
        return False
    href_lower = href.lower()
    return "files.slack.com" in href_lower or "/files/" in href_lower or "/download/" in href_lower


def is_attachment_metadata_text(text: str) -> bool:
    normalized = clean_text(text or "").lower()
    if not normalized:
        return False
    return bool(re.fullmatch(r"\d+\s+files?", normalized))


def clone_without(node: Node, predicate: Callable[[Node], bool]) -> Optional[Node]:
    if predicate(node):
        return None
    if node.tag == "#text":
        data = node.data or ""
        if data.strip():
            return Node("#text", data=data)
        return None
    cloned = Node(node.tag, dict(node.attrs))
    for child in node.children:
        child_clone = clone_without(child, predicate)
        if child_clone is not None:
            cloned.append(child_clone)
    if cloned.children or node.tag in {"br"}:
        return cloned
    # Preserve nodes that carry meaningful inline text even if they have no children.
    if node.tag not in {"div", "span", "section"}:
        text_value = clean_text(node.text())
        if text_value:
            cloned_text = Node("#text", data=node.text())
            cloned.append(cloned_text)
            return cloned
    return None


def generate_candidate_handle(full_name: str) -> str:
    tokens = re.findall(r"[A-Za-z0-9]+", full_name)
    if not tokens:
        return "@unknown"
    first = tokens[0].lower()
    last = tokens[-1].lower()
    prefix = first[:2] if len(first) >= 2 else first
    suffix = last[:6] if len(last) >= 6 else last
    handle_core = (prefix + suffix) or first or last
    return f"@{handle_core}"


TIMESTAMP_PATTERN = re.compile(r"(?:^|[^0-9])(\d{10}(?:\.\d{1,9})?)(?:[^0-9]|$)")


def timestamp_from_attrs(node: Node) -> Optional[dt.datetime]:
    candidates: List[float] = []
    attrs_to_scan = [node.attrs.get("id", ""), node.attrs.get("aria-labelledby", "")]
    for value in attrs_to_scan:
        if not value:
            continue
        for match in TIMESTAMP_PATTERN.finditer(value):
            try:
                candidates.append(float(match.group(1)))
            except ValueError:
                continue
    if not candidates:
        return None
    ts_value = max(candidates)
    return dt.datetime.fromtimestamp(ts_value, dt.timezone.utc).astimezone()


def extract_header_components(
    message_node: Node,
) -> tuple[Optional[str], Optional[str], Optional[Node], Optional[Node]]:
    header_div: Optional[Node] = None
    time_pattern = re.compile(r"\[\d{1,2}:\d{2}\s*(?:[AP]M|[ap]\.m\.)\]")

    for candidate in iter_descendants(message_node, tag="div"):
        if candidate is message_node:
            continue
        text_nodes = [child.data or "" for child in candidate.children if child.tag == "#text"]
        header_text = clean_text("".join(text_nodes))
        if header_text and time_pattern.search(header_text):
            header_div = candidate
            break

    if header_div is None:
        return None, None, None, None

    prefix_parts: List[str] = []
    br_node: Optional[Node] = None
    for child in header_div.children:
        if child.tag == "br":
            br_node = child
            break
        fragment = child.data if child.tag == "#text" else child.text()
        if fragment:
            prefix_parts.append(fragment)

    header_text = clean_text("".join(prefix_parts))
    name_part: Optional[str] = None
    if header_text:
        if "[" in header_text and "]" in header_text:
            before, _, remainder = header_text.partition("[")
            name_candidate = clean_text(before)
            if name_candidate:
                name_part = name_candidate
        else:
            name_part = header_text
    return name_part or None, None, header_div, br_node


def gather_post_header_nodes(
    header_div: Optional[Node], br_node: Optional[Node], message_root: Node
) -> List[Node]:
    if br_node is None and header_div is None:
        return list(message_root.children)

    start_node: Optional[Node]
    if br_node is not None:
        start_node = br_node
    else:
        start_node = header_div

    if start_node is None:
        return list(message_root.children)

    result: List[Node] = []
    current: Optional[Node] = start_node
    while current is not None and current != message_root:
        parent = current.parent
        if parent is None:
            break
        index = parent.children.index(current)
        result.extend(parent.children[index + 1 :])
        current = parent
    return result


def is_attachment_node_for_clone(node: Node) -> bool:
    if node.tag == "a" and looks_like_slack_file_href(node.attrs.get("href", "")):
        return True
    class_attr = node.attrs.get("class", "")
    if class_attr and any(cls.startswith("wrapper__") for cls in class_attr.split()):
        return True
    if node.tag in {"div", "span"} and is_attachment_metadata_text(node.text()):
        return True
    return False


def node_has_visible_content(node: Node) -> bool:
    if node.tag == "#text":
        return bool(node.data and node.data.strip())
    if node.tag == "br":
        return True
    return any(node_has_visible_content(child) for child in node.children)


def prune_trailing_breaks(node: Node) -> None:
    while node.children:
        last = node.children[-1]
        if last.tag == "br" or (last.tag == "#text" and not (last.data or "").strip()):
            last.parent = None
            node.children.pop()
            continue
        break


def extract_display_name_from_link(link: Node) -> Optional[str]:
    def looks_like_filename(value: str) -> bool:
        if not value:
            return False
        if "." in value:
            return True
        return " " in value

    span_candidates = find_all(link, lambda n: n.tag == "span")
    for span in span_candidates:
        text = clean_text(span.text()).strip()
        if looks_like_filename(text):
            return text
    fallback = clean_text(link.text()).strip()
    if looks_like_filename(fallback):
        return fallback
    return fallback or None


def collect_attachments_from_nodes(
    nodes: List[Node], workspace_domain: Optional[str]
) -> List[Attachment]:
    attachments: List[Attachment] = []
    index_map: dict[str, tuple[int, int]] = {}

    for candidate in nodes:
        for link in find_all(candidate, lambda n: n.tag == "a" and looks_like_slack_file_href(n.attrs.get("href", ""))):
            href = link.attrs.get("href", "")
            if not href:
                continue
            normalized_href = normalize_slack_href(href, workspace_domain)
            filename = decode_filename(normalized_href or href)
            display_source = extract_display_name_from_link(link)
            extension = ""
            if "." in filename:
                extension = filename[filename.rfind(".") :].lower()

            display_filename: str
            if extension:
                if display_source:
                    lower_text = display_source.lower()
                    idx = lower_text.rfind(extension)
                    if idx != -1:
                        display_filename = display_source[: idx + len(extension)]
                    else:
                        display_filename = display_source
                else:
                    display_filename = filename.replace("_", " ")
            else:
                display_filename = (display_source or "").strip() or filename.replace("_", " ")

            display_filename = display_filename.strip() or filename.replace("_", " ")
            encoded_target = quote(display_filename)
            file_url = f"file://{encoded_target}"

            lower_name = display_filename.lower()
            img_node = find_first(link, lambda node: node.tag == "img" and node.attrs.get("src"))
            is_image = img_node is not None or any(lower_name.endswith(ext) for ext in IMAGE_EXTENSIONS)
            image_src = display_filename if is_image else None
            display_text = strip_extension(display_filename) if is_image else display_filename
            has_label = bool(display_source)
            if has_label:
                priority = 2
            elif "download" in href.lower():
                priority = 1
            else:
                priority = 0
            attachment = Attachment(
                url=file_url,
                display_text=display_text or strip_extension(filename),
                is_image=is_image,
                image_src=image_src,
                original_filename=display_filename or filename,
            )
            key = lower_name
            if key in index_map:
                index, existing_priority = index_map[key]
                if priority > existing_priority:
                    attachments[index] = attachment
                    index_map[key] = (index, priority)
            else:
                index_map[key] = (len(attachments), priority)
                attachments.append(attachment)
    return attachments


def collect_message_nodes(root: Node) -> List[Node]:
    message_list_nodes = [
        node for node in iter_descendants(root) if node.attrs.get("id", "").startswith(SLACK_MESSAGE_PREFIX)
    ]
    if message_list_nodes:
        return message_list_nodes
    direct = [child for child in root.children if child.attrs.get("data-stringify-type") == MESSAGE_DTYPE]
    if direct:
        return direct
    indirect = [node for node in iter_descendants(root) if node.attrs.get("data-stringify-type") == MESSAGE_DTYPE]
    if indirect:
        return indirect
    fallback = [child for child in root.children if child.tag == "div"]
    if fallback:
        return fallback
    return [root]


def extract_messages(root: Node, workspace_domain: Optional[str]) -> List[Message]:
    messages: List[Message] = []
    candidate_nodes = collect_message_nodes(root)

    if candidate_nodes and all(
        node.attrs.get("id", "").startswith(SLACK_MESSAGE_PREFIX) for node in candidate_nodes
    ):
        return extract_messages_from_message_lists(candidate_nodes, workspace_domain)

    for message_node in candidate_nodes:
        timestamp, raw_timestamp = extract_timestamp(message_node)
        author = extract_author(message_node)
        body_nodes = extract_body_nodes(message_node)
        reactions = extract_reactions(message_node)
        attachments = extract_attachments(message_node, workspace_domain)
        messages.append(
            Message(
                timestamp=timestamp,
                raw_timestamp=raw_timestamp,
                author=author,
                body_nodes=body_nodes,
                reactions=reactions,
                attachments=attachments,
            )
        )
    return messages


def extract_timestamp(message_node: Node) -> tuple[Optional[dt.datetime], Optional[str]]:
    ts_node = find_first(message_node, lambda node: node.attrs.get("data-stringify-type") == "timestamp")
    if ts_node:
        parsed, raw = parse_timestamp_from_node(ts_node)
        return parsed, raw
    parsed, raw = parse_timestamp_from_node(message_node)
    return parsed, raw


def extract_author(message_node: Node) -> str:
    author_node = find_first(
        message_node,
        lambda node: node.attrs.get("data-stringify-type") in {"user", "user_mention", "author"},
    )
    if author_node:
        author = clean_text(author_node.text())
        return ensure_at_prefix(author) if author else "@unknown"
    bold_node = find_first(message_node, lambda node: node.tag == "strong")
    if bold_node:
        author = clean_text(bold_node.text())
        return ensure_at_prefix(author) if author else "@unknown"
    return "@unknown"


def extract_body_nodes(message_node: Node) -> List[Node]:
    preferred_types = [
        "rich_text",
        "message-text",
        "text",
        "rich_text_section",
        "rich_text_list",
    ]
    for dtype in preferred_types:
        nodes = find_all(message_node, lambda node, dt=dtype: node.attrs.get("data-stringify-type") == dt)
        if nodes:
            return nodes
    paragraphs = find_all(message_node, lambda node: node.tag == "p")
    if paragraphs:
        return paragraphs
    return [message_node]


def extract_reactions(message_node: Node) -> List[Reaction]:
    reactions: List[Reaction] = []
    reaction_nodes = find_all(message_node, lambda node: node.attrs.get("data-stringify-type") == "reaction")
    for node in reaction_nodes:
        emoji_char = (node.attrs.get("data-emoji-unicode") or node.text()).strip()
        emoji_name = node.attrs.get("data-emoji-name", "")
        if not emoji_char and emoji_name:
            emoji_char = lookup_emoji(emoji_name) or f":{emoji_name.strip(':')}:"
        elif emoji_char and emoji_char.startswith(":") and emoji_char.endswith(":"):
            emoji_char = lookup_emoji(emoji_char) or emoji_char
        users_attr = node.attrs.get("data-emoji-users") or node.attrs.get("data-users")
        if users_attr:
            users = flatten_user_list(users_attr)
        else:
            aria = node.attrs.get("aria-label", "")
            if " by " in aria:
                _, tail = aria.rsplit(" by ", 1)
                users = flatten_user_list(tail)
            else:
                users = [ensure_at_prefix(clean_text(child.text())) for child in node.children if clean_text(child.text())]
        reactions.append(
            Reaction(
                emoji=emoji_char,
                users=[user for user in users if user],
            )
        )
    return reactions


def extract_attachments(message_node: Node, workspace_domain: Optional[str]) -> List[Attachment]:
    return collect_attachments_from_nodes([message_node], workspace_domain)


def parse_slack_html(html_text: str, workspace_domain: Optional[str]) -> List[Message]:
    root = parse_html(html_text)
    return extract_messages(root, workspace_domain)


def extract_messages_from_message_lists(
    containers: List[Node], workspace_domain: Optional[str]
) -> List[Message]:
    messages: List[Message] = []
    last_author_full: Optional[str] = None
    last_author_handle: Optional[str] = None

    for container in containers:
        timestamp = timestamp_from_attrs(container)
        message_node = find_first(container, lambda n: n.attrs.get("aria-roledescription") == "message") or container

        author_name, _, header_div, br_node = extract_header_components(message_node)
        post_nodes = gather_post_header_nodes(header_div, br_node, message_node)

        attachments = collect_attachments_from_nodes(post_nodes, workspace_domain)

        body_nodes: List[Node] = []
        margin_matches: List[Node] = []
        seen_margin: set[int] = set()
        for candidate in post_nodes:
            for match in find_all(
                candidate,
                lambda node: node.tag == "div" and "margin: 4px 0" in node.attrs.get("style", ""),
            ):
                marker = id(match)
                if marker not in seen_margin:
                    seen_margin.add(marker)
                    margin_matches.append(match)

        candidate_sources = margin_matches or post_nodes

        for candidate in candidate_sources:
            clone = clone_without(candidate, is_attachment_node_for_clone)
            if clone is not None:
                prune_trailing_breaks(clone)
                if node_has_visible_content(clone):
                    body_nodes.append(clone)

        if not body_nodes:
            fallback_clone = clone_without(message_node, is_attachment_node_for_clone)
            if fallback_clone is not None and node_has_visible_content(fallback_clone):
                body_nodes = [fallback_clone]

        full_name = clean_text(author_name or "") or last_author_full or "@unknown"
        canonical_handle = generate_candidate_handle(full_name)
        explicit_author = author_name is not None and author_name.strip() != ""

        if explicit_author:
            display_author = canonical_handle
        else:
            display_author = full_name if full_name != "@unknown" else canonical_handle

        last_author_full = full_name
        last_author_handle = canonical_handle

        messages.append(
            Message(
                timestamp=timestamp,
                raw_timestamp=None,
                author=display_author,
                body_nodes=body_nodes or [message_node],
                reactions=[],  # Reactions not present in this HTML variant
                attachments=attachments,
            )
        )

    return messages
