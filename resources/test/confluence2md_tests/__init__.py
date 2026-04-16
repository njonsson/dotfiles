from __future__ import annotations

import sys
from pathlib import Path
from typing import Iterable

_RESOURCES_DIR = Path(__file__).resolve().parents[2]
_PACKAGE_DIR = _RESOURCES_DIR / "confluence2md"
_TEST_DIR = Path(__file__).resolve().parent


def _ensure_sys_path() -> None:
    if str(_RESOURCES_DIR) not in sys.path:
        sys.path.insert(0, str(_RESOURCES_DIR))
    if str(_TEST_DIR) not in sys.path:
        sys.path.insert(0, str(_TEST_DIR))


def _prefer_local_modules(names: Iterable[str]) -> None:
    for name in names:
        module = sys.modules.get(name)
        if module is None:
            continue
        module_file = getattr(module, "__file__", None)
        if not module_file:
            continue
        try:
            module_path = Path(module_file).resolve()
        except (OSError, RuntimeError):  # pragma: no cover - defensive
            continue
        if not module_path.is_relative_to(_PACKAGE_DIR):
            sys.modules.pop(name, None)


def setup() -> None:
    _ensure_sys_path()
    _prefer_local_modules(
        (
            "confluence2md",
            "confluence2md.cli",
            "confluence2md.converter",
            "confluence2md.utils",
            "confluence2md.html_parser",
            "confluence2md.inline",
            "confluence2md.tables",
        )
    )


setup()
