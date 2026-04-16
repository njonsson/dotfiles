from __future__ import annotations

import datetime as dt
from html import unescape
from typing import Iterable, List, Optional

from html_nodes import Node
from model import Attachment, Message, Reaction
from utils import (
    clean_text,
    escape_markdown,
    normalize_slack_href,
)

INLINE_TAGS = {
    "span",
    "strong",
    "b",
    "em",
    "i",
    "u",
    "s",
    "strike",
    "code",
    "a",
}


def format_timestamp(dt_value: Optional[dt.datetime], fallback: Optional[str]) -> str:
    if dt_value is None:
        return fallback.strip() if fallback else ""
    local = dt_value.astimezone()
    local = (local + dt.timedelta(seconds=30)).replace(second=0, microsecond=0)
    hour = local.strftime("%I").lstrip("0") or "0"
    minute = local.strftime("%M")
    ampm = local.strftime("%p").lower().replace("am", "a.m.").replace("pm", "p.m.")
    month = local.strftime("%b")
    day = str(local.day)
    year = local.strftime("%Y")
    return f"{day} {month} {year} {hour}:{minute} {ampm}"


def render_inline(node: Node, workspace_domain: Optional[str]) -> str:
    if node.tag == "#text":
        text = unescape(node.data or "")
        return escape_markdown(text)
    if node.tag == "br":
        return "\n"
    dtype = node.attrs.get("data-stringify-type")
    if dtype == "emoji":
        emoji_char = (node.attrs.get("data-emoji-unicode") or node.text()).strip()
        if emoji_char:
            return emoji_char
        name = node.attrs.get("data-emoji-name", "")
        return name if name.startswith(":") else f":{name.strip(':')}:"
    if node.tag in {"strong", "b"}:
        return f"**{''.join(render_inline(child, workspace_domain) for child in node.children)}**"
    if node.tag in {"em", "i"}:
        return f"*{''.join(render_inline(child, workspace_domain) for child in node.children)}*"
    if node.tag in {"del", "s", "strike"}:
        return f"~~{''.join(render_inline(child, workspace_domain) for child in node.children)}~~"
    if node.tag == "code":
        inner = "".join(render_inline(child, workspace_domain) for child in node.children)
        if "`" in inner:
            return f"``{inner}``"
        return f"`{inner}`"
    if node.tag == "span" and dtype in {"user", "user_mention", "mention"}:
        mention = clean_text(node.text())
        if mention and not mention.startswith("@"):
            mention = f"@{mention}"
        return mention
    if node.tag == "u":
        inner = "".join(render_inline(child, workspace_domain) for child in node.children)
        return f"<u>{inner}</u>"
    if node.tag == "a":
        href = normalize_slack_href(node.attrs.get("href", ""), workspace_domain)
        label = "".join(render_inline(child, workspace_domain) for child in node.children) or href
        return f"[{label}]({href})"
    return "".join(render_inline(child, workspace_domain) for child in node.children)


def render_block(
    node: Node,
    workspace_domain: Optional[str],
    list_state: Optional[dict] = None,
) -> List[str]:
    if node.tag == "#text":
        text_value = unescape(node.data or "")
        if not text_value.strip():
            return []
        return [escape_markdown(text_value)]
    dtype = node.attrs.get("data-stringify-type")
    if node.tag in {"div", "span", "section"} and dtype not in {"rich_text_preformatted"}:
        if all(
            child.tag in INLINE_TAGS or child.tag == "#text" or child.tag == "br"
            for child in node.children
        ):
            return ["".join(render_inline(child, workspace_domain) for child in node.children)]
        lines: List[str] = []
        for child in node.children:
            lines.extend(render_block(child, workspace_domain, list_state))
        return lines
    if node.tag == "p" or dtype in {"rich_text", "rich_text_section"}:
        return ["".join(render_inline(child, workspace_domain) for child in node.children)]
    if node.tag == "br":
        return [""]
    if node.tag in {"ul", "ol"}:
        ordered = node.tag == "ol"
        lines: List[str] = []
        index = 1
        for child in node.children:
            if child.tag != "li":
                continue
            child_state = {"ordered": ordered, "index": index}
            lines.extend(render_block(child, workspace_domain, child_state))
            index += 1
        return lines
    if node.tag == "li":
        ordered = (list_state or {}).get("ordered", False)
        index = (list_state or {}).get("index", 1)
        bullet = f"{index}. " if ordered else "- "
        content_lines: List[str] = []
        for child in node.children:
            content_lines.extend(render_block(child, workspace_domain, list_state))
        if not content_lines:
            return [bullet.rstrip()]
        first, *rest = content_lines
        lines = [f"{bullet}{first}"]
        indent = " " * len(bullet)
        for line in rest:
            lines.append(f"{indent}{line}")
        return lines
    if node.tag == "blockquote":
        inner_lines: List[str] = []
        for child in node.children:
            inner_lines.extend(render_block(child, workspace_domain, list_state))
        return [f"> {line}" if line else ">" for line in inner_lines]
    if node.tag == "pre" or dtype == "rich_text_preformatted":
        text = "".join(
            (unescape(child.data or "") if child.tag == "#text" else child.text())
            for child in node.children
        )
        text = unescape(text)
        lines = ["```"]
        lines.extend(text.splitlines())
        lines.append("```")
        return lines
    return [render_inline(node, workspace_domain)]


