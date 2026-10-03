*> PLB-Q005 into-count-mismatch: an INTO list with another number of
*> host variables than the select list has columns.
IDENTIFICATION DIVISION.
PROGRAM-ID. INTOCNT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-ID                   PIC S9(9) COMP.
01  WS-NAME                 PIC X(30).
01  WS-BALANCE              PIC S9(9)V99 COMP-3.
01  WS-NAME-IND             PIC S9(4) COMP.
01  WS-ACCOUNT.
    05  WS-ACC-ID           PIC S9(9) COMP.
    05  WS-ACC-NAME         PIC X(30).
    EXEC SQL DECLARE ACCT-CUR CURSOR FOR
        SELECT ACCT_ID, ACCT_NAME, COALESCE(BALANCE, 0)
          FROM ACCOUNT
         WHERE STATUS IN ('A', 'P')
    END-EXEC.
    EXEC SQL DECLARE ALL-CUR CURSOR FOR
        SELECT * FROM ACCOUNT
    END-EXEC.
PROCEDURE DIVISION.
    EXEC SQL OPEN ACCT-CUR END-EXEC
    *> Reported: three columns into two host variables.
    EXEC SQL FETCH ACCT-CUR INTO :WS-ID, :WS-NAME END-EXEC
    *> Fine: an indicator goes with its host variable, and the comma
    *> inside COALESCE( , ) does not count.
    EXEC SQL FETCH ACCT-CUR
        INTO :WS-ID
            ,:WS-NAME :WS-NAME-IND
            ,:WS-BALANCE
    END-EXEC
    EXEC SQL CLOSE ACCT-CUR END-EXEC
    *> Reported: two columns into three host variables.
    EXEC SQL SELECT ACCT_ID, ACCT_NAME
        INTO :WS-ID, :WS-NAME, :WS-BALANCE
        FROM ACCOUNT WHERE ACCT_ID = 1
    END-EXEC
    *> Fine: SELECT * and a host structure are not counted.
    EXEC SQL OPEN ALL-CUR END-EXEC
    EXEC SQL FETCH ALL-CUR INTO :WS-ID END-EXEC
    EXEC SQL CLOSE ALL-CUR END-EXEC
    EXEC SQL SELECT ACCT_ID, ACCT_NAME, BALANCE
        INTO :WS-ACCOUNT FROM ACCOUNT WHERE ACCT_ID = 2
    END-EXEC
    STOP RUN.
