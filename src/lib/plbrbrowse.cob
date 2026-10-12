*> ---------------------------------------------------------------
*> plbrbrowse: PLB-K009 browse-not-active.
*>
*> A CICS browse command for a file whose browse is not active, found
*> later in the same list of statements:
*>
*>     EXEC CICS ENDBR FILE('ACCTDAT') END-EXEC
*>     EXEC CICS READNEXT FILE('ACCTDAT') INTO(WS-REC)
*>         RIDFLD(WS-KEY) END-EXEC                  no browse
*>
*> After ENDBR, a READNEXT, READPREV, RESETBR, or ENDBR of the file
*> before a STARTBR of it has no browse to act on; after STARTBR,
*> another STARTBR before the ENDBR starts one that is already active.
*> CICS raises INVREQ, which abends the task unless the program
*> handles it. The statements after the ENDBR or STARTBR are read in
*> their list (for a statement directly in a sentence, on through the
*> paragraph's later sentences); a STARTBR (or ENDBR) of the file ends
*> the search, as do a PERFORM of a procedure, GO TO, CALL, GOBACK,
*> STOP, EXIT, and a statement holding other CICS commands. Files are
*> compared by what FILE or DATASET names, as written; commands with a
*> REQID, which runs several browses of one file, are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-K009.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-NEXT                 PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-VERB                 PIC X(31).
01  LS-FILE                 PIC X(40).
01  LS-FROM-VERB            PIC X(31).
01  LS-FROM-FILE            PIC X(40).
01  LS-REQID                PIC X.
01  LS-WORD                 PIC X(40).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-STOP                 PIC X.
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
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-RULES
        PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K009" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "STMT" AND ND-DETAIL(LS-NODE) = "EXEC"
            MOVE LS-NODE TO LS-STMT
            PERFORM CICS-COMMAND
            IF (LS-VERB = "ENDBR" OR LS-VERB = "STARTBR")
               AND LS-FILE NOT = SPACES AND LS-REQID = "N"
                MOVE LS-VERB TO LS-FROM-VERB
                MOVE LS-FILE TO LS-FROM-FILE
                PERFORM CHECK-AFTER
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> EXEC CICS verb ... in statement LS-STMT: LS-VERB, LS-FILE (the
*> text of FILE( ) or DATASET( ), upper-cased), and LS-REQID; spaces
*> when it is no CICS command.
CICS-COMMAND.
    MOVE SPACES TO LS-VERB LS-FILE
    MOVE "N" TO LS-REQID
    IF ND-TOK-FIRST(LS-STMT) + 2 > ND-TOK-LAST(LS-STMT)
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = "CICS"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-VERB LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-VERB) TO LS-VERB
    PERFORM VARYING LS-T FROM LS-T BY 1
            UNTIL LS-T + 2 > ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            COMPUTE LS-K = LS-T + 1
            IF TK-IS-LPAREN(LS-K)
                EVALUATE LS-WORD
                    WHEN "FILE" WHEN "DATASET"
                        ADD 1 TO LS-K
                        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K
                            LS-FILE LS-LEN
                        MOVE FUNCTION UPPER-CASE(LS-FILE) TO LS-FILE
                    WHEN "REQID"
                        MOVE "Y" TO LS-REQID
                END-EVALUATE
            END-IF
        END-IF
    END-PERFORM.

*> The statements after ENDBR or STARTBR LS-NODE of LS-FROM-FILE.
CHECK-AFTER.
    MOVE LS-NODE TO LS-STMT
    MOVE "N" TO LS-STOP
    PERFORM UNTIL LS-STOP = "Y"
        PERFORM NEXT-STATEMENT
        IF LS-NEXT = 0
            EXIT PERFORM
        END-IF
        MOVE LS-NEXT TO LS-STMT
        EVALUATE ND-DETAIL(LS-STMT)
            WHEN "EXEC"
                PERFORM CICS-COMMAND
                IF LS-VERB = SPACES OR LS-REQID = "Y"
                    MOVE "Y" TO LS-STOP
                END-IF
                IF LS-STOP = "N" AND LS-FILE = LS-FROM-FILE
                    PERFORM CHECK-COMMAND
                END-IF
            WHEN "GO" WHEN "CALL" WHEN "GOBACK" WHEN "STOP" WHEN "EXIT"
                MOVE "Y" TO LS-STOP
            WHEN OTHER
                PERFORM CHECK-OTHER
        END-EVALUATE
    END-PERFORM.

*> A browse command for the file, after the ENDBR or STARTBR.
CHECK-COMMAND.
    EVALUATE TRUE
        WHEN LS-FROM-VERB = "ENDBR"
             AND (LS-VERB = "READNEXT" OR LS-VERB = "READPREV"
                  OR LS-VERB = "RESETBR" OR LS-VERB = "ENDBR")
            PERFORM REPORT-NOT-ACTIVE
            MOVE "Y" TO LS-STOP
        WHEN LS-FROM-VERB = "STARTBR" AND LS-VERB = "STARTBR"
            PERFORM REPORT-ACTIVE
            MOVE "Y" TO LS-STOP
        WHEN LS-VERB = "STARTBR" OR LS-VERB = "ENDBR"
            MOVE "Y" TO LS-STOP
    END-EVALUATE.

*> A PERFORM of a procedure, or other CICS commands inside the
*> statement, ends the search.
CHECK-OTHER.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF FUNCTION UPPER-CASE(LS-WORD) = "EXEC"
                MOVE "Y" TO LS-STOP
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    IF ND-DETAIL(LS-STMT) = "PERFORM"
        MOVE ND-FIRST(LS-STMT) TO LS-UP
        PERFORM UNTIL LS-UP = 0
            IF ND-KIND(LS-UP) = "PROC"
                MOVE "Y" TO LS-STOP
                EXIT PARAGRAPH
            END-IF
            MOVE ND-NEXT(LS-UP) TO LS-UP
        END-PERFORM
    END-IF.

*> LS-NEXT: the statement after LS-STMT in its list, or the first of
*> the next sentence of the paragraph; 0 when there is none.
NEXT-STATEMENT.
    MOVE ND-NEXT(LS-STMT) TO LS-NEXT
    IF LS-NEXT > 0
        IF ND-KIND(LS-NEXT) NOT = "STMT"
            MOVE 0 TO LS-NEXT
        END-IF
        EXIT PARAGRAPH
    END-IF
    MOVE ND-PARENT(LS-STMT) TO LS-UP
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

REPORT-NOT-ACTIVE.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "the browse of " DELIMITED BY SIZE
           LS-FROM-FILE DELIMITED BY SPACE
           " ended on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ", with no STARTBR between: CICS rejects this "
           DELIMITED BY SIZE
           LS-VERB DELIMITED BY SPACE
           " (INVREQ)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-STMT) LS-MESSAGE.

REPORT-ACTIVE.
    MOVE SL-LINE-NO(TK-SRC-LINE(ND-TOK-FIRST(LS-NODE))) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "the browse of " DELIMITED BY SIZE
           LS-FROM-FILE DELIMITED BY SPACE
           " started on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " is still active, with no ENDBR between: CICS rejects "
           "this STARTBR (INVREQ)" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-STMT) LS-MESSAGE.
END PROGRAM PLB-RULE-K009.
