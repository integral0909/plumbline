*> ---------------------------------------------------------------
*> plbpic: PICTURE character-string analysis.
*>
*> PLB-PIC-ANALYZE works out an item's category, size, digits, scale,
*> and sign from its picture; PLB-PIC-STORAGE turns that into bytes
*> of storage for a given USAGE. Both are used by the symbol table
*> and by rules that compare the sizes of sending and receiving items.
*>
*> Symbols understood (after expanding repetitions such as X(10)):
*>   A X 9 N 1         character, digit, national, and boolean positions
*>   S                 operational sign (first symbol only, no position)
*>   V                 implied decimal point (no position)
*>   P                 decimal scaling position (no position)
*>   Z *               zero suppression; each stands for a digit
*>   + - $             a single one is an insertion character; when
*>                     repeated (floating insertion) every one after
*>                     the first stands for a digit
*>   CR DB             two-character sign
*>   . ,               actual decimal point and comma insertion
*>   B 0 /             simple insertion
*>   E                 exponent marker of a floating-point picture
*> ---------------------------------------------------------------

*> PLB-PIC-ANALYZE: analyze PICTURE into INFO (copy/plbpic.cpy).
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PIC-ANALYZE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-PIC                  PIC X(256).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-POS                  PIC 9(9) COMP-5.
01  LS-SYM                  PIC XX.
01  LS-CURRENCY-HITS        PIC 9(4) COMP-5.
01  LS-COUNT                PIC 9(9) COMP-5.
01  LS-CLOSE                PIC 9(9) COMP-5.
*> The position before the first significant digit of a count.
01  LS-FIRST-DIGIT          PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-SYMBOLS              PIC 9(9) COMP-5.
*> Positions by kind.
01  LS-N-A                  PIC 9(9) COMP-5.
01  LS-N-X                  PIC 9(9) COMP-5.
01  LS-N-9                  PIC 9(9) COMP-5.
01  LS-N-NAT                PIC 9(9) COMP-5.
01  LS-N-BOOL               PIC 9(9) COMP-5.
01  LS-N-P                  PIC 9(9) COMP-5.
01  LS-N-INSERT             PIC 9(9) COMP-5.
01  LS-N-NUM-EDIT           PIC 9(9) COMP-5.
01  LS-N-S                  PIC 9(9) COMP-5.
01  LS-N-V                  PIC 9(9) COMP-5.
01  LS-N-POINT              PIC 9(9) COMP-5.
01  LS-N-PLUS               PIC 9(9) COMP-5.
01  LS-N-MINUS              PIC 9(9) COMP-5.
01  LS-N-CURRENCY           PIC 9(9) COMP-5.
01  LS-AFTER-POINT          PIC X.
01  LS-SEEN-DIGIT           PIC X.
01  LS-DIGITS               PIC 9(9) COMP-5.
01  LS-SCALE                PIC S9(9) COMP-5.
01  LS-DIGIT-POS            PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-PICTURE              PIC X ANY LENGTH.
COPY "plbpic.cpy".
PROCEDURE DIVISION USING LK-PICTURE PLB-PIC-INFO.
    MOVE "?" TO PI-CATEGORY
    MOVE 0 TO PI-SIZE PI-DIGITS PI-SCALE
    MOVE "N" TO PI-SIGNED PI-SYMBOLIC
    MOVE SPACES TO PI-ERROR
    INITIALIZE LS-N-A LS-N-X LS-N-9 LS-N-NAT LS-N-BOOL LS-N-P
        LS-N-INSERT LS-N-NUM-EDIT LS-N-S LS-N-V LS-N-POINT LS-N-PLUS
        LS-N-MINUS LS-N-CURRENCY LS-DIGITS LS-SCALE LS-SYMBOLS
    MOVE "N" TO LS-AFTER-POINT LS-SEEN-DIGIT

    CALL "PLB-STR-LENGTH" USING LK-PICTURE LS-LEN
    IF LS-LEN = 0
        MOVE "empty picture" TO PI-ERROR
        GOBACK
    END-IF
    IF LS-LEN > LENGTH OF LS-PIC
        MOVE "picture longer than 256 characters" TO PI-ERROR
        GOBACK
    END-IF
    MOVE FUNCTION UPPER-CASE(LK-PICTURE(1:LS-LEN)) TO LS-PIC

    MOVE 1 TO LS-POS
    PERFORM UNTIL LS-POS > LS-LEN OR PI-ERROR NOT = SPACES
        PERFORM READ-SYMBOL
        IF PI-ERROR = SPACES
            PERFORM PROCESS-SYMBOL
        END-IF
    END-PERFORM
    IF PI-ERROR = SPACES
        PERFORM FINISH
    END-IF
    IF PI-ERROR NOT = SPACES
        MOVE "?" TO PI-CATEGORY
    END-IF
    GOBACK.

