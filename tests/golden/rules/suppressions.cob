*> Findings suppressed by comments.
PROCEDURE DIVISION.
MAIN-LINE.
    GO TO DONE.                    *> plumbline: ignore go-to
*> plumbline: ignore PLB-C001
UNUSED-ONE.
    DISPLAY "SUPPRESSED ON THE LINE BEFORE".
*> plumbline: ignore go-to
UNUSED-TWO.
    DISPLAY "NOT SUPPRESSED: WRONG RULE".
UNUSED-THREE.                      *> Plumbline: Ignore
    DISPLAY "SUPPRESSED: ALL RULES".
UNUSED-FOUR.
    GO TO DONE.                    *> plumbline: ignore PLB-C001, go-to
*> plumbline: ignore
DONE.
    STOP RUN.
UNUSED-FIVE.
    DISPLAY "A CODE LINE ABOVE DOES NOT SUPPRESS". *> plumbline: ignore
UNUSED-SIX.
    DISPLAY "NOT SUPPRESSED".
