*> PLB-Q015 insert-count-mismatch: an INSERT without a column list
*> whose values are not as many as its table's declared columns.
IDENTIFICATION DIVISION.
PROGRAM-ID. INSNOLST.
DATA DIVISION.
WORKING-STORAGE SECTION.
    EXEC SQL DECLARE ACCOUNT TABLE
        ( ACCT_ID      INTEGER NOT NULL,
          OWNER        CHAR(30),
          BALANCE      DECIMAL(9,2) )
    END-EXEC.
01  WS-ID               PIC S9(9) COMP.
01  WS-NAME             PIC X(30).
01  WS-BALANCE          PIC S9(7)V99 COMP-3.
PROCEDURE DIVISION.
    *> Reported: two values for three columns.
    EXEC SQL
        INSERT INTO ACCOUNT VALUES (:WS-ID, :WS-NAME)
    END-EXEC
    *> Not reported: three values, and a table with no DECLARE TABLE.
    EXEC SQL
        INSERT INTO ACCOUNT VALUES (:WS-ID, :WS-NAME, :WS-BALANCE)
    END-EXEC
    EXEC SQL
        INSERT INTO HISTORY VALUES (:WS-ID)
    END-EXEC
    STOP RUN.
