*> ---------------------------------------------------------------
*> plbrstmt: rules that look at individual statements.
*>
*>   PLB-C004  next-sentence-in-scope
*>   PLB-C027  divide-by-zero
*>   PLB-C032  duplicate-when
*>   PLB-C033  self-move
*>   PLB-M001  go-to
*>   PLB-M002  alter
*>   PLB-M011  evaluate-without-other
*>
*> One walk of the syntax tree dispatches each statement to the rules
*> that care about its verb.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-STATEMENTS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE-NEXT-SENTENCE   PIC 9(4) COMP-5.
01  LS-RULE-GO-TO           PIC 9(4) COMP-5.
01  LS-RULE-ALTER           PIC 9(4) COMP-5.
01  LS-RULE-NO-OTHER        PIC 9(4) COMP-5.
01  LS-RULE-DIVIDE-ZERO     PIC 9(4) COMP-5.
01  LS-RULE-DUPLICATE-WHEN  PIC 9(4) COMP-5.
01  LS-RULE-SELF-MOVE       PIC 9(4) COMP-5.
*> The WHEN conditions of one EVALUATE, as text.
01  LS-WHEN-COUNT           PIC 9(4) COMP-5.
01  LS-WHEN-TEXT            PIC X(200) OCCURS 200 TIMES.
01  LS-WHEN-LINE            PIC 9(9) COMP-5 OCCURS 200 TIMES.
01  LS-COND-TEXT            PIC X(200).
01  LS-COND-PTR             PIC 9(9) COMP-5.
01  LS-COND-NODE            PIC 9(9) COMP-5.
01  LS-W                    PIC 9(4) COMP-5.
01  LS-SOURCE               PIC X(31).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NEXT-CHILD-TOK       PIC 9(9) COMP-5.
01  LS-ZERO                 PIC X.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-DIGITS               PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C004"
        LS-RULE-NEXT-SENTENCE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M001" LS-RULE-GO-TO
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M002" LS-RULE-ALTER
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M011" LS-RULE-NO-OTHER
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C027" LS-RULE-DIVIDE-ZERO
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C032"
        LS-RULE-DUPLICATE-WHEN
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C033" LS-RULE-SELF-MOVE
    IF AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
            EVALUATE ND-DETAIL(LS-NODE)
                WHEN "NEXT SENTENCE"
                    PERFORM CHECK-NEXT-SENTENCE
                WHEN "GO"
                    PERFORM REPORT-GO-TO
                WHEN "ALTER"
                    PERFORM REPORT-ALTER
                WHEN "EVALUATE"
                    PERFORM CHECK-WHEN-OTHER
                    PERFORM CHECK-DUPLICATE-WHEN
                WHEN "MOVE"
                    PERFORM CHECK-SELF-MOVE
            END-EVALUATE
            IF ND-DETAIL(LS-NODE) NOT = "EXEC"
                PERFORM CHECK-DIVIDE-BY-ZERO
            END-IF
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> PLB-C004: NEXT SENTENCE continues after the next period, not after
*> the END-IF (or other terminator) of the statement it is in. In code
*> that uses scope terminators that is almost never what was meant;
*> CONTINUE is.
CHECK-NEXT-SENTENCE.
    MOVE ND-PARENT(LS-NODE) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "SENT"
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-UP) = "STMT"
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-TOK-LAST(LS-UP)
                LS-TEXT LS-LEN
            IF LS-TEXT(1:4) = "END-" AND TK-IS-WORD(ND-TOK-LAST(LS-UP))
                MOVE SPACES TO LS-MESSAGE
                STRING "NEXT SENTENCE skips past " DELIMITED BY SIZE
                       LS-TEXT DELIMITED BY SPACE
                       " to the next period; use CONTINUE"
                       DELIMITED BY SIZE
                    INTO LS-MESSAGE
                MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
                CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET
                    PLB-TOKENS PLB-RULES PLB-FINDINGS
                    LS-RULE-NEXT-SENTENCE LS-TOKEN LS-MESSAGE
                EXIT PERFORM
            END-IF
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> PLB-M001: GO TO makes the flow of control hard to follow; PERFORM
*> and structured statements are usually clearer.
REPORT-GO-TO.
    MOVE "GO TO makes the flow of control hard to follow"
        TO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-GO-TO LS-TOKEN LS-MESSAGE.

*> PLB-M002: ALTER changes the target of a GO TO while the program
*> runs, so the code no longer says where control goes. It was
*> removed from the standard in 2002.
REPORT-ALTER.
    MOVE "ALTER changes GO TO targets at run time and is obsolete"
        TO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-ALTER LS-TOKEN LS-MESSAGE.
*> PLB-M011: an EVALUATE without WHEN OTHER does nothing for a value
*> that no WHEN matches, and says nothing about it either. Shops that
*> want every EVALUATE to say what happens then turn this rule on.
CHECK-WHEN-OTHER.
    IF RL-ENABLED(LS-RULE-NO-OTHER) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "WHEN-OTHER"
            EXIT PARAGRAPH
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    MOVE "EVALUATE has no WHEN OTHER for values no WHEN matches"
        TO LS-MESSAGE
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-NO-OTHER LS-TOKEN LS-MESSAGE.

