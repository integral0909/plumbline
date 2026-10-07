*> ---------------------------------------------------------------
*> plbrref: rules that read the data references.
*>
*>   PLB-C008  move-truncation
*>   PLB-C009  undefined-name
*>   PLB-C010  ambiguous-name
*> ---------------------------------------------------------------

*> PLB-C009 undefined-name and PLB-C010 ambiguous-name.
*>
*> In a file where a COPY statement names a copybook that was not
*> found, an undeclared name is most likely declared there: each such
*> name is reported once, at its first reference, with the missing
*> copybook, rather than at every reference.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-NAMES.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> The names reported once, in a file with a missing copybook.
78  WS-ONCE-MAX                 VALUE 5000.
01  WS-ONCE-COUNT           PIC 9(9) COMP-5.
01  WS-ONCE                 PIC X(120) OCCURS WS-ONCE-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-SEEN                 PIC X.
01  LS-MISSING              PIC X(80).
01  LS-RULE-UNDEFINED       PIC 9(4) COMP-5.
01  LS-RULE-AMBIGUOUS       PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(120).
01  LS-WORD                 PIC X(31).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbref.cpy".
COPY "plbincl.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-REFS
        PLB-INCLUSIONS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C009" LS-RULE-UNDEFINED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C010" LS-RULE-AMBIGUOUS
    MOVE 0 TO WS-ONCE-COUNT
    PERFORM MISSING-TEXT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        EVALUATE RF-KIND(LS-R)
            WHEN "U"
                PERFORM NAME-TEXT
                IF IM-COUNT > 0
                    PERFORM TEST-SEEN
                ELSE
                    MOVE "N" TO LS-SEEN
                END-IF
                IF LS-SEEN = "N"
                    STRING LS-TEXT DELIMITED BY "  "
                           " is not declared" DELIMITED BY SIZE
                           LS-MISSING DELIMITED BY "  "
                        INTO LS-MESSAGE
                    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET
                        PLB-TOKENS PLB-RULES PLB-FINDINGS
                        LS-RULE-UNDEFINED RF-TOKEN(LS-R) LS-MESSAGE
                END-IF
            WHEN "A"
                PERFORM NAME-TEXT
                STRING LS-TEXT DELIMITED BY "  "
                       " names more than one data item; qualify it"
                       " with IN or OF" DELIMITED BY SIZE
                    INTO LS-MESSAGE
                CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET
                    PLB-TOKENS PLB-RULES PLB-FINDINGS LS-RULE-AMBIGUOUS
                    RF-TOKEN(LS-R) LS-MESSAGE
        END-EVALUATE
    END-PERFORM
    GOBACK.

*> LS-MISSING: what the message adds when copybooks are missing.
MISSING-TEXT.
    MOVE SPACES TO LS-MISSING
    EVALUATE TRUE
        WHEN IM-COUNT = 1
            STRING "; copybook " DELIMITED BY SIZE
                   IM-NAME(1) DELIMITED BY SPACE
                   ", which was not found, may declare it"
                   DELIMITED BY SIZE
                INTO LS-MISSING
        WHEN IM-COUNT > 1
            STRING "; a copybook that was not found (" DELIMITED BY SIZE
                   IM-NAME(1) DELIMITED BY SPACE
                   ", ...) may declare it" DELIMITED BY SIZE
                INTO LS-MISSING
    END-EVALUATE.

*> LS-SEEN = "Y" when LS-TEXT was reported before; else it is noted.
TEST-SEEN.
    MOVE "N" TO LS-SEEN
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-ONCE-COUNT
        IF WS-ONCE(LS-I) = LS-TEXT
            MOVE "Y" TO LS-SEEN
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-ONCE-COUNT < WS-ONCE-MAX
        ADD 1 TO WS-ONCE-COUNT
        MOVE LS-TEXT TO WS-ONCE(WS-ONCE-COUNT)
    END-IF.

