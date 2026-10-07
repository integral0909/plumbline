*> ---------------------------------------------------------------
*> plbrcontra: PLB-C071 contradictory-condition.
*>
*> A condition that joins equalities of one item with AND, or
*> inequalities with OR, so that it cannot be true, or cannot be false:
*>
*>     IF WS-STATUS = "A" AND WS-STATUS = "B"       never true
*>     IF WS-STATUS = "A" AND "B"                   never true
*>     IF WS-STATUS NOT = "A" OR "B"                always true
*>
*> AND was meant to be OR, or the other way round. The rule reads
*> conditions of IF and PERFORM ... UNTIL that are a chain of relations
*> item [IS] [NOT] = literal (or EQUAL [TO]), with the abbreviated
*> forms that leave out the item or the item and the operator, joined
*> all by AND or all by OR. A condition with parentheses that group, or
*> other operators, or both AND and OR, is not read. Literals are
*> compared by value: trailing spaces and leading zeros do not count.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C071.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  PIECE-MAX               VALUE 16.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-LEVEL                PIC S9(4) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-J                    PIC 9(4) COMP-5.
01  LS-K                    PIC 9(4) COMP-5.
01  LS-USABLE               PIC X.
*> The relations read: subject text, NOT or not, value; and how they
*> are joined (A all AND, O all OR, space none yet, X both).
01  LS-PIECE-COUNT          PIC 9(4) COMP-5.
01  LS-PIECE-SUBJECT        PIC X(64) OCCURS PIECE-MAX TIMES.
01  LS-PIECE-NOT            PIC X OCCURS PIECE-MAX TIMES.
01  LS-PIECE-VALUE          PIC X(64) OCCURS PIECE-MAX TIMES.
01  LS-PIECE-SHOWN          PIC X(40) OCCURS PIECE-MAX TIMES.
01  LS-JOIN                 PIC X.
*> The subject and operator carried to abbreviated relations.
01  LS-SUBJECT              PIC X(64).
01  LS-NOT                  PIC X.
01  LS-HAVE-SUBJECT         PIC X.
01  LS-TEXT                 PIC X(64).
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUMBER               PIC S9(18)V9(9) COMP-3.
01  LS-NUMBER-TEXT          PIC -9(18).9(9).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C071" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "COND"
            EVALUATE ND-DETAIL(LS-NODE)
                WHEN "IF"
                    MOVE ND-TOK-FIRST(LS-NODE) TO LS-FIRST
                    MOVE ND-TOK-LAST(LS-NODE) TO LS-LAST
                    PERFORM CHECK-CONDITION
                WHEN "LOOP"
                    PERFORM LOOP-CONDITION
            END-EVALUATE
        END-IF
    END-PERFORM
    GOBACK.

*> PERFORM ... UNTIL condition: the tokens after UNTIL, when there is
*> one UNTIL and no VARYING.
LOOP-CONDITION.
    MOVE 0 TO LS-FIRST
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                WHEN "VARYING"
                    EXIT PARAGRAPH
                WHEN "UNTIL"
                    IF LS-FIRST > 0
                        EXIT PARAGRAPH
                    END-IF
                    COMPUTE LS-FIRST = LS-T + 1
            END-EVALUATE
        END-IF
    END-PERFORM
    IF LS-FIRST = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-TOK-LAST(LS-NODE) TO LS-LAST
    PERFORM CHECK-CONDITION.

*> The tokens LS-FIRST to LS-LAST: read the chain, then compare.
CHECK-CONDITION.
    PERFORM READ-CHAIN
    IF LS-USABLE NOT = "Y" OR LS-PIECE-COUNT < 2
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I >= LS-PIECE-COUNT
        PERFORM VARYING LS-J FROM LS-I BY 1 UNTIL LS-J >= LS-PIECE-COUNT
            IF LS-PIECE-SUBJECT(LS-I) = LS-PIECE-SUBJECT(LS-J + 1)
               AND LS-PIECE-NOT(LS-I) = LS-PIECE-NOT(LS-J + 1)
               AND LS-PIECE-VALUE(LS-I) NOT = LS-PIECE-VALUE(LS-J + 1)
                IF (LS-JOIN = "A" AND LS-PIECE-NOT(LS-I) = "N")
                   OR (LS-JOIN = "O" AND LS-PIECE-NOT(LS-I) = "Y")
                    COMPUTE LS-K = LS-J + 1
                    PERFORM REPORT-CONDITION
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM.

