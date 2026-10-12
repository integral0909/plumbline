*> ---------------------------------------------------------------
*> plbrswap: PLB-C092 swap-lost.
*>
*> Two MOVE statements in a row that move an item to another and back:
*>
*>     MOVE WS-A TO WS-B
*>     MOVE WS-B TO WS-A                    WS-A gets back its own value
*>
*> Meant as a swap, it loses the value of WS-B: a swap needs a third
*> item. Reported only when WS-B holds every value of WS-A as it is
*> (both alphanumeric and WS-B no shorter, or both numeric and WS-B
*> with as many digits before and after the point, and a sign if WS-A
*> has one): then the second MOVE does nothing. Moving through a
*> smaller item and back is a way to cut a value (decimal places, the
*> end of a text), and is not reported. As for PLB-C033, the names
*> must stand alone, without qualification, subscripts, or reference
*> modification.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C092.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-ITEM                 PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
*> The sender and receiver of a MOVE (0 when it is not one read).
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-B                    PIC 9(9) COMP-5.
01  LS-HOLDS                PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C092" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "MOVE"
            PERFORM CHECK-MOVE
        END-IF
    END-PERFORM
    GOBACK.

*> MOVE LS-NODE, A TO B, and the statement after it, B TO A.
CHECK-MOVE.
    MOVE LS-NODE TO LS-STMT
    PERFORM READ-MOVE
    IF LS-FROM = 0
        EXIT PARAGRAPH
    END-IF
    MOVE LS-FROM TO LS-A
    MOVE LS-TO TO LS-B
    PERFORM NEXT-STATEMENT
    IF LS-NEXT = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-DETAIL(LS-NEXT) NOT = "MOVE"
        EXIT PARAGRAPH
    END-IF
    MOVE LS-NEXT TO LS-STMT
    PERFORM READ-MOVE
    IF LS-FROM NOT = LS-B OR LS-TO NOT = LS-A OR LS-A = LS-B
        EXIT PARAGRAPH
    END-IF
    PERFORM B-HOLDS-A
    IF LS-HOLDS = "Y"
        PERFORM REPORT-SWAP
    END-IF.

*> LS-FROM and LS-TO: the items of MOVE LS-STMT when it is exactly
*> MOVE name TO name, each a data item standing alone; else 0.
READ-MOVE.
    MOVE 0 TO LS-FROM LS-TO
    IF ND-TOK-LAST(LS-STMT) NOT = ND-TOK-FIRST(LS-STMT) + 3
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 2
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "TO"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    PERFORM ITEM-AT
    MOVE LS-ITEM TO LS-FROM
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 3
    PERFORM ITEM-AT
    MOVE LS-ITEM TO LS-TO
    IF LS-FROM = 0 OR LS-TO = 0
        MOVE 0 TO LS-FROM LS-TO
    END-IF.

*> LS-ITEM: the symbol of the plain data reference at token LS-T, or 0.
ITEM-AT.
    MOVE 0 TO LS-ITEM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-TOKEN(LS-R) = LS-T
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
               AND RF-LAST(LS-R) = LS-T
                MOVE RF-SYMBOL(LS-R) TO LS-ITEM
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> LS-NEXT: the statement after LS-NODE in its list, or the first of
*> the next sentence of the paragraph; 0 when there is none.
NEXT-STATEMENT.
    MOVE ND-NEXT(LS-NODE) TO LS-NEXT
    IF LS-NEXT > 0
        IF ND-KIND(LS-NEXT) NOT = "STMT"
            MOVE 0 TO LS-NEXT
        END-IF
        EXIT PARAGRAPH
    END-IF
    MOVE ND-PARENT(LS-NODE) TO LS-UP
    IF LS-UP = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-UP) NOT = "SENT"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-NEXT(LS-UP) TO LS-UP
    IF LS-UP = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-UP) = "SENT"
        MOVE ND-FIRST(LS-UP) TO LS-NEXT
        IF LS-NEXT > 0
            IF ND-KIND(LS-NEXT) NOT = "STMT"
                MOVE 0 TO LS-NEXT
            END-IF
        END-IF
    END-IF.

*> LS-HOLDS = "Y" when item LS-B holds every value of item LS-A.
B-HOLDS-A.
    MOVE "N" TO LS-HOLDS
    EVALUATE TRUE
        WHEN (SY-CATEGORY(LS-A) = "X" OR SY-CATEGORY(LS-A) = "A")
         AND SY-CATEGORY(LS-B) = "X"
            IF SY-SIZE(LS-B) >= SY-SIZE(LS-A)
                MOVE "Y" TO LS-HOLDS
            END-IF
        WHEN SY-CATEGORY(LS-A) = "A" AND SY-CATEGORY(LS-B) = "A"
            IF SY-SIZE(LS-B) >= SY-SIZE(LS-A)
                MOVE "Y" TO LS-HOLDS
            END-IF
        WHEN SY-CATEGORY(LS-A) = "9" AND SY-CATEGORY(LS-B) = "9"
            IF SY-DIGITS(LS-B) - SY-SCALE(LS-B)
                   >= SY-DIGITS(LS-A) - SY-SCALE(LS-A)
               AND SY-SCALE(LS-B) >= SY-SCALE(LS-A)
               AND SY-SCALE(LS-A) >= 0 AND SY-SCALE(LS-B) >= 0
               AND (SY-SIGNED(LS-B) = "Y" OR SY-SIGNED(LS-A) NOT = "Y")
                MOVE "Y" TO LS-HOLDS
            END-IF
    END-EVALUATE.

REPORT-SWAP.
    MOVE SPACES TO LS-MESSAGE
    STRING "this MOVE gives " DELIMITED BY SIZE
           SY-NAME(LS-A) DELIMITED BY SPACE
           " back the value the MOVE before it gave " DELIMITED BY SIZE
           SY-NAME(LS-B) DELIMITED BY SPACE
           ", so it does nothing, and the value " DELIMITED BY SIZE
           SY-NAME(LS-B) DELIMITED BY SPACE
           " had is lost: a swap needs a third item" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-NEXT) LS-MESSAGE.
END PROGRAM PLB-RULE-C092.