*> The symbol at LS-POS and its repetition count: "X(10)" is X ten
*> times; CR and DB are two-character symbols.
READ-SYMBOL.
    MOVE SPACES TO LS-SYM
    MOVE LS-PIC(LS-POS:1) TO LS-SYM(1:1)
    ADD 1 TO LS-POS
    IF (LS-SYM = "C" OR LS-SYM = "D") AND LS-POS <= LS-LEN
        IF LS-SYM = "C" AND LS-PIC(LS-POS:1) = "R"
           OR LS-SYM = "D" AND LS-PIC(LS-POS:1) = "B"
            MOVE LS-PIC(LS-POS:1) TO LS-SYM(2:1)
            ADD 1 TO LS-POS
        END-IF
    END-IF
    MOVE 1 TO LS-COUNT
    IF LS-POS <= LS-LEN AND LS-PIC(LS-POS:1) = "("
        MOVE 0 TO LS-CLOSE
        PERFORM VARYING LS-K FROM LS-POS BY 1 UNTIL LS-K > LS-LEN
            IF LS-PIC(LS-K:1) = ")"
                MOVE LS-K TO LS-CLOSE
                EXIT PERFORM
            END-IF
        END-PERFORM
        *> Leading zeros do not make a count larger: X(0020) is X(20).
        MOVE LS-POS TO LS-FIRST-DIGIT
        IF LS-CLOSE > LS-POS + 2
            PERFORM UNTIL LS-FIRST-DIGIT + 2 >= LS-CLOSE
                IF LS-PIC(LS-FIRST-DIGIT + 1:1) NOT = "0"
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-FIRST-DIGIT
            END-PERFORM
        END-IF
        EVALUATE TRUE
            WHEN LS-CLOSE = 0
                MOVE "unbalanced parenthesis" TO PI-ERROR
            WHEN LS-CLOSE = LS-POS + 1
                MOVE "empty repetition count" TO PI-ERROR
            WHEN LS-PIC(LS-POS + 1:1) >= "A"
                 AND LS-PIC(LS-POS + 1:1) <= "Z"
                *> A constant name (level 78) as the count.
                MOVE "Y" TO PI-SYMBOLIC
                COMPUTE LS-POS = LS-CLOSE + 1
            WHEN LS-CLOSE - LS-FIRST-DIGIT - 1 > 9
                MOVE "repetition count too large" TO PI-ERROR
            WHEN FUNCTION TEST-NUMVAL(LS-PIC(LS-POS + 1:
                                      LS-CLOSE - LS-POS - 1)) NOT = 0
                MOVE "repetition count is not a number" TO PI-ERROR
            WHEN OTHER
                MOVE FUNCTION NUMVAL(LS-PIC(LS-POS + 1:
                                     LS-CLOSE - LS-POS - 1)) TO LS-COUNT
                IF LS-COUNT = 0
                    MOVE "repetition count must be at least 1"
                        TO PI-ERROR
                END-IF
                COMPUTE LS-POS = LS-CLOSE + 1
        END-EVALUATE
    END-IF
    ADD 1 TO LS-SYMBOLS.

