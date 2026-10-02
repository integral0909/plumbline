*> ---------------------------------------------------------------
*> plbrloop: loops that cannot end.
*>
*>   PLB-C026  varying-limit-unreachable
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
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-LOOPS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
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
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "PERFORM"
            PERFORM CHECK-PERFORM
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

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
END PROGRAM PLB-RULE-LOOPS.
