*> PLB-C062 varying-subscript-out-of-range: the counter of a PERFORM
*> VARYING, used as a subscript, goes outside the table.
IDENTIFICATION DIVISION.
PROGRAM-ID. VARYSUB.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  IX                  PIC 9(3).
01  JX                  PIC 9(3).
01  TOTAL               PIC 9(5) VALUE 0.
01  LINES-TABLE.
    05  LINE-ENTRY      PIC X(10) OCCURS 20.
01  GRID.
    05  GRID-ROW        OCCURS 4 INDEXED BY ROW-IX.
        10  GRID-CELL   PIC 9 OCCURS 5.
PROCEDURE DIVISION.
MAIN-LINE.
    MOVE SPACES TO LINES-TABLE
    MOVE ZERO TO GRID
    *> Reaches 25.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 25
        DISPLAY LINE-ENTRY(IX)
    END-PERFORM
    *> Starts at 0.
    PERFORM VARYING IX FROM 0 BY 1 UNTIL IX >= 20
        DISPLAY LINE-ENTRY(IX)
    END-PERFORM
    *> IX + 1 reaches 21.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX = 21
        IF LINE-ENTRY(IX) = LINE-ENTRY(IX + 1)
            ADD 1 TO TOTAL
        END-IF
    END-PERFORM
    *> BY 3 from 2: 2, 5, ..., 20; then 23 ends the loop. Fine.
    PERFORM VARYING IX FROM 2 BY 3 UNTIL IX > 21
        DISPLAY LINE-ENTRY(IX)
    END-PERFORM
    *> An index, and the inner dimension past its 5 entries.
    PERFORM VARYING ROW-IX FROM 1 BY 1 UNTIL ROW-IX > 4
              AFTER JX FROM 1 BY 1 UNTIL JX > 6
        ADD GRID-CELL(ROW-IX, JX) TO TOTAL
    END-PERFORM
    *> Out of line.
    PERFORM SHOW-LINE VARYING JX FROM 1 BY 1 UNTIL JX > 30
    *> Guarded: left alone.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 25
        IF IX <= 20
            DISPLAY LINE-ENTRY(IX)
        END-IF
    END-PERFORM
    *> A condition with more in it: left alone.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 25 OR TOTAL > 3
        DISPLAY LINE-ENTRY(IX)
    END-PERFORM
    *> Within the table.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 20
        DISPLAY LINE-ENTRY(IX)
    END-PERFORM
    *> IX - 1 is 0 on the first pass.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 20
        DISPLAY LINE-ENTRY(IX - 1)
    END-PERFORM
    DISPLAY TOTAL
    STOP RUN.
SHOW-LINE.
    DISPLAY LINE-ENTRY(JX).
