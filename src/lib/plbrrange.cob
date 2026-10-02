*> ---------------------------------------------------------------
*> plbrrange: subscripts and reference modifiers written as numbers.
*>
*>   PLB-C023  subscript-out-of-range
*>   PLB-C024  refmod-out-of-range
*>
*> Only literal integers are checked: TABLE-ITEM (11) of a table that
*> occurs 10 times, or NAME (5:10) of a PIC X(8) item. A subscript or
*> position computed at run time is not; neither is a subscript list
*> that does not give one subscript per dimension (C009 and the
*> compiler report those).
*>
*> The dimensions of an item are the OCCURS of the item itself and of
*> the groups it belongs to, outermost first, which is the order its
*> subscripts are written in.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-RANGES.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  DIM-MAX                 VALUE 16.
LOCAL-STORAGE SECTION.
01  LS-RULE-SUBSCRIPT       PIC 9(4) COMP-5.
01  LS-RULE-REFMOD          PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-CLOSE                PIC 9(9) COMP-5.
01  LS-LEVEL                PIC S9(9) COMP-5.
01  LS-COLON                PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> Dimensions of the item, outermost first: their OCCURS counts.
01  LS-DIM-COUNT            PIC 9(4) COMP-5.
01  LS-DIM-OCCURS           PIC 9(9) COMP-5 OCCURS DIM-MAX TIMES.
*> Subscripts written: the value, or -1 when it is not a literal.
01  LS-SUB-COUNT            PIC 9(4) COMP-5.
01  LS-SUB-VALUE            PIC S9(9) COMP-5 OCCURS DIM-MAX TIMES.
01  LS-SUB-TOKEN            PIC 9(9) COMP-5 OCCURS DIM-MAX TIMES.
01  LS-TOO-MANY             PIC X.
01  LS-VALUE                PIC S9(9) COMP-5.
01  LS-OFFSET               PIC S9(9) COMP-5.
01  LS-LENGTH               PIC S9(9) COMP-5.
01  LS-CHARS                PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C023" LS-RULE-SUBSCRIPT
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C024" LS-RULE-REFMOD
    IF RL-ENABLED(LS-RULE-SUBSCRIPT) NOT = "Y"
       AND RL-ENABLED(LS-RULE-REFMOD) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D"
           AND (RF-SUBSCRIPTED(LS-R) = "Y" OR RF-REFMOD(LS-R) = "Y")
            MOVE RF-SYMBOL(LS-R) TO LS-S
            PERFORM CHECK-REFERENCE
        END-IF
    END-PERFORM
    GOBACK.

*> Find the parenthesized groups after the name and its qualifiers.
CHECK-REFERENCE.
    MOVE RF-TOKEN(LS-R) TO LS-T
    ADD 1 TO LS-T
    PERFORM UNTIL LS-T > RF-LAST(LS-R)
        IF TK-IS-LPAREN(LS-T)
            PERFORM FIND-CLOSE
            IF LS-CLOSE = 0
                EXIT PERFORM
            END-IF
            IF LS-COLON > 0
                PERFORM CHECK-REFMOD
            ELSE
                PERFORM CHECK-SUBSCRIPTS
            END-IF
            COMPUTE LS-T = LS-CLOSE + 1
        ELSE
            ADD 1 TO LS-T
        END-IF
    END-PERFORM.

*> LS-T is on "(": LS-CLOSE = its ")" (0 if none), LS-COLON = the
*> token of a colon at its top level (0 if none).
FIND-CLOSE.
    MOVE 0 TO LS-CLOSE LS-COLON LS-LEVEL
    PERFORM VARYING LS-I FROM 0 BY 1
            UNTIL LS-T + LS-I > RF-LAST(LS-R)
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-T + LS-I)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-T + LS-I)
                SUBTRACT 1 FROM LS-LEVEL
                IF LS-LEVEL = 0
                    COMPUTE LS-CLOSE = LS-T + LS-I
                    EXIT PERFORM
                END-IF
            WHEN TK-IS-COLON(LS-T + LS-I) AND LS-LEVEL = 1
                COMPUTE LS-COLON = LS-T + LS-I
        END-EVALUATE
    END-PERFORM.

*> PLB-C023 ----------------------------------------------------------

