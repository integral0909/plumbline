*> ---------------------------------------------------------------
*> plbrarith: rules about arithmetic statements.
*>
*>   PLB-C036  arithmetic-overflow
*> ---------------------------------------------------------------

*> PLB-C036 arithmetic-overflow: ADD, SUBTRACT, or MULTIPLY without ON
*> SIZE ERROR whose receiver has fewer integer digits than one of its
*> operands. A result that does not fit loses its high-order digits
*> without a word, as a MOVE would (PLB-C008), but here the values come
*> from the run, so nothing shows the loss until a total is wrong.
*>
*> The operands are the identifiers and numeric literals before TO,
*> FROM, or BY, and with GIVING also the one after them; the receivers
*> are those after TO, FROM, or BY, or after GIVING. COMPUTE and DIVIDE
*> are not checked: a quotient is commonly much smaller than its
*> dividend. Neither are CORRESPONDING forms, reference-modified items,
*> or items of unknown size.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C036.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-LEVEL                PIC S9(4) COMP-5.
01  LS-WORD                 PIC X(40).
01  LS-LEN                  PIC 9(9) COMP-5.
*> The token of GIVING, and of TO, FROM, or BY (0: none).
01  LS-GIVING               PIC 9(9) COMP-5.
01  LS-JOIN                 PIC 9(9) COMP-5.
01  LS-SKIP                 PIC X.
*> The widest operand: its integer digits and its token.
01  LS-WIDE-INT             PIC S9(9) COMP-5.
01  LS-WIDE-TOKEN           PIC 9(9) COMP-5.
01  LS-INT                  PIC S9(9) COMP-5.
01  LS-RECV                 PIC 9(9) COMP-5.
01  LS-RECV-INT             PIC S9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-DIGITS-SEEN          PIC X.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-A-TEXT               PIC X(20).
01  LS-A-LEN                PIC 9(9) COMP-5.
01  LS-B-TEXT               PIC X(20).
01  LS-B-LEN                PIC 9(9) COMP-5.
01  LS-WIDE-NAME            PIC X(40).
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C036" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
           AND (ND-DETAIL(LS-NODE) = "ADD" OR "SUBTRACT" OR "MULTIPLY")
            PERFORM CHECK-STATEMENT
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

CHECK-STATEMENT.
    PERFORM FIND-KEYWORDS
    IF LS-SKIP = "Y" OR (LS-JOIN = 0 AND LS-GIVING = 0)
        EXIT PARAGRAPH
    END-IF
    *> The widest operand.
    MOVE 0 TO LS-WIDE-INT LS-WIDE-TOKEN LS-LEVEL
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL > 0 OR LS-T = ND-TOK-FIRST(LS-NODE)
                CONTINUE
            WHEN LS-T = LS-GIVING
                EXIT PERFORM
            WHEN LS-T > LS-JOIN AND LS-GIVING = 0
                EXIT PERFORM
            WHEN OTHER
                PERFORM OPERAND-DIGITS
                IF LS-INT > LS-WIDE-INT
                    MOVE LS-INT TO LS-WIDE-INT
                    MOVE LS-T TO LS-WIDE-TOKEN
                END-IF
        END-EVALUATE
    END-PERFORM
    IF LS-WIDE-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    *> Each receiver.
    MOVE 0 TO LS-LEVEL
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL > 0
                CONTINUE
            WHEN (LS-GIVING > 0 AND LS-T > LS-GIVING)
              OR (LS-GIVING = 0 AND LS-T > LS-JOIN)
                IF WS-TOKEN-REF(LS-T) > 0
                    PERFORM CHECK-RECEIVER
                END-IF
        END-EVALUATE
    END-PERFORM.

