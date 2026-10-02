*> Numeric literals that start with a decimal point, with and without
*> a sign, and periods that end sentences.
IDENTIFICATION DIVISION.
PROGRAM-ID. DECIMALS.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  SMALL       PIC SV9(18) VALUE -.999999999999999999.
01  HALF        PIC V9 VALUE .5.
01  TINY        PIC SV9(7) VALUE +.0000009.
PROCEDURE DIVISION.
    COMPUTE HALF = FUNCTION ABS(-.5) + FUNCTION MIN(.5, .1).
    MOVE .5 TO HALF.
    STOP RUN.
