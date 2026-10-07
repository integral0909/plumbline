*> ---------------------------------------------------------------
*> plbrthru: PLB-C074 condition-range-reversed.
*>
*> A condition name whose VALUE a THRU b has a greater than b:
*>
*>     01  WS-CODE         PIC 99.
*>         88  CODE-VALID  VALUE 10 THRU 1.
*>
*> The range holds no value, so that part of the condition is never
*> true (GnuCOBOL 3.2 accepts it without a warning). The ends were
*> written the wrong way round.
*>
*> Numbers are compared by value. Alphanumeric literals are compared
*> only where ASCII and EBCDIC agree: at the first character that
*> differs (the shorter literal padded with spaces), both are digits,
*> both upper-case letters, or both lower-case letters, or one is a
*> space. Literals with a prefix (X, N, ...), figurative constants, and
*> numbers with a decimal comma or an exponent are not compared.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C074.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-LOW                  PIC 9(9) COMP-5.
01  LS-HIGH                 PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-REVERSED             PIC X.
01  LS-TEXT                 PIC X(200).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LOW-TEXT             PIC X(200).
01  LS-LOW-LEN              PIC 9(9) COMP-5.
01  LS-HIGH-TEXT            PIC X(200).
01  LS-HIGH-LEN             PIC 9(9) COMP-5.
01  LS-LOW-VALUE            PIC S9(18)V9(9) COMP-3.
01  LS-HIGH-VALUE           PIC S9(18)V9(9) COMP-3.
01  LS-A                    PIC X.
01  LS-B                    PIC X.
01  LS-A-CLASS              PIC X.
01  LS-CH                   PIC X.
01  LS-CLASS                PIC X.
01  LS-B-CLASS              PIC X.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C074" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-LEVEL(LS-S) = 88 AND SY-NODE(LS-S) > 0
            PERFORM CHECK-CONDITION
        END-IF
    END-PERFORM
    GOBACK.

*> The THRU ranges of the VALUE clause of condition LS-S.
CHECK-CONDITION.
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-C
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "CLAU" AND ND-DETAIL(LS-C) = "VALUE"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM
    IF LS-C = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-C) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-C)
        IF TK-IS-WORD(LS-T) AND LS-T > ND-TOK-FIRST(LS-C)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "THRU"
               OR FUNCTION UPPER-CASE(LS-TEXT) = "THROUGH"
                COMPUTE LS-LOW = LS-T - 1
                COMPUTE LS-HIGH = LS-T + 1
                PERFORM CHECK-RANGE
            END-IF
        END-IF
    END-PERFORM.

*> The range LS-LOW THRU LS-HIGH.
CHECK-RANGE.
    MOVE "N" TO LS-REVERSED
    EVALUATE TRUE
        WHEN TK-IS-NUMBER(LS-LOW) AND TK-IS-NUMBER(LS-HIGH)
            PERFORM COMPARE-NUMBERS
        WHEN TK-IS-ALNUM(LS-LOW) AND TK-IS-ALNUM(LS-HIGH)
             AND TK-PREFIX(LS-LOW) = SPACES
             AND TK-PREFIX(LS-HIGH) = SPACES
            PERFORM COMPARE-CHARACTERS
    END-EVALUATE
    IF LS-REVERSED = "Y"
        PERFORM REPORT-RANGE
    END-IF.

