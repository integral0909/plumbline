*> PLB-C057 misleading-indentation.
IDENTIFICATION DIVISION.
PROGRAM-ID. INDENTS.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AMOUNT           PIC 9(5) VALUE 10.
01  WS-LIMIT            PIC 9(5) VALUE 5.
01  WS-OVER-LIMIT       PIC X VALUE "N".
01  WS-COUNT            PIC 9(3) VALUE 0.
PROCEDURE DIVISION.
CHECK-LIMIT.
    *> Reported: the period ends the IF, so DISPLAY always runs.
    IF WS-AMOUNT > WS-LIMIT
        MOVE "Y" TO WS-OVER-LIMIT.
        DISPLAY "OVER LIMIT"
    *> Reported: after an ELSE too.
    IF WS-AMOUNT = 0
        DISPLAY "ZERO"
    ELSE
        DISPLAY "NOT ZERO".
        ADD 1 TO WS-COUNT
    *> Fine: the next sentence starts where the IF does.
    IF WS-AMOUNT > 100
        DISPLAY "LARGE".
    DISPLAY WS-COUNT.
    *> Fine: the body leaves, so the indented code is the "else".
    IF WS-COUNT > 5
        GO TO DONE.
        ADD 1 TO WS-COUNT.
    *> Reported: an inline PERFORM's body.
    PERFORM UNTIL WS-COUNT > 3
        ADD 1 TO WS-COUNT
    END-PERFORM.
        DISPLAY WS-COUNT.
DONE.
    DISPLAY WS-OVER-LIMIT
    GOBACK.
