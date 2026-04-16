from __future__ import annotations

import sys
import unittest
from importlib import util
from pathlib import Path

if __package__ in {None, ""}:  # pragma: no cover - direct execution
    init_path = Path(__file__).resolve().parent / "__init__.py"
    spec = util.spec_from_file_location("confluence2md_test_bootstrap", init_path)
    bootstrap = util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(bootstrap)  # type: ignore[attr-defined]
else:
    bootstrap = sys.modules[__package__]  # pragma: no cover

bootstrap.setup()

from confluence2md import utils  # type: ignore  # noqa: E402


class UtilsTests(unittest.TestCase):
    def test_language_from_class(self) -> None:
        self.assertEqual("python", utils.language_from_class("language-python"))
        self.assertEqual("js", utils.language_from_class("foo lang-js bar"))
        self.assertIsNone(utils.language_from_class(""))

    def test_bullet_for_depth_rotates_symbols(self) -> None:
        self.assertEqual("*", utils.bullet_for_depth(0))
        self.assertEqual("-", utils.bullet_for_depth(1))
        self.assertEqual("+", utils.bullet_for_depth(2))
        self.assertEqual("*", utils.bullet_for_depth(3))
