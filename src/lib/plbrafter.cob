*> ---------------------------------------------------------------
*> plbrafter: PLB-C091 varying-counter-repeated.
*>
*> A PERFORM VARYING whose AFTER phrase names the same counter as the
*> VARYING phrase, or as another AFTER phrase:
*>
*>     PERFORM FILL-CELL VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3
*>                         AFTER WS-I FROM 1 BY 1 UNTIL WS-I > 3
*>
*> Each time the outer phrase steps its counter, the inner one sets it
*> back to its FROM value, so the outer condition is tested on that
*> value: unless that value meets it, the loop never ends, as with
*> GnuCOBOL 3.2 the one above. Usually the AFTER phrase was copied and
*> its counter not changed. Counters are compared by the data item they
*> name, without subscripts.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C091.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  COUNTER-MAX             VALUE 8.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> The symbols of the counters.
01  LS-COUNT                PIC 9(4) COMP-5.
01  LS-SYMBOL               PIC 9(9) COMP-5 OCCURS COUNTER-MAX TIMES.
01  LS-FOUND                PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C091" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "PERFORM"
            PERFORM CHECK-PERFORM
        END-IF
    END-PERFORM
    GOBACK.

*> The counter after VARYING, then after each AFTER, up to the body.
CHECK-PERFORM.
    MOVE ND-TOK-LAST(LS-NODE) TO LS-LAST
    MOVE ND-FIRST(LS-NODE) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            COMPUTE LS-LAST = ND-TOK-FIRST(LS-CHILD) - 1
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    MOVE 0 TO LS-COUNT
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= LS-LAST
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "VARYING" OR LS-WORD = "AFTER"
                COMPUTE LS-NEXT = LS-T + 1
                PERFORM ADD-COUNTER
            END-IF
        END-IF
    END-PERFORM.

*> The data item at LS-NEXT, if it is one (WITH TEST AFTER is
*> followed by a keyword), against the counters before it.
ADD-COUNTER.
    MOVE 0 TO LS-FOUND
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-NEXT
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
               AND RF-SUBSCRIPTED(LS-R) = "N"
               AND RF-REFMOD(LS-R) = "N"
                MOVE RF-SYMBOL(LS-R) TO LS-FOUND
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-COUNT
        IF LS-SYMBOL(LS-I) = LS-FOUND
            PERFORM REPORT-REPEATED
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF LS-COUNT < COUNTER-MAX
        ADD 1 TO LS-COUNT
        MOVE LS-FOUND TO LS-SYMBOL(LS-COUNT)
    END-IF.

REPORT-REPEATED.
    MOVE SPACES TO LS-MESSAGE
    STRING SY-NAME(LS-FOUND) DELIMITED BY SPACE
           " is already the counter of an outer phrase of this "
           "PERFORM: this AFTER sets it back to its FROM value each "
           "time that phrase steps it" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-NEXT LS-MESSAGE.
END PROGRAM PLB-RULE-C091.