*> LS-TEXT = the name with its qualifiers, as in "A OF B".
NAME-TEXT.
    MOVE SPACES TO LS-MESSAGE LS-TEXT
    MOVE 1 TO LS-PTR
    PERFORM VARYING LS-T FROM RF-TOKEN(LS-R) BY 1
            UNTIL LS-T > RF-LAST(LS-R) OR TK-IS-LPAREN(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF LS-T > RF-TOKEN(LS-R)
            STRING " " DELIMITED BY SIZE INTO LS-TEXT WITH POINTER LS-PTR
        END-IF
        STRING LS-WORD(1:LS-LEN) DELIMITED BY SIZE
            INTO LS-TEXT WITH POINTER LS-PTR
    END-PERFORM.
END PROGRAM PLB-RULE-NAMES.

*> PLB-C008 move-truncation: a MOVE that cannot keep all of what it
*> moves.
*>
*>   - an alphanumeric literal longer than an alphanumeric or group
*>     receiver: the rightmost characters are lost;
*>   - a numeric literal or item with more integer digits than a
*>     numeric receiver: the high-order digits are lost, which silently
*>     changes the value;
*>   - a numeric literal with more decimal places than a numeric
*>     receiver (trailing zeros do not count): the low-order digits
*>     are lost. Items are not checked for that, as dropping decimal
*>     places of a computed value is often what is meant.
*>
*> Items with reference modification, MOVE CORRESPONDING, and moves of
*> ALL literals, figurative constants, and function results are not
*> checked: their sizes are not known here. Leading zeros of numeric
*> literals do not count as digits.
*>
*> PLB-C039 decimal-to-alphanumeric and PLB-M016 signed-to-alphanumeric
*> (off by default) are checked here too: a numeric item with decimal
*> places, or a signed integer, moved to an alphanumeric item.
*>
*> PLB-M004 alnum-narrowing (off by default) is checked here too: an
*> alphanumeric, edited, or group item moved to a smaller alphanumeric
*> or group item. That is often intended, so it is only a note.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C008.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
*> The storage of each item, for PLB-C046.
COPY "plbspan.cpy" REPLACING ==PLB-SPANS== BY ==WS-SPANS==.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-TRUNCATION      PIC 9(4) COMP-5.
01  LS-RULE-NARROWING       PIC 9(4) COMP-5.
01  LS-RULE-DECIMAL-TEXT    PIC 9(4) COMP-5.
01  LS-RULE-SIGNED-TEXT     PIC 9(4) COMP-5.
01  LS-RULE-OVERLAP         PIC 9(4) COMP-5.
01  LS-RULE-SIGN-LOST       PIC 9(4) COMP-5.
01  LS-OVERLAP              PIC X.
01  LS-SEND-SUBSCRIPTED     PIC X.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-SENDER               PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-LEVEL                PIC 9(4) COMP-5.
01  LS-TEXT                 PIC X(80).
01  LS-LEN                  PIC 9(9) COMP-5.
*> What is sent:
*>   L  alphanumeric literal of LS-SEND-SIZE characters
*>   N  numeric literal with LS-SEND-INT integer digits
*>   D  data item LS-SEND-SYM
*>   -  nothing checkable
01  LS-SEND-KIND            PIC X.
01  LS-SEND-SIZE            PIC 9(9) COMP-5.
01  LS-SEND-USED            PIC 9(9) COMP-5.
01  LS-SEND-CHECK           PIC 9(9) COMP-5.
01  LS-JUSTIFIED            PIC X.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-SEND-INT             PIC S9(9) COMP-5.
*> Decimal places of a numeric literal, without trailing zeros.
01  LS-SEND-DEC             PIC S9(9) COMP-5.
01  LS-IN-DECIMALS          PIC X.
01  LS-DECIMAL              PIC S9(9) COMP-5.
01  LS-SEND-SYM             PIC 9(9) COMP-5.
01  LS-SEND-NAME            PIC X(40).
01  LS-RECV                 PIC 9(9) COMP-5.
01  LS-RECV-INT             PIC S9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-DIGITS-SEEN          PIC X.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-A-TEXT               PIC X(20).
01  LS-A-LEN                PIC 9(9) COMP-5.
01  LS-B-TEXT               PIC X(20).
01  LS-B-LEN                PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C008" LS-RULE-TRUNCATION
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M004" LS-RULE-NARROWING
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C039" LS-RULE-DECIMAL-TEXT
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M016" LS-RULE-SIGNED-TEXT
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C046" LS-RULE-OVERLAP
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M018" LS-RULE-SIGN-LOST
    IF RL-ENABLED(LS-RULE-TRUNCATION) NOT = "Y"
       AND RL-ENABLED(LS-RULE-NARROWING) NOT = "Y"
       AND RL-ENABLED(LS-RULE-DECIMAL-TEXT) NOT = "Y"
       AND RL-ENABLED(LS-RULE-SIGNED-TEXT) NOT = "Y"
       AND RL-ENABLED(LS-RULE-OVERLAP) NOT = "Y"
       AND RL-ENABLED(LS-RULE-SIGN-LOST) NOT = "Y"
        GOBACK
    END-IF
    IF RL-ENABLED(LS-RULE-OVERLAP) = "Y"
        CALL "PLB-SPAN-BUILD" USING PLB-SYMBOLS WS-SPANS
    END-IF
    IF AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "MOVE"
            PERFORM CHECK-MOVE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

CHECK-MOVE.
    COMPUTE LS-SENDER = ND-TOK-FIRST(LS-NODE) + 1
    IF LS-SENDER > ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    PERFORM CLASSIFY-SENDER
    IF LS-SEND-KIND = "-"
        EXIT PARAGRAPH
    END-IF
    *> The TO outside any parentheses, then each receiver after it.
    MOVE 0 TO LS-TO LS-LEVEL
    PERFORM VARYING LS-T FROM LS-SENDER BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL = 0 AND TK-IS-WORD(LS-T) AND LS-TO = 0
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF LS-TEXT = "TO"
                    MOVE LS-T TO LS-TO
                END-IF
            WHEN LS-LEVEL = 0 AND LS-TO > 0
                IF WS-TOKEN-REF(LS-T) > 0
                    PERFORM CHECK-RECEIVER
                END-IF
        END-EVALUATE
    END-PERFORM.

CLASSIFY-SENDER.
    MOVE "-" TO LS-SEND-KIND
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-SENDER LS-TEXT LS-LEN
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-SENDER)
            MOVE "L" TO LS-SEND-KIND
            MOVE TK-TEXT-LEN(LS-SENDER) TO LS-SEND-SIZE
            *> Characters other than trailing spaces, which a receiver
            *> pads with anyway.
            MOVE LS-SEND-SIZE TO LS-SEND-USED
            PERFORM UNTIL LS-SEND-USED = 0
                IF TK-TEXT(TK-TEXT-OFF(LS-SENDER) + LS-SEND-USED - 1:1)
                   NOT = SPACE
                    EXIT PERFORM
                END-IF
                SUBTRACT 1 FROM LS-SEND-USED
            END-PERFORM
            EVALUATE TK-PREFIX(LS-SENDER)
                WHEN "X "
                    DIVIDE 2 INTO LS-SEND-SIZE
                WHEN "Z "
                    ADD 1 TO LS-SEND-SIZE
                WHEN "  "
                    CONTINUE
                WHEN OTHER
                    MOVE "-" TO LS-SEND-KIND
            END-EVALUATE
        WHEN TK-IS-NUMBER(LS-SENDER)
            PERFORM LITERAL-INTEGER-DIGITS
        WHEN TK-IS-WORD(LS-SENDER)
            IF WS-TOKEN-REF(LS-SENDER) > 0
                MOVE WS-TOKEN-REF(LS-SENDER) TO LS-R
                IF RF-KIND(LS-R) = "D" AND RF-REFMOD(LS-R) = "N"
                    MOVE "D" TO LS-SEND-KIND
                    MOVE RF-SYMBOL(LS-R) TO LS-SEND-SYM
                    MOVE RF-SUBSCRIPTED(LS-R) TO LS-SEND-SUBSCRIPTED
                    MOVE SY-SIZE(LS-SEND-SYM) TO LS-SEND-SIZE
                    COMPUTE LS-SEND-INT = SY-DIGITS(LS-SEND-SYM)
                        - SY-SCALE(LS-SEND-SYM)
                END-IF
            END-IF
    END-EVALUATE.

