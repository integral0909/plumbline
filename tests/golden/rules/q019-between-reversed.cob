*> PLB-Q019 between-reversed: an SQL BETWEEN whose first number is
*> above its second.
IDENTIFICATION DIVISION.
PROGRAM-ID. BETWEENR.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-COUNT            PIC S9(9) COMP.
01  WS-LOW              PIC S9(9) COMP.
PROCEDURE DIVISION.
    *> Reported: numbers, decimals, and negative numbers turned round.
    EXEC SQL
        SELECT COUNT(*) INTO :WS-COUNT FROM ACCOUNT
         WHERE AGE BETWEEN 65 AND 18
    END-EXEC
    EXEC SQL
        SELECT COUNT(*) INTO :WS-COUNT FROM ACCOUNT
         WHERE RATE BETWEEN 1.50 AND 0.75
           AND BALANCE NOT BETWEEN -5 AND -10
    END-EXEC
    *> Not reported: ends in order, a host variable, and an expression.
    EXEC SQL
        SELECT COUNT(*) INTO :WS-COUNT FROM ACCOUNT
         WHERE AGE BETWEEN 18 AND 65
           AND BALANCE BETWEEN -10 AND -5
           AND AGE BETWEEN :WS-LOW AND 10
           AND AGE BETWEEN 30 AND 20 + :WS-LOW
    END-EXEC
    DISPLAY WS-COUNT
    STOP RUN.