*> PLB-C027: a division whose divisor is a literal zero, in a DIVIDE
*> statement or after / in an expression. The statement's own tokens
*> are scanned: those of the statements under it are scanned when
*> they are visited. A statement with ON SIZE ERROR handles the
*> division failing, and is not reported.
CHECK-DIVIDE-BY-ZERO.
    IF RL-ENABLED(LS-RULE-DIVIDE-ZERO) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
           AND ND-DETAIL(LS-CHILD) = "SIZE-ERROR"
            EXIT PARAGRAPH
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    *> DIVIDE 0 INTO x: the first operand is the divisor.
    IF ND-DETAIL(LS-NODE) = "DIVIDE"
        COMPUTE LS-TOKEN = ND-TOK-FIRST(LS-NODE) + 1
        PERFORM TEST-ZERO
        IF LS-ZERO = "Y" AND LS-TOKEN < ND-TOK-LAST(LS-NODE)
            COMPUTE LS-T = LS-TOKEN + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "INTO"
                PERFORM REPORT-DIVIDE-BY-ZERO
            END-IF
        END-IF
    END-IF
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM NEXT-OWN-CHILD
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF LS-T = LS-NEXT-CHILD-TOK
            *> Skip the statements and phrases under this one.
            *> plumbline: ignore varying-control-changed -- skips the statements under this one
            MOVE ND-TOK-LAST(LS-CHILD) TO LS-T
            MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
            PERFORM NEXT-OWN-CHILD
        ELSE
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF (TK-IS-OPERATOR(LS-T) AND LS-TEXT = "/")
               OR (ND-DETAIL(LS-NODE) = "DIVIDE" AND LS-TEXT = "BY"
                   AND TK-IS-WORD(LS-T))
                COMPUTE LS-TOKEN = LS-T + 1
                PERFORM TEST-ZERO
                IF LS-ZERO = "Y"
                    PERFORM REPORT-DIVIDE-BY-ZERO
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> LS-CHILD = the next child, from LS-CHILD on, that is a statement or
*> a block of them; LS-NEXT-CHILD-TOK = its first token, or 0.
NEXT-OWN-CHILD.
    MOVE 0 TO LS-NEXT-CHILD-TOK
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "STMT" OR ND-KIND(LS-CHILD) = "BLCK"
            MOVE ND-TOK-FIRST(LS-CHILD) TO LS-NEXT-CHILD-TOK
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

*> LS-ZERO = "Y" when token LS-TOKEN is a numeric literal whose value
*> is zero, or ZERO, ZEROS, or ZEROES.
TEST-ZERO.
    MOVE "N" TO LS-ZERO
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT LS-LEN
    IF TK-IS-WORD(LS-TOKEN)
        IF LS-TEXT = "ZERO" OR "ZEROS" OR "ZEROES"
            MOVE "Y" TO LS-ZERO
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-NUMBER(LS-TOKEN) OR LS-LEN > 31
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-DIGITS
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > LS-LEN
        EVALUATE LS-TEXT(LS-C:1)
            WHEN "0"
                ADD 1 TO LS-DIGITS
            WHEN "+"
            WHEN "-"
            WHEN "."
            WHEN ","
                CONTINUE
            WHEN OTHER
                EXIT PARAGRAPH
        END-EVALUATE
    END-PERFORM
    IF LS-DIGITS > 0
        MOVE "Y" TO LS-ZERO
    END-IF.

REPORT-DIVIDE-BY-ZERO.
    MOVE "division by zero; the statement fails when it runs"
        TO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-DIVIDE-ZERO LS-TOKEN LS-MESSAGE.

*> PLB-C032: a WHEN of an EVALUATE that tests what an earlier WHEN of
*> the same EVALUATE already tests (the same words and literals, ALSO
*> parts included). EVALUATE takes the first WHEN that matches, so the
*> later one never runs. WHEN ANY and WHEN OTHER are left out.
CHECK-DUPLICATE-WHEN.
    IF RL-ENABLED(LS-RULE-DUPLICATE-WHEN) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-WHEN-COUNT
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "WHEN"
            MOVE ND-FIRST(LS-CHILD) TO LS-COND-NODE
            IF LS-COND-NODE > 0
                IF ND-KIND(LS-COND-NODE) = "COND"
                    PERFORM CONDITION-TEXT
                    IF LS-COND-TEXT NOT = SPACES
                        PERFORM COMPARE-WHEN
                    END-IF
                END-IF
            END-IF
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

