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
*> item [IS] [NOT] operator literal, with the abbreviated forms that
*> leave out the item or the item and the operator, joined all by AND
*> or all by OR. A condition with parentheses that group, or both AND
*> and OR, is not read. Literals are compared by value: trailing spaces
*> and leading zeros do not count.
*>
*> Relations with > or < and a number, of a numeric item, are read as
*> ranges: two that have no number in common under AND, or that hold
*> every number under OR, are reported too:
*>
*>     IF WS-AMOUNT > 5 AND WS-AMOUNT < 3           never true
*>     IF WS-AMOUNT < 5 OR >= 5                     always true
*>
*> For an item without decimal places, the ranges are of the whole
*> numbers it holds: WS-CODE > 3 AND WS-CODE < 4 is never true.
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
*> The operator of each relation: E =, G >, H >=, L <, M <= (NOT
*> folded into the others); and its value, when a number.
01  LS-PIECE-OP             PIC X OCCURS PIECE-MAX TIMES.
01  LS-PIECE-NUM            PIC S9(18)V9(9) COMP-3 OCCURS PIECE-MAX TIMES.
*> The operator carried to abbreviated relations.
01  LS-OP                   PIC X.
*> Two relations as intervals: low and high ends, Y for none (infinite),
*> Y for an end not included.
01  LS-A-LOW                PIC S9(18)V9(9) COMP-3.
01  LS-A-HIGH               PIC S9(18)V9(9) COMP-3.
01  LS-A-NO-LOW             PIC X.
01  LS-A-NO-HIGH            PIC X.
01  LS-A-OPEN-LOW           PIC X.
01  LS-A-OPEN-HIGH          PIC X.
01  LS-B-LOW                PIC S9(18)V9(9) COMP-3.
01  LS-B-HIGH               PIC S9(18)V9(9) COMP-3.
01  LS-B-NO-LOW             PIC X.
01  LS-B-NO-HIGH            PIC X.
01  LS-B-OPEN-LOW           PIC X.
01  LS-B-OPEN-HIGH          PIC X.
01  LS-P                    PIC 9(4) COMP-5.
01  LS-RANGE-FOUND          PIC X.
01  LS-OP-TEXT              PIC X(2).
01  LS-S                    PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(31).
01  LS-NUMERIC              PIC X.
*> Y when the subject holds whole numbers only, and when that is what
*> makes the ranges contradict.
01  LS-WHOLE                PIC X.
01  LS-BY-WHOLE             PIC X.
01  LS-W-LOW                PIC S9(18)V9(9) COMP-3.
01  LS-W-HIGH               PIC S9(18)V9(9) COMP-3.
01  LS-W-NO-LOW             PIC X.
01  LS-W-NO-HIGH            PIC X.
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
COPY "plbsym.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-RULES
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
               AND LS-PIECE-OP(LS-I) = "E"
               AND LS-PIECE-OP(LS-J + 1) = "E"
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
    END-PERFORM
    PERFORM CHECK-RANGES.

*> Two relations of one item with numbers, as intervals: under AND,
*> none in both; under OR, every number in one or the other.
CHECK-RANGES.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I >= LS-PIECE-COUNT
        PERFORM VARYING LS-J FROM LS-I BY 1 UNTIL LS-J >= LS-PIECE-COUNT
            COMPUTE LS-K = LS-J + 1
            IF LS-PIECE-SUBJECT(LS-I) = LS-PIECE-SUBJECT(LS-K)
               AND LS-PIECE-VALUE(LS-I)(1:2) = "N:"
               AND LS-PIECE-VALUE(LS-K)(1:2) = "N:"
               AND NOT (LS-PIECE-OP(LS-I) = "E"
                        AND LS-PIECE-OP(LS-K) = "E")
               AND NOT (LS-PIECE-OP(LS-I) = "E"
                        AND LS-PIECE-NOT(LS-I) = "Y")
               AND NOT (LS-PIECE-OP(LS-K) = "E"
                        AND LS-PIECE-NOT(LS-K) = "Y")
                PERFORM SUBJECT-NUMERIC
                IF LS-NUMERIC = "Y"
                    PERFORM TEST-RANGES
                ELSE
                    MOVE "N" TO LS-RANGE-FOUND
                END-IF
                IF LS-RANGE-FOUND = "Y"
                    PERFORM REPORT-RANGES
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM.

