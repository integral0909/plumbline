"""Every rule of the catalog has a test that shows it reporting."""

import glob
import os
import re
import unittest

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")


class RulesTestedTest(unittest.TestCase):
    def test_every_rule_reports_in_a_test(self):
        with open(os.path.join(ROOT, "docs", "rules.md")) as f:
            ids = re.findall(r"^\| \[(PLB-[A-Z]\d{3})\]", f.read(), re.M)
        self.assertTrue(ids)
        expected = []
        for path in glob.glob(os.path.join(ROOT, "tests", "golden", "*",
                                           "*.out")) + glob.glob(
                os.path.join(ROOT, "tests", "golden", "*", "*.err")):
            with open(path) as f:
                expected.append(f.read())
        with open(os.path.join(ROOT, "tests", "cli", "test-cli.sh")) as f:
            expected.append(f.read())
        text = "\n".join(expected)
        untested = [rule for rule in ids
                    if "[" + rule + "]" not in text
                    and "\\[" + rule + "\\]" not in text]
        self.assertEqual(untested, [])


if __name__ == "__main__":
    unittest.main()
