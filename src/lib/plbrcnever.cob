*> ---------------------------------------------------------------
*> plbrcnever: PLB-C090 condition-never-true.
*>
*> A condition name that is tested, when nothing gives its item one of
*> its values:
*>
*>     01  WS-EOF          PIC X VALUE "N".
*>         88  END-OF-FILE VALUE "Y".
*>         ...
*>         MOVE "E" TO WS-EOF
*>         PERFORM PROCESS-RECORD UNTIL END-OF-FILE     never true
*>
*> Only items that some statement stores into are read: one that keeps
*> its VALUE is a switch set by editing the program, and one with none
*> is PLB-C011's.
*>
*> Read is every way the item gets a value: its VALUE clause (or, with
*> none, the spaces or zero GnuCOBOL starts it with), MOVE of a literal
*> to it, SET of one of its condition names TO TRUE or FALSE,
*> INITIALIZE, and MOVE of SPACE, ZERO, or INITIALIZE of a group it is
*> in. Any other statement that stores into it or storage it shares
*> (MOVE of an item, READ INTO, ACCEPT, CALL BY REFERENCE, embedded
*> SQL or CICS INTO, a REDEFINES) makes its values unknown, and the
*> item is not read. Left out too are items of the LINKAGE, FILE,
*> SCREEN, and REPORT sections, FILE STATUS items (I/O statements set
*> them), the SQLCA, EXTERNAL, BASED, and JUSTIFIED items, and files
*> with a SCREEN SECTION. Literals with a prefix (X"...") are not
*> compared, nor ranges of characters.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C090.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbspan.cpy" REPLACING ==PLB-SPANS== BY ==WS-SPANS==.
COPY "plbstat.cpy" REPLACING ==PLB-STATUS-ITEMS== BY ==WS-STATUS==.
78  VALUE-MAX               VALUE 32.
78  ELEMENT-MAX             VALUE 32.
78  STATUS-MAX              VALUE 512.
*> The symbols of FILE STATUS items.
01  WS-STATUS-COUNT         PIC 9(4) COMP-5.
01  WS-STATUS-SYMBOL        PIC 9(9) COMP-5 OCCURS STATUS-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-J                    PIC 9(4) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-TEST                 PIC 9(9) COMP-5.
01  LS-OK                   PIC X.
01  LS-RESULT               PIC X.
01  LS-STORES               PIC 9(9) COMP-5.
01  LS-OVERLAP              PIC X.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> One value: K A text (LS-V-TEXT), S spaces, N number (LS-V-NUMBER);
*> space when it cannot be read.
01  LS-V-KIND               PIC X.
01  LS-V-TEXT               PIC X(64).
01  LS-V-NUMBER             PIC S9(18)V9(9) COMP-3.
*> The values the item can hold.
01  LS-VALUE-COUNT          PIC 9(4) COMP-5.
01  LS-VALUE-KIND           PIC X OCCURS VALUE-MAX TIMES.
01  LS-VALUE-TEXT           PIC X(64) OCCURS VALUE-MAX TIMES.
01  LS-VALUE-NUMBER         PIC S9(18)V9(9) COMP-3 OCCURS VALUE-MAX TIMES.
*> The values of the condition name: each a value or, for numbers, a
*> range to LS-ELEMENT-HIGH.
01  LS-ELEMENT-COUNT        PIC 9(4) COMP-5.
01  LS-ELEMENT-KIND         PIC X OCCURS ELEMENT-MAX TIMES.
01  LS-ELEMENT-TEXT         PIC X(64) OCCURS ELEMENT-MAX TIMES.
01  LS-ELEMENT-NUMBER       PIC S9(18)V9(9) COMP-3 OCCURS ELEMENT-MAX TIMES.
01  LS-ELEMENT-HIGH         PIC S9(18)V9(9) COMP-3 OCCURS ELEMENT-MAX TIMES.
01  LS-AFTER-THRU           PIC X.
01  LS-LIMIT                PIC S9(18)V9(9) COMP-3.
01  LS-SCALED               PIC S9(18)V9(9) COMP-3.
01  LS-SHOWN                PIC X(40).
01  LS-NUM-EDIT             PIC -(18)9.9(9).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C090" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    *> A SCREEN SECTION's ACCEPT stores into items no reference shows.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-SECTION(LS-S) = "S"
            GOBACK
        END-IF
    END-PERFORM
    CALL "PLB-SPAN-BUILD" USING PLB-SYMBOLS WS-SPANS
    CALL "PLB-STATUS-ITEMS" USING PLB-TOKENS PLB-AST WS-STATUS
    MOVE 0 TO WS-STATUS-COUNT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-CATEGORY(LS-S) NOT = "C"
            CALL "PLB-STATUS-ITEM-OF" USING PLB-SYMBOLS WS-STATUS LS-S
                LS-RESULT
            IF LS-RESULT = "Y" AND WS-STATUS-COUNT < STATUS-MAX
                ADD 1 TO WS-STATUS-COUNT
                MOVE LS-S TO WS-STATUS-SYMBOL(WS-STATUS-COUNT)
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > SY-COUNT
        IF SY-LEVEL(LS-C) = 88 AND SY-PARENT(LS-C) > 0
           AND SY-NODE(LS-C) > 0
            PERFORM CHECK-CONDITION
        END-IF
    END-PERFORM
    GOBACK.

