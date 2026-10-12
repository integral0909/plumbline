*> PLB-C101 string-numeric-sender: STRING of a number with decimal
*> places or a sign kept in its last digit.
IDENTIFICATION DIVISION.
PROGRAM-ID. STRNUM.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-AMOUNT           PIC S9(5)V99 VALUE -1.5.
01  WS-BALANCE          PIC S9(5) VALUE -123.
01  WS-RATE             PIC 9(3)V99 VALUE 1.5.
01  WS-COUNT            PIC 9(5) VALUE 42.
01  WS-SHOWN            PIC -(5)9.99.
01  WS-SEPARATE         PIC S9(5) SIGN LEADING SEPARATE VALUE -7.
01  WS-DELIM            PIC S9 VALUE 0.
01  WS-LINE             PIC X(80).
PROCEDURE DIVISION.
    *> Reported: decimal places, a sign in the last digit.
    STRING "AMOUNT " WS-AMOUNT " BALANCE " WS-BALANCE
           " RATE " WS-RATE DELIMITED BY SIZE
        INTO WS-LINE
    *> Not reported: an unsigned integer, an edited item, a separate
    *> sign, and an item that is the delimiter.
    MOVE WS-AMOUNT TO WS-SHOWN
    STRING "COUNT " WS-COUNT " SHOWN " WS-SHOWN " SIGN " WS-SEPARATE
           DELIMITED BY SIZE
           WS-LINE DELIMITED BY WS-DELIM
        INTO WS-LINE
    DISPLAY WS-LINE
    STOP RUN.
