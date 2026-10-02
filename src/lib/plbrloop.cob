*> ---------------------------------------------------------------
*> plbrloop: comparisons that a data item cannot satisfy.
*>
*>   PLB-C026  varying-limit-unreachable
*>   PLB-C028  comparison-never-true
*>
*> PERFORM VARYING I ... UNTIL I > 99, with I PIC 99: I goes from 99
*> to 00 when it is increased, so it is never greater than 99, and the
*> loop runs until something else stops the program. The rule checks
*> conditions of the form
*>
*>     UNTIL counter op literal
*>
*> on the counter the VARYING phrase names, where op is >, >=, =, <,
*> or <= (or their words), against the largest and smallest values the
*> counter can hold. Only integer counters stored as decimal digits
*> (DISPLAY or PACKED-DECIMAL) are checked: a binary counter can hold
*> more than its PICTURE when the compiler does not truncate binary
*> data (IBM's TRUNC(BIN)), and GnuCOBOL's options differ too.
*>
*> PLB-C028 applies the same test to every condition of the form
*> item op literal in an IF, an UNTIL, or a WHEN, except on the
*> counters that C026 checks.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-LOOPS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-COMPARE         PIC 9(4) COMP-5.
01  LS-RULE-ALNUM           PIC 9(4) COMP-5.
01  LS-COND                 PIC 9(9) COMP-5.
01  LS-BLOCK                PIC 9(9) COMP-5.
01  LS-SUBJECT              PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-LIMIT                PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-COUNTER-TOKEN        PIC 9(9) COMP-5.
01  LS-COUNTER              PIC X(31).
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> The comparison: > G, >= H, = E, < L, <= M.
01  LS-OP                   PIC X.
01  LS-VALUE                PIC S9(18) COMP-5.
01  LS-VALUE-TOKEN          PIC 9(9) COMP-5.
01  LS-NEGATIVE             PIC X.
01  LS-LARGEST              PIC S9(18) COMP-5.
01  LS-SMALLEST             PIC S9(18) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-NEVER                PIC X.
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
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C026" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C028" LS-RULE-COMPARE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C045" LS-RULE-ALNUM
    IF AS-COUNT = 0
        GOBACK
    END-IF
    IF RL-ENABLED(LS-RULE) = "Y"
        MOVE 1 TO LS-NODE
        MOVE 0 TO LS-DEPTH
        PERFORM UNTIL LS-NODE = 0
            IF ND-KIND(LS-NODE) = "STMT"
               AND ND-DETAIL(LS-NODE) = "PERFORM"
                PERFORM CHECK-PERFORM
            END-IF
            CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
        END-PERFORM
    END-IF
    IF RL-ENABLED(LS-RULE-COMPARE) = "Y" OR RL-ENABLED(LS-RULE-ALNUM) = "Y"
        PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
            *> A table element holds what its entry does, so
            *> subscripts are fine; reference modification is not.
            IF RF-KIND(LS-R) = "D" AND RF-REFMOD(LS-R) = "N"
               AND RF-STMT(LS-R) > 0
                PERFORM CHECK-COMPARISON
            END-IF
        END-PERFORM
    END-IF
    GOBACK.

*> PLB-C028: reference LS-R, when it is the subject of a relation
*> with an integer literal in a condition.
CHECK-COMPARISON.
    MOVE RF-TOKEN(LS-R) TO LS-SUBJECT
    *> Not an operand of arithmetic: A + B > 99 compares the sum.
    IF LS-SUBJECT > 1
        COMPUTE LS-T = LS-SUBJECT - 1
        IF TK-IS-OPERATOR(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "+" OR "-" OR "*" OR "/" OR "**"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-IF
    PERFORM FIND-CONDITION
    IF LS-COND = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-TOK-LAST(LS-COND) TO LS-LIMIT
    COMPUTE LS-T = RF-LAST(LS-R) + 1
    PERFORM READ-OPERATOR
    IF LS-OP = SPACE
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-LITERAL
    IF LS-VALUE-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = LS-VALUE-TOKEN + 1
    IF LS-T <= LS-LIMIT AND TK-IS-OPERATOR(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF LS-WORD = "+" OR "-" OR "*" OR "/" OR "**"
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    PERFORM CHECK-ALNUM-NUMBER
    IF RL-ENABLED(LS-RULE-COMPARE) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    IF ND-DETAIL(LS-COND) = "LOOP"
        PERFORM SKIP-IF-COUNTER
        IF LS-SUBJECT = 0
            EXIT PARAGRAPH
        END-IF
    END-IF
    PERFORM COUNTER-RANGE
    IF LS-LARGEST < 0
        EXIT PARAGRAPH
    END-IF
    PERFORM DECIDE
    IF LS-NEVER = "Y"
        MOVE SY-NAME(LS-S) TO LS-COUNTER
        PERFORM REPORT-COMPARISON
    END-IF.

*> PLB-C045 alnum-compared-to-number: an alphanumeric item (or group)
*> compared with a numeric literal that has fewer digits than the item
*> has characters. The comparison is of characters: 0 is "0" followed
*> by spaces, so IF CODE = 0 is false when CODE, PIC X(3), holds "000".
*> ZERO, which fills the item, is fine.
CHECK-ALNUM-NUMBER.
    IF RL-ENABLED(LS-RULE-ALNUM) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-S) NOT = "X" AND NOT = "A" AND NOT = "G"
        EXIT PARAGRAPH
    END-IF
    *> PIC X COMP-X (an extension) is a binary number.
    IF SY-USAGE(LS-S) NOT = SPACES AND SY-USAGE(LS-S) NOT = "DISPLAY"
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-VALUE-TOKEN LS-WORD LS-LEN
    IF SY-SIZE(LS-S) <= LS-LEN
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " is alphanumeric: " DELIMITED BY SIZE
           LS-WORD(1:LS-LEN) DELIMITED BY SIZE
           " compares as the characters " DELIMITED BY SIZE
           LS-WORD(1:LS-LEN) DELIMITED BY SIZE
           " followed by spaces, not as a number" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-ALNUM LS-VALUE-TOKEN LS-MESSAGE.

*> LS-COND = the condition of statement RF-STMT(LS-R), or of one of
*> its WHEN phrases, that contains the reference; 0 when the reference
*> is not in one.
FIND-CONDITION.
    MOVE 0 TO LS-COND
    MOVE ND-FIRST(RF-STMT(LS-R)) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0 OR LS-COND > 0
        EVALUATE ND-KIND(LS-CHILD)
            WHEN "COND"
                MOVE LS-CHILD TO LS-NODE
                PERFORM TEST-CONDITION
            WHEN "BLCK"
                MOVE ND-FIRST(LS-CHILD) TO LS-BLOCK
                PERFORM UNTIL LS-BLOCK = 0 OR LS-COND > 0
                    IF ND-KIND(LS-BLOCK) = "COND"
                        MOVE LS-BLOCK TO LS-NODE
                        PERFORM TEST-CONDITION
                    END-IF
                    MOVE ND-NEXT(LS-BLOCK) TO LS-BLOCK
                END-PERFORM
        END-EVALUATE
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

TEST-CONDITION.
    IF ND-DETAIL(LS-NODE) NOT = "SUBJECT"
       AND ND-TOK-FIRST(LS-NODE) <= LS-SUBJECT
       AND ND-TOK-LAST(LS-NODE) > RF-LAST(LS-R)
        MOVE LS-NODE TO LS-COND
    END-IF.

*> LS-SUBJECT = 0 when the subject is a counter that VARYING or AFTER
*> names in the loop condition LS-COND: PLB-C026 checks those.
SKIP-IF-COUNTER.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-SUBJECT LS-COUNTER LS-LEN
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-COND) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-COND)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "VARYING" OR LS-WORD = "AFTER"
                COMPUTE LS-NEXT = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-NEXT LS-WORD
                    LS-LEN
                IF LS-WORD = LS-COUNTER
                    MOVE 0 TO LS-SUBJECT
                    EXIT PERFORM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> The tokens of the PERFORM before its body, if it has one.
