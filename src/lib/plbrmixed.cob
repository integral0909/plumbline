*> ---------------------------------------------------------------
*> plbrmixed: PLB-M022 mixed-and-or.
*>
*> A condition that joins relations with both AND and OR at one level
*> of parentheses:
*>
*>     IF WS-TYPE = "A" OR WS-TYPE = "B" AND WS-AMOUNT > 0
*>
*> AND binds tighter than OR, so this is WS-TYPE = "A" OR (WS-TYPE =
*> "B" AND WS-AMOUNT > 0), and an "A" passes with any amount; a reader
*> takes it either way. Parentheses say which is meant. The OR of
*> GREATER OR EQUAL and LESS OR EQUAL is no join; ALSO, and the UNTIL,
*> AFTER, and VARYING of a PERFORM, start another condition.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-M022.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  DEPTH-MAX               VALUE 32.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC 9(4) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> For each level of parentheses: whether it has an AND, an OR.
01  LS-HAS-AND              PIC X OCCURS DEPTH-MAX TIMES.
01  LS-HAS-OR               PIC X OCCURS DEPTH-MAX TIMES.
01  LS-REPORTED             PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M022" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "COND"
            PERFORM CHECK-CONDITION
        END-IF
    END-PERFORM
    GOBACK.

*> The tokens of condition LS-NODE, a level of parentheses at a time.
CHECK-CONDITION.
    MOVE "N" TO LS-REPORTED
    MOVE 1 TO LS-DEPTH
    PERFORM CLEAR-LEVELS
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE) OR LS-REPORTED = "Y"
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                IF LS-DEPTH >= DEPTH-MAX
                    EXIT PARAGRAPH
                END-IF
                ADD 1 TO LS-DEPTH
                MOVE "N" TO LS-HAS-AND(LS-DEPTH) LS-HAS-OR(LS-DEPTH)
            WHEN TK-IS-RPAREN(LS-T)
                PERFORM TEST-LEVEL
                IF LS-DEPTH > 1
                    SUBTRACT 1 FROM LS-DEPTH
                END-IF
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
                EVALUATE LS-WORD
                    WHEN "AND"
                        MOVE "Y" TO LS-HAS-AND(LS-DEPTH)
                    WHEN "OR"
                        PERFORM NOTE-OR
                    WHEN "ALSO" WHEN "UNTIL" WHEN "AFTER" WHEN "VARYING"
                        PERFORM TEST-LEVEL
                        MOVE 1 TO LS-DEPTH
                        PERFORM CLEAR-LEVELS
                END-EVALUATE
        END-EVALUATE
    END-PERFORM
    IF LS-REPORTED = "N"
        PERFORM TEST-LEVEL
    END-IF.

*> OR, unless of GREATER OR EQUAL or LESS OR EQUAL.
NOTE-OR.
    COMPUTE LS-NEXT = LS-T + 1
    IF LS-NEXT <= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-NEXT)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-NEXT LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "EQUAL"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-IF
    MOVE "Y" TO LS-HAS-OR(LS-DEPTH).

CLEAR-LEVELS.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DEPTH-MAX
        MOVE "N" TO LS-HAS-AND(LS-I) LS-HAS-OR(LS-I)
    END-PERFORM.

*> The level at LS-DEPTH, as it ends: both joins, reported once.
TEST-LEVEL.
    IF LS-HAS-AND(LS-DEPTH) = "Y" AND LS-HAS-OR(LS-DEPTH) = "Y"
       AND LS-REPORTED = "N"
        MOVE "Y" TO LS-REPORTED
        MOVE SPACES TO LS-MESSAGE
        STRING "this condition joins with both AND and OR without "
               "parentheses: AND is done first (A OR B AND C is A OR "
               "(B AND C)); parentheses say which is meant"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-NODE)
            LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-M022.
