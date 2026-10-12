*> ---------------------------------------------------------------
*> plbrgval: VALUE clauses of groups.
*>
*>   PLB-C098  group-value-into-packed
*>   PLB-C099  value-overridden
*>
*> A group's VALUE gives the whole group its start value, byte for
*> byte, as an alphanumeric item:
*>
*>     01  WS-TOTALS VALUE SPACES.
*>         05  WS-COUNT    PIC S9(7) COMP-3.        spaces: no number
*>         05  WS-LIMIT    PIC 9(3) VALUE 100.      ignored
*>
*> PLB-C098: a packed-decimal or binary item in it gets the bytes of
*> the group's value, which are no valid number (spaces in a packed
*> item) or a meaningless one (spaces in a binary item); with GnuCOBOL
*> 3.2, ADD 1 TO WS-COUNT gives +2020203, and with run-time checks it
*> stops the run. LOW-VALUES gives a binary item the number 0, and is
*> left alone for binary items.
*>
*> PLB-C099: an item in it with a VALUE of its own: the group's VALUE
*> decides the start value, and with GnuCOBOL 3.2 the item's is
*> ignored without a message (WS-LIMIT above starts as spaces).
*>
*> Read are items of the WORKING-STORAGE and LOCAL-STORAGE SECTIONs;
*> condition names (88) are not items.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-GROUP-VALUES.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE-PACKED          PIC 9(4) COMP-5.
01  LS-RULE-OVERRIDDEN      PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-FOUND                PIC 9(9) COMP-5.
01  LS-MORE                 PIC 9(9) COMP-5.
01  LS-KIND                 PIC X.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> What the group's VALUE is, as the message names it.
01  LS-WHAT                 PIC X(40).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
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
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C098" LS-RULE-PACKED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C099" LS-RULE-OVERRIDDEN
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-HAS-VALUE(LS-S) = "Y"
           AND (SY-SECTION(LS-S) = "W" OR SY-SECTION(LS-S) = "L")
           AND SY-CATEGORY(LS-S) NOT = "C"
           AND SY-CATEGORY(LS-S) NOT = "K"
            IF RL-ENABLED(LS-RULE-OVERRIDDEN) = "Y"
                PERFORM CHECK-OVERRIDDEN
            END-IF
            IF SY-CATEGORY(LS-S) = "G"
               AND RL-ENABLED(LS-RULE-PACKED) = "Y"
                PERFORM CHECK-GROUP
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> PLB-C099: item LS-S with a VALUE, in a group with one.
CHECK-OVERRIDDEN.
    MOVE SY-PARENT(LS-S) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF SY-HAS-VALUE(LS-UP) = "Y"
            MOVE SPACES TO LS-MESSAGE
            STRING SY-NAME(LS-S) DELIMITED BY SPACE
                   " has a VALUE, but the group " DELIMITED BY SIZE
                   SY-NAME(LS-UP) DELIMITED BY SPACE
                   " it is in has one too: the group's decides the "
                   "start value, and this one is ignored"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE-OVERRIDDEN
                SY-NAME-TOKEN(LS-S) LS-MESSAGE
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> PLB-C098: group LS-S with a VALUE, and the packed or binary items
*> under it.
CHECK-GROUP.
    PERFORM READ-GROUP-VALUE
    IF LS-WHAT = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-FOUND LS-MORE
    PERFORM VARYING LS-G FROM LS-S BY 1 UNTIL LS-G > SY-COUNT
        IF LS-G > LS-S
            *> Under the group: LS-S is among its groups.
            MOVE SY-PARENT(LS-G) TO LS-UP
            PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-S
                MOVE SY-PARENT(LS-UP) TO LS-UP
            END-PERFORM
            IF LS-UP = 0
                EXIT PERFORM
            END-IF
            PERFORM ITEM-KIND
            IF LS-KIND = "P" OR (LS-KIND = "B" AND LS-WHAT NOT = "low")
                IF LS-FOUND = 0
                    MOVE LS-G TO LS-FOUND
                ELSE
                    ADD 1 TO LS-MORE
                END-IF
            END-IF
        END-IF
    END-PERFORM
    IF LS-FOUND > 0
        PERFORM REPORT-PACKED
    END-IF.

*> LS-KIND: P for a packed-decimal item LS-G, B for a binary one, space
*> for any other.
ITEM-KIND.
    MOVE SPACE TO LS-KIND
    IF SY-CATEGORY(LS-G) NOT = "9"
        EXIT PARAGRAPH
    END-IF
    EVALUATE SY-USAGE(LS-G)
        WHEN "COMP-3" WHEN "COMPUTATIONAL-3" WHEN "PACKED-DECIMAL"
            MOVE "P" TO LS-KIND
        WHEN "COMP" WHEN "COMPUTATIONAL" WHEN "COMP-4"
        WHEN "COMPUTATIONAL-4" WHEN "COMP-5" WHEN "COMPUTATIONAL-5"
        WHEN "BINARY"
            MOVE "B" TO LS-KIND
    END-EVALUATE.

*> LS-WHAT: the group's VALUE as the message names it ("low" for
*> LOW-VALUES, which the message names in full); spaces when it is
*> not read.
READ-GROUP-VALUE.
    MOVE SPACES TO LS-WHAT
    IF SY-NODE(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-N
    PERFORM UNTIL LS-N = 0
        IF ND-KIND(LS-N) = "CLAU" AND ND-DETAIL(LS-N) = "VALUE"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-N) TO LS-N
    END-PERFORM
    IF LS-N = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF TK-IS-ALNUM(LS-T) OR TK-IS-NUMBER(LS-T)
            MOVE "a literal" TO LS-WHAT
            EXIT PARAGRAPH
        END-IF
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                WHEN "SPACE" WHEN "SPACES"
                    MOVE "spaces" TO LS-WHAT
                    EXIT PARAGRAPH
                WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES"
                    MOVE "the character 0" TO LS-WHAT
                    EXIT PARAGRAPH
                WHEN "HIGH-VALUE" WHEN "HIGH-VALUES"
                    MOVE "HIGH-VALUES" TO LS-WHAT
                    EXIT PARAGRAPH
                WHEN "LOW-VALUE" WHEN "LOW-VALUES"
                    MOVE "low" TO LS-WHAT
                    EXIT PARAGRAPH
                WHEN "QUOTE" WHEN "QUOTES"
                    MOVE "quotes" TO LS-WHAT
                    EXIT PARAGRAPH
            END-EVALUATE
        END-IF
    END-PERFORM.

REPORT-PACKED.
    MOVE LS-FOUND TO LS-G
    PERFORM ITEM-KIND
    IF LS-WHAT = "low"
        MOVE "LOW-VALUES" TO LS-WHAT
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "the VALUE of " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           " puts " DELIMITED BY SIZE
           LS-WHAT DELIMITED BY "  "
           " in " DELIMITED BY SIZE
           SY-NAME(LS-FOUND) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-KIND = "P"
        STRING ", a packed-decimal item: no valid number"
            DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING ", a binary item: a meaningless number"
            DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    IF LS-MORE > 0
        MOVE LS-MORE TO LS-NUM
        CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
        STRING " (and in " DELIMITED BY SIZE
               LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
               " more such item" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        IF LS-MORE > 1
            STRING "s" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        END-IF
        STRING ")" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-PACKED SY-NAME-TOKEN(LS-S) LS-MESSAGE.
END PROGRAM PLB-RULE-GROUP-VALUES.
