*> ---------------------------------------------------------------
*> plbrdli: the status of DL/I and MQ calls.
*>
*>   PLB-I005  dli-status-not-checked
*>   PLB-C070  mq-completion-not-checked
*>
*> A DL/I call whose status code nothing tests before the next call:
*>
*>     CALL 'CBLTDLI' USING FUNC-GU PAUTBPCB PENDING-AUTH-SUMMARY
*>                          ROOT-QUAL-SSA.
*>     MOVE PA-ACCT-ID TO WS-ACCT-ID
*>
*> When the segment is not found (GE), or the call fails, the I/O area
*> holds what it held before, and the program goes on with it. For
*> CALL 'CBLTDLI' the status is the status code of the PCB mask passed
*> (the second argument): any of the mask's items, or the mask itself,
*> named after the call counts as the test. For EXEC DLI it is
*> DIBSTAT. The test is looked for as for PLB-C018: after the call in
*> its paragraph, before the next DL/I call that can run after it (not
*> one in another branch of the same IF or EVALUATE), or in a
*> paragraph performed from there. EXEC DLI TERM, which ends the use
*> of the PSB, is left alone.
*>
*> PLB-C070 does the same for the calls of the IBM MQ interface (MQGET,
*> MQPUT, MQOPEN, ...), whose last two arguments are the completion
*> code and the reason: either named after the call counts as the
*> test. A failed MQGET leaves the buffer as it was; a failed MQPUT
*> loses the message.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-I005.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none).
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-MQ              PIC 9(4) COMP-5.
*> MQ: the tokens of the last two arguments, and the call's name.
01  LS-ARG-1                PIC 9(9) COMP-5.
01  LS-ARG-2                PIC 9(9) COMP-5.
01  LS-CALLED               PIC X(31).
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-FUNC                 PIC 9(9) COMP-5.
01  LS-PCB-TOKEN            PIC 9(9) COMP-5.
01  LS-PCB                  PIC 9(9) COMP-5.
01  LS-STOP                 PIC 9(9) COMP-5.
*> C for CALL 'CBLTDLI', E for EXEC DLI; the kind of each statement
*> looked at for the next call.
01  LS-KIND                 PIC X.
01  LS-OTHER-KIND           PIC X.
01  LS-FOUND                PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-FUNC-TEXT            PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
COPY "plbnlist.cpy".
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbflow.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-FLOW PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-I005" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C070" LS-RULE-MQ
    IF (RL-ENABLED(LS-RULE) NOT = "Y"
        AND RL-ENABLED(LS-RULE-MQ) NOT = "Y") OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        MOVE LS-NODE TO LS-N
        PERFORM DLI-KIND
        EVALUATE TRUE
            WHEN LS-OTHER-KIND = "C" AND RL-ENABLED(LS-RULE) = "Y"
                MOVE LS-NODE TO LS-STMT
                PERFORM CHECK-CALL
            WHEN LS-OTHER-KIND = "E" AND RL-ENABLED(LS-RULE) = "Y"
                MOVE LS-NODE TO LS-STMT
                PERFORM CHECK-EXEC
            WHEN LS-OTHER-KIND = "M" AND RL-ENABLED(LS-RULE-MQ) = "Y"
                MOVE LS-NODE TO LS-STMT
                PERFORM CHECK-MQ
        END-EVALUATE
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> LS-OTHER-KIND for node LS-N: C a CALL of CBLTDLI, E an EXEC DLI, M
*> a CALL of the MQ interface, space anything else.
DLI-KIND.
    MOVE SPACE TO LS-OTHER-KIND
    IF ND-KIND(LS-N) NOT = "STMT"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    EVALUATE ND-DETAIL(LS-N)
        WHEN "CALL"
            IF TK-IS-ALNUM(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                EVALUATE FUNCTION UPPER-CASE(LS-TEXT)
                    WHEN "CBLTDLI"
                        MOVE "C" TO LS-OTHER-KIND
                    WHEN "MQCONN" WHEN "MQCONNX" WHEN "MQOPEN"
                    WHEN "MQGET" WHEN "MQPUT" WHEN "MQPUT1"
                    WHEN "MQCLOSE" WHEN "MQDISC" WHEN "MQINQ"
                    WHEN "MQSET" WHEN "MQCMIT" WHEN "MQBACK"
                    WHEN "MQBEGIN"
                        MOVE "M" TO LS-OTHER-KIND
                END-EVALUATE
            END-IF
        WHEN "EXEC"
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "DLI"
                MOVE "E" TO LS-OTHER-KIND
            END-IF
    END-EVALUATE.

*> CALL 'CBLTDLI' USING function pcb ...: the PCB mask and its items.
CHECK-CALL.
    MOVE "C" TO LS-KIND
    MOVE 0 TO LS-FUNC LS-PCB-TOKEN
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-STMT)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "USING"
                COMPUTE LS-FUNC = LS-T + 1
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-FUNC = 0
        EXIT PARAGRAPH
    END-IF
    *> BY REFERENCE before the first argument.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-FUNC LS-TEXT LS-LEN
    IF FUNCTION UPPER-CASE(LS-TEXT) = "BY"
        ADD 2 TO LS-FUNC
    END-IF
    *> The function: a data item or a literal, one token.
    COMPUTE LS-PCB-TOKEN = LS-FUNC + 1
    IF WS-TOKEN-REF(LS-FUNC) > 0
        COMPUTE LS-PCB-TOKEN = RF-LAST(WS-TOKEN-REF(LS-FUNC)) + 1
    END-IF
    IF WS-TOKEN-REF(LS-PCB-TOKEN) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE WS-TOKEN-REF(LS-PCB-TOKEN) TO LS-R
    IF RF-KIND(LS-R) NOT = "D"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-PCB
    *> The names to look for: the mask and every item in it.
    MOVE 1 TO NL-COUNT
    MOVE SY-NAME(LS-PCB) TO NL-NAME(1)
    PERFORM VARYING LS-S FROM LS-PCB BY 1
            UNTIL LS-S >= SY-COUNT OR NL-COUNT >= 32
        MOVE SY-PARENT(LS-S + 1) TO LS-UP
        PERFORM UNTIL LS-UP = 0 OR LS-UP = LS-PCB
            MOVE SY-PARENT(LS-UP) TO LS-UP
        END-PERFORM
        IF LS-UP NOT = LS-PCB
            EXIT PERFORM
        END-IF
        IF SY-NAME(LS-S + 1) NOT = SPACES
           AND SY-NAME(LS-S + 1) NOT = "FILLER"
            ADD 1 TO NL-COUNT
            MOVE SY-NAME(LS-S + 1) TO NL-NAME(NL-COUNT)
        END-IF
    END-PERFORM
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-FUNC LS-FUNC-TEXT LS-LEN
    PERFORM FIND-STOP
    CALL "PLB-NAMED-AFTER" USING PLB-TOKENS PLB-AST PLB-FLOW LS-STMT
        LS-STOP PLB-NAME-LIST LS-FOUND
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "the status of CALL 'CBLTDLI' " DELIMITED BY SIZE
           LS-FUNC-TEXT DELIMITED BY SPACE
           " in PCB " DELIMITED BY SIZE
           SY-NAME(LS-PCB) DELIMITED BY SPACE
           " is not tested before the next DL/I call" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-STMT) LS-MESSAGE.

