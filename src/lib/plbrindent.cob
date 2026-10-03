*> ---------------------------------------------------------------
*> plbrindent: PLB-C057 misleading-indentation.
*>
*> A statement indented as if it were inside the IF (or other statement
*> with a body) before it, when a period has already ended that
*> statement:
*>
*>     IF WS-AMOUNT > WS-LIMIT
*>         MOVE "Y" TO WS-OVER-LIMIT.
*>         PERFORM 900-WRITE-EXCEPTION       *> reported: always runs
*>
*> The period ends every open statement, so the PERFORM runs whatever
*> the condition. Either the period is a mistake (it is the classic
*> one) or the indentation is.
*>
*> The statement reported is the first of a sentence whose sentence
*> before it, in the same paragraph, ends with a statement that has a
*> body (IF, EVALUATE, SEARCH, inline PERFORM, READ ... AT END, ...),
*> and which starts further right than that statement, on a later
*> line, in the same file. Statements from copybooks are left alone.
*>
*> An IF without ELSE whose body ends by leaving (GO TO, GOBACK, STOP
*> RUN, EXIT PROGRAM, EXIT PARAGRAPH, ...) is left alone too: what
*> follows it runs only when the condition is false, and indenting it
*> as an "else" is a common style:
*>
*>     IF WS-STATUS = "10"
*>         GO TO 900-END-OF-FILE.
*>         ADD 1 TO WS-RECORDS
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C057.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-HAS-BODY             PIC X.
01  LS-HAS-ELSE             PIC X.
01  LS-BODY                 PIC 9(9) COMP-5.
01  LS-LEAVES               PIC X.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-LINE-TEXT            PIC X(20).
01  LS-LINE-LEN             PIC 9(9) COMP-5.
01  LS-PERIOD-TEXT          PIC X(20).
01  LS-PERIOD-LEN           PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C057" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "SENT" AND ND-NEXT(LS-NODE) > 0
            MOVE ND-NEXT(LS-NODE) TO LS-NEXT
            IF ND-KIND(LS-NEXT) = "SENT"
                PERFORM CHECK-SENTENCES
            END-IF
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

*> Sentence LS-NODE and the one after it, LS-NEXT.
CHECK-SENTENCES.
    MOVE ND-LAST(LS-NODE) TO LS-LAST
    MOVE ND-FIRST(LS-NEXT) TO LS-FIRST
    IF LS-LAST = 0 OR LS-FIRST = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-LAST) NOT = "STMT" OR ND-KIND(LS-FIRST) NOT = "STMT"
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-HAS-BODY LS-HAS-ELSE
    MOVE 0 TO LS-BODY
    MOVE ND-FIRST(LS-LAST) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK"
            MOVE "Y" TO LS-HAS-BODY
            IF LS-BODY = 0
                MOVE LS-CHILD TO LS-BODY
            END-IF
            IF ND-DETAIL(LS-CHILD) = "ELSE"
                MOVE "Y" TO LS-HAS-ELSE
            END-IF
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM
    IF LS-HAS-BODY = "N"
        EXIT PARAGRAPH
    END-IF
    IF ND-DETAIL(LS-LAST) = "IF" AND LS-HAS-ELSE = "N"
        PERFORM TEST-LEAVES
        IF LS-LEAVES = "Y"
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE ND-TOK-FIRST(LS-LAST) TO LS-T
    MOVE ND-TOK-FIRST(LS-FIRST) TO LS-U
    *> The period that ends the sentence.
    MOVE ND-TOK-LAST(LS-NODE) TO LS-P
    IF TK-INCL(LS-T) NOT = 0 OR TK-INCL(LS-U) NOT = 0
       OR TK-FILE-ID(LS-T) NOT = TK-FILE-ID(LS-U)
        EXIT PARAGRAPH
    END-IF
    IF TK-SRC-LINE(LS-U) <= TK-SRC-LINE(LS-P)
        EXIT PARAGRAPH
    END-IF
    IF TK-COLUMN(LS-U) > TK-COLUMN(LS-T)
        PERFORM REPORT-INDENTATION
    END-IF.

*> LS-LEAVES = "Y" when the last statement of block LS-BODY leaves it.
TEST-LEAVES.
    MOVE "N" TO LS-LEAVES
    MOVE ND-LAST(LS-BODY) TO LS-CHILD
    IF LS-CHILD = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-CHILD) NOT = "STMT"
        EXIT PARAGRAPH
    END-IF
    EVALUATE ND-DETAIL(LS-CHILD)
        WHEN "GO" WHEN "GOBACK" WHEN "STOP" WHEN "EXIT"
            MOVE "Y" TO LS-LEAVES
    END-EVALUATE.

REPORT-INDENTATION.
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-T)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-LINE-TEXT LS-LINE-LEN
    MOVE SL-LINE-NO(TK-SRC-LINE(LS-P)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-PERIOD-TEXT LS-PERIOD-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING ND-DETAIL(LS-FIRST) DELIMITED BY SPACE
           " is indented as if inside the " DELIMITED BY SIZE
           ND-DETAIL(LS-LAST) DELIMITED BY SPACE
           " on line " LS-LINE-TEXT(1:LS-LINE-LEN)
           ", but the period on line " LS-PERIOD-TEXT(1:LS-PERIOD-LEN)
           " ended it, so the statement is not part of it"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-U LS-MESSAGE.
END PROGRAM PLB-RULE-C057.
