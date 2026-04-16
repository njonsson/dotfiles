from __future__ import annotations

import io
import sys
import unittest
from importlib import util
from pathlib import Path
from unittest import mock

if __package__ in {None, ""}:  # pragma: no cover - direct execution
    init_path = Path(__file__).resolve().parent / "__init__.py"
    spec = util.spec_from_file_location("confluence2md_test_bootstrap", init_path)
    bootstrap = util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(bootstrap)  # type: ignore[attr-defined]
else:
    bootstrap = sys.modules[__package__]  # pragma: no cover

bootstrap.setup()

from confluence2md import cli  # type: ignore  # noqa: E402


class CliTests(unittest.TestCase):
    def test_cli_with_stdin(self) -> None:
        argv: list[str] = []
        input_html = "<p>Hello</p>"
        expected_output = "Hello\n"
        with mock.patch.object(sys, "stdin", io.StringIO(input_html)), mock.patch.object(sys, "stdout", new_callable=io.StringIO) as fake_stdout:
            exit_code = cli.main(argv)
        self.assertEqual(0, exit_code)
        self.assertEqual(expected_output, fake_stdout.getvalue())

    def test_read_input_requires_stdin_when_tty(self) -> None:
        parser = cli.build_parser()
        args = parser.parse_args([])

        class _Tty(io.StringIO):
            def isatty(self) -> bool:
                return True

        fake_stdin = _Tty("")
        with mock.patch.object(cli.sys, "stdin", fake_stdin):
            with self.assertRaises(RuntimeError) as ctx:
                cli.read_input(args)
        self.assertIn("pbpaste-html | confluence2md", str(ctx.exception))
