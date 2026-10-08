"""The fixes in the JSON and SARIF reports of plumbline check.

The SARIF replacements of each result are applied to the file, as a
SARIF viewer would, and the file then checked again: the findings that
had a fix are gone. The JSON report gives the same edits.
"""
import json
import os
import subprocess
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))))
PLUMBLINE = os.environ.get(
    "PLUMBLINE", os.path.join(ROOT, "build", "bin", "plumbline"))
# Given as a path relative to the repository, as the URIs are.
FIXABLE = os.path.join("tests", "fixtures", "fix", "fixable.cob")


def report(path, kind):
    run = subprocess.run([os.path.abspath(PLUMBLINE), "check", "--report",
                          kind, path], cwd=ROOT, capture_output=True,
                         text=True, check=False)
    return json.loads(run.stdout)


def apply(text, edits):
    """Edits as (line, column, end line, end column, text), 1-based,
    end exclusive; applied from the last to the first."""
    lines = text.split("\n")
    for line, column, end_line, end_column, new in sorted(
            edits, reverse=True):
        head = lines[line - 1][:column - 1]
        tail = lines[end_line - 1][end_column - 1:]
        lines[line - 1:end_line] = [head + new + tail]
    return "\n".join(lines)


class ReportFixesTest(unittest.TestCase):

    def test_sarif_fixes_remove_their_findings(self):
        sarif = report(FIXABLE, "sarif")
        results = sarif["runs"][0]["results"]
        fixed = [r for r in results if "fixes" in r]
        self.assertEqual(sorted(r["ruleId"] for r in fixed),
                         ["PLB-C004", "PLB-C004", "PLB-C071", "PLB-C071",
                          "PLB-C071", "PLB-C074"])
        edits = []
        for result in fixed:
            [fix] = result["fixes"]
            self.assertTrue(fix["description"]["text"])
            [change] = fix["artifactChanges"]
            self.assertEqual(change["artifactLocation"]["uri"],
                             "tests/fixtures/fix/fixable.cob")
            for replacement in change["replacements"]:
                region = replacement["deletedRegion"]
                edits.append((region["startLine"], region["startColumn"],
                              region["endLine"], region["endColumn"],
                              replacement["insertedContent"]["text"]))
        with open(os.path.join(ROOT, FIXABLE)) as source:
            fixed_text = apply(source.read(), edits)
        with tempfile.TemporaryDirectory() as directory:
            path = os.path.join(directory, "fixed.cob")
            with open(path, "w") as out:
                out.write(fixed_text)
            after = report(path, "json")
        rules = {f["rule"] for f in after["findings"]}
        for rule in ("PLB-C004", "PLB-C071", "PLB-C074"):
            self.assertNotIn(rule, rules)

    def test_json_gives_the_same_edits(self):
        sarif = report(FIXABLE, "sarif")
        from_sarif = sorted(
            (r["ruleId"], d["deletedRegion"]["startLine"],
             d["deletedRegion"]["startColumn"],
             d["insertedContent"]["text"])
            for r in sarif["runs"][0]["results"] if "fixes" in r
            for d in r["fixes"][0]["artifactChanges"][0]["replacements"])
        data = report(FIXABLE, "json")
        from_json = sorted(
            (f["rule"], e["line"], e["column"], e["text"])
            for f in data["findings"] if "fix" in f
            for e in f["fix"]["edits"])
        self.assertEqual(from_sarif, from_json)

    def test_findings_without_a_fix_have_none(self):
        data = report(FIXABLE, "json")
        for finding in data["findings"]:
            if finding["rule"] not in ("PLB-C004", "PLB-C071", "PLB-C074",
                                       "PLB-C079"):
                self.assertNotIn("fix", finding)


if __name__ == "__main__":
    unittest.main()
