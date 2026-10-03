*> PLB-C060 spaces-into-numeric.
IDENTIFICATION DIVISION.
PROGRAM-ID. PACKED.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT TOTALS-FILE ASSIGN TO "TOTALS"
        ORGANIZATION IS LINE SEQUENTIAL.
DATA DIVISION.
FILE SECTION.
FD  TOTALS-FILE.
01  TOTALS-REC.
    05  TR-BRANCH           PIC X(4).
    05  TR-AMOUNT           PIC S9(9)V99 COMP-3.
WORKING-STORAGE SECTION.
01  WS-TOTALS.
    05  WS-COUNT            PIC S9(7) COMP-3.
    05  WS-AMOUNT           PIC S9(9)V99 COMP-3.
    05  WS-NAME             PIC X(20).
01  WS-PRINT-LINE.
    05  PL-LABEL            PIC X(10).
    05  PL-PAGE             PIC 9(4).
PROCEDURE DIVISION.
ADD-ONE.
    *> Reported: WS-COUNT holds spaces when ADD reads it.
    MOVE SPACES TO WS-TOTALS
    ADD 1 TO WS-COUNT.
WRITE-EMPTY.
    *> Reported: the record is written with spaces in TR-AMOUNT.
    OPEN OUTPUT TOTALS-FILE
    MOVE SPACES TO TOTALS-REC
    MOVE "0001" TO TR-BRANCH
    WRITE TOTALS-REC
    CLOSE TOTALS-FILE.
FILL-FIRST.
    *> Fine: every packed item has a value before it is read.
    MOVE SPACES TO WS-TOTALS
    MOVE 0 TO WS-COUNT WS-AMOUNT
    ADD 1 TO WS-COUNT
    *> Fine: a READ fills the record.
    OPEN INPUT TOTALS-FILE
    MOVE SPACES TO TOTALS-REC
    READ TOTALS-FILE
        AT END MOVE "END" TO WS-NAME
    END-READ
    DISPLAY TR-AMOUNT
    CLOSE TOTALS-FILE
    *> Fine: nothing after it in the paragraph reads the items.
    MOVE SPACES TO WS-TOTALS
    MOVE "EMPTY" TO WS-NAME.
PRINT-BLANK.
    *> Fine: a DISPLAY item shows blanks in a print line.
    MOVE SPACES TO WS-PRINT-LINE
    DISPLAY WS-PRINT-LINE
    *> Reported: arithmetic on a zoned-decimal item holding spaces.
    MOVE SPACES TO WS-PRINT-LINE
    ADD 1 TO PL-PAGE.
SHOW.
    DISPLAY WS-NAME WS-AMOUNT PL-LABEL
    GOBACK.