CHECK-PERFORM.
    MOVE ND-TOK-LAST(LS-NODE) TO LS-LIMIT
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            COMPUTE LS-LIMIT = ND-TOK-FIRST(LS-CHILD) - 1
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    *> VARYING counter
    MOVE 0 TO LS-COUNTER-TOKEN
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= LS-LIMIT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "VARYING"
                COMPUTE LS-COUNTER-TOKEN = LS-T + 1
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-COUNTER-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-WORD(LS-COUNTER-TOKEN)
        EXIT PARAGRAPH
    END-IF
    PERFORM COUNTER-SYMBOL
    IF LS-S = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM COUNTER-RANGE
    IF LS-LARGEST < 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-COUNTER-TOKEN LS-COUNTER
        LS-LEN
    *> UNTIL counter op literal
    PERFORM VARYING LS-T FROM LS-COUNTER-TOKEN BY 1
            UNTIL LS-T >= LS-LIMIT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "UNTIL"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-T >= LS-LIMIT
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    IF NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD NOT = LS-COUNTER
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    PERFORM READ-OPERATOR
    IF LS-OP = SPACE
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-LITERAL
    IF LS-VALUE-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    *> The condition must end at the literal: no AND, OR, or
    *> arithmetic after it.
    COMPUTE LS-T = LS-VALUE-TOKEN + 1
    IF LS-T <= LS-LIMIT
        IF TK-IS-OPERATOR(LS-T)
            EXIT PARAGRAPH
        END-IF
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "AND" OR LS-WORD = "OR"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-IF
    PERFORM DECIDE
    IF LS-NEVER = "Y"
        PERFORM REPORT-LOOP
    END-IF.

