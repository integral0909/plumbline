*> ---------------------------------------------------------------
*> plbrnumv: PLB-C061 unchecked-numeric-move.
*>
*> MOVE of an alphanumeric item (or a reference modification, which is
*> alphanumeric) to a numeric item, where nothing in the paragraph tests
*> either with the NUMERIC class condition:
*>
*>     MOVE IN-AMOUNT-X TO WS-AMOUNT                 *> reported
*>     COMPUTE WS-TOTAL = WS-TOTAL + WS-AMOUNT
*>
*> The move copies the characters as they are: spaces or letters in the
*> input become a numeric item that holds no number, and the first
*> arithmetic on it fails on z/OS (a data exception, S0C7) or gives a
*> wrong result elsewhere. IF IN-AMOUNT-X IS NUMERIC before the move,
*> or IF WS-AMOUNT IS NUMERIC after it, anywhere in the paragraph, is
*> taken as the check; so is a test with NOT.
*>
*> Off by default: input checked in another paragraph, or data known to
*> be numeric (a key built from digits), is common.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C061.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-FIRST-REF            PIC 9(9) COMP-5 VALUE 1.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-SEND                 PIC 9(9) COMP-5.
01  LS-SEND-SYM             PIC 9(9) COMP-5.
01  LS-RECV-SYM             PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-PARA                 PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-CHECKED              PIC X.
01  LS-INSIDE               PIC X.
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
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C061" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0 OR RF-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "MOVE"
            PERFORM CHECK-MOVE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> MOVE sender TO receiver...: the sender, an alphanumeric item or a
*> reference modification; each numeric receiver.
CHECK-MOVE.
    PERFORM UNTIL LS-FIRST-REF > RF-COUNT
            OR RF-TOKEN(LS-FIRST-REF) >= ND-TOK-FIRST(LS-NODE)
        ADD 1 TO LS-FIRST-REF
    END-PERFORM
    IF LS-FIRST-REF > RF-COUNT
        EXIT PARAGRAPH
    END-IF
    MOVE LS-FIRST-REF TO LS-SEND
    IF RF-TOKEN(LS-SEND) NOT = ND-TOK-FIRST(LS-NODE) + 1
       OR RF-KIND(LS-SEND) NOT = "D" OR RF-SYMBOL(LS-SEND) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-SEND) TO LS-SEND-SYM
    IF RF-REFMOD(LS-SEND) = "N"
       AND SY-CATEGORY(LS-SEND-SYM) NOT = "X"
       AND SY-CATEGORY(LS-SEND-SYM) NOT = "A"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-R FROM LS-SEND BY 1
            UNTIL LS-R > RF-COUNT
               OR RF-TOKEN(LS-R) > ND-TOK-LAST(LS-NODE)
        IF RF-TOKEN(LS-R) > RF-LAST(LS-SEND) AND RF-KIND(LS-R) = "D"
           AND RF-SYMBOL(LS-R) > 0 AND RF-REFMOD(LS-R) = "N"
           AND RF-ROLE(LS-R) = "D"
            PERFORM TEST-INSIDE
            IF LS-INSIDE = "N"
                MOVE RF-SYMBOL(LS-R) TO LS-RECV-SYM
                IF SY-CATEGORY(LS-RECV-SYM) = "9"
                    PERFORM CHECK-PAIR
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> LS-INSIDE = "Y" when reference LS-R is in the subscripts of another.
TEST-INSIDE.
    MOVE "N" TO LS-INSIDE
    PERFORM VARYING LS-I FROM LS-SEND BY 1 UNTIL LS-I >= LS-R
        IF RF-TOKEN(LS-I) < RF-TOKEN(LS-R)
           AND RF-LAST(LS-I) >= RF-TOKEN(LS-R)
            MOVE "Y" TO LS-INSIDE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Is the sender or the receiver tested with NUMERIC in the paragraph?
CHECK-PAIR.
    MOVE ND-PARENT(LS-NODE) TO LS-PARA
    PERFORM UNTIL LS-PARA = 0
        IF ND-KIND(LS-PARA) = "PARA" OR ND-KIND(LS-PARA) = "SECT"
           OR ND-KIND(LS-PARA) = "PROG"
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-PARA) TO LS-PARA
    END-PERFORM
    IF LS-PARA = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-CHECKED
    PERFORM VARYING LS-I FROM 1 BY 1
            UNTIL LS-I > RF-COUNT OR LS-CHECKED = "Y"
        IF RF-TOKEN(LS-I) > ND-TOK-LAST(LS-PARA)
            EXIT PERFORM
        END-IF
        IF RF-TOKEN(LS-I) >= ND-TOK-FIRST(LS-PARA)
           AND RF-KIND(LS-I) = "D"
           AND (RF-SYMBOL(LS-I) = LS-SEND-SYM
                OR RF-SYMBOL(LS-I) = LS-RECV-SYM)
            PERFORM TEST-NUMERIC-AFTER
        END-IF
    END-PERFORM
    IF LS-CHECKED = "N"
        PERFORM REPORT-MOVE
    END-IF.

*> The reference LS-I is followed by [IS] [NOT] NUMERIC.
TEST-NUMERIC-AFTER.
    COMPUTE LS-K = RF-LAST(LS-I) + 1
    PERFORM 3 TIMES
        IF LS-K > TK-COUNT
            EXIT PERFORM
        END-IF
        IF NOT TK-IS-WORD(LS-K)
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
        EVALUATE LS-TEXT
            WHEN "NUMERIC"
                MOVE "Y" TO LS-CHECKED
                EXIT PERFORM
            WHEN "IS" WHEN "NOT"
                ADD 1 TO LS-K
            WHEN OTHER
                EXIT PERFORM
        END-EVALUATE
    END-PERFORM.

REPORT-MOVE.
    MOVE SPACES TO LS-MESSAGE
    STRING "MOVE of alphanumeric " DELIMITED BY SIZE
           SY-NAME(LS-SEND-SYM) DELIMITED BY SPACE
           " to numeric " DELIMITED BY SIZE
           SY-NAME(LS-RECV-SYM) DELIMITED BY SPACE
           ", which nothing in the paragraph tests with NUMERIC"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C061.