*> Condition name LS-C of item LS-P.
CHECK-CONDITION.
    MOVE SY-PARENT(LS-C) TO LS-P
    PERFORM FIND-TEST
    IF LS-TEST = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-ITEM
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-C TO LS-S
    PERFORM READ-ELEMENTS
    IF LS-OK = "N" OR LS-ELEMENT-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM COLLECT-VALUES
    IF LS-OK = "N" OR LS-VALUE-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    *> One value the condition holds is enough.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-VALUE-COUNT
        PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > LS-ELEMENT-COUNT
            PERFORM MATCH-VALUE
            IF LS-RESULT = "Y"
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
    END-PERFORM
    PERFORM REPORT-CONDITION.

*> LS-TEST: the first reference that tests condition LS-C, or 0.
FIND-TEST.
    MOVE 0 TO LS-TEST
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-SYMBOL(LS-R) = LS-C AND RF-KIND(LS-R) = "D"
           AND RF-ROLE(LS-R) = "U"
            MOVE RF-TOKEN(LS-R) TO LS-TEST
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-OK = "Y" when item LS-P is one the rule reads.
CHECK-ITEM.
    MOVE "N" TO LS-OK
    IF SY-SECTION(LS-P) NOT = "W" AND SY-SECTION(LS-P) NOT = "L"
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-P) NOT = "X" AND SY-CATEGORY(LS-P) NOT = "A"
       AND SY-CATEGORY(LS-P) NOT = "9"
        EXIT PARAGRAPH
    END-IF
    IF SY-SIZE(LS-P) = 0 OR SY-SIZE(LS-P) > 64
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION UPPER-CASE(SY-NAME(LS-P)(1:3)) = "SQL"
        EXIT PARAGRAPH
    END-IF
    *> The item and the groups it is in: no REDEFINES either way, no
    *> EXTERNAL, BASED, or JUSTIFIED, not the SQLCA.
    MOVE LS-P TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF SY-REDEFINES(LS-UP) > 0
            EXIT PARAGRAPH
        END-IF
        PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
            IF SY-REDEFINES(LS-S) = LS-UP
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
        IF SY-NODE(LS-UP) > 0
            MOVE ND-FIRST(SY-NODE(LS-UP)) TO LS-N
            PERFORM UNTIL LS-N = 0
                IF ND-KIND(LS-N) = "CLAU"
                    IF ND-DETAIL(LS-N) = "EXTERNAL"
                       OR ND-DETAIL(LS-N) = "BASED"
                       OR ND-DETAIL(LS-N) = "JUSTIFIED"
                        EXIT PARAGRAPH
                    END-IF
                END-IF
                MOVE ND-NEXT(LS-N) TO LS-N
            END-PERFORM
        END-IF
        IF SY-PARENT(LS-UP) = 0
           AND FUNCTION UPPER-CASE(SY-NAME(LS-UP)) = "SQLCA"
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-STATUS-COUNT
        CALL "PLB-SPAN-OVERLAP" USING WS-SPANS WS-STATUS-SYMBOL(LS-I)
            LS-P LS-OVERLAP
        IF LS-OVERLAP = "Y" OR WS-STATUS-SYMBOL(LS-I) = LS-P
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    MOVE "Y" TO LS-OK.

