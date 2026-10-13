*> PLB-C104 count-too-small: an INSPECT TALLYING or UNSTRING COUNT IN
*> item with too few digits for the count it can be given.
IDENTIFICATION DIVISION.
PROGRAM-ID. COUNTS.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-TEXT             PIC X(50) VALUE SPACES.
01  WS-SHORT            PIC X(18) VALUE SPACES.
01  WS-PAIR             PIC XX VALUE "AB".
01  WS-PART             PIC X(30).
01  WS-ONE              PIC 9 VALUE 0.
01  WS-TWO              PIC 99 VALUE 0.
01  WS-PACKED           PIC S9 COMP-3 VALUE 0.
01  WS-NATIVE           PIC 9 COMP-5 VALUE 0.
PROCEDURE DIVISION.
    *> Reported: 50 characters into one digit, and into a packed digit.
    MOVE 0 TO WS-ONE WS-PACKED
    INSPECT WS-TEXT TALLYING WS-ONE FOR CHARACTERS
    INSPECT WS-TEXT TALLYING WS-PACKED FOR ALL SPACES
    *> Reported: a two-character string, 25 times at most.
    MOVE 0 TO WS-ONE
    INSPECT WS-TEXT TALLYING WS-ONE FOR ALL WS-PAIR
    *> Reported: the second count; the first has two digits.
    MOVE 0 TO WS-TWO WS-ONE
    INSPECT WS-TEXT TALLYING WS-TWO FOR ALL "A"
                             WS-ONE FOR LEADING "B"
    *> Reported: COUNT IN of up to 50 characters.
    UNSTRING WS-TEXT DELIMITED BY "," INTO WS-PART COUNT IN WS-ONE
    *> Not reported: counts that fit (9 pairs of 18 characters), a
    *> count of native binary usage, and a reference-modified item.
    MOVE 0 TO WS-ONE WS-NATIVE
    INSPECT WS-SHORT TALLYING WS-ONE FOR ALL "AB"
    INSPECT WS-TEXT TALLYING WS-NATIVE FOR ALL "A"
    INSPECT WS-TEXT(1:9) TALLYING WS-ONE FOR ALL "A"
    UNSTRING WS-SHORT DELIMITED BY "," INTO WS-PART COUNT WS-TWO
    DISPLAY WS-ONE WS-TWO WS-PACKED WS-NATIVE WS-PART
    STOP RUN.
