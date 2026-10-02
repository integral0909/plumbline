*> ---------------------------------------------------------------
*> plbsym: the symbol table of data items.
*>
*> PLB-SYM-BUILD walks the syntax tree and makes one PLB-SYMBOLS entry
*> per data description entry, in three passes:
*>
*>   1. describe each item: name, level, section, parent group,
*>      picture analysis, usage (inherited from the group when not
*>      given), OCCURS, DEPENDING ON, REDEFINES, and VALUE; an
*>      elementary item's size follows from its picture and usage.
*>      Level-78 constants with numeric values are remembered, so that
*>      a later PIC X(MAX-LEN) is analyzed as the value it names;
*>   2. compute group sizes bottom-up: the sum of the members, each
*>      multiplied by its OCCURS, not counting REDEFINES members;
*>   3. compute offsets top-down: members follow one another inside
*>      their group, and an item that redefines another starts where
*>      that item starts.
*>
*> Diagnostic codes raised here:
*>   SY001  warning  invalid PICTURE character-string
*>   SY002  error    REDEFINES names no earlier item at the same level
*>   SY004  error    symbol table full
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-SYM-BUILD.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> The symbol entry made for each tree node (valid for DATA nodes of
*> the current build only).
01  WS-NODE-SYMBOL          PIC 9(9) COMP-5 OCCURS 400000 TIMES.
*> Running offset inside each group during the offset pass.
01  WS-CURSOR               PIC 9(9) COMP-5 OCCURS 100000 TIMES.
*> Level-78 constants with numeric values, for picture counts.
01  WS-CONSTANTS.
    05  WS-CONSTANT-COUNT   PIC 9(4) COMP-5.
    05  WS-CONSTANT         OCCURS 1000 TIMES.
        10  CN-PROGRAM      PIC 9(9) COMP-5.
        10  CN-NAME         PIC X(31).
        10  CN-VALUE        PIC X(10).
LOCAL-STORAGE SECTION.
COPY "plbpic.cpy".
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-SECTION              PIC X.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(256).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-HAS-PICTURE          PIC X.
01  LS-FULL                 PIC X VALUE "N".
01  LS-TIMES                PIC 9(9) COMP-5.
01  LS-DETAIL               PIC X(20).
01  LS-PICTURE              PIC X(256).
01  LS-PIC-POS              PIC 9(9) COMP-5.
01  LS-PIC-OUT              PIC 9(9) COMP-5.
01  LS-CLOSE                PIC 9(9) COMP-5.
01  LS-CONST-NAME           PIC X(31).
01  LS-C                    PIC 9(4) COMP-5.
01  LS-SUBSTITUTED          PIC X.
*> From the SPECIAL-NAMES of the current program.
01  LS-DECIMAL-COMMA        PIC X VALUE "N".
01  LS-CURRENCY             PIC X VALUE SPACE.
COPY "plbpic.cpy" REPLACING ==PLB-PIC-INFO== BY ==LS-SAVED-PIC==.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST PLB-SYMBOLS.
    MOVE 0 TO SY-COUNT LS-PROGRAM LS-DEPTH WS-CONSTANT-COUNT
    MOVE "?" TO LS-SECTION
    IF AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    PERFORM UNTIL LS-NODE = 0 OR LS-FULL = "Y"
        EVALUATE ND-KIND(LS-NODE)
            WHEN "PROG"
                MOVE LS-NODE TO LS-PROGRAM
                PERFORM READ-SPECIAL-NAMES
            WHEN "SECT"
                PERFORM NOTE-SECTION
            WHEN "DATA"
                PERFORM DESCRIBE-ITEM
        END-EVALUATE
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM COMPUTE-SIZES
    PERFORM COMPUTE-OFFSETS
    GOBACK.

NOTE-SECTION.
    EVALUATE ND-DETAIL(LS-NODE)
        WHEN "WORKING-STORAGE"  MOVE "W" TO LS-SECTION
        WHEN "LOCAL-STORAGE"    MOVE "L" TO LS-SECTION
        WHEN "LINKAGE"          MOVE "K" TO LS-SECTION
        WHEN "FILE"             MOVE "F" TO LS-SECTION
        WHEN "REPORT"           MOVE "R" TO LS-SECTION
        WHEN "SCREEN"           MOVE "S" TO LS-SECTION
        WHEN OTHER              MOVE "?" TO LS-SECTION
    END-EVALUATE.

