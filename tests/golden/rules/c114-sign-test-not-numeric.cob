*> PLB-C114 sign-test-not-numeric: POSITIVE, NEGATIVE, or ZERO sign
*> test of an item that is not numeric.
IDENTIFICATION DIVISION.
PROGRAM-ID. SIGNTEST.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-CODE             PIC X(4) VALUE "0012".
01  WS-NAME             PIC A(4) VALUE "ABCD".
01  WS-SHOWN            PIC ZZ9.99 VALUE ZERO.
01  WS-TOTALS.
    05  WS-COUNT        PIC 9(2) VALUE 0.
01  WS-AMOUNT           PIC S9(5)V99 VALUE -1.
PROCEDURE DIVISION.
    *> Reported.
    IF WS-CODE IS POSITIVE
        DISPLAY "code"
    END-IF
    IF WS-NAME NOT NEGATIVE
        DISPLAY "name"
    END-IF
    IF WS-SHOWN IS ZERO
        DISPLAY "shown"
    END-IF
    IF WS-TOTALS IS NOT ZERO
        DISPLAY "totals"
    END-IF
    *> Not reported: a number, an expression, and relations to ZERO.
    IF WS-AMOUNT IS NEGATIVE AND WS-COUNT IS ZERO
        DISPLAY "amount"
    END-IF
    IF WS-AMOUNT + 1 IS POSITIVE
        DISPLAY "sum"
    END-IF
    IF WS-CODE = ZERO OR WS-TOTALS = ZERO
        DISPLAY "relation"
    END-IF
    STOP RUN.
