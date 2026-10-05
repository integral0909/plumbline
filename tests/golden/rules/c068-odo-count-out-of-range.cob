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
PROCEDURE DIVISION.
    *> Reported: above the maximum, and below the minimum.
    MOVE 60 TO ORDER-COUNT
    COMPUTE LINE-COUNT = 1
    *> Not reported: within the bounds, and values not written as
    *> numbers.
    MOVE 50 TO ORDER-COUNT
    COMPUTE LINE-COUNT = 2
    MOVE LINE-COUNT TO ORDER-COUNT
    COMPUTE ORDER-COUNT = LINE-COUNT + 1
    DISPLAY ORDER-LINE(1) PRINT-LINE(1)
    STOP RUN.
