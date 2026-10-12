*> PLB-C102 nested-if-decided: an IF first in the THEN branch of
*> another whose test the outer test already decides.
IDENTIFICATION DIVISION.
PROGRAM-ID. NESTEDIF.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AMOUNT           PIC S9(5)V99.
01  WS-COUNT            PIC 9(3).
01  WS-RATE             PIC 9(3) OCCURS 5 TIMES.
01  WS-I                PIC 9.
PROCEDURE DIVISION.
    MOVE 0 TO WS-AMOUNT WS-COUNT WS-I
    MOVE ALL "0" TO WS-RATE(1)
    *> Reported: always true.
    IF WS-AMOUNT > 100
        IF WS-AMOUNT > 50
            DISPLAY "OVER 50"
        ELSE
            DISPLAY "NEVER"
        END-IF
    END-IF
    *> Reported: never true, and the same element of a table.
    IF WS-COUNT NOT LESS THAN 100
        IF WS-COUNT < 10
            DISPLAY "NEVER"
        END-IF
    END-IF
    IF WS-RATE(WS-I) = 5
        IF WS-RATE(WS-I) >= 5
            DISPLAY "FIVE"
        END-IF
    END-IF
    *> Not reported: a test the outer one leaves open, another item or
    *> element, an IF after another statement, an IF in the ELSE, and
    *> ends that touch where both are closed.
    IF WS-AMOUNT > 100
        IF WS-AMOUNT > 500
            DISPLAY "OVER 500"
        END-IF
    END-IF
    IF WS-AMOUNT > 100
        IF WS-COUNT < 10
            DISPLAY "FEW"
        END-IF
    END-IF
    IF WS-RATE(1) > 10
        IF WS-RATE(2) < 5
            DISPLAY "OTHER"
        END-IF
    END-IF
    IF WS-COUNT > 10
        MOVE 0 TO WS-COUNT
        IF WS-COUNT < 5
            DISPLAY "RESET"
        END-IF
    END-IF
    IF WS-COUNT > 10
        DISPLAY "OVER 10"
    ELSE
        IF WS-COUNT > 20
            DISPLAY "PLB-C051 REPORTS THIS"
        END-IF
    END-IF
    IF WS-COUNT >= 10
        IF WS-COUNT <= 10
            DISPLAY "TEN"
        END-IF
    END-IF
    STOP RUN.
