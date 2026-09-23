import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "MacStatus" / "MacStatus"


class ArchitectureTests(unittest.TestCase):
    def test_swiftui_preferences_use_semantic_keys(self):
        offenders = []
        for path in SOURCE.rglob("*.swift"):
            if '@AppStorage("' in path.read_text(encoding="utf-8"):
                offenders.append(str(path.relative_to(ROOT)))
        self.assertEqual([], offenders)

    def test_status_view_model_is_the_only_tick_consumer(self):
        consumers = []
        pattern = re.compile(r"tickPublisher\s*\n\s*\.sink")
        for path in SOURCE.rglob("*.swift"):
            if pattern.search(path.read_text(encoding="utf-8")):
                consumers.append(str(path.relative_to(ROOT)))
        self.assertEqual(["MacStatus/MacStatus/StatusViewModel.swift"], consumers)


if __name__ == "__main__":
    unittest.main()
