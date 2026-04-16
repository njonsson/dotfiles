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

from slack2md import utils  # type: ignore  # noqa: E402


class UtilsTests(unittest.TestCase):
    def test_clean_text_preserves_nbsp(self) -> None:
        self.assertEqual(utils.clean_text("Hello&nbsp;world"), "Hello world")

    def test_normalize_workspace_domain(self) -> None:
        self.assertEqual(utils.normalize_workspace_domain("team.slack.com"), "team.slack.com")

    def test_escape_markdown_escapes_special_characters(self) -> None:
        self.assertEqual(utils.escape_markdown("*test*"), r"\*test\*")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
