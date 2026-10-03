*> PLB-Q006 host-variable-too-small and PLB-Q007 host-variable-too-large:
*> host variables against the columns of the DECLARE TABLE.
IDENTIFICATION DIVISION.
PROGRAM-ID. HOSTVARS.
DATA DIVISION.
WORKING-STORAGE SECTION.
    EXEC SQL DECLARE BANK.ACCOUNT TABLE
    ( ACCT_ID                        DECIMAL(11, 0) NOT NULL,
      ACCT_NAME                      VARCHAR(40) NOT NULL,
      CITY                           CHAR(20),
      BALANCE                        DECIMAL(9, 2),
      VISITS                         INTEGER,
      BRANCH                         SMALLINT
    ) END-EXEC.
01  WS-ID                   PIC S9(11) COMP-3.
01  WS-SHORT-ID             PIC S9(7) COMP-3.
01  WS-NAME.
    49  WS-NAME-LEN         PIC S9(4) COMP.
    49  WS-NAME-TEXT        PIC X(30).
01  WS-CITY                 PIC X(20).
01  WS-LONG-CITY            PIC X(25).
01  WS-BALANCE              PIC S9(7)V99 COMP-3.
01  WS-ROUND-BALANCE        PIC S9(7) COMP-3.
01  WS-BIG-BALANCE          PIC S9(11)V999 COMP-3.
01  WS-VISITS               PIC S9(9) COMP.
01  WS-FEW-VISITS           PIC S9(4) COMP.
01  WS-BRANCH               PIC S9(4) COMP.
PROCEDURE DIVISION.
    *> Fine: each host variable fits its column.
    EXEC SQL SELECT ACCT_ID, CITY, BALANCE, VISITS, BRANCH
        INTO :WS-ID, :WS-CITY, :WS-BALANCE, :WS-VISITS, :WS-BRANCH
        FROM BANK.ACCOUNT WHERE ACCT_ID = 1
    END-EXEC
    *> Q006: too few integer digits, characters, and decimal places.
    EXEC SQL SELECT ACCT_ID, ACCT_NAME, BALANCE, VISITS
        INTO :WS-SHORT-ID, :WS-NAME, :WS-ROUND-BALANCE, :WS-FEW-VISITS
        FROM BANK.ACCOUNT WHERE ACCT_ID = 2
    END-EXEC
    *> Q007: values the columns cannot hold.
    EXEC SQL INSERT INTO BANK.ACCOUNT (ACCT_ID, CITY, BALANCE)
        VALUES (:WS-ID, :WS-LONG-CITY, :WS-BIG-BALANCE)
    END-EXEC
    *> Fine: the variables fit.
    EXEC SQL UPDATE BANK.ACCOUNT
        SET CITY = :WS-CITY, BALANCE = :WS-BALANCE
        WHERE ACCT_ID = :WS-ID
    END-EXEC
    STOP RUN.
