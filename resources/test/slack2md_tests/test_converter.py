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

from slack2md import converter  # type: ignore  # noqa: E402

FIXTURE_DIR = Path(__file__).with_name("fixtures")


class ConverterTests(unittest.TestCase):
    def test_convert_matches_expected_markdown(self) -> None:
        html_path = FIXTURE_DIR / "slack_clipboard.html"
        expected_path = FIXTURE_DIR / "slack_clipboard_expected.md"
        html_text = html_path.read_text(encoding="utf-8")
        expected = expected_path.read_text(encoding="utf-8").strip()
        result = converter.convert(html_text, workspace_domain=None)
        self.assertEqual(result.strip(), expected)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
