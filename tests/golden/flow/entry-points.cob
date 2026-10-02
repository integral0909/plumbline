*> ENTRY makes a second way into the program: the paragraph that holds
*> it runs when a caller calls that entry, and falls into the next one.
IDENTIFICATION DIVISION.
PROGRAM-ID. ACCOUNTS.
DATA DIVISION.
LINKAGE SECTION.
01  ACCOUNT-ID          PIC X(8).
PROCEDURE DIVISION.
OPEN-ACCOUNT.
    DISPLAY "OPEN"
    GOBACK.
CLOSE-ACCOUNT.
    ENTRY "CLOSEACC" USING ACCOUNT-ID
    DISPLAY "CLOSE " ACCOUNT-ID.
CLOSE-DONE.
    GOBACK.
NEVER-USED.
    DISPLAY "UNREACHABLE".
