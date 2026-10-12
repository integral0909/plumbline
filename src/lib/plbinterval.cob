*> ---------------------------------------------------------------
*> plbinterval: relations of a numeric item with a number, as ranges.
*>
*> PLB-COND-RANGE USING TOKENS AST SYMBOLS REFS COND RANGE reads
*> condition node COND as item [IS] [NOT] op number (op =, >, <, >=,
*> <=, or their words) into RANGE (plbrange.cpy). The item must be a
*> numeric data item without reference modification; NOT = is not
*> read, and NOT turns the other operators round (NOT > 9 is <= 9).
*>
*> PLB-RANGE-CONTAINS USING OUTER INNER RESULT sets RESULT to "Y" when
*> range OUTER holds every value of range INNER.
*>
*> PLB-RANGE-MEETS USING FIRST SECOND RESULT sets RESULT to "Y" when
*> some value is in both ranges.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-COND-RANGE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-SYM                  PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-OP                   PIC X.
01  LS-NOT                  PIC X.
01  LS-VALUE                PIC S9(18)V9(9) COMP-3.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
01  LK-COND                 PIC 9(9) COMP-5.
01  PLB-RANGE.
COPY "plbrange.cpy".
PROCEDURE DIVISION USING PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-REFS
        LK-COND PLB-RANGE.
    MOVE "N" TO RG-OK
    MOVE SPACES TO RG-SUBJECT
    MOVE ND-TOK-FIRST(LK-COND) TO LS-T
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
        GOBACK
    END-IF
    IF SY-CATEGORY(LS-SYM) NOT = "9"
        GOBACK
    END-IF
    *> The item as written, subscripts too.
    MOVE 1 TO LS-PTR
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LK-COND) BY 1
            UNTIL LS-T > RF-LAST(LS-R)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        IF LS-PTR + LS-LEN < 64
            STRING FUNCTION UPPER-CASE(LS-TEXT(1:LS-LEN))
                DELIMITED BY SIZE INTO RG-SUBJECT WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    COMPUTE LS-T = RF-LAST(LS-R) + 1
    PERFORM READ-OPERATOR
    IF LS-OP = SPACE OR LS-T NOT = ND-TOK-LAST(LK-COND)
        GOBACK
    END-IF
    PERFORM READ-NUMBER
    IF RG-OK = "N"
        GOBACK
    END-IF
    MOVE LS-VALUE TO RG-LOW RG-HIGH
    MOVE "N" TO RG-NO-LOW RG-NO-HIGH RG-OPEN-LOW RG-OPEN-HIGH
    EVALUATE LS-OP
        WHEN "G" MOVE "Y" TO RG-NO-HIGH RG-OPEN-LOW
        WHEN "H" MOVE "Y" TO RG-NO-HIGH
        WHEN "L" MOVE "Y" TO RG-NO-LOW RG-OPEN-HIGH
        WHEN "M" MOVE "Y" TO RG-NO-LOW
    END-EVALUATE
    GOBACK.

*> [IS] [NOT] operator at LS-T: LS-OP (E =, G >, H >=, L <, M <=), with
*> NOT folded in; NOT = is not read (space). LS-T is left after it.
READ-OPERATOR.
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

*> LS-VALUE from the number at LS-T; RG-OK = "Y" when it is one.
READ-NUMBER.
    MOVE "N" TO RG-OK
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
    MOVE "Y" TO RG-OK.
END PROGRAM PLB-COND-RANGE.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RANGE-CONTAINS.
DATA DIVISION.
LINKAGE SECTION.
01  LK-OUTER.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==OU-==.
01  LK-INNER.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==IN-==.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING LK-OUTER LK-INNER LK-RESULT.
    MOVE "N" TO LK-RESULT
    *> Its low end.
    IF OU-NO-LOW = "N"
        IF IN-NO-LOW = "Y"
            GOBACK
        END-IF
        IF OU-LOW > IN-LOW
            GOBACK
        END-IF
        IF OU-LOW = IN-LOW AND OU-OPEN-LOW = "Y" AND IN-OPEN-LOW = "N"
            GOBACK
        END-IF
    END-IF
    *> Its high end.
    IF OU-NO-HIGH = "N"
        IF IN-NO-HIGH = "Y"
            GOBACK
        END-IF
        IF OU-HIGH < IN-HIGH
            GOBACK
        END-IF
        IF OU-HIGH = IN-HIGH AND OU-OPEN-HIGH = "Y"
           AND IN-OPEN-HIGH = "N"
            GOBACK
        END-IF
    END-IF
    MOVE "Y" TO LK-RESULT
    GOBACK.
END PROGRAM PLB-RANGE-CONTAINS.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RANGE-MEETS.
DATA DIVISION.
LINKAGE SECTION.
01  LK-FIRST.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==FI-==.
01  LK-SECOND.
COPY "plbrange.cpy" REPLACING LEADING ==RG-== BY ==SE-==.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING LK-FIRST LK-SECOND LK-RESULT.
    MOVE "N" TO LK-RESULT
    *> The first ends below where the second starts.
    IF FI-NO-HIGH = "N" AND SE-NO-LOW = "N"
        IF FI-HIGH < SE-LOW
            GOBACK
        END-IF
        IF FI-HIGH = SE-LOW
           AND (FI-OPEN-HIGH = "Y" OR SE-OPEN-LOW = "Y")
            GOBACK
        END-IF
    END-IF
    *> The second ends below where the first starts.
    IF SE-NO-HIGH = "N" AND FI-NO-LOW = "N"
        IF SE-HIGH < FI-LOW
            GOBACK
        END-IF
        IF SE-HIGH = FI-LOW
           AND (SE-OPEN-HIGH = "Y" OR FI-OPEN-LOW = "Y")
            GOBACK
        END-IF
    END-IF
    MOVE "Y" TO LK-RESULT
    GOBACK.
END PROGRAM PLB-RANGE-MEETS.
