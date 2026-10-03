*> ---------------------------------------------------------------
*> plbrjcl: programs checked against the JCL that runs them.
*>
*>   PLB-J001  dd-missing           a file the step's programs open has
*>                                  no DD in the step
*>   PLB-J002  dd-unused            a DD of the step that none of its
*>                                  programs assigns
*>   PLB-J003  program-not-in-run   a step runs a program that is not
*>                                  among the programs of the run
*>   PLB-J004  dd-cannot-be-read    a file the program only reads has
*>                                  a DD that gives it no data
*>   PLB-J005  temp-not-created     a step reads a temporary data set
*>                                  no earlier step creates
*>   PLB-J006  lrecl-mismatch       a DD's LRECL is not the length of
*>                                  the program's records
*>   PLB-J007  dataset-created-twice  a DD creates and catalogs a data
*>                                  set an earlier DD already did
*>
*> A step that runs a program of the run (EXEC PGM=name) gives that
*> program, and the programs it calls by literal name, their files:
*> each SELECT ... ASSIGN TO name opens the step's DD of that name.
*> A step in a procedure also has the DDs that the job steps running
*> the procedure add as STEP.DDNAME.
*>
*> A step whose program starts another one (DFSRRC00 for IMS,
*> IKJEFT01 running a DB2 program) is checked for the program it runs,
*> as the JCL reader finds it in PARM or in the SYSTSIN input.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-JCL.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
*> The programs a step runs: its program and those it calls.
78  RN-MAX                      VALUE 500.
01  WS-RUNS.
    05  WS-RUN-COUNT        PIC 9(4) COMP-5.
    05  WS-RUN              PIC 9(9) COMP-5 OCCURS RN-MAX TIMES.
*> The DD names the step has: its own, and overrides from the jobs
*> that run its procedure.
78  SD-MAX                      VALUE 2000.
01  WS-STEP-DDS.
    05  WS-SD-COUNT         PIC 9(4) COMP-5.
    05  WS-SD               OCCURS SD-MAX TIMES.
        10  WS-SD-NAME      PIC X(8).
        10  WS-SD-USED      PIC X.
        10  WS-SD-ENTRY     PIC 9(9) COMP-5.
*> The program files that steps give a data set to, for PLB-A002: the
*> data set without a generation, the job or procedure of a temporary
*> one, the record length, the program, and the DD.
78  US-MAX                      VALUE 5000.
01  WS-USES.
    05  WS-USE-COUNT        PIC 9(9) COMP-5.
    05  WS-USE              OCCURS US-MAX TIMES.
        10  WS-USE-KEY      PIC X(44).
        10  WS-USE-JOB      PIC 9(18) COMP-5.
        10  WS-USE-SIZE     PIC 9(9) COMP-5.
        10  WS-USE-PROGRAM  PIC 9(9) COMP-5.
        10  WS-USE-DD       PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-RULE-MISSING         PIC 9(4) COMP-5.
01  LS-RULE-UNUSED          PIC 9(4) COMP-5.
01  LS-RULE-UNKNOWN         PIC 9(4) COMP-5.
01  LS-RULE-UNREADABLE      PIC 9(4) COMP-5.
01  LS-RULE-LRECL           PIC 9(4) COMP-5.
01  LS-RULE-CONFLICT        PIC 9(4) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-C-TEXT               PIC X(20).
01  LS-C-LEN                PIC 9(9) COMP-5.
01  LS-ASA                  PIC 9(4) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-A-TEXT               PIC X(20).
01  LS-A-LEN                PIC 9(9) COMP-5.
01  LS-B-TEXT               PIC X(20).
01  LS-B-LEN                PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-PATH-DD              PIC X(8).
01  LS-DIGIT                PIC 9.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-DYNAMIC              PIC X.
01  LS-STEP-NAME            PIC X(8).
01  LS-PROC-NAME            PIC X(8).
01  LS-PROGRAM-NAME         PIC X(8).
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbcall.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J001" LS-RULE-MISSING
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J002" LS-RULE-UNUSED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J003" LS-RULE-UNKNOWN
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J004" LS-RULE-UNREADABLE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J006" LS-RULE-LRECL
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-A002" LS-RULE-CONFLICT
    CALL "PLB-RULE-JCL-TEMPS" USING PLB-RULES PLB-FINDINGS PLB-JCL
    CALL "PLB-RULE-J007" USING PLB-RULES PLB-FINDINGS PLB-JCL
    MOVE 0 TO WS-USE-COUNT
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) = "P"
            PERFORM CHECK-STEP
        END-IF
    END-PERFORM
    IF RL-ENABLED(LS-RULE-CONFLICT) = "Y"
        PERFORM VARYING LS-U FROM 2 BY 1 UNTIL LS-U > WS-USE-COUNT
            PERFORM CHECK-USE
        END-PERFORM
    END-IF
    GOBACK.

