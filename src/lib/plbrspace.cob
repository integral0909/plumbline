*> ---------------------------------------------------------------
*> plbrspace: PLB-C060 spaces-into-numeric, PLB-C085 zeros-into-packed.
*>
*> MOVE SPACES (or SPACE, or a literal of spaces) to a group that
*> contains numeric items, when a statement after it in the paragraph
*> reads one of them, or the group, before anything gives it a value:
*>
*>     01  WS-TOTALS.
*>         05  WS-COUNT        PIC S9(7)   COMP-3.
*>         05  WS-AMOUNT       PIC S9(9)V99 COMP-3.
*>     ...
*>     MOVE SPACES TO WS-TOTALS                    *> reported
*>     ADD 1 TO WS-COUNT
*>
*> A group move copies the spaces byte for byte. In a packed-decimal
*> or zoned-decimal (DISPLAY) item they are not a valid number, and the
*> first arithmetic on it fails on z/OS (a data exception, S0C7); in a
*> binary item they are a meaningless number. The compiler rejects
*> MOVE SPACES to a numeric item itself, but not to its group.
*> INITIALIZE gives each item a value of its own kind.
*>
*> Clearing a record with spaces and then filling it, or reading into
*> it, is common and fine; so the statements after the MOVE, in source
*> order to the end of the paragraph, are followed. A statement that
*> gives the item, a group around it, or the whole group a value ends
*> the search for that item, and a READ or RETURN (which may fill the
*> record), a PERFORM, or a CALL (which may give it values elsewhere)
*> ends it for all, as does a statement that gives a value to a
*> RENAMES item or to an item under a REDEFINES, which may share the
*> storage. A read of the item (ADD 1 TO it, a comparison, ...) before
*> then is reported, with its line, and so is a read of a group around
*> a packed or binary item (WRITE of the record, MOVE of the group),
*> which copies the bad bytes on; a DISPLAY item read with its group
*> only shows blanks, as print lines do. Branches are not told apart.
*>
*> PLB-C085 is the same for MOVE ZERO (ZEROS, ZEROES, or a literal of
*> zeros) to a group, and its packed-decimal and binary items only: the
*> character 0 in each byte is a valid DISPLAY number, but no packed or
*> binary zero. With GnuCOBOL 3.2 a COMP-3 item so filled fails a
*> NUMERIC test and ADD 1 makes it 30304.
*>
*> A group named after FILE STATUS in a SELECT is left alone by both:
*> the I/O statements give it its values.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C060.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> The FILE STATUS items of the SELECT statements, with their programs.
78  STATUS-MAX              VALUE 512.
01  WS-STATUS-COUNT         PIC 9(9) COMP-5.
01  WS-STATUS-NAME          PIC X(31) OCCURS STATUS-MAX TIMES.
01  WS-STATUS-PROGRAM       PIC 9(9) COMP-5 OCCURS STATUS-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-IS-STATUS            PIC X.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-ZEROS           PIC 9(4) COMP-5.
*> What the MOVE fills the group with: S spaces, Z zeros.
01  LS-FILL                 PIC X.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-FIRST-REF            PIC 9(9) COMP-5 VALUE 1.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-INSIDE               PIC X.
01  LS-PACKED-COUNT         PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
*> The numeric items of the group still holding spaces.
78  LS-PACKED-MAX           VALUE 200.
01  LS-PACKED               PIC 9(9) COMP-5 OCCURS LS-PACKED-MAX TIMES.
01  LS-SPACES               PIC X OCCURS LS-PACKED-MAX TIMES.
01  LS-LEFT                 PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-PARA                 PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-X                    PIC 9(9) COMP-5.
01  LS-USE                  PIC 9(9) COMP-5.
01  LS-USED                 PIC 9(9) COMP-5.
01  LS-ABOVE                PIC X.
01  LS-NUMERIC              PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C060" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C085" LS-RULE-ZEROS
    IF (RL-ENABLED(LS-RULE) NOT = "Y"
        AND RL-ENABLED(LS-RULE-ZEROS) NOT = "Y")
       OR AS-COUNT = 0 OR RF-COUNT = 0
        GOBACK
    END-IF
    MOVE 0 TO WS-STATUS-COUNT
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "SELE"
            PERFORM COLLECT-STATUS
        END-IF
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "MOVE"
            PERFORM CHECK-MOVE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> MOVE SPACE[S] TO receiver...: each group receiver.
