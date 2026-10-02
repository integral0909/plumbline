*> Signed literals in pseudo-text: ==+00001== matches the literal
*> +00001 of the copybook, one token like it, and so does ==-.5==.
IDENTIFICATION DIVISION.
PROGRAM-ID. SIGNED.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  TOTAL               PIC S9(5)V9 VALUE 0.
PROCEDURE DIVISION.
    COPY signed REPLACING ==+00001== BY ==+2==
                          ==-.5== BY ==-.25==.
    DISPLAY TOTAL
    GOBACK.