*> Pass 1 ---------------------------------------------------------

DESCRIBE-ITEM.
    IF SY-COUNT >= SY-MAX
        MOVE "Y" TO LS-FULL
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS ND-TOK-FIRST(LS-NODE) "E" "SY004"
            "too many data items; the rest are not analyzed"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO SY-COUNT
    MOVE SY-COUNT TO LS-S
    MOVE LS-S TO WS-NODE-SYMBOL(LS-NODE)
    MOVE LS-NODE TO SY-NODE(LS-S)
    MOVE LS-PROGRAM TO SY-PROGRAM(LS-S)
    MOVE LS-SECTION TO SY-SECTION(LS-S)
    *> plumbline: ignore move-truncation -- level numbers are at most 88
    MOVE ND-NUM(LS-NODE) TO SY-LEVEL(LS-S)
    MOVE ND-NAME(LS-NODE) TO SY-NAME-TOKEN(LS-S)
    MOVE SPACES TO SY-NAME(LS-S) SY-USAGE(LS-S)
    IF ND-NAME(LS-NODE) > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-NODE)
            SY-NAME(LS-S) LS-LEN
    END-IF
    MOVE 0 TO SY-PARENT(LS-S) SY-DIGITS(LS-S) SY-SCALE(LS-S)
        SY-SIZE(LS-S) SY-OFFSET(LS-S) SY-OCCURS(LS-S)
        SY-ODO-TOKEN(LS-S) SY-REDEFINES(LS-S)
    MOVE "N" TO SY-SIGNED(LS-S) SY-HAS-VALUE(LS-S)
    IF ND-KIND(ND-PARENT(LS-NODE)) = "DATA"
        MOVE WS-NODE-SYMBOL(ND-PARENT(LS-NODE)) TO SY-PARENT(LS-S)
    END-IF

    MOVE "N" TO LS-HAS-PICTURE
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "CLAU"
            PERFORM DESCRIBE-CLAUSE
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM

    *> A member without its own usage takes its group's.
    IF SY-USAGE(LS-S) = SPACES AND SY-PARENT(LS-S) > 0
        MOVE SY-USAGE(SY-PARENT(LS-S)) TO SY-USAGE(LS-S)
    END-IF

    EVALUATE TRUE
        WHEN SY-LEVEL(LS-S) = 88
            MOVE "C" TO SY-CATEGORY(LS-S)
        WHEN SY-LEVEL(LS-S) = 66
            MOVE "R" TO SY-CATEGORY(LS-S)
        WHEN SY-LEVEL(LS-S) = 78
            MOVE "K" TO SY-CATEGORY(LS-S)
        WHEN LS-HAS-PICTURE = "Y"
            MOVE LS-SAVED-PIC TO PLB-PIC-INFO
            *> An invalid picture gives no reliable size.
            IF NOT PI-IS-INVALID OF PLB-PIC-INFO
                CALL "PLB-PIC-STORAGE" USING PLB-PIC-INFO SY-USAGE(LS-S)
                    SY-SIZE(LS-S)
                PERFORM ADD-SEPARATE-SIGN
            END-IF
        WHEN OTHER
            PERFORM CATEGORY-WITHOUT-PICTURE
            IF SY-CATEGORY(LS-S) = "U"
                MOVE 0 TO PI-SIZE OF PLB-PIC-INFO PI-DIGITS OF PLB-PIC-INFO
                CALL "PLB-PIC-STORAGE" USING PLB-PIC-INFO
                    SY-USAGE(LS-S) SY-SIZE(LS-S)
            END-IF
    END-EVALUATE
    IF SY-LEVEL(LS-S) = 78
        PERFORM REMEMBER-CONSTANT
    END-IF
    *> PIC X ANY LENGTH (a linkage item that takes the caller's
    *> length) has no size of its own.
    PERFORM VARYING LS-TOKEN FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-TOKEN >= ND-TOK-LAST(LS-NODE)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT LS-LEN
        IF LS-TEXT = "ANY" AND TK-IS-WORD(LS-TOKEN)
            COMPUTE LS-R = LS-TOKEN + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-R LS-TEXT LS-LEN
            IF LS-TEXT = "LENGTH"
                MOVE 0 TO SY-SIZE(LS-S)
            END-IF
        END-IF
    END-PERFORM
    *> A parent that has members is a group.
    IF SY-PARENT(LS-S) > 0 AND SY-LEVEL(LS-S) NOT = 88
       AND SY-LEVEL(LS-S) NOT = 66 AND SY-LEVEL(LS-S) NOT = 78
        MOVE "G" TO SY-CATEGORY(SY-PARENT(LS-S))
    END-IF.

