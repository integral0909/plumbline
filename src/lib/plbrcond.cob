*> ---------------------------------------------------------------
*> plbrcond: PLB-C064 duplicate-condition-value.
*>
*> Two condition names (level 88) of the same item with the same
*> values:
*>
*>     01  ACCOUNT-STATUS      PIC X.
*>         88  STATUS-OPEN     VALUE "O".
*>         88  STATUS-ACTIVE   VALUE "O".
*>
*> Usually one was copied from the other and its value not changed:
*> each is true whenever the other is, and SET STATUS-ACTIVE TO TRUE
*> stores what SET STATUS-OPEN TO TRUE does, so a test meant to tell
*> them apart never can.
*>
*> The values are compared as a set: the same literals and ranges, in
*> any order. An alphanumeric literal's trailing spaces do not count,
*> nor a number's leading zeros or trailing decimal zeros; figurative
*> constants are compared by what they name (SPACE and SPACES alike,
*> ZERO and 0 for a numeric item).
*> A condition whose values are a superset of another's, as a VALID
*> condition listing the values of several others, is not reported.
*> The WHEN SET TO FALSE phrase is not compared.
*>
*> Only pairs that the program's procedures name, one or the other,
*> are reported: two condition names that nothing tests or sets, as
*> two messages with the same text in a table of messages, mislead no
*> statement.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C064.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  CONDITION-MAX           VALUE 64.
78  ELEMENT-MAX             VALUE 32.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-J                    PIC 9(4) COMP-5.
01  LS-PARENT               PIC 9(9) COMP-5.
*> The conditions seen so far of the current item: their symbols and
*> the signatures of their values.
01  LS-COND-COUNT           PIC 9(4) COMP-5.
01  LS-COND-SYMBOL          PIC 9(9) COMP-5 OCCURS CONDITION-MAX TIMES.
01  LS-COND-SIGNATURE       PIC X(1024) OCCURS CONDITION-MAX TIMES.
*> The values of one condition, each as text, sorted, then joined.
01  LS-ELEMENT-COUNT        PIC 9(4) COMP-5.
01  LS-ELEMENT              PIC X(64) OCCURS ELEMENT-MAX TIMES.
01  LS-SWAP                 PIC X(64).
01  LS-SIGNATURE            PIC X(1024).
01  LS-USABLE               PIC X.
01  LS-AFTER-THRU           PIC X.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-VALUE                PIC X(64).
01  LS-TEXT                 PIC X(200).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-USED                 PIC 9(9) COMP-5.
01  LS-NUMBER               PIC S9(18)V9(9) COMP-3.
01  LS-NUMBER-TEXT          PIC -9(18).9(9).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C064" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    MOVE 0 TO LS-PARENT LS-COND-COUNT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-LEVEL(LS-S) = 88 AND SY-PARENT(LS-S) > 0
           AND SY-NODE(LS-S) > 0
            IF SY-PARENT(LS-S) NOT = LS-PARENT
                MOVE SY-PARENT(LS-S) TO LS-PARENT
                MOVE 0 TO LS-COND-COUNT
            END-IF
            PERFORM CHECK-CONDITION
        END-IF
    END-PERFORM
    GOBACK.

*> Condition LS-S: its signature, against those of the conditions of
*> the same item before it.
CHECK-CONDITION.
    PERFORM BUILD-SIGNATURE
    IF LS-USABLE NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-COND-COUNT
        IF LS-COND-SIGNATURE(LS-I) = LS-SIGNATURE
            PERFORM CHECK-NAMED
            IF LS-USABLE = "Y"
                PERFORM REPORT-DUPLICATE
            END-IF
            *> Kept off the list: a third copy is reported against the
            *> first too, once.
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF LS-COND-COUNT < CONDITION-MAX
        ADD 1 TO LS-COND-COUNT
        MOVE LS-S TO LS-COND-SYMBOL(LS-COND-COUNT)
        MOVE LS-SIGNATURE TO LS-COND-SIGNATURE(LS-COND-COUNT)
    END-IF.