CHECK-MOVE.
    COMPUTE LS-T = ND-TOK-FIRST(LS-NODE) + 1
    IF LS-T >= ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    EVALUATE TRUE
        WHEN TK-IS-WORD(LS-T)
             AND (LS-TEXT = "SPACE" OR LS-TEXT = "SPACES")
            MOVE "S" TO LS-FILL
        WHEN TK-IS-ALNUM(LS-T) AND TK-PREFIX(LS-T) = SPACES
             AND LS-LEN > 0 AND LS-TEXT(1:LS-LEN) = SPACES
            MOVE "S" TO LS-FILL
        WHEN TK-IS-WORD(LS-T)
             AND (LS-TEXT = "ZERO" OR LS-TEXT = "ZEROS"
                  OR LS-TEXT = "ZEROES")
            MOVE "Z" TO LS-FILL
        WHEN TK-IS-ALNUM(LS-T) AND TK-PREFIX(LS-T) = SPACES
             AND LS-LEN > 0
             AND FUNCTION TRIM(LS-TEXT(1:LS-LEN) TRAILING) IS NUMERIC
             AND FUNCTION NUMVAL(LS-TEXT(1:LS-LEN)) = 0
             AND LS-TEXT(1:LS-LEN) NOT = SPACES
            MOVE "Z" TO LS-FILL
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    IF LS-FILL = "S" AND RL-ENABLED(LS-RULE) NOT = "Y"
       OR LS-FILL = "Z" AND RL-ENABLED(LS-RULE-ZEROS) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    *> The receivers: the references after TO, not in subscripts.
    COMPUTE LS-TO = LS-T + 1
    PERFORM UNTIL LS-FIRST-REF > RF-COUNT
            OR RF-TOKEN(LS-FIRST-REF) >= ND-TOK-FIRST(LS-NODE)
        ADD 1 TO LS-FIRST-REF
    END-PERFORM
    PERFORM VARYING LS-R FROM LS-FIRST-REF BY 1
            UNTIL LS-R > RF-COUNT
               OR RF-TOKEN(LS-R) > ND-TOK-LAST(LS-NODE)
        IF RF-TOKEN(LS-R) > LS-TO AND RF-KIND(LS-R) = "D"
           AND RF-SYMBOL(LS-R) > 0 AND RF-REFMOD(LS-R) = "N"
            PERFORM TEST-INSIDE
            IF LS-INSIDE = "N"
                IF SY-CATEGORY(RF-SYMBOL(LS-R)) = "G"
                    PERFORM TEST-STATUS
                    IF LS-IS-STATUS = "N"
                        PERFORM CHECK-GROUP
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> SELECT ... [FILE] STATUS [IS] name, of SELECT node LS-NODE.
COLLECT-STATUS.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "STATUS"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
                IF LS-TEXT = "IS"
                    ADD 1 TO LS-K
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                END-IF
                IF TK-IS-WORD(LS-K) AND WS-STATUS-COUNT < STATUS-MAX
                    ADD 1 TO WS-STATUS-COUNT
                    MOVE LS-TEXT TO WS-STATUS-NAME(WS-STATUS-COUNT)
                    MOVE LS-NODE TO LS-UP
                    PERFORM UNTIL LS-UP = 0
                        IF ND-KIND(LS-UP) = "PROG"
                            EXIT PERFORM
                        END-IF
                        MOVE ND-PARENT(LS-UP) TO LS-UP
                    END-PERFORM
                    MOVE LS-UP TO WS-STATUS-PROGRAM(WS-STATUS-COUNT)
                END-IF
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> LS-IS-STATUS = "Y" when the receiver of reference LS-R is a FILE
*> STATUS item.
TEST-STATUS.
    MOVE "N" TO LS-IS-STATUS
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > WS-STATUS-COUNT
        IF WS-STATUS-NAME(LS-K) = SY-NAME(RF-SYMBOL(LS-R))
           AND WS-STATUS-PROGRAM(LS-K) = SY-PROGRAM(RF-SYMBOL(LS-R))
            MOVE "Y" TO LS-IS-STATUS
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-INSIDE = "Y" when reference LS-R is in the subscripts of another.
TEST-INSIDE.
    MOVE "N" TO LS-INSIDE
    PERFORM VARYING LS-I FROM LS-FIRST-REF BY 1 UNTIL LS-I >= LS-R
        IF RF-TOKEN(LS-I) < RF-TOKEN(LS-R)
           AND RF-LAST(LS-I) >= RF-TOKEN(LS-R)
            MOVE "Y" TO LS-INSIDE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> The numeric items in group LS-G: they follow it in the symbol
