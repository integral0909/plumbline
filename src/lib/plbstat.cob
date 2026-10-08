*> ---------------------------------------------------------------
*> plbstat: the FILE STATUS items of a file's programs.
*>
*> PLB-STATUS-ITEMS USING TOKENS AST ITEMS fills ITEMS (plbstat.cpy)
*> from the SELECT statements: SELECT ... [FILE] STATUS [IS] name.
*> PLB-STATUS-ITEM-OF USING SYMBOLS ITEMS SYMBOL RESULT sets RESULT to
*> "Y" when data item SYMBOL (not a condition name) is a status item of
*> its program, else "N".
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STATUS-ITEMS.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbstat.cpy".
PROCEDURE DIVISION USING PLB-TOKENS PLB-AST PLB-STATUS-ITEMS.
    MOVE 0 TO SI-COUNT
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "SELE"
            PERFORM COLLECT-STATUS
        END-IF
    END-PERFORM
    GOBACK.

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
                IF TK-IS-WORD(LS-K) AND SI-COUNT < SI-MAX
                    ADD 1 TO SI-COUNT
                    MOVE LS-TEXT TO SI-NAME(SI-COUNT)
                    MOVE LS-NODE TO LS-UP
                    PERFORM UNTIL LS-UP = 0
                        IF ND-KIND(LS-UP) = "PROG"
                            EXIT PERFORM
                        END-IF
                        MOVE ND-PARENT(LS-UP) TO LS-UP
                    END-PERFORM
                    MOVE LS-UP TO SI-PROGRAM(SI-COUNT)
                END-IF
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.
END PROGRAM PLB-STATUS-ITEMS.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-STATUS-ITEM-OF.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-K                    PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsym.cpy".
COPY "plbstat.cpy".
01  LK-SYMBOL               PIC 9(9) COMP-5.
01  LK-RESULT               PIC X.
PROCEDURE DIVISION USING PLB-SYMBOLS PLB-STATUS-ITEMS LK-SYMBOL
        LK-RESULT.
    MOVE "N" TO LK-RESULT
    IF LK-SYMBOL = 0 OR LK-SYMBOL > SY-COUNT
        GOBACK
    END-IF
    IF SY-LEVEL(LK-SYMBOL) = 88
        GOBACK
    END-IF
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > SI-COUNT
        IF SI-NAME(LS-K) = SY-NAME(LK-SYMBOL)
           AND SI-PROGRAM(LS-K) = SY-PROGRAM(LK-SYMBOL)
            MOVE "Y" TO LK-RESULT
            GOBACK
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-STATUS-ITEM-OF.