CHECK-STEP.
    PERFORM FIND-PROGRAM
    IF LS-P = 0
        IF CP-COUNT > 0
            PERFORM REPORT-UNKNOWN
        END-IF
        EXIT PARAGRAPH
    END-IF
    PERFORM COLLECT-RUNS
    PERFORM COLLECT-STEP-DDS
    *> Each file the step's programs open needs its DD.
    MOVE "N" TO LS-DYNAMIC
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > PF-COUNT
        PERFORM IS-RUN-PROGRAM
        IF LS-FOUND = "Y"
            PERFORM CHECK-FILE
        END-IF
    END-PERFORM
    *> DDs no program of the step assigns; not when some file's DD
    *> name is only known at run time, nor in a step whose program
    *> starts the COBOL program (IMS and DB2 read DDs of their own).
    IF LS-DYNAMIC = "N" AND JS-INNER(LS-S) = SPACES
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-SD-COUNT
            IF WS-SD-USED(LS-I) = "N"
                PERFORM REPORT-UNUSED
            END-IF
        END-PERFORM
    END-IF.

*> LS-P = the outermost program of the run that step LS-S runs.
FIND-PROGRAM.
    MOVE 0 TO LS-P
    MOVE JS-TARGET(LS-S) TO LS-PROGRAM-NAME
    IF JS-INNER(LS-S) NOT = SPACES
        MOVE JS-INNER(LS-S) TO LS-PROGRAM-NAME
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CP-COUNT
        IF CP-KIND(LS-I) = "P" AND CP-PARENT(LS-I) = 0
           AND CP-NAME(LS-I) = LS-PROGRAM-NAME
            MOVE LS-I TO LS-P
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> WS-RUN = LS-P and every program it calls, directly or not, through
*> calls the graph resolved.
COLLECT-RUNS.
    MOVE 1 TO WS-RUN-COUNT
    MOVE LS-P TO WS-RUN(1)
    MOVE 1 TO LS-K
    PERFORM UNTIL LS-K > WS-RUN-COUNT
        PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
            IF CC-TO(LS-C) > 0
                IF CP-OWNER(CC-FROM(LS-C)) = WS-RUN(LS-K)
                    MOVE CP-OWNER(CC-TO(LS-C)) TO LS-J
                    PERFORM ADD-RUN
                END-IF
            END-IF
        END-PERFORM
        ADD 1 TO LS-K
    END-PERFORM.

ADD-RUN.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-RUN-COUNT
        IF WS-RUN(LS-I) = LS-J
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-RUN-COUNT < RN-MAX
        ADD 1 TO WS-RUN-COUNT
        MOVE LS-J TO WS-RUN(WS-RUN-COUNT)
    END-IF.

*> LS-FOUND = "Y" when file LS-F belongs to a program of the step:
*> one of WS-RUN, or a program nested in one.
IS-RUN-PROGRAM.
    MOVE "N" TO LS-FOUND
    MOVE PF-PROGRAM(LS-F) TO LS-J
    PERFORM UNTIL LS-J = 0
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-RUN-COUNT
            IF WS-RUN(LS-I) = LS-J
                MOVE "Y" TO LS-FOUND
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
        MOVE CP-PARENT(LS-J) TO LS-J
    END-PERFORM.

