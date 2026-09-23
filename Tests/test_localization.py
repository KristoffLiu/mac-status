import json
import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOG = ROOT / "MacStatus" / "MacStatus" / "Localizable.xcstrings"
HAN = re.compile(r"[\u3400-\u9fff]")


class LocalizationTests(unittest.TestCase):
    def test_chinese_source_strings_have_english_localizations(self):
        strings = json.loads(CATALOG.read_text(encoding="utf-8"))["strings"]
        missing = [
            key
            for key, entry in strings.items()
            if HAN.search(key) and "en" not in entry.get("localizations", {})
        ]
        self.assertEqual([], missing)


if __name__ == "__main__":
    unittest.main()