*> table, as long as LS-G is above them. Numeric means the picture's
*> category 9, or a numeric usage without a picture (COMP-1, BINARY-
*> LONG, ...).
CHECK-GROUP.
    MOVE RF-SYMBOL(LS-R) TO LS-G
    MOVE 0 TO LS-PACKED-COUNT
    PERFORM VARYING LS-I FROM LS-G BY 1 UNTIL LS-I >= SY-COUNT
        COMPUTE LS-UP = LS-I + 1
        PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-G
            MOVE SY-PARENT(LS-UP) TO LS-UP
        END-PERFORM
        IF LS-UP = 0
            EXIT PERFORM
        END-IF
        MOVE "N" TO LS-NUMERIC
        EVALUATE SY-CATEGORY(LS-I + 1)
            WHEN "9"
                MOVE "Y" TO LS-NUMERIC
            WHEN "U"
                IF SY-USAGE(LS-I + 1) NOT = "INDEX"
                   AND SY-USAGE(LS-I + 1) NOT = "POINTER"
                   AND SY-USAGE(LS-I + 1) NOT = "PROCEDURE-POINTER"
                   AND SY-USAGE(LS-I + 1) NOT = "PROGRAM-POINTER"
                   AND SY-USAGE(LS-I + 1) NOT = "OBJECT-REFERENCE"
                    MOVE "Y" TO LS-NUMERIC
                END-IF
        END-EVALUATE
        *> Zeros are a valid DISPLAY number.
        IF LS-FILL = "Z" AND LS-NUMERIC = "Y"
           AND (SY-USAGE(LS-I + 1) = SPACES
                OR SY-USAGE(LS-I + 1) = "DISPLAY")
            MOVE "N" TO LS-NUMERIC
        END-IF
        IF LS-NUMERIC = "Y" AND LS-PACKED-COUNT < LS-PACKED-MAX
            ADD 1 TO LS-PACKED-COUNT
            COMPUTE LS-PACKED(LS-PACKED-COUNT) = LS-I + 1
            MOVE "Y" TO LS-SPACES(LS-PACKED-COUNT)
        END-IF
    END-PERFORM
    IF LS-PACKED-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM FOLLOW-PARAGRAPH
    IF LS-USE > 0
        PERFORM REPORT-USE
    END-IF.

*> The statements after the MOVE in its paragraph, in source order,
*> until every numeric item has a value again or one is read: LS-USE,
*> the reference that reads, and LS-USED, the item it reaches.
FOLLOW-PARAGRAPH.
    MOVE 0 TO LS-USE LS-USED
    MOVE LS-PACKED-COUNT TO LS-LEFT
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
    PERFORM VARYING LS-S FROM LS-NODE BY 1
            UNTIL LS-S >= AS-COUNT OR LS-USE > 0 OR LS-LEFT = 0
        IF ND-TOK-FIRST(LS-S + 1) > ND-TOK-LAST(LS-PARA)
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-S + 1) = "STMT"
            PERFORM FOLLOW-STATEMENT
        END-IF
    END-PERFORM.