*> CALL 'MQxxx' USING ... compcode reason: either named after it.
CHECK-MQ.
    MOVE "M" TO LS-KIND
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-CALLED LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-CALLED) TO LS-CALLED
    MOVE 0 TO LS-ARG-1 LS-ARG-2
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-STMT) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-STMT)
        IF WS-TOKEN-REF(LS-T) > 0
            MOVE WS-TOKEN-REF(LS-T) TO LS-R
            IF RF-KIND(LS-R) = "D"
                MOVE LS-ARG-2 TO LS-ARG-1
                MOVE LS-T TO LS-ARG-2
                *> plumbline: ignore varying-control-changed -- skips the reference's subscripts
                MOVE RF-LAST(LS-R) TO LS-T
            END-IF
        END-IF
    END-PERFORM
    IF LS-ARG-1 = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 2 TO NL-COUNT
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-ARG-1 NL-NAME(1) LS-LEN
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-ARG-2 NL-NAME(2) LS-LEN
    MOVE FUNCTION UPPER-CASE(NL-NAME(1)) TO NL-NAME(1)
    MOVE FUNCTION UPPER-CASE(NL-NAME(2)) TO NL-NAME(2)
    PERFORM FIND-STOP
    *> The codes passed to a later MQ call are set there, not tested.
    MOVE "MQ" TO NL-SKIP-PREFIX
    CALL "PLB-NAMED-AFTER" USING PLB-TOKENS PLB-AST PLB-FLOW LS-STMT
        LS-STOP PLB-NAME-LIST LS-FOUND
    MOVE SPACES TO NL-SKIP-PREFIX
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "the completion code of CALL '" DELIMITED BY SIZE
           LS-CALLED DELIMITED BY SPACE
           "' (" DELIMITED BY SIZE
           NL-NAME(1) DELIMITED BY SPACE
           ", " DELIMITED BY SIZE
           NL-NAME(2) DELIMITED BY SPACE
           ") is not tested before the next MQ call" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-MQ ND-TOK-FIRST(LS-STMT) LS-MESSAGE.