*> LS-S = the counter's symbol, when it is a data item named without
*> subscripts; else 0.
COUNTER-SYMBOL.
    MOVE 0 TO LS-S
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-COUNTER-TOKEN
            IF RF-KIND(LS-R) = "D" AND RF-SUBSCRIPTED(LS-R) = "N"
               AND RF-REFMOD(LS-R) = "N"
                MOVE RF-SYMBOL(LS-R) TO LS-S
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-LARGEST and LS-SMALLEST the counter can hold; LS-LARGEST is -1
*> when the counter is not one the rule checks.
COUNTER-RANGE.
    MOVE -1 TO LS-LARGEST
    IF SY-CATEGORY(LS-S) NOT = "9" OR SY-SCALE(LS-S) NOT = 0
       OR SY-DIGITS(LS-S) = 0 OR SY-DIGITS(LS-S) > 17
        EXIT PARAGRAPH
    END-IF
    EVALUATE SY-USAGE(LS-S)
        WHEN SPACES WHEN "DISPLAY" WHEN "PACKED-DECIMAL" WHEN "COMP-3"
        WHEN "COMPUTATIONAL-3"
            CONTINUE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE 1 TO LS-LARGEST
    PERFORM SY-DIGITS(LS-S) TIMES
        MULTIPLY 10 BY LS-LARGEST
    END-PERFORM
    SUBTRACT 1 FROM LS-LARGEST
    IF SY-SIGNED(LS-S) = "Y"
        COMPUTE LS-SMALLEST = 0 - LS-LARGEST
    ELSE
        MOVE 0 TO LS-SMALLEST
    END-IF.

*> LS-OP from the relational operator at LS-T: symbols, or words
*> ([IS] GREATER [THAN] [OR EQUAL [TO]], EQUAL [TO], LESS ...).
*> LS-T is left after it. A NOT makes the rule give up.
READ-OPERATOR.
    MOVE SPACE TO LS-OP
    IF LS-T > LS-LIMIT
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF TK-IS-OPERATOR(LS-T)
        EVALUATE LS-WORD
            WHEN ">"
                MOVE "G" TO LS-OP
            WHEN ">="
                MOVE "H" TO LS-OP
            WHEN "="
                MOVE "E" TO LS-OP
            WHEN "<"
                MOVE "L" TO LS-OP
            WHEN "<="
                MOVE "M" TO LS-OP
        END-EVALUATE
        ADD 1 TO LS-T
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    IF LS-WORD = "IS"
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    END-IF
    EVALUATE LS-WORD
        WHEN "GREATER"
            MOVE "G" TO LS-OP
        WHEN "LESS"
            MOVE "L" TO LS-OP
        WHEN "EQUAL"
            MOVE "E" TO LS-OP
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    ADD 1 TO LS-T
    PERFORM SKIP-THAN-TO
    *> GREATER THAN OR EQUAL TO, LESS THAN OR EQUAL TO
    IF LS-OP NOT = "E" AND TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        COMPUTE LS-NEXT = LS-T + 1
        IF LS-WORD = "OR" AND TK-IS-WORD(LS-NEXT)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-NEXT LS-WORD LS-LEN
            IF LS-WORD = "EQUAL"
                IF LS-OP = "G"
                    MOVE "H" TO LS-OP
                ELSE
                    MOVE "M" TO LS-OP
                END-IF
                ADD 2 TO LS-T
                PERFORM SKIP-THAN-TO
            END-IF
        END-IF
    END-IF.

