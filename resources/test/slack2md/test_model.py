from __future__ import annotations

import sys
import unittest
from pathlib import Path


TEST_ROOT = Path(__file__).resolve().parents[2]
MODULE_DIR = TEST_ROOT / "slack2md.d"

if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))

import model  # noqa: E402


class ModelTests(unittest.TestCase):
    def test_reaction_defaults_provide_unique_lists(self) -> None:
        first = model.Reaction(emoji="👍")
        second = model.Reaction(emoji="🔥")
        first.users.append("@nijonsso")
        self.assertEqual(second.users, [])

    def test_attachment_records_image_metadata(self) -> None:
        attachment = model.Attachment(
            url="file://Nice%20emoji.png",
            display_text="Nice emoji",
            is_image=True,
            image_src="Nice emoji.png",
            original_filename="Nice emoji.png",
        )
        self.assertTrue(attachment.is_image)
        self.assertEqual(attachment.image_src, "Nice emoji.png")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