DESCRIBE-CLAUSE.
    MOVE ND-DETAIL(LS-CHILD) TO LS-DETAIL
    EVALUATE LS-DETAIL
        WHEN "PICTURE"
            IF ND-NAME(LS-CHILD) > 0
                MOVE "Y" TO LS-HAS-PICTURE
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-CHILD)
                    LS-TEXT LS-LEN
                PERFORM SUBSTITUTE-CONSTANTS
                MOVE LS-DECIMAL-COMMA TO PI-DECIMAL-COMMA OF PLB-PIC-INFO
                MOVE LS-CURRENCY TO PI-CURRENCY OF PLB-PIC-INFO
                CALL "PLB-PIC-ANALYZE" USING LS-TEXT PLB-PIC-INFO
                MOVE PLB-PIC-INFO TO LS-SAVED-PIC
                MOVE PI-CATEGORY OF PLB-PIC-INFO TO SY-CATEGORY(LS-S)
                MOVE PI-DIGITS OF PLB-PIC-INFO TO SY-DIGITS(LS-S)
                MOVE PI-SCALE OF PLB-PIC-INFO TO SY-SCALE(LS-S)
                MOVE PI-SIGNED OF PLB-PIC-INFO TO SY-SIGNED(LS-S)
                IF PI-IS-INVALID OF PLB-PIC-INFO
                    CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET
                        PLB-DIAGNOSTICS PLB-TOKENS ND-NAME(LS-CHILD)
                        "W" "SY001" PI-ERROR OF PLB-PIC-INFO
                END-IF
            END-IF
        WHEN "VALUE"
            MOVE "Y" TO SY-HAS-VALUE(LS-S)
        WHEN "OCCURS"
            PERFORM DESCRIBE-OCCURS
        WHEN "REDEFINES"
            PERFORM FIND-REDEFINED
        WHEN "USAGE"
            *> USAGE IS x: the parser stored the usage word as detail.
            CONTINUE
        WHEN "SIGN" WHEN "JUSTIFIED" WHEN "SYNCHRONIZED"
        WHEN "BLANK-WHEN-ZERO" WHEN "EXTERNAL" WHEN "GLOBAL"
        WHEN "BASED" WHEN "RENAMES"
            CONTINUE
        WHEN OTHER
            *> A usage clause: USAGE IS COMP-3 or plain COMP-3.
            MOVE LS-DETAIL TO SY-USAGE(LS-S)
    END-EVALUATE.

*> DECIMAL-POINT IS COMMA and CURRENCY [SIGN] [IS] "c" [WITH PICTURE
*> SYMBOL "s"] in the environment division of program LS-NODE. A
*> nested program without its own keeps those of the program it is
*> in.
READ-SPECIAL-NAMES.
    IF ND-KIND(ND-PARENT(LS-NODE)) NOT = "PROG"
        MOVE "N" TO LS-DECIMAL-COMMA
        MOVE SPACE TO LS-CURRENCY
    END-IF
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "DIVN"
           AND ND-DETAIL(LS-CHILD) = "ENVIRONMENT"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-CHILD = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-TOKEN FROM ND-TOK-FIRST(LS-CHILD) BY 1
            UNTIL LS-TOKEN > ND-TOK-LAST(LS-CHILD)
        IF TK-IS-WORD(LS-TOKEN)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT LS-LEN
            EVALUATE LS-TEXT
                WHEN "DECIMAL-POINT"
                    MOVE LS-TOKEN TO LS-R
                    PERFORM NEXT-NON-NOISE-WORD
                    IF LS-TEXT = "COMMA"
                        MOVE "Y" TO LS-DECIMAL-COMMA
                    END-IF
                WHEN "CURRENCY"
                    PERFORM READ-CURRENCY
                WHEN "SYMBOL"
                    *> WITH PICTURE SYMBOL "s": the picture character.
                    COMPUTE LS-R = LS-TOKEN + 1
                    IF LS-R <= ND-TOK-LAST(LS-CHILD)
                        IF TK-IS-ALNUM(LS-R)
                            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-R
                                LS-TEXT LS-LEN
                            MOVE LS-TEXT(1:1) TO LS-CURRENCY
                        END-IF
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM.

