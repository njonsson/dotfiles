from __future__ import annotations

import io
import sys
import unittest
from importlib import util
from pathlib import Path
from unittest.mock import patch

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

from slack2md import cli  # type: ignore  # noqa: E402


class _FakeStdin(io.StringIO):
    def isatty(self) -> bool:
        return False


class CliTests(unittest.TestCase):
    def test_build_parser_handles_workspace_domain(self) -> None:
        parser = cli.build_parser()
        args = parser.parse_args(["--workspace-domain", "example.slack.com"])
        self.assertEqual(args.workspace_domain, "example.slack.com")

    def test_read_input_prefers_stdin_when_present(self) -> None:
        parser = cli.build_parser()
        args = parser.parse_args([])
        fake_stdin = _FakeStdin("<html>payload</html>")
        with patch.object(cli.sys, "stdin", fake_stdin):
            data = cli.read_input(args)
        self.assertEqual(data, "<html>payload</html>")

    def test_read_input_requires_stdin_when_tty(self) -> None:
        parser = cli.build_parser()
        args = parser.parse_args([])

        class _Tty(io.StringIO):
            def isatty(self) -> bool:
                return True

        fake_stdin = _Tty("")
        with patch.object(cli.sys, "stdin", fake_stdin):
            with self.assertRaises(RuntimeError) as ctx:
                cli.read_input(args)
        self.assertIn("pbpaste-html | slack2md", str(ctx.exception))


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
