*> PLB-C105 string-edited-leading-space: STRING ... DELIMITED BY
*> SPACE of a numeric-edited item that can start with a space.
IDENTIFICATION DIVISION.
PROGRAM-ID. EDSPACE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-COUNT            PIC ZZZ9 VALUE 5.
01  WS-NET              PIC -9(5) VALUE 5.
01  WS-PRICE            PIC $$$9.99 VALUE 5.
01  WS-DELTA            PIC +(4)9 VALUE 5.
01  WS-CODE             PIC B99 VALUE 5.
01  WS-CHECK            PIC ***9 VALUE 5.
01  WS-TOTAL            PIC 9(4) VALUE 5.
01  WS-SIGNED           PIC +9(4) VALUE 5.
01  WS-NAME             PIC X(10) VALUE "SMITH".
01  WS-LINE             PIC X(80).
PROCEDURE DIVISION.
    *> Reported: Z, a leading -, a floating $ and +, and B.
    STRING "COUNT " WS-COUNT DELIMITED BY SPACE INTO WS-LINE
    STRING WS-NET ";" WS-PRICE DELIMITED BY SPACES INTO WS-LINE
    STRING WS-DELTA DELIMITED BY " " WS-CODE DELIMITED BY SPACE
        INTO WS-LINE
    *> Not reported: DELIMITED BY SIZE, asterisks, digits, a single
    *> +, and an alphanumeric item.
    STRING WS-COUNT DELIMITED BY SIZE INTO WS-LINE
    STRING WS-CHECK WS-TOTAL WS-SIGNED WS-NAME DELIMITED BY SPACE
        INTO WS-LINE
    DISPLAY WS-LINE
    STOP RUN.
