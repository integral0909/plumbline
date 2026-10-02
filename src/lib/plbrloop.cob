*> ---------------------------------------------------------------
*> plbrloop: loops, and comparisons that a data item cannot satisfy.
*>
*>   PLB-C026  varying-limit-unreachable
*>   PLB-C028  comparison-never-true
*>   PLB-C044  varying-control-changed
*>   PLB-C049  loop-condition-unchanged
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

*> PLB-C049 loop-condition-unchanged: a PERFORM ... UNTIL whose loop
*> changes nothing its condition reads, so that unless the condition
*> holds when the loop starts, the loop never ends:
*>
*>     PERFORM READ-NEXT UNTIL WS-EOF = "Y"
*>
*> when READ-NEXT sets some other flag. The loop is the inline body, or
*> the procedure range it performs, with every paragraph and section
*> that runs from there by PERFORM or GO TO; the condition's items are
*> the data items it names (a condition name stands for its item). An
*> item counts as changed when a statement of the loop stores into it,
*> or into an item that shares storage with it, or passes it to a CALL
*> by reference.
*>
*> The loop is left alone when it can end some other way, or change
*> things the references do not show: when it reaches a GO TO, EXIT
*> PERFORM, STOP RUN, GOBACK, EXIT PROGRAM, CALL, ALTER, EXEC, or I/O
*> statement (READ changes a record and its FILE STATUS without naming
*> them); when the condition calls a FUNCTION, names an index or a
*> name that is not resolved, or names no data item; when one of its
*> items is in the LINKAGE SECTION; and when the
*> analysis could not resolve a procedure the loop runs.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C049.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
*> The storage of each item.
COPY "plbspan.cpy" REPLACING ==PLB-SPANS== BY ==WS-SPANS==.
*> The condition's items.
78  WS-COND-MAX             VALUE 50.
01  WS-COND-COUNT           PIC 9(4) COMP-5.
01  WS-COND                 PIC 9(9) COMP-5 OCCURS WS-COND-MAX TIMES.
01  WS-COND-CHANGED         PIC X OCCURS WS-COND-MAX TIMES.
*> The units the loop runs: a work list, and the mark of each unit on
*> it.
01  WS-IN-SET               PIC X OCCURS 20000 TIMES.
01  WS-SET                  PIC 9(9) COMP-5 OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-BODY                 PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-SCAN                 PIC 9(9) COMP-5.
01  LS-SCAN-DEPTH           PIC S9(9) COMP-5.
01  LS-SCAN-ROOT            PIC 9(9) COMP-5.
01  LS-COND-FIRST           PIC 9(9) COMP-5.
01  LS-COND-LAST            PIC 9(9) COMP-5.
01  LS-UNTIL                PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-SET-COUNT            PIC 9(9) COMP-5.
01  LS-SET-NEXT             PIC 9(9) COMP-5.
01  LS-RANGE-FIRST          PIC 9(9) COMP-5.
01  LS-RANGE-LAST           PIC 9(9) COMP-5.
01  LS-GIVE-UP              PIC X.
01  LS-OVERLAP              PIC X.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NAMES                PIC X(120).
01  LS-NAMES-PTR            PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C049" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    CALL "PLB-SPAN-BUILD" USING PLB-SYMBOLS WS-SPANS
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE "N" TO WS-IN-SET(LS-U)
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "PERFORM"
            MOVE LS-NODE TO LS-STMT
            PERFORM CHECK-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

CHECK-PERFORM.
    PERFORM FIND-CONDITION
    IF LS-UNTIL = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM CONDITION-ITEMS
    IF LS-GIVE-UP = "Y" OR WS-COND-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-SET-COUNT
    *> The inline body, then the procedures the statement and the body
    *> perform.
    IF LS-BODY > 0
        MOVE ND-TOK-FIRST(LS-BODY) TO LS-RANGE-FIRST
        MOVE ND-TOK-LAST(LS-BODY) TO LS-RANGE-LAST
        MOVE LS-BODY TO LS-SCAN-ROOT
        PERFORM SCAN-RANGE
        PERFORM VARYING LS-E FROM 1 BY 1
                UNTIL LS-E > FE-COUNT OR LS-GIVE-UP = "Y"
            IF FE-STMT(LS-E) > 0
               AND ND-TOK-FIRST(FE-STMT(LS-E)) >= LS-RANGE-FIRST
               AND ND-TOK-FIRST(FE-STMT(LS-E)) <= LS-RANGE-LAST
                PERFORM ADD-EDGE
            END-IF
        END-PERFORM
    ELSE
        PERFORM VARYING LS-E FROM 1 BY 1
                UNTIL LS-E > FE-COUNT OR LS-GIVE-UP = "Y"
            IF FE-STMT(LS-E) = LS-STMT
                PERFORM ADD-EDGE
            END-IF
        END-PERFORM
    END-IF
    MOVE 1 TO LS-SET-NEXT
    PERFORM UNTIL LS-SET-NEXT > LS-SET-COUNT OR LS-GIVE-UP = "Y"
        MOVE WS-SET(LS-SET-NEXT) TO LS-U
        PERFORM VISIT-UNIT
        ADD 1 TO LS-SET-NEXT
    END-PERFORM
    PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > LS-SET-COUNT
        MOVE "N" TO WS-IN-SET(WS-SET(LS-V))
    END-PERFORM
    IF LS-GIVE-UP = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-COND-COUNT
        IF WS-COND-CHANGED(LS-C) = "Y"
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    PERFORM REPORT-LOOP.

