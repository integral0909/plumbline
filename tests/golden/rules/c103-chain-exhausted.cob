*> PLB-C103 chain-exhausted: an IF or the last ELSE of an ELSE IF
*> chain that no value reaches.
IDENTIFICATION DIVISION.
PROGRAM-ID. EXHAUST.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AMOUNT           PIC S9(5)V99 VALUE 0.
01  WS-COUNT            PIC 9(3) VALUE 0.
01  WS-CODE             PIC X VALUE SPACE.
PROCEDURE DIVISION.
    *> Reported: the third test, which the first two take between them.
    IF WS-AMOUNT > 5
        DISPLAY "OVER 5"
    ELSE IF WS-AMOUNT < 8
        DISPLAY "UNDER 8"
    ELSE IF WS-AMOUNT >= 3
        DISPLAY "NEVER"
    END-IF
    END-IF
    END-IF
    *> Reported: the last ELSE, past a test of another item.
    IF WS-COUNT >= 100
        DISPLAY "LARGE"
    ELSE IF WS-CODE = "X"
        DISPLAY "CODE X"
    ELSE IF WS-COUNT < 100
        DISPLAY "SMALL"
    ELSE
        DISPLAY "NEVER"
    END-IF
    END-IF
    END-IF
    *> Not reported: values left (5 to 8 here), a range in the middle,
    *> which leaves two, and a test one earlier test holds (PLB-C051).
    IF WS-AMOUNT > 8
        DISPLAY "OVER 8"
    ELSE IF WS-AMOUNT < 5
        DISPLAY "UNDER 5"
    ELSE
        DISPLAY "5 TO 8"
    END-IF
    END-IF
    IF WS-COUNT = 50
        DISPLAY "FIFTY"
    ELSE IF WS-COUNT < 100
        DISPLAY "UNDER 100"
    ELSE
        DISPLAY "100 OR MORE"
    END-IF
    END-IF
    IF WS-COUNT >= 0
        DISPLAY "ANY"
    ELSE IF WS-COUNT = 7
        DISPLAY "PLB-C051 REPORTS THIS"
    END-IF
    END-IF
    STOP RUN.
