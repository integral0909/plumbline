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

*> ---------------------------------------------------------------
*> PLB-J018 gdg-generation-not-created: a DD that reads a new
*> generation of a generation data group (NAME(+1), with DISP=OLD or
*> SHR) that no earlier step of its job, or procedure, creates:
*>
*>     //REPORT   EXEC PGM=PAYRPT
*>     //IN       DD DSN=PAY.HISTORY(+1),DISP=SHR
*>
*> Relative generation numbers are fixed when the job starts: (+1) is
*> the generation a step of this job creates, and (0) the newest one
*> before it. Read before any step creates it, (+1) does not exist, and
*> the step fails (data set not found); (0) was usually meant. Names
*> with symbols, and steps after one that runs a procedure, which may
*> create the generation, are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J018.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-AMPERSANDS           PIC 9(4) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J018" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-KIND(LS-D) = "D"
           AND (JD-DISP(LS-D) = "OLD" OR JD-DISP(LS-D) = "SHR")
           AND JD-QUALIFIER(LS-D) = SPACES AND JD-STEP(LS-D) > 0
            PERFORM NEW-GENERATION
            IF LS-AT > 0
                PERFORM CHECK-CREATED
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> LS-AT: where (+n) starts in the DSN of DD LS-D, n from 1 to 9; 0
*> when it names no new generation, or holds a symbol.
NEW-GENERATION.
    MOVE 0 TO LS-AT LS-AMPERSANDS
    INSPECT JD-DSN(LS-D) TALLYING LS-AMPERSANDS FOR ALL "&"
    IF LS-AMPERSANDS > 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > 40
        IF JD-DSN(LS-D)(LS-T:2) = "(+"
            IF JD-DSN(LS-D)(LS-T + 2:1) >= "1"
               AND JD-DSN(LS-D)(LS-T + 2:1) <= "9"
               AND JD-DSN(LS-D)(LS-T + 3:1) = ")"
                MOVE LS-T TO LS-AT
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> An earlier step of the same job or procedure that creates the
*> generation, or one that runs a procedure, which may.
CHECK-CREATED.
    MOVE JD-STEP(LS-D) TO LS-S
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-T FROM 1 BY 1
            UNTIL LS-T >= LS-S OR LS-FOUND = "Y"
        IF (JS-JOB(LS-S) > 0 AND JS-JOB(LS-T) = JS-JOB(LS-S))
           OR (JS-PROC(LS-S) > 0 AND JS-PROC(LS-T) = JS-PROC(LS-S))
            IF JS-KIND(LS-T) = "R"
                MOVE "Y" TO LS-FOUND
            END-IF
            PERFORM VARYING LS-E FROM JS-DD-FIRST(LS-T) BY 1
                    UNTIL LS-E >= JS-DD-FIRST(LS-T) + JS-DD-COUNT(LS-T)
                       OR LS-FOUND = "Y"
                IF JD-DSN(LS-E) = JD-DSN(LS-D)
                   AND (JD-DISP(LS-E) = "NEW" OR JD-DISP(LS-E) = "MOD"
                        OR JD-DISP(LS-E) = SPACES)
                    MOVE "Y" TO LS-FOUND
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = "N"
        MOVE SPACES TO LS-MESSAGE
        STRING JD-DSN(LS-D) DELIMITED BY SPACE
               " is a new generation, read with DISP=" DELIMITED BY SIZE
               JD-DISP(LS-D) DELIMITED BY SPACE
               ", but no earlier step creates it: it does not exist yet"
               " (the newest is (0))" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-J018.

*> ---------------------------------------------------------------
*> PLB-J019 parm-too-long: a step whose PARM passes the program more
*> than 100 characters:
*>
*>     //REPORT   EXEC PGM=PAYRPT,PARM='...101 characters...'
*>
*> z/OS takes at most 100 characters in the PARM of an EXEC statement,
*> and fails the job with a JCL error; PARMDD names a data set that
*> can hold more. The count leaves out the apostrophes or parentheses
*> that enclose the PARM, and counts a doubled apostrophe once (see
*> JS-PARM-LEN), so it is never more than what the program would be
*> passed. A PARM with a symbol is not counted, nor one on a step that
*> runs a procedure.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J019.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J019" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) = "P" AND JS-PARM-LEN(LS-S) > 100
            PERFORM REPORT-LONG
        END-IF
    END-PERFORM
    GOBACK.

