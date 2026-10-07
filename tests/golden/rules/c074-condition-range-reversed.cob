*> PLB-C074 condition-range-reversed: VALUE a THRU b with a above b.
IDENTIFICATION DIVISION.
PROGRAM-ID. THRURNG.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-MONTH            PIC 99 VALUE 1.
    *> Reported: numbers.
    88  MONTH-VALID     VALUE 12 THRU 1.
    88  MONTH-SUMMER    VALUES 6 THROUGH 8.
    *> Reported: the second range of the clause.
    88  MONTH-ODD-END   VALUES 1 THRU 3, 12 THRU 10.
01  WS-DELTA            PIC S9V99 VALUE 0.
    *> Reported: signs and decimal places count.
    88  DELTA-NEGATIVE  VALUE -1 THRU -5.
    88  DELTA-SMALL     VALUE 1.5 THRU 1.25.
    88  DELTA-ZERO      VALUE -0.5 THRU 0.5.
01  WS-GRADE            PIC XX VALUE "A".
    *> Reported: letters of one case.
    88  GRADE-PASS      VALUE "D" THRU "A".
    *> Reported: the shorter value is padded with spaces.
    88  GRADE-PLUS      VALUE "AB" THRU "A".
    88  GRADE-ANY       VALUE "A" THRU "ZZ".
    *> Not reported: ASCII and EBCDIC order these differently.
    88  GRADE-MIXED     VALUE "a" THRU "Z".
    88  GRADE-DIGIT     VALUE "A" THRU "9".
    *> Not reported: hexadecimal literals.
    88  GRADE-HEX       VALUE X"FF" THRU X"00".
PROCEDURE DIVISION.
    IF MONTH-VALID OR MONTH-SUMMER OR MONTH-ODD-END
        DISPLAY "M"
    END-IF
    IF DELTA-NEGATIVE OR DELTA-SMALL OR DELTA-ZERO
        DISPLAY "D"
    END-IF
    IF GRADE-PASS OR GRADE-PLUS OR GRADE-ANY OR GRADE-MIXED
       OR GRADE-DIGIT OR GRADE-HEX
        DISPLAY "G"
    END-IF
    GOBACK.