*> CURRENCY [SIGN] [IS] "c": the first character of the literal.
READ-CURRENCY.
    COMPUTE LS-R = LS-TOKEN + 1
    PERFORM UNTIL LS-R > ND-TOK-LAST(LS-CHILD)
        IF TK-IS-ALNUM(LS-R)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-R LS-TEXT LS-LEN
            IF LS-LEN = 1
                MOVE LS-TEXT(1:1) TO LS-CURRENCY
            END-IF
            EXIT PERFORM
        END-IF
        IF NOT TK-IS-WORD(LS-R)
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-R LS-TEXT LS-LEN
        IF LS-TEXT NOT = "SIGN" AND LS-TEXT NOT = "IS"
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-R
    END-PERFORM.

*> LS-TEXT = the word after token LS-R, skipping IS.
NEXT-NON-NOISE-WORD.
    MOVE SPACES TO LS-TEXT
    ADD 1 TO LS-R
    IF LS-R <= ND-TOK-LAST(LS-CHILD) AND TK-IS-WORD(LS-R)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-R LS-TEXT LS-LEN
        IF LS-TEXT = "IS"
            ADD 1 TO LS-R
            MOVE SPACES TO LS-TEXT
            IF LS-R <= ND-TOK-LAST(LS-CHILD) AND TK-IS-WORD(LS-R)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-R LS-TEXT LS-LEN
            END-IF
        END-IF
    END-IF.

*> SIGN ... SEPARATE [CHARACTER] gives a signed display item a
*> character of its own for the sign. The nearest SIGN clause counts:
*> the item's, or else that of the group it is in.
ADD-SEPARATE-SIGN.
    IF PI-SIGNED OF PLB-PIC-INFO NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    IF SY-USAGE(LS-S) NOT = SPACES AND SY-USAGE(LS-S) NOT = "DISPLAY"
       AND SY-USAGE(LS-S) NOT = "NATIONAL"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-S TO LS-P
    PERFORM UNTIL LS-P = 0
        MOVE ND-FIRST(SY-NODE(LS-P)) TO LS-CHILD
        PERFORM UNTIL LS-CHILD = 0
            IF ND-KIND(LS-CHILD) = "CLAU" AND ND-DETAIL(LS-CHILD) = "SIGN"
                PERFORM VARYING LS-TOKEN FROM ND-TOK-FIRST(LS-CHILD) BY 1
                        UNTIL LS-TOKEN > ND-TOK-LAST(LS-CHILD)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT
                        LS-LEN
                    IF LS-TEXT = "SEPARATE" AND TK-IS-WORD(LS-TOKEN)
                        IF PI-IS-NATIONAL OF PLB-PIC-INFO
                           OR SY-USAGE(LS-S) = "NATIONAL"
                            ADD 2 TO SY-SIZE(LS-S)
                        ELSE
                            ADD 1 TO SY-SIZE(LS-S)
                        END-IF
                    END-IF
                END-PERFORM
                EXIT PARAGRAPH
            END-IF
            MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
        END-PERFORM
        MOVE SY-PARENT(LS-P) TO LS-P
    END-PERFORM.

*> Replace each "(NAME)" in LS-TEXT whose NAME is a level-78 constant
*> of the current program by "(value)".
SUBSTITUTE-CONSTANTS.
    IF WS-CONSTANT-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-PICTURE
    MOVE 1 TO LS-PIC-POS LS-PIC-OUT
    MOVE "N" TO LS-SUBSTITUTED
    PERFORM UNTIL LS-PIC-POS > LS-LEN
        IF LS-TEXT(LS-PIC-POS:1) = "(" AND LS-PIC-POS < LS-LEN
           AND LS-TEXT(LS-PIC-POS + 1:1) >= "A"
           AND LS-TEXT(LS-PIC-POS + 1:1) <= "Z"
            PERFORM TRY-CONSTANT
        ELSE
            MOVE LS-TEXT(LS-PIC-POS:1) TO LS-PICTURE(LS-PIC-OUT:1)
            ADD 1 TO LS-PIC-POS LS-PIC-OUT
        END-IF
    END-PERFORM
    IF LS-SUBSTITUTED = "Y"
        MOVE LS-PICTURE TO LS-TEXT
        CALL "PLB-STR-LENGTH" USING LS-TEXT LS-LEN
    END-IF.

