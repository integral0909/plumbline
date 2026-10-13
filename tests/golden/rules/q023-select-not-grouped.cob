*> PLB-Q023 select-not-grouped: a column in the select list of a
*> grouped query that its GROUP BY does not name.
IDENTIFICATION DIVISION.
PROGRAM-ID. NOTGRP.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-OWNER            PIC X(30).
01  WS-TYPE             PIC X(2).
01  WS-TOTAL            PIC S9(9)V99 COMP-3.
01  WS-COUNT            PIC S9(9) COMP.
    *> Reported: a column with an aggregate and no GROUP BY.
    EXEC SQL
        DECLARE TOTAL-CUR CURSOR FOR
            SELECT OWNER, SUM(AMOUNT) FROM PAYMENT
    END-EXEC.
PROCEDURE DIVISION.
    *> Reported: a column the GROUP BY leaves out.
    EXEC SQL
        SELECT OWNER, PAY_TYPE, SUM(AMOUNT)
          INTO :WS-OWNER, :WS-TYPE, :WS-TOTAL
          FROM PAYMENT
         WHERE OWNER = 'X'
         GROUP BY OWNER
    END-EXEC
    *> Not reported: grouped columns, aggregates alone, and a query
    *> that does not group.
    EXEC SQL
        SELECT OWNER, PAY_TYPE, COUNT(*)
          INTO :WS-OWNER, :WS-TYPE, :WS-COUNT
          FROM PAYMENT
         GROUP BY OWNER, PAY_TYPE
    END-EXEC
    EXEC SQL
        SELECT COUNT(*), SUM(AMOUNT) INTO :WS-COUNT, :WS-TOTAL
          FROM PAYMENT
    END-EXEC
    EXEC SQL
        SELECT OWNER, PAY_TYPE INTO :WS-OWNER, :WS-TYPE
          FROM PAYMENT WHERE AMOUNT > 0
    END-EXEC
    STOP RUN.
