*> ---------------------------------------------------------------
*> plbrwhen: PLB-C087 when-covered.
*>
*> A WHEN of an EVALUATE whose values an earlier WHEN's range takes:
*>
*>     EVALUATE WS-CODE
*>         WHEN 1 THRU 10
*>             ...
*>         WHEN 5                       never matches
*>
*> EVALUATE runs the first WHEN that matches, so the later one never
*> runs. Read are EVALUATE statements of one subject (no ALSO, not TRUE
*> or FALSE), and WHEN phrases that are a number or a range of numbers
*> (THRU or THROUGH); a WHEN is reported when one earlier WHEN's range
*> holds all its values. A WHEN the same as an earlier one is PLB-C032's.
*> Alphanumeric ranges, which depend on the collating sequence, are not
*> read.
*>
*> EVALUATE TRUE is read too, for WHEN phrases that are one relation of
*> a numeric item with a number (item > 10, item = 5): a WHEN whose
*> values a WHEN before it, on the same item as written, takes all of
*> is never chosen (WHEN AMOUNT > 20 after WHEN AMOUNT > 10).
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C087.
DATA DIVISION.
LOCAL-STORAGE SECTION.
78  WHEN-MAX                VALUE 256.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-COND                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-OK                   PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LOW                  PIC S9(18)V9(9) COMP-3.
01  LS-HIGH                 PIC S9(18)V9(9) COMP-3.
01  LS-VALUE                PIC S9(18)V9(9) COMP-3.
*> The ranges of the earlier WHEN phrases, and where each is.
01  LS-WHEN-COUNT           PIC 9(9) COMP-5.
01  LS-WHEN-LOW             PIC S9(18)V9(9) COMP-3 OCCURS WHEN-MAX TIMES.
01  LS-WHEN-HIGH            PIC S9(18)V9(9) COMP-3 OCCURS WHEN-MAX TIMES.
01  LS-WHEN-TOKEN           PIC 9(9) COMP-5 OCCURS WHEN-MAX TIMES.
01  LS-WHEN-LAST            PIC 9(9) COMP-5 OCCURS WHEN-MAX TIMES.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
*> EVALUATE TRUE: each WHEN read, as its item and the interval of its
*> values.
01  LS-TW-COUNT             PIC 9(9) COMP-5.
01  LS-TW                   OCCURS WHEN-MAX TIMES.
    05  TW-SUBJECT          PIC X(64).
    05  TW-LOW              PIC S9(18)V9(9) COMP-3.
    05  TW-HIGH             PIC S9(18)V9(9) COMP-3.
    05  TW-NO-LOW           PIC X.
    05  TW-NO-HIGH          PIC X.
    05  TW-OPEN-LOW         PIC X.
    05  TW-OPEN-HIGH        PIC X.
    05  TW-TOKEN            PIC 9(9) COMP-5.
    05  TW-LAST             PIC 9(9) COMP-5.
01  LS-SUBJECT              PIC X(64).
01  LS-NO-LOW               PIC X.
01  LS-NO-HIGH              PIC X.
01  LS-OPEN-LOW             PIC X.
01  LS-OPEN-HIGH            PIC X.
01  LS-OP                   PIC X.
01  LS-NOT                  PIC X.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-SYM                  PIC 9(9) COMP-5.
01  LS-CONTAINS             PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C087" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "EVALUATE"
            PERFORM CHECK-EVALUATE
        END-IF
    END-PERFORM
    GOBACK.