SKIP-THAN-TO.
    IF TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF LS-WORD = "THAN" OR LS-WORD = "TO"
            ADD 1 TO LS-T
        END-IF
    END-IF.

*> LS-VALUE from an integer literal at LS-T (with a sign or not);
*> LS-VALUE-TOKEN is 0 when there is none.
READ-LITERAL.
    MOVE 0 TO LS-VALUE-TOKEN
    IF LS-T > LS-LIMIT OR NOT TK-IS-NUMBER(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE "N" TO LS-NEGATIVE
    MOVE 1 TO LS-I
    IF LS-WORD(1:1) = "+" OR LS-WORD(1:1) = "-"
        IF LS-WORD(1:1) = "-"
            MOVE "Y" TO LS-NEGATIVE
        END-IF
        MOVE 2 TO LS-I
    END-IF
    IF LS-I > LS-LEN OR LS-LEN - LS-I + 1 > 18
        EXIT PARAGRAPH
    END-IF
    IF LS-WORD(LS-I:LS-LEN - LS-I + 1) IS NOT NUMERIC
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-VALUE = FUNCTION NUMVAL(LS-WORD(LS-I:LS-LEN - LS-I + 1))
    IF LS-NEGATIVE = "Y"
        COMPUTE LS-VALUE = 0 - LS-VALUE
    END-IF
    MOVE LS-T TO LS-VALUE-TOKEN.

*> LS-NEVER = "Y" when no value the counter can hold makes the
*> condition true.
DECIDE.
    MOVE "N" TO LS-NEVER
    EVALUATE LS-OP
        WHEN "G"
            IF LS-LARGEST <= LS-VALUE
                MOVE "Y" TO LS-NEVER
            END-IF
        WHEN "H"
            IF LS-LARGEST < LS-VALUE
                MOVE "Y" TO LS-NEVER
            END-IF
        WHEN "E"
            IF LS-LARGEST < LS-VALUE OR LS-SMALLEST > LS-VALUE
                MOVE "Y" TO LS-NEVER
            END-IF
        WHEN "L"
            IF LS-SMALLEST >= LS-VALUE
                MOVE "Y" TO LS-NEVER
            END-IF
        WHEN "M"
            IF LS-SMALLEST > LS-VALUE
                MOVE "Y" TO LS-NEVER
            END-IF
    END-EVALUATE.

REPORT-LOOP.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING LS-COUNTER DELIMITED BY SPACE
           " holds " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-OP = "L" OR LS-OP = "M"
       OR (LS-OP = "E" AND LS-VALUE < LS-SMALLEST)
        STRING "nothing below " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-SMALLEST TO LS-NUM
    ELSE
        STRING "nothing above " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-LARGEST TO LS-NUM
    END-IF
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", so the UNTIL condition is never true; only leaving the"
           DELIMITED BY SIZE
           " loop another way ends it" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-VALUE-TOKEN LS-MESSAGE.

REPORT-COMPARISON.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING LS-COUNTER DELIMITED BY SPACE
           " holds " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-OP = "L" OR LS-OP = "M"
       OR (LS-OP = "E" AND LS-VALUE < LS-SMALLEST)
        STRING "nothing below " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-SMALLEST TO LS-NUM
    ELSE
        STRING "nothing above " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-LARGEST TO LS-NUM
    END-IF
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", so this comparison is never true" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-COMPARE LS-VALUE-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-LOOPS.

*> PLB-C044 varying-control-changed: a statement inside a PERFORM
*> VARYING loop that stores into the loop's control item (the item
*> after VARYING or AFTER). The loop then steps from the changed value:
*> it skips or repeats iterations, or never ends. The body is the
*> inline loop's statements, or, for PERFORM procedure VARYING, the
*> paragraphs from the procedure through its THRU; procedures they
*> perform in turn are not followed.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C044.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-LOOP                 PIC 9(9) COMP-5.
01  LS-BODY                 PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-PHRASE-FROM          PIC 9(9) COMP-5.
01  LS-PHRASE-TO            PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-CONTROL              PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
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
COPY "plbflow.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-FLOW PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C044" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "PERFORM"
            PERFORM CHECK-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> The loop phrase and the inline body of PERFORM statement LS-NODE.
