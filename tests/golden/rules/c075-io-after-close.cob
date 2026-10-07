*> PLB-C075 io-after-close: an operation on a file after its CLOSE,
*> with no OPEN between.
IDENTIFICATION DIVISION.
PROGRAM-ID. AFTERCLS.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT IN-FILE ASSIGN TO "in.dat" FILE STATUS IS WS-IN-STATUS.
    SELECT OUT-FILE ASSIGN TO "out.dat" FILE STATUS IS WS-OUT-STATUS.
DATA DIVISION.
FILE SECTION.
FD  IN-FILE.
01  IN-REC              PIC X(80).
FD  OUT-FILE.
01  OUT-REC             PIC X(80).
WORKING-STORAGE SECTION.
01  WS-IN-STATUS        PIC XX.
01  WS-OUT-STATUS       PIC XX.
01  WS-DONE             PIC X VALUE "N".
PROCEDURE DIVISION.
MAIN-PARA.
    OPEN INPUT IN-FILE OUTPUT OUT-FILE
    CLOSE IN-FILE
    *> Reported: READ fails with status 47.
    READ IN-FILE
    CLOSE OUT-FILE.
    *> Reported: a later sentence, inside an IF.
    IF WS-DONE = "N"
        WRITE OUT-REC
    END-IF.
    *> Not reported: OPEN between.
    OPEN INPUT IN-FILE
    CLOSE IN-FILE
    OPEN INPUT IN-FILE
    READ IN-FILE
    PERFORM CLOSE-PARA
    STOP RUN.
CLOSE-PARA.
    IF WS-DONE = "Y"
        CLOSE IN-FILE
        *> Reported: a second CLOSE, status 42.
        CLOSE IN-FILE
    ELSE
        *> Not reported: the other branch.
        READ IN-FILE
    END-IF
    *> Not reported: after the IF that closed it in one branch.
    READ IN-FILE
    CLOSE IN-FILE
    *> Not reported: the PERFORM may open the file again.
    PERFORM OPEN-PARA
    READ IN-FILE
    CLOSE IN-FILE.
OPEN-PARA.
    OPEN INPUT IN-FILE.