*> EVALUATE LS-NODE: one subject, then its WHEN phrases in order.
CHECK-EVALUATE.
    MOVE ND-FIRST(LS-NODE) TO LS-C
    IF LS-C = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-C) NOT = "COND" OR ND-DETAIL(LS-C) NOT = "SUBJECT"
        EXIT PARAGRAPH
    END-IF
    *> EVALUATE TRUE alone.
    IF ND-TOK-FIRST(LS-C) = ND-TOK-LAST(LS-C)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-TOK-FIRST(LS-C) LS-TEXT
            LS-LEN
        IF FUNCTION UPPER-CASE(LS-TEXT) = "TRUE"
            PERFORM CHECK-EVALUATE-TRUE
            EXIT PARAGRAPH
        END-IF
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-C) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-C)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "ALSO" OR LS-TEXT = "TRUE" OR LS-TEXT = "FALSE"
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    MOVE 0 TO LS-WHEN-COUNT
    MOVE ND-NEXT(LS-C) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "BLCK" AND ND-DETAIL(LS-C) = "WHEN"
            MOVE ND-FIRST(LS-C) TO LS-COND
            IF LS-COND > 0
                IF ND-KIND(LS-COND) = "COND"
                    PERFORM READ-WHEN
                    IF LS-OK = "Y"
                        PERFORM TEST-COVERED
                        PERFORM ADD-WHEN
                    END-IF
                END-IF
            END-IF
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM.

*> EVALUATE TRUE LS-NODE: each WHEN that is one relation, against the
*> WHEN phrases before it.
CHECK-EVALUATE-TRUE.
    MOVE 0 TO LS-TW-COUNT
    MOVE ND-NEXT(ND-FIRST(LS-NODE)) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "BLCK" AND ND-DETAIL(LS-C) = "WHEN"
            MOVE ND-FIRST(LS-C) TO LS-COND
            IF LS-COND > 0
                IF ND-KIND(LS-COND) = "COND"
                   AND ND-NEXT(LS-COND) NOT = 0
                    PERFORM READ-RELATION
                    IF LS-OK = "Y"
                        PERFORM TEST-TRUE-COVERED
                        PERFORM ADD-TRUE-WHEN
                    END-IF
                END-IF
            END-IF
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM.

*> WHEN condition LS-COND as item op number: LS-SUBJECT, and the
*> interval LS-LOW to LS-HIGH with its open and missing ends; LS-OK =
*> "Y" when it is one.
READ-RELATION.
    MOVE "N" TO LS-OK
    MOVE ND-TOK-FIRST(LS-COND) TO LS-T
    MOVE 0 TO LS-SYM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-T
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
               AND RF-REFMOD(LS-R) = "N"
                MOVE RF-SYMBOL(LS-R) TO LS-SYM
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-SYM = 0
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-SYM) NOT = "9"
        EXIT PARAGRAPH
    END-IF
    *> The item as written, subscripts too.
    MOVE SPACES TO LS-SUBJECT
    MOVE 1 TO LS-PTR
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-COND) BY 1
            UNTIL LS-T > RF-LAST(LS-R)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        IF LS-PTR + LS-LEN < 64
            STRING FUNCTION UPPER-CASE(LS-TEXT(1:LS-LEN))
                DELIMITED BY SIZE INTO LS-SUBJECT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    COMPUTE LS-T = RF-LAST(LS-R) + 1
    PERFORM READ-RELATION-OPERATOR
    IF LS-OP = SPACE OR LS-T NOT = ND-TOK-LAST(LS-COND)
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-NUMBER
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-VALUE TO LS-LOW LS-HIGH
    MOVE "N" TO LS-NO-LOW LS-NO-HIGH LS-OPEN-LOW LS-OPEN-HIGH
    EVALUATE LS-OP
        WHEN "G" MOVE "Y" TO LS-NO-HIGH LS-OPEN-LOW
        WHEN "H" MOVE "Y" TO LS-NO-HIGH
        WHEN "L" MOVE "Y" TO LS-NO-LOW LS-OPEN-HIGH
        WHEN "M" MOVE "Y" TO LS-NO-LOW
    END-EVALUATE.