PROCESS-SYMBOL.
    *> Symbols as the program's SPECIAL-NAMES define them.
    IF PI-DECIMAL-COMMA = "Y"
        EVALUATE LS-SYM
            WHEN ". "
                MOVE ", " TO LS-SYM
            WHEN ", "
                MOVE ". " TO LS-SYM
        END-EVALUATE
    END-IF
    IF LS-SYM(2:1) = SPACE AND LS-SYM(1:1) NOT = SPACE
       AND PI-CURRENCY NOT = SPACES AND PI-CURRENCY NOT = LOW-VALUES
        MOVE 0 TO LS-CURRENCY-HITS
        INSPECT PI-CURRENCY TALLYING LS-CURRENCY-HITS
            FOR ALL LS-SYM(1:1)
        IF LS-CURRENCY-HITS > 0
            MOVE "$ " TO LS-SYM
        END-IF
    END-IF
    EVALUATE LS-SYM
        WHEN "A "
            ADD LS-COUNT TO LS-N-A
            ADD LS-COUNT TO PI-SIZE
        WHEN "X "
            ADD LS-COUNT TO LS-N-X
            ADD LS-COUNT TO PI-SIZE
        WHEN "9 "
            ADD LS-COUNT TO LS-N-9
            ADD LS-COUNT TO PI-SIZE
            MOVE LS-COUNT TO LS-DIGIT-POS
            PERFORM ADD-DIGITS
        WHEN "N "
            ADD LS-COUNT TO LS-N-NAT
            ADD LS-COUNT TO PI-SIZE
        WHEN "1 "
            ADD LS-COUNT TO LS-N-BOOL
            ADD LS-COUNT TO PI-SIZE
        WHEN "S "
            IF LS-SYMBOLS NOT = 1 OR LS-COUNT NOT = 1
                MOVE "S must appear once, as the first symbol"
                    TO PI-ERROR
            END-IF
            ADD 1 TO LS-N-S
            MOVE "Y" TO PI-SIGNED
        WHEN "V "
            ADD LS-COUNT TO LS-N-V
            MOVE "Y" TO LS-AFTER-POINT
        WHEN "P "
            ADD LS-COUNT TO LS-N-P
            PERFORM SCALING-POSITIONS
        WHEN "Z "
        WHEN "* "
            ADD LS-COUNT TO LS-N-NUM-EDIT
            ADD LS-COUNT TO PI-SIZE
            MOVE LS-COUNT TO LS-DIGIT-POS
            PERFORM ADD-DIGITS
        WHEN "+ "
            PERFORM FLOATING-SYMBOL
            ADD LS-COUNT TO LS-N-PLUS
            MOVE "Y" TO PI-SIGNED
        WHEN "- "
            PERFORM FLOATING-SYMBOL
            ADD LS-COUNT TO LS-N-MINUS
            MOVE "Y" TO PI-SIGNED
        WHEN "$ "
            PERFORM FLOATING-SYMBOL
            ADD LS-COUNT TO LS-N-CURRENCY
        WHEN "CR"
        WHEN "DB"
            ADD 1 TO LS-N-NUM-EDIT
            ADD 2 TO PI-SIZE
            MOVE "Y" TO PI-SIGNED
        WHEN ". "
            ADD LS-COUNT TO LS-N-POINT LS-N-NUM-EDIT PI-SIZE
            MOVE "Y" TO LS-AFTER-POINT
        WHEN ", "
            ADD LS-COUNT TO LS-N-NUM-EDIT PI-SIZE
        WHEN "B "
        WHEN "0 "
        WHEN "/ "
            ADD LS-COUNT TO LS-N-INSERT PI-SIZE
        WHEN "E "
            ADD 1 TO LS-N-NUM-EDIT PI-SIZE
        WHEN OTHER
            MOVE SPACES TO PI-ERROR
            STRING "invalid character '" LS-SYM(1:1) "' in picture"
                DELIMITED BY SIZE INTO PI-ERROR
    END-EVALUATE.

*> A floating insertion string: the first +, -, or $ is the
*> insertion character; each later one stands for a digit.
FLOATING-SYMBOL.
    ADD LS-COUNT TO LS-N-NUM-EDIT PI-SIZE
    EVALUATE TRUE
        WHEN LS-SYM = "+ " AND LS-N-PLUS > 0
        WHEN LS-SYM = "- " AND LS-N-MINUS > 0
        WHEN LS-SYM = "$ " AND LS-N-CURRENCY > 0
            MOVE LS-COUNT TO LS-DIGIT-POS
        WHEN OTHER
            COMPUTE LS-DIGIT-POS = LS-COUNT - 1
    END-EVALUATE
    IF LS-DIGIT-POS > 0
        PERFORM ADD-DIGITS
    END-IF.

