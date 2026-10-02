"""Tests for tools/corpus/split_nist.py."""

import contextlib
import io
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..",
                                "tools", "corpus"))
import split_nist  # noqa: E402

SUITE = """\
CCVS85  VERSION 4.0   01 OCT 1992 0032
*HEADER,COBOL,NC101A
000100 IDENTIFICATION DIVISION.                                         NC1014.2
000200S    EXIT PROGRAM.                                                NC1014.2
000300D    DISPLAY "DEBUG".                                             NC1014.2
*END-OF,NC101A
*HEADER,COBOL,IC101A,SUBRTN,IC102A
000100 PROGRAM-ID. IC102A.                                              IC1024.2
*END-OF,IC102A
*HEADER,CLBRY,KP001
000100     02 FILLER PIC X.                                             KP0014.2
*END-OF,KP001
*HEADER,DATA*,SQ101A
SOME DATA
*END-OF,SQ101A
*HEADER,COBOL,ST146A                                                    TES00010
000100 PROGRAM-ID. ST146A.                                              ST1464.2
*END-OF,ST146A
"""


class SplitTest(unittest.TestCase):
    def test_members(self):
        members = list(split_nist.split(SUITE.splitlines(True)))
        self.assertEqual(
            [(kind, name) for kind, name, _ in members],
            [("COBOL", "NC101A"), ("COBOL", "IC102A"), ("CLBRY", "KP001"),
             ("DATA*", "SQ101A"), ("COBOL", "ST146A")])
        self.assertEqual(len(members[0][2]), 3)

    def test_optional_code_is_switched_off(self):
        self.assertEqual(
            split_nist.without_optional_code("000200S    EXIT PROGRAM."),
            "000200*    EXIT PROGRAM.")

    def test_cobol_indicators_are_kept(self):
        for line in ("000300D    DISPLAY 1.", "000300-    \"A\".",
                     "000300*   NOTE", "000300     MOVE 1 TO A.", "000300"):
            self.assertEqual(split_nist.without_optional_code(line), line)

    def test_main_writes_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            suite = os.path.join(tmp, "newcob.val")
            with open(suite, "w", encoding="latin-1") as f:
                f.write(SUITE)
            out = os.path.join(tmp, "src")
            with contextlib.redirect_stdout(io.StringIO()):
                status = split_nist.main(["split_nist.py", suite, out])
            self.assertEqual(status, 0)
            self.assertEqual(sorted(os.listdir(out)),
                             ["IC102A.cob", "NC101A.cob", "ST146A.cob", "copy"])
            self.assertEqual(os.listdir(os.path.join(out, "copy")),
                             ["KP001.cpy"])
            with open(os.path.join(out, "NC101A.cob"),
                      encoding="latin-1") as f:
                self.assertEqual(f.read().splitlines()[1][6], "*")

    def test_duplicate_names_are_an_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            suite = os.path.join(tmp, "newcob.val")
            with open(suite, "w", encoding="latin-1") as f:
                f.write(SUITE + "*HEADER,COBOL,NC101A\nX\n*END-OF,NC101A\n")
            out = os.path.join(tmp, "src")
            with contextlib.redirect_stdout(io.StringIO()), \
                    contextlib.redirect_stderr(io.StringIO()):
                status = split_nist.main(["split_nist.py", suite, out])
            self.assertEqual(status, 1)


if __name__ == "__main__":
    unittest.main()
