*> PLB-C086 read-loop-end-only: a READ loop that ends only when the
*> file status is "10".
IDENTIFICATION DIVISION.
PROGRAM-ID. RDLOOP.
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
    88  FS-END          VALUE "10".
01  WS-COUNT            PIC 9(7) VALUE 0.
PROCEDURE DIVISION.
    OPEN INPUT IN-FILE
    *> Reported: inline, and a paragraph performed until a condition
    *> name of "10".
    PERFORM UNTIL WS-FS = "10"
        READ IN-FILE
        ADD 1 TO WS-COUNT
    END-PERFORM
    PERFORM READ-ONE UNTIL FS-END
    *> Not reported: the loop looks at the status, or can stop.
    PERFORM UNTIL WS-FS = "10"
        READ IN-FILE
        IF WS-FS NOT = "00" AND NOT = "10"
            DISPLAY "READ FAILED " WS-FS
        END-IF
    END-PERFORM
    PERFORM UNTIL WS-FS = "10"
        READ IN-FILE
        ADD 1 TO WS-COUNT
        IF WS-COUNT > 1000000
            STOP RUN
        END-IF
    END-PERFORM
    CLOSE IN-FILE
    GOBACK.
READ-ONE.
    READ IN-FILE
    ADD 1 TO WS-COUNT.
