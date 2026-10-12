*> PLB-C068 odo-count-out-of-range: the count of an OCCURS DEPENDING ON
*> table given a value outside the table's bounds.
IDENTIFICATION DIVISION.
PROGRAM-ID. ODOCOUNT.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reported: a VALUE above the maximum.
01  LINE-COUNT          PIC 999 VALUE 75.
01  ORDER-COUNT         PIC 999 VALUE 1.
01  ORDER-TABLE.
    05  ORDER-LINE      PIC X(40)
                        OCCURS 1 TO 50 DEPENDING ON ORDER-COUNT.
01  PRINT-AREA.
    05  PRINT-LINE      PIC X(80)
                        OCCURS 2 TO 60 DEPENDING ON LINE-COUNT.
01  SIGNED-COUNT        PIC S999 VALUE 1.
01  SIGNED-TABLE.
    05  SIGNED-LINE     PIC X(10)
                        OCCURS 1 TO 10 DEPENDING ON SIGNED-COUNT.
PROCEDURE DIVISION.
    *> Reported: above the maximum, and below the minimum.
    MOVE 60 TO ORDER-COUNT
    COMPUTE LINE-COUNT = 1
    *> Reported: a negative number, written with one sign, in a count
    *> with a sign.
    MOVE -3 TO SIGNED-COUNT
    *> Not reported: within the bounds, a count without a sign, which
    *> keeps 3 (PLB-C008 reports the MOVE), and values not written as
    *> numbers.
    MOVE -3 TO ORDER-COUNT
    MOVE 50 TO ORDER-COUNT
    COMPUTE LINE-COUNT = 2
    MOVE LINE-COUNT TO ORDER-COUNT
    COMPUTE ORDER-COUNT = LINE-COUNT + 1
    DISPLAY ORDER-LINE(1) PRINT-LINE(1) SIGNED-LINE(1)
    STOP RUN.