CHECK-SUBSCRIPTS.
    IF RL-ENABLED(LS-RULE-SUBSCRIPT) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM COLLECT-DIMENSIONS
    PERFORM COLLECT-SUBSCRIPTS
    IF LS-TOO-MANY = "Y" OR LS-SUB-COUNT NOT = LS-DIM-COUNT
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-SUB-COUNT
        IF LS-SUB-VALUE(LS-I) >= 0
            IF LS-SUB-VALUE(LS-I) < 1
               OR (LS-SUB-VALUE(LS-I) > LS-DIM-OCCURS(LS-I)
                   AND LS-DIM-OCCURS(LS-I) > 0)
                PERFORM REPORT-SUBSCRIPT
            END-IF
        END-IF
    END-PERFORM.

*> The OCCURS of the item and the groups above it, outermost first.
COLLECT-DIMENSIONS.
    MOVE 0 TO LS-DIM-COUNT
    MOVE "N" TO LS-TOO-MANY
    MOVE LS-S TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF SY-OCCURS(LS-UP) > 0
            IF LS-DIM-COUNT >= DIM-MAX
                MOVE "Y" TO LS-TOO-MANY
                EXIT PERFORM
            END-IF
            *> Shift so that the outermost ends up first.
            PERFORM VARYING LS-I FROM LS-DIM-COUNT BY -1 UNTIL LS-I = 0
                MOVE LS-DIM-OCCURS(LS-I) TO LS-DIM-OCCURS(LS-I + 1)
            END-PERFORM
            *> No largest count to check against: 0.
            IF SY-UNBOUNDED(LS-UP) = "Y"
                MOVE 0 TO LS-DIM-OCCURS(1)
            ELSE
                MOVE SY-OCCURS(LS-UP) TO LS-DIM-OCCURS(1)
            END-IF
            ADD 1 TO LS-DIM-COUNT
        END-IF
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> The subscripts between LS-T and LS-CLOSE. A subscript is a literal
*> integer, or anything else (a name, possibly with + or - and a
*> number after it, or ALL), which gets the value -1.
COLLECT-SUBSCRIPTS.
    MOVE 0 TO LS-SUB-COUNT
    MOVE LS-T TO LS-UP
    ADD 1 TO LS-UP
    PERFORM UNTIL LS-UP >= LS-CLOSE
        IF LS-SUB-COUNT >= DIM-MAX
            MOVE "Y" TO LS-TOO-MANY
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-SUB-COUNT
        MOVE LS-UP TO LS-SUB-TOKEN(LS-SUB-COUNT)
        MOVE -1 TO LS-SUB-VALUE(LS-SUB-COUNT)
        IF TK-IS-NUMBER(LS-UP)
            PERFORM LITERAL-VALUE
            MOVE LS-VALUE TO LS-SUB-VALUE(LS-SUB-COUNT)
        END-IF
        *> A parenthesized subscript of its own, as in A (B (1)).
        IF TK-IS-WORD(LS-UP) AND LS-UP + 1 < LS-CLOSE
            IF TK-IS-LPAREN(LS-UP + 1)
                PERFORM SKIP-NESTED-GROUP
            END-IF
        END-IF
        ADD 1 TO LS-UP
        *> A relative subscript: NAME + 1, NAME - 1.
        IF LS-UP < LS-CLOSE AND TK-IS-OPERATOR(LS-UP)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-UP LS-TEXT LS-LEN
            IF LS-TEXT = "+" OR LS-TEXT = "-"
                MOVE -1 TO LS-SUB-VALUE(LS-SUB-COUNT)
                ADD 2 TO LS-UP
            END-IF
        END-IF
    END-PERFORM.

*> LS-UP is on a word followed by "(": move it to the matching ")".
SKIP-NESTED-GROUP.
    MOVE 0 TO LS-LEVEL
    ADD 1 TO LS-UP
    PERFORM UNTIL LS-UP >= LS-CLOSE
        IF TK-IS-LPAREN(LS-UP)
            ADD 1 TO LS-LEVEL
        END-IF
        IF TK-IS-RPAREN(LS-UP)
            SUBTRACT 1 FROM LS-LEVEL
            IF LS-LEVEL = 0
                EXIT PERFORM
            END-IF
        END-IF
        ADD 1 TO LS-UP
    END-PERFORM.

*> LS-VALUE = the value of numeric literal LS-UP when it is an unsigned
*> integer of at most 9 digits, else -1.
LITERAL-VALUE.
    MOVE -1 TO LS-VALUE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-UP LS-TEXT LS-LEN
    IF LS-LEN = 0 OR LS-LEN > 9
        EXIT PARAGRAPH
    END-IF
    IF LS-TEXT(1:LS-LEN) IS NUMERIC
        COMPUTE LS-VALUE = FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
    END-IF.

