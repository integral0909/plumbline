*> PLB-C080 initialize-loses-value: INITIALIZE replaces VALUE clauses
*> that nothing gives back.
IDENTIFICATION DIVISION.
PROGRAM-ID. INITVAL.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  HEADING-LINE.
    05  HL-TITLE        PIC X(12) VALUE "SALES REPORT".
    05  HL-SUBTITLE     PIC X(8)  VALUE "BY MONTH".
    05  FILLER          PIC X(3)  VALUE " - ".
    05  HL-BLANK        PIC X(4)  VALUE SPACES.
    05  HL-PAGE         PIC ZZ9   VALUE ZERO.
01  WORK-AREA.
    05  WA-STATE        PIC X     VALUE "N".
        88  WA-DONE               VALUE "Y".
        88  WA-NOT-DONE           VALUE "N".
    05  WA-LIMIT        PIC 9(3)  VALUE 100.
    05  WA-UNUSED       PIC X(3)  VALUE "ABC".
    05  WA-CODES        PIC X(3)  VALUE "XYZ".
    05  WA-CODE-TABLE REDEFINES WA-CODES.
        10  WA-CODE     PIC X OCCURS 3.
    05  WA-DEFAULT      PIC X(5)  VALUE "FIRST".
PROCEDURE DIVISION.
    *> Reported: HL-TITLE and HL-SUBTITLE are never given their values
    *> again; not FILLER, VALUE SPACES, or VALUE ZERO.
    INITIALIZE HEADING-LINE
    MOVE 1 TO HL-PAGE
    DISPLAY HEADING-LINE
    *> Not reported: WA-STATE is set by its condition name, WA-LIMIT by
    *> a MOVE, WA-CODES through its REDEFINES; WA-UNUSED is never read.
    *> Reported: WA-DEFAULT.
    INITIALIZE WORK-AREA
    SET WA-NOT-DONE TO TRUE
    MOVE 50 TO WA-LIMIT
    MOVE "Q" TO WA-CODE (1)
    DISPLAY WA-STATE WA-LIMIT WA-CODES WA-DEFAULT
    *> Not reported: the VALUE phrase gives the values back.
    INITIALIZE HEADING-LINE ALL TO VALUE
    GOBACK.
