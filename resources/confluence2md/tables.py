from __future__ import annotations

import re
from dataclasses import dataclass
from typing import List, Optional

from . import html_parser, inline

ALIGN_RE = re.compile(r"text-align\s*:\s*(left|right|center)", re.IGNORECASE)


@dataclass
class TableCell:
    text: str
    align: Optional[str]
    is_header: bool = False


@dataclass
class TableRow:
    cells: List[TableCell]
    is_header: bool = False


def _extract_alignment(attrs: dict[str, str]) -> Optional[str]:
    align = attrs.get("align", "").strip().lower()
    if align in {"left", "right", "center"}:
        return align
    style = attrs.get("style", "")
    match = ALIGN_RE.search(style)
    if match:
        return match.group(1).lower()
    return None


def _render_cell_text(cell: html_parser.Node) -> str:
    text = inline.render_inline(cell.children, preserve_soft_breaks=True)
    text = text.strip()
    return text.replace("\n", "<br>")


def _collect_rows(parent: html_parser.Node) -> List[TableRow]:
    rows: List[TableRow] = []
    for child in parent.children:
        if child.node_type != "element":
            continue
        if child.name == "tr":
            cells: List[TableCell] = []
            is_header = False
            for cell in child.children:
                if cell.node_type != "element":
                    continue
                if cell.name not in {"td", "th"}:
                    continue
                text = _render_cell_text(cell)
                align = _extract_alignment(cell.attrs)
                header = cell.name == "th"
                if header:
                    is_header = True
                cells.append(TableCell(text, align, header))
            if cells:
                rows.append(TableRow(cells, is_header))
        elif child.name in {"thead", "tbody", "tfoot"}:
            rows.extend(_collect_rows(child))
    return rows


def _alignment_marker(alignment: Optional[str]) -> str:
    if alignment == "left":
        return ":---"
    if alignment == "right":
        return "---:"
    if alignment == "center":
        return ":---:"
    return "---"


def render_table(table_node: html_parser.Node) -> str:
    rows = _collect_rows(table_node)
    if not rows:
        return ""
    column_count = max(len(row.cells) for row in rows)
    header_index = next((index for index, row in enumerate(rows) if row.is_header), None)
    alignments: List[Optional[str]] = [None] * column_count
    for row in rows:
        for index, cell in enumerate(row.cells):
            if index >= column_count:
                continue
            if cell.align and not alignments[index]:
                alignments[index] = cell.align
    if header_index is not None:
        header_row = rows[header_index]
        header_cells = [cell.text for cell in header_row.cells]
        header_cells.extend([""] * (column_count - len(header_cells)))
    else:
        header_cells = ["" for _ in range(column_count)]
    header_line = "| " + " | ".join(header_cells[:column_count]) + " |"
    marker_line = "| " + " | ".join(_alignment_marker(alignments[i]) for i in range(column_count)) + " |"
    body_lines: List[str] = []
    for index, row in enumerate(rows):
        if header_index is not None and index == header_index:
            continue
        cells = [cell.text for cell in row.cells]
        cells.extend([""] * (column_count - len(cells)))
        body_lines.append("| " + " | ".join(cells[:column_count]) + " |")
    return "\n".join([header_line, marker_line] + body_lines)
