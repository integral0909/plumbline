*> ---------------------------------------------------------------
*> plbrbranch: PLB-C066 identical-branches.
*>
*> An IF whose ELSE does what its THEN does:
*>
*>     IF WS-ACCOUNT-TYPE = "S"
*>         MOVE SAVINGS-RATE TO WS-RATE
*>     ELSE
*>         MOVE SAVINGS-RATE TO WS-RATE
*>     END-IF
*>
*> The condition decides nothing. Usually one branch was copied from
*> the other and not changed. The branches are compared token by
*> token, as written after COPY and REPLACE: the same words, literals,
*> and operators in the same order. Spacing, line breaks, and comments
*> do not count, nor does the case of words.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C066.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-THEN                 PIC 9(9) COMP-5.
01  LS-ELSE                 PIC 9(9) COMP-5.
*> The statements of each branch: their first and last tokens.
01  LS-A-FROM               PIC 9(9) COMP-5.
01  LS-A-TO                 PIC 9(9) COMP-5.
01  LS-B-FROM               PIC 9(9) COMP-5.
01  LS-B-TO                 PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
01  LS-SAME                 PIC X.
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
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C066" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "IF"
            PERFORM CHECK-IF
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> IF statement LS-NODE: its THEN and ELSE blocks, when both have
*> statements, compared.
CHECK-IF.
    MOVE 0 TO LS-THEN LS-ELSE
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            EVALUATE ND-DETAIL(LS-CHILD)
                WHEN "THEN"
                    MOVE LS-CHILD TO LS-THEN
                WHEN "ELSE"
                    MOVE LS-CHILD TO LS-ELSE
            END-EVALUATE
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-THEN = 0 OR LS-ELSE = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-FIRST(LS-THEN) = 0 OR ND-FIRST(LS-ELSE) = 0
        EXIT PARAGRAPH
    END-IF
    *> From the first statement to the end of the last: the ELSE
    *> block's own range starts at the word ELSE.
    MOVE ND-TOK-FIRST(ND-FIRST(LS-THEN)) TO LS-A-FROM
    MOVE ND-TOK-LAST(ND-LAST(LS-THEN)) TO LS-A-TO
    MOVE ND-TOK-FIRST(ND-FIRST(LS-ELSE)) TO LS-B-FROM
    MOVE ND-TOK-LAST(ND-LAST(LS-ELSE)) TO LS-B-TO
    IF LS-A-TO - LS-A-FROM NOT = LS-B-TO - LS-B-FROM
        EXIT PARAGRAPH
    END-IF
    PERFORM COMPARE-TOKENS
    IF LS-SAME = "Y"
        PERFORM REPORT-IF
    END-IF.

*> LS-SAME = "Y" when the two ranges hold the same tokens.
COMPARE-TOKENS.
    MOVE "Y" TO LS-SAME
    PERFORM VARYING LS-I FROM 0 BY 1 UNTIL LS-I > LS-A-TO - LS-A-FROM
        COMPUTE LS-A = LS-A-FROM + LS-I
        COMPUTE LS-B = LS-B-FROM + LS-I
        IF TK-KIND(LS-A) NOT = TK-KIND(LS-B)
           OR TK-PREFIX(LS-A) NOT = TK-PREFIX(LS-B)
           OR TK-TEXT-LEN(LS-A) NOT = TK-TEXT-LEN(LS-B)
            MOVE "N" TO LS-SAME
            EXIT PERFORM
        END-IF
        IF TK-TEXT-LEN(LS-A) > 0
            IF TK-TEXT(TK-TEXT-OFF(LS-A):TK-TEXT-LEN(LS-A))
               NOT = TK-TEXT(TK-TEXT-OFF(LS-B):TK-TEXT-LEN(LS-B))
                MOVE "N" TO LS-SAME
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

REPORT-IF.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "the ELSE of the IF on line " LS-NUM-TEXT(1:LS-NUM-LEN)
           " does what its THEN does: the condition decides nothing"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-ELSE) LS-MESSAGE.
END PROGRAM PLB-RULE-C066.