*> LS-UNTIL: the UNTIL token of a PERFORM without VARYING or TIMES
*> (0 otherwise); LS-COND-FIRST and LS-COND-LAST: the condition after
*> it; LS-BODY: the inline body (0 for an out-of-line PERFORM).
FIND-CONDITION.
    MOVE 0 TO LS-UNTIL LS-BODY
    MOVE ND-TOK-LAST(LS-STMT) TO LS-COND-LAST
    MOVE ND-FIRST(LS-STMT) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            MOVE LS-CHILD TO LS-BODY
            COMPUTE LS-COND-LAST = ND-TOK-FIRST(LS-CHILD) - 1
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > LS-COND-LAST
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            EVALUATE LS-WORD
                WHEN "VARYING"
                WHEN "TIMES"
                    MOVE 0 TO LS-UNTIL
                    EXIT PARAGRAPH
                WHEN "UNTIL"
                    IF LS-UNTIL = 0
                        MOVE LS-T TO LS-UNTIL
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM
    COMPUTE LS-COND-FIRST = LS-UNTIL + 1.

*> The data items the condition names. A FUNCTION, a name that is not
*> a data item (an index), an item of the LINKAGE SECTION, or more
*> items than the table holds: give up.
CONDITION-ITEMS.
    MOVE 0 TO WS-COND-COUNT
    MOVE "N" TO LS-GIVE-UP
    PERFORM VARYING LS-T FROM LS-COND-FIRST BY 1
            UNTIL LS-T > LS-COND-LAST OR LS-GIVE-UP = "Y"
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "FUNCTION"
                MOVE "Y" TO LS-GIVE-UP
            END-IF
        END-IF
        MOVE WS-TOKEN-REF(LS-T) TO LS-R
        IF LS-R > 0
            *> An index name, or a name that did not resolve: its changes
            *> are not in the references.
            IF RF-KIND(LS-R) NOT = "D" OR RF-SYMBOL(LS-R) = 0
                MOVE "Y" TO LS-GIVE-UP
            ELSE
                MOVE RF-SYMBOL(LS-R) TO LS-S
                *> A condition name stands for its item.
                IF SY-CATEGORY(LS-S) = "C" AND SY-PARENT(LS-S) > 0
                    MOVE SY-PARENT(LS-S) TO LS-S
                END-IF
                PERFORM ADD-CONDITION-ITEM
            END-IF
        END-IF
    END-PERFORM.

ADD-CONDITION-ITEM.
    IF SY-SECTION(LS-S) = "K"
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-COND-COUNT
        IF WS-COND(LS-C) = LS-S
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-COND-COUNT >= WS-COND-MAX
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-COND-COUNT
    MOVE LS-S TO WS-COND(WS-COND-COUNT)
    MOVE "N" TO WS-COND-CHANGED(WS-COND-COUNT).

*> Edge LS-E: its procedures join the loop; an unresolved one, or an
*> ALTER, ends the check.
ADD-EDGE.
    IF FE-TO(LS-E) = 0 OR FE-KIND(LS-E) = "A"
        MOVE "Y" TO LS-GIVE-UP
        EXIT PARAGRAPH
    END-IF
    MOVE FE-TO(LS-E) TO LS-FROM
    MOVE FE-THRU(LS-E) TO LS-TO
    IF FE-KIND(LS-E) NOT = "P"
        MOVE 0 TO LS-TO
    END-IF
    PERFORM ADD-RANGE.

*> Units LS-FROM through LS-TO (LS-FROM alone when LS-TO is 0) onto
*> the work list.
ADD-RANGE.
    MOVE LS-FROM TO LS-V
    PERFORM UNTIL LS-V = 0
        PERFORM ADD-UNIT
        IF LS-TO = 0 OR LS-V = LS-TO
            EXIT PERFORM
        END-IF
        MOVE FU-NEXT(LS-V) TO LS-V
    END-PERFORM.

ADD-UNIT.
    IF WS-IN-SET(LS-V) = "N" AND LS-SET-COUNT < 20000
        MOVE "Y" TO WS-IN-SET(LS-V)
        ADD 1 TO LS-SET-COUNT
        MOVE LS-V TO WS-SET(LS-SET-COUNT)
    END-IF.

