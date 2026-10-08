*> PLB-C065 open-in-loop: an OPEN on every pass of a loop that never
*> closes the file.
IDENTIFICATION DIVISION.
PROGRAM-ID. OPENLOOP.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT IN-FILE ASSIGN TO "IN.DAT"
        FILE STATUS IS WS-STATUS.
    SELECT OUT-FILE ASSIGN TO "OUT.DAT".
DATA DIVISION.
FILE SECTION.
FD  IN-FILE.
01  IN-REC              PIC X(80).
FD  OUT-FILE.
01  OUT-REC             PIC X(80).
WORKING-STORAGE SECTION.
01  WS-STATUS           PIC XX.
01  WS-PASS             PIC 9 VALUE 0.
01  WS-FIRST            PIC X VALUE "Y".
PROCEDURE DIVISION.
MAIN-LINE.
    *> Reported: the inline loop opens IN-FILE on every pass.
    PERFORM UNTIL WS-PASS > 3
        OPEN INPUT IN-FILE
        READ IN-FILE
        ADD 1 TO WS-PASS
    END-PERFORM
    *> Reported: the performed paragraph opens OUT-FILE three times.
    PERFORM WRITE-REPORT 3 TIMES
    *> Not reported: closed in the loop, or in a paragraph it performs.
    PERFORM VARYING WS-PASS FROM 1 BY 1 UNTIL WS-PASS > 3
        OPEN INPUT IN-FILE
        READ IN-FILE
        CLOSE IN-FILE
    END-PERFORM
    PERFORM UNTIL WS-PASS = 0
        OPEN EXTEND OUT-FILE
        PERFORM FINISH-OUTPUT
        SUBTRACT 1 FROM WS-PASS
    END-PERFORM
    *> Not reported: opened once, under an IF.
    PERFORM UNTIL WS-PASS > 3
        IF WS-FIRST = "Y"
            OPEN INPUT IN-FILE
            MOVE "N" TO WS-FIRST
        END-IF
        ADD 1 TO WS-PASS
    END-PERFORM
    *> Reported: a paragraph performed on every pass of an inline loop.
    PERFORM UNTIL WS-PASS > 3
        PERFORM OPEN-AGAIN
        ADD 1 TO WS-PASS
    END-PERFORM
    *> Not reported: 1 TIMES, and a PERFORM that does not loop.
    PERFORM 1 TIMES
        OPEN INPUT IN-FILE
    END-PERFORM
    PERFORM
        CLOSE IN-FILE
    END-PERFORM
    STOP RUN.
WRITE-REPORT.
    OPEN OUTPUT OUT-FILE
    WRITE OUT-REC.
FINISH-OUTPUT.
    WRITE OUT-REC
    CLOSE OUT-FILE.
OPEN-AGAIN.
    OPEN INPUT IN-FILE.
