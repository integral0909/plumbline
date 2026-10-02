*> Screen section entries carry attributes with numeric operands
*> (colors, positions) that are not level numbers; an entry may have
*> no name. A level number starts its line.
IDENTIFICATION DIVISION.
PROGRAM-ID. SCREENS.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  REPLY               PIC X.
SCREEN SECTION.
01  MAIN-SCREEN.
    05  BLANK SCREEN BACKGROUND-COLOR 1 FOREGROUND-COLOR 7.
    05  LINE 2 COLUMN 10 VALUE "Continue?" HIGHLIGHT.
    05  LINE 2 COLUMN 21 PIC X USING REPLY REVERSE-VIDEO.
PROCEDURE DIVISION.
    DISPLAY MAIN-SCREEN
    ACCEPT MAIN-SCREEN
    STOP RUN.
