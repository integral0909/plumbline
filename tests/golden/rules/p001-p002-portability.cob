*> Files assigned to paths, directly or through a data item, and
*> calls of compiler library routines (PLB-P001 is off by default, so
*> those calls are not reported here). Bare names are portable.
IDENTIFICATION DIVISION.
PROGRAM-ID. PORTABILITY.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT UNIX-FILE ASSIGN TO "/var/data/in.dat".
    SELECT DOS-FILE ASSIGN TO "C:\DATA\OUT.DAT".
    SELECT ITEM-FILE ASSIGN TO DYNAMIC ITEM-PATH.
    SELECT DD-FILE ASSIGN TO "INFILE".
    SELECT NAME-FILE ASSIGN TO NAME-ONLY.
DATA DIVISION.
FILE SECTION.
FD  UNIX-FILE.
01  UNIX-REC            PIC X(80).
FD  DOS-FILE.
01  DOS-REC             PIC X(80).
FD  ITEM-FILE.
01  ITEM-REC            PIC X(80).
FD  DD-FILE.
01  DD-REC              PIC X(80).
FD  NAME-FILE.
01  NAME-REC            PIC X(80).
WORKING-STORAGE SECTION.
01  ITEM-PATH           PIC X(40) VALUE "../shared/item.dat".
01  NAME-ONLY           PIC X(40) VALUE "names.dat".
01  RESULT              PIC S9(9) COMP-5.
PROCEDURE DIVISION.
    CALL "CBL_DELETE_FILE" USING ITEM-PATH RETURNING RESULT
    STOP RUN.