*> LS-COND-TEXT = the tokens of condition LS-COND-NODE, one space
*> between; spaces when it is too long to compare or is ANY.
CONDITION-TEXT.
    MOVE SPACES TO LS-COND-TEXT
    MOVE 1 TO LS-COND-PTR
    PERFORM VARYING LS-TOKEN FROM ND-TOK-FIRST(LS-COND-NODE) BY 1
            UNTIL LS-TOKEN > ND-TOK-LAST(LS-COND-NODE)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-TEXT LS-LEN
        IF LS-LEN > 31 OR LS-COND-PTR + LS-LEN + 2 > 200
            MOVE SPACES TO LS-COND-TEXT
            EXIT PARAGRAPH
        END-IF
        IF TK-IS-ALNUM(LS-TOKEN)
            STRING '"' DELIMITED BY SIZE
                   LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
                   '"' DELIMITED BY SIZE
                INTO LS-COND-TEXT WITH POINTER LS-COND-PTR
        ELSE
            IF LS-LEN > 0
                STRING LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
                    INTO LS-COND-TEXT WITH POINTER LS-COND-PTR
            END-IF
        END-IF
        STRING " " DELIMITED BY SIZE
            INTO LS-COND-TEXT WITH POINTER LS-COND-PTR
    END-PERFORM
    IF LS-COND-TEXT = "ANY "
        MOVE SPACES TO LS-COND-TEXT
    END-IF.

*> Report LS-COND-TEXT when an earlier WHEN has it; keep it.
COMPARE-WHEN.
    PERFORM VARYING LS-W FROM 1 BY 1 UNTIL LS-W > LS-WHEN-COUNT
        IF LS-WHEN-TEXT(LS-W) = LS-COND-TEXT
            MOVE LS-WHEN-LINE(LS-W) TO LS-NUM
            CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
            MOVE SPACES TO LS-MESSAGE
            STRING "this WHEN repeats the one on line " DELIMITED BY SIZE
                   LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
                   ", which EVALUATE chooses first; it never runs"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            MOVE ND-TOK-FIRST(LS-COND-NODE) TO LS-TOKEN
            CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-RULES PLB-FINDINGS LS-RULE-DUPLICATE-WHEN LS-TOKEN
                LS-MESSAGE
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF LS-WHEN-COUNT < 200
        ADD 1 TO LS-WHEN-COUNT
        MOVE LS-COND-TEXT TO LS-WHEN-TEXT(LS-WHEN-COUNT)
        MOVE ND-TOK-FIRST(LS-COND-NODE) TO LS-TOKEN
        MOVE 0 TO LS-WHEN-LINE(LS-WHEN-COUNT)
        IF TK-SRC-LINE(LS-TOKEN) > 0
            MOVE SL-LINE-NO(TK-SRC-LINE(LS-TOKEN))
                TO LS-WHEN-LINE(LS-WHEN-COUNT)
        END-IF
    END-IF.

*> PLB-C033: MOVE X TO ... X, with X a name on its own (no
*> qualification, subscript, or reference modification) on both
*> sides. The MOVE does nothing; usually another item was meant.
CHECK-SELF-MOVE.
    IF RL-ENABLED(LS-RULE-SELF-MOVE) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-TOKEN = ND-TOK-FIRST(LS-NODE) + 1
    IF NOT TK-IS-WORD(LS-TOKEN)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-TOKEN LS-SOURCE LS-LEN
    IF TK-KEYWORD(LS-TOKEN) NOT = SPACE
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-UP = LS-TOKEN + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-UP LS-TEXT LS-LEN
    IF LS-TEXT NOT = "TO"
        EXIT PARAGRAPH
    END-IF
    *> Receivers only: not names inside a receiver's subscripts or
    *> reference modification.
    MOVE 0 TO LS-W
    PERFORM VARYING LS-UP FROM LS-UP BY 1
            UNTIL LS-UP > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-UP)
                ADD 1 TO LS-W
            WHEN TK-IS-RPAREN(LS-UP) AND LS-W > 0
                SUBTRACT 1 FROM LS-W
            WHEN TK-IS-WORD(LS-UP) AND LS-W = 0
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-UP LS-TEXT LS-LEN
                IF LS-TEXT = LS-SOURCE
                    PERFORM TEST-PLAIN-RECEIVER
                END-IF
        END-EVALUATE
    END-PERFORM.

*> The receiver at LS-UP stands alone: not qualified, subscripted, or
*> reference-modified.
TEST-PLAIN-RECEIVER.
    COMPUTE LS-CHILD = LS-UP + 1
    IF LS-CHILD <= ND-TOK-LAST(LS-NODE)
        IF TK-IS-LPAREN(LS-CHILD)
            EXIT PARAGRAPH
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-CHILD LS-TEXT LS-LEN
        IF LS-TEXT = "OF" OR LS-TEXT = "IN"
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "MOVE " DELIMITED BY SIZE
           LS-SOURCE DELIMITED BY SPACE
           " TO " DELIMITED BY SIZE
           LS-SOURCE DELIMITED BY SPACE
           " does nothing" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-SELF-MOVE LS-UP LS-MESSAGE.
END PROGRAM PLB-RULE-STATEMENTS.