*> LS-USABLE = "Y" when a reference of the procedures names condition
*> LS-S or LS-COND-SYMBOL(LS-I).
CHECK-NAMED.
    MOVE "N" TO LS-USABLE
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D"
           AND (RF-SYMBOL(LS-R) = LS-S
                OR RF-SYMBOL(LS-R) = LS-COND-SYMBOL(LS-I))
            MOVE "Y" TO LS-USABLE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-SIGNATURE: the values of the VALUE clause of condition LS-S,
*> each made canonical, sorted, and joined. LS-USABLE = "N" when there
*> is no clause, too many values, or one that cannot be compared.
BUILD-SIGNATURE.
    MOVE "N" TO LS-USABLE
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
    MOVE 0 TO LS-ELEMENT-COUNT
    MOVE "N" TO LS-AFTER-THRU
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-C) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-C)
        MOVE SPACES TO LS-VALUE
        EVALUATE TRUE
            WHEN TK-IS-ALNUM(LS-T)
                PERFORM ALNUM-VALUE
            WHEN TK-IS-NUMBER(LS-T)
                PERFORM NUMBER-VALUE
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                EVALUATE FUNCTION UPPER-CASE(LS-TEXT)
                    WHEN "VALUE" WHEN "VALUES" WHEN "IS" WHEN "ARE"
                        CONTINUE
                    WHEN "THRU" WHEN "THROUGH"
                        MOVE "Y" TO LS-AFTER-THRU
                    WHEN "WHEN" WHEN "FALSE"
                        *> WHEN SET TO FALSE: the values end here.
                        EXIT PERFORM
                    WHEN "SPACE" WHEN "SPACES"
                        MOVE "F:SPACE" TO LS-VALUE
                    WHEN "ZERO" WHEN "ZEROS" WHEN "ZEROES"
                        *> For a number, ZERO is the value 0.
                        IF SY-CATEGORY(LS-PARENT) = "9"
                            MOVE 0 TO LS-NUMBER
                            MOVE LS-NUMBER TO LS-NUMBER-TEXT
                            STRING "N:" LS-NUMBER-TEXT DELIMITED BY SIZE
                                INTO LS-VALUE
                        ELSE
                            MOVE "F:ZERO" TO LS-VALUE
                        END-IF
                    WHEN "HIGH-VALUE" WHEN "HIGH-VALUES"
                        MOVE "F:HIGH-VALUE" TO LS-VALUE
                    WHEN "LOW-VALUE" WHEN "LOW-VALUES"
                        MOVE "F:LOW-VALUE" TO LS-VALUE
                    WHEN "QUOTE" WHEN "QUOTES"
                        MOVE "F:QUOTE" TO LS-VALUE
                    WHEN "NULL" WHEN "NULLS"
                        MOVE "F:NULL" TO LS-VALUE
                    WHEN OTHER
                        *> ALL "x", constants, and anything else.
                        EXIT PARAGRAPH
                END-EVALUATE
            WHEN OTHER
                EXIT PARAGRAPH
        END-EVALUATE
        *> A literal that could not be made canonical: give up, rather
        *> than compare the other values alone.
        IF LS-VALUE = SPACES
           AND (TK-IS-ALNUM(LS-T) OR TK-IS-NUMBER(LS-T))
            EXIT PARAGRAPH
        END-IF
        IF LS-VALUE NOT = SPACES
            PERFORM ADD-ELEMENT
            IF LS-ELEMENT-COUNT = 0
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    IF LS-ELEMENT-COUNT = 0 OR LS-AFTER-THRU = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM SORT-ELEMENTS
    MOVE SPACES TO LS-SIGNATURE
    MOVE 1 TO LS-PTR
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-ELEMENT-COUNT
        STRING FUNCTION TRIM(LS-ELEMENT(LS-I) TRAILING) X"00"
            DELIMITED BY SIZE INTO LS-SIGNATURE WITH POINTER LS-PTR
            ON OVERFLOW
                EXIT PARAGRAPH
        END-STRING
    END-PERFORM
    MOVE "Y" TO LS-USABLE.