REPORT-LONG.
    MOVE JS-PARM-LEN(LS-S) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "PARM passes " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " characters; z/OS takes at most 100 (PARMDD can pass more)"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J019.

*> ---------------------------------------------------------------
*> PLB-J020 jcl-name-invalid: a statement whose name z/OS does not
*> accept:
*>
*>     //EXTRACTSTEP EXEC PGM=PAYEXT       eleven characters
*>     //1COPY    EXEC PGM=IEBGENER        starts with a digit
*>
*> A name in the name field (of a JOB, EXEC, DD, PROC, or any other
*> statement) is 1 to 8 letters, digits, or national characters ($, #,
*> @), the first not a digit; in a STEP.DDNAME override, each part
*> is. z/OS ends the job with a JCL error. The JCL reader checks each
*> name (JN-ENTRY in plbjcl.cpy); names with a symbol are not checked.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J020.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J020" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > JN-COUNT
        PERFORM REPORT-NAME
    END-PERFORM
    GOBACK.

REPORT-NAME.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    EVALUATE JN-KIND(LS-N)
        WHEN "P"
            STRING "program " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN "R"
            STRING "procedure " DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
    END-EVALUATE
    STRING "name " DELIMITED BY SIZE
           JN-NAME(LS-N) DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF JN-LEN(LS-N) > 17
        STRING "..." DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    IF JN-PART(LS-N) > 1
        STRING " (after the dot)" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    EVALUATE JN-PROBLEM(LS-N)
        WHEN "L"
            STRING " is longer than 8 characters" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN "F"
            STRING " does not start with a letter or $, #, or @"
                DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN "C"
            STRING " has a character other than a letter, digit, $, #,"
                   " or @" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN OTHER
            STRING " has an empty part" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
    END-EVALUATE
    STRING ": z/OS ends the job with a JCL error" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JN-FILE-ID(LS-N) JN-LINE(LS-N) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J020.

*> ---------------------------------------------------------------
*> PLB-J021 cond-always-bypasses: a step whose COND has a test that is
*> true for every return code:
*>
*>     //REPORT   EXEC PGM=PAYRPT,COND=(0,LE)
*>
*> COND=(code,op) bypasses the step when code op RC is true for the
*> return code of a step before it (APAR OA44770 corrects the summary
*> table): (code,LE) when code <= RC, (code,GE) when code >= RC.
*> Return codes run from 0 to 4095, so (0,LE) and (4095,GE) are true
*> for every one, and the step never runs once a step before it has.
*> Usually (0,LT) or (4,LT) was meant. Steps of procedures, and the
*> first step of a job, which has no step before it, are not read.
*>
*> PLB-J022 cond-never-true: a test true for no return code, (0,GT)
*> (0 > RC) or (4095,LT) (4095 < RC): it never bypasses the step, and
*> was written the wrong way round, (0,LT) for (0,GT), as a rule.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J021.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-NEVER           PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-J                    PIC 9(4) COMP-5.
01  LS-CODE                 PIC 9(9) COMP-5.
01  LS-OP                   PIC XX.
01  LS-AFTER                PIC X.
01  LS-FOUND                PIC X.
01  LS-TEST                 PIC X(10).
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J021" LS-RULE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J022" LS-RULE-NEVER
    IF RL-ENABLED(LS-RULE) NOT = "Y" AND RL-ENABLED(LS-RULE-NEVER) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 2 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-PROC(LS-S) = 0 AND JS-JOB(LS-S) > 0
           AND JS-COND(LS-S) NOT = SPACES
            PERFORM CHECK-STEP
        END-IF
    END-PERFORM
    GOBACK.

*> Step LS-S: a step of its job before it, then each test of its COND.
CHECK-STEP.
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E >= LS-S
        IF JS-JOB(LS-E) = JS-JOB(LS-S) AND JS-PROC(LS-E) = 0
            MOVE "Y" TO LS-FOUND
        END-IF
    END-PERFORM
    IF LS-FOUND = "N"
        EXIT PARAGRAPH
    END-IF
    *> Each test: a parenthesis, a number, a comma, an operator.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > 75
        IF JS-COND(LS-S)(LS-I:1) = "("
            PERFORM READ-TEST
        END-IF
    END-PERFORM.

