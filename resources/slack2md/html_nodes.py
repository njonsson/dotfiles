from __future__ import annotations

from html.parser import HTMLParser
from typing import Callable, Iterable, Iterator, Optional


class Node:
    """Lightweight DOM node representing Slack clipboard HTML."""

    __slots__ = ("tag", "attrs", "children", "data", "parent")

    def __init__(
        self,
        tag: str,
        attrs: Optional[dict[str, str]] = None,
        data: Optional[str] = None,
    ) -> None:
        self.tag = tag
        self.attrs = attrs or {}
        self.children: list[Node] = []
        self.data = data
        self.parent: Optional[Node] = None

    def append(self, child: "Node") -> None:
        child.parent = self
        self.children.append(child)

    def text(self) -> str:
        if self.tag == "#text":
            return self.data or ""
        return "".join(child.text() for child in self.children)

    def __repr__(self) -> str:  # pragma: no cover - debugging helper
        if self.tag == "#text":
            return f"Text({self.data!r})"
        return f"Node(tag={self.tag!r}, attrs={self.attrs!r}, children={len(self.children)})"


VOID_TAGS = {
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


class SlackHTMLParser(HTMLParser):
    """Parser that produces a Node tree while tolerating Slack clipboard quirks."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.root = Node("document")
        self._stack: list[Node] = [self.root]

    def handle_starttag(self, tag: str, attrs: list[tuple[str, Optional[str]]]) -> None:
        node = Node(tag, {name: value or "" for name, value in attrs})
        self._stack[-1].append(node)
        if tag.lower() not in VOID_TAGS:
            self._stack.append(node)

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, Optional[str]]]) -> None:  # pragma: no cover - mirrors starttag
        node = Node(tag, {name: value or "" for name, value in attrs})
        self._stack[-1].append(node)

    def handle_endtag(self, tag: str) -> None:
        for idx in range(len(self._stack) - 1, 0, -1):
            if self._stack[idx].tag == tag:
                del self._stack[idx:]
                break

    def handle_data(self, data: str) -> None:
        if not data:
            return
        node = Node("#text", data=data)
        self._stack[-1].append(node)

    def handle_entityref(self, name: str) -> None:  # pragma: no cover - passthrough
        self.handle_data(f"&{name};")

    def handle_charref(self, name: str) -> None:  # pragma: no cover - passthrough
        self.handle_data(f"&#{name};")


def parse_html(text: str) -> Node:
    parser = SlackHTMLParser()
    parser.feed(text)
    parser.close()
    return parser.root


def iter_nodes(node: Node) -> Iterator[Node]:
    yield node
    for child in node.children:
        yield from iter_nodes(child)


def find_first(node: Node, predicate: Callable[[Node], bool]) -> Optional[Node]:
    for candidate in iter_nodes(node):
        if predicate(candidate):
            return candidate
    return None


def find_all(node: Node, predicate: Callable[[Node], bool]) -> list[Node]:
    return [candidate for candidate in iter_nodes(node) if predicate(candidate)]


def each_child(node: Node, tag: Optional[str] = None) -> Iterable[Node]:
    for child in node.children:
        if tag is None or child.tag == tag:
            yield child
