*> ---------------------------------------------------------------
*> plbtest: assertion library for Plumbline unit tests.
*>
*> A test program calls PLBT-BEGIN once, then any number of
*> PLBT-CASE / PLBT-ASSERT-* calls, then PLBT-END. Output follows
*> the TAP 13 format so any TAP consumer can read it:
*>
*>     ok 1 - length of blank text
*>     not ok 2 - upper folds letters
*>       ---
*>       expected: 'ABC'
*>       actual:   'abc'
*>       ...
*>     1..2
*>
*> PLBT-END sets RETURN-CODE to 1 if any assertion failed.
*> String comparison follows COBOL rules: trailing spaces are
*> not significant.
*> ---------------------------------------------------------------

*> PLBT-BEGIN: reset counters and announce the suite.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLBT-BEGIN.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbtstate.cpy".
LINKAGE SECTION.
01  LK-SUITE                PIC X ANY LENGTH.
PROCEDURE DIVISION USING LK-SUITE.
    MOVE LK-SUITE TO PLBT-SUITE
    MOVE SPACES TO PLBT-CASE-NAME
    MOVE 0 TO PLBT-TOTAL PLBT-FAILED
    DISPLAY "TAP version 13"
    DISPLAY "# suite: " FUNCTION TRIM(PLBT-SUITE TRAILING)
    GOBACK.
END PROGRAM PLBT-BEGIN.

*> PLBT-CASE: name the group the following assertions belong to.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLBT-CASE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbtstate.cpy".
LINKAGE SECTION.
01  LK-CASE                 PIC X ANY LENGTH.
PROCEDURE DIVISION USING LK-CASE.
    MOVE LK-CASE TO PLBT-CASE-NAME
    DISPLAY "# case: " FUNCTION TRIM(PLBT-CASE-NAME TRAILING)
    GOBACK.
END PROGRAM PLBT-CASE.

*> PLBT-REPORT: record one result. Internal; called by the asserts.
*> LK-OK is "Y" or "N". Diagnostics are printed by the caller.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLBT-REPORT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbtstate.cpy".
01  WS-NUM                  PIC Z(8)9.
LINKAGE SECTION.
01  LK-LABEL                PIC X ANY LENGTH.
01  LK-OK                   PIC X.
PROCEDURE DIVISION USING LK-LABEL LK-OK.
    ADD 1 TO PLBT-TOTAL
    MOVE PLBT-TOTAL TO WS-NUM
    IF LK-OK = "Y"
        DISPLAY "ok " FUNCTION TRIM(WS-NUM) " - "
            FUNCTION TRIM(LK-LABEL TRAILING)
    ELSE
        ADD 1 TO PLBT-FAILED
        DISPLAY "not ok " FUNCTION TRIM(WS-NUM) " - "
            FUNCTION TRIM(LK-LABEL TRAILING)
    END-IF
    GOBACK.
END PROGRAM PLBT-REPORT.

*> PLBT-ASSERT-STR: EXPECTED and ACTUAL must compare equal.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLBT-ASSERT-STR.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-OK                   PIC X.
LINKAGE SECTION.
01  LK-LABEL                PIC X ANY LENGTH.
01  LK-EXPECTED             PIC X ANY LENGTH.
01  LK-ACTUAL               PIC X ANY LENGTH.
PROCEDURE DIVISION USING LK-LABEL LK-EXPECTED LK-ACTUAL.
    IF LK-EXPECTED = LK-ACTUAL
        MOVE "Y" TO LS-OK
    ELSE
        MOVE "N" TO LS-OK
    END-IF
    CALL "PLBT-REPORT" USING LK-LABEL LS-OK
    IF LS-OK = "N"
        DISPLAY "  ---"
        DISPLAY "  expected: '" FUNCTION TRIM(LK-EXPECTED TRAILING) "'"
        DISPLAY "  actual:   '" FUNCTION TRIM(LK-ACTUAL TRAILING) "'"
        DISPLAY "  ..."
    END-IF
    GOBACK.
END PROGRAM PLBT-ASSERT-STR.

*> PLBT-ASSERT-NUM: EXPECTED and ACTUAL (signed 18-digit) must be equal.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLBT-ASSERT-NUM.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-OK                   PIC X.
01  LS-SHOW                 PIC -(18)9.
LINKAGE SECTION.
01  LK-LABEL                PIC X ANY LENGTH.
01  LK-EXPECTED             PIC S9(18) COMP-5.
01  LK-ACTUAL               PIC S9(18) COMP-5.
PROCEDURE DIVISION USING LK-LABEL LK-EXPECTED LK-ACTUAL.
    IF LK-EXPECTED = LK-ACTUAL
        MOVE "Y" TO LS-OK
    ELSE
        MOVE "N" TO LS-OK
    END-IF
    CALL "PLBT-REPORT" USING LK-LABEL LS-OK
    IF LS-OK = "N"
        DISPLAY "  ---"
        MOVE LK-EXPECTED TO LS-SHOW
        DISPLAY "  expected: " FUNCTION TRIM(LS-SHOW)
        MOVE LK-ACTUAL TO LS-SHOW
        DISPLAY "  actual:   " FUNCTION TRIM(LS-SHOW)
        DISPLAY "  ..."
    END-IF
    GOBACK.
END PROGRAM PLBT-ASSERT-NUM.

*> PLBT-ASSERT-FLAG: a Y/N flag must hold the expected value.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLBT-ASSERT-FLAG.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-OK                   PIC X.
LINKAGE SECTION.
01  LK-LABEL                PIC X ANY LENGTH.
01  LK-EXPECTED             PIC X.
01  LK-ACTUAL               PIC X.
PROCEDURE DIVISION USING LK-LABEL LK-EXPECTED LK-ACTUAL.
    IF LK-EXPECTED = LK-ACTUAL
        MOVE "Y" TO LS-OK
    ELSE
        MOVE "N" TO LS-OK
    END-IF
    CALL "PLBT-REPORT" USING LK-LABEL LS-OK
    IF LS-OK = "N"
        DISPLAY "  ---"
        DISPLAY "  expected: " LK-EXPECTED
        DISPLAY "  actual:   " LK-ACTUAL
        DISPLAY "  ..."
    END-IF
    GOBACK.
END PROGRAM PLBT-ASSERT-FLAG.

*> PLBT-END: print the plan and summary; fail the run on any failure.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLBT-END.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbtstate.cpy".
01  WS-NUM                  PIC Z(8)9.
01  WS-FAILED               PIC Z(8)9.
PROCEDURE DIVISION.
    MOVE PLBT-TOTAL TO WS-NUM
    MOVE PLBT-FAILED TO WS-FAILED
    DISPLAY "1.." FUNCTION TRIM(WS-NUM)
    DISPLAY "# " FUNCTION TRIM(PLBT-SUITE TRAILING) ": "
        FUNCTION TRIM(WS-NUM) " assertions, "
        FUNCTION TRIM(WS-FAILED) " failed"
    IF PLBT-FAILED > 0
        MOVE 1 TO RETURN-CODE
    ELSE
        MOVE 0 TO RETURN-CODE
    END-IF
    GOBACK.
END PROGRAM PLBT-END.
