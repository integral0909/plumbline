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
        STRING "this test is always true: the IF on line "
               DELIMITED BY SIZE
               LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
               ", whose THEN it starts, took only values that pass it"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        PERFORM REPORT-INNER
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-RANGE-MEETS" USING LS-OUTER PLB-RANGE LS-RESULT
    IF LS-RESULT = "N"
        PERFORM LINE-OF-OUTER
        STRING "this test is never true: the IF on line "
               DELIMITED BY SIZE
               LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
               ", whose THEN it starts, took no value that passes it"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        PERFORM REPORT-INNER
    END-IF.

*> LS-NUM-TEXT: the line of the outer test; LS-MESSAGE cleared.
LINE-OF-OUTER.
    MOVE 0 TO LS-NUM
    MOVE ND-TOK-FIRST(LS-COND) TO LS-TOKEN
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
