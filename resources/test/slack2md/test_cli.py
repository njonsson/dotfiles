from __future__ import annotations

import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


TEST_ROOT = Path(__file__).resolve().parents[2]
MODULE_DIR = TEST_ROOT / "slack2md.d"

if str(MODULE_DIR) not in sys.path:
    sys.path.insert(0, str(MODULE_DIR))
if str(TEST_ROOT) not in sys.path:
    sys.path.insert(0, str(TEST_ROOT))

import cli  # noqa: E402


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

    def test_read_input_isatty_without_clipboard_raises(self) -> None:
        parser = cli.build_parser()
        args = parser.parse_args([])

        class _Tty(io.StringIO):
            def isatty(self) -> bool:
                return True

        fake_stdin = _Tty("")
        with patch.object(cli.sys, "stdin", fake_stdin):
            with self.assertRaises(RuntimeError):
                cli.read_input(args)

    def test_read_input_uses_clipboard_when_requested(self) -> None:
        parser = cli.build_parser()
        args = parser.parse_args(["--clipboard"])
        with patch("cli.read_clipboard_html", return_value="<html/>") as mock_clip:
            data = cli.read_input(args)
        mock_clip.assert_called_once()
        self.assertEqual(data, "<html/>")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