*> The values of the VALUE clause of condition LS-S into the elements.
*> LS-OK = "N" for one that cannot be read.
READ-ELEMENTS.
    MOVE "N" TO LS-OK
    MOVE 0 TO LS-ELEMENT-COUNT
    PERFORM FIND-VALUE-CLAUSE
    IF LS-N = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-AFTER-THRU
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
        ELSE
            MOVE SPACES TO LS-WORD
        END-IF
        EVALUATE TRUE
            WHEN LS-WORD = "VALUE" OR LS-WORD = "VALUES"
                 OR LS-WORD = "IS" OR LS-WORD = "ARE"
                CONTINUE
            WHEN LS-WORD = "THRU" OR LS-WORD = "THROUGH"
                MOVE "Y" TO LS-AFTER-THRU
            WHEN LS-WORD = "WHEN" OR LS-WORD = "FALSE"
                EXIT PERFORM
            WHEN OTHER
                PERFORM READ-VALUE
                IF LS-V-KIND = SPACE
                    EXIT PARAGRAPH
                END-IF
                PERFORM ADD-ELEMENT
                IF LS-OK = "X"
                    MOVE "N" TO LS-OK
                    EXIT PARAGRAPH
                END-IF
        END-EVALUATE
    END-PERFORM
    IF LS-AFTER-THRU = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO LS-OK.

*> LS-N: the VALUE clause of the entry of symbol LS-S, or 0.
FIND-VALUE-CLAUSE.
    MOVE 0 TO LS-N
    IF SY-NODE(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-N
    PERFORM UNTIL LS-N = 0
        IF ND-KIND(LS-N) = "CLAU" AND ND-DETAIL(LS-N) = "VALUE"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-N) TO LS-N
    END-PERFORM.

*> The value just read as the next element, or as the end of the range
*> the last one starts. LS-OK = "X" when it cannot be.
ADD-ELEMENT.
    IF LS-AFTER-THRU = "Y"
        MOVE "N" TO LS-AFTER-THRU
        IF LS-ELEMENT-COUNT = 0 OR LS-V-KIND NOT = "N"
            MOVE "X" TO LS-OK
            EXIT PARAGRAPH
        END-IF
        IF LS-ELEMENT-KIND(LS-ELEMENT-COUNT) NOT = "N"
            MOVE "X" TO LS-OK
            EXIT PARAGRAPH
        END-IF
        MOVE LS-V-NUMBER TO LS-ELEMENT-HIGH(LS-ELEMENT-COUNT)
        EXIT PARAGRAPH
    END-IF
    IF LS-ELEMENT-COUNT >= ELEMENT-MAX
        MOVE "X" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-ELEMENT-COUNT
    MOVE LS-V-KIND TO LS-ELEMENT-KIND(LS-ELEMENT-COUNT)
    MOVE LS-V-TEXT TO LS-ELEMENT-TEXT(LS-ELEMENT-COUNT)
    MOVE LS-V-NUMBER TO LS-ELEMENT-NUMBER(LS-ELEMENT-COUNT)
    MOVE LS-V-NUMBER TO LS-ELEMENT-HIGH(LS-ELEMENT-COUNT).