def render_blocks(nodes: Iterable[Node], workspace_domain: Optional[str]) -> List[str]:
    lines: List[str] = []
    for node in nodes:
        lines.extend(render_block(node, workspace_domain))
    collapsed: List[str] = []
    previous_blank = False
    for line in lines:
        is_blank = not line.strip()
        if is_blank and previous_blank:
            continue
        collapsed.append(line)
        previous_blank = is_blank
    return collapsed


def render_reactions(reactions: List[Reaction]) -> List[str]:
    lines: List[str] = []
    total = len(reactions)
    for idx, reaction in enumerate(reactions):
        emoji = reaction.emoji.strip()
        users = ", ".join(reaction.users) if reaction.users else ""
        payload = emoji
        if emoji and users:
            payload = f"{emoji} {users}"
        elif users:
            payload = users
        suffix = "  " if idx < total - 1 else ""
        lines.append(f"`{payload}`{suffix}")
    return lines


def render_attachment(attachment: Attachment) -> str:
    target = attachment.url
    if attachment.is_image:
        alt_text = escape_markdown(attachment.display_text or "")
        image_src = attachment.image_src or attachment.original_filename or target
        image_label = f"![{alt_text}]({escape_markdown(image_src)})"
        return f"*[{image_label}]({target})*"
    link_text = escape_markdown(attachment.display_text or "")
    return f"[*{link_text}*]({target})"


def render_attachments(attachments: List[Attachment]) -> List[str]:
    return [render_attachment(attachment) for attachment in attachments]


def render_attachment_fallback(attachment: Attachment) -> str:
    target = attachment.url
    if attachment.is_image:
        alt_text = escape_markdown(attachment.display_text or "")
        image_src = escape_markdown(attachment.image_src or attachment.original_filename or "")
        return f"[![{alt_text}]({image_src})]({target})"
    link_text = escape_markdown(attachment.display_text or "")
    return f"[*{link_text}*]({target})"


def render_attachment_fallbacks(attachments: List[Attachment]) -> List[str]:
    return [render_attachment_fallback(attachment) for attachment in attachments]


def build_message_markdown(message: Message, workspace_domain: Optional[str]) -> str:
    timestamp_text = format_timestamp(message.timestamp, message.raw_timestamp)
    output_lines: List[str] = []
    if timestamp_text:
        output_lines.append(f"*{timestamp_text}*  ")
    if message.author.startswith("@") or " " in message.author:
        author = message.author
    else:
        author = f"@{message.author}"
    body_lines = render_blocks(message.body_nodes, workspace_domain)

    def append_with_breaks(text: str, *, include_prefix: bool) -> None:
        segments = text.split("\n")
        first_segment = True
        for segment in segments:
            content = segment
            if include_prefix and first_segment:
                line_text = f"**{author}:** {content}" if content else f"**{author}:**"
            else:
                line_text = content
            if line_text.strip():
                output_lines.append(f"{line_text}  ")
            else:
                output_lines.append("")
            first_segment = False

    if body_lines:
        first, *rest = body_lines
        append_with_breaks(first, include_prefix=True)
        for line in rest:
            append_with_breaks(line, include_prefix=False)
    else:
        output_lines.append(f"**{author}:**  ")
    reaction_lines = render_reactions(message.reactions)
    if reaction_lines:
        output_lines.extend(reaction_lines)
    attachment_lines = render_attachments(message.attachments)
    if attachment_lines:
        if output_lines and output_lines[-1]:
            output_lines.append("")
        output_lines.extend(attachment_lines)
    if output_lines and output_lines[-1].endswith("  "):
        output_lines[-1] = output_lines[-1][:-2]
    return "\n".join(output_lines)