*> The test after the parenthesis at LS-I.
READ-TEST.
    MOVE 0 TO LS-CODE
    COMPUTE LS-J = LS-I + 1
    PERFORM UNTIL LS-J > 76
        IF JS-COND(LS-S)(LS-J:1) < "0" OR JS-COND(LS-S)(LS-J:1) > "9"
            EXIT PERFORM
        END-IF
        IF LS-CODE < 100000
            COMPUTE LS-CODE = LS-CODE * 10
                + FUNCTION NUMVAL(JS-COND(LS-S)(LS-J:1))
        END-IF
        ADD 1 TO LS-J
    END-PERFORM
    IF LS-J = LS-I + 1 OR LS-J > 76
        EXIT PARAGRAPH
    END-IF
    IF JS-COND(LS-S)(LS-J:1) NOT = ","
        EXIT PARAGRAPH
    END-IF
    MOVE JS-COND(LS-S)(LS-J + 1:2) TO LS-OP
    MOVE JS-COND(LS-S)(LS-J + 3:1) TO LS-AFTER
    IF LS-AFTER NOT = ")" AND LS-AFTER NOT = ","
        EXIT PARAGRAPH
    END-IF
    IF ((LS-CODE = 0 AND LS-OP = "GT")
        OR (LS-CODE = 4095 AND LS-OP = "LT"))
       AND RL-ENABLED(LS-RULE-NEVER) = "Y"
        MOVE SPACES TO LS-TEST
        STRING JS-COND(LS-S)(LS-I + 1:LS-J + 2 - LS-I) DELIMITED BY SIZE
            INTO LS-TEST
        MOVE SPACES TO LS-MESSAGE
        STRING "COND test (" DELIMITED BY SIZE
               LS-TEST DELIMITED BY SPACE
               ") is true for no return code: it never bypasses step "
               DELIMITED BY SIZE
               JS-NAME(LS-S) DELIMITED BY SPACE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-NEVER
            JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF
    IF ((LS-CODE = 0 AND LS-OP = "LE")
        OR (LS-CODE = 4095 AND LS-OP = "GE"))
       AND RL-ENABLED(LS-RULE) = "Y"
        MOVE SPACES TO LS-TEST
        STRING JS-COND(LS-S)(LS-I + 1:LS-J + 2 - LS-I) DELIMITED BY SIZE
            INTO LS-TEST
        MOVE SPACES TO LS-MESSAGE
        STRING "COND test (" DELIMITED BY SIZE
               LS-TEST DELIMITED BY SPACE
               ") is true for every return code: step " DELIMITED BY SIZE
               JS-NAME(LS-S) DELIMITED BY SPACE
               " is bypassed whenever a step before it has run"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-J021.