*> The DD names of step LS-S, and of the job steps that run its
*> procedure with STEP.DDNAME.
COLLECT-STEP-DDS.
    MOVE 0 TO WS-SD-COUNT
    PERFORM VARYING LS-D FROM JS-DD-FIRST(LS-S) BY 1
            UNTIL LS-D >= JS-DD-FIRST(LS-S) + JS-DD-COUNT(LS-S)
        PERFORM ADD-STEP-DD
    END-PERFORM
    IF JS-PROC(LS-S) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE JS-NAME(LS-S) TO LS-STEP-NAME
    MOVE JP-NAME(JS-PROC(LS-S)) TO LS-PROC-NAME
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > JS-COUNT
        IF JS-KIND(LS-J) = "R" AND JS-TARGET(LS-J) = LS-PROC-NAME
            PERFORM VARYING LS-D FROM JS-DD-FIRST(LS-J) BY 1
                    UNTIL LS-D >= JS-DD-FIRST(LS-J) + JS-DD-COUNT(LS-J)
                IF JD-QUALIFIER(LS-D) = LS-STEP-NAME
                    PERFORM ADD-STEP-DD
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM.

*> DD LS-D, once per name. DDs the system or the runtime reads
*> (STEPLIB, SYSOUT, SYSPRINT, CEEDUMP, ...) count as used.
ADD-STEP-DD.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-SD-COUNT
        IF WS-SD-NAME(LS-I) = JD-NAME(LS-D)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-SD-COUNT >= SD-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-SD-COUNT
    MOVE JD-NAME(LS-D) TO WS-SD-NAME(WS-SD-COUNT)
    MOVE LS-D TO WS-SD-ENTRY(WS-SD-COUNT)
    MOVE "N" TO WS-SD-USED(WS-SD-COUNT)
    IF JD-NAME(LS-D)(1:3) = "SYS" OR JD-NAME(LS-D)(1:3) = "CEE"
       OR JD-NAME(LS-D)(1:4) = "SORT" OR JD-NAME(LS-D) = "STEPLIB"
       OR JD-NAME(LS-D) = "JOBLIB" OR JD-QUALIFIER(LS-D) NOT = SPACES
        MOVE "Y" TO WS-SD-USED(WS-SD-COUNT)
    END-IF.

*> File LS-F: its DD must be there when the program opens it, unless
*> the file is OPTIONAL or a sort file.
CHECK-FILE.
    IF PF-DDNAME(LS-F) = SPACES
        IF PF-SORT(LS-F) = "N"
            MOVE "Y" TO LS-DYNAMIC
        END-IF
        EXIT PARAGRAPH
    END-IF
    *> An alternate index is read through a path whose DD name is the
    *> file's with a digit at the end, in its last place if the name
    *> has 8 characters: XREFFILE, XREFFIL1, XREFFIL2.
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > PF-ALTERNATES(LS-F)
                                        OR LS-K > 9
        MOVE PF-DDNAME(LS-F) TO LS-PATH-DD
        CALL "PLB-STR-LENGTH" USING LS-PATH-DD LS-LEN
        *> plumbline: ignore move-truncation -- the loop stops at 9
        MOVE LS-K TO LS-DIGIT
        IF LS-LEN = 8
            MOVE LS-DIGIT TO LS-PATH-DD(8:1)
        ELSE
            MOVE LS-DIGIT TO LS-PATH-DD(LS-LEN + 1:1)
        END-IF
        PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-SD-COUNT
            IF WS-SD-NAME(LS-I) = LS-PATH-DD
                MOVE "Y" TO WS-SD-USED(LS-I)
            END-IF
        END-PERFORM
    END-PERFORM
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-SD-COUNT
        IF WS-SD-NAME(LS-I) = PF-DDNAME(LS-F)
            MOVE "Y" TO WS-SD-USED(LS-I) LS-FOUND
            PERFORM CHECK-READABLE
            PERFORM CHECK-LRECL
            PERFORM NOTE-USE
        END-IF
    END-PERFORM
    IF LS-FOUND = "Y" OR PF-OPTIONAL(LS-F) = "Y" OR PF-SORT(LS-F) = "Y"
        EXIT PARAGRAPH
    END-IF
    IF PF-INPUT(LS-F) = "N" AND PF-OUTPUT(LS-F) = "N"
       AND PF-I-O(LS-F) = "N" AND PF-EXTEND(LS-F) = "N"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "step " DELIMITED BY SIZE
           JS-NAME(LS-S) DELIMITED BY SPACE
           " has no DD " DELIMITED BY SIZE
           PF-DDNAME(LS-F) DELIMITED BY SPACE
           " for file " DELIMITED BY SIZE
           PF-NAME(LS-F) DELIMITED BY SPACE
           ", which " DELIMITED BY SIZE
           CP-NAME(PF-PROGRAM(LS-F)) DELIMITED BY SPACE
           " opens" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-MISSING
        JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE.

