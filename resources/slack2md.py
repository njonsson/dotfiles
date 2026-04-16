#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


def _bootstrap_modules() -> None:
    script_dir = Path(__file__).resolve().parent
    module_dir = script_dir / "slack2md.d"
    sys_path = str(module_dir)
    if sys_path not in sys.path:
        sys.path.insert(0, sys_path)


_bootstrap_modules()


from cli import main as _main  # type: ignore  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    return _main(argv)


if __name__ == "__main__":
    raise SystemExit(main())
