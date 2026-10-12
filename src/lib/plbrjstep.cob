*> ---------------------------------------------------------------
*> plbrjstep: PLB-J015 step-name-repeated.
*>
*> Two steps of one job, or of one procedure, with the same name:
*>
*>     //EXTRACT  EXEC PGM=ACCTEXT
*>     //SORT     EXEC PGM=SORT
*>     //EXTRACT  EXEC PGM=ACCTRPT
*>
*> COND and IF tests, backward references (*.EXTRACT.OUT), restarts
*> (RESTART=EXTRACT), and the job's messages name a step by its name,
*> and cannot tell two of one name apart. Usually a step was copied and
*> not renamed. Steps without a name are not compared; a procedure's
*> steps are compared among themselves, not with the job's.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J015.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J015" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 2 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-NAME(LS-S) NOT = SPACES
            PERFORM CHECK-STEP
        END-IF
    END-PERFORM
    GOBACK.

*> Step LS-S against the steps before it in its job or procedure.
CHECK-STEP.
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E >= LS-S
        IF JS-JOB(LS-E) = JS-JOB(LS-S) AND JS-PROC(LS-E) = JS-PROC(LS-S)
           AND JS-NAME(LS-E) = JS-NAME(LS-S)
            PERFORM REPORT-REPEATED
            EXIT PARAGRAPH
        END-IF
    END-PERFORM.

REPORT-REPEATED.
    MOVE JS-LINE(LS-E) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "step name " DELIMITED BY SIZE
           JS-NAME(LS-S) DELIMITED BY SPACE
           " is already the name of the step on line " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ": COND, IF, backward references, and restarts that name it"
           " cannot tell the two apart" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J015.
