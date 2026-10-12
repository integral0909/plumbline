*> PLB-M021 empty-branch-statement: an IF or EVALUATE whose every
*> branch is CONTINUE or empty.
IDENTIFICATION DIVISION.
PROGRAM-ID. EMPTYIF.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-CODE             PIC X VALUE "A".
01  WS-COUNT            PIC 9(3) VALUE 0.
PROCEDURE DIVISION.
MAIN-LINE.
    *> Reported.
    IF WS-CODE = "A"
        CONTINUE
    END-IF
    EVALUATE WS-CODE
        WHEN "A"
            CONTINUE
        WHEN OTHER
            CONTINUE
    END-EVALUATE
    *> Not reported: one branch acts, NEXT SENTENCE, a nested IF, and
    *> an ELSE as empty as the THEN (PLB-C066), and a FUNCTION.
    IF FUNCTION RANDOM > 0.5
        CONTINUE
    END-IF
    EVALUATE TRUE
        WHEN FUNCTION RANDOM > 0.5
            CONTINUE
    END-EVALUATE
    IF WS-CODE = "B"
        CONTINUE
    ELSE
        CONTINUE
    END-IF
    IF WS-CODE = "A"
        CONTINUE
    ELSE
        ADD 1 TO WS-COUNT
    END-IF
    IF WS-CODE = "C"
        NEXT SENTENCE
    END-IF
    IF WS-CODE = "A"
        IF WS-COUNT = 0
            ADD 1 TO WS-COUNT
        END-IF
    END-IF
    DISPLAY WS-COUNT.
    STOP RUN.
