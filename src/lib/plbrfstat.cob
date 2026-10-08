*> ---------------------------------------------------------------
*> plbrfstat: PLB-C084 file-status-unknown.
*>
*> A FILE STATUS item compared with a code no I/O statement returns:
*>
*>     SELECT IN-FILE ASSIGN TO "in.dat" FILE STATUS IS WS-FS.
*>     ...
*>     IF WS-FS = "01"
*>
*> No I/O statement returns that code, so the test does not catch what
*> it was written for.
*> Usually a digit is wrong ("01" for "10"), or a one-character code
*> was written for a two-character status. The codes known are those
*> of GnuCOBOL 3.2 (libcob/common.h), which include the standard's:
*> 00, 02, 04 to 07, 09, 10, 14, 21 to 24, 30, 31, 34, 35, 37 to 39,
*> 41 to 49, 51 to 54, 57, 61, and 71; and any code that starts with 9,
*> which each implementation defines for itself.
*>
*> Checked are the alphanumeric literals in comparisons of the status
*> item with = (or EQUAL TO, NOT =), with the abbreviated OR and AND
*> forms after them; the single-literal WHEN phrases of an EVALUATE of
*> the item; and the VALUE literals of its condition names. The item is
*> the one named after FILE STATUS in a SELECT of the same program,
*> without reference modification or subscripts. A literal that the
*> program itself moves into the item (MOVE "<>" TO WS-FS, a marker
*> for "not set yet") is a value it can hold, and is not reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C084.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  STATUS-MAX              VALUE 512.
01  WS-STATUS-ITEMS.
    05  WS-STATUS-COUNT     PIC 9(9) COMP-5.
    05  WS-STATUS-NAME      PIC X(31) OCCURS STATUS-MAX TIMES.
    05  WS-STATUS-PROGRAM   PIC 9(9) COMP-5 OCCURS STATUS-MAX TIMES.
*> The codes, two characters each.
01  WS-KNOWN                PIC X(72) VALUE
    "000204050607091014212223243031343537383941424344"
    & "454647484951525354576171".
*> Literals the program moves into status items: item and text.
78  MOVED-MAX               VALUE 1024.
01  WS-MOVED.
    05  WS-MOVED-COUNT      PIC 9(9) COMP-5.
    05  WS-MOVED-SYMBOL     PIC 9(9) COMP-5 OCCURS MOVED-MAX TIMES.
    05  WS-MOVED-TEXT       PIC X(31) OCCURS MOVED-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-X                    PIC 9(9) COMP-5.