*> LS-RANGE-FOUND = "Y" when relations LS-I and LS-K, joined by
*> LS-JOIN, can never both hold (AND) or always hold one (OR).
TEST-RANGES.
    MOVE "N" TO LS-RANGE-FOUND
    MOVE LS-I TO LS-P
    PERFORM INTERVAL-OF
    MOVE LS-B-LOW TO LS-A-LOW
    MOVE LS-B-HIGH TO LS-A-HIGH
    MOVE LS-B-NO-LOW TO LS-A-NO-LOW
    MOVE LS-B-NO-HIGH TO LS-A-NO-HIGH
    MOVE LS-B-OPEN-LOW TO LS-A-OPEN-LOW
    MOVE LS-B-OPEN-HIGH TO LS-A-OPEN-HIGH
    MOVE LS-K TO LS-P
    PERFORM INTERVAL-OF
    MOVE "N" TO LS-BY-WHOLE
    PERFORM TEST-INTERVALS
    IF LS-RANGE-FOUND = "N" AND LS-WHOLE = "Y"
        *> Again with the whole numbers each holds. WHOLE-B works on
        *> LS-B-*, so the two are swapped round it; the tests do not
        *> depend on which is which.
        PERFORM WHOLE-B
        MOVE LS-B-LOW TO LS-W-LOW
        MOVE LS-B-HIGH TO LS-W-HIGH
        MOVE LS-A-LOW TO LS-B-LOW
        MOVE LS-A-HIGH TO LS-B-HIGH
        MOVE LS-A-NO-LOW TO LS-W-NO-LOW
        MOVE LS-B-NO-LOW TO LS-A-NO-LOW
        MOVE LS-W-NO-LOW TO LS-B-NO-LOW
        MOVE LS-A-NO-HIGH TO LS-W-NO-HIGH
        MOVE LS-B-NO-HIGH TO LS-A-NO-HIGH
        MOVE LS-W-NO-HIGH TO LS-B-NO-HIGH
        MOVE LS-A-OPEN-LOW TO LS-B-OPEN-LOW
        MOVE LS-A-OPEN-HIGH TO LS-B-OPEN-HIGH
        PERFORM WHOLE-B
        MOVE LS-W-LOW TO LS-A-LOW
        MOVE LS-W-HIGH TO LS-A-HIGH
        MOVE "N" TO LS-A-OPEN-LOW
        MOVE "Y" TO LS-A-OPEN-HIGH
        *> A relation no whole number meets on its own is not this
        *> rule's (PLB-C028).
        IF (LS-A-NO-LOW = "Y" OR LS-A-NO-HIGH = "Y"
            OR LS-A-LOW < LS-A-HIGH)
           AND (LS-B-NO-LOW = "Y" OR LS-B-NO-HIGH = "Y"
                OR LS-B-LOW < LS-B-HIGH)
            PERFORM TEST-INTERVALS
            MOVE LS-RANGE-FOUND TO LS-BY-WHOLE
        END-IF
    END-IF.

*> LS-RANGE-FOUND = "Y" when the intervals LS-A-* and LS-B-* have no
*> number in common (AND) or hold every number between them (OR).
TEST-INTERVALS.
    IF LS-JOIN = "A"
        *> The higher low end against the lower high end.
        IF LS-A-NO-LOW = "N" AND LS-B-NO-HIGH = "N"
            IF LS-A-LOW > LS-B-HIGH
               OR (LS-A-LOW = LS-B-HIGH
                   AND (LS-A-OPEN-LOW = "Y" OR LS-B-OPEN-HIGH = "Y"))
                MOVE "Y" TO LS-RANGE-FOUND
            END-IF
        END-IF
        IF LS-B-NO-LOW = "N" AND LS-A-NO-HIGH = "N"
            IF LS-B-LOW > LS-A-HIGH
               OR (LS-B-LOW = LS-A-HIGH
                   AND (LS-B-OPEN-LOW = "Y" OR LS-A-OPEN-HIGH = "Y"))
                MOVE "Y" TO LS-RANGE-FOUND
            END-IF
        END-IF
    ELSE
        *> One reaches down without end, the other up, and they meet.
        IF LS-A-NO-LOW = "Y" AND LS-B-NO-HIGH = "Y"
           AND LS-A-NO-HIGH = "N" AND LS-B-NO-LOW = "N"
            IF LS-B-LOW < LS-A-HIGH
               OR (LS-B-LOW = LS-A-HIGH
                   AND (LS-B-OPEN-LOW = "N" OR LS-A-OPEN-HIGH = "N"))
                MOVE "Y" TO LS-RANGE-FOUND
            END-IF
        END-IF
        IF LS-B-NO-LOW = "Y" AND LS-A-NO-HIGH = "Y"
           AND LS-B-NO-HIGH = "N" AND LS-A-NO-LOW = "N"
            IF LS-A-LOW < LS-B-HIGH
               OR (LS-A-LOW = LS-B-HIGH
                   AND (LS-A-OPEN-LOW = "N" OR LS-B-OPEN-HIGH = "N"))
                MOVE "Y" TO LS-RANGE-FOUND
            END-IF
        END-IF
    END-IF.