ADD-DIGITS.
    ADD LS-DIGIT-POS TO LS-DIGITS
    IF LS-AFTER-POINT = "Y"
        ADD LS-DIGIT-POS TO LS-SCALE
    END-IF
    MOVE "Y" TO LS-SEEN-DIGIT.

*> P to the right of the digits scales up (99PPP is a multiple of
*> 1000); P before any digit scales down (PPP99 or VPPP99 is less
*> than .001).
SCALING-POSITIONS.
    ADD LS-COUNT TO LS-DIGITS
    IF LS-SEEN-DIGIT = "Y" AND LS-AFTER-POINT = "N"
        SUBTRACT LS-COUNT FROM LS-SCALE
    ELSE
        *> Leading P implies a decimal point to its left: the digits
        *> that follow are fractional too.
        ADD LS-COUNT TO LS-SCALE
        MOVE "Y" TO LS-AFTER-POINT
    END-IF.

*> Decide the category and check the combination of symbols.
FINISH.
    EVALUATE TRUE
        WHEN LS-N-V > 1
            MOVE "more than one V" TO PI-ERROR
        WHEN LS-N-POINT > 1
            MOVE "more than one decimal point" TO PI-ERROR
        WHEN LS-N-V > 0 AND LS-N-POINT > 0
            MOVE "both V and a decimal point" TO PI-ERROR
        WHEN LS-DIGITS > 38
            MOVE "more than 38 digit positions" TO PI-ERROR
    END-EVALUATE
    IF PI-ERROR NOT = SPACES
        EXIT PARAGRAPH
    END-IF

    EVALUATE TRUE
        WHEN LS-N-BOOL > 0
            IF LS-N-A + LS-N-X + LS-N-9 + LS-N-NAT + LS-N-INSERT
               + LS-N-NUM-EDIT + LS-N-S + LS-N-V + LS-N-P > 0
                MOVE "boolean positions mixed with other symbols"
                    TO PI-ERROR
            ELSE
                MOVE "1" TO PI-CATEGORY
            END-IF
        WHEN LS-N-NAT > 0
            IF LS-N-A + LS-N-X + LS-N-9 + LS-N-NUM-EDIT + LS-N-S
               + LS-N-V + LS-N-P > 0
                MOVE "national positions mixed with other symbols"
                    TO PI-ERROR
            ELSE
                IF LS-N-INSERT > 0
                    MOVE "M" TO PI-CATEGORY
                ELSE
                    MOVE "N" TO PI-CATEGORY
                END-IF
            END-IF
        WHEN LS-N-X > 0 OR (LS-N-A > 0 AND LS-N-9 > 0)
            PERFORM ALPHANUMERIC-CATEGORY
        WHEN LS-N-A > 0
            PERFORM ALPHANUMERIC-CATEGORY
            IF PI-ERROR = SPACES AND LS-N-INSERT = 0
                MOVE "A" TO PI-CATEGORY
            END-IF
        WHEN LS-DIGITS > 0
            IF LS-N-NUM-EDIT + LS-N-INSERT > 0
                IF LS-N-S > 0
                    MOVE "S cannot be used in an edited picture"
                        TO PI-ERROR
                ELSE
                    MOVE "E" TO PI-CATEGORY
                END-IF
            ELSE
                MOVE "9" TO PI-CATEGORY
            END-IF
        WHEN OTHER
            MOVE "picture has no character positions" TO PI-ERROR
    END-EVALUATE
    *> plumbline: ignore move-truncation -- digits are limited to 38 above
    MOVE LS-DIGITS TO PI-DIGITS
    *> plumbline: ignore move-truncation -- the scale is within the 38-digit limit checked above
    MOVE LS-SCALE TO PI-SCALE.

*> A, X, and 9 together: alphanumeric, or alphanumeric-edited with
*> simple insertion. Numeric editing makes no sense here.
ALPHANUMERIC-CATEGORY.
    EVALUATE TRUE
        WHEN LS-N-NUM-EDIT > 0 OR LS-N-S > 0 OR LS-N-V > 0
             OR LS-N-P > 0
            MOVE "numeric symbols in an alphanumeric picture"
                TO PI-ERROR
        WHEN LS-N-INSERT > 0
            MOVE "D" TO PI-CATEGORY
        WHEN OTHER
            MOVE "X" TO PI-CATEGORY
    END-EVALUATE.
