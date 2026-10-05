*> ---------------------------------------------------------------
*> plbrodo: PLB-C068 odo-count-out-of-range.
*>
*> The count of a table with OCCURS ... DEPENDING ON given a value the
*> table cannot have:
*>
*>     01  ORDER-COUNT         PIC 999.
*>     01  ORDER-TABLE.
*>         05  ORDER-LINE      PIC X(40)
*>                             OCCURS 1 TO 50 DEPENDING ON ORDER-COUNT.
*>     ...
*>         MOVE 60 TO ORDER-COUNT
*>
*> A count above the maximum makes the table, and the record it is in,
*> reach past the storage they were given; one below the minimum is not
*> allowed either, except zero, the count of a table not filled yet. Checked are the values written as numbers: a MOVE of
*> a numeric literal to the count, a COMPUTE whose expression is one,
*> and the count's VALUE clause. The count is the item of that name in
*> the same program, as for PLB-C040.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C068.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-O                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(31).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-MIN                  PIC S9(18) COMP-5.
01  LS-MAX                  PIC S9(18) COMP-5.
01  LS-VALUE                PIC S9(18) COMP-5.
01  LS-VALUE-OK             PIC X.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-WHAT                 PIC X(20).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C068" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-ODO-TOKEN(LS-S) > 0 AND SY-OCCURS(LS-S) > 0
           AND SY-UNBOUNDED(LS-S) NOT = "Y" AND SY-NODE(LS-S) > 0
            PERFORM CHECK-TABLE
        END-IF
    END-PERFORM
    GOBACK.

*> Table LS-S: its count, its bounds, and the values the count is given.
CHECK-TABLE.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS SY-ODO-TOKEN(LS-S) LS-NAME
        LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-NAME) TO LS-NAME
    PERFORM VARYING LS-O FROM 1 BY 1 UNTIL LS-O > SY-COUNT
        IF SY-NAME(LS-O) = LS-NAME
           AND SY-PROGRAM(LS-O) = SY-PROGRAM(LS-S)
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-O > SY-COUNT
        EXIT PARAGRAPH
    END-IF
    MOVE SY-OCCURS(LS-S) TO LS-MAX
    PERFORM FIND-MINIMUM
    PERFORM CHECK-VALUE-CLAUSE
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) = LS-O
           AND RF-ROLE(LS-R) = "D" AND RF-STMT(LS-R) > 0
           AND RF-SUBSCRIPTED(LS-R) = "N" AND RF-REFMOD(LS-R) = "N"
            MOVE RF-STMT(LS-R) TO LS-STMT
            PERFORM CHECK-STATEMENT
        END-IF
    END-PERFORM.

*> LS-MIN: n of OCCURS n TO max, or 0 when the clause gives none.
FIND-MINIMUM.
    MOVE 0 TO LS-MIN
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "CLAU" AND ND-DETAIL(LS-C) = "OCCURS"
            COMPUTE LS-T = ND-TOK-FIRST(LS-C) + 1
            PERFORM READ-NUMBER
            IF LS-VALUE-OK = "Y"
                ADD 1 TO LS-T
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "TO"
                    MOVE LS-VALUE TO LS-MIN
                END-IF
            END-IF
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM.

*> The count's VALUE clause, when it is one number.
CHECK-VALUE-CLAUSE.
    IF SY-NODE(LS-O) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(SY-NODE(LS-O)) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "CLAU" AND ND-DETAIL(LS-C) = "VALUE"
            MOVE ND-TOK-LAST(LS-C) TO LS-T
            PERFORM READ-NUMBER
            IF LS-VALUE-OK = "Y"
                MOVE LS-T TO LS-AT
                MOVE "its VALUE" TO LS-WHAT
                PERFORM TEST-VALUE
            END-IF
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM.

*> Statement LS-STMT gives the count a value: MOVE number TO count, or
*> COMPUTE count = number.
CHECK-STATEMENT.
    EVALUATE ND-DETAIL(LS-STMT)
        WHEN "MOVE"
            COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
            PERFORM READ-NUMBER
            IF LS-VALUE-OK = "Y"
                ADD 1 TO LS-T
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) = "TO"
                    COMPUTE LS-AT = LS-T - 1
                    MOVE "this MOVE" TO LS-WHAT
                    PERFORM TEST-VALUE
                END-IF
            END-IF
        WHEN "COMPUTE"
            COMPUTE LS-T = RF-LAST(LS-R) + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "=" OR FUNCTION UPPER-CASE(LS-TEXT) = "EQUAL"
                ADD 1 TO LS-T
                PERFORM READ-NUMBER
                *> The expression is the number alone.
                IF LS-VALUE-OK = "Y" AND LS-T = ND-TOK-LAST(LS-STMT)
                    MOVE LS-T TO LS-AT
                    MOVE "this COMPUTE" TO LS-WHAT
                    PERFORM TEST-VALUE
                END-IF
            END-IF
    END-EVALUATE.

*> LS-VALUE from an integer literal at LS-T (a sign allowed).
READ-NUMBER.
    MOVE "N" TO LS-VALUE-OK
    IF LS-T < 1 OR LS-T > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-NUMBER(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-LEN > 18 OR FUNCTION TEST-NUMVAL(LS-TEXT(1:LS-LEN)) NOT = 0
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
       NOT = FUNCTION INTEGER-PART(FUNCTION NUMVAL(LS-TEXT(1:LS-LEN)))
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-VALUE = FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
    MOVE "Y" TO LS-VALUE-OK.

*> LS-VALUE against the bounds; reported at token LS-AT.
TEST-VALUE.
    *> Zero is the count of a table not filled yet (VALUE 0, MOVE 0
    *> before loading it), whatever the minimum.
    IF LS-VALUE <= LS-MAX AND (LS-VALUE >= LS-MIN OR LS-VALUE = 0)
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING SY-NAME(LS-O) DELIMITED BY SPACE
           " is the count of " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF SY-NAME(LS-S) = SPACES OR SY-NAME(LS-S) = "FILLER"
        STRING "the table in " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        IF SY-PARENT(LS-S) > 0
            STRING SY-NAME(SY-PARENT(LS-S)) DELIMITED BY SPACE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        END-IF
    ELSE
        STRING SY-NAME(LS-S) DELIMITED BY SPACE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING ", which has " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-MIN TO LS-NUM
    PERFORM APPEND-NUM
    STRING " to " DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-MAX TO LS-NUM
    PERFORM APPEND-NUM
    STRING " entries, and " DELIMITED BY SIZE
           LS-WHAT DELIMITED BY "  "
           " makes it " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-VALUE TO LS-NUM
    PERFORM APPEND-NUM
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-AT LS-MESSAGE.

APPEND-NUM.
    IF LS-NUM < 0
        STRING "-" DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR.
END PROGRAM PLB-RULE-C068.