CHECK-PERFORM.
    MOVE 0 TO LS-LOOP LS-BODY
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        EVALUATE TRUE
            WHEN ND-KIND(LS-CHILD) = "COND" AND ND-DETAIL(LS-CHILD) = "LOOP"
                MOVE LS-CHILD TO LS-LOOP
            WHEN ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "BODY"
                MOVE LS-CHILD TO LS-BODY
        END-EVALUATE
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    *> PERFORM procedure VARYING ... has no loop node: its VARYING
    *> phrase is in the statement's own tokens.
    IF LS-LOOP = 0
        IF LS-BODY > 0
            EXIT PARAGRAPH
        END-IF
        MOVE ND-TOK-FIRST(LS-NODE) TO LS-PHRASE-FROM
        MOVE ND-TOK-LAST(LS-NODE) TO LS-PHRASE-TO
    ELSE
        MOVE ND-TOK-FIRST(LS-LOOP) TO LS-PHRASE-FROM
        MOVE ND-TOK-LAST(LS-LOOP) TO LS-PHRASE-TO
    END-IF
    *> Each control item: the data item after VARYING or AFTER.
    PERFORM VARYING LS-T FROM LS-PHRASE-FROM BY 1
            UNTIL LS-T >= LS-PHRASE-TO
        IF TK-IS-WORD(LS-T) AND WS-TOKEN-REF(LS-T) = 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "VARYING"
               OR FUNCTION UPPER-CASE(LS-WORD) = "AFTER"
                COMPUTE LS-Q = LS-T + 1
                IF WS-TOKEN-REF(LS-Q) > 0
                    MOVE WS-TOKEN-REF(LS-Q) TO LS-R
                    IF RF-KIND(LS-R) = "D"
                        MOVE RF-SYMBOL(LS-R) TO LS-CONTROL
                        PERFORM CHECK-BODY
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM.

CHECK-BODY.
    IF LS-BODY > 0
        MOVE ND-TOK-FIRST(LS-BODY) TO LS-FROM
        MOVE ND-TOK-LAST(LS-BODY) TO LS-TO
        PERFORM FIND-STORES
        EXIT PARAGRAPH
    END-IF
    *> PERFORM procedure [THRU last] VARYING: the units of the range.
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-STMT(LS-E) = LS-NODE AND FE-KIND(LS-E) = "P"
           AND FE-TO(LS-E) > 0
            MOVE FE-THRU(LS-E) TO LS-LAST
            IF LS-LAST < FE-TO(LS-E)
                MOVE FE-TO(LS-E) TO LS-LAST
            END-IF
            PERFORM VARYING LS-U FROM FE-TO(LS-E) BY 1
                    UNTIL LS-U > LS-LAST
                MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO LS-FROM
                MOVE ND-TOK-LAST(FU-NODE(LS-U)) TO LS-TO
                PERFORM FIND-STORES
            END-PERFORM
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Each reference from LS-FROM to LS-TO that stores into the control
*> item or a group around it (role D, or B as in ADD 1 TO it).
FIND-STORES.
    PERFORM VARYING LS-S FROM LS-FROM BY 1 UNTIL LS-S > LS-TO
        IF WS-TOKEN-REF(LS-S) > 0
            MOVE WS-TOKEN-REF(LS-S) TO LS-R
            IF RF-KIND(LS-R) = "D"
               AND (RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B")
                MOVE LS-CONTROL TO LS-UP
                PERFORM UNTIL LS-UP = 0
                    IF RF-SYMBOL(LS-R) = LS-UP
                        PERFORM REPORT-STORE
                        EXIT PERFORM
                    END-IF
                    MOVE SY-PARENT(LS-UP) TO LS-UP
                END-PERFORM
            END-IF
        END-IF
    END-PERFORM.

REPORT-STORE.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-CONTROL) DELIMITED BY SPACE
           " is the control of the PERFORM VARYING on line "
           DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", and this statement changes it inside the loop"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-S LS-MESSAGE.
END PROGRAM PLB-RULE-C044.
