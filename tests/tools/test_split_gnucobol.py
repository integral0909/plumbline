"""Tests for tools/corpus/split_gnucobol.py."""

import contextlib
import io
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..",
                                "tools", "corpus"))
import split_gnucobol  # noqa: E402

# Three test cases in Autotest's form: one that compiles two programs
# with options, one GnuCOBOL expects to fail, and one whose compile is
# expected to fail.
SUITE = """\
AT_SETUP([Intrinsics @<:@all@:>@])
AT_KEYWORDS([functions])

AT_DATA([prog.cob], [
       IDENTIFICATION   DIVISION.
       PROGRAM-ID.      prog.
       PROCEDURE        DIVISION.
           DISPLAY PI.
])

AT_DATA([free.cob], [
PROGRAM-ID. free.
])

AT_CHECK([$COMPILE -fintrinsics=all prog.cob], [0], [], [])
AT_CHECK([$COMPILE_ONLY -free -std=ibm free.cob], [0], [], [])
AT_CLEANUP


AT_SETUP([Expected to fail])
AT_XFAIL_IF([true])

AT_DATA([prog.cob], [
       PROGRAM-ID. prog.
])

AT_CHECK([$COMPILE prog.cob], [0], [], [])
AT_CLEANUP


AT_SETUP([Compile error])

AT_DATA([prog.cob], [
       PROGRAM-ID. prog.
])

AT_CHECK([$COMPILE -fformat=variable prog.cob], [1], [], [ignore])
AT_CLEANUP
"""


class SplitGnuCOBOLTest(unittest.TestCase):
    def test_test_cases(self):
        titles = [title for title, _ in split_gnucobol.test_cases(SUITE)]
        self.assertEqual(titles, ["Intrinsics @<:@all@:>@",
                                  "Expected to fail", "Compile error"])

    def test_quadrigraphs(self):
        self.assertEqual(split_gnucobol.unquote("@<:@1@:>@ @S|@X"),
                         "[1] $X")

    def test_files_and_compiles(self):
        _, body = next(split_gnucobol.test_cases(SUITE))
        files, compiles = split_gnucobol.files_and_compiles(body)
        self.assertEqual(sorted(files), ["free.cob", "prog.cob"])
        self.assertIn("DISPLAY PI.", files["prog.cob"])
        self.assertEqual(compiles, [
            (["-fintrinsics=all"], "prog.cob", "0"),
            (["-free", "-std=ibm"], "free.cob", "0")])

    def test_quoted_arguments_nest(self):
        args, end = split_gnucobol.macro_arguments("([a [b] c], [d])", 0)
        self.assertEqual(args, ["a [b] c", "d"])
        self.assertEqual(end, 16)

    def test_manifest(self):
        with tempfile.TemporaryDirectory() as tmp:
            suite = os.path.join(tmp, "suite")
            os.makedirs(suite)
            with open(os.path.join(suite, "run_misc.at"), "w",
                      encoding="latin-1") as f:
                f.write(SUITE)
            out = os.path.join(tmp, "src")
            with contextlib.redirect_stdout(io.StringIO()):
                status = split_gnucobol.main(["split_gnucobol.py", suite,
                                              out])
            self.assertEqual(status, 0)
            with open(os.path.join(out, "MANIFEST"), encoding="utf-8") as f:
                rows = [line.split("\t") for line in f.read().splitlines()]
            # Only the first test case: the second is expected to fail,
            # and the third's compile is. Its title is unquoted.
            directory = "0001-intrinsics-all"
            self.assertEqual(rows, [
                [directory, "prog.cob", "fixed", "default", "all",
                 "run_misc.at: Intrinsics [all]"],
                [directory, "free.cob", "free", "ibm", "-",
                 "run_misc.at: Intrinsics [all]"]])
            with open(os.path.join(out, directory, "prog.cob"),
                      encoding="latin-1") as f:
                self.assertTrue(f.read().startswith("       IDENTIFICATION"))


if __name__ == "__main__":
    unittest.main()