*> LS-USABLE = "Y" when the tokens are a chain of relations of the form
*> the rule reads; the relations are then in LS-PIECE-*.
READ-CHAIN.
    MOVE "N" TO LS-USABLE
    MOVE 0 TO LS-PIECE-COUNT
    MOVE SPACE TO LS-JOIN
    MOVE "N" TO LS-HAVE-SUBJECT LS-NOT
    MOVE LS-FIRST TO LS-T
    PERFORM UNTIL LS-T > LS-LAST
        PERFORM READ-RELATION
        IF LS-USABLE = "X"
            MOVE "N" TO LS-USABLE
            EXIT PARAGRAPH
        END-IF
        IF LS-T > LS-LAST
            EXIT PERFORM
        END-IF
        *> AND or OR, all the same.
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        EVALUATE FUNCTION UPPER-CASE(LS-WORD)
            WHEN "AND"
                IF LS-JOIN = "O"
                    EXIT PARAGRAPH
                END-IF
                MOVE "A" TO LS-JOIN
            WHEN "OR"
                IF LS-JOIN = "A"
                    EXIT PARAGRAPH
                END-IF
                MOVE "O" TO LS-JOIN
            WHEN OTHER
                EXIT PARAGRAPH
        END-EVALUATE
        ADD 1 TO LS-T
    END-PERFORM
    MOVE "Y" TO LS-USABLE.

*> One relation from LS-T: [item] [IS] [NOT] [= | EQUAL [TO]] literal,
*> the item and operator carried from the one before when left out.
*> LS-USABLE = "X" when it is not of that form.
READ-RELATION.
    MOVE "X" TO LS-USABLE
    IF LS-PIECE-COUNT >= PIECE-MAX
        EXIT PARAGRAPH
    END-IF
    *> The item: a word, with a subscript in parentheses.
    IF TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
        IF LS-WORD NOT = "IS" AND LS-WORD NOT = "NOT"
           AND LS-WORD NOT = "EQUAL" AND LS-WORD NOT = "SPACE"
           AND LS-WORD NOT = "SPACES" AND LS-WORD NOT = "ZERO"
           AND LS-WORD NOT = "ZEROS" AND LS-WORD NOT = "ZEROES"
            PERFORM READ-SUBJECT
            IF LS-T > LS-LAST
                EXIT PARAGRAPH
            END-IF
            MOVE "N" TO LS-NOT
            MOVE "Y" TO LS-HAVE-SUBJECT
            *> [IS] [NOT] = | EQUAL [TO]: an item must have an operator.
            PERFORM READ-OPERATOR
            IF LS-USABLE = "E"
                EXIT PARAGRAPH
            END-IF
        ELSE
            IF LS-WORD = "IS" OR LS-WORD = "NOT" OR LS-WORD = "EQUAL"
                PERFORM READ-OPERATOR
                IF LS-USABLE = "E"
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-IF
    END-IF
    IF TK-IS-OPERATOR(LS-T)
        PERFORM READ-OPERATOR
        IF LS-USABLE = "E"
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF LS-HAVE-SUBJECT NOT = "Y" OR LS-T > LS-LAST
        MOVE "X" TO LS-USABLE
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-VALUE
    IF LS-TEXT = SPACES
        MOVE "X" TO LS-USABLE
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-PIECE-COUNT
    MOVE LS-SUBJECT TO LS-PIECE-SUBJECT(LS-PIECE-COUNT)
    MOVE LS-NOT TO LS-PIECE-NOT(LS-PIECE-COUNT)
    MOVE LS-TEXT TO LS-PIECE-VALUE(LS-PIECE-COUNT)
    ADD 1 TO LS-T
    MOVE "Y" TO LS-USABLE.

*> LS-SUBJECT: the word at LS-T and a parenthesized subscript after
*> it; LS-T is left after them. Parentheses elsewhere give up.
READ-SUBJECT.
    MOVE SPACES TO LS-SUBJECT
    MOVE 1 TO LS-PTR
    STRING LS-WORD DELIMITED BY SPACE INTO LS-SUBJECT WITH POINTER LS-PTR
    ADD 1 TO LS-T
    IF LS-T <= LS-LAST AND TK-IS-LPAREN(LS-T)
        MOVE 0 TO LS-LEVEL
        PERFORM UNTIL LS-T > LS-LAST
            IF TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            END-IF
            IF TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            END-IF
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-LEN > 0 AND LS-PTR + LS-LEN < 64
                STRING LS-WORD(1:LS-LEN) DELIMITED BY SIZE
                    INTO LS-SUBJECT WITH POINTER LS-PTR
            END-IF
            ADD 1 TO LS-T
            IF LS-LEVEL = 0
                EXIT PERFORM
            END-IF
        END-PERFORM
    END-IF.

