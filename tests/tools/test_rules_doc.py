"""The rule table in docs/rules.md matches plumbline's rule catalog."""

import json
import os
import re
import subprocess
import unittest

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
PLUMBLINE = os.environ.get(
    "PLUMBLINE", os.path.join(ROOT, "build", "bin", "plumbline"))
RULES_DOC = os.path.join(ROOT, "docs", "rules.md")

# | [PLB-C001](#plb-c001-unreachable-code) | unreachable-code | warning | Title |
ROW = re.compile(
    r"^\| \[(PLB-[A-Z]\d{3})\]\(#([a-z0-9-]+)\) \| ([a-z0-9-]+) \| "
    r"(error|warning|note)(, off)? \| (.+) \|$")


def catalog():
    out = subprocess.run(
        [PLUMBLINE, "rules", "--no-config", "--report", "json"],
        check=True, capture_output=True, text=True).stdout
    return {rule["id"]: rule for rule in json.loads(out)["rules"]}


def documented():
    with open(RULES_DOC, encoding="utf-8") as doc:
        text = doc.read()
    rows = {}
    for line in text.splitlines():
        match = ROW.match(line)
        if match:
            rule_id, anchor, name, severity, off, title = match.groups()
            rows[rule_id] = {
                "anchor": anchor, "name": name, "severity": severity,
                "enabled": off is None, "title": title}
    headings = set(re.findall(r"^## (PLB-[A-Z]\d{3}) ([a-z0-9-]+)$",
                              text, re.M))
    return rows, headings


@unittest.skipUnless(os.path.exists(PLUMBLINE), "plumbline is not built")
class RulesDocTest(unittest.TestCase):

    def setUp(self):
        self.rules = catalog()
        self.rows, self.headings = documented()

    def test_every_rule_has_a_row(self):
        self.assertEqual(sorted(self.rules), sorted(self.rows))

    def test_rows_match_the_catalog(self):
        for rule_id, rule in self.rules.items():
            row = self.rows.get(rule_id)
            if row is None:
                continue
            with self.subTest(rule=rule_id):
                self.assertEqual(row["name"], rule["name"])
                self.assertEqual(row["severity"], rule["severity"])
                self.assertEqual(row["enabled"], rule["enabled"])
                self.assertEqual(row["title"], rule["title"])

    def test_every_rule_has_a_section(self):
        for rule_id, rule in self.rules.items():
            with self.subTest(rule=rule_id):
                self.assertIn((rule_id, rule["name"]), self.headings)

    def test_rows_link_to_their_sections(self):
        for rule_id, row in self.rows.items():
            with self.subTest(rule=rule_id):
                self.assertEqual(
                    row["anchor"], f"{rule_id.lower()}-{row['name']}")


if __name__ == "__main__":
    unittest.main()
