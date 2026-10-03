*> ---------------------------------------------------------------
*> plbrcmp: PLB-C056 self-comparison.
*>
*> A relation condition whose two sides are the same data item, written
*> the same way:
*>
*>     IF WS-OLD-BALANCE NOT = WS-OLD-BALANCE      *> always false
*>         PERFORM 300-POST-CHANGE
*>     END-IF
*>
*> The condition is the same every time (true for =, >=, and <=, false
*> for <, >, and NOT =), so a branch never runs, or a loop never ends or
*> never starts. It is most often a copy of the line above with one
*> name left unchanged.
*>
*> The sides must be the whole operands: X + 1 > X is not reported.
*> They match when their tokens are the same, case aside, subscripts
*> and reference modifiers included; X(I) = X(J) is not reported. The
*> = of COMPUTE, which stores, is not a condition.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C056.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-INSIDE               PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-OTHER                PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-OTHER-LEN            PIC 9(9) COMP-5.
*> The operator between the two sides, as words: "=" "<" ">" "<=" ">="
*> "<>" with NOT before it when it is negated.
01  LS-OP                   PIC X(2).
01  LS-NOT                  PIC X.
01  LS-VALID                PIC X.
01  LS-SAME                 PIC X.
01  LS-ALWAYS               PIC X(5).
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C056" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0 OR RF-COUNT < 2
        GOBACK
    END-IF
    *> Each reference with the next one of the same statement that is
    *> not inside its subscripts.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R >= RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-STMT(LS-R) > 0
            PERFORM NEXT-SIDE
            IF LS-S > 0
                PERFORM CHECK-PAIR
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> LS-S: the first reference after LS-R's last token, in the same
*> statement, or 0.
NEXT-SIDE.
    MOVE 0 TO LS-S
    PERFORM VARYING LS-Q FROM LS-R BY 1 UNTIL LS-Q >= RF-COUNT
        IF RF-TOKEN(LS-Q + 1) > RF-LAST(LS-R)
            COMPUTE LS-S = LS-Q + 1
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-S > 0
        IF RF-STMT(LS-S) NOT = RF-STMT(LS-R) OR RF-KIND(LS-S) NOT = "D"
            MOVE 0 TO LS-S
        END-IF
    END-IF.

CHECK-PAIR.
    IF ND-DETAIL(RF-STMT(LS-R)) = "COMPUTE"
        EXIT PARAGRAPH
    END-IF
    *> Inside a subscript of another reference: the subscript's own
    *> comparison is not a condition.
    MOVE "N" TO LS-INSIDE
    PERFORM VARYING LS-Q FROM LS-R BY -1 UNTIL LS-Q < 1
        IF RF-STMT(LS-Q) NOT = RF-STMT(LS-R)
            EXIT PERFORM
        END-IF
        IF LS-Q < LS-R AND RF-LAST(LS-Q) >= RF-TOKEN(LS-R)
            MOVE "Y" TO LS-INSIDE
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-INSIDE = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-OPERATOR
    IF LS-VALID = "N"
        EXIT PARAGRAPH
    END-IF
    PERFORM WHOLE-OPERANDS
    IF LS-VALID = "N"
        EXIT PARAGRAPH
    END-IF
    PERFORM COMPARE-SIDES
    IF LS-SAME = "Y"
        PERFORM REPORT-SELF
    END-IF.

*> The tokens between the two sides: [IS] [NOT] and one of = < > <=
*> >= <>, EQUAL [TO], GREATER [THAN] [OR EQUAL [TO]], LESS [THAN] [OR
*> EQUAL [TO]]. LS-VALID = "N" when they are anything else.
READ-OPERATOR.
    MOVE "N" TO LS-VALID LS-NOT
    MOVE SPACES TO LS-OP
    COMPUTE LS-T = RF-LAST(LS-R) + 1
    PERFORM WORD-AT
    IF LS-TEXT = "IS"
        ADD 1 TO LS-T
        PERFORM WORD-AT
    END-IF
    IF LS-TEXT = "NOT"
        MOVE "Y" TO LS-NOT
        ADD 1 TO LS-T
        PERFORM WORD-AT
    END-IF
    EVALUATE LS-TEXT
        WHEN "=" WHEN "<" WHEN ">" WHEN "<=" WHEN ">=" WHEN "<>"
            MOVE LS-TEXT TO LS-OP
            ADD 1 TO LS-T
        WHEN "EQUAL"
            MOVE "=" TO LS-OP
            ADD 1 TO LS-T
            PERFORM SKIP-TO
        WHEN "GREATER"
            MOVE ">" TO LS-OP
            PERFORM OR-EQUAL
        WHEN "LESS"
            MOVE "<" TO LS-OP
            PERFORM OR-EQUAL
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    IF LS-T = RF-TOKEN(LS-S)
        MOVE "Y" TO LS-VALID
    END-IF.

