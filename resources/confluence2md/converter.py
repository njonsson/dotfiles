from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterable, List, Optional

from . import html_parser, inline, tables, utils

INLINE_TAGS = {
    "a",
    "ac:link",
    "ac:image",
    "ac:plain-text-link-body",
    "b",
    "br",
    "button",
    "code",
    "del",
    "em",
    "i",
    "img",
    "ins",
    "span",
    "strong",
    "sub",
    "sup",
    "s",
    "strike",
    "tt",
    "u",
    "var",
}

BLOCK_CONTAINER_TAGS = {
    "div",
    "section",
    "article",
    "nav",
    "main",
    "body",
    "figure",
    "figcaption",
    "header",
    "footer",
    "ac:layout",
    "ac:layout-section",
    "ac:layout-cell",
    "ac:rich-text-body",
    "ac:structured-macro",
    "ac:macro",
}


@dataclass
class RenderContext:
    blockquote_depth: int = 0
    list_stack: List[utils.ListState] = field(default_factory=list)


def convert(html: str) -> str:
    root = html_parser.parse_html(html)
    ctx = RenderContext()
    blocks = _render_children_as_blocks(root.children, ctx)
    filtered = [block for block in blocks if block.strip()]
    if not filtered:
        return ""
    return "\n\n".join(filtered).rstrip() + "\n"


def _render_children_as_blocks(nodes: Iterable[html_parser.Node], ctx: RenderContext) -> List[str]:
    blocks: List[str] = []
    inline_buffer: List[html_parser.Node] = []
    for node in nodes:
        if node.node_type == "text" and not node.text.strip():
            continue
        if _is_inline_node(node):
            inline_buffer.append(node)
            continue
        if inline_buffer:
            paragraph = inline.render_inline(inline_buffer)
            inline_buffer.clear()
            if paragraph.strip():
                blocks.append(_apply_blockquote(ctx.blockquote_depth, paragraph.strip()))
        blocks.extend(_render_block_node(node, ctx))
    if inline_buffer:
        paragraph = inline.render_inline(inline_buffer)
        if paragraph.strip():
            blocks.append(_apply_blockquote(ctx.blockquote_depth, paragraph.strip()))
    return blocks


def _is_inline_node(node: html_parser.Node) -> bool:
    if node.node_type == "text":
        return True
    if node.node_type != "element":
        return False
    if node.name in INLINE_TAGS:
        return True
    if node.name == "span":
        return True
    if node.name == "ac:link-body":
        return True
    return False


def _render_block_node(node: html_parser.Node, ctx: RenderContext) -> List[str]:
    if node.node_type == "text":
        text = inline.render_inline([node])
        if text.strip():
            return [_apply_blockquote(ctx.blockquote_depth, text.strip())]
        return []
    if node.node_type != "element":
        return []
    name = node.name or ""
    if name in {"p", "label"}:
        text = inline.render_inline(node.children)
        if text.strip():
            return [_apply_blockquote(ctx.blockquote_depth, text.strip())]
        return []
    if name in BLOCK_CONTAINER_TAGS:
        inner_blocks = _render_children_as_blocks(node.children, ctx)
        if inner_blocks:
            return inner_blocks
        macro_name = node.attrs.get("ac:name") or node.attrs.get("name")
        if macro_name:
            return [_apply_blockquote(ctx.blockquote_depth, f"<!-- Unsupported macro: {macro_name} -->")]
        return []
    if name in {"h1", "h2", "h3", "h4", "h5", "h6"}:
        level = int(name[1])
        text = inline.render_inline(node.children).strip()
        if not text:
            return []
        heading = "#" * level + " " + text
        return [_apply_blockquote(ctx.blockquote_depth, heading)]
    if name in {"pre", "code", "tt"}:
        return [_render_code_block(node, ctx)]
    if name == "blockquote":
        ctx.blockquote_depth += 1
        try:
            return _render_children_as_blocks(node.children, ctx)
        finally:
            ctx.blockquote_depth -= 1
    if name == "ul":
        text = _render_list(node, ctx, "ul")
        return [_apply_blockquote(ctx.blockquote_depth, text)] if text.strip() else []
    if name == "ol":
        text = _render_list(node, ctx, "ol")
        return [_apply_blockquote(ctx.blockquote_depth, text)] if text.strip() else []
    if name == "li":
        ctx.list_stack.append(utils.ListState(kind="ul", depth=len(ctx.list_stack)))
        try:
            lines = _render_list_item(node, ctx)
        finally:
            ctx.list_stack.pop()
        if lines:
            return ["\n".join(lines)]
        return []
    if name == "hr":
        return [_apply_blockquote(ctx.blockquote_depth, "---")]
    if name == "table":
        table_md = tables.render_table(node)
        if table_md:
            return [_apply_blockquote(ctx.blockquote_depth, table_md)]
        return []
    if name == "br":
        return [_apply_blockquote(ctx.blockquote_depth, utils.hard_line_break())]
    return _render_children_as_blocks(node.children, ctx)