*> PLB-A002 record-length-conflict: two programs whose files, through
*> the DDs of the steps that run them, are the same data set, and whose
*> records for it have different lengths:
*>
*>     //EXTRACT EXEC PGM=ACCTEXT   FD ACCT-OUT, 01 record of 300 bytes
*>     //OUT     DD DSN=PROD.ACCT.EXTRACT,...
*>     //REPORT  EXEC PGM=ACCTRPT   FD ACCT-IN, 01 record of 350 bytes
*>     //IN      DD DSN=PROD.ACCT.EXTRACT,DISP=SHR
*>
*> One of them has an old copy of the layout: the reader fails to open
*> the file (status 39), or reads each record shifted against its
*> fields. Data sets are compared by name without a generation
*> (PAY.HISTORY(+1) is PAY.HISTORY), and temporary ones (&&NAME)
*> within their job. Only files of fixed length count: not those whose
*> records differ in length or vary, not DDs with RECFM V or U, and not
*> sort files.
*>
*> NOTE-USE keeps the file of LS-F through DD LS-D (WS-SD-ENTRY of
*> LS-I); CHECK-USE compares use LS-U with the first of its data set.
NOTE-USE.
    MOVE WS-SD-ENTRY(LS-I) TO LS-D
    IF JD-KIND(LS-D) NOT = "D" OR PF-SORT(LS-F) = "Y"
       OR PF-VARIABLE(LS-F) = "Y" OR PF-RECORD-SIZE(LS-F) = 0
       OR JD-RECFM(LS-D)(1:1) = "V" OR JD-RECFM(LS-D)(1:1) = "U"
       OR WS-USE-COUNT >= US-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-USE-COUNT
    MOVE SPACES TO WS-USE-KEY(WS-USE-COUNT)
    UNSTRING JD-DSN(LS-D) DELIMITED BY "("
        INTO WS-USE-KEY(WS-USE-COUNT)
    END-UNSTRING
    MOVE 0 TO WS-USE-JOB(WS-USE-COUNT)
    IF JD-DSN(LS-D)(1:2) = "&&"
        COMPUTE WS-USE-JOB(WS-USE-COUNT) =
            JS-JOB(LS-S) + 100000 * JS-PROC(LS-S)
    END-IF
    MOVE PF-RECORD-SIZE(LS-F) TO WS-USE-SIZE(WS-USE-COUNT)
    MOVE PF-PROGRAM(LS-F) TO WS-USE-PROGRAM(WS-USE-COUNT)
    MOVE LS-D TO WS-USE-DD(WS-USE-COUNT).

*> The first use of the data set, usually the step that creates it,
*> sets the length: a later use that agrees with it is not reported
*> for disagreeing with another one that does not.
CHECK-USE.
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K >= LS-U
        IF WS-USE-KEY(LS-K) = WS-USE-KEY(LS-U)
           AND WS-USE-JOB(LS-K) = WS-USE-JOB(LS-U)
            IF WS-USE-SIZE(LS-K) NOT = WS-USE-SIZE(LS-U)
                PERFORM REPORT-CONFLICT
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-CONFLICT.
    MOVE WS-USE-SIZE(LS-U) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE WS-USE-SIZE(LS-K) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    MOVE JD-LINE(WS-USE-DD(LS-K)) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-C-TEXT LS-C-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING WS-USE-KEY(LS-U) DELIMITED BY SPACE
           " has " DELIMITED BY SIZE
           LS-A-TEXT(1:LS-A-LEN) DELIMITED BY SIZE
           "-byte records in " DELIMITED BY SIZE
           CP-NAME(WS-USE-PROGRAM(LS-U)) DELIMITED BY SPACE
           " but " DELIMITED BY SIZE
           LS-B-TEXT(1:LS-B-LEN) DELIMITED BY SIZE
           "-byte ones in " DELIMITED BY SIZE
           CP-NAME(WS-USE-PROGRAM(LS-K)) DELIMITED BY SPACE
           " (DD on line " DELIMITED BY SIZE
           LS-C-TEXT(1:LS-C-LEN) DELIMITED BY SIZE
           ")" DELIMITED BY SIZE
        INTO LS-MESSAGE
    MOVE WS-USE-DD(LS-U) TO LS-D
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-CONFLICT
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.

