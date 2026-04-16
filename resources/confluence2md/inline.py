from __future__ import annotations

from typing import Iterable, List

from . import html_parser, utils


def _style_matches(style_value: str, keyword: str) -> bool:
    if not style_value:
        return False
    return keyword in style_value.lower()


def _span_behaviors(node: html_parser.Node) -> dict[str, bool]:
    result = {
        "bold": False,
        "italic": False,
        "underline": False,
        "strike": False,
        "monospace": False,
        "sup": False,
        "sub": False,
    }
    style = node.attrs.get("style", "")
    classes = node.attrs.get("class", "")
    if _style_matches(style, "font-weight: bold") or "strong" in classes.split():
        result["bold"] = True
    if _style_matches(style, "font-style: italic") or "em" in classes.split():
        result["italic"] = True
    if _style_matches(style, "text-decoration: underline") or "underline" in classes.split():
        result["underline"] = True
    if _style_matches(style, "text-decoration: line-through") or "strike" in classes.split():
        result["strike"] = True
    if _style_matches(style, "font-family") and "monospace" in style.lower():
        result["monospace"] = True
    if _style_matches(style, "vertical-align: super"):
        result["sup"] = True
    if _style_matches(style, "vertical-align: sub"):
        result["sub"] = True
    if "code" in classes.split():
        result["monospace"] = True
    return result


def _apply_span_behaviors(text: str, behaviors: dict[str, bool]) -> str:
    if not text:
        return text
    if behaviors.get("sup"):
        return f"<sup>{text}</sup>"
    if behaviors.get("sub"):
        return f"<sub>{text}</sub>"
    if behaviors.get("monospace"):
        return utils.wrap_inline_code(text)
    if behaviors.get("bold"):
        text = f"**{text}**"
    if behaviors.get("italic"):
        text = f"*{text}*"
    if behaviors.get("underline"):
        text = f"_{text}_"
    if behaviors.get("strike"):
        text = f"~~{text}~~"
    return text


def render_inline(
    nodes: Iterable[html_parser.Node],
    preserve_soft_breaks: bool = False,
    within_code: bool = False,
) -> str:
    pieces: List[str] = []
    for node in nodes:
        if node.node_type == "text":
            text = node.text if preserve_soft_breaks or within_code else utils.normalize_whitespace(node.text)
            if not within_code:
                text = utils.escape_markdown(text)
            pieces.append(text)
            continue
        if node.node_type != "element":
            continue
        name = node.name or ""
        if name in {"strong", "b"}:
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            pieces.append(f"**{content}**")
        elif name in {"em", "i"}:
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            pieces.append(f"*{content}*")
        elif name in {"u", "ins"}:
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            pieces.append(f"_{content}_")
        elif name in {"s", "strike", "del"}:
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            pieces.append(f"~~{content}~~")
        elif name == "sup":
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            pieces.append(f"<sup>{content}</sup>")
        elif name == "sub":
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            pieces.append(f"<sub>{content}</sub>")
        elif name in {"code", "tt"}:
            raw = utils.text_content(node.children, preserve=True)
            text = raw.replace("`", "\\`")
            if "\n" in text:
                formatted = raw.replace("\r\n", "\n").strip("\n")
                pieces.append(formatted)
            else:
                pieces.append(utils.wrap_inline_code(text))
        elif name == "br":
            pieces.append(utils.hard_line_break())
        elif name == "span":
            behaviors = _span_behaviors(node)
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            pieces.append(_apply_span_behaviors(content, behaviors))
        elif name == "a":
            href = node.attrs.get("href", "").strip()
            title = node.attrs.get("title", "").strip()
            content = render_inline(node.children, preserve_soft_breaks, within_code)
            link_text = content.strip() or href.strip()
            if not link_text and not href:
                continue
            display_text = link_text or href
            link = f"[{display_text}]"
            if href:
                if title:
                    pieces.append(f"{link}({href} \"{title}\")")
                else:
                    pieces.append(f"{link}({href})")
            else:
                pieces.append(display_text)
        elif name == "img":
            alt = node.attrs.get("alt", "").strip()
            src = node.attrs.get("src", "").strip()
            title = node.attrs.get("title", "").strip()
            if not src:
                continue
            alt_text = utils.escape_markdown(alt)
            if title:
                pieces.append(f"![{alt_text}]({src} \"{title}\")")
            else:
                pieces.append(f"![{alt_text}]({src})")
        elif name in {"ac:image", "ac:link"}:
            # Confluence macro wrappers; render children.
            pieces.append(render_inline(node.children, preserve_soft_breaks, within_code))
        elif name == "ac:plain-text-link-body":
            pieces.append(render_inline(node.children, preserve_soft_breaks, within_code))
        elif name == "input":
            continue
        else:
            pieces.append(render_inline(node.children, preserve_soft_breaks, within_code))
    return "".join(pieces)