def _render_code_block(node: html_parser.Node, ctx: RenderContext) -> str:
    language = utils.language_from_attrs(node.attrs)
    text = utils.text_content(node.children, preserve=True) if node.children else node.text or ""
    if node.name == "pre":
        for child in node.children:
            if child.node_type == "element" and child.name in {"code", "tt"}:
                inner_text = utils.text_content(child.children, preserve=True)
                if inner_text:
                    text = inner_text
                inner_language = utils.language_from_attrs(child.attrs)
                if inner_language:
                    language = inner_language
    text = (text or "").replace("\r\n", "\n")
    if "\n" in text or node.name == "pre":
        body = text.strip("\n")
        fence = "```" + (language or "")
        closing = "```"
        content = f"{fence}\n{body}\n{closing}"
        return _apply_blockquote(ctx.blockquote_depth, content)
    inline_code = utils.wrap_inline_code(text.strip())
    return _apply_blockquote(ctx.blockquote_depth, inline_code)


def _render_list(node: html_parser.Node, ctx: RenderContext, kind: str) -> str:
    state = utils.ListState(kind=kind, depth=len(ctx.list_stack))
    ctx.list_stack.append(state)
    try:
        lines: List[str] = []
        for child in node.children:
            if child.node_type == "element" and child.name == "li":
                item_lines = _render_list_item(child, ctx)
                if item_lines:
                    lines.extend(item_lines)
        return "\n".join(lines)
    finally:
        ctx.list_stack.pop()


def _render_list_item(node: html_parser.Node, ctx: RenderContext) -> List[str]:
    if not ctx.list_stack:
        ctx.list_stack.append(utils.ListState(kind="ul", depth=0))
    state = ctx.list_stack[-1]
    if state.kind == "ol":
        state.counter += 1
        marker = f"{state.counter}."
        indent = "   " * state.depth
    else:
        marker = utils.bullet_for_depth(state.depth)
        indent = "  " * state.depth
    checkbox = _find_checkbox_state(node)
    marker_text = f"{marker} [{checkbox}]" if checkbox is not None else marker
    segments = _split_list_item_segments(node)
    rendered_segments: List[tuple[str, List[str], Optional[html_parser.Node]]] = []
    for segment_type, payload in segments:
        if segment_type == "inline":
            text = inline.render_inline(payload).strip()
            if text:
                rendered_segments.append(("inline", text.split("\n"), None))
        else:
            block_node = payload
            for block in _render_block_node(payload, ctx):
                if block.strip():
                    rendered_segments.append(("block", block.split("\n"), block_node))
    lines: List[str] = []
    prefix = f"{indent}{marker_text}"
    continuation = " " * (len(prefix) + 1)
    remaining = rendered_segments
    if rendered_segments and rendered_segments[0][0] == "inline":
        first_lines = rendered_segments[0][1]
        remaining = rendered_segments[1:]
        lines.append(f"{prefix} {first_lines[0]}".rstrip())
        for extra in first_lines[1:]:
            lines.append((continuation + extra).rstrip())
    else:
        lines.append(prefix)
    for seg_type, seg_lines, seg_node in remaining:
        if seg_type == "block" and seg_node is not None and seg_node.name in {"ul", "ol"}:
            lines.extend(seg_lines)
        else:
            for line in seg_lines:
                lines.append((continuation + line).rstrip())
    return lines


def _split_list_item_segments(node: html_parser.Node) -> List[tuple[str, List[html_parser.Node] | html_parser.Node]]:
    segments: List[tuple[str, List[html_parser.Node] | html_parser.Node]] = []
    inline_buffer: List[html_parser.Node] = []
    for child in node.children:
        if _is_inline_node(child) or (child.node_type == "element" and child.name in {"p", "label", "span"}):
            inline_buffer.append(child)
            continue
        if inline_buffer:
            segments.append(("inline", inline_buffer[:]))
            inline_buffer.clear()
        if child.node_type == "element":
            segments.append(("block", child))
    if inline_buffer:
        segments.append(("inline", inline_buffer))
    return segments


def _find_checkbox_state(node: html_parser.Node) -> Optional[str]:
    if node.node_type == "element":
        state = utils.detect_checkbox_state(node.attrs)
        if state is not None:
            return state
        if node.name == "input" and node.attrs.get("type", "").lower() == "checkbox":
            if "checked" in node.attrs or node.attrs.get("value", "").lower() in {"true", "on"}:
                return "x"
            return " "
        for child in node.children:
            child_state = _find_checkbox_state(child)
            if child_state is not None:
                return child_state
    return None


def _apply_blockquote(depth: int, text: str) -> str:
    if depth <= 0:
        return text
    tokens = [">" for _ in range(depth)]
    prefix = " ".join(tokens)
    lines = text.split("\n")
    result: List[str] = []
    for line in lines:
        if line.strip():
            result.append(f"{prefix} {line}")
        else:
            result.append(prefix)
    return "\n".join(result)