*> The value at LS-T, as item LS-P holds it: an alphanumeric literal
*> without prefix (cut to the item's size), SPACE, a number the
*> item's picture holds, or ZERO of a numeric item. LS-V-KIND is space
*> for anything else.
READ-VALUE.
    MOVE SPACE TO LS-V-KIND
    MOVE SPACES TO LS-V-TEXT
    MOVE 0 TO LS-V-NUMBER
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-T)
            IF TK-PREFIX(LS-T) NOT = SPACES
               OR SY-CATEGORY(LS-P) = "9"
                EXIT PARAGRAPH
            END-IF
            MOVE TK-TEXT-LEN(LS-T) TO LS-LEN
            IF LS-LEN > SY-SIZE(LS-P)
                MOVE SY-SIZE(LS-P) TO LS-LEN
            END-IF
            IF LS-LEN > 0
                MOVE TK-TEXT(TK-TEXT-OFF(LS-T):LS-LEN) TO LS-V-TEXT
            END-IF
            IF LS-V-TEXT = SPACES
                MOVE "S" TO LS-V-KIND
            ELSE
                MOVE "A" TO LS-V-KIND
            END-IF
        WHEN TK-IS-NUMBER(LS-T)
            IF SY-CATEGORY(LS-P) NOT = "9"
                EXIT PARAGRAPH
            END-IF
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-LEN = 0 OR LS-LEN > 27
                EXIT PARAGRAPH
            END-IF
            MOVE 0 TO LS-I
            INSPECT LS-WORD(1:LS-LEN) TALLYING LS-I FOR ALL "E" "e"
            IF LS-I > 0
                EXIT PARAGRAPH
            END-IF
            IF FUNCTION TEST-NUMVAL(LS-WORD(1:LS-LEN)) NOT = 0
                EXIT PARAGRAPH
            END-IF
            COMPUTE LS-V-NUMBER = FUNCTION NUMVAL(LS-WORD(1:LS-LEN))
            PERFORM NUMBER-FITS
            IF LS-RESULT = "Y"
                MOVE "N" TO LS-V-KIND
            END-IF
        WHEN TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                WHEN "SPACE" WHEN "SPACES"
                    MOVE "S" TO LS-V-KIND
                WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES"
                    IF SY-CATEGORY(LS-P) = "9"
                        MOVE "N" TO LS-V-KIND
                    END-IF
            END-EVALUATE
    END-EVALUATE.

*> LS-RESULT = "Y" when item LS-P's picture holds LS-V-NUMBER as it
*> is: its sign, digits before the point, and those after it.
NUMBER-FITS.
    MOVE "N" TO LS-RESULT
    IF SY-DIGITS(LS-P) = 0 OR SY-DIGITS(LS-P) > 17
       OR SY-SCALE(LS-P) < 0 OR SY-SCALE(LS-P) > 9
       OR SY-SCALE(LS-P) > SY-DIGITS(LS-P)
        EXIT PARAGRAPH
    END-IF
    IF LS-V-NUMBER < 0 AND SY-SIGNED(LS-P) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-LIMIT = 10 ** (SY-DIGITS(LS-P) - SY-SCALE(LS-P))
    IF FUNCTION ABS(LS-V-NUMBER) >= LS-LIMIT
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-SCALED = LS-V-NUMBER * 10 ** SY-SCALE(LS-P)
    IF LS-SCALED NOT = FUNCTION INTEGER-PART(LS-SCALED)
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO LS-RESULT.

*> Every value item LS-P can hold. LS-OK = "N" when one is not known.
COLLECT-VALUES.
    MOVE "N" TO LS-OK
    MOVE 0 TO LS-VALUE-COUNT
    PERFORM INITIAL-VALUE
    IF LS-V-KIND = SPACE
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-VALUE
    MOVE 0 TO LS-STORES
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
           AND RF-ROLE(LS-R) NOT = "U" AND RF-ROLE(LS-R) NOT = "-"
            PERFORM STORE-VALUE
            IF LS-OK = "X"
                MOVE "N" TO LS-OK
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    *> An item no statement changes is a switch set by its VALUE, or
    *> one PLB-C011 reports; neither is this rule's.
    IF LS-STORES > 0
        MOVE "Y" TO LS-OK
    END-IF.

