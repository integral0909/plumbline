>>SOURCE FORMAT IS FREE
*> Free-format lines that do not fit in columns 8-72: a long statement,
*> a literal longer than a line, an inline comment, an indented
*> paragraph header, and EXIT, which is not one.
IDENTIFICATION DIVISION.
PROGRAM-ID. LONGLINES.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  GREETING PIC X(120) VALUE "This literal is longer than the sixty-five columns a fixed-format line has room for".
01  TOTAL PIC 9(5) VALUE 0.
PROCEDURE DIVISION.
    MAIN-LINE.
        COMPUTE TOTAL = TOTAL + 1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10 + 11 + 12 + 13 + 14 *> a running total
        DISPLAY GREETING TOTAL.
    MAIN-EXIT.
        EXIT.
