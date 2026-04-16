from __future__ import annotations

import sys
import unittest
from importlib import util
from pathlib import Path

if __package__ in {None, ""}:  # pragma: no cover - direct execution
    init_path = Path(__file__).resolve().parent / "__init__.py"
    spec = util.spec_from_file_location("slack2md_test_bootstrap", init_path)
    bootstrap = util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(bootstrap)  # type: ignore[attr-defined]
else:
    from importlib import import_module

    package_name = __package__ or Path(__file__).resolve().parent.name
    bootstrap = import_module(package_name)  # pragma: no cover

bootstrap.setup()

from slack2md import model  # type: ignore  # noqa: E402


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
