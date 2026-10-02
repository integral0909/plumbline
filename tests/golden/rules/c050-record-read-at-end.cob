*> PLB-C050 record-read-at-end: the AT END phrase of a READ or RETURN
*> reads the file's record, which is undefined there.
IDENTIFICATION DIVISION.
PROGRAM-ID. ATEND.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT IN-FILE ASSIGN TO "in".
    SELECT OTHER-FILE ASSIGN TO "other".
    SELECT SORT-FILE ASSIGN TO "sortwork".
DATA DIVISION.
FILE SECTION.
FD  IN-FILE.
01  IN-REC.
    05  IN-KEY              PIC X(5).
        88  IN-TRAILER      VALUE "99999".
    05  IN-AMOUNT           PIC 9(7).
FD  OTHER-FILE.
01  OTHER-REC               PIC X(12).
SD  SORT-FILE.
01  SORT-REC.
    05  SORT-KEY            PIC X(5).
WORKING-STORAGE SECTION.
01  WS-LAST-KEY             PIC X(5).
01  WS-COUNT                PIC 9(5) VALUE 0.
01  WS-EOF                  PIC X VALUE "N".
PROCEDURE DIVISION.
MAIN-LINE.
    OPEN INPUT IN-FILE OTHER-FILE
    *> Reported: IN-KEY and the condition name on it, once each.
    READ IN-FILE
        AT END
            DISPLAY "LAST " IN-KEY
            IF NOT IN-TRAILER
                DISPLAY "NO TRAILER AFTER " IN-KEY
            END-IF
            MOVE "Y" TO WS-EOF
        NOT AT END
            MOVE IN-KEY TO WS-LAST-KEY
    END-READ
    *> Fine: a store into the record, and another file's record.
    READ IN-FILE
        AT END
            MOVE HIGH-VALUES TO IN-KEY
            DISPLAY OTHER-REC WS-LAST-KEY WS-COUNT
    END-READ
    CLOSE IN-FILE OTHER-FILE
    SORT SORT-FILE ON ASCENDING KEY SORT-KEY
        USING IN-FILE
        OUTPUT PROCEDURE IS SHOW-SORTED
    STOP RUN.
SHOW-SORTED.
    PERFORM UNTIL WS-EOF = "Y"
        *> Reported: the sort record after the last one is returned.
        RETURN SORT-FILE
            AT END
                MOVE "Y" TO WS-EOF
                DISPLAY "ENDED AT " SORT-KEY
        END-RETURN
    END-PERFORM.