*> An alphanumeric literal at LS-T, less its trailing spaces, with its
*> prefix (X"C1" and "A" are not taken for the same value).
ALNUM-VALUE.
    MOVE TK-TEXT-LEN(LS-T) TO LS-USED
    PERFORM UNTIL LS-USED = 0
        IF TK-TEXT(TK-TEXT-OFF(LS-T) + LS-USED - 1:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-USED
    END-PERFORM
    *> Too long to compare: LS-VALUE stays blank.
    IF LS-USED > 60
        EXIT PARAGRAPH
    END-IF
    MOVE "A" TO LS-VALUE(1:1)
    MOVE TK-PREFIX(LS-T) TO LS-VALUE(2:2)
    MOVE ":" TO LS-VALUE(4:1)
    IF LS-USED > 0
        MOVE TK-TEXT(TK-TEXT-OFF(LS-T):LS-USED) TO LS-VALUE(5:LS-USED)
    ELSE
        *> All spaces: the same as SPACE.
        MOVE "F:SPACE" TO LS-VALUE
    END-IF.

*> A numeric literal at LS-T, by its value. A literal with an exponent
*> or too many digits leaves LS-VALUE blank, and the condition is not
*> compared.
NUMBER-VALUE.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-LEN = 0 OR LS-LEN > 28
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION TEST-NUMVAL(LS-TEXT(1:LS-LEN)) NOT = 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-NUMBER = FUNCTION NUMVAL(LS-TEXT(1:LS-LEN))
        ON SIZE ERROR
            EXIT PARAGRAPH
    END-COMPUTE
    MOVE LS-NUMBER TO LS-NUMBER-TEXT
    STRING "N:" LS-NUMBER-TEXT DELIMITED BY SIZE INTO LS-VALUE.

*> LS-VALUE as the next element, or, after THRU, as the end of the
*> range the last element starts. LS-ELEMENT-COUNT is set to 0 when
*> there are too many.
ADD-ELEMENT.
    IF LS-AFTER-THRU = "Y" AND LS-ELEMENT-COUNT > 0
        MOVE SPACES TO LS-SWAP
        STRING FUNCTION TRIM(LS-ELEMENT(LS-ELEMENT-COUNT) TRAILING)
               " THRU " DELIMITED BY SIZE
               FUNCTION TRIM(LS-VALUE TRAILING) DELIMITED BY SIZE
            INTO LS-SWAP
        MOVE LS-SWAP TO LS-ELEMENT(LS-ELEMENT-COUNT)
        MOVE "N" TO LS-AFTER-THRU
        EXIT PARAGRAPH
    END-IF
    IF LS-ELEMENT-COUNT >= ELEMENT-MAX
        MOVE 0 TO LS-ELEMENT-COUNT
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-ELEMENT-COUNT
    MOVE LS-VALUE TO LS-ELEMENT(LS-ELEMENT-COUNT).

*> A few values at most: an insertion sort.
SORT-ELEMENTS.
    PERFORM VARYING LS-I FROM 2 BY 1 UNTIL LS-I > LS-ELEMENT-COUNT
        MOVE LS-ELEMENT(LS-I) TO LS-SWAP
        MOVE LS-I TO LS-J
        PERFORM UNTIL LS-J = 1
            IF LS-ELEMENT(LS-J - 1) <= LS-SWAP
                EXIT PERFORM
            END-IF
            MOVE LS-ELEMENT(LS-J - 1) TO LS-ELEMENT(LS-J)
            SUBTRACT 1 FROM LS-J
        END-PERFORM
        MOVE LS-SWAP TO LS-ELEMENT(LS-J)
    END-PERFORM.

REPORT-DUPLICATE.
    MOVE LS-COND-SYMBOL(LS-I) TO LS-C
    MOVE SL-LINE-NO(TK-SRC-LINE(SY-NAME-TOKEN(LS-C))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-S) DELIMITED BY SPACE
           " has the same values as " DELIMITED BY SIZE
           SY-NAME(LS-C) DELIMITED BY SPACE
           " on line " LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", another condition of " DELIMITED BY SIZE
           SY-NAME(LS-PARENT) DELIMITED BY SPACE
           ": the two cannot be told apart" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE SY-NAME-TOKEN(LS-S) LS-MESSAGE.
END PROGRAM PLB-RULE-C064.