*> Integer digits of the numeric literal at LS-SENDER, without sign
*> or leading zeros, and its decimal places, without trailing zeros.
*> Floating-point literals are not checked.
LITERAL-INTEGER-DIGITS.
    MOVE 0 TO LS-SEND-INT LS-SEND-DEC LS-DECIMAL
    MOVE "N" TO LS-DIGITS-SEEN LS-IN-DECIMALS
    MOVE "N" TO LS-SEND-KIND
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        EVALUATE TRUE
            WHEN LS-TEXT(LS-I:1) = "." OR LS-TEXT(LS-I:1) = ","
                MOVE "Y" TO LS-IN-DECIMALS
            WHEN LS-TEXT(LS-I:1) = "E" OR LS-TEXT(LS-I:1) = "e"
                MOVE "-" TO LS-SEND-KIND
                EXIT PERFORM
            WHEN LS-TEXT(LS-I:1) < "0" OR LS-TEXT(LS-I:1) > "9"
                CONTINUE
            WHEN LS-IN-DECIMALS = "Y"
                ADD 1 TO LS-DECIMAL
                IF LS-TEXT(LS-I:1) NOT = "0"
                    MOVE LS-DECIMAL TO LS-SEND-DEC
                END-IF
            WHEN LS-TEXT(LS-I:1) NOT = "0"
                MOVE "Y" TO LS-DIGITS-SEEN
                ADD 1 TO LS-SEND-INT
            WHEN LS-DIGITS-SEEN = "Y"
                ADD 1 TO LS-SEND-INT
        END-EVALUATE
    END-PERFORM.