*> [IS] [NOT] = | EQUAL [TO] at LS-T: LS-NOT; LS-USABLE = "E" when it
*> is another operator.
READ-OPERATOR.
    MOVE "N" TO LS-NOT
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) = "IS"
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    END-IF
    IF FUNCTION UPPER-CASE(LS-WORD) = "NOT"
        MOVE "Y" TO LS-NOT
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = "="
            ADD 1 TO LS-T
        WHEN FUNCTION UPPER-CASE(LS-WORD) = "EQUAL"
            ADD 1 TO LS-T
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "TO"
                ADD 1 TO LS-T
            END-IF
        WHEN OTHER
            MOVE "E" TO LS-USABLE
    END-EVALUATE.

*> LS-TEXT: the value of the literal or figurative constant at LS-T
*> (spaces when it is something else), and how it is shown.
READ-VALUE.
    MOVE SPACES TO LS-TEXT
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-T)
            IF TK-PREFIX(LS-T) NOT = SPACES OR LS-LEN > 60
                EXIT PARAGRAPH
            END-IF
            MOVE "A:" TO LS-TEXT(1:2)
            IF LS-LEN > 0
                MOVE LS-WORD(1:LS-LEN) TO LS-TEXT(3:)
            END-IF
            *> Trailing spaces do not count; all spaces is SPACE.
            IF LS-TEXT(3:) = SPACES
                MOVE "F:SPACE" TO LS-TEXT
            END-IF
            MOVE SPACES TO LS-PIECE-SHOWN(LS-PIECE-COUNT + 1)
            STRING '"' LS-WORD(1:FUNCTION MIN(LS-LEN, 30)) '"'
                DELIMITED BY SIZE
                INTO LS-PIECE-SHOWN(LS-PIECE-COUNT + 1)
        WHEN TK-IS-NUMBER(LS-T)
            IF LS-LEN > 28 OR FUNCTION TEST-NUMVAL(LS-WORD(1:LS-LEN))
               NOT = 0
                EXIT PARAGRAPH
            END-IF
            COMPUTE LS-NUMBER = FUNCTION NUMVAL(LS-WORD(1:LS-LEN))
            MOVE LS-NUMBER TO LS-NUMBER-TEXT
            STRING "N:" LS-NUMBER-TEXT DELIMITED BY SIZE INTO LS-TEXT
            MOVE LS-WORD(1:LS-LEN) TO LS-PIECE-SHOWN(LS-PIECE-COUNT + 1)
        WHEN TK-IS-WORD(LS-T)
            EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                WHEN "SPACE" WHEN "SPACES"
                    MOVE "F:SPACE" TO LS-TEXT
                    MOVE "SPACES" TO LS-PIECE-SHOWN(LS-PIECE-COUNT + 1)
                WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES"
                    MOVE "F:ZERO" TO LS-TEXT
                    MOVE "ZERO" TO LS-PIECE-SHOWN(LS-PIECE-COUNT + 1)
            END-EVALUATE
    END-EVALUATE.

REPORT-CONDITION.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    IF LS-JOIN = "A"
        STRING "this condition is never true: " DELIMITED BY SIZE
               LS-PIECE-SUBJECT(LS-I) DELIMITED BY SPACE
               " cannot be both " DELIMITED BY SIZE
               FUNCTION TRIM(LS-PIECE-SHOWN(LS-I)) " and "
               FUNCTION TRIM(LS-PIECE-SHOWN(LS-K)) DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING "this condition is always true: " DELIMITED BY SIZE
               LS-PIECE-SUBJECT(LS-I) DELIMITED BY SPACE
               " is always unequal to " DELIMITED BY SIZE
               FUNCTION TRIM(LS-PIECE-SHOWN(LS-I)) " or to "
               FUNCTION TRIM(LS-PIECE-SHOWN(LS-K)) DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-FIRST LS-MESSAGE.
END PROGRAM PLB-RULE-C071.