*> LS-V-*: what item LS-P holds at the start. Its VALUE clause, or one
*> of a group it is in; with none, spaces or zero.
INITIAL-VALUE.
    MOVE LS-P TO LS-S
    PERFORM FIND-VALUE-CLAUSE
    IF LS-N > 0
        PERFORM CLAUSE-VALUE
        EXIT PARAGRAPH
    END-IF
    MOVE SY-PARENT(LS-P) TO LS-S
    PERFORM UNTIL LS-S = 0
        PERFORM FIND-VALUE-CLAUSE
        IF LS-N > 0
            *> A group's VALUE: SPACE or ZERO fill the item; a literal
            *> is cut among the items, and is not read.
            PERFORM CLAUSE-VALUE
            IF LS-V-KIND = "A" OR LS-V-KIND = "N"
                MOVE SPACE TO LS-V-KIND
            END-IF
            IF LS-V-KIND = SPACE
                EXIT PARAGRAPH
            END-IF
            PERFORM FIGURATIVE-FOR-ITEM
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-S) TO LS-S
    END-PERFORM
    *> As GnuCOBOL starts an item without VALUE.
    IF SY-CATEGORY(LS-P) = "9"
        MOVE "N" TO LS-V-KIND
        MOVE 0 TO LS-V-NUMBER
    ELSE
        MOVE "S" TO LS-V-KIND
        MOVE SPACES TO LS-V-TEXT
    END-IF.

*> The single value of VALUE clause LS-N.
CLAUSE-VALUE.
    MOVE SPACE TO LS-V-KIND
    MOVE ND-TOK-FIRST(LS-N) TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) = "VALUE"
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    END-IF
    IF FUNCTION UPPER-CASE(LS-WORD) = "IS"
        ADD 1 TO LS-T
    END-IF
    IF LS-T NOT = ND-TOK-LAST(LS-N)
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-VALUE.

*> A group's SPACE or ZERO as item LS-P holds it: SPACE in a numeric
*> item, or ZERO in an alphanumeric one, is not read.
FIGURATIVE-FOR-ITEM.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE SPACE TO LS-V-KIND
    MOVE 0 TO LS-V-NUMBER
    MOVE SPACES TO LS-V-TEXT
    EVALUATE FUNCTION UPPER-CASE(LS-WORD)
        WHEN "SPACE" WHEN "SPACES"
            IF SY-CATEGORY(LS-P) NOT = "9"
                MOVE "S" TO LS-V-KIND
            END-IF
        WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES"
            IF SY-CATEGORY(LS-P) = "9"
                MOVE "N" TO LS-V-KIND
            END-IF
    END-EVALUATE.

*> Reference LS-R stores into its symbol: what that gives item LS-P.
*> LS-OK = "X" when it touches the item in a way not read.
STORE-VALUE.
    MOVE RF-SYMBOL(LS-R) TO LS-S
    MOVE RF-STMT(LS-R) TO LS-STMT
    EVALUATE TRUE
        WHEN LS-S = LS-P
            IF LS-STMT = 0
                MOVE "X" TO LS-OK
                EXIT PARAGRAPH
            END-IF
            EVALUATE ND-DETAIL(LS-STMT)
                WHEN "MOVE"
                    PERFORM MOVED-VALUE
                WHEN "INITIALIZE"
                    PERFORM INITIALIZED-VALUE
                WHEN OTHER
                    MOVE SPACE TO LS-V-KIND
            END-EVALUATE
        WHEN SY-CATEGORY(LS-S) = "C" AND SY-PARENT(LS-S) = LS-P
            PERFORM SET-VALUE
        WHEN SY-CATEGORY(LS-S) = "C"
            *> A condition name of another item: a store when that item
            *> shares storage with this one.
            CALL "PLB-SPAN-OVERLAP" USING WS-SPANS SY-PARENT(LS-S) LS-P
                LS-OVERLAP
            IF LS-OVERLAP = "Y"
                MOVE "X" TO LS-OK
            END-IF
            EXIT PARAGRAPH
        WHEN OTHER
            CALL "PLB-SPAN-OVERLAP" USING WS-SPANS LS-S LS-P LS-OVERLAP
            IF LS-OVERLAP = "N"
                EXIT PARAGRAPH
            END-IF
            PERFORM GROUP-VALUE
    END-EVALUATE
    IF LS-V-KIND = SPACE
        MOVE "X" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-STORES
    PERFORM ADD-VALUE.