REPORT-SUBSCRIPT.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "subscript " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-SUB-VALUE(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    IF LS-SUB-VALUE(LS-I) < 1
        STRING " is below 1, the first occurrence of " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING " is past the " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-DIM-OCCURS(LS-I) TO LS-NUM
        PERFORM APPEND-NUM
        STRING " occurrences of " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-SUB-COUNT > 1
        STRING " (dimension " DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        MOVE LS-I TO LS-NUM
        PERFORM APPEND-NUM
        STRING ")" DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-SUBSCRIPT LS-SUB-TOKEN(LS-I) LS-MESSAGE.

*> PLB-C024 ----------------------------------------------------------

*> (OFFSET:LENGTH) or (OFFSET:). Each part that is one literal
*> integer is checked; a part computed at run time is -1, unknown. A
*> length longer than the item is wrong wherever it starts.
CHECK-REFMOD.
    IF RL-ENABLED(LS-RULE-REFMOD) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM ITEM-CHARACTERS
    IF LS-CHARS = 0
        EXIT PARAGRAPH
    END-IF
    MOVE -1 TO LS-OFFSET LS-LENGTH
    IF LS-COLON = LS-T + 2
        COMPUTE LS-UP = LS-T + 1
        IF TK-IS-NUMBER(LS-UP)
            PERFORM LITERAL-VALUE
            MOVE LS-VALUE TO LS-OFFSET
        END-IF
    END-IF
    IF LS-CLOSE = LS-COLON + 2
        COMPUTE LS-UP = LS-COLON + 1
        IF TK-IS-NUMBER(LS-UP)
            PERFORM LITERAL-VALUE
            MOVE LS-VALUE TO LS-LENGTH
        END-IF
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    EVALUATE TRUE
        WHEN LS-OFFSET = 0
            STRING "reference modification starts at " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            MOVE LS-OFFSET TO LS-NUM
            PERFORM APPEND-NUM
            STRING "; positions start at 1" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN LS-OFFSET > LS-CHARS
            STRING "reference modification starts at " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            MOVE LS-OFFSET TO LS-NUM
            PERFORM APPEND-NUM
            PERFORM APPEND-PAST-END
        WHEN LS-LENGTH = 0
            STRING "reference modification has length 0"
                DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN LS-LENGTH > LS-CHARS
            STRING "reference modification is " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            MOVE LS-LENGTH TO LS-NUM
            PERFORM APPEND-NUM
            STRING " characters long, more than the " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            MOVE LS-CHARS TO LS-NUM
            PERFORM APPEND-NUM
            STRING " of " DELIMITED BY SIZE
                   SY-NAME(LS-S) DELIMITED BY SPACE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN LS-OFFSET >= 1 AND LS-LENGTH > 0
             AND LS-OFFSET + LS-LENGTH - 1 > LS-CHARS
            STRING "reference modification ends at " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
            COMPUTE LS-NUM = LS-OFFSET + LS-LENGTH - 1
            PERFORM APPEND-NUM
            PERFORM APPEND-PAST-END
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    COMPUTE LS-UP = LS-T + 1
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-REFMOD LS-UP LS-MESSAGE.

APPEND-PAST-END.
    STRING ", past the end of " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           " (" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-CHARS TO LS-NUM
    PERFORM APPEND-NUM
    STRING " characters)" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR.

*> LS-CHARS = the character positions of one occurrence of item LS-S,
*> or 0 when they are not known for sure: an item of unknown size, a
*> national item (whose characters are not bytes), or a numeric item
*> that is not DISPLAY.
ITEM-CHARACTERS.
    MOVE SY-SIZE(LS-S) TO LS-CHARS
    EVALUATE SY-CATEGORY(LS-S)
        WHEN "N" WHEN "M" WHEN "1" WHEN "?" WHEN "U" WHEN "C" WHEN "K"
            MOVE 0 TO LS-CHARS
        WHEN "9" WHEN "E"
            IF SY-USAGE(LS-S) NOT = SPACES
               AND SY-USAGE(LS-S) NOT = "DISPLAY"
                MOVE 0 TO LS-CHARS
            END-IF
    END-EVALUATE
    *> An item with OCCURS DEPENDING ON in it, or on it, changes size
    *> at run time.
    IF SY-VARIABLE(LS-S) = "Y"
        MOVE 0 TO LS-CHARS
    END-IF.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR.
END PROGRAM PLB-RULE-RANGES.
