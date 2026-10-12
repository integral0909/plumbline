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
    03  TW-RANGE.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==TW-==.
    03  TW-TOKEN            PIC 9(9) COMP-5.
    03  TW-LAST             PIC 9(9) COMP-5.
01  PLB-RANGE.
COPY "plbrange.cpy".
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
                    CALL "PLB-COND-RANGE" USING PLB-TOKENS PLB-AST
                        PLB-SYMBOLS PLB-REFS LS-COND PLB-RANGE
                    IF RG-OK = "Y"
                        PERFORM TEST-TRUE-COVERED
                        PERFORM ADD-TRUE-WHEN
                    END-IF
                END-IF
            END-IF
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM.

*> The WHEN just read, inside one before it on the same item; one the
*> same as it is PLB-C032's.
TEST-TRUE-COVERED.
    MOVE 0 TO LS-SYM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-TW-COUNT
        IF TW-SUBJECT(LS-I) = RG-SUBJECT
            CALL "PLB-RANGE-CONTAINS" USING TW-RANGE(LS-I) PLB-RANGE
                LS-CONTAINS
            IF LS-CONTAINS = "Y" AND TW-RANGE(LS-I) NOT = PLB-RANGE
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

ADD-TRUE-WHEN.
    IF LS-TW-COUNT >= WHEN-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-TW-COUNT
    MOVE PLB-RANGE TO TW-RANGE(LS-TW-COUNT)
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
