from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


TEST_ROOT = Path(__file__).resolve().parents[2]

if str(TEST_ROOT) not in sys.path:
    sys.path.insert(0, str(TEST_ROOT))


class PackageInitTests(unittest.TestCase):
    def test_package_exports_main(self) -> None:
        module_path = TEST_ROOT / "slack2md.d" / "__init__.py"
        spec = importlib.util.spec_from_file_location("slack2md_d", module_path)
        self.assertIsNotNone(spec)
        module = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
        assert spec.loader is not None
        spec.loader.exec_module(module)  # type: ignore[misc]
        package = module
        self.assertTrue(callable(getattr(package, "main", None)))


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
