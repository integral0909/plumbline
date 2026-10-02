*> IBM Enterprise COBOL replaces parts of words written in
*> parentheses: ==(FIELD)== BY ==STATUS== turns FLG-(FIELD)-NOT-OK
*> into FLG-STATUS-NOT-OK. A subscript such as CELL (2) is untouched.
IDENTIFICATION DIVISION.
PROGRAM-ID. PARTIAL.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  FLG-STATUS-NOT-OK   PIC X.
01  MAIN-ATTR           PIC 9.
01  CELLS.
    05  CELL            PIC X OCCURS 3 TIMES.
PROCEDURE DIVISION.
    COPY SETATTR REPLACING ==(FIELD)== BY ==STATUS==
                           ==(SCREEN)== BY ==MAIN==.
    MOVE "A" TO CELL (2)
    STOP RUN.