01  LS-LIT                  PIC 9(9) COMP-5.
01  LS-AFTER-THRU           PIC X.
01  LS-IS-STATUS            PIC X.
01  LS-OK                   PIC X.
01  LS-CODE                 PIC X(2).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C084" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 0 TO WS-STATUS-COUNT
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "SELE"
            PERFORM COLLECT-STATUS
        END-IF
    END-PERFORM
    IF WS-STATUS-COUNT = 0
        GOBACK
    END-IF
    *> MOVE literal TO status item.
    MOVE 0 TO WS-MOVED-COUNT
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
           AND RF-STMT(LS-R) > 0 AND RF-ROLE(LS-R) = "D"
            IF ND-DETAIL(RF-STMT(LS-R)) = "MOVE"
                MOVE RF-SYMBOL(LS-R) TO LS-X
                PERFORM TEST-STATUS-SYMBOL
                COMPUTE LS-T = ND-TOK-FIRST(RF-STMT(LS-R)) + 1
                IF LS-IS-STATUS = "Y" AND TK-IS-ALNUM(LS-T)
                   AND TK-TEXT-LEN(LS-T) <= 31
                   AND WS-MOVED-COUNT < MOVED-MAX
                    ADD 1 TO WS-MOVED-COUNT
                    MOVE LS-X TO WS-MOVED-SYMBOL(WS-MOVED-COUNT)
                    MOVE SPACES TO WS-MOVED-TEXT(WS-MOVED-COUNT)
                    IF TK-TEXT-LEN(LS-T) > 0
                        MOVE TK-TEXT(TK-TEXT-OFF(LS-T):TK-TEXT-LEN(LS-T))
                            TO WS-MOVED-TEXT(WS-MOVED-COUNT)
                    END-IF
                END-IF
            END-IF
        END-IF
    END-PERFORM
    *> The condition names of each status item.
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-LEVEL(LS-S) = 88 AND SY-PARENT(LS-S) > 0
           AND SY-NODE(LS-S) > 0
            MOVE SY-PARENT(LS-S) TO LS-X
            PERFORM TEST-STATUS-SYMBOL
            IF LS-IS-STATUS = "Y"
                PERFORM CHECK-CONDITION-NAME
            END-IF
        END-IF
    END-PERFORM
    *> Comparisons in the procedure division.
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
           AND RF-STMT(LS-R) > 0 AND RF-REFMOD(LS-R) = "N"
           AND RF-SUBSCRIPTED(LS-R) = "N"
            MOVE RF-SYMBOL(LS-R) TO LS-X
            PERFORM TEST-STATUS-SYMBOL
            IF LS-IS-STATUS = "Y"
                PERFORM CHECK-REFERENCE
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> SELECT ... [FILE] STATUS [IS] name: the name, with its program.
COLLECT-STATUS.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-NODE)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "STATUS"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
                IF LS-TEXT = "IS"
                    ADD 1 TO LS-K
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT
                        LS-LEN
                END-IF
                IF TK-IS-WORD(LS-K) AND WS-STATUS-COUNT < STATUS-MAX
                    ADD 1 TO WS-STATUS-COUNT
                    MOVE LS-TEXT TO WS-STATUS-NAME(WS-STATUS-COUNT)
                    MOVE LS-NODE TO LS-UP
                    PERFORM UNTIL LS-UP = 0
                        IF ND-KIND(LS-UP) = "PROG"
                            EXIT PERFORM
                        END-IF
                        MOVE ND-PARENT(LS-UP) TO LS-UP
                    END-PERFORM
                    MOVE LS-UP TO WS-STATUS-PROGRAM(WS-STATUS-COUNT)
                END-IF
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> LS-IS-STATUS = "Y" when symbol LS-X is a status item.
TEST-STATUS-SYMBOL.
    MOVE "N" TO LS-IS-STATUS
    IF SY-LEVEL(LS-X) = 88
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > WS-STATUS-COUNT
        IF WS-STATUS-NAME(LS-K) = SY-NAME(LS-X)
           AND WS-STATUS-PROGRAM(LS-K) = SY-PROGRAM(LS-X)
            MOVE "Y" TO LS-IS-STATUS
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> The VALUE literals of condition name LS-S, but not the ends of a
*> THRU range.
CHECK-CONDITION-NAME.
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
    MOVE "N" TO LS-AFTER-THRU
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-C) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-C)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "THRU" OR LS-TEXT = "THROUGH"
                MOVE "Y" TO LS-AFTER-THRU
            END-IF
        END-IF
        IF TK-IS-ALNUM(LS-T)
            COMPUTE LS-K = LS-T + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
            IF LS-AFTER-THRU = "N"
               AND LS-TEXT NOT = "THRU" AND LS-TEXT NOT = "THROUGH"
                MOVE LS-T TO LS-LIT
                PERFORM CHECK-LITERAL
            END-IF
            MOVE "N" TO LS-AFTER-THRU
        END-IF
    END-PERFORM.

*> Reference LS-R to a status item: compared with =, or the subject of
*> an EVALUATE.
CHECK-REFERENCE.
    IF ND-DETAIL(RF-STMT(LS-R)) = "EVALUATE"
        PERFORM CHECK-EVALUATE
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = RF-LAST(LS-R) + 1
    PERFORM SKIP-WORD-IS
    PERFORM SKIP-WORD-NOT
    IF LS-T > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    EVALUATE TRUE
        WHEN TK-IS-OPERATOR(LS-T) AND LS-TEXT = "="
            ADD 1 TO LS-T
        WHEN TK-IS-WORD(LS-T) AND LS-TEXT = "EQUAL"
            ADD 1 TO LS-T
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF TK-IS-WORD(LS-T) AND LS-TEXT = "TO"
                ADD 1 TO LS-T
            END-IF
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    *> The literal, then the abbreviated ones after OR or AND.
    PERFORM UNTIL LS-T > ND-TOK-LAST(RF-STMT(LS-R))
        IF NOT TK-IS-ALNUM(LS-T)
            EXIT PERFORM
        END-IF
        MOVE LS-T TO LS-LIT
        PERFORM CHECK-LITERAL
        COMPUTE LS-K = LS-T + 1
        IF LS-K > ND-TOK-LAST(RF-STMT(LS-R)) OR NOT TK-IS-WORD(LS-K)
            EXIT PERFORM
        END-IF
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
        IF LS-TEXT NOT = "OR" AND LS-TEXT NOT = "AND"
            EXIT PERFORM
        END-IF
        COMPUTE LS-T = LS-K + 1
    END-PERFORM.

