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

*> ---------------------------------------------------------------
*> PLB-J016 utility-dd-missing: a job step that runs an IBM utility
*> without a DD statement the utility reads or writes by that name:
*>
*>     //COPY     EXEC PGM=IEBGENER
*>     //SYSUT1   DD DSN=PAY.INPUT,DISP=SHR
*>     //SYSUT2   DD DSN=PAY.COPY,DISP=(NEW,CATLG)
*>                                     no SYSIN, no SYSPRINT
*>
*> IEBGENER needs SYSUT1, SYSUT2, SYSIN (DUMMY when there are no
*> control statements), and SYSPRINT; IDCAMS takes its commands from
*> SYSIN; the TSO batch program IKJEFT01 (and IKJEFT1A, IKJEFT1B), which
*> runs DB2 programs, its commands from SYSTSIN. Without them the step
*> fails. Read are steps of a job that run the program themselves: a
*> procedure's steps may get their DD statements from the job that runs
*> it.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J016.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-FOUND                PIC X.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
*> The DD names the step's program needs.
01  LS-NEED-COUNT           PIC 9(4) COMP-5.
01  LS-NEED                 PIC X(8) OCCURS 4 TIMES.
01  LS-MISSING              PIC X(60).
01  LS-PTR                  PIC 9(4) COMP-5.
01  LS-MISSING-COUNT        PIC 9(4) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J016" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) = "P" AND JS-PROC(LS-S) = 0
           AND JS-JOB(LS-S) > 0
            PERFORM CHECK-STEP
        END-IF
    END-PERFORM
    GOBACK.

*> Step LS-S: the DD names its utility needs, against its DDs.
CHECK-STEP.
    MOVE 0 TO LS-NEED-COUNT
    EVALUATE JS-TARGET(LS-S)
        WHEN "IEBGENER"
            MOVE 4 TO LS-NEED-COUNT
            MOVE "SYSUT1" TO LS-NEED(1)
            MOVE "SYSUT2" TO LS-NEED(2)
            MOVE "SYSIN" TO LS-NEED(3)
            MOVE "SYSPRINT" TO LS-NEED(4)
        WHEN "IDCAMS"
            MOVE 1 TO LS-NEED-COUNT
            MOVE "SYSIN" TO LS-NEED(1)
        WHEN "IKJEFT01" WHEN "IKJEFT1A" WHEN "IKJEFT1B"
            MOVE 1 TO LS-NEED-COUNT
            MOVE "SYSTSIN" TO LS-NEED(1)
    END-EVALUATE
    IF LS-NEED-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MISSING
    MOVE 1 TO LS-PTR
    MOVE 0 TO LS-MISSING-COUNT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-NEED-COUNT
        MOVE "N" TO LS-FOUND
        PERFORM VARYING LS-D FROM JS-DD-FIRST(LS-S) BY 1
                UNTIL LS-D >= JS-DD-FIRST(LS-S) + JS-DD-COUNT(LS-S)
                   OR LS-FOUND = "Y"
            IF JD-NAME(LS-D) = LS-NEED(LS-I)
                MOVE "Y" TO LS-FOUND
            END-IF
        END-PERFORM
        IF LS-FOUND = "N"
            IF LS-MISSING-COUNT > 0
                STRING ", " DELIMITED BY SIZE
                    INTO LS-MISSING WITH POINTER LS-PTR
            END-IF
            STRING LS-NEED(LS-I) DELIMITED BY SPACE
                INTO LS-MISSING WITH POINTER LS-PTR
            ADD 1 TO LS-MISSING-COUNT
        END-IF
    END-PERFORM
    IF LS-MISSING-COUNT > 0
        MOVE SPACES TO LS-MESSAGE
        STRING "step " DELIMITED BY SIZE
               JS-NAME(LS-S) DELIMITED BY SPACE
               " runs " DELIMITED BY SIZE
               JS-TARGET(LS-S) DELIMITED BY SPACE
               " but has no DD " DELIMITED BY SIZE
               LS-MISSING DELIMITED BY "  "
               ", which it needs: the step fails" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-J016.

*> ---------------------------------------------------------------
*> PLB-J017 blksize-invalid: a DD whose BLKSIZE does not fit its
*> RECFM and LRECL:
*>
*>     //OUT DD DSN=PAY.COPY,DISP=(NEW,CATLG),
*>     //       DCB=(RECFM=FB,LRECL=80,BLKSIZE=27900)
*>
*> With fixed blocked records (FB), a block holds whole records, so
*> BLKSIZE must be a multiple of LRECL; with fixed unblocked records
*> (F), equal to it; with variable records (V, VB, not spanned), at
*> least LRECL + 4, for the block descriptor word. Otherwise the data
*> set cannot be opened: for fixed records, abend 013-34. Read are DDs
*> that give RECFM, LRECL, and a BLKSIZE other than 0 (which lets the
*> system choose).
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J017.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-BAD                  PIC X.
01  LS-NEED                 PIC X(40).
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-1                PIC X(20).
01  LS-NUM-1-LEN            PIC 9(9) COMP-5.
01  LS-NUM-2                PIC X(20).
01  LS-NUM-2-LEN            PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J017" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-LRECL(LS-D) > 0 AND JD-BLKSIZE(LS-D) > 0
           AND JD-RECFM(LS-D) NOT = SPACES
            PERFORM CHECK-DD
        END-IF
    END-PERFORM
    GOBACK.

*> DD LS-D: its BLKSIZE against its RECFM and LRECL.
CHECK-DD.
    MOVE "N" TO LS-BAD
    EVALUATE TRUE
        WHEN JD-RECFM(LS-D)(1:2) = "FB"
            IF FUNCTION MOD(JD-BLKSIZE(LS-D), JD-LRECL(LS-D)) NOT = 0
                MOVE "Y" TO LS-BAD
                MOVE "a multiple of LRECL" TO LS-NEED
            END-IF
        WHEN JD-RECFM(LS-D) = "F" OR JD-RECFM(LS-D) = "FA"
            IF JD-BLKSIZE(LS-D) NOT = JD-LRECL(LS-D)
                MOVE "LRECL" TO LS-NEED
                MOVE "Y" TO LS-BAD
            END-IF
        WHEN JD-RECFM(LS-D) = "V" OR JD-RECFM(LS-D) = "VB"
             OR JD-RECFM(LS-D) = "VA" OR JD-RECFM(LS-D) = "VBA"
            IF JD-BLKSIZE(LS-D) < JD-LRECL(LS-D) + 4
                MOVE "at least LRECL + 4" TO LS-NEED
                MOVE "Y" TO LS-BAD
            END-IF
    END-EVALUATE
    IF LS-BAD = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE JD-BLKSIZE(LS-D) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-1 LS-NUM-1-LEN
    MOVE JD-LRECL(LS-D) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-2 LS-NUM-2-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "DD " DELIMITED BY SIZE
           JD-NAME(LS-D) DELIMITED BY SPACE
           " has BLKSIZE " DELIMITED BY SIZE
           LS-NUM-1(1:LS-NUM-1-LEN) DELIMITED BY SIZE
           " and LRECL " DELIMITED BY SIZE
           LS-NUM-2(1:LS-NUM-2-LEN) DELIMITED BY SIZE
           ", but RECFM=" DELIMITED BY SIZE
           JD-RECFM(LS-D) DELIMITED BY SPACE
           " needs a BLKSIZE " DELIMITED BY SIZE
           LS-NEED DELIMITED BY "  "
           ": the data set cannot be opened" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J017.