CHECK-RECEIVER.
    MOVE WS-TOKEN-REF(LS-T) TO LS-R
    IF RF-KIND(LS-R) NOT = "D" OR RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-RECV
    *> ANY LENGTH items and items with invalid pictures have no known
    *> size.
    IF SY-SIZE(LS-RECV) = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-OVERLAP
    IF LS-SEND-KIND = "D"
        IF SY-SIZE(LS-SEND-SYM) = 0
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE SPACES TO LS-MESSAGE
    EVALUATE TRUE
        *> Characters into an alphanumeric or group receiver.
        WHEN SY-CATEGORY(LS-RECV) = "X" OR "A" OR "D" OR "G"
            *> Cutting off trailing spaces loses nothing, unless the
            *> receiver is JUSTIFIED and loses characters on the left.
            MOVE LS-SEND-SIZE TO LS-SEND-CHECK
            IF LS-SEND-KIND = "L" AND TK-PREFIX(LS-SENDER) = SPACES
                PERFORM CHECK-JUSTIFIED
                IF LS-JUSTIFIED = "N"
                    MOVE LS-SEND-USED TO LS-SEND-CHECK
                END-IF
            END-IF
            IF LS-SEND-KIND = "L" AND LS-SEND-CHECK > SY-SIZE(LS-RECV)
                PERFORM REPORT-LITERAL-CHARACTERS
            END-IF
            IF LS-SEND-KIND = "D"
                IF (SY-CATEGORY(LS-SEND-SYM) = "X" OR "A" OR "D" OR "E"
                    OR "G")
                   AND LS-SEND-SIZE > SY-SIZE(LS-RECV)
                    PERFORM REPORT-ITEM-CHARACTERS
                END-IF
                *> A number with decimal places or a sign, as text.
                IF SY-CATEGORY(LS-SEND-SYM) = "9"
                   AND SY-CATEGORY(LS-RECV) NOT = "G"
                   AND (SY-SCALE(LS-SEND-SYM) > 0
                        OR SY-SIGNED(LS-SEND-SYM) = "Y")
                    PERFORM REPORT-NUMERIC-TEXT
                END-IF
            END-IF
        *> Digits into a numeric receiver.
        WHEN SY-CATEGORY(LS-RECV) = "9" OR "E"
            COMPUTE LS-RECV-INT = SY-DIGITS(LS-RECV) - SY-SCALE(LS-RECV)
            IF LS-SEND-KIND = "N" AND LS-SEND-INT > LS-RECV-INT
                PERFORM REPORT-DIGITS
            END-IF
            IF LS-SEND-KIND = "N" AND SY-CATEGORY(LS-RECV) = "9"
               AND SY-SCALE(LS-RECV) >= 0
               AND LS-SEND-DEC > SY-SCALE(LS-RECV)
                PERFORM REPORT-DECIMALS
            END-IF
            IF LS-SEND-KIND = "D"
                IF SY-CATEGORY(LS-SEND-SYM) = "9"
                   AND LS-SEND-INT > LS-RECV-INT
                    PERFORM REPORT-DIGITS
                END-IF
                *> PLB-M018: a signed number into an unsigned one.
                IF SY-CATEGORY(LS-SEND-SYM) = "9"
                   AND SY-CATEGORY(LS-RECV) = "9"
                   AND SY-SIGNED(LS-SEND-SYM) = "Y"
                   AND SY-SIGNED(LS-RECV) NOT = "Y"
                   AND RL-ENABLED(LS-RULE-SIGN-LOST) = "Y"
                    PERFORM REPORT-SIGN-LOST
                END-IF
            END-IF
    END-EVALUATE.

*> PLB-M018: the receiver keeps the sender's absolute value; a negative
*> amount comes out positive.
REPORT-SIGN-LOST.
    MOVE SPACES TO LS-MESSAGE
    MOVE LS-RULE-SIGN-LOST TO LS-RULE
    STRING "MOVE of signed " DELIMITED BY SIZE
           SY-NAME(LS-SEND-SYM) DELIMITED BY SPACE
           " to unsigned " DELIMITED BY SIZE
           SY-NAME(LS-RECV) DELIMITED BY SPACE
           " drops its sign: -5 is stored as 5" DELIMITED BY SIZE
        INTO LS-MESSAGE
    PERFORM REPORT-FINDING
    MOVE SPACES TO LS-MESSAGE.

