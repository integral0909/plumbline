*> PLB-C051 duplicate-if-condition: an ELSE IF chain that tests the
*> same condition twice.
IDENTIFICATION DIVISION.
PROGRAM-ID. DUPIF.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-CODE                 PIC X.
01  WS-COUNT                PIC 9(3) VALUE 0.
PROCEDURE DIVISION.
    *> Reported: the third test repeats the first.
    IF WS-CODE = "A"
        DISPLAY "ADD"
    ELSE IF WS-CODE = "C"
        DISPLAY "CHANGE"
    ELSE IF WS-CODE = "A"
        DISPLAY "NEVER"
    END-IF END-IF END-IF
    *> Fine: something runs between the tests, so the second can differ.
    IF WS-COUNT > 5
        DISPLAY "MANY"
    ELSE
        ADD 10 TO WS-COUNT
        IF WS-COUNT > 5
            DISPLAY "NOW MANY"
        END-IF
    END-IF
    *> Fine: the same test in the THEN branch is true there, not dead.
    IF WS-CODE = "D"
        IF WS-CODE = "D"
            DISPLAY "DELETE"
        END-IF
    END-IF
    *> Fine: a FUNCTION can answer differently the second time.
    IF FUNCTION RANDOM > 0.5
        DISPLAY "HEADS"
    ELSE IF FUNCTION RANDOM > 0.5
        DISPLAY "TAILS, THEN HEADS"
    END-IF END-IF
    STOP RUN.
