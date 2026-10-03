*> PLB-C061 unchecked-numeric-move, which is off by default.
IDENTIFICATION DIVISION.
PROGRAM-ID. NUMMOVE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  IN-RECORD.
    05  IN-AMOUNT-X         PIC X(7).
    05  IN-COUNT-X          PIC X(3).
    05  IN-CODE             PIC X(4).
01  WS-AMOUNT               PIC 9(5)V99.
01  WS-COUNT                PIC 9(3).
01  WS-CODE                 PIC X(4).
01  WS-TOTAL                PIC 9(7)V99 VALUE 0.
PROCEDURE DIVISION.
TAKE-AMOUNT.
    ACCEPT IN-RECORD
    *> Reported: nothing tests the input.
    MOVE IN-AMOUNT-X TO WS-AMOUNT
    ADD WS-AMOUNT TO WS-TOTAL.
TAKE-COUNT.
    *> Fine: the sender is tested first.
    IF IN-COUNT-X IS NUMERIC
        MOVE IN-COUNT-X TO WS-COUNT
    END-IF
    *> Fine: the receiver is tested after.
    MOVE IN-AMOUNT-X(1:3) TO WS-COUNT
    IF WS-COUNT NOT NUMERIC
        MOVE 0 TO WS-COUNT
    END-IF
    *> Fine: an alphanumeric receiver.
    MOVE IN-CODE TO WS-CODE
    DISPLAY WS-TOTAL WS-COUNT WS-CODE
    GOBACK.
