*> PLB-C078 string-literal-cut: a STRING literal that holds its own
*> delimiter.
IDENTIFICATION DIVISION.
PROGRAM-ID. STRCUT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-NAME             PIC X(10) VALUE "SMITH".
01  WS-SEP              PIC X VALUE ";".
01  WS-LINE             PIC X(60).
PROCEDURE DIVISION.
    *> Reported: cut at its space; then one sent nothing.
    STRING "DEAR MR " WS-NAME DELIMITED BY SPACE
           " WELCOME" DELIMITED BY ALL SPACES
        INTO WS-LINE
    *> Reported: a literal delimiter, and QUOTE.
    STRING "A,B" DELIMITED BY ","
           "SAY ""HI""" DELIMITED BY QUOTE
        INTO WS-LINE
    *> Not reported: by SIZE, by a data item, a literal without its
    *> delimiter, a function's argument, and a hexadecimal literal.
    STRING "DEAR MR " DELIMITED BY SIZE
           "A;B" DELIMITED BY WS-SEP
           "SMITH" DELIMITED BY SPACE
           FUNCTION TRIM(" X ") DELIMITED BY SPACE
           X"2020" DELIMITED BY SPACE
        INTO WS-LINE
    DISPLAY WS-LINE
    GOBACK.