END PROGRAM PLB-PIC-ANALYZE.

*> PLB-PIC-STORAGE: bytes of storage for an item described by INFO
*> with USAGE (spaces or DISPLAY for the default). Binary sizes follow
*> the common convention of 2, 4, or 8 bytes by digit count; pointers
*> are 8 bytes, as on 64-bit platforms. Usages that need no picture
*> (COMP-1, INDEX, POINTER, BINARY-LONG, ...) ignore INFO.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PIC-STORAGE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-USAGE                PIC X(20).
LINKAGE SECTION.
COPY "plbpic.cpy".
01  LK-USAGE                PIC X ANY LENGTH.
01  LK-BYTES                PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-PIC-INFO LK-USAGE LK-BYTES.
    MOVE FUNCTION UPPER-CASE(LK-USAGE) TO LS-USAGE
    EVALUATE LS-USAGE
        WHEN SPACES
        WHEN "DISPLAY"
            IF PI-IS-NATIONAL OR PI-IS-NATIONAL-EDITED
                COMPUTE LK-BYTES = PI-SIZE * 2
            ELSE
                MOVE PI-SIZE TO LK-BYTES
            END-IF
        WHEN "NATIONAL"
            COMPUTE LK-BYTES = PI-SIZE * 2
        WHEN "COMP-3" WHEN "COMPUTATIONAL-3" WHEN "PACKED-DECIMAL"
            DIVIDE PI-DIGITS BY 2 GIVING LK-BYTES
            ADD 1 TO LK-BYTES
        WHEN "BINARY" WHEN "COMP" WHEN "COMPUTATIONAL"
        WHEN "COMP-4" WHEN "COMPUTATIONAL-4"
        WHEN "COMP-5" WHEN "COMPUTATIONAL-5"
            EVALUATE TRUE
                WHEN PI-DIGITS <= 4
                    MOVE 2 TO LK-BYTES
                WHEN PI-DIGITS <= 9
                    MOVE 4 TO LK-BYTES
                WHEN PI-DIGITS <= 18
                    MOVE 8 TO LK-BYTES
                WHEN OTHER
                    MOVE 16 TO LK-BYTES
            END-EVALUATE
        WHEN "COMP-X" WHEN "COMPUTATIONAL-X"
            *> The fewest bytes whose range covers the digits.
            EVALUATE TRUE
                WHEN PI-DIGITS <= 2   MOVE 1 TO LK-BYTES
                WHEN PI-DIGITS <= 4   MOVE 2 TO LK-BYTES
                WHEN PI-DIGITS <= 7   MOVE 3 TO LK-BYTES
                WHEN PI-DIGITS <= 9   MOVE 4 TO LK-BYTES
                WHEN PI-DIGITS <= 12  MOVE 5 TO LK-BYTES
                WHEN PI-DIGITS <= 14  MOVE 6 TO LK-BYTES
                WHEN PI-DIGITS <= 16  MOVE 7 TO LK-BYTES
                WHEN OTHER            MOVE 8 TO LK-BYTES
            END-EVALUATE
        WHEN "COMP-1" WHEN "COMPUTATIONAL-1" WHEN "FLOAT-SHORT"
        WHEN "BINARY-LONG"
        WHEN "INDEX"
            MOVE 4 TO LK-BYTES
        WHEN "COMP-2" WHEN "COMPUTATIONAL-2" WHEN "FLOAT-LONG"
        WHEN "BINARY-DOUBLE" WHEN "POINTER" WHEN "PROCEDURE-POINTER"
        WHEN "PROGRAM-POINTER" WHEN "OBJECT-REFERENCE"
            MOVE 8 TO LK-BYTES
        WHEN "BINARY-CHAR"
            MOVE 1 TO LK-BYTES
        WHEN "BINARY-SHORT"
            MOVE 2 TO LK-BYTES
        WHEN OTHER
            MOVE PI-SIZE TO LK-BYTES
    END-EVALUATE
    GOBACK.
END PROGRAM PLB-PIC-STORAGE.