*> LS-NUMERIC = "Y" when the subject of relation LS-I names numeric
*> items only. An alphanumeric item is compared with a number character
*> by character, where "10" comes before "9".
SUBJECT-NUMERIC.
    MOVE "N" TO LS-NUMERIC LS-WHOLE
    *> A reference modification is alphanumeric.
    MOVE 0 TO LS-S
    INSPECT LS-PIECE-SUBJECT(LS-I) TALLYING LS-S FOR ALL ":"
    IF LS-S > 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-NAME
    UNSTRING LS-PIECE-SUBJECT(LS-I) DELIMITED BY "(" INTO LS-NAME
    MOVE FUNCTION UPPER-CASE(LS-NAME) TO LS-NAME
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF FUNCTION UPPER-CASE(SY-NAME(LS-S)) = LS-NAME
            IF SY-CATEGORY(LS-S) NOT = "9"
                MOVE "N" TO LS-NUMERIC LS-WHOLE
                EXIT PARAGRAPH
            END-IF
            *> Whole numbers only, when no item of the name has
            *> decimal places.
            IF LS-NUMERIC = "N" OR LS-WHOLE = "Y"
                IF SY-SCALE(LS-S) <= 0
                    MOVE "Y" TO LS-WHOLE
                ELSE
                    MOVE "N" TO LS-WHOLE
                END-IF
            END-IF
            MOVE "Y" TO LS-NUMERIC
        END-IF
    END-PERFORM.

*> The interval LS-B-* as the whole numbers it holds: its low end the
*> lowest of them, included; its high end the one past the highest,
*> not included. Ends without limit stay so.
WHOLE-B.
    IF LS-B-NO-LOW = "N"
        IF LS-B-OPEN-LOW = "Y"
            COMPUTE LS-B-LOW = FUNCTION INTEGER(LS-B-LOW) + 1
        ELSE
            COMPUTE LS-B-LOW = 0 - FUNCTION INTEGER(0 - LS-B-LOW)
        END-IF
    END-IF
    IF LS-B-NO-HIGH = "N"
        IF LS-B-OPEN-HIGH = "Y"
            COMPUTE LS-B-HIGH = 0 - FUNCTION INTEGER(0 - LS-B-HIGH)
        ELSE
            COMPUTE LS-B-HIGH = FUNCTION INTEGER(LS-B-HIGH) + 1
        END-IF
    END-IF
    MOVE "N" TO LS-B-OPEN-LOW
    MOVE "Y" TO LS-B-OPEN-HIGH.

*> Relation LS-P as the interval LS-B-*.
INTERVAL-OF.
    MOVE "N" TO LS-B-NO-LOW LS-B-NO-HIGH LS-B-OPEN-LOW LS-B-OPEN-HIGH
    MOVE LS-PIECE-NUM(LS-P) TO LS-B-LOW LS-B-HIGH
    EVALUATE LS-PIECE-OP(LS-P)
        WHEN "G"
            MOVE "Y" TO LS-B-NO-HIGH LS-B-OPEN-LOW
        WHEN "H"
            MOVE "Y" TO LS-B-NO-HIGH
        WHEN "L"
            MOVE "Y" TO LS-B-NO-LOW LS-B-OPEN-HIGH
        WHEN "M"
            MOVE "Y" TO LS-B-NO-LOW
    END-EVALUATE.

REPORT-RANGES.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    IF LS-JOIN = "A"
        STRING "this condition is never true: " DELIMITED BY SIZE
               LS-PIECE-SUBJECT(LS-I) DELIMITED BY SPACE
               " cannot be both " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING "this condition is always true: " DELIMITED BY SIZE
               LS-PIECE-SUBJECT(LS-I) DELIMITED BY SPACE
               " is always " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    MOVE LS-I TO LS-P
    PERFORM APPEND-RELATION
    IF LS-JOIN = "A"
        STRING " and " DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING " or " DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    MOVE LS-K TO LS-P
    PERFORM APPEND-RELATION
    IF LS-BY-WHOLE = "Y"
        STRING ", as it holds whole numbers only" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-FIRST LS-MESSAGE.

