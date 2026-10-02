*> ---------------------------------------------------------------
*> plbrstr: STRING statements that cannot fit their receiver.
*>
*>   PLB-C031  string-overflow
*>
*> An operand DELIMITED BY SIZE is sent whole. When those operands of
*> a STRING are longer together than the receiving item, the
*> statement always overflows: what does not fit is lost, and without
*> ON OVERFLOW nothing says so. Operands delimited by anything else
*> send an unknown part of themselves and are not counted, so the sum
*> is the least the statement sends.
*>
*> Operands whose size is not known from the source (reference
*> modification, functions, literals with a prefix such as X or N)
*> count as nothing. A receiver with reference modification, of
*> variable size, or of national usage is not checked.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-STRINGS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-NEST                 PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> Sizes of the operands since the last DELIMITED phrase, and of all
*> operands delimited by size.
01  LS-PENDING              PIC 9(9) COMP-5.
01  LS-SENT                 PIC 9(9) COMP-5.
01  LS-TARGET-REF           PIC 9(9) COMP-5.
01  LS-TARGET               PIC 9(9) COMP-5.
01  LS-TOKEN                PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-SENT-TEXT            PIC X(20).
01  LS-SENT-LEN             PIC 9(9) COMP-5.
01  LS-SIZE-TEXT            PIC X(20).
01  LS-SIZE-LEN             PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C031" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0 OR RF-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "STRING"
            PERFORM CHECK-STRING
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

CHECK-STRING.
    *> ON OVERFLOW handles what does not fit; the phrases start the
    *> part of the statement after its operands.
    MOVE ND-TOK-LAST(LS-NODE) TO LS-LAST
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            IF ND-DETAIL(LS-CHILD) = "OVERFLOW"
                EXIT PARAGRAPH
            END-IF
            IF ND-TOK-FIRST(LS-CHILD) - 1 < LS-LAST
                COMPUTE LS-LAST = ND-TOK-FIRST(LS-CHILD) - 1
            END-IF
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    PERFORM FIRST-REF
    MOVE 0 TO LS-PENDING LS-SENT LS-TARGET-REF
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM UNTIL LS-T > LS-LAST
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        EVALUATE TRUE
            WHEN TK-IS-WORD(LS-T) AND LS-WORD = "INTO"
                PERFORM READ-TARGET
                EXIT PERFORM
            WHEN TK-IS-WORD(LS-T) AND LS-WORD = "DELIMITED"
                PERFORM READ-DELIMITER
            WHEN OTHER
                PERFORM READ-OPERAND
        END-EVALUATE
    END-PERFORM
    IF LS-TARGET-REF = 0
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-TARGET-REF) TO LS-TARGET
    IF LS-SENT > SY-SIZE(LS-TARGET) AND SY-SIZE(LS-TARGET) > 0
        PERFORM REPORT-OVERFLOW
    END-IF.

*> LS-R = the first reference at or after the first token of LS-NODE.
FIRST-REF.
    MOVE 1 TO LS-R
    MOVE RF-COUNT TO LS-K
    PERFORM UNTIL LS-R >= LS-K
        COMPUTE LS-U = (LS-R + LS-K) / 2
        IF RF-TOKEN(LS-U) < ND-TOK-FIRST(LS-NODE)
            COMPUTE LS-R = LS-U + 1
        ELSE
            MOVE LS-U TO LS-K
        END-IF
    END-PERFORM.

*> DELIMITED [BY] SIZE adds the pending operands to what is sent;
*> another delimiter drops them. LS-T is left after the delimiter.
READ-DELIMITER.
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF TK-IS-WORD(LS-T) AND LS-WORD = "BY"
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    END-IF
    IF TK-IS-WORD(LS-T) AND LS-WORD = "SIZE"
        ADD LS-PENDING TO LS-SENT
        ADD 1 TO LS-T
    ELSE
        *> The delimiter is an operand of its own: skip it.
        PERFORM SKIP-OPERAND
    END-IF
    MOVE 0 TO LS-PENDING.

