*> ---------------------------------------------------------------
*> plbrcount: PLB-C104 count-too-small.
*>
*> A count that INSPECT or UNSTRING stores in an item with too few
*> digits to hold it:
*>
*>     01  WS-TEXT    PIC X(50).
*>     01  WS-COUNT   PIC 9.
*>         INSPECT WS-TEXT TALLYING WS-COUNT FOR ALL "A"
*>         UNSTRING WS-TEXT DELIMITED BY "," INTO WS-PART
*>             COUNT IN WS-COUNT
*>
*> The count is stored like the result of an ADD without ON SIZE
*> ERROR: its high-order digits are lost. With GnuCOBOL 3.2, 50 A's
*> counted into a PIC 9 leave 0, and so does a COUNT IN of 50
*> characters. The largest count is the length of the item inspected,
*> divided by the length of the shortest string counted (CHARACTERS
*> counts one at a time), or, for COUNT IN, the length of the item
*> unstrung. A string that is neither a literal nor an item of fixed
*> size, an item with reference modification or of variable size, and
*> a count of native binary usage are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C104.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-SUBJECT              PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-SHORTEST             PIC 9(9) COMP-5.
01  LS-OPERAND-LEN          PIC 9(9) COMP-5.
*> What the next operand is: S a string counted, B a BEFORE or AFTER
*> string, N not expected.
01  LS-MODE                 PIC X.
01  LS-OK                   PIC X.
01  LS-MOST                 PIC S9(18) COMP-5.
01  LS-HOLDS                PIC S9(18) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-HOLDS-TEXT           PIC X(20).
01  LS-HOLDS-LEN            PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C104" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    MOVE 0 TO LS-STMT LS-SUBJECT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        *> The first reference of a statement is what it inspects or
        *> unstrings.
        IF RF-STMT(LS-R) NOT = LS-STMT
            MOVE RF-STMT(LS-R) TO LS-STMT
            MOVE LS-R TO LS-SUBJECT
        ELSE
            IF LS-STMT > 0
                PERFORM CHECK-REFERENCE
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> Reference LS-R, after the subject LS-SUBJECT of statement LS-STMT:
*> a count when INSPECT has FOR after it, or UNSTRING COUNT [IN]
*> before it.
CHECK-REFERENCE.
    IF ND-DETAIL(LS-STMT) NOT = "INSPECT"
       AND ND-DETAIL(LS-STMT) NOT = "UNSTRING"
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-R) NOT = "D" OR RF-KIND(LS-SUBJECT) NOT = "D"
       OR RF-REFMOD(LS-SUBJECT) = "Y"
        EXIT PARAGRAPH
    END-IF
    IF SY-VARIABLE(RF-SYMBOL(LS-SUBJECT)) = "Y"
       OR SY-SIZE(RF-SYMBOL(LS-SUBJECT)) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-TOK-LAST(LS-STMT) TO LS-LAST
    IF ND-DETAIL(LS-STMT) = "INSPECT"
        COMPUTE LS-T = RF-LAST(LS-R) + 1
        IF LS-T > LS-LAST
            EXIT PARAGRAPH
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF FUNCTION UPPER-CASE(LS-WORD) NOT = "FOR"
            EXIT PARAGRAPH
        END-IF
        PERFORM SHORTEST-STRING
        IF LS-OK = "N"
            EXIT PARAGRAPH
        END-IF
        COMPUTE LS-MOST = SY-SIZE(RF-SYMBOL(LS-SUBJECT)) / LS-SHORTEST
    ELSE
        COMPUTE LS-T = RF-TOKEN(LS-R) - 1
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF FUNCTION UPPER-CASE(LS-WORD) = "IN"
            SUBTRACT 1 FROM LS-T
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        END-IF
        IF FUNCTION UPPER-CASE(LS-WORD) NOT = "COUNT"
            EXIT PARAGRAPH
        END-IF
        MOVE SY-SIZE(RF-SYMBOL(LS-SUBJECT)) TO LS-MOST
    END-IF
    PERFORM COUNT-HOLDS
    IF LS-HOLDS >= 0 AND LS-MOST > LS-HOLDS
        PERFORM REPORT-COUNT
    END-IF.