*> [IS] [NOT] operator at LS-T: LS-OP (E =, G >, H >=, L <, M <=), with
*> NOT folded in; NOT = is not read (space). LS-T is left after it.
READ-RELATION-OPERATOR.
    MOVE SPACE TO LS-OP
    MOVE "N" TO LS-NOT
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    IF LS-TEXT = "IS"
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    END-IF
    IF LS-TEXT = "NOT"
        MOVE "Y" TO LS-NOT
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    END-IF
    EVALUATE TRUE
        WHEN LS-TEXT = "=" OR LS-TEXT = "EQUAL"
            MOVE "E" TO LS-OP
        WHEN LS-TEXT = ">" OR LS-TEXT = "GREATER"
            MOVE "G" TO LS-OP
        WHEN LS-TEXT = "<" OR LS-TEXT = "LESS"
            MOVE "L" TO LS-OP
        WHEN LS-TEXT = ">="
            MOVE "H" TO LS-OP
        WHEN LS-TEXT = "<="
            MOVE "M" TO LS-OP
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    ADD 1 TO LS-T
    *> THAN, TO, and OR EQUAL [TO] of the words.
    PERFORM 3 TIMES
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
        EVALUATE LS-TEXT
            WHEN "THAN" WHEN "TO"
                ADD 1 TO LS-T
            WHEN "OR"
                ADD 1 TO LS-T
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                IF FUNCTION UPPER-CASE(LS-TEXT) NOT = "EQUAL"
                    MOVE SPACE TO LS-OP
                    EXIT PARAGRAPH
                END-IF
                ADD 1 TO LS-T
                IF LS-OP = "G"
                    MOVE "H" TO LS-OP
                ELSE
                    MOVE "M" TO LS-OP
                END-IF
        END-EVALUATE
    END-PERFORM
    IF LS-NOT = "Y"
        EVALUATE LS-OP
            WHEN "E" MOVE SPACE TO LS-OP
            WHEN "G" MOVE "M" TO LS-OP
            WHEN "H" MOVE "L" TO LS-OP
            WHEN "L" MOVE "H" TO LS-OP
            WHEN "M" MOVE "G" TO LS-OP
        END-EVALUATE
    END-IF.

*> The WHEN just read, inside one before it on the same item; one the
*> same as it is PLB-C032's.
TEST-TRUE-COVERED.
    MOVE 0 TO LS-SYM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-TW-COUNT
        IF TW-SUBJECT(LS-I) = LS-SUBJECT
            PERFORM TRUE-CONTAINS
            IF LS-CONTAINS = "Y"
               AND NOT (TW-NO-LOW(LS-I) = LS-NO-LOW
                        AND TW-NO-HIGH(LS-I) = LS-NO-HIGH
                        AND TW-OPEN-LOW(LS-I) = LS-OPEN-LOW
                        AND TW-OPEN-HIGH(LS-I) = LS-OPEN-HIGH
                        AND TW-LOW(LS-I) = LS-LOW
                        AND TW-HIGH(LS-I) = LS-HIGH)
                MOVE LS-I TO LS-SYM
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    *> REPORT-COVERED names the earlier WHEN at LS-WHEN-TOKEN(LS-I).
    IF LS-SYM > 0
        MOVE TW-TOKEN(LS-SYM) TO LS-WHEN-TOKEN(1)
        MOVE TW-LAST(LS-SYM) TO LS-WHEN-LAST(1)
        MOVE 1 TO LS-I
        PERFORM REPORT-COVERED
    END-IF.

*> LS-CONTAINS = "Y" when interval LS-I holds every value of the one
*> just read.
TRUE-CONTAINS.
    MOVE "N" TO LS-CONTAINS
    *> Its low end.
    IF TW-NO-LOW(LS-I) = "N"
        IF LS-NO-LOW = "Y"
            EXIT PARAGRAPH
        END-IF
        IF TW-LOW(LS-I) > LS-LOW
            EXIT PARAGRAPH
        END-IF
        IF TW-LOW(LS-I) = LS-LOW AND TW-OPEN-LOW(LS-I) = "Y"
           AND LS-OPEN-LOW = "N"
            EXIT PARAGRAPH
        END-IF
    END-IF
    *> Its high end.
    IF TW-NO-HIGH(LS-I) = "N"
        IF LS-NO-HIGH = "Y"
            EXIT PARAGRAPH
        END-IF
        IF TW-HIGH(LS-I) < LS-HIGH
            EXIT PARAGRAPH
        END-IF
        IF TW-HIGH(LS-I) = LS-HIGH AND TW-OPEN-HIGH(LS-I) = "Y"
           AND LS-OPEN-HIGH = "N"
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE "Y" TO LS-CONTAINS.