*> GREATER or LESS at LS-T: [THAN] [OR EQUAL [TO]].
OR-EQUAL.
    ADD 1 TO LS-T
    PERFORM WORD-AT
    IF LS-TEXT = "THAN"
        ADD 1 TO LS-T
        PERFORM WORD-AT
    END-IF
    IF LS-TEXT = "OR"
        ADD 1 TO LS-T
        PERFORM WORD-AT
        IF LS-TEXT NOT = "EQUAL"
            *> X > OR ... is not this operator.
            MOVE 0 TO LS-T
            EXIT PARAGRAPH
        END-IF
        MOVE "=" TO LS-OP(2:1)
        ADD 1 TO LS-T
        PERFORM SKIP-TO
    END-IF.

SKIP-TO.
    PERFORM WORD-AT
    IF LS-TEXT = "TO"
        ADD 1 TO LS-T
    END-IF.

*> LS-TEXT: token LS-T in upper case (spaces past the statement).
WORD-AT.
    MOVE SPACES TO LS-TEXT
    IF LS-T >= RF-TOKEN(LS-S) OR LS-T > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT.

*> Neither side is part of an arithmetic expression: no operator
*> before the first or after the second.
WHOLE-OPERANDS.
    MOVE "N" TO LS-VALID
    COMPUTE LS-T = RF-TOKEN(LS-R) - 1
    IF LS-T > 0
        IF TK-IS-OPERATOR(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "+" OR "-" OR "*" OR "/" OR "**"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-IF
    COMPUTE LS-T = RF-LAST(LS-S) + 1
    IF LS-T <= TK-COUNT
        IF TK-IS-OPERATOR(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "+" OR "-" OR "*" OR "/" OR "**"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-IF
    MOVE "Y" TO LS-VALID.

*> LS-SAME = "Y" when both sides have the same tokens.
COMPARE-SIDES.
    MOVE "N" TO LS-SAME
    IF RF-SYMBOL(LS-R) NOT = RF-SYMBOL(LS-S)
       OR RF-LAST(LS-R) - RF-TOKEN(LS-R) NOT =
          RF-LAST(LS-S) - RF-TOKEN(LS-S)
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM RF-TOKEN(LS-R) BY 1
            UNTIL LS-T > RF-LAST(LS-R)
        COMPUTE LS-U = RF-TOKEN(LS-S) + LS-T - RF-TOKEN(LS-R)
        IF TK-KIND(LS-T) NOT = TK-KIND(LS-U)
            EXIT PARAGRAPH
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-U LS-OTHER LS-OTHER-LEN
        IF FUNCTION UPPER-CASE(LS-TEXT) NOT =
           FUNCTION UPPER-CASE(LS-OTHER)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    MOVE "Y" TO LS-SAME.

REPORT-SELF.
    *> = <= >= hold of any value with itself; < > <> never do.
    IF LS-OP = "=" OR LS-OP = "<=" OR LS-OP = ">="
        MOVE "true" TO LS-ALWAYS
    ELSE
        MOVE "false" TO LS-ALWAYS
    END-IF
    IF LS-NOT = "Y"
        IF LS-ALWAYS = "true"
            MOVE "false" TO LS-ALWAYS
        ELSE
            MOVE "true" TO LS-ALWAYS
        END-IF
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(RF-SYMBOL(LS-R)) DELIMITED BY SPACE
           " is compared with itself: the condition is always "
           DELIMITED BY SIZE
           LS-ALWAYS DELIMITED BY SPACE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-S) LS-MESSAGE.
END PROGRAM PLB-RULE-C056.
