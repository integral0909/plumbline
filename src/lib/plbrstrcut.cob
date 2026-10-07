*> ---------------------------------------------------------------
*> plbrstrcut: PLB-C078 string-literal-cut.
*>
*> A literal sent by STRING with a delimiter that the literal holds:
*>
*>     STRING "DEAR MR " WS-NAME DELIMITED BY SPACE
*>         INTO WS-LINE
*>
*> Each operand is sent up to the first occurrence of its delimiter, so
*> "DEAR MR " sends only "DEAR". A literal says what is to be sent, so
*> one cut short by its own delimiter is a mistake: DELIMITED BY SIZE
*> was meant for it. The delimiters read are SPACE, ZERO, QUOTE (with
*> or without ALL), and alphanumeric literals without a prefix; the
*> literals checked are the operands the phrase applies to, outside
*> parentheses (not the arguments of a function).
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C078.
DATA DIVISION.
LOCAL-STORAGE SECTION.
78  PENDING-MAX             VALUE 64.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> The literal operands since the last DELIMITED phrase.
01  LS-PENDING-COUNT        PIC 9(9) COMP-5.
01  LS-PENDING              PIC 9(9) COMP-5 OCCURS PENDING-MAX TIMES.
*> The delimiter: its characters, and how it is written.
01  LS-DELIM                PIC X(256).
01  LS-DELIM-LEN            PIC 9(9) COMP-5.
01  LS-DELIM-SHOWN          PIC X(40).
01  LS-VALUE                PIC X(256).
01  LS-VALUE-LEN            PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C078" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "STRING"
            PERFORM CHECK-STRING
        END-IF
    END-PERFORM
    GOBACK.

*> The operands of STRING statement LS-NODE, up to INTO.
CHECK-STRING.
    MOVE ND-TOK-LAST(LS-NODE) TO LS-LAST
    MOVE 0 TO LS-DEPTH LS-PENDING-COUNT
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM UNTIL LS-T > LS-LAST
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-DEPTH
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-DEPTH
            WHEN LS-DEPTH > 0
                CONTINUE
            WHEN TK-IS-ALNUM(LS-T)
                IF TK-PREFIX(LS-T) = SPACES
                   AND LS-PENDING-COUNT < PENDING-MAX
                    ADD 1 TO LS-PENDING-COUNT
                    MOVE LS-T TO LS-PENDING(LS-PENDING-COUNT)
                END-IF
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                IF LS-WORD = "INTO"
                    EXIT PARAGRAPH
                END-IF
                IF LS-WORD = "DELIMITED"
                    PERFORM READ-DELIMITER
                    PERFORM CHECK-PENDING
                    MOVE 0 TO LS-PENDING-COUNT
                END-IF
        END-EVALUATE
        ADD 1 TO LS-T
    END-PERFORM.

*> After DELIMITED at LS-T: [BY] [ALL] delimiter. LS-DELIM-LEN is 0
*> when the delimiter is SIZE, a data item, or not read; LS-T is left
*> on the delimiter's token.
READ-DELIMITER.
    MOVE 0 TO LS-DELIM-LEN
    MOVE SPACES TO LS-DELIM LS-DELIM-SHOWN
    ADD 1 TO LS-T
    PERFORM DELIMITER-WORD
    IF LS-WORD = "BY"
        ADD 1 TO LS-T
        PERFORM DELIMITER-WORD
    END-IF
    IF LS-WORD = "ALL"
        ADD 1 TO LS-T
        PERFORM DELIMITER-WORD
    END-IF
    IF LS-T > LS-LAST
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-T)
            IF TK-PREFIX(LS-T) = SPACES AND TK-TEXT-LEN(LS-T) > 0
               AND TK-TEXT-LEN(LS-T) <= 38
                MOVE TK-TEXT(TK-TEXT-OFF(LS-T):TK-TEXT-LEN(LS-T))
                    TO LS-DELIM
                MOVE TK-TEXT-LEN(LS-T) TO LS-DELIM-LEN
                STRING '"' LS-DELIM(1:LS-DELIM-LEN) '"' DELIMITED BY SIZE
                    INTO LS-DELIM-SHOWN
            END-IF
        WHEN LS-WORD = "SPACE" OR LS-WORD = "SPACES"
            MOVE SPACE TO LS-DELIM
            MOVE 1 TO LS-DELIM-LEN
            MOVE "SPACE" TO LS-DELIM-SHOWN
        WHEN LS-WORD = "ZERO" OR LS-WORD = "ZEROS" OR LS-WORD = "ZEROES"
            MOVE "0" TO LS-DELIM
            MOVE 1 TO LS-DELIM-LEN
            MOVE "ZERO" TO LS-DELIM-SHOWN
        WHEN LS-WORD = "QUOTE" OR LS-WORD = "QUOTES"
            MOVE '"' TO LS-DELIM
            MOVE 1 TO LS-DELIM-LEN
            MOVE "QUOTE" TO LS-DELIM-SHOWN
    END-EVALUATE.

*> LS-WORD: the word at LS-T, or spaces when it is not a word.
DELIMITER-WORD.
    MOVE SPACES TO LS-WORD
    IF LS-T <= LS-LAST
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        END-IF
    END-IF.

*> Each pending literal that holds the delimiter.
CHECK-PENDING.
    IF LS-DELIM-LEN = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-PENDING-COUNT
        MOVE TK-TEXT-LEN(LS-PENDING(LS-I)) TO LS-VALUE-LEN
        IF LS-VALUE-LEN > 0 AND LS-VALUE-LEN <= 120
            MOVE SPACES TO LS-VALUE
            MOVE TK-TEXT(TK-TEXT-OFF(LS-PENDING(LS-I)):LS-VALUE-LEN)
                TO LS-VALUE
            PERFORM FIND-DELIMITER
            IF LS-P > 0
                PERFORM REPORT-CUT
            END-IF
        END-IF
    END-PERFORM.

*> LS-P: where the delimiter first starts in the literal, or 0.
FIND-DELIMITER.
    MOVE 0 TO LS-P
    IF LS-DELIM-LEN > LS-VALUE-LEN
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-P FROM 1 BY 1
            UNTIL LS-P > LS-VALUE-LEN - LS-DELIM-LEN + 1
        IF LS-VALUE(LS-P:LS-DELIM-LEN) = LS-DELIM(1:LS-DELIM-LEN)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    MOVE 0 TO LS-P.

REPORT-CUT.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "DELIMITED BY " DELIMITED BY SIZE
           LS-DELIM-SHOWN DELIMITED BY "  "
           " cuts this literal at its first delimiter: STRING sends "
           DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-P = 1
        STRING "nothing of it" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING 'only "' LS-VALUE(1:LS-P - 1) '"' DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-PENDING(LS-I) LS-MESSAGE.
END PROGRAM PLB-RULE-C078.
