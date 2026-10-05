*> PLB-C028 comparison-never-true for alphanumeric items: an equality
*> with a literal longer than the item. Trailing spaces of the literal,
*> other operators, NOT, prefixed literals, and items whose size is not
*> their characters are not reported.
IDENTIFICATION DIVISION.
PROGRAM-ID. LONGLIT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  STATE-CODE         PIC X(2) VALUE SPACES.
01  FLAG               PIC A VALUE SPACE.
01  ACCOUNT.
    05  ACCOUNT-TYPE   PIC X(3) VALUE SPACES.
    05  ACCOUNT-NO     PIC 9(5) VALUE 0.
01  AMOUNT             PIC S9(5) COMP-3 VALUE 0.
PROCEDURE DIVISION.
    IF STATE-CODE = "TEX"
        DISPLAY "TEXAS"
    END-IF
    IF FLAG IS EQUAL TO 'YES'
        DISPLAY "YES"
    END-IF
    EVALUATE TRUE
        WHEN ACCOUNT-TYPE = "SAVINGS"
            DISPLAY "SAVINGS"
        WHEN ACCOUNT = "CHK00001X"
            DISPLAY "FIRST"
    END-EVALUATE
    EVALUATE STATE-CODE ALSO ACCOUNT-TYPE
        WHEN "TEX" ALSO "CHK"
            DISPLAY "TEXAS CHECKING"
        WHEN "TX" ALSO "SAVINGS"
            DISPLAY "TEXAS SAVINGS"
        WHEN "AL" THRU "WYO" ALSO ANY
            DISPLAY "A RANGE IS NOT CHECKED"
    END-EVALUATE
    PERFORM UNTIL STATE-CODE = "NONE"
        MOVE "NO" TO STATE-CODE
    END-PERFORM
    *> Not reported: trailing spaces, fits, other operators, NOT, a
    *> hexadecimal literal.
    IF STATE-CODE = "TX  "
       OR STATE-CODE = "TX"
       OR STATE-CODE < "TEX"
       OR STATE-CODE NOT = "TEX"
       OR STATE-CODE = X"C1C2C3"
        DISPLAY "TX"
    END-IF
    DISPLAY AMOUNT
    STOP RUN.
