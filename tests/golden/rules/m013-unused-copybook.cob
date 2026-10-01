*> Copybooks none of whose items the program uses, reported at the
*> COPY. Constants count as used when the data division sizes items
*> with them; a condition name uses its item; a copybook that only
*> copies others is judged by them; a copybook in the file section has
*> its file to answer for, and is left alone.
IDENTIFICATION DIVISION.
PROGRAM-ID. COPYBOOKS.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT ORDER-FILE ASSIGN TO "ORDERS".
DATA DIVISION.
FILE SECTION.
FD  ORDER-FILE.
COPY orders IN copy.
WORKING-STORAGE SECTION.
COPY lens IN copy.
COPY cust IN copy.
COPY orders IN copy.
COPY both IN copy.
PROCEDURE DIVISION.
    DISPLAY CUST-NAME
    IF STATUS-OK
        DISPLAY "OK"
    END-IF
    GOBACK.
