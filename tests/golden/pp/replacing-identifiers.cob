*> COPY REPLACING operands that are identifiers: qualified names and
*> subscripted names are replaced as a whole.
IDENTIFICATION DIVISION.
PROGRAM-ID. REPLID.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  OUTER.
    05  INNER.
        10  CELL    PIC X OCCURS 3.
01  TOTAL           PIC X.
PROCEDURE DIVISION.
    COPY MOVEONE REPLACING SOURCE-ITEM BY CELL OF INNER IN OUTER (2)
                           TARGET-ITEM BY TOTAL.
    STOP RUN.
