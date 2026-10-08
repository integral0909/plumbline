*> PLB-C083 close-in-loop: a CLOSE on every pass of a loop that never
*> opens the file again.
IDENTIFICATION DIVISION.
PROGRAM-ID. CLSLOOP.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT IN-FILE ASSIGN TO "in.dat" FILE STATUS IS WS-FS.
DATA DIVISION.
FILE SECTION.
FD  IN-FILE.
01  IN-REC              PIC X(80).
WORKING-STORAGE SECTION.
01  WS-FS               PIC XX.
01  WS-EOF              PIC X VALUE "N".
PROCEDURE DIVISION.
    OPEN INPUT IN-FILE
    *> Reported: in the inline body, and in a paragraph performed on
    *> every pass.
    PERFORM UNTIL WS-EOF = "Y"
        READ IN-FILE AT END MOVE "Y" TO WS-EOF END-READ
        CLOSE IN-FILE
    END-PERFORM
    PERFORM UNTIL WS-EOF = "Y"
        READ IN-FILE AT END MOVE "Y" TO WS-EOF END-READ
        PERFORM CLOSE-FILE
    END-PERFORM
    *> Not reported: the loop opens it again, the CLOSE is under an IF,
    *> and the loop performs a paragraph that opens and closes it.
    PERFORM UNTIL WS-EOF = "Y"
        OPEN INPUT IN-FILE
        READ IN-FILE AT END MOVE "Y" TO WS-EOF END-READ
        CLOSE IN-FILE
    END-PERFORM
    PERFORM UNTIL WS-EOF = "Y"
        READ IN-FILE AT END MOVE "Y" TO WS-EOF END-READ
        IF WS-EOF = "Y"
            CLOSE IN-FILE
        END-IF
    END-PERFORM
    PERFORM READ-ONE UNTIL WS-EOF = "Y"
    STOP RUN.
CLOSE-FILE.
    CLOSE IN-FILE.
READ-ONE.
    OPEN INPUT IN-FILE
    READ IN-FILE AT END MOVE "Y" TO WS-EOF END-READ
    CLOSE IN-FILE.
