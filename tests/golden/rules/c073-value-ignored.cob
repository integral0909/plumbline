*> PLB-C073 value-ignored: a VALUE clause in the FILE or LINKAGE
*> SECTION, where storage is not the program's own.
IDENTIFICATION DIVISION.
PROGRAM-ID. VALIGN.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT OUT-FILE ASSIGN TO "out.dat".
DATA DIVISION.
FILE SECTION.
FD  OUT-FILE.
*> Reported once, at the first VALUE of the record.
01  OUT-REC.
    05  OUT-TYPE        PIC X VALUE "H".
        *> Not reported: condition names.
        88  OUT-HEADER  VALUE "H".
    05  OUT-COUNT       PIC 9(4) VALUE ZERO.
LINKAGE SECTION.
*> Not reported: a constant.
78  LK-MAX              VALUE 10.
*> Reported: the caller's storage.
01  LK-FLAG             PIC X VALUE "N".
*> Not reported: ALLOCATE ... INITIALIZED gives it its value.
01  LK-AREA             PIC X(8) VALUE "AREA".
*> Not reported: INITIALIZE ... TO VALUE gives it its value.
01  LK-PARMS.
    05  LK-LIMIT        PIC 9(3) VALUE 100.
PROCEDURE DIVISION USING LK-FLAG LK-PARMS.
    ALLOCATE LK-AREA INITIALIZED
    INITIALIZE LK-PARMS ALL TO VALUE
    OPEN OUTPUT OUT-FILE
    MOVE LK-FLAG TO OUT-TYPE
    MOVE LK-LIMIT TO OUT-COUNT
    DISPLAY LK-AREA LK-MAX
    WRITE OUT-REC
    CLOSE OUT-FILE
    GOBACK.