*> EXEC DLI: DIBSTAT.
CHECK-EXEC.
    MOVE "E" TO LS-KIND
    MOVE 1 TO NL-COUNT
    MOVE "DIBSTAT" TO NL-NAME(1)
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 2
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-FUNC-TEXT LS-LEN
    *> TERM ends the use of the PSB: its status is seldom of use.
    IF FUNCTION UPPER-CASE(LS-FUNC-TEXT) = "TERM"
        EXIT PARAGRAPH
    END-IF
    PERFORM FIND-STOP
    CALL "PLB-NAMED-AFTER" USING PLB-TOKENS PLB-AST PLB-FLOW LS-STMT
        LS-STOP PLB-NAME-LIST LS-FOUND
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "the status of EXEC DLI " DELIMITED BY SIZE
           LS-FUNC-TEXT DELIMITED BY SPACE
           " (DIBSTAT) is not tested before the next DL/I call"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE ND-TOK-FIRST(LS-STMT) LS-MESSAGE.

*> LS-STOP: the first token of the next DL/I call of the same kind
*> after the statement (0: none).
FIND-STOP.
    MOVE 0 TO LS-STOP
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        IF ND-TOK-FIRST(LS-N) > ND-TOK-LAST(LS-STMT)
           AND (LS-STOP = 0 OR ND-TOK-FIRST(LS-N) < LS-STOP)
            PERFORM DLI-KIND
            IF LS-OTHER-KIND = LS-KIND
                PERFORM TEST-EXCLUSIVE
                IF LS-FOUND = "N"
                    MOVE ND-TOK-FIRST(LS-N) TO LS-STOP
                END-IF
            END-IF
        END-IF
    END-PERFORM.
*> LS-FOUND = "Y" when call LS-N is in another branch of an IF or
*> EVALUATE whose branch holds the statement: it cannot run after it.
TEST-EXCLUSIVE.
    MOVE "N" TO LS-FOUND
    MOVE ND-PARENT(LS-STMT) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "BLCK" AND ND-PARENT(LS-UP) > 0
            IF ND-KIND(ND-PARENT(LS-UP)) = "STMT"
               AND (ND-DETAIL(ND-PARENT(LS-UP)) = "IF"
                    OR ND-DETAIL(ND-PARENT(LS-UP)) = "EVALUATE")
               AND ND-TOK-FIRST(LS-N) > ND-TOK-LAST(LS-UP)
               AND ND-TOK-FIRST(LS-N) <= ND-TOK-LAST(ND-PARENT(LS-UP))
                MOVE "Y" TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.
END PROGRAM PLB-RULE-I005.
