*> ---------------------------------------------------------------
*> plbrstrnum: PLB-C101 string-numeric-sender.
*>
*> A STRING that sends a numeric item with decimal places or a sign:
*>
*>     01  WS-AMOUNT  PIC S9(5)V99.
*>         STRING "TOTAL " WS-AMOUNT DELIMITED BY SIZE INTO WS-LINE
*>
*> STRING sends the item's characters as they are stored, not the
*> number they stand for: the decimal point is not there (1.5 in a
*> 9(3)V99 is sent as 00150), and the sign is kept in the last digit,
*> which becomes a letter or another sign (with GnuCOBOL 3.2, -123 in
*> an S9(3) is sent as 12s). MOVE the item to a numeric-edited item
*> first, and send that. An item with a separate sign (SIGN SEPARATE)
*> sends a real - or +, and its decimal places are what is reported.
*> The compiler rejects packed and binary items in STRING itself.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C101.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-LEVEL                PIC S9(4) COMP-5.
01  LS-AFTER-BY             PIC X.
01  LS-SEPARATE             PIC X.
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
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C101" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "STRING"
            PERFORM CHECK-STRING
        END-IF
    END-PERFORM
    GOBACK.

*> The items STRING LS-NODE sends: those up to INTO, outside
*> parentheses, other than the delimiter after DELIMITED [BY].
CHECK-STRING.
    MOVE 0 TO LS-LEVEL
    MOVE "N" TO LS-AFTER-BY
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL > 0
                CONTINUE
            WHEN TK-IS-WORD(LS-T)
                PERFORM REF-AT
                IF LS-R = 0
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD
                        LS-LEN
                    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
                    EVALUATE LS-WORD
                        WHEN "INTO"
                            EXIT PARAGRAPH
                        WHEN "DELIMITED"
                            MOVE "Y" TO LS-AFTER-BY
                        WHEN "BY" WHEN "ALL"
                            CONTINUE
                        WHEN OTHER
                            *> SIZE, SPACE, a figurative constant.
                            MOVE "N" TO LS-AFTER-BY
                    END-EVALUATE
                ELSE
                    IF LS-AFTER-BY = "N"
                        PERFORM CHECK-SENDER
                    END-IF
                    MOVE "N" TO LS-AFTER-BY
                    MOVE RF-LAST(LS-R) TO LS-T
                END-IF
            WHEN OTHER
                MOVE "N" TO LS-AFTER-BY
        END-EVALUATE
        ADD 1 TO LS-T
    END-PERFORM.

*> LS-R: the data reference that starts at token LS-T, or 0.
REF-AT.
    MOVE 0 TO LS-K
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > RF-COUNT
        IF RF-TOKEN(LS-K) = LS-T
            IF RF-KIND(LS-K) = "D" AND RF-SYMBOL(LS-K) > 0
                MOVE LS-K TO LS-R
                EXIT PARAGRAPH
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE 0 TO LS-R.

*> The sent item of reference LS-R: a DISPLAY number with decimal
*> places, or a sign kept in its last digit.
CHECK-SENDER.
    IF RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF SY-CATEGORY(LS-S) NOT = "9"
        EXIT PARAGRAPH
    END-IF
    IF SY-USAGE(LS-S) NOT = SPACES AND SY-USAGE(LS-S) NOT = "DISPLAY"
        EXIT PARAGRAPH
    END-IF
    PERFORM SIGN-SEPARATE
    MOVE SPACES TO LS-MESSAGE
    EVALUATE TRUE
        WHEN SY-SCALE(LS-S) > 0
            STRING "STRING sends the digits of " DELIMITED BY SIZE
                   SY-NAME(LS-S) DELIMITED BY SPACE
                   " without its decimal point: 1.5 in a 9(3)V99 is "
                   "sent as 00150" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN SY-SIGNED(LS-S) = "Y" AND LS-SEPARATE = "N"
            STRING "STRING sends signed " DELIMITED BY SIZE
                   SY-NAME(LS-S) DELIMITED BY SPACE
                   " as stored, its sign in its last digit: -123 is "
                   "sent as 12s" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.

*> LS-SEPARATE = "Y" when item LS-S has SIGN ... SEPARATE.
SIGN-SEPARATE.
    MOVE "N" TO LS-SEPARATE
    IF SY-NODE(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-N FROM ND-TOK-FIRST(SY-NODE(LS-S)) BY 1
            UNTIL LS-N > ND-TOK-LAST(SY-NODE(LS-S))
        IF TK-IS-WORD(LS-N)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-N LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "SEPARATE"
                MOVE "Y" TO LS-SEPARATE
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM.
END PROGRAM PLB-RULE-C101.