*> PLB-J006: the DD of file LS-F (WS-SD-ENTRY of LS-I) gives a record
*> length the program's records do not have. With a fixed format
*> (RECFM F, FB, ...), LRECL is the record's length; with a variable
*> one (V, VB, ...), the longest record's length and 4 bytes for its
*> descriptor at most. With ASA control characters (FBA, VBA), one
*> more byte for the character is also right. A DD without RECFM, or
*> with U, is not checked.
CHECK-LRECL.
    MOVE WS-SD-ENTRY(LS-I) TO LS-D
    IF JD-LRECL(LS-D) = 0 OR PF-RECORD-SIZE(LS-F) = 0
       OR JD-RECFM(LS-D) = SPACES OR JD-RECFM(LS-D)(1:1) = "U"
       OR PF-SORT(LS-F) = "Y"
        EXIT PARAGRAPH
    END-IF
    *> With ASA control characters (RECFM FBA, VBA), a program that
    *> writes with ADVANCING may have one more byte for the character.
    MOVE 0 TO LS-ASA
    INSPECT JD-RECFM(LS-D) TALLYING LS-ASA FOR ALL "A"
    IF JD-RECFM(LS-D)(1:1) = "V"
        IF PF-RECORD-SIZE(LS-F) + 4 + LS-ASA <= JD-LRECL(LS-D)
           OR PF-RECORD-SIZE(LS-F) + 4 <= JD-LRECL(LS-D)
            EXIT PARAGRAPH
        END-IF
    ELSE
        IF PF-RECORD-SIZE(LS-F) = JD-LRECL(LS-D)
           OR PF-RECORD-SIZE(LS-F) + LS-ASA = JD-LRECL(LS-D)
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE JD-LRECL(LS-D) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-A-TEXT LS-A-LEN
    MOVE PF-RECORD-SIZE(LS-F) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING "DD " DELIMITED BY SIZE
           JD-NAME(LS-D) DELIMITED BY SPACE
           " has LRECL=" LS-A-TEXT(1:LS-A-LEN) " RECFM="
           DELIMITED BY SIZE
           JD-RECFM(LS-D) DELIMITED BY SPACE
           ", but the records of " DELIMITED BY SIZE
           PF-NAME(LS-F) DELIMITED BY SPACE
           " in " DELIMITED BY SIZE
           CP-NAME(PF-PROGRAM(LS-F)) DELIMITED BY SPACE
           " are " LS-B-TEXT(1:LS-B-LEN) " bytes" DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF JD-RECFM(LS-D)(1:1) = "V"
        STRING " (" DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
        COMPUTE LS-NUM = PF-RECORD-SIZE(LS-F) + 4
        CALL "PLB-STR-FROM-INT" USING LS-NUM LS-B-TEXT LS-B-LEN
        STRING LS-B-TEXT(1:LS-B-LEN) " with the record descriptor)"
            DELIMITED BY SIZE INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-LRECL
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.