*> MOVE literal TO ... item LS-P.
MOVED-VALUE.
    MOVE SPACE TO LS-V-KIND
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    COMPUTE LS-N = LS-T + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-N LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "TO"
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-VALUE.

*> INITIALIZE of the item, without REPLACING or a VALUE phrase:
*> spaces, or zero.
INITIALIZED-VALUE.
    MOVE SPACE TO LS-V-KIND
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "REPLACING" OR LS-WORD = "VALUE"
               OR LS-WORD = "DEFAULT" OR LS-WORD = "FILLER"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    IF SY-CATEGORY(LS-P) = "9"
        MOVE "N" TO LS-V-KIND
        MOVE 0 TO LS-V-NUMBER
    ELSE
        MOVE "S" TO LS-V-KIND
        MOVE SPACES TO LS-V-TEXT
    END-IF.

*> SET condition LS-S TO TRUE (its first value) or FALSE (the value
*> of its WHEN SET TO FALSE phrase).
SET-VALUE.
    MOVE SPACE TO LS-V-KIND
    IF LS-STMT = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-DETAIL(LS-STMT) NOT = "SET"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-TOK-LAST(LS-STMT) TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    PERFORM FIND-VALUE-CLAUSE
    IF LS-N = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE FUNCTION UPPER-CASE(LS-WORD)
        WHEN "TRUE"
            MOVE ND-TOK-FIRST(LS-N) TO LS-T
            PERFORM UNTIL LS-T > ND-TOK-LAST(LS-N)
                IF NOT TK-IS-WORD(LS-T)
                    EXIT PERFORM
                END-IF
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
                IF LS-WORD NOT = "VALUE" AND LS-WORD NOT = "VALUES"
                   AND LS-WORD NOT = "IS" AND LS-WORD NOT = "ARE"
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-T
            END-PERFORM
        WHEN "FALSE"
            *> The literal after FALSE [IS].
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-N)
                IF TK-IS-WORD(LS-T)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD
                        LS-LEN
                    IF FUNCTION UPPER-CASE(LS-WORD) = "FALSE"
                        EXIT PERFORM
                    END-IF
                END-IF
            END-PERFORM
            ADD 1 TO LS-T
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "IS"
                ADD 1 TO LS-T
            END-IF
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    IF LS-T > ND-TOK-LAST(LS-N)
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-VALUE.

*> A store into LS-S, which shares storage with item LS-P: a group
*> around the item given SPACE or ZERO by MOVE, or INITIALIZE.
GROUP-VALUE.
    MOVE SPACE TO LS-V-KIND
    IF LS-STMT = 0
        EXIT PARAGRAPH
    END-IF
    *> The item must be inside the group.
    MOVE SY-PARENT(LS-P) TO LS-UP
    PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-S
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF LS-UP = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE ND-DETAIL(LS-STMT)
        WHEN "MOVE"
            COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
            COMPUTE LS-N = LS-T + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-N LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "TO"
                PERFORM FIGURATIVE-FOR-ITEM
            END-IF
        WHEN "INITIALIZE"
            PERFORM INITIALIZED-VALUE
    END-EVALUATE.