SKIP-WORD-IS.
    IF LS-T <= TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "IS"
                ADD 1 TO LS-T
            END-IF
        END-IF
    END-IF.

SKIP-WORD-NOT.
    IF LS-T <= TK-COUNT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF LS-TEXT = "NOT"
                ADD 1 TO LS-T
            END-IF
        END-IF
    END-IF.

*> EVALUATE status-item: each WHEN phrase that is one literal.
CHECK-EVALUATE.
    MOVE RF-STMT(LS-R) TO LS-NODE
    MOVE ND-FIRST(LS-NODE) TO LS-C
    *> The item must be the whole subject.
    IF LS-C = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-C) NOT = "COND"
       OR ND-TOK-FIRST(LS-C) NOT = RF-TOKEN(LS-R)
       OR ND-TOK-LAST(LS-C) NOT = RF-LAST(LS-R)
        EXIT PARAGRAPH
    END-IF
    PERFORM UNTIL LS-C = 0
        IF ND-KIND(LS-C) = "BLCK" AND ND-DETAIL(LS-C) = "WHEN"
            MOVE ND-FIRST(LS-C) TO LS-UP
            IF LS-UP > 0
                IF ND-KIND(LS-UP) = "COND"
                   AND ND-TOK-FIRST(LS-UP) = ND-TOK-LAST(LS-UP)
                   AND TK-IS-ALNUM(ND-TOK-FIRST(LS-UP))
                    MOVE ND-TOK-FIRST(LS-UP) TO LS-LIT
                    PERFORM CHECK-LITERAL
                END-IF
            END-IF
        END-IF
        MOVE ND-NEXT(LS-C) TO LS-C
    END-PERFORM.

*> Literal LS-LIT: a code a status can hold?
CHECK-LITERAL.
    IF TK-PREFIX(LS-LIT) NOT = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-OK
    IF TK-TEXT-LEN(LS-LIT) = 2
        MOVE TK-TEXT(TK-TEXT-OFF(LS-LIT):2) TO LS-CODE
        IF LS-CODE(1:1) = "9"
            MOVE "Y" TO LS-OK
        ELSE
            PERFORM VARYING LS-K FROM 1 BY 2 UNTIL LS-K > 72
                IF WS-KNOWN(LS-K:2) = LS-CODE
                    MOVE "Y" TO LS-OK
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
    END-IF
    *> A value the program moves into the item itself.
    IF LS-OK = "N" AND TK-TEXT-LEN(LS-LIT) <= 31
        MOVE SPACES TO LS-TEXT
        IF TK-TEXT-LEN(LS-LIT) > 0
            MOVE TK-TEXT(TK-TEXT-OFF(LS-LIT):TK-TEXT-LEN(LS-LIT))
                TO LS-TEXT
        END-IF
        PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > WS-MOVED-COUNT
            IF WS-MOVED-SYMBOL(LS-K) = LS-X
               AND WS-MOVED-TEXT(LS-K) = LS-TEXT
                MOVE "Y" TO LS-OK
                EXIT PERFORM
            END-IF
        END-PERFORM
    END-IF
    IF LS-OK = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING '"' DELIMITED BY SIZE
           TK-TEXT(TK-TEXT-OFF(LS-LIT):TK-TEXT-LEN(LS-LIT))
           DELIMITED BY SIZE
           '" is no file status code: no I/O statement sets the status'
           ' item to it' DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-LIT LS-MESSAGE.
END PROGRAM PLB-RULE-C084.
