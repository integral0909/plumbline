*> PLB-C071 contradictory-condition: equalities of one item joined by
*> AND, or inequalities joined by OR.
IDENTIFICATION DIVISION.
PROGRAM-ID. CONTRA.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-STATUS           PIC XX VALUE "00".
01  WS-CODE             PIC 9(3) VALUE 0.
01  WS-TABLE.
    05  WS-FLAG         PIC X OCCURS 3.
PROCEDURE DIVISION.
    *> Reported: never true.
    IF WS-STATUS = "00" AND WS-STATUS = "23"
        DISPLAY "1"
    END-IF
    IF WS-STATUS = "00" AND "23"
        DISPLAY "2"
    END-IF
    IF WS-FLAG(1) IS EQUAL TO "Y" AND WS-FLAG(1) = "N"
        DISPLAY "3"
    END-IF
    *> Reported: always true.
    IF WS-CODE NOT = 100 OR 200
        DISPLAY "4"
    END-IF
    *> Not reported: OR of equalities, the same value, different items
    *> or subscripts, AND of inequalities, and other operators.
    IF WS-STATUS = "00" OR "23"
        DISPLAY "5"
    END-IF
    IF WS-CODE = 7 AND WS-CODE = 007
        DISPLAY "6"
    END-IF
    IF WS-FLAG(1) = "Y" AND WS-FLAG(2) = "N"
        DISPLAY "7"
    END-IF
    IF WS-STATUS NOT = "00" AND NOT = "23"
        DISPLAY "8"
    END-IF
    IF WS-CODE > 100 AND WS-CODE = 50
        DISPLAY "9"
    END-IF
    STOP RUN.
