*> ---------------------------------------------------------------
*> plbrptr: PLB-C093 pointer-too-small.
*>
*> A STRING or UNSTRING POINTER item too small for the positions it
*> counts:
*>
*>     01  WS-OUT  PIC X(20).
*>     01  WS-P    PIC 9.
*>         STRING WS-PART DELIMITED BY SIZE INTO WS-OUT
*>             WITH POINTER WS-P
*>
*> The pointer counts positions of the receiver (STRING) or the sending
*> item (UNSTRING), up to one past its last; WS-P above must reach 21.
*> A pointer that cannot hold that loses its high-order digits: with
*> GnuCOBOL 3.2, after 12 characters WS-P holds 3, so the next STRING
*> writes over the third character, and an UNSTRING starts over. Read
*> are pointers stored as decimal digits (DISPLAY or PACKED-DECIMAL),
*> whose picture decides what they hold, and receivers and sending
*> items of a fixed size, without reference modification.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C093.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> The item whose positions are counted, and the pointer.
01  LS-TARGET               PIC 9(9) COMP-5.
01  LS-POINTER              PIC 9(9) COMP-5.
01  LS-POINTER-TOKEN        PIC 9(9) COMP-5.
01  LS-FOUND                PIC 9(9) COMP-5.
01  LS-LARGEST              PIC S9(18) COMP-5.
01  LS-NEEDED               PIC S9(18) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-1                PIC X(20).
01  LS-NUM-1-LEN            PIC 9(9) COMP-5.
01  LS-NUM-2                PIC X(20).
01  LS-NUM-2-LEN            PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C093" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT"
           AND (ND-DETAIL(LS-NODE) = "STRING"
                OR ND-DETAIL(LS-NODE) = "UNSTRING")
            PERFORM CHECK-STATEMENT
        END-IF
    END-PERFORM
    GOBACK.

*> The pointer, and the receiver after INTO (STRING) or the sending
*> item after UNSTRING, up to the first phrase of statements.
CHECK-STATEMENT.
    MOVE ND-TOK-LAST(LS-NODE) TO LS-LAST
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            COMPUTE LS-LAST = ND-TOK-FIRST(LS-CHILD) - 1
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    MOVE 0 TO LS-TARGET LS-POINTER
    IF ND-DETAIL(LS-NODE) = "UNSTRING"
        COMPUTE LS-AT = ND-TOK-FIRST(LS-NODE) + 1
        PERFORM ITEM-AT
        MOVE LS-FOUND TO LS-TARGET
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= LS-LAST
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            EVALUATE TRUE
                WHEN LS-WORD = "INTO" AND ND-DETAIL(LS-NODE) = "STRING"
                    COMPUTE LS-AT = LS-T + 1
                    PERFORM ITEM-AT
                    MOVE LS-FOUND TO LS-TARGET
                WHEN LS-WORD = "POINTER"
                    COMPUTE LS-AT = LS-T + 1
                    MOVE LS-AT TO LS-POINTER-TOKEN
                    PERFORM ITEM-AT
                    MOVE LS-FOUND TO LS-POINTER
            END-EVALUATE
        END-IF
    END-PERFORM
    IF LS-TARGET = 0 OR LS-POINTER = 0
        EXIT PARAGRAPH
    END-IF
    IF SY-VARIABLE(LS-TARGET) = "Y" OR SY-SIZE(LS-TARGET) = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM POINTER-LARGEST
    IF LS-LARGEST < 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-NEEDED = SY-SIZE(LS-TARGET) + 1
    IF LS-LARGEST < LS-NEEDED
        PERFORM REPORT-SMALL
    END-IF.

*> LS-FOUND: the item of the data reference at LS-AT, without reference
*> modification; 0 for anything else.
ITEM-AT.
    MOVE 0 TO LS-FOUND
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-AT
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
               AND RF-REFMOD(LS-R) = "N"
                MOVE RF-SYMBOL(LS-R) TO LS-FOUND
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-LARGEST: the largest number the pointer holds; -1 when it is not
*> an integer stored as decimal digits.
POINTER-LARGEST.
    MOVE -1 TO LS-LARGEST
    IF SY-CATEGORY(LS-POINTER) NOT = "9" OR SY-SCALE(LS-POINTER) NOT = 0
       OR SY-DIGITS(LS-POINTER) = 0 OR SY-DIGITS(LS-POINTER) > 17
        EXIT PARAGRAPH
    END-IF
    EVALUATE SY-USAGE(LS-POINTER)
        WHEN SPACES WHEN "DISPLAY" WHEN "PACKED-DECIMAL" WHEN "COMP-3"
        WHEN "COMPUTATIONAL-3"
            CONTINUE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE 1 TO LS-LARGEST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > SY-DIGITS(LS-POINTER)
        MULTIPLY 10 BY LS-LARGEST
    END-PERFORM
    SUBTRACT 1 FROM LS-LARGEST.

REPORT-SMALL.
    MOVE LS-LARGEST TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    MOVE LS-NEEDED TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-POINTER) DELIMITED BY SPACE
           " holds at most " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           ", but as the pointer into " DELIMITED BY SIZE
           SY-NAME(LS-TARGET) DELIMITED BY SPACE
           " it goes up to " DELIMITED BY SIZE
           LS-NUM-2(1:LS-NUM-2-LEN) DELIMITED BY SIZE
           ": past " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           " it loses its high-order digits" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-POINTER-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C093.
