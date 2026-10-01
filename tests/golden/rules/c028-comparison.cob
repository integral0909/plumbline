*> Comparisons with a literal that the data item cannot hold, in IF,
*> UNTIL, EVALUATE WHEN, and SEARCH WHEN conditions. Comparisons that
*> can be true, arithmetic operands, binary items, decimals, and the
*> VARYING counter (PLB-C026 checks it) are not reported.
IDENTIFICATION DIVISION.
PROGRAM-ID. COMPARES.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  AGE                PIC 99 VALUE 0.
01  BALANCE            PIC 9(5) VALUE 0.
01  DELTA              PIC S9(3) VALUE 0.
01  HITS               PIC 9(4) COMP VALUE 0.
01  PRICE              PIC 9(3)V99 VALUE 0.
01  I                  PIC 99 VALUE 0.
01  CODES.
    05  CODE-ENTRY     PIC 9 OCCURS 5 INDEXED BY CX.
PROCEDURE DIVISION.
    IF AGE > 99
        DISPLAY "TOO OLD"
    END-IF
    IF BALANCE < 0
        DISPLAY "OVERDRAWN"
    END-IF
    IF AGE IS GREATER THAN OR EQUAL TO 100 OR BALANCE = 100000
        DISPLAY "OUT OF RANGE"
    END-IF
    PERFORM UNTIL AGE = 100
        ADD 1 TO AGE
    END-PERFORM
    EVALUATE TRUE
        WHEN DELTA < -999
            DISPLAY "LOW"
        WHEN OTHER
            CONTINUE
    END-EVALUATE
    SEARCH CODE-ENTRY
        WHEN CODE-ENTRY (CX) = 10
            DISPLAY "FOUND"
    END-SEARCH
    IF AGE = 99 OR DELTA < 0 OR BALANCE >= 99999
        DISPLAY "EDGES"
    END-IF
    IF AGE + BALANCE > 99
        DISPLAY "SUM"
    END-IF
    IF HITS > 9999
        DISPLAY "BINARY"
    END-IF
    IF PRICE > 999
        DISPLAY "DECIMAL"
    END-IF
    IF AGE NOT > 99
        DISPLAY "NOT"
    END-IF
    PERFORM VARYING I FROM 1 BY 1 UNTIL I > 99 OR BALANCE > 99999
        DISPLAY I
    END-PERFORM
    GOBACK.
