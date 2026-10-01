"""The Visual Studio Code extension's manifest is sound."""

import json
import os
import re
import unittest

EXTENSION = os.path.join(os.path.dirname(__file__), "..", "..", "editors",
                         "vscode")


class ExtensionTest(unittest.TestCase):
    def setUp(self):
        with open(os.path.join(EXTENSION, "package.json")) as f:
            self.manifest = json.load(f)
        with open(os.path.join(EXTENSION, "extension.js")) as f:
            self.source = f.read()

    def test_main_exists(self):
        self.assertTrue(os.path.exists(
            os.path.join(EXTENSION, self.manifest["main"])))

    def test_settings_are_the_ones_read(self):
        settings = self.manifest["contributes"]["configuration"]["properties"]
        read = set(re.findall(r'settings\.get\("([a-z]+)"', self.source))
        self.assertEqual({"plumbline." + name for name in read},
                         set(settings))

    def test_commands_are_registered(self):
        for command in self.manifest["contributes"]["commands"]:
            self.assertIn('"%s"' % command["command"], self.source)

    def test_starts_the_language_server(self):
        self.assertIn('["lsp", ...settings.get("arguments", [])]',
                      self.source)

    def test_version_matches_the_program(self):
        with open(os.path.join(EXTENSION, "..", "..", "copy",
                               "plbver.cpy")) as f:
            version = re.search(r'"(\d+\.\d+\.\d+)(-[a-z]+)?"', f.read()).group(1)
        self.assertEqual(self.manifest["version"], version)


if __name__ == "__main__":
    unittest.main()
