from __future__ import annotations

from html.parser import HTMLParser
from typing import Dict, List, Optional

from . import utils


class Node:
    __slots__ = ("node_type", "name", "attrs", "children", "text")

    def __init__(self, node_type: str, name: Optional[str] = None, attrs: Optional[Dict[str, str]] = None, text: str = "") -> None:
        self.node_type = node_type
        self.name = name.lower() if name else None
        self.attrs = attrs or {}
        self.children: List[Node] = []
        self.text = text

    def append(self, node: "Node") -> None:
        self.children.append(node)


VOID_ELEMENTS = {
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
}


class ConfluenceHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.root = Node("element", "document")
        self.stack: List[Node] = [self.root]

    def parse(self, html: str) -> Node:
        self.feed(html)
        self.close()
        return self.root

    def handle_starttag(self, tag: str, attrs: List[tuple[str, Optional[str]]]) -> None:
        name = tag.lower()
        attr_dict = {k.lower(): v or "" for k, v in attrs}
        node = Node("element", name, attr_dict)
        self.stack[-1].append(node)
        if name not in VOID_ELEMENTS:
            self.stack.append(node)

    def handle_endtag(self, tag: str) -> None:
        name = tag.lower()
        for index in range(len(self.stack) - 1, 0, -1):
            if self.stack[index].name == name:
                del self.stack[index:]
                break

    def handle_startendtag(self, tag: str, attrs: List[tuple[str, Optional[str]]]) -> None:
        self.handle_starttag(tag, attrs)

    def handle_data(self, data: str) -> None:
        if not data:
            return
        text = utils.unescape(data)
        if not text:
            return
        node = Node("text", text=text)
        self.stack[-1].append(node)

    def handle_entityref(self, name: str) -> None:
        self.handle_data(f"&{name};")

    def handle_charref(self, name: str) -> None:
        self.handle_data(f"&#{name};")


def parse_html(html: str) -> Node:
    parser = ConfluenceHTMLParser()
    return parser.parse(html)