TRY-CONSTANT.
    MOVE 0 TO LS-CLOSE
    PERFORM VARYING LS-TOKEN FROM LS-PIC-POS BY 1
            UNTIL LS-TOKEN > LS-LEN
        IF LS-TEXT(LS-TOKEN:1) = ")"
            MOVE LS-TOKEN TO LS-CLOSE
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE 0 TO LS-C
    IF LS-CLOSE > LS-PIC-POS + 1 AND LS-CLOSE - LS-PIC-POS - 1 <= 31
        MOVE LS-TEXT(LS-PIC-POS + 1:LS-CLOSE - LS-PIC-POS - 1)
            TO LS-CONST-NAME
        PERFORM FIND-CONSTANT
    END-IF
    IF LS-C = 0
        *> Not a known constant: copy the "(" and carry on.
        MOVE "(" TO LS-PICTURE(LS-PIC-OUT:1)
        ADD 1 TO LS-PIC-POS LS-PIC-OUT
    ELSE
        STRING "(" DELIMITED BY SIZE
               CN-VALUE(LS-C) DELIMITED BY SPACE
               ")" DELIMITED BY SIZE
            INTO LS-PICTURE WITH POINTER LS-PIC-OUT
        COMPUTE LS-PIC-POS = LS-CLOSE + 1
        MOVE "Y" TO LS-SUBSTITUTED
    END-IF.

*> LS-C = the constant named LS-CONST-NAME in this program, or 0.
FIND-CONSTANT.
    PERFORM VARYING LS-C FROM WS-CONSTANT-COUNT BY -1 UNTIL LS-C = 0
        IF CN-NAME(LS-C) = LS-CONST-NAME
           AND CN-PROGRAM(LS-C) = LS-PROGRAM
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> 78 NAME VALUE n: remember n when it is an unsigned integer.
REMEMBER-CONSTANT.
    IF SY-NAME(LS-S) = SPACES OR WS-CONSTANT-COUNT >= 1000
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-DETAIL(LS-CHILD) = "VALUE"
            COMPUTE LS-TOKEN = ND-TOK-FIRST(LS-CHILD) + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT LS-LEN
            IF LS-TEXT = "IS"
                ADD 1 TO LS-TOKEN
            END-IF
            IF TK-IS-NUMBER(LS-TOKEN) AND TK-TEXT-LEN(LS-TOKEN) <= 10
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT
                    LS-LEN
                IF FUNCTION TEST-NUMVAL(LS-TEXT(1:LS-LEN)) = 0
                   AND LS-TEXT(1:1) >= "0" AND LS-TEXT(1:1) <= "9"
                    ADD 1 TO WS-CONSTANT-COUNT
                    MOVE LS-PROGRAM TO CN-PROGRAM(WS-CONSTANT-COUNT)
                    MOVE SY-NAME(LS-S) TO CN-NAME(WS-CONSTANT-COUNT)
                    MOVE LS-TEXT(1:LS-LEN) TO CN-VALUE(WS-CONSTANT-COUNT)
                END-IF
            END-IF
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

*> OCCURS n [TO m] ...: the table has at most m (or n) entries. A
*> count may be a level-78 constant name.
DESCRIBE-OCCURS.
    COMPUTE LS-TOKEN = ND-TOK-FIRST(LS-CHILD) + 1
    PERFORM UNTIL LS-TOKEN > ND-TOK-LAST(LS-CHILD)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT LS-LEN
        EVALUATE TRUE
            WHEN TK-IS-NUMBER(LS-TOKEN)
                MOVE FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
                    TO SY-OCCURS(LS-S)
            WHEN LS-TEXT = "TO"
                CONTINUE
            WHEN OTHER
                MOVE LS-TEXT TO LS-CONST-NAME
                PERFORM FIND-CONSTANT
                IF LS-C = 0
                    EXIT PERFORM
                END-IF
                MOVE FUNCTION NUMVAL(CN-VALUE(LS-C)) TO SY-OCCURS(LS-S)
        END-EVALUATE
        ADD 1 TO LS-TOKEN
    END-PERFORM
    IF ND-FIRST(LS-CHILD) > 0
        MOVE ND-NAME(ND-FIRST(LS-CHILD)) TO SY-ODO-TOKEN(LS-S)
    END-IF.

