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
LOCAL-STORAGE SECTION.
01  LS-RULE-MISSING         PIC 9(4) COMP-5.
01  LS-RULE-UNUSED          PIC 9(4) COMP-5.
01  LS-RULE-UNKNOWN         PIC 9(4) COMP-5.
01  LS-RULE-UNREADABLE      PIC 9(4) COMP-5.
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
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) = "P"
            PERFORM CHECK-STEP
        END-IF
    END-PERFORM
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