*> Unit LS-U of the loop: its statements, its paragraphs if it is a
*> section, and the procedures it performs or goes to.
VISIT-UNIT.
    MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO LS-RANGE-FIRST
    MOVE ND-TOK-LAST(FU-NODE(LS-U)) TO LS-RANGE-LAST
    MOVE FU-NODE(LS-U) TO LS-SCAN-ROOT
    PERFORM SCAN-RANGE
    IF FU-KIND(LS-U) = "S"
        PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > FU-COUNT
            IF FU-SECTION(LS-V) = LS-U
                PERFORM ADD-UNIT
            END-IF
        END-PERFORM
    END-IF
    PERFORM VARYING LS-E FROM 1 BY 1
            UNTIL LS-E > FE-COUNT OR LS-GIVE-UP = "Y"
        IF FE-FROM(LS-E) = LS-U
            PERFORM ADD-EDGE
        END-IF
    END-PERFORM.

*> The statements from LS-RANGE-FIRST to LS-RANGE-LAST: a way out of
*> the loop ends the check; a store marks the condition items it
*> reaches.
SCAN-RANGE.
    PERFORM VARYING LS-T FROM LS-RANGE-FIRST BY 1
            UNTIL LS-T > LS-RANGE-LAST OR LS-GIVE-UP = "Y"
        MOVE WS-TOKEN-REF(LS-T) TO LS-R
        IF LS-R > 0
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
               AND (RF-ROLE(LS-R) = "D" OR RF-ROLE(LS-R) = "B"
                    OR RF-ROLE(LS-R) = "X")
                PERFORM MARK-CHANGED
            END-IF
        END-IF
    END-PERFORM
    IF LS-GIVE-UP = "N"
        PERFORM SCAN-STATEMENTS
    END-IF.

*> Statements under node LS-SCAN-ROOT that leave the loop or act
*> unseen.
SCAN-STATEMENTS.
    MOVE LS-SCAN-ROOT TO LS-SCAN
    MOVE 0 TO LS-SCAN-DEPTH
    PERFORM UNTIL LS-SCAN = 0 OR LS-GIVE-UP = "Y"
        IF ND-KIND(LS-SCAN) = "STMT"
            EVALUATE ND-DETAIL(LS-SCAN)
                WHEN "GO"
                WHEN "STOP"
                WHEN "GOBACK"
                WHEN "CALL"
                WHEN "ALTER"
                WHEN "EXEC"
                WHEN "READ"
                WHEN "WRITE"
                WHEN "REWRITE"
                WHEN "DELETE"
                WHEN "START"
                WHEN "OPEN"
                WHEN "CLOSE"
                WHEN "RETURN"
                WHEN "RELEASE"
                WHEN "SORT"
                WHEN "MERGE"
                *> EXIT PARAGRAPH and EXIT SECTION stay in the loop.
                WHEN "EXIT PERFORM"
                WHEN "EXIT PROGRAM"
                WHEN "EXIT METHOD"
                WHEN "EXIT FUNCTION"
                    MOVE "Y" TO LS-GIVE-UP
            END-EVALUATE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-SCAN-ROOT LS-SCAN
            LS-SCAN-DEPTH
    END-PERFORM.

*> The item at reference LS-R is stored into: every condition item
*> that shares storage with it has changed.
MARK-CHANGED.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-COND-COUNT
        IF WS-COND-CHANGED(LS-C) = "N"
            IF WS-COND(LS-C) = RF-SYMBOL(LS-R)
                MOVE "Y" TO WS-COND-CHANGED(LS-C)
            ELSE
                CALL "PLB-SPAN-OVERLAP" USING WS-SPANS WS-COND(LS-C)
                    RF-SYMBOL(LS-R) LS-OVERLAP
                IF LS-OVERLAP = "Y"
                    MOVE "Y" TO WS-COND-CHANGED(LS-C)
                END-IF
            END-IF
        END-IF
    END-PERFORM.

REPORT-LOOP.
    MOVE SPACES TO LS-NAMES
    MOVE 1 TO LS-NAMES-PTR
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > WS-COND-COUNT
        EVALUATE TRUE
            WHEN LS-C = 1
                CONTINUE
            WHEN LS-C = WS-COND-COUNT
                STRING " or " DELIMITED BY SIZE
                    INTO LS-NAMES WITH POINTER LS-NAMES-PTR
            WHEN OTHER
                STRING ", " DELIMITED BY SIZE
                    INTO LS-NAMES WITH POINTER LS-NAMES-PTR
        END-EVALUATE
        STRING SY-NAME(WS-COND(LS-C)) DELIMITED BY SPACE
            INTO LS-NAMES WITH POINTER LS-NAMES-PTR
    END-PERFORM
    MOVE SPACES TO LS-MESSAGE
    STRING "the loop never changes " DELIMITED BY SIZE
           LS-NAMES(1:LS-NAMES-PTR - 1) DELIMITED BY SIZE
           ", which its UNTIL condition reads: unless the condition "
           "holds when the loop starts, it never ends" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-UNTIL LS-MESSAGE.
END PROGRAM PLB-RULE-C049.
