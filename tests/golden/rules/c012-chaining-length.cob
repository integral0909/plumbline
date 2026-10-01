*> Items that are not read before they are set: one named in
*> PROCEDURE DIVISION CHAINING gets its value from the command line,
*> and FUNCTION LENGTH only measures its argument. An item truly read
*> before it is set is still reported.
IDENTIFICATION DIVISION.
PROGRAM-ID. CHAINED.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  ARG-TEXT            PIC X(20).
01  WORK-TABLE.
    05  WORK-ROW        PIC X(4) OCCURS 10 TIMES.
01  ROW-LENGTH          PIC 9(4).
01  COUNTER             PIC 9(4).
PROCEDURE DIVISION CHAINING ARG-TEXT.
    IF ARG-TEXT = SPACES
        DISPLAY "no argument"
    END-IF
    COMPUTE ROW-LENGTH = FUNCTION LENGTH (WORK-TABLE)
    ADD 1 TO COUNTER
    MOVE ARG-TEXT TO WORK-ROW (1)
    MOVE 0 TO COUNTER
    DISPLAY ROW-LENGTH COUNTER WORK-ROW (1)
    STOP RUN.
