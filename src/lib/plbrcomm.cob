*> ---------------------------------------------------------------
*> plbrcomm: PLB-M019 commented-out-code.
*>
*> Comment lines that are COBOL statements rather than prose:
*>
*>      *    MOVE WS-OLD-RATE TO WS-RATE
*>      *    PERFORM 300-APPLY-DISCOUNT.
*>
*> Code kept in comments is never compiled and soon wrong: its names
*> are renamed and its logic changed around it, and the reader has to
*> make out each time whether it matters. Version control keeps old
*> code; the comments can go.
*>
*> A comment line counts when its text starts with a statement's verb
*> (MOVE, PERFORM, IF, CALL, ...), has no lower-case letters, has what
*> prose rarely has: a hyphenated name (WS-RATE, 300-APPLY) or a period
*> at its end, and has at most one plain word: one that is not a
*> reserved word of the statement (TO, OF, UNTIL, ...), a hyphenated
*> name, a number, or in a literal. "MOVE OLD VALUES TO NON-DISPLAY
*> FIELDS" is prose. A run of such lines, which may have blank or
*> other comment lines between them, is reported once, at its first
*> line, with its count. Only the lines of the file analyzed are read,
*> not those of its copybooks. Off by default.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-M019.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-FILE                 PIC 9(4) COMP-5.
01  LS-L                    PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-RUN                  PIC 9(9) COMP-5.
01  LS-GAP                  PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(256).
01  LS-UPPER                PIC X(256).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-START                PIC 9(9) COMP-5.
01  LS-VERB                 PIC X(20).
01  LS-CODE                 PIC X.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(40).
01  LS-WORD-LEN             PIC 9(9) COMP-5.
01  LS-PLAIN                PIC 9(9) COMP-5.
01  LS-QUOTE                PIC X.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M019" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR TK-COUNT = 0
        GOBACK
    END-IF
    *> The file analyzed: that of its first token.
    MOVE TK-FILE-ID(1) TO LS-FILE
    IF LS-FILE < 1 OR LS-FILE > SS-FILE-COUNT
        GOBACK
    END-IF
    IF SF-LOADED(LS-FILE) NOT = "Y" OR SF-FIRST-LINE(LS-FILE) = 0
        GOBACK
    END-IF
    MOVE 0 TO LS-RUN LS-GAP LS-FIRST
    PERFORM VARYING LS-L FROM SF-FIRST-LINE(LS-FILE) BY 1
            UNTIL LS-L >= SF-FIRST-LINE(LS-FILE)
                         + SF-LINE-COUNT(LS-FILE)
        EVALUATE TRUE
            WHEN SL-IS-COMMENT(LS-L)
                PERFORM TEST-LINE
                IF LS-CODE = "Y"
                    IF LS-RUN = 0
                        MOVE LS-L TO LS-FIRST
                    END-IF
                    ADD 1 TO LS-RUN
                    MOVE 0 TO LS-GAP
                ELSE
                    ADD 1 TO LS-GAP
                END-IF
            WHEN SL-IS-BLANK(LS-L)
                ADD 1 TO LS-GAP
            WHEN OTHER
                PERFORM END-RUN
        END-EVALUATE
        *> More than two lines of something else end a run too.
        IF LS-GAP > 2
            PERFORM END-RUN
        END-IF
    END-PERFORM
    PERFORM END-RUN
    GOBACK.