*> Statement LS-S + 1: reads first, then what it gives values to.
FOLLOW-STATEMENT.
    COMPUTE LS-Q = LS-S + 1
    EVALUATE ND-DETAIL(LS-Q)
        WHEN "READ" WHEN "RETURN" WHEN "PERFORM" WHEN "CALL"
            MOVE 0 TO LS-LEFT
            EXIT PARAGRAPH
    END-EVALUATE
    PERFORM VARYING LS-X FROM LS-FIRST-REF BY 1
            UNTIL LS-X > RF-COUNT OR LS-USE > 0
        IF RF-TOKEN(LS-X) > ND-TOK-LAST(LS-Q)
            EXIT PERFORM
        END-IF
        IF RF-STMT(LS-X) = LS-Q AND RF-KIND(LS-X) = "D"
           AND RF-SYMBOL(LS-X) > 0
           AND (RF-ROLE(LS-X) = "U" OR RF-ROLE(LS-X) = "B")
            PERFORM MARK-READ
        END-IF
    END-PERFORM
    IF LS-USE > 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-X FROM LS-FIRST-REF BY 1 UNTIL LS-X > RF-COUNT
        IF RF-TOKEN(LS-X) > ND-TOK-LAST(LS-Q)
            EXIT PERFORM
        END-IF
        IF RF-STMT(LS-X) = LS-Q AND RF-KIND(LS-X) = "D"
           AND RF-SYMBOL(LS-X) > 0
           AND (RF-ROLE(LS-X) = "D" OR RF-ROLE(LS-X) = "X")
            PERFORM MARK-SET
        END-IF
    END-PERFORM.

*> Reference LS-X reads a numeric item still holding spaces, or a group
*> around one that is not DISPLAY.
MARK-READ.
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > LS-PACKED-COUNT
        IF LS-SPACES(LS-P) = "Y"
            PERFORM TEST-ABOVE
            IF LS-ABOVE = "Y" AND RF-SYMBOL(LS-X) NOT = LS-PACKED(LS-P)
               AND (SY-USAGE(LS-PACKED(LS-P)) = SPACES
                    OR SY-USAGE(LS-PACKED(LS-P)) = "DISPLAY")
                MOVE "N" TO LS-ABOVE
            END-IF
            IF LS-ABOVE = "Y"
                MOVE LS-X TO LS-USE
                MOVE LS-PACKED(LS-P) TO LS-USED
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> Reference LS-X gives a value to numeric items (itself or a group
*> around them); to a RENAMES item, or one under a REDEFINES, maybe
*> to any of them.
MARK-SET.
    MOVE RF-SYMBOL(LS-X) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF SY-CATEGORY(LS-UP) = "R" OR SY-REDEFINES(LS-UP) > 0
            MOVE 0 TO LS-LEFT
            EXIT PARAGRAPH
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > LS-PACKED-COUNT
        IF LS-SPACES(LS-P) = "Y"
            PERFORM TEST-ABOVE
            IF LS-ABOVE = "Y"
                MOVE "N" TO LS-SPACES(LS-P)
                SUBTRACT 1 FROM LS-LEFT
            END-IF
        END-IF
    END-PERFORM.

*> LS-ABOVE = "Y" when the item of reference LS-X is numeric item
*> LS-PACKED(LS-P) or a group around it.
TEST-ABOVE.
    MOVE "N" TO LS-ABOVE
    MOVE LS-PACKED(LS-P) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF LS-UP = RF-SYMBOL(LS-X)
            MOVE "Y" TO LS-ABOVE
            EXIT PERFORM
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

REPORT-USE.
    MOVE SL-LINE-NO(TK-SRC-LINE(RF-TOKEN(LS-USE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    IF LS-FILL = "Z"
        STRING "MOVE ZEROS to " DELIMITED BY SIZE
               SY-NAME(LS-G) DELIMITED BY SPACE
               " puts the character 0, not a zero, in its " DELIMITED BY SIZE
               SY-USAGE(LS-USED) DELIMITED BY SPACE
               " item " DELIMITED BY SIZE
               SY-NAME(LS-USED) DELIMITED BY SPACE
               ", which line " LS-NUM-TEXT(1:LS-NUM-LEN)
               DELIMITED BY SIZE
               " reads before anything gives it a value"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-ZEROS RF-TOKEN(LS-R)
            LS-MESSAGE
        EXIT PARAGRAPH
    END-IF
    STRING "MOVE SPACES to " DELIMITED BY SIZE
           SY-NAME(LS-G) DELIMITED BY SPACE
           " puts spaces in its numeric item " DELIMITED BY SIZE
           SY-NAME(LS-USED) DELIMITED BY SPACE
           ", which line " LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " reads before anything gives it a value" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C060.