*> PLB-C046: sender and receiver share storage, and are not the same
*> item (PLB-C033). Subscripted items stand for their whole table here,
*> so they are not compared.
CHECK-OVERLAP.
    IF RL-ENABLED(LS-RULE-OVERLAP) NOT = "Y" OR LS-SEND-KIND NOT = "D"
       OR LS-SEND-SYM = LS-RECV OR LS-SEND-SUBSCRIPTED = "Y"
       OR RF-SUBSCRIPTED(LS-R) = "Y" OR SY-SIZE(LS-SEND-SYM) = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-SPAN-OVERLAP" USING WS-SPANS LS-SEND-SYM LS-RECV
        LS-OVERLAP
    IF LS-OVERLAP = "Y"
        MOVE SPACES TO LS-MESSAGE
        STRING "MOVE from " DELIMITED BY SIZE
               SY-NAME(LS-SEND-SYM) DELIMITED BY SPACE
               " to " DELIMITED BY SIZE
               SY-NAME(LS-RECV) DELIMITED BY SPACE
               ", which share storage: the result is undefined"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        MOVE LS-RULE-OVERLAP TO LS-RULE
        PERFORM REPORT-FINDING
        MOVE SPACES TO LS-MESSAGE
    END-IF.

*> LS-JUSTIFIED = "Y" when the receiver has a JUSTIFIED clause.
CHECK-JUSTIFIED.
    MOVE "N" TO LS-JUSTIFIED
    MOVE ND-FIRST(SY-NODE(LS-RECV)) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "CLAU"
           AND ND-DETAIL(LS-CHILD) = "JUSTIFIED"
            MOVE "Y" TO LS-JUSTIFIED
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

REPORT-LITERAL-CHARACTERS.
    MOVE LS-SEND-SIZE TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE SY-SIZE(LS-RECV) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    MOVE LS-RULE-TRUNCATION TO LS-RULE
    STRING "MOVE truncates a " LS-A-TEXT(1:LS-A-LEN)
           "-character literal to fit " DELIMITED BY SIZE
           SY-NAME(LS-RECV) DELIMITED BY SPACE
           " (" LS-B-TEXT(1:LS-B-LEN) " characters)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    PERFORM REPORT-FINDING.

REPORT-ITEM-CHARACTERS.
    MOVE LS-SEND-SIZE TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE SY-SIZE(LS-RECV) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    MOVE LS-RULE-NARROWING TO LS-RULE
    STRING "MOVE truncates " DELIMITED BY SIZE
           SY-NAME(LS-SEND-SYM) DELIMITED BY SPACE
           " (" LS-A-TEXT(1:LS-A-LEN) " characters) to fit "
           DELIMITED BY SIZE
           SY-NAME(LS-RECV) DELIMITED BY SPACE
           " (" LS-B-TEXT(1:LS-B-LEN) " characters)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    PERFORM REPORT-FINDING.

*> PLB-C039: a number with decimal places is not a valid sender at all
*> (the standard allows only integers, and GnuCOBOL rejects the MOVE).
*> PLB-M016: a signed integer loses its sign silently.
REPORT-NUMERIC-TEXT.
    MOVE SPACES TO LS-MESSAGE
    IF SY-SCALE(LS-SEND-SYM) > 0
        MOVE LS-RULE-DECIMAL-TEXT TO LS-RULE
        STRING "MOVE of " DELIMITED BY SIZE
               SY-NAME(LS-SEND-SYM) DELIMITED BY SPACE
               ", which has decimal places, to alphanumeric "
               DELIMITED BY SIZE
               SY-NAME(LS-RECV) DELIMITED BY SPACE
               " is not a valid MOVE: only integers may be moved to"
               " alphanumeric items" DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        MOVE LS-RULE-SIGNED-TEXT TO LS-RULE
        STRING "MOVE of signed " DELIMITED BY SIZE
               SY-NAME(LS-SEND-SYM) DELIMITED BY SPACE
               " to alphanumeric " DELIMITED BY SIZE
               SY-NAME(LS-RECV) DELIMITED BY SPACE
               " drops its sign: -5 and 5 give the same text"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    PERFORM REPORT-FINDING.

