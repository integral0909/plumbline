*> ---------------------------------------------------------------
*> plbrnested: PLB-C102 nested-if-decided.
*>
*> An IF that is the first statement of the THEN branch of another,
*> whose test the outer test already decides:
*>
*>     IF WS-AMOUNT > 100
*>         IF WS-AMOUNT > 50          always true here
*>         ...
*>         IF WS-AMOUNT < 10          never true here
*>
*> The inner test runs only when the outer one was true, and nothing
*> runs in between, so its item still holds a value the outer test
*> took. Both tests must be one relation of the same numeric item with
*> a number (PLB-COND-RANGE), written the same way with the same
*> subscripts. Always true: every value the outer test takes passes
*> the inner one, and the inner ELSE never runs. Never true: no value
*> passes both, and the inner branch never runs.
*>
*> The same holds for an IF that starts the body of an inline PERFORM
*> ... UNTIL, tested before each time round (not WITH TEST AFTER, and
*> not VARYING ... AFTER): the body runs only while the UNTIL test is
*> false, so its item holds a value that fails it. An UNTIL test with
*> one end (> < >= <=, not =) leaves the values beyond it:
*>
*>     PERFORM UNTIL WS-I > 10
*>         IF WS-I > 20               never true here
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C102.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-COND                 PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-INNER                PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-OUTER-TOKEN          PIC 9(9) COMP-5.
01  LS-UNTIL-TOKEN          PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> What the inner IF starts: I for a THEN branch, P for a PERFORM body.
01  LS-KIND                 PIC X.
01  LS-UNTIL.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==UN-==.
01  LS-RESULT               PIC X.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
01  LS-OUTER.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==OU-==.
01  PLB-RANGE.
COPY "plbrange.cpy".
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C102" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "IF"
            PERFORM CHECK-IF
        END-IF
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "PERFORM"
            PERFORM CHECK-PERFORM
        END-IF
    END-PERFORM
    GOBACK.

*> IF LS-NODE: its test as a range, then the IF that starts its THEN.
CHECK-IF.
    MOVE ND-FIRST(LS-NODE) TO LS-COND
    IF LS-COND = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-COND) NOT = "COND"
        EXIT PARAGRAPH
    END-IF
    *> The first statement of the THEN branch.
    MOVE 0 TO LS-INNER
    MOVE ND-NEXT(LS-COND) TO LS-C
    IF LS-C > 0
        IF ND-KIND(LS-C) = "BLCK" AND ND-DETAIL(LS-C) = "THEN"
            MOVE ND-FIRST(LS-C) TO LS-INNER
        END-IF
    END-IF
    IF LS-INNER = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-INNER) NOT = "STMT" OR ND-DETAIL(LS-INNER) NOT = "IF"
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-COND-RANGE" USING PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-REFS
        LS-COND LS-OUTER
    MOVE "I" TO LS-KIND
    MOVE ND-TOK-FIRST(LS-COND) TO LS-OUTER-TOKEN
    PERFORM COMPARE-INNER.

*> Inline PERFORM LS-NODE: the values its UNTIL test leaves, then the
*> IF that starts its body.
CHECK-PERFORM.
    MOVE ND-FIRST(LS-NODE) TO LS-COND
    IF LS-COND = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-COND) NOT = "COND" OR ND-DETAIL(LS-COND) NOT = "LOOP"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-INNER
    MOVE ND-NEXT(LS-COND) TO LS-C
    IF LS-C > 0
        IF ND-KIND(LS-C) = "BLCK" AND ND-DETAIL(LS-C) = "BODY"
            MOVE ND-FIRST(LS-C) TO LS-INNER
        END-IF
    END-IF
    IF LS-INNER = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-INNER) NOT = "STMT" OR ND-DETAIL(LS-INNER) NOT = "IF"
        EXIT PARAGRAPH
    END-IF
    *> UNTIL, and no AFTER: neither WITH TEST AFTER nor VARYING AFTER.
    MOVE 0 TO LS-UNTIL-TOKEN
    PERFORM VARYING LS-TOKEN FROM ND-TOK-FIRST(LS-COND) BY 1
            UNTIL LS-TOKEN > ND-TOK-LAST(LS-COND)
        IF TK-IS-WORD(LS-TOKEN)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "AFTER"
                EXIT PARAGRAPH
            END-IF
            IF LS-WORD = "UNTIL" AND LS-UNTIL-TOKEN = 0
                MOVE LS-TOKEN TO LS-UNTIL-TOKEN
            END-IF
        END-IF
    END-PERFORM
    IF LS-UNTIL-TOKEN = 0 OR LS-UNTIL-TOKEN >= ND-TOK-LAST(LS-COND)
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-UNTIL-TOKEN
    CALL "PLB-SPAN-RANGE" USING PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-REFS
        LS-UNTIL-TOKEN ND-TOK-LAST(LS-COND) LS-UNTIL
    CALL "PLB-RANGE-COMPLEMENT" USING LS-UNTIL LS-OUTER
    MOVE "P" TO LS-KIND
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-OUTER-TOKEN
    PERFORM COMPARE-INNER.

*> The test of IF LS-INNER against LS-OUTER, the values its item can
*> hold there.
COMPARE-INNER.
    IF OU-OK NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-INNER) TO LS-C
    IF LS-C = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-C) NOT = "COND"
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-COND-RANGE" USING PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-REFS
        LS-C PLB-RANGE
    IF RG-OK NOT = "Y" OR RG-SUBJECT NOT = OU-SUBJECT
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-RANGE-CONTAINS" USING PLB-RANGE LS-OUTER LS-RESULT
    IF LS-RESULT = "Y"
        PERFORM LINE-OF-OUTER
        IF LS-KIND = "I"
            STRING "this test is always true: the IF on line "
                   DELIMITED BY SIZE
                   LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
                   ", whose THEN it starts, took only values that pass"
                   " it" DELIMITED BY SIZE
                INTO LS-MESSAGE
        ELSE
            STRING "this test is always true: the PERFORM on line "
                   DELIMITED BY SIZE
                   LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
                   " runs its body only for values that pass it"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
        END-IF
        PERFORM REPORT-INNER
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-RANGE-MEETS" USING LS-OUTER PLB-RANGE LS-RESULT
    IF LS-RESULT = "N"
        PERFORM LINE-OF-OUTER
        IF LS-KIND = "I"
            STRING "this test is never true: the IF on line "
                   DELIMITED BY SIZE
                   LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
                   ", whose THEN it starts, took no value that passes it"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
        ELSE
            STRING "this test is never true: the PERFORM on line "
                   DELIMITED BY SIZE
                   LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
                   " runs its body for no value that passes it"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
        END-IF
        PERFORM REPORT-INNER
    END-IF.

*> LS-NUM-TEXT: the line of the outer statement; LS-MESSAGE cleared.
LINE-OF-OUTER.
    MOVE 0 TO LS-NUM
    MOVE LS-OUTER-TOKEN TO LS-TOKEN
    IF TK-SRC-LINE(LS-TOKEN) > 0
        MOVE SL-LINE-NO(TK-SRC-LINE(LS-TOKEN)) TO LS-NUM
    END-IF
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE.

REPORT-INNER.
    MOVE ND-TOK-FIRST(LS-C) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C102.