*> ---------------------------------------------------------------
*> PLB-J023 copy-onto-itself: an IEBGENER step whose SYSUT2, the
*> output, names a data set that SYSUT1, the input, or one of the data
*> sets concatenated to it, names too:
*>
*>     //COPY     EXEC PGM=IEBGENER
*>     //SYSUT1   DD DSN=PAY.MASTER,DISP=SHR
*>     //SYSUT2   DD DSN=PAY.MASTER,DISP=OLD
*>
*> Reading from and writing to the same data set at once gives results
*> that are "always unpredictable" for any program that uses BSAM or
*> QSAM, and IEBGENER documents that its input and output must not be
*> one data set (IBM support, "Incorrect results with IDCAMS REPRO
*> using input DD concatenation where one DD is also the output DD").
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J023.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J023" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) = "P"
           AND JS-TARGET(LS-S) = "IEBGENER"
           AND JS-DD-COUNT(LS-S) > 0
            PERFORM CHECK-STEP
        END-IF
    END-PERFORM
    GOBACK.

*> Each SYSUT2 of step LS-S against each SYSUT1 of it.
CHECK-STEP.
    COMPUTE LS-LAST = JS-DD-FIRST(LS-S) + JS-DD-COUNT(LS-S) - 1
    PERFORM VARYING LS-D FROM JS-DD-FIRST(LS-S) BY 1 UNTIL LS-D > LS-LAST
        IF JD-NAME(LS-D) = "SYSUT2" AND JD-KIND(LS-D) = "D"
           AND JD-DSN(LS-D) NOT = SPACES
            PERFORM VARYING LS-E FROM JS-DD-FIRST(LS-S) BY 1
                    UNTIL LS-E > LS-LAST
                IF JD-NAME(LS-E) = "SYSUT1" AND JD-KIND(LS-E) = "D"
                   AND JD-DSN(LS-E) = JD-DSN(LS-D)
                    MOVE SPACES TO LS-MESSAGE
                    STRING "SYSUT2 names " DELIMITED BY SIZE
                           JD-DSN(LS-D) DELIMITED BY SPACE
                           ", which SYSUT1 reads: " DELIMITED BY SIZE
                           JS-TARGET(LS-S) DELIMITED BY SPACE
                           " would read and write one data set at once"
                           DELIMITED BY SIZE
                        INTO LS-MESSAGE
                    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS
                        LS-RULE JD-FILE-ID(LS-D) JD-LINE(LS-D)
                        LS-COLUMN LS-ZERO LS-MESSAGE
                    EXIT PERFORM
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM.
END PROGRAM PLB-RULE-J023.

*> ---------------------------------------------------------------
*> PLB-J024 sysout-parameter-conflict: a DD that codes SYSOUT with a
*> parameter the z/OS MVS JCL Reference says not to code with it, or
*> DEST, HOLD, or OUTLIM without SYSOUT:
*>
*>     //REPORT   DD SYSOUT=A,DISP=(NEW,CATLG)
*>     //LOG      DD DSN=PAY.LOG,DISP=SHR,HOLD=YES
*>
*> JES allocates a sysout data set: it has no disposition, volume, or
*> label of its own, and DEST, HOLD, and OUTLIM say how JES is to print
*> it. "Do not code the following DD parameters with the SYSOUT
*> parameter": *, AMP, CHKPT, DATA, DATACLAS, DDNAME, DISP, DYNAM,
*> EXPDT, LABEL, LIKE, PROTECT, QNAME, RETPD, ROACCESS, SUBSYS, and
*> VOLUME; and "Code the DEST [HOLD, OUTLIM] parameter only on a DD
*> statement with the SYSOUT parameter". The keywords are checked, not
*> * and DATA. The DDs of a step that calls a
*> procedure, and DDs named STEP.DD, are left out: they may override a
*> DD of the procedure that has, or lacks, SYSOUT.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J024.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J024" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-SYSOUT-CLASH(LS-D) NOT = SPACES
           AND JD-QUALIFIER(LS-D) = SPACES AND JD-STEP(LS-D) > 0
            IF JS-KIND(JD-STEP(LS-D)) = "P"
                PERFORM REPORT-CLASH
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

REPORT-CLASH.
    MOVE SPACES TO LS-MESSAGE
    IF JD-SYSOUT(LS-D) = "Y"
        STRING "DD " DELIMITED BY SIZE
               JD-NAME(LS-D) DELIMITED BY SPACE
               " codes " DELIMITED BY SIZE
               JD-SYSOUT-CLASH(LS-D) DELIMITED BY SPACE
               " with SYSOUT, which the JCL Reference says not to: JES"
               " allocates a sysout data set" DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "DD " DELIMITED BY SIZE
               JD-NAME(LS-D) DELIMITED BY SPACE
               " codes " DELIMITED BY SIZE
               JD-SYSOUT-CLASH(LS-D) DELIMITED BY SPACE
               " without SYSOUT; the JCL Reference says to code it only"
               " on a DD with SYSOUT" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J024.

*> ---------------------------------------------------------------
*> PLB-J025 dlm-not-instream: a DD that codes DLM= but is not DD * or
*> DD DATA:
*>
*>     //SYSIN    DD DSN=PAY.CARDS,DISP=SHR,DLM=@@
*>
*> DLM names the delimiter that ends in-stream data. The z/OS MVS JCL
*> Reference (DLM, "Relationship to other parameters") says it has
*> meaning only on DD * and DD DATA statements: "If DLM is specified on
*> any other statement, a JCL error message is issued." Usually the
*> data was meant to follow in the stream, or the DD was changed to a
*> data set and DLM was left. DDs named STEP.DD are left out.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J025.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J025" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-DLM(LS-D) = "Y" AND JD-KIND(LS-D) NOT = "I"
           AND JD-QUALIFIER(LS-D) = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes DLM but is not DD * or DD DATA: a JCL error"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J025.

*> ---------------------------------------------------------------
*> PLB-J026 job-too-many-steps: a job of more than 255 steps, counting
*> the steps of the procedures it calls:
*>
*>     //PAYALL   JOB ...
*>     //DAY01    EXEC PAYDAY          (PAYDAY has 16 steps)
*>     ...
*>     //DAY16    EXEC PAYDAY          256 steps
*>
*> The z/OS MVS JCL Reference ("Steps in a Job") says: "A job can
*> consist of up to 255 job steps, including all steps in any procedures
*> that the job calls. Specification of a greater number of steps
*> produces a JCL error." The count is a lower bound: a procedure that
*> is not among the inputs counts as one step, and of several with one
*> name the one with fewest steps is taken.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J026.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
*> Steps of each procedure, procedures it calls included.
01  WS-PROC-STEPS           PIC 9(9) COMP-5 OCCURS JP-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-PASS                 PIC 9(4) COMP-5.
01  LS-COUNT                PIC 9(9) COMP-5.
01  LS-STEPS                PIC 9(9) COMP-5.
01  LS-CHANGED              PIC X.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J026" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR JJ-COUNT = 0
        GOBACK
    END-IF
    *> Each procedure's steps, with those of the procedures it calls,
    *> pass by pass: procedures nest at most 15 deep.
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > JP-COUNT
        MOVE 0 TO WS-PROC-STEPS(LS-P)
    END-PERFORM
    PERFORM VARYING LS-PASS FROM 1 BY 1 UNTIL LS-PASS > 16
        MOVE "N" TO LS-CHANGED
        PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > JP-COUNT
            MOVE 0 TO LS-COUNT
            PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
                IF JS-PROC(LS-S) = LS-P
                    PERFORM STEP-COUNT
                    ADD LS-STEPS TO LS-COUNT
                END-IF
            END-PERFORM
            IF LS-COUNT NOT = WS-PROC-STEPS(LS-P)
                MOVE LS-COUNT TO WS-PROC-STEPS(LS-P)
                MOVE "Y" TO LS-CHANGED
            END-IF
        END-PERFORM
        IF LS-CHANGED = "N"
            EXIT PERFORM
        END-IF
    END-PERFORM
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > JJ-COUNT
        MOVE 0 TO LS-COUNT
        PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
            IF JS-JOB(LS-S) = LS-J AND JS-PROC(LS-S) = 0
                PERFORM STEP-COUNT
                ADD LS-STEPS TO LS-COUNT
            END-IF
        END-PERFORM
        IF LS-COUNT > 255
            PERFORM REPORT-JOB
        END-IF
    END-PERFORM
    GOBACK.

*> LS-STEPS: the steps step LS-S stands for.
STEP-COUNT.
    MOVE 1 TO LS-STEPS
    IF JS-KIND(LS-S) NOT = "R"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-STEPS
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > JP-COUNT
        IF JP-NAME(LS-Q) = JS-TARGET(LS-S) AND WS-PROC-STEPS(LS-Q) > 0
            IF LS-STEPS = 0 OR WS-PROC-STEPS(LS-Q) < LS-STEPS
                MOVE WS-PROC-STEPS(LS-Q) TO LS-STEPS
            END-IF
        END-IF
    END-PERFORM
    IF LS-STEPS = 0
        MOVE 1 TO LS-STEPS
    END-IF.

REPORT-JOB.
    MOVE LS-COUNT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "job " DELIMITED BY SIZE
           JJ-NAME(LS-J) DELIMITED BY SPACE
           " has at least " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " steps with those of its procedures; z/OS takes 255"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JJ-FILE-ID(LS-J) JJ-LINE(LS-J) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J026.