ADD-TRUE-WHEN.
    IF LS-TW-COUNT >= WHEN-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-TW-COUNT
    MOVE LS-SUBJECT TO TW-SUBJECT(LS-TW-COUNT)
    MOVE LS-LOW TO TW-LOW(LS-TW-COUNT)
    MOVE LS-HIGH TO TW-HIGH(LS-TW-COUNT)
    MOVE LS-NO-LOW TO TW-NO-LOW(LS-TW-COUNT)
    MOVE LS-NO-HIGH TO TW-NO-HIGH(LS-TW-COUNT)
    MOVE LS-OPEN-LOW TO TW-OPEN-LOW(LS-TW-COUNT)
    MOVE LS-OPEN-HIGH TO TW-OPEN-HIGH(LS-TW-COUNT)
    MOVE ND-TOK-FIRST(LS-COND) TO TW-TOKEN(LS-TW-COUNT)
    MOVE ND-TOK-LAST(LS-COND) TO TW-LAST(LS-TW-COUNT).

*> LS-OK = "Y" when WHEN condition LS-COND is a number, or a number
*> THRU a number: LS-LOW to LS-HIGH.
READ-WHEN.
    MOVE "N" TO LS-OK
    MOVE ND-TOK-FIRST(LS-COND) TO LS-T
    PERFORM READ-NUMBER
    IF LS-OK = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-VALUE TO LS-LOW LS-HIGH
    IF LS-T = ND-TOK-LAST(LS-COND)
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-OK
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-TEXT NOT = "THRU" AND LS-TEXT NOT = "THROUGH"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    IF LS-T NOT = ND-TOK-LAST(LS-COND)
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-NUMBER
    IF LS-OK = "Y"
        MOVE LS-VALUE TO LS-HIGH
        *> A range written high to low holds no value (PLB-C074 for a
        *> condition name); it covers nothing.
        IF LS-HIGH < LS-LOW
            MOVE "N" TO LS-OK
        END-IF
    END-IF.

*> LS-VALUE from the number at LS-T; LS-OK = "Y" when it is one.
READ-NUMBER.
    MOVE "N" TO LS-OK
    IF NOT TK-IS-NUMBER(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-LEN > 27
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-I
    INSPECT LS-TEXT(1:LS-LEN) TALLYING LS-I FOR ALL "," "E" "e"
    IF LS-I > 0
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION TEST-NUMVAL(LS-TEXT(1:LS-LEN)) NOT = 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-VALUE = FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
    MOVE "Y" TO LS-OK.

*> The WHEN LS-LOW to LS-HIGH inside an earlier range, other than one
*> the same as it.
TEST-COVERED.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-WHEN-COUNT
        IF LS-WHEN-LOW(LS-I) <= LS-LOW AND LS-HIGH <= LS-WHEN-HIGH(LS-I)
           AND NOT (LS-WHEN-LOW(LS-I) = LS-LOW
                    AND LS-WHEN-HIGH(LS-I) = LS-HIGH)
            PERFORM REPORT-COVERED
            EXIT PERFORM
        END-IF
    END-PERFORM.

ADD-WHEN.
    IF LS-WHEN-COUNT >= WHEN-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-WHEN-COUNT
    MOVE LS-LOW TO LS-WHEN-LOW(LS-WHEN-COUNT)
    MOVE LS-HIGH TO LS-WHEN-HIGH(LS-WHEN-COUNT)
    MOVE ND-TOK-FIRST(LS-COND) TO LS-WHEN-TOKEN(LS-WHEN-COUNT)
    MOVE ND-TOK-LAST(LS-COND) TO LS-WHEN-LAST(LS-WHEN-COUNT).

*> The WHEN at LS-COND, covered by earlier WHEN LS-I.
REPORT-COVERED.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "this WHEN never matches: the WHEN " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    PERFORM VARYING LS-T FROM LS-WHEN-TOKEN(LS-I) BY 1
            UNTIL LS-T > LS-WHEN-LAST(LS-I)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        STRING LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
        IF LS-T < LS-WHEN-LAST(LS-I)
            STRING " " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-WHEN-TOKEN(LS-I))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING " on line " LS-NUM-TEXT(1:LS-NUM-LEN)
           " takes all its values first" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-COND) LS-MESSAGE.
END PROGRAM PLB-RULE-C087.
