*> PLB-C079 nonnumeric-literal-move: an alphanumeric literal that is not
*> a number moved to a numeric item.
IDENTIFICATION DIVISION.
PROGRAM-ID. NONNUM.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-COUNT            PIC 9(3).
01  WS-AMOUNT           PIC S9(5)V99 COMP-3.
01  WS-TEXT             PIC X(5).
01  WS-EDITED           PIC ZZ9.
PROCEDURE DIVISION.
    *> Reported: letters, a decimal point, a space.
    MOVE "ABC" TO WS-COUNT
    MOVE "1.50" TO WS-AMOUNT
    MOVE "12 " TO WS-COUNT
    *> Not reported: digits only, an alphanumeric or edited receiver,
    *> a numeric literal, and a hexadecimal literal.
    MOVE "123" TO WS-COUNT
    MOVE "ABC" TO WS-TEXT
    MOVE "ABC" TO WS-EDITED
    MOVE 1.50 TO WS-AMOUNT
    MOVE X"F1F2" TO WS-COUNT
    DISPLAY WS-COUNT WS-AMOUNT WS-TEXT WS-EDITED
    GOBACK.