ADD-VALUE.
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > LS-VALUE-COUNT
        IF LS-VALUE-KIND(LS-J) = LS-V-KIND
           AND LS-VALUE-TEXT(LS-J) = LS-V-TEXT
           AND LS-VALUE-NUMBER(LS-J) = LS-V-NUMBER
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF LS-VALUE-COUNT >= VALUE-MAX
        MOVE "X" TO LS-OK
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-VALUE-COUNT
    MOVE LS-V-KIND TO LS-VALUE-KIND(LS-VALUE-COUNT)
    MOVE LS-V-TEXT TO LS-VALUE-TEXT(LS-VALUE-COUNT)
    MOVE LS-V-NUMBER TO LS-VALUE-NUMBER(LS-VALUE-COUNT).

*> LS-RESULT = "Y" when value LS-I is element LS-J or in its range.
MATCH-VALUE.
    MOVE "N" TO LS-RESULT
    IF LS-VALUE-KIND(LS-I) NOT = LS-ELEMENT-KIND(LS-J)
        EXIT PARAGRAPH
    END-IF
    EVALUATE LS-VALUE-KIND(LS-I)
        WHEN "S"
            MOVE "Y" TO LS-RESULT
        WHEN "A"
            IF LS-VALUE-TEXT(LS-I) = LS-ELEMENT-TEXT(LS-J)
                MOVE "Y" TO LS-RESULT
            END-IF
        WHEN "N"
            IF LS-VALUE-NUMBER(LS-I) >= LS-ELEMENT-NUMBER(LS-J)
               AND LS-VALUE-NUMBER(LS-I) <= LS-ELEMENT-HIGH(LS-J)
                MOVE "Y" TO LS-RESULT
            END-IF
    END-EVALUATE.

*> At the first test: the condition and the values its item holds.
REPORT-CONDITION.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING SY-NAME(LS-C) DELIMITED BY SPACE
           " is never true: " DELIMITED BY SIZE
           SY-NAME(LS-P) DELIMITED BY SPACE
           " is only ever " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-VALUE-COUNT
        IF LS-I > 1
            IF LS-I = LS-VALUE-COUNT
                STRING " or " DELIMITED BY SIZE
                    INTO LS-MESSAGE WITH POINTER LS-PTR
            ELSE
                STRING ", " DELIMITED BY SIZE
                    INTO LS-MESSAGE WITH POINTER LS-PTR
            END-IF
        END-IF
        IF LS-PTR > 150
            STRING "..." DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            EXIT PERFORM
        END-IF
        PERFORM SHOW-VALUE
        STRING LS-SHOWN DELIMITED BY "  "
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-PERFORM
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TEST LS-MESSAGE.

*> LS-SHOWN: value LS-I as written in COBOL.
SHOW-VALUE.
    MOVE SPACES TO LS-SHOWN
    EVALUATE LS-VALUE-KIND(LS-I)
        WHEN "S"
            MOVE "SPACES" TO LS-SHOWN
        WHEN "A"
            STRING '"' FUNCTION TRIM(LS-VALUE-TEXT(LS-I) TRAILING) '"'
                DELIMITED BY SIZE INTO LS-SHOWN
        WHEN "N"
            MOVE LS-VALUE-NUMBER(LS-I) TO LS-NUM-EDIT
            MOVE FUNCTION TRIM(LS-NUM-EDIT) TO LS-SHOWN
            *> Without trailing decimal zeros, nor a point with none.
            MOVE 0 TO LS-N
            INSPECT LS-SHOWN TALLYING LS-N FOR CHARACTERS
                BEFORE INITIAL "."
            MOVE FUNCTION LENGTH(FUNCTION TRIM(LS-SHOWN)) TO LS-J
            PERFORM UNTIL LS-J <= LS-N + 1
                     OR LS-SHOWN(LS-J:1) NOT = "0"
                MOVE SPACE TO LS-SHOWN(LS-J:1)
                SUBTRACT 1 FROM LS-J
            END-PERFORM
            IF LS-J = LS-N + 1
                MOVE SPACE TO LS-SHOWN(LS-J:1)
            END-IF
    END-EVALUATE.
END PROGRAM PLB-RULE-C090.