*> LS-CODE = "Y" when comment line LS-L reads as a statement.
TEST-LINE.
    MOVE "N" TO LS-CODE
    MOVE SPACES TO LS-TEXT
    IF SL-FORMAT(LS-L) NOT = "F"
        *> Fixed format: the indicator is in column 7; the text runs
        *> from column 8 to 72 (to the end in VARIABLE format).
        IF SL-TEXT-LEN(LS-L) <= 7
            EXIT PARAGRAPH
        END-IF
        IF SL-FORMAT(LS-L) = "V"
            COMPUTE LS-LEN = FUNCTION MIN(SL-TEXT-LEN(LS-L), 256) - 7
        ELSE
            COMPUTE LS-LEN = FUNCTION MIN(SL-TEXT-LEN(LS-L), 72) - 7
        END-IF
        MOVE SS-HEAP(SL-TEXT-OFF(LS-L) + 7:LS-LEN) TO LS-TEXT
    ELSE
        *> Free format: after the *> that starts the comment.
        IF SL-COMMENT-COL(LS-L) = 0
           OR SL-COMMENT-COL(LS-L) + 2 > SL-TEXT-LEN(LS-L)
            EXIT PARAGRAPH
        END-IF
        COMPUTE LS-LEN = SL-TEXT-LEN(LS-L) - SL-COMMENT-COL(LS-L) - 1
        IF LS-LEN > 256
            MOVE 256 TO LS-LEN
        END-IF
        MOVE SS-HEAP(SL-TEXT-OFF(LS-L) + SL-COMMENT-COL(LS-L) + 1:
            LS-LEN) TO LS-TEXT
    END-IF
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-UPPER
    IF LS-UPPER NOT = LS-TEXT
        EXIT PARAGRAPH
    END-IF
    *> The first word.
    MOVE 1 TO LS-START
    PERFORM UNTIL LS-START > 256
        IF LS-TEXT(LS-START:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-START
    END-PERFORM
    IF LS-START > 250
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-VERB
    UNSTRING LS-TEXT(LS-START:) DELIMITED BY SPACE OR "." INTO LS-VERB
    EVALUATE LS-VERB
        WHEN "MOVE" WHEN "PERFORM" WHEN "IF" WHEN "ELSE" WHEN "END-IF"
        WHEN "CALL" WHEN "DISPLAY" WHEN "COMPUTE" WHEN "ADD"
        WHEN "SUBTRACT" WHEN "MULTIPLY" WHEN "DIVIDE" WHEN "INITIALIZE"
        WHEN "READ" WHEN "WRITE" WHEN "REWRITE" WHEN "OPEN" WHEN "CLOSE"
        WHEN "GO" WHEN "EVALUATE" WHEN "WHEN" WHEN "END-EVALUATE"
        WHEN "END-PERFORM" WHEN "STRING" WHEN "UNSTRING" WHEN "INSPECT"
        WHEN "SET" WHEN "ACCEPT" WHEN "EXEC" WHEN "END-EXEC" WHEN "SEARCH"
        WHEN "GOBACK" WHEN "EXIT"
            CONTINUE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    *> A hyphenated name, or a period at the end.
    CALL "PLB-STR-LENGTH" USING LS-TEXT LS-LEN
    IF LS-LEN > 0
        IF LS-TEXT(LS-LEN:1) = "."
            MOVE "Y" TO LS-CODE
        END-IF
    END-IF
    PERFORM VARYING LS-K FROM LS-START BY 1 UNTIL LS-K >= LS-LEN
                                              OR LS-CODE = "Y"
        IF LS-TEXT(LS-K:1) = "-" AND LS-K > LS-START
            IF LS-TEXT(LS-K - 1:1) NOT = SPACE
               AND LS-TEXT(LS-K + 1:1) NOT = SPACE
                MOVE "Y" TO LS-CODE
            END-IF
        END-IF
    END-PERFORM
    IF LS-CODE = "Y"
        PERFORM COUNT-PLAIN-WORDS
        IF LS-PLAIN > 1
            MOVE "N" TO LS-CODE
        END-IF
    END-IF.

*> LS-PLAIN: the words after the verb, outside literals, that are not
*> reserved words, hyphenated names, or numbers.
COUNT-PLAIN-WORDS.
    MOVE 0 TO LS-PLAIN
    MOVE SPACE TO LS-QUOTE
    COMPUTE LS-P = LS-START + FUNCTION LENGTH(FUNCTION TRIM(LS-VERB))
    PERFORM UNTIL LS-P > LS-LEN
        *> Past blanks; a literal is passed over whole.
        IF LS-TEXT(LS-P:1) = SPACE OR LS-TEXT(LS-P:1) = ","
            ADD 1 TO LS-P
        ELSE
            IF LS-TEXT(LS-P:1) = '"' OR LS-TEXT(LS-P:1) = "'"
                MOVE LS-TEXT(LS-P:1) TO LS-QUOTE
                ADD 1 TO LS-P
                PERFORM UNTIL LS-P > LS-LEN
                    IF LS-TEXT(LS-P:1) = LS-QUOTE
                        EXIT PERFORM
                    END-IF
                    ADD 1 TO LS-P
                END-PERFORM
                ADD 1 TO LS-P
            ELSE
                MOVE SPACES TO LS-WORD
                MOVE 0 TO LS-WORD-LEN
                PERFORM UNTIL LS-P > LS-LEN
                    IF LS-TEXT(LS-P:1) = SPACE OR LS-TEXT(LS-P:1) = ","
                        EXIT PERFORM
                    END-IF
                    IF LS-WORD-LEN < 40
                        ADD 1 TO LS-WORD-LEN
                        MOVE LS-TEXT(LS-P:1) TO LS-WORD(LS-WORD-LEN:1)
                    END-IF
                    ADD 1 TO LS-P
                END-PERFORM
                PERFORM CLASSIFY-WORD
            END-IF
        END-IF
    END-PERFORM.

CLASSIFY-WORD.
    IF LS-WORD-LEN > 0
        IF LS-WORD(LS-WORD-LEN:1) = "."
            MOVE SPACE TO LS-WORD(LS-WORD-LEN:1)
            SUBTRACT 1 FROM LS-WORD-LEN
        END-IF
    END-IF
    IF LS-WORD-LEN = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-K
    INSPECT LS-WORD(1:LS-WORD-LEN) TALLYING LS-K FOR ALL "-"
    IF LS-K > 0 OR LS-WORD(1:LS-WORD-LEN) IS NUMERIC
        EXIT PARAGRAPH
    END-IF
    EVALUATE LS-WORD
        WHEN "TO" WHEN "OF" WHEN "IN" WHEN "FROM" WHEN "BY" WHEN "INTO"
        WHEN "GIVING" WHEN "USING" WHEN "THRU" WHEN "THROUGH"
        WHEN "UNTIL" WHEN "VARYING" WHEN "TIMES" WHEN "AND" WHEN "OR"
        WHEN "NOT" WHEN "EQUAL" WHEN "GREATER" WHEN "LESS" WHEN "THAN"
        WHEN "IS" WHEN "=" WHEN ">" WHEN "<" WHEN ">=" WHEN "<="
        WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES" WHEN "SPACE" WHEN "SPACES"
        WHEN "LOW-VALUES" WHEN "HIGH-VALUES" WHEN "TRUE" WHEN "FALSE"
        WHEN "THEN" WHEN "ELSE" WHEN "GO" WHEN "DELIMITED" WHEN "SIZE"
        WHEN "ALL" WHEN "RECORD" WHEN "NEXT" WHEN "AT" WHEN "END"
        WHEN "INVALID" WHEN "KEY" WHEN "INPUT" WHEN "OUTPUT" WHEN "I-O"
        WHEN "EXTEND" WHEN "ROUNDED" WHEN "PROGRAM" WHEN "RUN"
        WHEN "PARAGRAPH" WHEN "SECTION" WHEN "WITH" WHEN "POINTER"
        WHEN "TALLYING" WHEN "REPLACING" WHEN "FOR" WHEN "LEADING"
        WHEN "CHARACTERS" WHEN "AFTER" WHEN "BEFORE" WHEN "UPON"
        WHEN "CONSOLE" WHEN "NUMERIC" WHEN "ALPHABETIC" WHEN "OTHER"
        WHEN "ALSO" WHEN "ON" WHEN "ERROR" WHEN "REMAINDER"
        WHEN "CORRESPONDING" WHEN "CORR" WHEN "ADDRESS" WHEN "LENGTH"
        WHEN "FUNCTION" WHEN "CONTENT" WHEN "REFERENCE" WHEN "VALUE"
        WHEN "SQL" WHEN "CICS" WHEN "END-EXEC"
            CONTINUE
        WHEN OTHER
            ADD 1 TO LS-PLAIN
    END-EVALUATE.

*> The run of commented-out lines, if any, as one finding.
END-RUN.
    IF LS-RUN > 0
        MOVE LS-RUN TO LS-NUM
        CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
        MOVE SPACES TO LS-MESSAGE
        IF LS-RUN = 1
            MOVE "a line of commented-out code" TO LS-MESSAGE
        ELSE
            STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
                   " lines of commented-out code" DELIMITED BY SIZE
                INTO LS-MESSAGE
        END-IF
        MOVE 1 TO LS-COLUMN
        IF SL-FORMAT(LS-FIRST) NOT = "F"
            MOVE 7 TO LS-COLUMN
        END-IF
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            SL-FILE-ID(LS-FIRST) SL-LINE-NO(LS-FIRST) LS-COLUMN
            LS-FIRST LS-MESSAGE
    END-IF
    MOVE 0 TO LS-RUN LS-GAP LS-FIRST.
END PROGRAM PLB-RULE-M019.
