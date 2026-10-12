*> ---------------------------------------------------------------
*> plbraccept: PLB-C088 accept-truncation.
*>
*> ACCEPT of the date or time into a numeric item with too few digits:
*>
*>     01  WS-TIME  PIC 9(6).
*>         ACCEPT WS-TIME FROM TIME        HHMMSShh: keeps MMSShh
*>
*> ACCEPT ... FROM DATE, DAY, DAY-OF-WEEK, or TIME moves an unsigned
*> whole number to the item, as MOVE does. A numeric item keeps the
*> digits on the right, so the ones lost are the year or the hours, and
*> what is left reads as a date or time that is wrong. Read are items
*> stored as decimal digits (DISPLAY or PACKED-DECIMAL); the digits
*> counted are those before the decimal point. A binary item does not
*> keep the last digits (COMP-5 wraps round its bytes), and is left
*> out with pictures with P. An alphanumeric item
*> keeps the characters on the left (HHMMSS of the time), which is
*> often what was meant, and is not reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C088.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> What the source gives: its name as written, its digits, and what
*> each digit is (as YYYYMMDD).
01  LS-SOURCE               PIC X(24).
01  LS-SOURCE-DIGITS        PIC 9(4) COMP-5.
01  LS-LAYOUT               PIC X(8).
01  LS-KEPT                 PIC S9(4) COMP-5.
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
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C088" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    *> The receiver of an ACCEPT is the reference that starts right
    *> after the word ACCEPT.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE RF-STMT(LS-R) TO LS-NODE
        IF LS-NODE > 0
            IF ND-DETAIL(LS-NODE) = "ACCEPT"
               AND RF-TOKEN(LS-R) = ND-TOK-FIRST(LS-NODE) + 1
               AND RF-KIND(LS-R) = "D" AND RF-REFMOD(LS-R) = "N"
                PERFORM CHECK-ACCEPT
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> ACCEPT receiver LS-R FROM a date or the time.
CHECK-ACCEPT.
    MOVE RF-LAST(LS-R) TO LS-T
    ADD 1 TO LS-T
    IF LS-T >= ND-TOK-LAST(LS-NODE)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "FROM"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    PERFORM READ-SOURCE
    IF LS-SOURCE-DIGITS = 0
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF LS-S = 0
        EXIT PARAGRAPH
    END-IF
    IF SY-CATEGORY(LS-S) NOT = "9" OR SY-DIGITS(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE SY-USAGE(LS-S)
        WHEN SPACES WHEN "DISPLAY" WHEN "PACKED-DECIMAL" WHEN "COMP-3"
        WHEN "COMPUTATIONAL-3"
            CONTINUE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    *> The digits before the decimal point. A picture with P left of
    *> the point (99PP) loses the low-order digits as well, which the
    *> message does not tell, and is left out.
    IF SY-SCALE(LS-S) < 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-KEPT = SY-DIGITS(LS-S) - SY-SCALE(LS-S)
    IF LS-KEPT < LS-SOURCE-DIGITS
        PERFORM REPORT-TRUNCATION
    END-IF.

*> At LS-T, the source: LS-SOURCE-DIGITS is 0 for one not read.
READ-SOURCE.
    MOVE 0 TO LS-SOURCE-DIGITS
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    EVALUATE LS-WORD
        WHEN "DATE"
            MOVE "DATE" TO LS-SOURCE
            MOVE 6 TO LS-SOURCE-DIGITS
            MOVE "YYMMDD" TO LS-LAYOUT
        WHEN "DAY"
            MOVE "DAY" TO LS-SOURCE
            MOVE 5 TO LS-SOURCE-DIGITS
            MOVE "YYDDD" TO LS-LAYOUT
        WHEN "TIME"
            MOVE "TIME" TO LS-SOURCE
            MOVE 8 TO LS-SOURCE-DIGITS
            MOVE "HHMMSShh" TO LS-LAYOUT
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    IF LS-T < ND-TOK-LAST(LS-NODE)
        ADD 1 TO LS-T
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
        EVALUATE TRUE
            WHEN LS-SOURCE = "DATE" AND LS-WORD = "YYYYMMDD"
                MOVE "DATE YYYYMMDD" TO LS-SOURCE
                MOVE 8 TO LS-SOURCE-DIGITS
                MOVE "YYYYMMDD" TO LS-LAYOUT
            WHEN LS-SOURCE = "DAY" AND LS-WORD = "YYYYDDD"
                MOVE "DAY YYYYDDD" TO LS-SOURCE
                MOVE 7 TO LS-SOURCE-DIGITS
                MOVE "YYYYDDD" TO LS-LAYOUT
            WHEN LS-WORD = "END-ACCEPT"
                CONTINUE
            WHEN OTHER
                *> Some other phrase follows; not a form read here.
                MOVE 0 TO LS-SOURCE-DIGITS
        END-EVALUATE
    END-IF.

*> The message names the digits the item keeps and those it loses,
*> by the source's layout.
REPORT-TRUNCATION.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    MOVE LS-SOURCE-DIGITS TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-SOURCE DELIMITED BY "  "
           " gives " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " digits (" DELIMITED BY SIZE
           LS-LAYOUT DELIMITED BY SPACE
           ") and " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           " keeps the last " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    MOVE LS-KEPT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " (" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF LS-KEPT > 0
        STRING LS-LAYOUT(LS-SOURCE-DIGITS - LS-KEPT + 1:LS-KEPT)
               DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    STRING "): " DELIMITED BY SIZE
           LS-LAYOUT(1:LS-SOURCE-DIGITS - LS-KEPT) DELIMITED BY SIZE
           " is lost" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C088.
