*> ---------------------------------------------------------------
*> plbrchain: PLB-C103 chain-exhausted.
*>
*> An IF of an ELSE IF chain, or the chain's last ELSE, that no value
*> reaches, because the tests before it take every value of their
*> item between them:
*>
*>     IF WS-AMOUNT > 5 ...
*>     ELSE IF WS-AMOUNT < 8 ...
*>     ELSE IF WS-AMOUNT >= 3 ...     never reached
*>     ELSE ...                       never runs
*>
*> Each test that is one relation of the item of the chain's first
*> such test with a number (PLB-COND-RANGE) takes its values out of
*> what is left (PLB-RANGE-REMOVE); a test of something else leaves
*> what is left as it is, as failing it says nothing about the item.
*> What is left is followed while it is one range. The first IF
*> reached with nothing left is reported, unless one earlier test
*> alone holds all its values, which is PLB-C051's; otherwise the
*> last ELSE is. An IF is a link of the chain when it is the first
*> statement of the ELSE of the one before, so nothing runs between
*> the tests.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C103.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-IF                   PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-COND                 PIC 9(9) COMP-5.
01  LS-ELSE                 PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-RESULT               PIC X.
01  LS-STATE                PIC X.
01  LS-SUBJECT              PIC X(64).
01  LS-MESSAGE              PIC X(200).
01  LS-LEFT.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==LE-==.
01  PLB-RANGE.
COPY "plbrange.cpy".
*> The ranges of the chain's tests on its item so far.
01  LS-SEEN-COUNT           PIC 9(4) COMP-5.
01  LS-SEEN                 OCCURS 50 TIMES.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==SN-==.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C103" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "IF"
            PERFORM CHECK-CHAIN
        END-IF
    END-PERFORM
    GOBACK.

*> The chain that starts at IF LS-NODE; an IF that is a link of a
*> chain is walked from its head.
CHECK-CHAIN.
    MOVE ND-PARENT(LS-NODE) TO LS-UP
    IF LS-UP > 0
        IF ND-KIND(LS-UP) = "BLCK" AND ND-DETAIL(LS-UP) = "ELSE"
           AND ND-FIRST(LS-UP) = LS-NODE
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE "A" TO LS-STATE
    MOVE SPACES TO LS-SUBJECT
    MOVE 0 TO LS-SEEN-COUNT
    MOVE LS-NODE TO LS-IF
    PERFORM UNTIL LS-IF = 0
        MOVE ND-FIRST(LS-IF) TO LS-COND
        IF LS-COND = 0
            EXIT PARAGRAPH
        END-IF
        IF ND-KIND(LS-COND) NOT = "COND"
            EXIT PARAGRAPH
        END-IF
        CALL "PLB-COND-RANGE" USING PLB-TOKENS PLB-AST PLB-SYMBOLS
            PLB-REFS LS-COND PLB-RANGE
        IF LS-STATE = "E"
            PERFORM REPORT-IF
            EXIT PARAGRAPH
        END-IF
        IF RG-OK = "Y"
            IF LS-SUBJECT = SPACES
                MOVE RG-SUBJECT TO LS-SUBJECT
            END-IF
            IF RG-SUBJECT = LS-SUBJECT
                CALL "PLB-RANGE-REMOVE" USING LS-LEFT LS-STATE PLB-RANGE
                IF LS-STATE = "U"
                    EXIT PARAGRAPH
                END-IF
                IF LS-SEEN-COUNT < 50
                    ADD 1 TO LS-SEEN-COUNT
                    MOVE PLB-RANGE TO LS-SEEN(LS-SEEN-COUNT)
                END-IF
            END-IF
        END-IF
        *> The next link: the first statement of this IF's ELSE.
        MOVE 0 TO LS-ELSE
        MOVE ND-FIRST(LS-IF) TO LS-C
        PERFORM UNTIL LS-C = 0
            IF ND-KIND(LS-C) = "BLCK" AND ND-DETAIL(LS-C) = "ELSE"
                MOVE LS-C TO LS-ELSE
            END-IF
            MOVE ND-NEXT(LS-C) TO LS-C
        END-PERFORM
        MOVE 0 TO LS-IF
        IF LS-ELSE > 0
            MOVE ND-FIRST(LS-ELSE) TO LS-C
            IF LS-C > 0
                IF ND-KIND(LS-C) = "STMT" AND ND-DETAIL(LS-C) = "IF"
                    MOVE LS-C TO LS-IF
                END-IF
            END-IF
            IF LS-IF = 0 AND LS-STATE = "E"
                PERFORM REPORT-ELSE
            END-IF
        END-IF
    END-PERFORM.

*> IF LS-COND, reached with no value left, unless one test before it
*> alone holds all its values (PLB-C051).
REPORT-IF.
    IF RG-OK = "Y" AND RG-SUBJECT = LS-SUBJECT
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-SEEN-COUNT
            CALL "PLB-RANGE-CONTAINS" USING LS-SEEN(LS-I) PLB-RANGE
                LS-RESULT
            IF LS-RESULT = "Y"
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "no value reaches this IF: the tests before it in the chain"
           " take every value of " DELIMITED BY SIZE
           LS-SUBJECT DELIMITED BY SPACE
        INTO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-COND) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.

REPORT-ELSE.
    MOVE SPACES TO LS-MESSAGE
    STRING "this ELSE never runs: the tests of the chain take every"
           " value of " DELIMITED BY SIZE
           LS-SUBJECT DELIMITED BY SPACE
        INTO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-ELSE) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C103.