*> PLB-J004: a file opened only for input, whose DD (WS-SD-ENTRY of
*> LS-I) is a new data set, which is empty, or SYSOUT, which cannot be
*> read. DUMMY is left alone: it reads as an empty file on purpose.
CHECK-READABLE.
    IF PF-INPUT(LS-F) = "N" OR PF-OUTPUT(LS-F) = "Y"
       OR PF-I-O(LS-F) = "Y" OR PF-EXTEND(LS-F) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE WS-SD-ENTRY(LS-I) TO LS-D
    MOVE SPACES TO LS-MESSAGE
    EVALUATE TRUE
        WHEN JD-KIND(LS-D) = "S"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " is SYSOUT, but " DELIMITED BY SIZE
                   CP-NAME(PF-PROGRAM(LS-F)) DELIMITED BY SPACE
                   " reads it as " DELIMITED BY SIZE
                   PF-NAME(LS-F) DELIMITED BY SPACE
                INTO LS-MESSAGE
        WHEN JD-DISP(LS-D) = "NEW"
            STRING "DD " DELIMITED BY SIZE
                   JD-NAME(LS-D) DELIMITED BY SPACE
                   " creates a new, empty data set, but " DELIMITED BY SIZE
                   CP-NAME(PF-PROGRAM(LS-F)) DELIMITED BY SPACE
                   " only reads it as " DELIMITED BY SIZE
                   PF-NAME(LS-F) DELIMITED BY SPACE
                INTO LS-MESSAGE
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-UNREADABLE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.

REPORT-UNUSED.
    MOVE WS-SD-ENTRY(LS-I) TO LS-D
    MOVE SPACES TO LS-MESSAGE
    STRING "DD " DELIMITED BY SIZE
           JD-NAME(LS-D) DELIMITED BY SPACE
           " is not a file of " DELIMITED BY SIZE
           CP-NAME(LS-P) DELIMITED BY SPACE
           " or the programs it calls" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-UNUSED
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.

REPORT-UNKNOWN.
    MOVE SPACES TO LS-MESSAGE
    STRING "step " DELIMITED BY SIZE
           JS-NAME(LS-S) DELIMITED BY SPACE
           " runs " DELIMITED BY SIZE
           LS-PROGRAM-NAME DELIMITED BY SPACE
           ", which is not among the programs checked" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-UNKNOWN
        JS-FILE-ID(LS-S) JS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-JCL.

*> PLB-J005 temp-not-created: a step reads a temporary data set
*> (DSN=&&NAME with DISP=OLD or SHR) that no earlier step of its job,
*> or of its procedure, creates. A temporary data set lives only from
*> the step that creates it (DISP=NEW or MOD, or no DISP) to the end of
*> the job, so the step fails with a JCL error.
*>
*> A job that runs a procedure before the step is not checked, since
*> the procedure's steps may create it; nor is a DD that a job adds to
*> a procedure's step.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-JCL-TEMPS.
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
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-MESSAGE              PIC X(200).
01  LS-PTR                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J005" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        IF JD-KIND(LS-D) = "D" AND JD-DSN(LS-D)(1:2) = "&&"
           AND (JD-DISP(LS-D) = "OLD" OR JD-DISP(LS-D) = "SHR")
           AND JD-QUALIFIER(LS-D) = SPACES AND JD-STEP(LS-D) > 0
            PERFORM CHECK-TEMP
        END-IF
    END-PERFORM
    GOBACK.

*> An earlier step of the same job or procedure that creates the data
*> set, or one that runs a procedure, which may.
CHECK-TEMP.
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
        PERFORM REPORT-TEMP
    END-IF.

REPORT-TEMP.
    MOVE SPACES TO LS-MESSAGE
    MOVE 1 TO LS-PTR
    STRING JD-DSN(LS-D) DELIMITED BY SPACE
           " is read with DISP=" DELIMITED BY SIZE
           JD-DISP(LS-D) DELIMITED BY SPACE
           ", but no earlier step of the " DELIMITED BY SIZE
        INTO LS-MESSAGE WITH POINTER LS-PTR
    IF JS-JOB(LS-S) > 0
        STRING "job creates it" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    ELSE
        STRING "procedure creates it" DELIMITED BY SIZE
            INTO LS-MESSAGE WITH POINTER LS-PTR
    END-IF
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-JCL-TEMPS.

