from __future__ import annotations

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

import slack2md  # type: ignore  # noqa: E402


class PackageInitTests(unittest.TestCase):
    def test_package_exports_main(self) -> None:
        self.assertTrue(callable(getattr(slack2md, "main", None)))


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
