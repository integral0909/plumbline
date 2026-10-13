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
*>
*> Both read the COND of a JOB statement too, whose tests are made
*> against the return code of each step; when one is true, "the system
*> bypasses all remaining job steps and terminates the job" (JOB
*> statement, COND parameter). (0,LE) there ends the job after its
*> first step, and (0,GT) never ends it.
*>
*> PLB-J033 cond-invalid: a COND that the z/OS MVS JCL Reference does
*> not allow, on any step or job: a code above 4095 ("code is a decimal
*> number from 0 through 4095"), an operator other than GT, GE, EQ, LT,
*> LE, and NE, or more than eight tests ("if you code EVEN or ONLY,
*> specify up to seven return code tests").
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J021.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-RULE-NEVER           PIC 9(4) COMP-5.
01  LS-RULE-INVALID         PIC 9(4) COMP-5.
*> "Y" when the tests are judged for J021 and J022: a step with a step
*> of its job before it, or a job.
01  LS-JUDGE                PIC X.
01  LS-TESTS                PIC 9(4) COMP-5.
01  LS-K                    PIC 9(4) COMP-5.
01  LS-OP-LEN               PIC 9(4) COMP-5.
01  LS-MOST                 PIC 9(4) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-J                    PIC 9(4) COMP-5.
01  LS-CODE                 PIC 9(9) COMP-5.
01  LS-OP                   PIC XX.
01  LS-AFTER                PIC X.
01  LS-FOUND                PIC X.
01  LS-TEST                 PIC X(10).
01  LS-J-NO                 PIC 9(9) COMP-5.
*> The COND being read, and its statement: S a step, J a job.
01  LS-COND                 PIC X(80).
01  LS-OF                   PIC X.
01  LS-OF-NAME              PIC X(8).
01  LS-OF-FILE-ID           PIC 9(4) COMP-5.
01  LS-OF-LINE              PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J033" LS-RULE-INVALID
    IF RL-ENABLED(LS-RULE) NOT = "Y" AND RL-ENABLED(LS-RULE-NEVER) NOT = "Y"
       AND RL-ENABLED(LS-RULE-INVALID) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-COND(LS-S) NOT = SPACES
            PERFORM CHECK-STEP
        END-IF
    END-PERFORM
    PERFORM VARYING LS-J-NO FROM 1 BY 1 UNTIL LS-J-NO > JJ-COUNT
        IF JJ-COND(LS-J-NO) NOT = SPACES
            MOVE JJ-COND(LS-J-NO) TO LS-COND
            MOVE "J" TO LS-OF
            MOVE JJ-NAME(LS-J-NO) TO LS-OF-NAME
            MOVE JJ-FILE-ID(LS-J-NO) TO LS-OF-FILE-ID
            MOVE JJ-LINE(LS-J-NO) TO LS-OF-LINE
            MOVE "Y" TO LS-JUDGE
            PERFORM READ-TESTS
        END-IF
    END-PERFORM
    GOBACK.

*> Step LS-S: each test of its COND, judged when it is a step of a job
*> with a step of the job before it.
CHECK-STEP.
    MOVE "N" TO LS-FOUND
    IF JS-PROC(LS-S) = 0 AND JS-JOB(LS-S) > 0
        PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E >= LS-S
            IF JS-JOB(LS-E) = JS-JOB(LS-S) AND JS-PROC(LS-E) = 0
                MOVE "Y" TO LS-FOUND
            END-IF
        END-PERFORM
    END-IF
    MOVE LS-FOUND TO LS-JUDGE
    IF LS-JUDGE = "N" AND RL-ENABLED(LS-RULE-INVALID) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE JS-COND(LS-S) TO LS-COND
    MOVE "S" TO LS-OF
    MOVE JS-NAME(LS-S) TO LS-OF-NAME
    MOVE JS-FILE-ID(LS-S) TO LS-OF-FILE-ID
    MOVE JS-LINE(LS-S) TO LS-OF-LINE
    PERFORM READ-TESTS.

*> Each test of LS-COND: a parenthesis, a number, a comma, an operator.
READ-TESTS.
    MOVE 0 TO LS-TESTS
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > 75
        IF LS-COND(LS-I:1) = "("
            PERFORM READ-TEST
        END-IF
    END-PERFORM
    *> At most eight tests, seven with EVEN or ONLY (of a step).
    MOVE 8 TO LS-MOST
    MOVE 0 TO LS-E
    INSPECT LS-COND TALLYING LS-E FOR ALL ",EVEN" ALL ",ONLY"
        ALL "(EVEN" ALL "(ONLY"
    IF LS-E > 0 OR LS-COND(1:4) = "EVEN" OR LS-COND(1:4) = "ONLY"
        MOVE 7 TO LS-MOST
    END-IF
    IF LS-TESTS > LS-MOST AND RL-ENABLED(LS-RULE-INVALID) = "Y"
        MOVE LS-TESTS TO LS-NUM
        CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
        MOVE SPACES TO LS-MESSAGE
        STRING "COND of " DELIMITED BY SIZE
               LS-OF-NAME DELIMITED BY SPACE
               " has " DELIMITED BY SIZE
               LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
               " return code tests; z/OS takes 8, or 7 with EVEN or ONLY"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-INVALID
            LS-OF-FILE-ID LS-OF-LINE LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF.

*> The test after the parenthesis at LS-I.
READ-TEST.
    MOVE 0 TO LS-CODE
    COMPUTE LS-J = LS-I + 1
    PERFORM UNTIL LS-J > 76
        IF LS-COND(LS-J:1) < "0" OR LS-COND(LS-J:1) > "9"
            EXIT PERFORM
        END-IF
        IF LS-CODE < 100000
            COMPUTE LS-CODE = LS-CODE * 10
                + FUNCTION NUMVAL(LS-COND(LS-J:1))
        END-IF
        ADD 1 TO LS-J
    END-PERFORM
    IF LS-J = LS-I + 1 OR LS-J > 76
        EXIT PARAGRAPH
    END-IF
    IF LS-COND(LS-J:1) NOT = ","
        EXIT PARAGRAPH
    END-IF
    *> The operator: up to the parenthesis or comma after it.
    MOVE 0 TO LS-OP-LEN
    MOVE SPACE TO LS-AFTER
    COMPUTE LS-K = LS-J + 1
    PERFORM VARYING LS-K FROM LS-K BY 1 UNTIL LS-K > 80
        IF LS-COND(LS-K:1) = ")" OR LS-COND(LS-K:1) = ","
            MOVE LS-COND(LS-K:1) TO LS-AFTER
            EXIT PERFORM
        END-IF
        IF LS-COND(LS-K:1) = SPACE OR LS-COND(LS-K:1) = "("
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-OP-LEN
    END-PERFORM
    IF LS-AFTER = SPACE OR LS-OP-LEN = 0 OR LS-OP-LEN > 8
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-OP
    IF LS-OP-LEN = 2
        MOVE LS-COND(LS-J + 1:2) TO LS-OP
    END-IF
    ADD 1 TO LS-TESTS
    MOVE SPACES TO LS-TEST
    STRING LS-COND(LS-I + 1:LS-J + LS-OP-LEN - LS-I) DELIMITED BY SIZE
        INTO LS-TEST
    IF RL-ENABLED(LS-RULE-INVALID) = "Y"
        IF LS-CODE > 4095
            MOVE SPACES TO LS-MESSAGE
            STRING "COND test (" DELIMITED BY SIZE
                   LS-TEST DELIMITED BY SPACE
                   ") of " DELIMITED BY SIZE
                   LS-OF-NAME DELIMITED BY SPACE
                   " has a code above 4095, the highest return code"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS
                LS-RULE-INVALID LS-OF-FILE-ID LS-OF-LINE LS-COLUMN
                LS-ZERO LS-MESSAGE
        END-IF
        IF LS-OP NOT = "GT" AND LS-OP NOT = "GE" AND LS-OP NOT = "EQ"
           AND LS-OP NOT = "LT" AND LS-OP NOT = "LE" AND LS-OP NOT = "NE"
            MOVE SPACES TO LS-MESSAGE
            STRING "COND test (" DELIMITED BY SIZE
                   LS-TEST DELIMITED BY SPACE
                   ") of " DELIMITED BY SIZE
                   LS-OF-NAME DELIMITED BY SPACE
                   " has operator " DELIMITED BY SIZE
                   LS-COND(LS-J + 1:LS-OP-LEN) DELIMITED BY SIZE
                   ", not GT, GE, EQ, LT, LE, or NE" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS
                LS-RULE-INVALID LS-OF-FILE-ID LS-OF-LINE LS-COLUMN
                LS-ZERO LS-MESSAGE
        END-IF
    END-IF
    IF LS-JUDGE NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    IF ((LS-CODE = 0 AND LS-OP = "GT")
        OR (LS-CODE = 4095 AND LS-OP = "LT"))
       AND RL-ENABLED(LS-RULE-NEVER) = "Y"
        MOVE SPACES TO LS-TEST
        STRING LS-COND(LS-I + 1:LS-J + 2 - LS-I) DELIMITED BY SIZE
            INTO LS-TEST
        MOVE SPACES TO LS-MESSAGE
        IF LS-OF = "J"
            STRING "COND test (" DELIMITED BY SIZE
                   LS-TEST DELIMITED BY SPACE
                   ") is true for no return code: it never ends job "
                   DELIMITED BY SIZE
                   LS-OF-NAME DELIMITED BY SPACE
                INTO LS-MESSAGE
        ELSE
            STRING "COND test (" DELIMITED BY SIZE
                   LS-TEST DELIMITED BY SPACE
                   ") is true for no return code: it never bypasses"
                   " step " DELIMITED BY SIZE
                   LS-OF-NAME DELIMITED BY SPACE
                INTO LS-MESSAGE
        END-IF
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-NEVER
            LS-OF-FILE-ID LS-OF-LINE LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF
    IF ((LS-CODE = 0 AND LS-OP = "LE")
        OR (LS-CODE = 4095 AND LS-OP = "GE"))
       AND RL-ENABLED(LS-RULE) = "Y"
        MOVE SPACES TO LS-TEST
        STRING LS-COND(LS-I + 1:LS-J + 2 - LS-I) DELIMITED BY SIZE
            INTO LS-TEST
        MOVE SPACES TO LS-MESSAGE
        IF LS-OF = "J"
            STRING "COND test (" DELIMITED BY SIZE
                   LS-TEST DELIMITED BY SPACE
                   ") is true for every return code: job "
                   DELIMITED BY SIZE
                   LS-OF-NAME DELIMITED BY SPACE
                   " ends after its first step" DELIMITED BY SIZE
                INTO LS-MESSAGE
        ELSE
            STRING "COND test (" DELIMITED BY SIZE
                   LS-TEST DELIMITED BY SPACE
                   ") is true for every return code: step "
                   DELIMITED BY SIZE
                   LS-OF-NAME DELIMITED BY SPACE
                   " is bypassed whenever a step before it has run"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
        END-IF
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            LS-OF-FILE-ID LS-OF-LINE LS-COLUMN LS-ZERO LS-MESSAGE
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
*> * and DATA. OUTPUT, which refers to an OUTPUT JCL statement, goes
*> "only on a DD statement with the SYSOUT or SUBSYS parameter", and not
*> "when the SYSOUT parameter specifies a JES2 internal reader by an
*> INTRDR parameter". The DDs of a step that calls a
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
    EVALUATE TRUE
        WHEN JD-SYSOUT-CLASH(LS-D) = "OUTPUT" AND JD-SYSOUT(LS-D) = "Y"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes OUTPUT with SYSOUT=(...,INTRDR), the JES2"
                   " internal reader, which the JCL Reference says not to"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN JD-SYSOUT-CLASH(LS-D) = "OUTPUT"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes OUTPUT without SYSOUT or SUBSYS; the JCL"
                   " Reference says to code it only on a DD with one"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
    END-EVALUATE
    IF LS-MESSAGE NOT = SPACES
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE
        EXIT PARAGRAPH
    END-IF
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

*> ---------------------------------------------------------------
*> PLB-J027 proc-calls-itself: a procedure step that calls the
*> procedure it is in, directly or through the procedures it calls:
*>
*>     //PAYA     PROC
*>     //STEP1    EXEC PAYB
*>     //PAYB     PROC
*>     //STEP1    EXEC PAYA           PAYB calls PAYA, which calls PAYB
*>
*> The z/OS MVS JCL Reference ("Nested procedures") lets procedures
*> invoke other procedures "up to 15 levels of nesting"; a cycle nests
*> without end, so a job that calls any procedure of it fails. Calls
*> are followed by name to the procedures among the inputs.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J027.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
01  WS-SEEN                 PIC X OCCURS JP-MAX TIMES.
01  WS-QUEUE                PIC 9(9) COMP-5 OCCURS JP-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-HEAD                 PIC 9(9) COMP-5.
01  LS-TAIL                 PIC 9(9) COMP-5.
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-BACK                 PIC X.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J027" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-PROC(LS-S) > 0 AND JS-KIND(LS-S) = "R"
            MOVE JS-PROC(LS-S) TO LS-P
            PERFORM LEADS-BACK
            IF LS-BACK = "Y"
                PERFORM REPORT-STEP
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> LS-BACK = "Y" when the procedures step LS-S calls reach procedure
*> LS-P, breadth first.
LEADS-BACK.
    MOVE "N" TO LS-BACK
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > JP-COUNT
        MOVE "N" TO WS-SEEN(LS-Q)
    END-PERFORM
    MOVE 0 TO LS-HEAD LS-TAIL
    MOVE LS-S TO LS-AT
    PERFORM QUEUE-TARGETS
    PERFORM UNTIL LS-HEAD >= LS-TAIL OR LS-BACK = "Y"
        ADD 1 TO LS-HEAD
        MOVE WS-QUEUE(LS-HEAD) TO LS-Q
        IF LS-Q = LS-P
            MOVE "Y" TO LS-BACK
        ELSE
            PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > JS-COUNT
                IF JS-PROC(LS-T) = LS-Q AND JS-KIND(LS-T) = "R"
                    MOVE LS-T TO LS-AT
                    PERFORM QUEUE-TARGETS
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM.

*> The procedures named like the one step LS-AT calls, not yet seen.
QUEUE-TARGETS.
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > JP-COUNT
        IF JP-NAME(LS-Q) = JS-TARGET(LS-AT) AND WS-SEEN(LS-Q) = "N"
            MOVE "Y" TO WS-SEEN(LS-Q)
            ADD 1 TO LS-TAIL
            MOVE LS-Q TO WS-QUEUE(LS-TAIL)
        END-IF
    END-PERFORM.

REPORT-STEP.
    MOVE SPACES TO LS-MESSAGE
    IF JS-TARGET(LS-S) = JP-NAME(LS-P)
        STRING "procedure " DELIMITED BY SIZE
               JP-NAME(LS-P) DELIMITED BY SPACE
               " calls itself: procedures nest at most 15 levels, and"
               " this nests without end" DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "procedure " DELIMITED BY SIZE
               JP-NAME(LS-P) DELIMITED BY SPACE
               " calls " DELIMITED BY SIZE
               JS-TARGET(LS-S) DELIMITED BY SPACE
               ", which calls " DELIMITED BY SIZE
               JP-NAME(LS-P) DELIMITED BY SPACE
               " again: procedures nest at most 15 levels, and this"
               " nests without end" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J027.

*> ---------------------------------------------------------------
*> PLB-J028 instream-procs-too-many: the 16th in-stream procedure of a
*> job, and each after it:
*>
*>     //PAYALL   JOB ...
*>     //P01      PROC
*>     ...
*>     //P16      PROC                 the 16th
*>
*> The z/OS MVS JCL Reference ("Entering jobs")
*> says: "The maximum number of in-stream procedures you can code in any
*> job is 15." Procedures that many are better cataloged in a library.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J028.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-COUNT                PIC 9(9) COMP-5.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J028" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > JJ-COUNT
        MOVE 0 TO LS-COUNT
        PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > JP-COUNT
            IF JP-INSTREAM(LS-P) = "Y" AND JP-JOB(LS-P) = LS-J
                ADD 1 TO LS-COUNT
                IF LS-COUNT > 15
                    PERFORM REPORT-PROC
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM
    GOBACK.

REPORT-PROC.
    MOVE LS-COUNT TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "procedure " DELIMITED BY SIZE
           JP-NAME(LS-P) DELIMITED BY SPACE
           " is in-stream procedure " DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " of job " DELIMITED BY SIZE
           JJ-NAME(LS-J) DELIMITED BY SPACE
           "; a job may have 15" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JP-FILE-ID(LS-P) JP-LINE(LS-P) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J028.

*> ---------------------------------------------------------------
*> PLB-J029 time-invalid: a TIME= on a JOB or EXEC statement that the
*> z/OS MVS JCL Reference does not allow:
*>
*>     //EXTRACT  EXEC PGM=PAYEXTR,TIME=(5,90)
*>     //PAYJOB   JOB (ACCT),'PAY',TIME=0
*>
*> Minutes must be a number "from 0 through 357912", and seconds "from
*> 0 through 59" ("TIME parameter", of EXEC and of JOB); 1440, NOLIMIT,
*> and MAXIMUM ask for no limit. Of TIME=0 on a JOB statement, the
*> Reference says: "Do not code TIME=0 on a JOB statement. The results
*> are unpredictable." Values with symbols are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J029.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-BAD                  PIC X(20).
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J029" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        IF JJ-TIME-BAD(LS-I) NOT = SPACES
            MOVE JJ-TIME-BAD(LS-I) TO LS-BAD
            MOVE SPACES TO LS-MESSAGE
            IF LS-BAD = "0" OR LS-BAD = "(0)"
                STRING "job " DELIMITED BY SIZE
                       JJ-NAME(LS-I) DELIMITED BY SPACE
                       " codes TIME=0, whose results on a JOB statement"
                       " are unpredictable" DELIMITED BY SIZE
                    INTO LS-MESSAGE
            ELSE
                STRING "job " DELIMITED BY SIZE
                       JJ-NAME(LS-I) DELIMITED BY SPACE
                       " codes TIME=" DELIMITED BY SIZE
                       LS-BAD DELIMITED BY SPACE
                       ", not minutes to 357912 and seconds to 59,"
                       " 1440, NOLIMIT, or MAXIMUM" DELIMITED BY SIZE
                    INTO LS-MESSAGE
            END-IF
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JJ-FILE-ID(LS-I) JJ-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        IF JS-TIME-BAD(LS-I) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "step " DELIMITED BY SIZE
                   JS-NAME(LS-I) DELIMITED BY SPACE
                   " codes TIME=" DELIMITED BY SIZE
                   JS-TIME-BAD(LS-I) DELIMITED BY SPACE
                   ", not minutes to 357912 and seconds to 59, 1440,"
                   " NOLIMIT, or MAXIMUM" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JS-FILE-ID(LS-I) JS-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J029.

*> ---------------------------------------------------------------
*> PLB-J030 region-invalid: a REGION= on a JOB or EXEC statement that
*> the z/OS MVS JCL Reference does not allow:
*>
*>     //SORT     EXEC PGM=SORT,REGION=4096M
*>     //LOAD     EXEC PGM=PAYLOAD,REGION=4096
*>
*> REGION is valueK, "from 1 through 2096128", or valueM, "from 1
*> through 2047" ("REGION parameter", of EXEC and of JOB); 0K and 0M
*> give the step all the storage there is. A number without K or M is
*> neither. Values with symbols are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J030.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J030" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        IF JJ-REGION-BAD(LS-I) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "job " DELIMITED BY SIZE
                   JJ-NAME(LS-I) DELIMITED BY SPACE
                   " codes REGION=" DELIMITED BY SIZE
                   JJ-REGION-BAD(LS-I) DELIMITED BY SPACE
                   ", not 0K to 2096128K or 0M to 2047M"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JJ-FILE-ID(LS-I) JJ-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        IF JS-REGION-BAD(LS-I) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "step " DELIMITED BY SIZE
                   JS-NAME(LS-I) DELIMITED BY SPACE
                   " codes REGION=" DELIMITED BY SIZE
                   JS-REGION-BAD(LS-I) DELIMITED BY SPACE
                   ", not 0K to 2096128K or 0M to 2047M"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JS-FILE-ID(LS-I) JS-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J030.

*> ---------------------------------------------------------------
*> PLB-J031 msglevel-invalid: a MSGLEVEL= on a JOB statement that the
*> z/OS MVS JCL Reference does not allow:
*>
*>     //PAYJOB   JOB (ACCT),'PAY',MSGLEVEL=(1,2)
*>
*> MSGLEVEL=(statements,messages) says what JCL output the job lists.
*> Of statements the Reference ("MSGLEVEL parameter") says "this
*> subparameter is one of the following numbers": 0, 1, or 2; of
*> messages, 0 or 1. (1,2) usually meant (2,1) or (1,1). Values with
*> symbols are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J031.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J031" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        IF JJ-MSGLEVEL-BAD(LS-I) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "job " DELIMITED BY SIZE
                   JJ-NAME(LS-I) DELIMITED BY SPACE
                   " codes MSGLEVEL=" DELIMITED BY SIZE
                   JJ-MSGLEVEL-BAD(LS-I) DELIMITED BY SPACE
                   ": statements are 0, 1, or 2, and messages 0 or 1"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JJ-FILE-ID(LS-I) JJ-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J031.

*> ---------------------------------------------------------------
*> PLB-J032 class-invalid: a job class or output class that the z/OS
*> MVS JCL Reference does not allow:
*>
*>     //PAYJOB   JOB (ACCT),'PAY',CLASS=-A,MSGCLASS=XY
*>     //REPORT   DD SYSOUT=AB
*>
*> An output class, of MSGCLASS= on the JOB statement and of SYSOUT= on
*> a DD, "is one character, A through Z or 0 through 9" (it may be
*> quoted; SYSOUT also takes * and the null class of SYSOUT=(,)). A job
*> class, CLASS= on the JOB statement, "is 1-8 characters", the first
*> "a member of the 36-character set A-Z and 0-9", the others letters,
*> digits, or national characters. Values with symbols are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J032.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J032" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        IF JJ-CLASS-BAD(LS-I) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            IF JJ-CLASS-KEY(LS-I) = "CLASS"
                STRING "job " DELIMITED BY SIZE
                       JJ-NAME(LS-I) DELIMITED BY SPACE
                       " codes CLASS=" DELIMITED BY SIZE
                       JJ-CLASS-BAD(LS-I) DELIMITED BY SPACE
                       "; a job class is 1 to 8 letters, digits, or #,"
                       " @, $, starting with a letter or digit"
                       DELIMITED BY SIZE
                    INTO LS-MESSAGE
            ELSE
                STRING "job " DELIMITED BY SIZE
                       JJ-NAME(LS-I) DELIMITED BY SPACE
                       " codes MSGCLASS=" DELIMITED BY SIZE
                       JJ-CLASS-BAD(LS-I) DELIMITED BY SPACE
                       "; an output class is one character, A to Z or"
                       " 0 to 9" DELIMITED BY SIZE
                    INTO LS-MESSAGE
            END-IF
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JJ-FILE-ID(LS-I) JJ-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JD-COUNT
        IF JD-CLASS-BAD(LS-I) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-I) DELIMITED BY SPACE
                   " codes SYSOUT class " DELIMITED BY SIZE
                   JD-CLASS-BAD(LS-I) DELIMITED BY SPACE
                   "; an output class is one character, A to Z or 0 to"
                   " 9, or *" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JD-FILE-ID(LS-I) JD-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J032.

*> ---------------------------------------------------------------
*> PLB-J034 lrecl-invalid: a DD whose LRECL the z/OS MVS JCL Reference
*> does not allow:
*>
*>     //OUTFILE  DD DSN=PAY.EXTRACT,DISP=(NEW,CATLG),
*>     //            RECFM=FB,LRECL=40000
*>
*> LRECL ("LRECL parameter") is "1 to 32,760 for non-VSAM data sets",
*> and 1 to 32,761 for VSAM ones (a DD that codes RECORG); longer
*> variable spanned records are LRECL=X. "LRECL=0 is valid only for
*> RECFM=U", and for RECFM=D or V "the length must be a minimum of 5",
*> the record descriptor word and a byte of data. RECFM is read only
*> when the DD codes it.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J034.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-MOST                 PIC 9(9) COMP-5.
01  LS-WHY                  PIC X(60).
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J034" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-LRECL-CODED(LS-D) = "Y"
            PERFORM CHECK-DD
        END-IF
    END-PERFORM
    GOBACK.

CHECK-DD.
    MOVE SPACES TO LS-WHY
    IF JD-RECORG(LS-D) = "Y"
        MOVE 32761 TO LS-MOST
    ELSE
        MOVE 32760 TO LS-MOST
    END-IF
    EVALUATE TRUE
        WHEN JD-LRECL(LS-D) > LS-MOST
            MOVE LS-MOST TO LS-NUM
            CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
            STRING "above " DELIMITED BY SIZE
                   LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
                   ", the longest record" DELIMITED BY SIZE
                INTO LS-WHY
        WHEN JD-LRECL(LS-D) = 0 AND JD-RECFM(LS-D) NOT = SPACES
             AND JD-RECFM(LS-D)(1:1) NOT = "U"
            MOVE "only RECFM=U takes 0" TO LS-WHY
        WHEN JD-LRECL(LS-D) > 0 AND JD-LRECL(LS-D) < 5
             AND (JD-RECFM(LS-D)(1:1) = "V" OR JD-RECFM(LS-D)(1:1) = "D")
            MOVE "below 5, the least for variable records" TO LS-WHY
    END-EVALUATE
    IF LS-WHY = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE JD-LRECL(LS-D) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING "DD " DELIMITED BY SIZE
           JD-NAME(LS-D) DELIMITED BY SPACE
           " codes LRECL=" DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           ": " DELIMITED BY SIZE
           LS-WHY DELIMITED BY "  "
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J034.

*> ---------------------------------------------------------------
*> PLB-J035 retention-invalid: a DD whose EXPDT or RETPD the z/OS MVS
*> JCL Reference does not allow:
*>
*>     //BACKUP   DD DSN=PAY.BACKUP,DISP=(NEW,CATLG),EXPDT=2024/400
*>     //WORK     DD DSN=&&WORK,DISP=(NEW,PASS),RETPD=30
*>
*> EXPDT is yyddd (a year of the 1900s) or yyyy/ddd, a year from 1900
*> through 2155 and a day from 001 through 365, or 366 in a leap year;
*> RETPD is "one through five decimal digits (0-93000)". The two are
*> not coded together ("Do not code the following DD parameters with
*> the EXPDT parameter": RETPD), and "Do not specify EXPDT [RETPD] for a
*> temporary data set". Values with symbols are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J035.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J035" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-RETAIN-PROBLEM(LS-D) NOT = SPACE
            PERFORM REPORT-DD
        END-IF
    END-PERFORM
    GOBACK.

REPORT-DD.
    MOVE SPACES TO LS-MESSAGE
    EVALUATE JD-RETAIN-PROBLEM(LS-D)
        WHEN "E"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes EXPDT=" DELIMITED BY SIZE
                   JD-RETAIN-VALUE(LS-D) DELIMITED BY SPACE
                   ", not yyddd or yyyy/ddd of a day from 1900 to 2155"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN "R"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes RETPD=" DELIMITED BY SIZE
                   JD-RETAIN-VALUE(LS-D) DELIMITED BY SPACE
                   ", not a number of days from 0 to 93000"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN "B"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes both EXPDT and RETPD; code one" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN OTHER
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " gives the temporary data set " DELIMITED BY SIZE
                   JD-DSN(LS-D) DELIMITED BY SPACE
                   " an EXPDT or RETPD, which a temporary data set does"
                   " not take" DELIMITED BY SIZE
                INTO LS-MESSAGE
    END-EVALUATE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J035.

*> ---------------------------------------------------------------
*> PLB-J036 space-invalid: a DD whose SPACE= the z/OS MVS JCL Reference
*> does not allow:
*>
*>     //OUTFILE  DD DSN=PAY.OUT,DISP=(NEW,CATLG),
*>     //            SPACE=(TRACKS,(10,5),RELEASE)
*>
*> SPACE=(unit,(primary,secondary,directory),options): the unit is TRK,
*> CYL, ABSTR, or a block or record length "from 0 through 65535"; for
*> the quantities "syntax allows for values of 0-16777215"; and the
*> options are RLSE, CONTIG, MXIG, ALX, and ROUND ("SPACE parameter").
*> The first part not allowed is reported. Values with symbols are not
*> read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J036.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-WHAT                 PIC X(60).
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J036" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-SPACE-PART(LS-D) NOT = SPACE
            EVALUATE JD-SPACE-PART(LS-D)
                WHEN "U"
                    MOVE "not TRK, CYL, ABSTR, or a length of 0 to 65535"
                        TO LS-WHAT
                WHEN "Q"
                    MOVE "not quantities of 0 to 16777215" TO LS-WHAT
                WHEN OTHER
                    MOVE "not RLSE, CONTIG, MXIG, ALX, or ROUND" TO LS-WHAT
            END-EVALUATE
            MOVE SPACES TO LS-MESSAGE
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes SPACE with " DELIMITED BY SIZE
                   JD-SPACE-BAD(LS-D) DELIMITED BY SPACE
                   ", " DELIMITED BY SIZE
                   LS-WHAT DELIMITED BY "  "
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J036.

*> ---------------------------------------------------------------
*> PLB-J037 disp-invalid: a DD whose DISP= the z/OS MVS JCL Reference
*> does not allow:
*>
*>     //OUTFILE  DD DSN=PAY.OUT,DISP=(NEW,CATLG,PASS)
*>
*> DISP=(status,normal-termination-disp,abnormal-termination-disp)
*> ("DISP parameter"): the status is NEW, OLD, SHR, or MOD; after a
*> normal end, DELETE, KEEP, PASS, CATLG, or UNCATLG; after an abnormal
*> end, DELETE, KEEP, CATLG, or UNCATLG, not PASS. Values with symbols
*> are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J037.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-WHAT                 PIC X(80).
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J037" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-DISP-PART(LS-D) NOT = SPACE
            EVALUATE JD-DISP-PART(LS-D)
                WHEN "S"
                    MOVE "a status other than NEW, OLD, SHR, or MOD"
                        TO LS-WHAT
                WHEN "N"
                    MOVE SPACES TO LS-WHAT
                    STRING "a disposition other than DELETE, KEEP, PASS,"
                           " CATLG, or UNCATLG" DELIMITED BY SIZE
                        INTO LS-WHAT
                WHEN "A"
                    MOVE SPACES TO LS-WHAT
                    STRING "an abnormal-end disposition other than"
                           " DELETE, KEEP, CATLG, or UNCATLG"
                           DELIMITED BY SIZE
                        INTO LS-WHAT
                WHEN OTHER
                    MOVE "a fourth subparameter; DISP takes three"
                        TO LS-WHAT
            END-EVALUATE
            MOVE SPACES TO LS-MESSAGE
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes DISP with " DELIMITED BY SIZE
                   JD-DISP-BAD(LS-D) DELIMITED BY SPACE
                   ", " DELIMITED BY SIZE
                   LS-WHAT DELIMITED BY "  "
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J037.

*> ---------------------------------------------------------------
*> PLB-J038 output-unresolved: an OUTPUT=*.name or *.stepname.name on
*> a DD that names no OUTPUT JCL statement before it:
*>
*>     //REPORT   OUTPUT CLASS=A,FORMS=STD
*>     //PRINT    EXEC PGM=PAYRPT
*>     //LIST     DD SYSOUT=A,OUTPUT=*.REPROT
*>
*> *.name "refers to an earlier OUTPUT JCL statement with name in its
*> name field. The system searches for the OUTPUT JCL statement first in
*> the same step, then before the first EXEC statement of the job";
*> *.stepname.name, to one in that step of the job. "If the system finds
*> no match for the name coded in the OUTPUT parameter, the system
*> issues a JCL error" (z/OS MVS JCL Reference, DD OUTPUT parameter). In
*> a procedure, the statement must come before the DD in the procedure.
*> References through a procedure step (*.step.procstep.name), DDs named
*> STEP.DD, and values with symbols are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J038.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-O                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(4) COMP-5.
01  LS-PTR                  PIC 9(4) COMP-5.
01  LS-LIST                 PIC X(60).
01  LS-REF                  PIC X(40).
01  LS-PART-1               PIC X(20).
01  LS-PART-2               PIC X(20).
01  LS-PART-3               PIC X(20).
01  LS-FOUND                PIC X.
01  LS-AT-STEP              PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J038" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-OUTPUT(LS-D) NOT = SPACES AND JD-STEP(LS-D) > 0
           AND JD-QUALIFIER(LS-D) = SPACES
            MOVE 0 TO LS-N
            INSPECT JD-OUTPUT(LS-D) TALLYING LS-N FOR ALL "&" ALL "%"
            IF LS-N = 0
                PERFORM CHECK-DD
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> Each reference of the DD's OUTPUT=, one or a list in parentheses.
CHECK-DD.
    MOVE JD-STEP(LS-D) TO LS-S
    MOVE JD-OUTPUT(LS-D) TO LS-LIST
    IF LS-LIST(1:1) = "("
        MOVE JD-OUTPUT(LS-D)(2:) TO LS-LIST
        INSPECT LS-LIST REPLACING ALL ")" BY SPACE
    END-IF
    MOVE 1 TO LS-PTR
    PERFORM UNTIL LS-PTR > 60
        MOVE SPACES TO LS-REF
        UNSTRING LS-LIST DELIMITED BY "," INTO LS-REF
            WITH POINTER LS-PTR
        END-UNSTRING
        IF LS-REF = SPACES
            EXIT PERFORM
        END-IF
        IF LS-REF(1:2) = "*."
            PERFORM CHECK-REFERENCE
        END-IF
    END-PERFORM.

*> LS-REF, *.name or *.stepname.name, against the OUTPUT statements.
CHECK-REFERENCE.
    MOVE SPACES TO LS-PART-1 LS-PART-2 LS-PART-3
    UNSTRING LS-REF(3:) DELIMITED BY "." INTO LS-PART-1 LS-PART-2
        LS-PART-3
    IF LS-PART-3 NOT = SPACES OR LS-PART-1 = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-FOUND
    IF LS-PART-2 = SPACES
        PERFORM VARYING LS-O FROM 1 BY 1 UNTIL LS-O > JO-COUNT
            IF JO-NAME(LS-O) = LS-PART-1
               AND JO-FILE-ID(LS-O) = JD-FILE-ID(LS-D)
               AND JO-LINE(LS-O) < JD-LINE(LS-D)
               AND JO-JOB(LS-O) = JS-JOB(LS-S)
               AND JO-PROC(LS-O) = JS-PROC(LS-S)
               AND (JO-STEP(LS-O) = LS-S OR JO-STEP(LS-O) = 0)
                MOVE "Y" TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-PERFORM
    ELSE
        IF JS-PROC(LS-S) > 0
            EXIT PARAGRAPH
        END-IF
        *> The step named, of this job, at or before this one.
        MOVE 0 TO LS-AT-STEP
        PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > LS-S
            IF JS-JOB(LS-E) = JS-JOB(LS-S) AND JS-PROC(LS-E) = 0
               AND JS-NAME(LS-E) = LS-PART-1
                MOVE LS-E TO LS-AT-STEP
            END-IF
        END-PERFORM
        PERFORM VARYING LS-O FROM 1 BY 1 UNTIL LS-O > JO-COUNT
            IF LS-AT-STEP > 0 AND JO-NAME(LS-O) = LS-PART-2
               AND JO-STEP(LS-O) = LS-AT-STEP
               AND JO-PROC(LS-O) = 0
               AND JO-JOB(LS-O) = JS-JOB(LS-S)
               AND (JO-FILE-ID(LS-O) NOT = JD-FILE-ID(LS-D)
                    OR JO-LINE(LS-O) < JD-LINE(LS-D))
                MOVE "Y" TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-PERFORM
    END-IF
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "DD " DELIMITED BY SIZE
           JD-NAME(LS-D) DELIMITED BY SPACE
           " codes OUTPUT=" DELIMITED BY SIZE
           LS-REF DELIMITED BY SPACE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    EVALUATE TRUE
        WHEN LS-PART-2 NOT = SPACES
            STRING ", but step " DELIMITED BY SIZE
                   LS-PART-1 DELIMITED BY SPACE
                   " has no OUTPUT statement of that name before it"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN JS-PROC(LS-S) > 0
            STRING ", but no OUTPUT statement of that name comes before"
                   " it in its procedure" DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
        WHEN OTHER
            STRING ", but no OUTPUT statement of that name comes before"
                   " it in its step, or before the job's first step"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE WITH POINTER LS-PTR
    END-EVALUATE
    STRING ": a JCL error" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J038.

*> ---------------------------------------------------------------
*> PLB-J039 dd-value-invalid: a DD keyword whose value is not one of
*> those the z/OS MVS JCL Reference lists for it:
*>
*>     //REPORT   DD SYSOUT=A,HOLD=YESS
*>     //KSDS     DD DSN=PAY.KSDS,DISP=(NEW,CATLG),RECORG=KSDS
*>
*> HOLD is YES, Y, NO, or N; FREE is END or CLOSE; SPIN is NO or
*> UNALLOC (with a time or a line count in parentheses); AVGREC is U,
*> K, or M; RECORG is KS, ES, RR, or LS; and DSNTYPE is LIBRARY, HFS,
*> PDS, PIPE, EXTREQ, EXTPREF, LARGE, or BASIC (LIBRARY, EXTREQ, and
*> EXTPREF may take a version, 1 or 2). DCB=(DSORG=) is PS, PSU, DA,
*> DAU, PO, POU, CX, or GS. LABEL=(sequence,label,...) takes a sequence
*> number up to 65535, a label of AL, AUL, BLP, LTM, NL, NSL, SL, or
*> SUL, then PASSWORD or NOPWREAD, then IN or OUT. Values with symbols
*> are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J039.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-VALUES               PIC X(60).
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J039" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-VALUE-KEY(LS-D) NOT = SPACES
            EVALUATE JD-VALUE-KEY(LS-D)
                WHEN "HOLD"
                    MOVE "YES, Y, NO, or N" TO LS-VALUES
                WHEN "FREE"
                    MOVE "END or CLOSE" TO LS-VALUES
                WHEN "SPIN"
                    MOVE "NO or UNALLOC" TO LS-VALUES
                WHEN "AVGREC"
                    MOVE "U, K, or M" TO LS-VALUES
                WHEN "DSNTYPE"
                    MOVE "LIBRARY, PDS, HFS, PIPE, EXTREQ, LARGE, ..."
                        TO LS-VALUES
                WHEN "DSORG"
                    MOVE "PS, PSU, DA, DAU, PO, POU, CX, or GS" TO LS-VALUES
                WHEN "LABEL"
                    MOVE SPACES TO LS-VALUES
                WHEN OTHER
                    MOVE "KS, ES, RR, or LS" TO LS-VALUES
            END-EVALUATE
            MOVE SPACES TO LS-MESSAGE
            IF JD-VALUE-KEY(LS-D) = "LABEL"
                STRING "DD " DELIMITED BY SIZE
                       JD-NAME(LS-D) DELIMITED BY SPACE
                       " codes " DELIMITED BY SIZE
                       JD-VALUE-BAD(LS-D) DELIMITED BY SPACE
                       " in LABEL, which takes a sequence number, a label"
                       " (SL, NL, AL, ...), PASSWORD or NOPWREAD, and IN"
                       " or OUT" DELIMITED BY SIZE
                    INTO LS-MESSAGE
            ELSE
                STRING "DD " DELIMITED BY SIZE
                       JD-NAME(LS-D) DELIMITED BY SPACE
                       " codes " DELIMITED BY SIZE
                       JD-VALUE-KEY(LS-D) DELIMITED BY SPACE
                       "=" DELIMITED BY SIZE
                       JD-VALUE-BAD(LS-D) DELIMITED BY SPACE
                       ", not " DELIMITED BY SIZE
                       LS-VALUES DELIMITED BY "  "
                    INTO LS-MESSAGE
            END-IF
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J039.

*> ---------------------------------------------------------------
*> PLB-J040 recfm-invalid: a RECFM that is none of the record formats
*> the z/OS MVS JCL Reference lists:
*>
*>     //OUTFILE  DD DSN=PAY.OUT,DISP=(NEW,CATLG),RECFM=BF,LRECL=80
*>
*> "RECFM parameter" lists, for its access methods, U, UT, F, FB, FS,
*> FT, FBS, FBT, V, VB, VS, VT, VBS, VBT, VBST, and for ISO/ANSI tapes
*> D, DB, DS, DBS, and says "A or M can be coded with any record
*> format, such as: RECFM=FBA" (A only with D). The letters come in
*> that order: BF, FBB, or VF are none of them. RECFM is read as a
*> keyword and in DCB=( ); values with symbols are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J040.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J040" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-RECFM-BAD(LS-D) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes RECFM=" DELIMITED BY SIZE
                   JD-RECFM-BAD(LS-D) DELIMITED BY SPACE
                   ", none of the record formats z/OS takes (F, FB, V,"
                   " VB, U, ..., with A or M)" DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J040.

*> ---------------------------------------------------------------
*> PLB-J041 dd-parameter-conflict: a DD that codes two parameters the
*> z/OS MVS JCL Reference says not to code together:
*>
*>     //KSDS     DD DSN=PAY.KSDS,DISP=(NEW,CATLG),RECORG=KS,RECFM=FB
*>     //RECS     DD DSN=PAY.RECS,DISP=(NEW,CATLG),AVGREC=K,
*>     //            SPACE=(TRK,(10,5))
*>
*> From the "Relationship to other parameters" of each: RECORG not with
*> RECFM, DCB=RECFM, DSNTYPE, DCB=DSORG, or FREE=CLOSE; AVGREC not with
*> a SPACE in TRK, CYL, or ABSTR ("When specifying the TRK, CYL, or
*> ABSTR subparameters of the SPACE parameter, do not code the AVGREC
*> parameter"); LRECL not with DCB=LRECL; RECFM not with DCB=RECFM. The
*> first pair found is reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J041.
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
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J041" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-CONFLICT-1(LS-D) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes " DELIMITED BY SIZE
                   JD-CONFLICT-1(LS-D) DELIMITED BY SPACE
                   " with " DELIMITED BY SIZE
                   JD-CONFLICT-2(LS-D) DELIMITED BY "  "
                   ", which the JCL Reference says not to code together"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J041.

*> ---------------------------------------------------------------
*> PLB-J042 exec-value-invalid: an ADDRSPC=, RD=, or MEMLIMIT= on a JOB
*> or EXEC statement whose value the z/OS MVS JCL Reference does not
*> list:
*>
*>     //LOAD     EXEC PGM=PAYLOAD,ADDRSPC=VIRTUAL
*>     //SORT     EXEC PGM=SORT,MEMLIMIT=10GB
*>
*> ADDRSPC is VIRT or REAL; RD is R, RNC, NR, or NC; MEMLIMIT is NOLIMIT
*> or nnnnnM, nnnnnG, nnnnnT, or nnnnnP, "nnnnn may be a value from 0 to
*> 99999, with a maximum value of 16384P". Of the JOB statement alone,
*> TYPRUN is COPY, HOLD, JCLHOLD, or SCAN; PRTY "a number from 0 through
*> 15"; JESLOG SPIN, NOSPIN, or SUPPRESS. Values with symbols are not
*> read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J042.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-KEY                  PIC X(8).
01  LS-VALUES               PIC X(60).
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J042" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JJ-COUNT
        IF JJ-VALUE-KEY(LS-I) NOT = SPACES
            MOVE JJ-VALUE-KEY(LS-I) TO LS-KEY
            PERFORM VALUES-OF-KEY
            MOVE SPACES TO LS-MESSAGE
            STRING "job " DELIMITED BY SIZE
                   JJ-NAME(LS-I) DELIMITED BY SPACE
                   " codes " DELIMITED BY SIZE
                   JJ-VALUE-KEY(LS-I) DELIMITED BY SPACE
                   "=" DELIMITED BY SIZE
                   JJ-VALUE-BAD(LS-I) DELIMITED BY SPACE
                   ", not " DELIMITED BY SIZE
                   LS-VALUES DELIMITED BY "  "
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JJ-FILE-ID(LS-I) JJ-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        IF JS-VALUE-KEY(LS-I) NOT = SPACES
            MOVE JS-VALUE-KEY(LS-I) TO LS-KEY
            PERFORM VALUES-OF-KEY
            MOVE SPACES TO LS-MESSAGE
            STRING "step " DELIMITED BY SIZE
                   JS-NAME(LS-I) DELIMITED BY SPACE
                   " codes " DELIMITED BY SIZE
                   JS-VALUE-KEY(LS-I) DELIMITED BY SPACE
                   "=" DELIMITED BY SIZE
                   JS-VALUE-BAD(LS-I) DELIMITED BY SPACE
                   ", not " DELIMITED BY SIZE
                   LS-VALUES DELIMITED BY "  "
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JS-FILE-ID(LS-I) JS-LINE(LS-I) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.

VALUES-OF-KEY.
    EVALUATE TRUE
        WHEN LS-KEY(1:7) = "ADDRSPC"
            MOVE "VIRT or REAL" TO LS-VALUES
        WHEN LS-KEY = "TYPRUN"
            MOVE "COPY, HOLD, JCLHOLD, or SCAN" TO LS-VALUES
        WHEN LS-KEY = "PRTY"
            MOVE "a priority from 0 through 15" TO LS-VALUES
        WHEN LS-KEY = "JESLOG"
            MOVE "SPIN, NOSPIN, or SUPPRESS" TO LS-VALUES
        WHEN LS-KEY(1:2) = "RD"
            MOVE "R, RNC, NR, or NC" TO LS-VALUES
        WHEN OTHER
            MOVE "NOLIMIT or 0 to 99999 with M, G, T, or P (up to 16384P)"
                TO LS-VALUES
    END-EVALUATE.
END PROGRAM PLB-RULE-J042.

*> ---------------------------------------------------------------
*> PLB-J043 joblib-misplaced: a JOBLIB DD that is not right after the
*> JOB statement, or that is in a procedure:
*>
*>     //PAYJOB   JOB (ACCT),'PAY'
*>     //SYSOUT   DD SYSOUT=*
*>     //JOBLIB   DD DSN=PAY.LOADLIB,DISP=SHR
*>
*> The z/OS MVS JCL Reference ("JOBLIB DD statement", Location in the
*> JCL): "The JOBLIB DD statement must immediately follow the JOB
*> statement and any JES statements. There must be no intervening EXEC
*> or other DD statements", and "Do not include a JOBLIB DD statement in
*> an in-stream or cataloged procedure". A JOBLIB after an EXEC is a DD
*> of that step, so the job's programs are not looked for in the
*> library. Concatenated DDs right after the JOBLIB are part of it.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J043.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J043" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-NAME(LS-D) = "JOBLIB" AND JD-CONCAT(LS-D) = "N"
           AND JD-QUALIFIER(LS-D) = SPACES
            PERFORM CHECK-JOBLIB
        END-IF
    END-PERFORM
    *> Before the first EXEC, after another DD (the JCL reader notes it).
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > JJ-COUNT
        IF JJ-JOBLIB-AFTER(LS-J) NOT = SPACES
            MOVE SPACES TO LS-MESSAGE
            STRING "JOBLIB DD after DD " DELIMITED BY SIZE
                   JJ-JOBLIB-AFTER(LS-J) DELIMITED BY SPACE
                   ": it must come right after the JOB statement"
                   DELIMITED BY SIZE
                INTO LS-MESSAGE
            CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
                JJ-FILE-ID(LS-J) JJ-JOBLIB-LINE(LS-J) LS-COLUMN LS-ZERO
                LS-MESSAGE
        END-IF
    END-PERFORM
    GOBACK.

CHECK-JOBLIB.
    MOVE SPACES TO LS-MESSAGE
    EVALUATE TRUE
        WHEN JD-STEP(LS-D) > 0 AND JS-PROC(JD-STEP(LS-D)) > 0
            MOVE "JOBLIB DD in a procedure: a procedure may not have one"
                TO LS-MESSAGE
        WHEN JD-STEP(LS-D) > 0
            STRING "JOBLIB DD after EXEC " DELIMITED BY SIZE
                   JS-NAME(JD-STEP(LS-D)) DELIMITED BY SPACE
                   ": it must come right after the JOB statement, and"
                   " here is a DD of that step" DELIMITED BY SIZE
                INTO LS-MESSAGE
    END-EVALUATE
    IF LS-MESSAGE NOT = SPACES
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF.

END PROGRAM PLB-RULE-J043.

*> ---------------------------------------------------------------
*> PLB-J044 jcllib-misplaced: a JCLLIB statement after the first EXEC
*> of its job, a second JCLLIB in a job, or one in a procedure:
*>
*>     //PAYJOB   JOB (ACCT),'PAY'
*>     //STEP1    EXEC PAYPROC
*>     //LIBS     JCLLIB ORDER=PAY.PROCLIB
*>
*> The z/OS MVS JCL Reference ("JCLLIB statement"): a JCLLIB "must
*> appear after the JOB statement and before the first EXEC statement
*> in the job", and "you can code only one JCLLIB statement per job".
*> The libraries it names are where the job's procedures are found.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J044.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-L                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J044" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-L FROM 1 BY 1 UNTIL LS-L > JL-COUNT
        EVALUATE JL-PROBLEM(LS-L)
            WHEN "A"
                MOVE SPACES TO LS-MESSAGE
                STRING "JCLLIB after the first EXEC of its job: it must"
                       " come before the first EXEC" DELIMITED BY SIZE
                    INTO LS-MESSAGE
            WHEN "T"
                MOVE "a second JCLLIB in the job: a job has only one"
                    TO LS-MESSAGE
            WHEN OTHER
                MOVE "JCLLIB in a procedure: it belongs to the job"
                    TO LS-MESSAGE
        END-EVALUATE
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            JL-FILE-ID(LS-L) JL-LINE(LS-L) LS-COLUMN LS-ZERO LS-MESSAGE
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-J044.

*> ---------------------------------------------------------------
*> PLB-J045 unit-aff-invalid: a UNIT=AFF=ddname that names no earlier
*> DD of its step, or that the z/OS MVS JCL Reference says not to code:
*>
*>     //TAPE1    DD DSN=PAY.TAPE1,DISP=OLD,UNIT=AFF=TAPE2
*>     //TAPE2    DD DSN=PAY.TAPE2,DISP=OLD,UNIT=TAPE
*>
*> Unit affinity puts the data set on the device of another DD, where
*> "ddname is the ddname of an earlier DD statement in the same step"
*> (UNIT parameter). Its restrictions: "Do not code UNIT=AFF=ddname" on
*> a DD * or DD DATA statement or one with SUBSYS (the system ignores
*> it), "when the DD statement referenced in the AFF subparameter
*> contains FREE=CLOSE", or "with the STORCLAS parameter". DDs named
*> STEP.DD are not read.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J045.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-FOUND                PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J045" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-UNIT-AFF(LS-D) NOT = SPACES
           AND JD-QUALIFIER(LS-D) = SPACES
            PERFORM CHECK-DD
        END-IF
    END-PERFORM
    GOBACK.

CHECK-DD.
    MOVE SPACES TO LS-MESSAGE
    EVALUATE JD-AFF-WITH(LS-D)
        WHEN "S"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes UNIT=AFF with STORCLAS, which the JCL"
                   " Reference says not to" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN "U" WHEN "I"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " codes UNIT=AFF on in-stream data or with SUBSYS:"
                   " the system ignores it" DELIMITED BY SIZE
                INTO LS-MESSAGE
        WHEN OTHER
            *> The earlier DD of the step it names.
            MOVE 0 TO LS-FOUND
            PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E >= LS-D
                IF JD-STEP(LS-E) = JD-STEP(LS-D)
                   AND JD-NAME(LS-E) = JD-UNIT-AFF(LS-D)
                    MOVE LS-E TO LS-FOUND
                END-IF
            END-PERFORM
            EVALUATE TRUE
                WHEN LS-FOUND = 0
                    STRING "DD " DELIMITED BY SIZE
                           JD-NAME(LS-D) DELIMITED BY SPACE
                           " codes UNIT=AFF=" DELIMITED BY SIZE
                           JD-UNIT-AFF(LS-D) DELIMITED BY SPACE
                           ", but no earlier DD of its step has that"
                           " name" DELIMITED BY SIZE
                        INTO LS-MESSAGE
                WHEN JD-FREE-CLOSE(LS-FOUND) = "Y"
                    STRING "DD " DELIMITED BY SIZE
                           JD-NAME(LS-D) DELIMITED BY SPACE
                           " codes UNIT=AFF=" DELIMITED BY SIZE
                           JD-UNIT-AFF(LS-D) DELIMITED BY SPACE
                           ", a DD with FREE=CLOSE, which the JCL"
                           " Reference says not to" DELIMITED BY SIZE
                        INTO LS-MESSAGE
            END-EVALUATE
    END-EVALUATE
    IF LS-MESSAGE NOT = SPACES
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
            JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE
    END-IF.
END PROGRAM PLB-RULE-J045.