REPORT-DIGITS.
    MOVE LS-SEND-INT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE LS-RECV-INT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    MOVE LS-RULE-TRUNCATION TO LS-RULE
    IF LS-SEND-KIND = "N"
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-SENDER LS-SEND-NAME
            LS-LEN
    ELSE
        MOVE SY-NAME(LS-SEND-SYM) TO LS-SEND-NAME
    END-IF
    STRING "MOVE loses high-order digits: " DELIMITED BY SIZE
           LS-SEND-NAME DELIMITED BY SPACE
           " has " LS-A-TEXT(1:LS-A-LEN) " integer digits, "
           DELIMITED BY SIZE
           SY-NAME(LS-RECV) DELIMITED BY SPACE
           " has " LS-B-TEXT(1:LS-B-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE
    PERFORM REPORT-FINDING.

REPORT-DECIMALS.
    MOVE LS-SEND-DEC TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE SY-SCALE(LS-RECV) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    MOVE LS-RULE-TRUNCATION TO LS-RULE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-SENDER LS-SEND-NAME LS-LEN
    STRING "MOVE loses low-order digits: " DELIMITED BY SIZE
           LS-SEND-NAME DELIMITED BY SPACE
           " has " LS-A-TEXT(1:LS-A-LEN) " decimal places, "
           DELIMITED BY SIZE
           SY-NAME(LS-RECV) DELIMITED BY SPACE
           " has " LS-B-TEXT(1:LS-B-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE
    PERFORM REPORT-FINDING.

REPORT-FINDING.
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-T LS-MESSAGE.
END PROGRAM PLB-RULE-C008.

*> PLB-C041 write-from-truncation: WRITE record FROM item and REWRITE
*> record FROM item move the item to the record, as MOVE does, and an
*> item longer than the record loses its last bytes in the file.
*>
*> READ ... INTO a shorter item is not reported: reading only the start
*> of a record (the first columns of a control card) is common and
*> meant. Reference-modified items, items of unknown size, and items
*> whose size changes at run time (OCCURS DEPENDING ON) are not
*> checked.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C041.
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
01  LS-VERB                 PIC X(12).
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-JOIN                 PIC 9(9) COMP-5.
01  LS-SENDER-SIZE          PIC 9(9) COMP-5.
01  LS-RECEIVER-SIZE        PIC 9(9) COMP-5.
01  LS-SENDER-NAME          PIC X(31).
01  LS-RECEIVER-NAME        PIC X(31).
01  LS-ITEM                 PIC 9(9) COMP-5.
01  LS-FILE-NAME            PIC X(31).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-A-TEXT               PIC X(20).
01  LS-A-LEN                PIC 9(9) COMP-5.
01  LS-B-TEXT               PIC X(20).
01  LS-B-LEN                PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C041" LS-RULE
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
            MOVE ND-DETAIL(LS-NODE) TO LS-VERB
            EVALUATE LS-VERB
                WHEN "WRITE" WHEN "REWRITE"
                    MOVE "FROM" TO LS-WORD
                    PERFORM FIND-JOIN
                    IF LS-JOIN > 0
                        PERFORM CHECK-FROM
                    END-IF
            END-EVALUATE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> LS-JOIN: the token of FROM (LS-WORD) outside parentheses, or 0.
FIND-JOIN.
    MOVE 0 TO LS-JOIN LS-LEVEL
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL = 0 AND TK-IS-WORD(LS-T)
             AND WS-TOKEN-REF(LS-T) = 0
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-FILE-NAME
                    LS-LEN
                IF FUNCTION UPPER-CASE(LS-FILE-NAME) = LS-WORD
                    MOVE LS-T TO LS-JOIN
                    EXIT PERFORM
                END-IF
        END-EVALUATE
    END-PERFORM.

*> LS-ITEM: the data item whose reference starts at token LS-T, or 0.
ITEM-AT.
    MOVE 0 TO LS-ITEM
    IF WS-TOKEN-REF(LS-T) > 0
        MOVE WS-TOKEN-REF(LS-T) TO LS-R
        IF RF-KIND(LS-R) = "D" AND RF-REFMOD(LS-R) = "N"
            MOVE RF-SYMBOL(LS-R) TO LS-ITEM
            IF SY-SIZE(LS-ITEM) = 0 OR SY-VARIABLE(LS-ITEM) = "Y"
                MOVE 0 TO LS-ITEM
            END-IF
        END-IF
    END-IF.

*> WRITE record FROM item.
CHECK-FROM.
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    PERFORM ITEM-AT
    IF LS-ITEM = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SY-SIZE(LS-ITEM) TO LS-RECEIVER-SIZE
    MOVE SY-NAME(LS-ITEM) TO LS-RECEIVER-NAME
    COMPUTE LS-T = LS-JOIN + 1
    PERFORM ITEM-AT
    IF LS-ITEM = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SY-SIZE(LS-ITEM) TO LS-SENDER-SIZE
    MOVE SY-NAME(LS-ITEM) TO LS-SENDER-NAME
    IF LS-SENDER-SIZE > LS-RECEIVER-SIZE
        PERFORM REPORT-LOSS
    END-IF.

REPORT-LOSS.
    MOVE LS-SENDER-SIZE TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE LS-RECEIVER-SIZE TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING FUNCTION TRIM(LS-VERB) DELIMITED BY SIZE
           " moves " DELIMITED BY SIZE
           FUNCTION TRIM(LS-SENDER-NAME) DELIMITED BY SIZE
           " (" LS-A-TEXT(1:LS-A-LEN) " bytes) to " DELIMITED BY SIZE
           LS-RECEIVER-NAME DELIMITED BY SPACE
           " (" LS-B-TEXT(1:LS-B-LEN) " bytes), which loses its end"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-JOIN LS-MESSAGE.
END PROGRAM PLB-RULE-C041.

*> PLB-C043 pointer-not-reset is checked here too: STRING ... WITH
*> POINTER p and UNSTRING ... WITH POINTER p start at p and leave it past
*> what they handled. A pointer that no statement of the program sets
*> (only a VALUE clause, or nothing) is reported: the statement starts
*> where the previous run left it. A pointer set by a caller, as in a
*> paragraph that appends to a line being built, is fine.
*>
*> PLB-C042 inspect-count-not-reset: INSPECT ... TALLYING count FOR
*> ... adds to count; it does not start it at zero. A count that the
*> paragraph does not set before the INSPECT (MOVE ZERO TO count,
*> INITIALIZE of it or of a group around it, ...) carries whatever it
*> held: the total of an earlier INSPECT, or a loop index's last value.
*>
*> Only the paragraph of the INSPECT is read, and only plain stores
*> count: ADD 1 TO count adds as INSPECT does. A count passed BY
*> REFERENCE to a CALL before the INSPECT counts as set.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C042.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-POINTER         PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-START                PIC 9(9) COMP-5.
01  LS-END                  PIC 9(9) COMP-5.
01  LS-UNIT                 PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-COUNT                PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-LEVEL                PIC S9(4) COMP-5.
01  LS-TALLYING             PIC X.
01  LS-FOUND                PIC X.
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
COPY "plbflow.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-FLOW PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C042" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C043" LS-RULE-POINTER
    IF (RL-ENABLED(LS-RULE) NOT = "Y"
        AND RL-ENABLED(LS-RULE-POINTER) NOT = "Y") OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
            EVALUATE ND-DETAIL(LS-NODE)
                WHEN "INSPECT"
                    PERFORM CHECK-INSPECT
                WHEN "STRING" WHEN "UNSTRING"
                    PERFORM CHECK-POINTER
            END-EVALUATE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> PLB-C043: the item after WITH POINTER (or POINTER), outside
*> parentheses.
CHECK-POINTER.
    IF RL-ENABLED(LS-RULE-POINTER) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-LEVEL
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL = 0 AND TK-IS-WORD(LS-T)
             AND WS-TOKEN-REF(LS-T) = 0
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                IF FUNCTION UPPER-CASE(LS-WORD) = "POINTER"
                    *> plumbline: ignore varying-control-changed -- steps past the tokens just read
                    ADD 1 TO LS-T
                    IF WS-TOKEN-REF(LS-T) > 0
                        MOVE WS-TOKEN-REF(LS-T) TO LS-R
                        IF RF-KIND(LS-R) = "D"
                            MOVE RF-SYMBOL(LS-R) TO LS-COUNT
                            PERFORM FIND-SET-ANYWHERE
                            IF LS-FOUND = "N"
                                PERFORM REPORT-POINTER
                            END-IF
                        END-IF
                    END-IF
                    EXIT PERFORM
                END-IF
        END-EVALUATE
    END-PERFORM.

*> LS-FOUND = "Y" when a statement of the file stores into the pointer
*> or a group around it (role D), or may (role X). The STRING and
*> UNSTRING statements themselves only move it on (role B).
FIND-SET-ANYWHERE.
    MOVE 1 TO LS-START
    MOVE TK-COUNT TO LS-END
    PERFORM FIND-RESET.

REPORT-POINTER.
    MOVE SPACES TO LS-MESSAGE
    STRING FUNCTION TRIM(ND-DETAIL(LS-NODE)) DELIMITED BY SIZE
           " starts at the value of " DELIMITED BY SIZE
           SY-NAME(LS-COUNT) DELIMITED BY SPACE
           ", which no statement of the program sets: only its first"
           " run starts where its VALUE says" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-POINTER LS-T LS-MESSAGE.

*> LS-FOUND = "Y" when item LS-COUNT is set before statement LS-NODE
*> in its paragraph, or in a paragraph leading into it.
CHECK-SET-BEFORE.
    PERFORM PARAGRAPH-START
    MOVE ND-TOK-FIRST(LS-NODE) TO LS-END
    PERFORM FIND-RESET
    IF LS-FOUND = "N" AND LS-UNIT > 0
        PERFORM FIND-RESET-BEFORE
    END-IF.

*> The counts of the TALLYING phrase: each data item followed by FOR.
CHECK-INSPECT.
    MOVE "N" TO LS-TALLYING
    MOVE 0 TO LS-LEVEL
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T)
                SUBTRACT 1 FROM LS-LEVEL
            WHEN LS-LEVEL > 0
                CONTINUE
            WHEN WS-TOKEN-REF(LS-T) > 0 AND LS-TALLYING = "Y"
                PERFORM COUNT-AT-T
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                EVALUATE FUNCTION UPPER-CASE(LS-WORD)
                    WHEN "TALLYING"
                        MOVE "Y" TO LS-TALLYING
                    WHEN "REPLACING" WHEN "CONVERTING"
                        MOVE "N" TO LS-TALLYING
                END-EVALUATE
        END-EVALUATE
    END-PERFORM.

*> The data item at LS-T is a count when the next word is FOR (past
*> its subscripts).
COUNT-AT-T.
    MOVE WS-TOKEN-REF(LS-T) TO LS-R
    IF RF-KIND(LS-R) NOT = "D"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-NEXT = RF-LAST(LS-R) + 1
    IF LS-NEXT > ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-NEXT LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "FOR"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-COUNT
    PERFORM CHECK-SET-BEFORE
    IF LS-FOUND = "N" AND RL-ENABLED(LS-RULE) = "Y"
        MOVE SPACES TO LS-MESSAGE
        STRING "INSPECT adds to " DELIMITED BY SIZE
               SY-NAME(LS-COUNT) DELIMITED BY SPACE
               ", which this paragraph does not set before it"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE LS-T LS-MESSAGE
    END-IF.

*> LS-START: the first token of the paragraph (or section, or start of
*> the division) the INSPECT is in.
PARAGRAPH-START.
    MOVE 1 TO LS-START
    MOVE 0 TO LS-UNIT
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF ND-TOK-FIRST(FU-NODE(LS-U)) <= ND-TOK-FIRST(LS-NODE)
           AND ND-TOK-FIRST(FU-NODE(LS-U)) >= LS-START
            MOVE ND-TOK-FIRST(FU-NODE(LS-U)) TO LS-START
            MOVE LS-U TO LS-UNIT
        END-IF
    END-PERFORM.

*> A unit that leads into the INSPECT's (LS-UNIT) may set the count
*> anywhere: one that falls into it, goes to it, or performs it.
FIND-RESET-BEFORE.
    PERFORM VARYING LS-V FROM 1 BY 1
            UNTIL LS-V > FU-COUNT OR LS-FOUND = "Y"
        IF FU-NEXT(LS-V) = LS-UNIT AND FU-FALLS(LS-V) = "Y"
           AND FU-FLOWED(LS-V) = "Y"
            PERFORM FIND-RESET-IN-UNIT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1
            UNTIL LS-E > FE-COUNT OR LS-FOUND = "Y"
        IF FE-TO(LS-E) = LS-UNIT
           AND (FE-KIND(LS-E) = "P" OR FE-KIND(LS-E) = "G")
            MOVE FE-FROM(LS-E) TO LS-V
            PERFORM FIND-RESET-IN-UNIT
        END-IF
    END-PERFORM.

FIND-RESET-IN-UNIT.
    MOVE ND-TOK-FIRST(FU-NODE(LS-V)) TO LS-START
    COMPUTE LS-END = ND-TOK-LAST(FU-NODE(LS-V)) + 1
    PERFORM FIND-RESET.

*> LS-FOUND = "Y" when a reference from LS-START up to LS-END stores
*> into the count or a group around it (role D), or may (role X).
FIND-RESET.
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > RF-COUNT
        IF RF-TOKEN(LS-Q) >= LS-START
           AND RF-TOKEN(LS-Q) < LS-END
           AND RF-KIND(LS-Q) = "D"
           AND (RF-ROLE(LS-Q) = "D" OR RF-ROLE(LS-Q) = "X")
            MOVE LS-COUNT TO LS-UP
            PERFORM UNTIL LS-UP = 0
                IF RF-SYMBOL(LS-Q) = LS-UP
                    MOVE "Y" TO LS-FOUND
                    EXIT PARAGRAPH
                END-IF
                MOVE SY-PARENT(LS-UP) TO LS-UP
            END-PERFORM
        END-IF
    END-PERFORM.
END PROGRAM PLB-RULE-C042.
