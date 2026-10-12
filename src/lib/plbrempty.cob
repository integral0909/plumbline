*> ---------------------------------------------------------------
*> plbrempty: PLB-M021 empty-branch-statement.
*>
*> An IF without ELSE, or an EVALUATE, whose every branch is
*> CONTINUE, or empty:
*>
*>     IF WS-CODE = "A"
*>         CONTINUE
*>     END-IF
*>
*> The statement does nothing: a condition without FUNCTION changes no
*> data (one with FUNCTION, which may, is not reported). It
*> is usually left from code taken out, or the branch that was meant to
*> act is missing. An IF with CONTINUE in one branch and statements in
*> the other is the common way to write a negated test, and is not
*> reported; nor is NEXT SENTENCE, which goes somewhere. An IF whose
*> ELSE is CONTINUE too is reported by PLB-C066.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-M021.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-BLOCK                PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-COND                 PIC 9(9) COMP-5.
01  LS-EMPTY                PIC X.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M021" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT"
           AND (ND-DETAIL(LS-NODE) = "IF"
                OR ND-DETAIL(LS-NODE) = "EVALUATE")
            PERFORM CHECK-STATEMENT
        END-IF
    END-PERFORM
    GOBACK.

*> LS-EMPTY = "Y" when every branch of statement LS-NODE holds no
*> statement but CONTINUE.
CHECK-STATEMENT.
    MOVE "Y" TO LS-EMPTY
    MOVE ND-FIRST(LS-NODE) TO LS-BLOCK
    PERFORM UNTIL LS-BLOCK = 0
        *> An IF with an ELSE that does what its THEN does is
        *> PLB-C066's.
        IF ND-KIND(LS-BLOCK) = "BLCK" AND ND-DETAIL(LS-BLOCK) = "ELSE"
            MOVE "N" TO LS-EMPTY
            EXIT PARAGRAPH
        END-IF
        IF ND-KIND(LS-BLOCK) = "BLCK"
            MOVE ND-FIRST(LS-BLOCK) TO LS-CHILD
            PERFORM UNTIL LS-CHILD = 0
                IF ND-KIND(LS-CHILD) = "COND"
                    MOVE LS-CHILD TO LS-COND
                    PERFORM CHECK-FUNCTION
                    IF LS-EMPTY = "N"
                        EXIT PARAGRAPH
                    END-IF
                ELSE
                    IF ND-KIND(LS-CHILD) NOT = "STMT"
                       OR ND-DETAIL(LS-CHILD) NOT = "CONTINUE"
                        MOVE "N" TO LS-EMPTY
                        EXIT PARAGRAPH
                    END-IF
                END-IF
                MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
            END-PERFORM
        ELSE
            *> Anything but the condition and the subject: give up.
            IF ND-KIND(LS-BLOCK) NOT = "COND"
                MOVE "N" TO LS-EMPTY
                EXIT PARAGRAPH
            END-IF
            MOVE LS-BLOCK TO LS-COND
            PERFORM CHECK-FUNCTION
            IF LS-EMPTY = "N"
                EXIT PARAGRAPH
            END-IF
        END-IF
        MOVE ND-NEXT(LS-BLOCK) TO LS-BLOCK
    END-PERFORM
    PERFORM REPORT-EMPTY.

*> A FUNCTION in condition LS-COND may act (RANDOM moves its seed, a
*> user-defined function can do anything): LS-EMPTY = "N".
CHECK-FUNCTION.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-COND) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-COND)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "FUNCTION"
                MOVE "N" TO LS-EMPTY
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM.

REPORT-EMPTY.
    MOVE SPACES TO LS-MESSAGE
    STRING "this " DELIMITED BY SIZE
           ND-DETAIL(LS-NODE) DELIMITED BY SPACE
           " does nothing: every branch is CONTINUE or empty"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-NODE) LS-MESSAGE.
END PROGRAM PLB-RULE-M021.
