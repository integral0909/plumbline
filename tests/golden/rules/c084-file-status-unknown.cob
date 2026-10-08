*> PLB-C084 file-status-unknown: a FILE STATUS item compared with a
*> code no I/O statement returns.
IDENTIFICATION DIVISION.
PROGRAM-ID. FSCODE.
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
    *> Reported: "11"; not "00" or "35".
    88  FS-OK           VALUE "00" "11".
    88  FS-MISSING      VALUE "35".
PROCEDURE DIVISION.
    MOVE "<>" TO WS-FS
    OPEN INPUT IN-FILE
    *> Reported: "01", and "1" after OR.
    IF WS-FS = "01" OR "1"
        DISPLAY "END"
    END-IF
    *> Reported: "13" in an EVALUATE; not "10" or "9A", an
    *> implementor's code.
    EVALUATE WS-FS
        WHEN "10" DISPLAY "END"
        WHEN "13" DISPLAY "?"
        WHEN "9A" DISPLAY "VENDOR"
    END-EVALUATE
    *> Not reported: a value the program moves in itself.
    IF WS-FS IS EQUAL TO "<>"
        DISPLAY "NOT SET"
    END-IF
    CLOSE IN-FILE
    GOBACK.