*> LS-JOIN: TO, FROM, or BY; LS-GIVING: GIVING; LS-SKIP = "Y" for the
*> CORRESPONDING forms and those with SIZE ERROR phrases. Only words
*> outside parentheses count.
FIND-KEYWORDS.
    MOVE 0 TO LS-JOIN LS-GIVING LS-LEVEL
    MOVE "N" TO LS-SKIP
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL = 0 AND TK-IS-WORD(LS-T)
             AND WS-TOKEN-REF(LS-T) = 0
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                    WHEN "TO"
                    WHEN "FROM"
                    WHEN "BY"
                        IF LS-JOIN = 0
                            MOVE LS-T TO LS-JOIN
                        END-IF
                    WHEN "GIVING"
                        MOVE LS-T TO LS-GIVING
                    WHEN "CORRESPONDING"
                    WHEN "CORR"
                    WHEN "SIZE"
                        MOVE "Y" TO LS-SKIP
                END-EVALUATE
        END-EVALUATE
    END-PERFORM.

*> LS-INT: the integer digits of the operand at LS-T, or 0 when it is
*> not a numeric literal or a numeric item of known size.
OPERAND-DIGITS.
    MOVE 0 TO LS-INT
    EVALUATE TRUE
        WHEN TK-IS-NUMBER(LS-T)
            PERFORM LITERAL-INTEGER-DIGITS
        WHEN WS-TOKEN-REF(LS-T) > 0
            MOVE WS-TOKEN-REF(LS-T) TO LS-R
            IF RF-KIND(LS-R) = "D" AND RF-REFMOD(LS-R) = "N"
                MOVE RF-SYMBOL(LS-R) TO LS-RECV
                IF SY-CATEGORY(LS-RECV) = "9" AND SY-SIZE(LS-RECV) > 0
                    COMPUTE LS-INT = SY-DIGITS(LS-RECV)
                        - SY-SCALE(LS-RECV)
                END-IF
            END-IF
    END-EVALUATE.

*> Integer digits of a numeric literal, without sign or leading zeros.
*> Floating-point literals count as 0.
LITERAL-INTEGER-DIGITS.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE "N" TO LS-DIGITS-SEEN
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        EVALUATE TRUE
            WHEN LS-WORD(LS-I:1) = "." OR LS-WORD(LS-I:1) = ","
                EXIT PERFORM
            WHEN LS-WORD(LS-I:1) = "E" OR LS-WORD(LS-I:1) = "e"
                MOVE 0 TO LS-INT
                EXIT PERFORM
            WHEN LS-WORD(LS-I:1) >= "1" AND LS-WORD(LS-I:1) <= "9"
                MOVE "Y" TO LS-DIGITS-SEEN
                ADD 1 TO LS-INT
            WHEN LS-WORD(LS-I:1) = "0" AND LS-DIGITS-SEEN = "Y"
                ADD 1 TO LS-INT
        END-EVALUATE
    END-PERFORM.

CHECK-RECEIVER.
    MOVE WS-TOKEN-REF(LS-T) TO LS-R
    IF RF-KIND(LS-R) NOT = "D" OR RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-RECV
    IF SY-SIZE(LS-RECV) = 0
       OR (SY-CATEGORY(LS-RECV) NOT = "9" AND NOT = "E")
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-RECV-INT = SY-DIGITS(LS-RECV) - SY-SCALE(LS-RECV)
    IF LS-WIDE-INT > LS-RECV-INT
        PERFORM REPORT-RECEIVER
    END-IF.

REPORT-RECEIVER.
    MOVE LS-WIDE-INT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE LS-RECV-INT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-WIDE-TOKEN LS-WIDE-NAME
        LS-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING FUNCTION TRIM(ND-DETAIL(LS-NODE)) DELIMITED BY SIZE
           " without ON SIZE ERROR can lose high-order digits: "
           DELIMITED BY SIZE
           LS-WIDE-NAME DELIMITED BY SPACE
           " has " LS-A-TEXT(1:LS-A-LEN) " integer digits, "
           DELIMITED BY SIZE
           SY-NAME(LS-RECV) DELIMITED BY SPACE
           " has " LS-B-TEXT(1:LS-B-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-T LS-MESSAGE.
END PROGRAM PLB-RULE-C036.
