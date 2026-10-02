#!/usr/bin/env python3
"""Validate a plumbline JSON, SARIF, or Code Climate report read from
standard input.

Usage: check_report.py json|sarif|codeclimate [EXPECTED-FINDINGS]

Checks the structure the report promises (see src/lib/plbreport.cob),
not just that it parses. With EXPECTED-FINDINGS, the number of findings
(JSON), results (SARIF), or issues (Code Climate) must match. Exits 1 with a message on the
first problem.
"""

import json
import sys

LEVELS = {"error", "warning", "note"}
SEVERITIES = {"info", "minor", "major", "critical", "blocker"}
CATEGORIES = {"Bug Risk", "Clarity", "Compatibility", "Complexity",
              "Duplication", "Performance", "Security", "Style"}


class Invalid(Exception):
    pass


def require(cond, message):
    if not cond:
        raise Invalid(message)


def check_json(doc):
    require(doc.get("tool") == "plumbline", "tool must be plumbline")
    require(isinstance(doc.get("version"), str), "version must be a string")
    findings = doc.get("findings")
    require(isinstance(findings, list), "findings must be a list")
    for f in findings:
        require(f["rule"].startswith("PLB-"), f"bad rule id {f['rule']}")
        require(f["severity"] in LEVELS, f"bad severity {f['severity']}")
        require(isinstance(f["line"], int) and f["line"] >= 0, "bad line")
        require(isinstance(f["column"], int), "bad column")
        require(isinstance(f["message"], str) and f["message"], "no message")
    for d in doc.get("diagnostics", []):
        require(d["severity"] in LEVELS, f"bad severity {d['severity']}")
    return len(findings)


def check_sarif(doc):
    require(doc.get("version") == "2.1.0", "SARIF version must be 2.1.0")
    runs = doc.get("runs")
    require(isinstance(runs, list) and len(runs) == 1, "expected one run")
    run = runs[0]
    driver = run["tool"]["driver"]
    require(driver["name"] == "plumbline", "driver name must be plumbline")
    rules = driver["rules"]
    require(rules, "driver must list its rules")
    ids = [r["id"] for r in rules]
    require(len(ids) == len(set(ids)), "rule ids must be unique")
    for r in rules:
        require(r["defaultConfiguration"]["level"] in LEVELS, "bad level")
        require(r["shortDescription"]["text"], "rule needs a description")
    for n in run["invocations"][0]["toolExecutionNotifications"]:
        require(n["level"] in LEVELS, "bad notification level")
    results = run["results"]
    for res in results:
        index = res["ruleIndex"]
        require(0 <= index < len(rules), "ruleIndex out of range")
        require(rules[index]["id"] == res["ruleId"],
                "ruleIndex does not point at ruleId")
        require(res["level"] in LEVELS, "bad result level")
        require(res["message"]["text"], "result needs a message")
        loc = res["locations"][0]["physicalLocation"]
        require(loc["artifactLocation"]["uri"], "result needs a uri")
        require(" " not in loc["artifactLocation"]["uri"], "uri not encoded")
        require(loc["region"]["startLine"] >= 1, "startLine must be >= 1")
    return len(results)


def check_codeclimate(doc):
    require(isinstance(doc, list), "the report must be a list of issues")
    fingerprints = set()
    for issue in doc:
        require(issue.get("type") == "issue", "type must be issue")
        require(issue["check_name"], "issue needs a check_name")
        require(issue["description"], "issue needs a description")
        require(issue["severity"] in SEVERITIES,
                f"bad severity {issue['severity']}")
        require(issue["categories"] and
                set(issue["categories"]) <= CATEGORIES, "bad categories")
        fingerprint = issue["fingerprint"]
        require(len(fingerprint) == 16 and
                all(c in "0123456789abcdef" for c in fingerprint),
                f"bad fingerprint {fingerprint}")
        require(fingerprint not in fingerprints,
                f"fingerprint {fingerprint} is not unique")
        fingerprints.add(fingerprint)
        require(issue["location"]["path"], "issue needs a path")
        require(issue["location"]["lines"]["begin"] >= 1,
                "begin must be >= 1")
    return len(doc)


CHECKS = {"json": check_json, "sarif": check_sarif,
          "codeclimate": check_codeclimate}


def main(argv):
    if len(argv) not in (2, 3) or argv[1] not in CHECKS:
        print(__doc__, file=sys.stderr)
        return 2
    try:
        doc = json.load(sys.stdin)
        count = CHECKS[argv[1]](doc)
        if len(argv) == 3:
            require(count == int(argv[2]),
                    f"expected {argv[2]} findings, found {count}")
    except (Invalid, KeyError, TypeError, ValueError) as e:
        print(f"check_report: invalid {argv[1]} report: {e}",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