*> The redefined item is the nearest earlier item of the same program
*> with the same level and name, with no item of a lower level in
*> between (it must be a sibling).
FIND-REDEFINED.
    IF ND-NAME(LS-CHILD) = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-CHILD) LS-TEXT
        LS-LEN
    COMPUTE LS-R = LS-S - 1
    PERFORM UNTIL LS-R = 0
        IF SY-PROGRAM(LS-R) NOT = SY-PROGRAM(LS-S)
           OR SY-LEVEL(LS-R) < SY-LEVEL(LS-S)
           AND SY-LEVEL(LS-R) NOT = 88
            MOVE 0 TO LS-R
            EXIT PERFORM
        END-IF
        IF SY-LEVEL(LS-R) = SY-LEVEL(LS-S)
           AND SY-NAME(LS-R) = LS-TEXT(1:31)
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-R
    END-PERFORM
    IF LS-R = 0
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS ND-NAME(LS-CHILD) "E" "SY002"
            "REDEFINES must name an earlier item at the same level"
    ELSE
        MOVE LS-R TO SY-REDEFINES(LS-S)
    END-IF.

*> Items without a picture: a group, or a usage that implies its own
*> format.
CATEGORY-WITHOUT-PICTURE.
    EVALUATE SY-USAGE(LS-S)
        WHEN "INDEX" WHEN "POINTER" WHEN "PROCEDURE-POINTER"
        WHEN "PROGRAM-POINTER" WHEN "COMP-1" WHEN "COMP-2"
        WHEN "COMPUTATIONAL-1" WHEN "COMPUTATIONAL-2"
        WHEN "FLOAT-SHORT" WHEN "FLOAT-LONG" WHEN "BINARY-CHAR"
        WHEN "BINARY-SHORT" WHEN "BINARY-LONG" WHEN "BINARY-DOUBLE"
        WHEN "OBJECT-REFERENCE"
            MOVE "U" TO SY-CATEGORY(LS-S)
        WHEN OTHER
            *> Becomes G if members follow; otherwise the picture is
            *> missing.
            MOVE "?" TO SY-CATEGORY(LS-S)
    END-EVALUATE.

*> Pass 2: sizes, members before groups -----------------------------

COMPUTE-SIZES.
    PERFORM VARYING LS-S FROM SY-COUNT BY -1 UNTIL LS-S = 0
        MOVE SY-PARENT(LS-S) TO LS-P
        IF LS-P > 0 AND SY-REDEFINES(LS-S) = 0
           AND SY-CATEGORY(LS-S) NOT = "C"
           AND SY-CATEGORY(LS-S) NOT = "R"
           AND SY-CATEGORY(LS-S) NOT = "K"
            PERFORM OCCURRENCES
            COMPUTE SY-SIZE(LS-P) = SY-SIZE(LS-P)
                + SY-SIZE(LS-S) * LS-TIMES
        END-IF
    END-PERFORM.

OCCURRENCES.
    MOVE 1 TO LS-TIMES
    IF SY-OCCURS(LS-S) > 0
        MOVE SY-OCCURS(LS-S) TO LS-TIMES
    END-IF.

*> Pass 3: offsets, groups before members --------------------------

COMPUTE-OFFSETS.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        MOVE SY-PARENT(LS-S) TO LS-P
        EVALUATE TRUE
            WHEN SY-REDEFINES(LS-S) > 0
                MOVE SY-OFFSET(SY-REDEFINES(LS-S)) TO SY-OFFSET(LS-S)
            WHEN LS-P = 0
                MOVE 0 TO SY-OFFSET(LS-S)
            WHEN SY-CATEGORY(LS-S) = "C" OR SY-CATEGORY(LS-S) = "R"
                MOVE SY-OFFSET(LS-P) TO SY-OFFSET(LS-S)
            WHEN OTHER
                MOVE WS-CURSOR(LS-P) TO SY-OFFSET(LS-S)
                PERFORM OCCURRENCES
                COMPUTE WS-CURSOR(LS-P) = WS-CURSOR(LS-P)
                    + SY-SIZE(LS-S) * LS-TIMES
        END-EVALUATE
        MOVE SY-OFFSET(LS-S) TO WS-CURSOR(LS-S)
    END-PERFORM.
END PROGRAM PLB-SYM-BUILD.