*> Operator and value of relation LS-P, as "> 5".
APPEND-RELATION.
    EVALUATE LS-PIECE-OP(LS-P)
        WHEN "G" MOVE ">" TO LS-OP-TEXT
        WHEN "H" MOVE ">=" TO LS-OP-TEXT
        WHEN "L" MOVE "<" TO LS-OP-TEXT
        WHEN "M" MOVE "<=" TO LS-OP-TEXT
        WHEN OTHER MOVE "=" TO LS-OP-TEXT
    END-EVALUATE
    STRING LS-OP-TEXT DELIMITED BY SPACE
           " " FUNCTION TRIM(LS-PIECE-SHOWN(LS-P)) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR.

*> LS-USABLE = "Y" when the tokens are a chain of relations of the form
*> the rule reads; the relations are then in LS-PIECE-*.
READ-CHAIN.
    MOVE "N" TO LS-USABLE
    MOVE 0 TO LS-PIECE-COUNT
    MOVE SPACE TO LS-JOIN
    MOVE "N" TO LS-HAVE-SUBJECT LS-NOT
    MOVE SPACE TO LS-OP
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
           AND LS-WORD NOT = "EQUAL" AND LS-WORD NOT = "GREATER"
           AND LS-WORD NOT = "LESS" AND LS-WORD NOT = "SPACE"
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
               OR LS-WORD = "GREATER" OR LS-WORD = "LESS"
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
    IF LS-OP = SPACE
        MOVE "X" TO LS-USABLE
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-PIECE-COUNT
    MOVE LS-SUBJECT TO LS-PIECE-SUBJECT(LS-PIECE-COUNT)
    MOVE LS-NOT TO LS-PIECE-NOT(LS-PIECE-COUNT)
    MOVE LS-OP TO LS-PIECE-OP(LS-PIECE-COUNT)
    MOVE 0 TO LS-PIECE-NUM(LS-PIECE-COUNT)
    IF LS-TEXT(1:2) = "N:"
        MOVE LS-NUMBER TO LS-PIECE-NUM(LS-PIECE-COUNT)
    END-IF
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

*> [IS] [NOT] operator at LS-T: LS-OP and LS-NOT. The operators are
*> =, EQUAL [TO], >, GREATER [THAN], <, LESS [THAN], >=, <=, and
*> GREATER or LESS [THAN] OR EQUAL [TO]; NOT before one other than =
*> turns it round (NOT > is <=), and LS-NOT stays "N". LS-USABLE = "E"
*> for anything else.
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
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    EVALUATE TRUE
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = "="
            MOVE "E" TO LS-OP
            ADD 1 TO LS-T
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = ">"
            MOVE "G" TO LS-OP
            ADD 1 TO LS-T
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = "<"
            MOVE "L" TO LS-OP
            ADD 1 TO LS-T
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = ">="
            MOVE "H" TO LS-OP
            ADD 1 TO LS-T
        WHEN TK-IS-OPERATOR(LS-T) AND LS-WORD = "<="
            MOVE "M" TO LS-OP
            ADD 1 TO LS-T
        WHEN LS-WORD = "EQUAL"
            MOVE "E" TO LS-OP
            ADD 1 TO LS-T
            PERFORM SKIP-THAN-TO
        WHEN LS-WORD = "GREATER" OR LS-WORD = "LESS"
            IF LS-WORD = "GREATER"
                MOVE "G" TO LS-OP
            ELSE
                MOVE "L" TO LS-OP
            END-IF
            ADD 1 TO LS-T
            PERFORM SKIP-THAN-TO
            *> OR EQUAL [TO]
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "OR" AND LS-T < LS-LAST
                ADD 1 TO LS-T
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = "EQUAL"
                    IF LS-OP = "G"
                        MOVE "H" TO LS-OP
                    ELSE
                        MOVE "M" TO LS-OP
                    END-IF
                    ADD 1 TO LS-T
                    PERFORM SKIP-THAN-TO
                ELSE
                    *> OR starts the next relation.
                    SUBTRACT 1 FROM LS-T
                END-IF
            END-IF
        WHEN OTHER
            MOVE "E" TO LS-USABLE
            EXIT PARAGRAPH
    END-EVALUATE
    *> NOT folded into the other operators.
    IF LS-NOT = "Y" AND LS-OP NOT = "E"
        EVALUATE LS-OP
            WHEN "G" MOVE "M" TO LS-OP
            WHEN "H" MOVE "L" TO LS-OP
            WHEN "L" MOVE "H" TO LS-OP
            WHEN "M" MOVE "G" TO LS-OP
        END-EVALUATE
        MOVE "N" TO LS-NOT
    END-IF.

*> Past THAN or TO at LS-T.
SKIP-THAN-TO.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) = "THAN"
       OR FUNCTION UPPER-CASE(LS-WORD) = "TO"
        ADD 1 TO LS-T
    END-IF.

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