COMPARE-NUMBERS.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-LOW LS-LOW-TEXT LS-LOW-LEN
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-HIGH LS-HIGH-TEXT
        LS-HIGH-LEN
    IF LS-LOW-LEN > 27 OR LS-HIGH-LEN > 27
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-I
    INSPECT LS-LOW-TEXT(1:LS-LOW-LEN) TALLYING LS-I FOR ALL "," "E" "e"
    INSPECT LS-HIGH-TEXT(1:LS-HIGH-LEN) TALLYING LS-I FOR ALL "," "E" "e"
    IF LS-I > 0
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION TEST-NUMVAL(LS-LOW-TEXT(1:LS-LOW-LEN)) NOT = 0
       OR FUNCTION TEST-NUMVAL(LS-HIGH-TEXT(1:LS-HIGH-LEN)) NOT = 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-LOW-VALUE = FUNCTION NUMVAL(LS-LOW-TEXT(1:LS-LOW-LEN))
    COMPUTE LS-HIGH-VALUE = FUNCTION NUMVAL(LS-HIGH-TEXT(1:LS-HIGH-LEN))
    IF LS-LOW-VALUE > LS-HIGH-VALUE
        MOVE "Y" TO LS-REVERSED
    END-IF.

*> The first character that differs decides, when both encodings
*> order the two characters the same way.
COMPARE-CHARACTERS.
    MOVE SPACES TO LS-LOW-TEXT LS-HIGH-TEXT
    MOVE TK-TEXT-LEN(LS-LOW) TO LS-LOW-LEN
    MOVE TK-TEXT-LEN(LS-HIGH) TO LS-HIGH-LEN
    IF LS-LOW-LEN > 200 OR LS-HIGH-LEN > 200
        EXIT PARAGRAPH
    END-IF
    IF LS-LOW-LEN > 0
        MOVE TK-TEXT(TK-TEXT-OFF(LS-LOW):LS-LOW-LEN) TO LS-LOW-TEXT
    END-IF
    IF LS-HIGH-LEN > 0
        MOVE TK-TEXT(TK-TEXT-OFF(LS-HIGH):LS-HIGH-LEN) TO LS-HIGH-TEXT
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > 200
        IF LS-LOW-TEXT(LS-I:1) NOT = LS-HIGH-TEXT(LS-I:1)
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-I > 200
        EXIT PARAGRAPH
    END-IF
    MOVE LS-LOW-TEXT(LS-I:1) TO LS-A
    MOVE LS-HIGH-TEXT(LS-I:1) TO LS-B
    MOVE LS-A TO LS-CH
    PERFORM CLASSIFY
    MOVE LS-CLASS TO LS-A-CLASS
    MOVE LS-B TO LS-CH
    PERFORM CLASSIFY
    MOVE LS-CLASS TO LS-B-CLASS
    EVALUATE TRUE
        *> A space is below every letter and digit in both.
        WHEN LS-B-CLASS = "S" AND LS-A-CLASS NOT = "?"
            MOVE "Y" TO LS-REVERSED
        WHEN LS-A-CLASS = "S"
            CONTINUE
        WHEN LS-A-CLASS = LS-B-CLASS AND LS-A-CLASS NOT = "?"
            IF LS-A > LS-B
                MOVE "Y" TO LS-REVERSED
            END-IF
    END-EVALUATE.

*> LS-CLASS: the class of character LS-CH: S space, D digit, U
*> upper-case letter, L lower-case letter, ? other.
CLASSIFY.
    EVALUATE TRUE
        WHEN LS-CH = SPACE
            MOVE "S" TO LS-CLASS
        WHEN LS-CH >= "0" AND LS-CH <= "9"
            MOVE "D" TO LS-CLASS
        WHEN LS-CH >= "A" AND LS-CH <= "Z"
            MOVE "U" TO LS-CLASS
        WHEN LS-CH >= "a" AND LS-CH <= "z"
            MOVE "L" TO LS-CLASS
        WHEN OTHER
            MOVE "?" TO LS-CLASS
    END-EVALUATE.

REPORT-RANGE.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " has a range that holds no value: " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-LOW LS-TEXT LS-LEN
    IF TK-IS-ALNUM(LS-LOW)
        STRING '"' LS-TEXT(1:LS-LEN) '"' DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING " is above " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-HIGH LS-TEXT LS-LEN
    IF TK-IS-ALNUM(LS-HIGH)
        STRING '"' LS-TEXT(1:LS-LEN) '"' DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-LOW LS-MESSAGE.
END PROGRAM PLB-RULE-C074.
