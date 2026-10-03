*> PLB-C056 self-comparison.
IDENTIFICATION DIVISION.
PROGRAM-ID. SELFCMP.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-OLD-BALANCE      PIC S9(7)V99 VALUE 10.
01  WS-NEW-BALANCE      PIC S9(7)V99 VALUE 12.
01  WS-TABLE.
    05  WS-ENTRY        PIC X(4) OCCURS 10 VALUE SPACES.
01  WS-I                PIC 99 VALUE 1.
01  WS-J                PIC 99 VALUE 2.
01  WS-COUNT            PIC 99 VALUE 0.
PROCEDURE DIVISION.
    *> Reported: always false.
    IF WS-OLD-BALANCE NOT = WS-OLD-BALANCE
        DISPLAY "CHANGED"
    END-IF
    *> Reported: always true, written out.
    IF WS-NEW-BALANCE IS GREATER THAN OR EQUAL TO WS-NEW-BALANCE
        DISPLAY "NOT LOWER"
    END-IF
    *> Reported: the same entry on both sides.
    IF WS-ENTRY (WS-I) < WS-ENTRY (WS-I)
        DISPLAY "LOWER"
    END-IF
    *> Fine: different entries, different items, an expression, and
    *> the = of COMPUTE.
    IF WS-ENTRY (WS-I) = WS-ENTRY (WS-J)
       OR WS-OLD-BALANCE = WS-NEW-BALANCE
       OR WS-COUNT + 1 > WS-COUNT
        DISPLAY "SAME"
    END-IF
    COMPUTE WS-COUNT = WS-COUNT
    PERFORM UNTIL WS-COUNT > WS-I
        ADD 1 TO WS-COUNT
    END-PERFORM
    GOBACK.
