*> PLB-C049 loop-condition-unchanged: a PERFORM UNTIL loop that never
*> changes what its condition reads.
IDENTIFICATION DIVISION.
PROGRAM-ID. LOOPCOND.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-FLAGS.
    05  WS-DONE             PIC X VALUE "N".
        88  ALL-DONE        VALUE "Y".
    05  WS-OTHER            PIC X VALUE "N".
01  WS-COUNT                PIC 9(4) VALUE 0.
01  WS-LIMIT                PIC 9(4) VALUE 10.
01  WS-TOTAL                PIC 9(6) VALUE 0.
01  WS-ALIAS REDEFINES WS-TOTAL PIC X(6).
01  WS-TABLE.
    05  WS-ENTRY            PIC X OCCURS 9 INDEXED BY WS-IX.
PROCEDURE DIVISION.
MAIN-LINE.
    *> Reported: nothing in the body changes WS-COUNT or WS-LIMIT.
    PERFORM UNTIL WS-COUNT > WS-LIMIT
        ADD 1 TO WS-TOTAL
    END-PERFORM
    *> Reported: STEP sets another flag than the one tested.
    PERFORM STEP UNTIL ALL-DONE
    *> Fine: the body counts.
    PERFORM UNTIL WS-COUNT > WS-LIMIT
        ADD 1 TO WS-COUNT
    END-PERFORM
    *> Fine: FINISH, performed from STEP-2, sets the 88's item.
    PERFORM STEP-2 UNTIL ALL-DONE
    *> Fine: the group holding the flag is stored into.
    PERFORM UNTIL WS-DONE = "Y"
        MOVE SPACES TO WS-FLAGS
    END-PERFORM
    *> Fine: the item shares storage with one that changes.
    PERFORM UNTIL WS-TOTAL > 5
        MOVE "000009" TO WS-ALIAS
    END-PERFORM
    *> Fine: the body moves the index the condition subscripts with.
    SET WS-IX TO 1
    PERFORM UNTIL WS-ENTRY(WS-IX) = "X"
        SET WS-IX UP BY 1
    END-PERFORM
    *> Fine: the loop can end by GO TO.
    PERFORM UNTIL WS-OTHER = "Y"
        GO TO DONE
    END-PERFORM
    *> Fine: VARYING and TIMES loops are other rules' concern.
    PERFORM STEP VARYING WS-COUNT FROM 1 BY 1 UNTIL WS-COUNT > 3
    PERFORM STEP 3 TIMES.
DONE.
    STOP RUN.
STEP.
    MOVE "Y" TO WS-OTHER.
STEP-2.
    PERFORM FINISH.
FINISH.
    SET ALL-DONE TO TRUE.
