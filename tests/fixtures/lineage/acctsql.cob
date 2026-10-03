       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTSQL.
      *> Lineage through embedded SQL: columns read into host
      *> variables, and host variables stored into columns.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL INCLUDE SQLCA END-EXEC.
           EXEC SQL DECLARE ACCOUNT TABLE
               ( ACCT_ID      CHAR(8)       NOT NULL,
                 BALANCE      DECIMAL(9,2)  NOT NULL,
                 CREDIT_LIMIT DECIMAL(9,2)  NOT NULL )
           END-EXEC.
           EXEC SQL DECLARE ACCT-CUR CURSOR FOR
               SELECT ACCT_ID, CREDIT_LIMIT FROM ACCOUNT
           END-EXEC.
       01  WS-ACCT-ID          PIC X(8).
       01  WS-BALANCE          PIC S9(7)V99 COMP-3.
       01  WS-LIMIT            PIC S9(7)V99 COMP-3.
       01  WS-NEW-BALANCE      PIC S9(7)V99 COMP-3.
       PROCEDURE DIVISION.
           EXEC SQL OPEN ACCT-CUR END-EXEC
           EXEC SQL FETCH ACCT-CUR INTO :WS-ACCT-ID, :WS-LIMIT
           END-EXEC
           EXEC SQL SELECT BALANCE INTO :WS-BALANCE
               FROM ACCOUNT WHERE ACCT_ID = :WS-ACCT-ID
           END-EXEC
           COMPUTE WS-NEW-BALANCE = WS-BALANCE + WS-LIMIT
           EXEC SQL UPDATE ACCOUNT SET BALANCE = :WS-NEW-BALANCE
               WHERE ACCT_ID = :WS-ACCT-ID
           END-EXEC
           EXEC SQL CLOSE ACCT-CUR END-EXEC
           GOBACK.
