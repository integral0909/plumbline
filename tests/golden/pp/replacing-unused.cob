*> PP008: a REPLACING rule that replaces nothing in its copybook is
*> reported at the COPY; the rule that matches is not.
IDENTIFICATION DIVISION.
PROGRAM-ID. UNUSED.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY totals REPLACING ==TOTAL== BY ==GRAND-TOTAL==
                           ==SUBTOTAL== BY ==PART-TOTAL==.
PROCEDURE DIVISION.
    GOBACK.
