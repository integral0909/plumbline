*> ---------------------------------------------------------------
*> plbrstrsp: PLB-C105 string-edited-leading-space.
*>
*> A STRING that sends a numeric-edited item DELIMITED BY SPACE, where
*> the item's picture starts with a symbol that leaves a space for a
*> small or positive value:
*>
*>     01  WS-AMOUNT   PIC ZZZ9.
*>         STRING "TOTAL " WS-AMOUNT DELIMITED BY SPACE INTO WS-LINE
*>
*> STRING stops sending an item at its first space, so for 5, held as
*> "   5", it sends nothing at all. The symbols are Z and B, which leave
*> spaces for leading zeros and blanks, a leading -, which is a space
*> for a positive value, and a floating + or currency sign (++9, $$9),
*> which leaves spaces before the sign. Asterisks (***9) fill with *,
*> and 9 and 0 never leave a space at the start. Send such an item
*> DELIMITED BY SIZE, or move it to an item without the spaces first.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C105.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-LEVEL                PIC S9(4) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-CLAUSE               PIC 9(9) COMP-5.
01  LS-PICTURE              PIC X(64).
01  LS-PICTURE-LEN          PIC 9(9) COMP-5.
01  LS-LEADING              PIC X.
*> The items sent since the last DELIMITED phrase.
01  LS-SENT-COUNT           PIC 9(4) COMP-5.
01  LS-SENT                 PIC 9(9) COMP-5 OCCURS 50 TIMES.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C105" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "STRING"
            PERFORM CHECK-STRING
        END-IF
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> The items STRING LS-NODE sends, up to INTO, each with the
*> DELIMITED phrase that follows it.
CHECK-STRING.
    MOVE 0 TO LS-LEVEL LS-SENT-COUNT
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL > 0
                CONTINUE
            WHEN WS-TOKEN-REF(LS-T) > 0
                MOVE WS-TOKEN-REF(LS-T) TO LS-R
                IF LS-SENT-COUNT < 50
                    ADD 1 TO LS-SENT-COUNT
                    MOVE LS-R TO LS-SENT(LS-SENT-COUNT)
                END-IF
                MOVE RF-LAST(LS-R) TO LS-T
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
                EVALUATE LS-WORD
                    WHEN "INTO"
                        EXIT PARAGRAPH
                    WHEN "DELIMITED"
                        PERFORM READ-DELIMITER
                END-EVALUATE
        END-EVALUATE
        ADD 1 TO LS-T
    END-PERFORM.

*> DELIMITED [BY] at LS-T: when the delimiter is a space, the items
*> sent before it; LS-T is left at the delimiter.
READ-DELIMITER.
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) = "BY"
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    END-IF
    IF WS-TOKEN-REF(LS-T) = 0
        IF (TK-IS-WORD(LS-T)
            AND (FUNCTION UPPER-CASE(LS-WORD) = "SPACE"
                 OR FUNCTION UPPER-CASE(LS-WORD) = "SPACES"))
           OR (TK-IS-ALNUM(LS-T) AND TK-PREFIX(LS-T) = SPACES
               AND TK-TEXT-LEN(LS-T) = 1 AND LS-WORD(1:1) = SPACE)
            PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-SENT-COUNT
                MOVE LS-SENT(LS-I) TO LS-R
                PERFORM CHECK-SENDER
            END-PERFORM
        END-IF
    END-IF
    MOVE 0 TO LS-SENT-COUNT.

*> The item of reference LS-R: numeric-edited, with a picture that
*> starts with a space for some values.
CHECK-SENDER.
    IF RF-KIND(LS-R) NOT = "D" OR RF-REFMOD(LS-R) = "Y"
       OR RF-SYMBOL(LS-R) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF SY-CATEGORY(LS-S) NOT = "E" OR SY-NODE(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-CLAUSE
    PERFORM UNTIL LS-CLAUSE = 0
        IF ND-KIND(LS-CLAUSE) = "CLAU" AND ND-DETAIL(LS-CLAUSE) = "PICTURE"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CLAUSE) TO LS-CLAUSE
    END-PERFORM
    IF LS-CLAUSE = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-PICTURE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-TOK-LAST(LS-CLAUSE)
        LS-PICTURE LS-PICTURE-LEN
    IF LS-PICTURE-LEN < 2
        EXIT PARAGRAPH
    END-IF
    MOVE FUNCTION UPPER-CASE(LS-PICTURE) TO LS-PICTURE
    MOVE "N" TO LS-LEADING
    EVALUATE TRUE
        WHEN LS-PICTURE(1:1) = "Z" OR "B" OR "-"
            MOVE "Y" TO LS-LEADING
        WHEN (LS-PICTURE(1:1) = "+" OR "$")
             AND (LS-PICTURE(2:1) = LS-PICTURE(1:1)
                  OR LS-PICTURE(2:1) = "(")
            MOVE "Y" TO LS-LEADING
    END-EVALUATE
    IF LS-LEADING = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " (PIC " DELIMITED BY SIZE
           LS-PICTURE(1:LS-PICTURE-LEN) DELIMITED BY SIZE
           ") starts with a space for some values, and STRING sends"
           " nothing of it then, DELIMITED BY SPACE" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C105.