*> An operand to send: its size goes to LS-PENDING.
READ-OPERAND.
    PERFORM REF-AT-T
    IF LS-K > 0
        IF RF-KIND(LS-K) = "D" AND RF-REFMOD(LS-K) = "N"
            IF SY-VARIABLE(RF-SYMBOL(LS-K)) NOT = "Y"
                ADD SY-SIZE(RF-SYMBOL(LS-K)) TO LS-PENDING
            END-IF
        END-IF
        COMPUTE LS-T = RF-LAST(LS-K) + 1
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-T)
            IF TK-PREFIX(LS-T) = SPACES
                ADD TK-TEXT-LEN(LS-T) TO LS-PENDING
            END-IF
        WHEN TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE LS-WORD
                WHEN "SPACE" WHEN "SPACES" WHEN "ZERO" WHEN "ZEROS"
                WHEN "ZEROES" WHEN "QUOTE" WHEN "QUOTES"
                WHEN "LOW-VALUE" WHEN "LOW-VALUES" WHEN "HIGH-VALUE"
                WHEN "HIGH-VALUES"
                    ADD 1 TO LS-PENDING
                WHEN "FUNCTION"
                    *> FUNCTION name [(arguments)]: size unknown.
                    ADD 1 TO LS-T
                    PERFORM SKIP-PARENTHESES
            END-EVALUATE
    END-EVALUATE
    ADD 1 TO LS-T.

*> Past the operand at LS-T: a reference, or one token.
SKIP-OPERAND.
    PERFORM REF-AT-T
    IF LS-K > 0
        COMPUTE LS-T = RF-LAST(LS-K) + 1
    ELSE
        ADD 1 TO LS-T
    END-IF.

*> When the token after LS-T opens parentheses, LS-T moves to the
*> token that closes them.
SKIP-PARENTHESES.
    COMPUTE LS-U = LS-T + 1
    IF LS-U > LS-LAST
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-LPAREN(LS-U)
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-NEST
    PERFORM VARYING LS-T FROM LS-U BY 1 UNTIL LS-T > LS-LAST
        IF TK-IS-LPAREN(LS-T)
            ADD 1 TO LS-NEST
        END-IF
        IF TK-IS-RPAREN(LS-T)
            SUBTRACT 1 FROM LS-NEST
            IF LS-NEST = 0
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> LS-K = the reference that starts at token LS-T, or 0.
REF-AT-T.
    MOVE 0 TO LS-K
    PERFORM UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) >= LS-T
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-R
    END-PERFORM
    IF LS-R <= RF-COUNT
        IF RF-TOKEN(LS-R) = LS-T
            MOVE LS-R TO LS-K
        END-IF
    END-IF.

*> The receiver after INTO, when the rule can judge its size.
READ-TARGET.
    ADD 1 TO LS-T
    PERFORM REF-AT-T
    IF LS-K = 0
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-K) NOT = "D" OR RF-REFMOD(LS-K) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-K) TO LS-U
    IF SY-VARIABLE(LS-U) = "Y" OR SY-CATEGORY(LS-U) = "N"
       OR SY-USAGE(LS-U) = "NATIONAL"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-K TO LS-TARGET-REF.

REPORT-OVERFLOW.
    MOVE LS-SENT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-SENT-TEXT LS-SENT-LEN
    MOVE SY-SIZE(LS-TARGET) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-SIZE-TEXT LS-SIZE-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "STRING sends at least " DELIMITED BY SIZE
           LS-SENT-TEXT(1:LS-SENT-LEN) DELIMITED BY SIZE
           " characters into " DELIMITED BY SIZE
           SY-NAME(LS-TARGET) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
           LS-SIZE-TEXT(1:LS-SIZE-LEN) DELIMITED BY SIZE
           "), so the rest is lost" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE RF-TOKEN(LS-TARGET-REF) TO LS-TOKEN
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-STRINGS.