*> PLB-J007 dataset-created-twice: a DD that creates and catalogs a
*> data set (DISP=(NEW,CATLG), or (,CATLG)) that an earlier DD of the
*> same job, or procedure, already created and cataloged, with no DD
*> in between that deletes it:
*>
*>     //EXTRACT  EXEC PGM=ACCTEXT
*>     //OUT      DD DSN=PROD.ACCT.EXTRACT,DISP=(NEW,CATLG,DELETE)
*>     //RESORT   EXEC PGM=SORT
*>     //SORTOUT  DD DSN=PROD.ACCT.EXTRACT,DISP=(NEW,CATLG,DELETE)
*>
*> The data set exists when the second step asks for a new one: the
*> step fails with a duplicate name, or the data set is made and left
*> uncataloged (NOT CATLGD 2). Temporary data sets, generations
*> (NAME(+1)), and names with symbols (&HLQ..NAME), which another
*> procedure call may give another value, are not compared.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-J007.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-CREATES              PIC X.
01  LS-SAME-SCOPE           PIC X.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 3.
01  LS-NUM-TEXT             PIC X(12).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-J007" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > JD-COUNT
        MOVE LS-D TO LS-I
        PERFORM TEST-CREATES
        IF LS-CREATES = "Y"
            PERFORM CHECK-EARLIER
        END-IF
    END-PERFORM
    GOBACK.

*> LS-CREATES = "Y" when DD LS-I creates and catalogs a data set whose
*> name can be compared.
TEST-CREATES.
    MOVE "N" TO LS-CREATES
    IF JD-KIND(LS-I) NOT = "D" OR JD-QUALIFIER(LS-I) NOT = SPACES
       OR JD-STEP(LS-I) = 0 OR JD-NORMAL(LS-I) NOT = "CATLG"
        EXIT PARAGRAPH
    END-IF
    IF JD-DISP(LS-I) NOT = "NEW" AND JD-DISP(LS-I) NOT = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-N
    INSPECT JD-DSN(LS-I) TALLYING LS-N FOR ALL "&" ALL "("
    IF LS-N = 0
        MOVE "Y" TO LS-CREATES
    END-IF.

*> The last earlier DD of the job or procedure that creates the same
*> data set, unless one after it deletes it.
CHECK-EARLIER.
    MOVE 0 TO LS-FIRST
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E >= LS-D
        IF JD-DSN(LS-E) = JD-DSN(LS-D) AND JD-STEP(LS-E) > 0
            PERFORM TEST-SAME-SCOPE
            IF LS-SAME-SCOPE = "Y"
                MOVE LS-E TO LS-I
                PERFORM TEST-CREATES
                EVALUATE TRUE
                    WHEN LS-CREATES = "Y"
                        MOVE LS-E TO LS-FIRST
                    WHEN JD-NORMAL(LS-E) = "DELETE"
                    WHEN JD-NORMAL(LS-E) = "UNCATLG"
                        MOVE 0 TO LS-FIRST
                END-EVALUATE
            END-IF
        END-IF
    END-PERFORM
    IF LS-FIRST > 0
        PERFORM REPORT-TWICE
    END-IF.

*> LS-SAME-SCOPE = "Y" when DDs LS-E and LS-D are in steps of the same
*> job, or of the same procedure.
TEST-SAME-SCOPE.
    MOVE "N" TO LS-SAME-SCOPE
    IF (JS-JOB(JD-STEP(LS-E)) > 0
        AND JS-JOB(JD-STEP(LS-E)) = JS-JOB(JD-STEP(LS-D)))
       OR (JS-PROC(JD-STEP(LS-E)) > 0
           AND JS-PROC(JD-STEP(LS-E)) = JS-PROC(JD-STEP(LS-D)))
        MOVE "Y" TO LS-SAME-SCOPE
    END-IF.

REPORT-TWICE.
    MOVE JD-LINE(LS-FIRST) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    MOVE SPACES TO LS-MESSAGE
    STRING JD-DSN(LS-D) DELIMITED BY SPACE
           " is created and cataloged again; the DD on line "
           DELIMITED BY SIZE
           LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
           " already did, and nothing deletes it in between"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        JD-FILE-ID(LS-D) JD-LINE(LS-D) LS-COLUMN LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-J007.