*> LS-SHORTEST: the length of the shortest string the count at LS-R
*> counts, from FOR to the next count (an item followed by FOR) or
*> the end of the statement. LS-OK = "N" when one cannot be read.
SHORTEST-STRING.
    MOVE "Y" TO LS-OK
    MOVE 999999 TO LS-SHORTEST
    MOVE "N" TO LS-MODE
    COMPUTE LS-T = RF-LAST(LS-R) + 2
    PERFORM UNTIL LS-T > LS-LAST
        MOVE WS-TOKEN-REF(LS-T) TO LS-Q
        IF LS-Q > 0
            *> The next count ends this one's strings.
            IF RF-LAST(LS-Q) < LS-LAST
                COMPUTE LS-T = RF-LAST(LS-Q) + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD
                    LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = "FOR"
                    EXIT PERFORM
                END-IF
            END-IF
            IF LS-MODE = "S"
                IF RF-KIND(LS-Q) NOT = "D" OR RF-REFMOD(LS-Q) = "Y"
                    MOVE "N" TO LS-OK
                    EXIT PARAGRAPH
                END-IF
                IF SY-VARIABLE(RF-SYMBOL(LS-Q)) = "Y"
                   OR SY-SIZE(RF-SYMBOL(LS-Q)) = 0
                    MOVE "N" TO LS-OK
                    EXIT PARAGRAPH
                END-IF
                MOVE SY-SIZE(RF-SYMBOL(LS-Q)) TO LS-OPERAND-LEN
                PERFORM TAKE-LENGTH
            END-IF
            IF LS-MODE = "B"
                MOVE "S" TO LS-MODE
            END-IF
            COMPUTE LS-T = RF-LAST(LS-Q) + 1
        ELSE
            PERFORM READ-TOKEN
            ADD 1 TO LS-T
        END-IF
    END-PERFORM
    IF LS-SHORTEST = 999999
        MOVE "N" TO LS-OK
    END-IF.

*> The token at LS-T that is not a data reference.
READ-TOKEN.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    EVALUATE TRUE
        WHEN LS-WORD = "ALL" OR LS-WORD = "LEADING"
            MOVE "S" TO LS-MODE
        WHEN LS-WORD = "CHARACTERS"
            MOVE 1 TO LS-OPERAND-LEN
            PERFORM TAKE-LENGTH
            MOVE "N" TO LS-MODE
        WHEN LS-WORD = "BEFORE" OR LS-WORD = "AFTER"
            MOVE "B" TO LS-MODE
        WHEN LS-WORD = "INITIAL"
            CONTINUE
        WHEN TK-IS-ALNUM(LS-T) OR TK-IS-NUMBER(LS-T)
            IF LS-MODE = "S"
                IF TK-IS-ALNUM(LS-T) AND TK-PREFIX(LS-T) NOT = SPACES
                    MOVE "N" TO LS-OK
                END-IF
                MOVE TK-TEXT-LEN(LS-T) TO LS-OPERAND-LEN
                IF TK-IS-NUMBER(LS-T)
                    MOVE LS-LEN TO LS-OPERAND-LEN
                END-IF
                PERFORM TAKE-LENGTH
            END-IF
            IF LS-MODE = "B"
                MOVE "S" TO LS-MODE
            END-IF
        WHEN LS-WORD = "SPACE" OR "SPACES" OR "ZERO" OR "ZEROS"
             OR "ZEROES" OR "QUOTE" OR "QUOTES" OR "LOW-VALUE"
             OR "LOW-VALUES" OR "HIGH-VALUE" OR "HIGH-VALUES"
            IF LS-MODE = "S"
                MOVE 1 TO LS-OPERAND-LEN
                PERFORM TAKE-LENGTH
            END-IF
            IF LS-MODE = "B"
                MOVE "S" TO LS-MODE
            END-IF
    END-EVALUATE.

TAKE-LENGTH.
    IF LS-OPERAND-LEN = 0
        MOVE "N" TO LS-OK
    END-IF
    IF LS-OPERAND-LEN < LS-SHORTEST
        MOVE LS-OPERAND-LEN TO LS-SHORTEST
    END-IF.

*> LS-HOLDS: the largest count the item at LS-R holds; -1 when it is
*> not an integer of decimal digits or of binary usage that keeps to
*> its picture.
COUNT-HOLDS.
    MOVE -1 TO LS-HOLDS
    IF SY-CATEGORY(RF-SYMBOL(LS-R)) NOT = "9"
       OR SY-SCALE(RF-SYMBOL(LS-R)) NOT = 0
       OR SY-DIGITS(RF-SYMBOL(LS-R)) = 0
       OR SY-DIGITS(RF-SYMBOL(LS-R)) > 17
        EXIT PARAGRAPH
    END-IF
    EVALUATE SY-USAGE(RF-SYMBOL(LS-R))
        WHEN SPACES WHEN "DISPLAY" WHEN "PACKED-DECIMAL" WHEN "COMP-3"
        WHEN "COMPUTATIONAL-3" WHEN "BINARY" WHEN "COMP"
        WHEN "COMPUTATIONAL" WHEN "COMP-4" WHEN "COMPUTATIONAL-4"
            CONTINUE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE 1 TO LS-HOLDS
    PERFORM SY-DIGITS(RF-SYMBOL(LS-R)) TIMES
        MULTIPLY 10 BY LS-HOLDS
    END-PERFORM
    SUBTRACT 1 FROM LS-HOLDS.

REPORT-COUNT.
    MOVE LS-MOST TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    CALL "PLB-STR-FROM-INT" USING LS-HOLDS LS-HOLDS-TEXT LS-HOLDS-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(RF-SYMBOL(LS-R)) DELIMITED BY SPACE
           " holds counts up to " DELIMITED BY SIZE
           LS-HOLDS-TEXT(1:LS-HOLDS-LEN) DELIMITED BY SIZE
           ", but this count can reach " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           "; its high-order digits are lost" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C104.
