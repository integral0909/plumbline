*> PLB-C063 varying-refmod-out-of-range: the counter of a PERFORM
*> VARYING, as the start or length of a reference modifier, goes
*> outside the item.
IDENTIFICATION DIVISION.
PROGRAM-ID. VARYREF.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  IX          PIC 9(3).
01  BLANKS      PIC 9(3) VALUE 0.
01  WS-NAME     PIC X(20).
PROCEDURE DIVISION.
    MOVE SPACES TO WS-NAME
    *> Starts at 30; the IF reads IX only in the modifier.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 30
        IF WS-NAME(IX:1) = SPACE
            ADD 1 TO BLANKS
        END-IF
    END-PERFORM
    *> Starts at 0, with the length left out.
    PERFORM VARYING IX FROM 0 BY 1 UNTIL IX > 19
        DISPLAY WS-NAME(IX:)
    END-PERFORM
    *> Ends at 21.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 19
        DISPLAY WS-NAME(IX:3)
    END-PERFORM
    *> Length 0, then ends at 22 with IX + 1.
    PERFORM VARYING IX FROM 0 BY 1 UNTIL IX > 20
        DISPLAY WS-NAME(1:IX)
    END-PERFORM
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 20
        DISPLAY WS-NAME(2:IX + 1)
    END-PERFORM
    *> Starts at -1, written with one sign.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 20
        DISPLAY WS-NAME(IX - 2:1)
    END-PERFORM
    *> Within the item.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 20
        DISPLAY WS-NAME(IX:1) WS-NAME(1:IX) WS-NAME(IX:)
    END-PERFORM
    *> Guarded: left alone.
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 30
        IF IX <= 20
            DISPLAY WS-NAME(IX:1)
        END-IF
    END-PERFORM
    DISPLAY BLANKS
    STOP RUN.
