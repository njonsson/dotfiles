from __future__ import annotations

from typing import List, Optional

from .extract import parse_slack_html
from .model import Attachment
from .render import build_message_markdown, render_attachment_fallbacks


def convert(html_text: str, workspace_domain: Optional[str]) -> str:
    messages = parse_slack_html(html_text, workspace_domain)
    if not messages:
        return ""
    sections: List[str] = []
    attachment_keys: set[tuple] = set()
    fallback_attachments: List[Attachment] = []
    for message in messages:
        if not message:
            continue
        rendered = build_message_markdown(message, workspace_domain)
        if rendered.strip():
            sections.append(rendered)
        for attachment in message.attachments:
            key = (
                attachment.url,
                attachment.display_text,
                attachment.is_image,
                attachment.image_src,
                attachment.original_filename,
            )
            if key in attachment_keys:
                continue
            attachment_keys.add(key)
            fallback_attachments.append(attachment)
    fallback_lines = render_attachment_fallbacks(fallback_attachments)
    if fallback_lines:
        sections.append("\n\n".join(fallback_lines))
    return "\n\n".join(sections)
