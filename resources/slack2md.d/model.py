from __future__ import annotations

import datetime as _dt
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass(slots=True)
class Reaction:
    """Represents a Slack emoji reaction."""

    emoji: str
    users: List[str] = field(default_factory=list)


@dataclass(slots=True)
class Attachment:
    """Represents a Slack attachment embedded in a message."""

    url: str  # typically file:// path (URL encoded)
    display_text: str  # rendered text (sans extension when required)
    is_image: bool
    image_src: Optional[str] = None  # URL-decoded path for image display
    original_filename: Optional[str] = None  # decoded filename with extension


@dataclass(slots=True)
class Message:
    """Represents a Slack message extracted from clipboard HTML."""

    timestamp: Optional[_dt.datetime]
    raw_timestamp: Optional[str]
    author: str
    body_nodes: List["Node"]
    reactions: List[Reaction] = field(default_factory=list)
    attachments: List[Attachment] = field(default_factory=list)


# Forward reference for type checking: Node is defined in html_nodes.py.
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from html_nodes import Node
