*> Constants are not reported as unused, whether a picture, an OCCURS
*> count, a VALUE, or another constant uses them or nothing does: a
*> program often declares a whole set of codes and uses some.
IDENTIFICATION DIVISION.
PROGRAM-ID. CONSTUSE.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  NAME-SIZE           VALUE 8.
78  TABLE-SIZE          VALUE 10.
78  START-VALUE         VALUE 5.
01  TWICE               CONSTANT AS NAME-SIZE * 2.
78  NEVER-USED          VALUE 3.
01  CUSTOMER-NAME       PIC X(NAME-SIZE).
01  LONG-NAME           PIC X(TWICE).
01  COUNTS.
    05  ONE-COUNT       PIC 99 VALUE START-VALUE OCCURS TABLE-SIZE TIMES.
PROCEDURE DIVISION.
    DISPLAY CUSTOMER-NAME LONG-NAME ONE-COUNT (1)
    STOP RUN.
