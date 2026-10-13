*> PLB-Q022 aggregate-in-where: an aggregate function in the WHERE of
*> embedded SQL.
IDENTIFICATION DIVISION.
PROGRAM-ID. AGGWHERE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-OWNER            PIC X(30).
01  WS-TOTAL            PIC S9(9)V99 COMP-3.
    *> Reported: SUM in a cursor's WHERE.
    EXEC SQL
        DECLARE BIG-CUR CURSOR FOR
            SELECT OWNER FROM PAYMENT
             WHERE SUM(AMOUNT) > 1000
             GROUP BY OWNER
    END-EXEC.
PROCEDURE DIVISION.
    *> Reported: COUNT after AND.
    EXEC SQL
        SELECT OWNER INTO :WS-OWNER FROM PAYMENT
         WHERE OWNER = 'X' AND COUNT(*) > 1
    END-EXEC
    *> Not reported: aggregates in HAVING, in the select list, and in a
    *> subquery of the WHERE.
    EXEC SQL
        SELECT SUM(AMOUNT) INTO :WS-TOTAL FROM PAYMENT
         WHERE AMOUNT > (SELECT AVG(AMOUNT) FROM PAYMENT)
         GROUP BY OWNER
        HAVING COUNT(*) > 1
    END-EXEC
    STOP RUN.
