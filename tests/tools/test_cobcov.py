"""Tests for tools/cobcov.py."""

import io
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "tools"))
import cobcov  # noqa: E402

GENERATED_C = """\
  /* Line: 10        : Entry     DEMO                    : src/demo.cob */
  /* Line: 10        : Paragraph MAIN                    : src/demo.cob */
  /* Line: 11        : MOVE               : src/demo.cob */
  /* Line: 12        : IF                 : src/demo.cob */
    /* Line: 13        : DISPLAY            : src/demo.cob */
    /* Line: 15        : DISPLAY            : src/demo.cob */
  /* Line: 16        : WHEN               : copy/demo.cpy */
  /* Line: 20        : last source line                  :src/demo.cob */
  /* Line: 3         : MOVE               : tests/unit/test-demo.cob */
  /* Line: 0         : Paragraph Default Error Handler   : src/demo.cob */
"""

TRACE = """\
Source: 'src/demo.cob'
Program-Id:  DEMO
Source: src/demo.cob                   |     0
Source: src/demo.cob                   |    10
Source: src/demo.cob                   |    11
Source: src/demo.cob                   |    12
Source: src/demo.cob                   |    15
Source: src/demo.cob                   |    11
"""


class CobcovTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.map = self._write("gen/demo.c", GENERATED_C)
        self.trace = self._write("trace/t_1.trace", TRACE)

    def _write(self, rel, text):
        path = os.path.join(self.tmp.name, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(text)
        return path

    def test_map_skips_entry_sentinel_and_line_zero(self):
        lines = cobcov.read_maps([self.map])
        self.assertEqual(lines["src/demo.cob"], {10, 11, 12, 13, 15})
        self.assertEqual(lines["copy/demo.cpy"], {16})

    def test_trace_counts_hits(self):
        hits = cobcov.read_traces([self.trace])
        self.assertEqual(hits["src/demo.cob"][11], 2)
        self.assertEqual(hits["src/demo.cob"][13], 0)

    def test_expand_directories(self):
        self._write("trace/notes.txt", "ignored")
        files = cobcov.expand([os.path.dirname(self.trace)], ".trace")
        self.assertEqual(files, [self.trace])
        self.assertEqual(cobcov.expand([self.map], ".c"), [self.map])

    def test_report_filters_by_prefix(self):
        report = cobcov.build_report(cobcov.read_maps([self.map]),
                                     cobcov.read_traces([self.trace]),
                                     ["src/"])
        self.assertEqual([name for name, _ in report], ["src/demo.cob"])
        counts = report[0][1]
        self.assertEqual(counts, {10: 1, 11: 2, 12: 1, 13: 0, 15: 1})

    def test_lcov_output(self):
        report = [("src/demo.cob", {11: 2, 13: 0})]
        out = io.StringIO()
        cobcov.write_lcov(report, out)
        self.assertEqual(out.getvalue(),
                         "TN:\nSF:src/demo.cob\nDA:11,2\nDA:13,0\n"
                         "LF:2\nLH:1\nend_of_record\n")

    def test_unmapped_hits_ignore_line_zero(self):
        executable = {"src/demo.cob": {11}}
        hits = {"src/demo.cob": {0: 3, 11: 1, 12: 1}}
        self.assertEqual(cobcov.unmapped_hits(executable, hits, []),
                         {"src/demo.cob": [12]})

    def test_fail_under(self):
        args = ["--map", self.map, "--trace", self.trace, "--include", "src/"]
        out, err = io.StringIO(), io.StringIO()
        saved = sys.stdout, sys.stderr
        sys.stdout, sys.stderr = out, err
        try:
            self.assertEqual(cobcov.main(args + ["--fail-under", "80"]), 0)
            self.assertEqual(cobcov.main(args + ["--fail-under", "81"]), 1)
        finally:
            sys.stdout, sys.stderr = saved
        self.assertIn("TOTAL", out.getvalue())
        self.assertIn("below the required 81.0%", err.getvalue())

    def test_fold_accumulates_counts(self):
        counts = os.path.join(self.tmp.name, "counts")
        cobcov.fold(self.trace, counts)
        cobcov.fold(self.trace, counts)
        hits = cobcov.read_counts(counts,
                                  cobcov.defaultdict(
                                      lambda: cobcov.defaultdict(int)))
        self.assertEqual(hits["src/demo.cob"][11], 4)
        self.assertEqual(hits["src/demo.cob"][10], 2)

    def test_report_from_counts(self):
        counts = os.path.join(self.tmp.name, "counts")
        cobcov.fold(self.trace, counts)
        out, err = io.StringIO(), io.StringIO()
        saved = sys.stdout, sys.stderr
        sys.stdout, sys.stderr = out, err
        try:
            rc = cobcov.main(["--map", self.map, "--counts", counts,
                              "--include", "src/", "--fail-under", "80"])
        finally:
            sys.stdout, sys.stderr = saved
        self.assertEqual(rc, 0)
        self.assertIn("80.0%", out.getvalue())

    def test_empty_report_is_full_coverage(self):
        self.assertEqual(cobcov.percent(0, 0), 100.0)


if __name__ == "__main__":
    unittest.main()
