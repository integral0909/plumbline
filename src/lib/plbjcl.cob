*> ---------------------------------------------------------------
*> plbjcl: reading JCL.
*>
*> A JCL file is a list of 80-column records. A statement starts with
*> // in columns 1 and 2: an optional name from column 3, an
*> operation (JOB, EXEC, DD, PROC, PEND, ...), and operands separated
*> by commas, up to the first blank outside quotes; what follows is a
*> comment, as are columns 72 to 80. A statement continues on the
*> next // line, from column 4 to 16, when its operands end with a
*> comma, or when a quoted string reaches column 71 (it goes on in
*> column 16). //* lines are comments, /* ends in-stream data, and
*> // alone ends the job.
*>
*> DD * and DD DATA are followed by in-stream data: lines up to /*, or
*> up to the DLM= delimiter. For DD *, a // line also ends the data.
*>
*> Only what the analysis needs is kept (see plbjcl.cpy): jobs,
*> procedure definitions, steps and what they run, and DD names with
*> what they define. Other statements (SET, IF, INCLUDE, JCLLIB,
*> OUTPUT) are read and passed over.
*> ---------------------------------------------------------------

*> PLB-JCL-INIT: an empty model.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-JCL-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbjclc.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-JCL.
    MOVE 0 TO JJ-COUNT JP-COUNT JS-COUNT JD-COUNT JI-COUNT JR-COUNT
    GOBACK.
END PROGRAM PLB-JCL-INIT.

*> PLB-JCL-READ: add the JCL of file PATH, as file FILE-ID of the
*> run, to the model. STATUS receives 0, or 1 when the file cannot be
*> opened or read.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-JCL-READ.
ENVIRONMENT DIVISION.
CONFIGURATION SECTION.
SPECIAL-NAMES.
    *> The characters of a name in an IF condition: STEP.PROCSTEP.RC.
    CLASS IF-NAME-CHAR IS "A" THRU "Z" "0" THRU "9" "@" "#" "$" ".".
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT JCL-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  JCL-FILE.
01  JCL-RECORD              PIC X(256).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(1024).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
    88  WS-AT-END                 VALUE "10".
LOCAL-STORAGE SECTION.
01  LS-DONE                 PIC X VALUE "N".
01  LS-LINE-NO              PIC 9(9) COMP-5 VALUE 0.
01  LS-TEXT                 PIC X(80).
01  LS-P                    PIC 9(4) COMP-5.
01  LS-Q                    PIC 9(4) COMP-5.
*> In-stream data, and the delimiter that ends it (spaces: /* or //).
01  LS-IN-DATA              PIC X VALUE "N".
01  LS-DLM                  PIC XX VALUE SPACES.
*> Where the reading is: job, procedure definition, step.
01  LS-JOB                  PIC 9(9) COMP-5 VALUE 0.
01  LS-PROC                 PIC 9(9) COMP-5 VALUE 0.
01  LS-STEP                 PIC 9(9) COMP-5 VALUE 0.
*> The statement being read.
01  ST-ACTIVE               PIC X VALUE "N".
01  ST-CONTINUES            PIC X VALUE "N".
01  ST-IN-QUOTE             PIC X VALUE "N".
01  ST-LINE                 PIC 9(9) COMP-5.
01  ST-NAME                 PIC X(17).
01  ST-OP                   PIC X(8).
01  ST-OPERANDS             PIC X(4000).
01  ST-LEN                  PIC 9(4) COMP-5.
*> One operand: KEY=VALUE, or a positional VALUE.
01  OP-START                PIC 9(4) COMP-5.
01  OP-I                    PIC 9(4) COMP-5.
01  OP-DEPTH                PIC 9(4) COMP-5.
01  OP-QUOTE                PIC X.
01  OP-ITEM                 PIC X(4000).
01  OP-KEY                  PIC X(8).
01  OP-VALUE                PIC X(4000).
01  OP-POSITION             PIC 9(4) COMP-5.
01  OP-EQ                   PIC 9(4) COMP-5.
01  OP-ITEM-LEN             PIC 9(4) COMP-5.
*> The parameters of DCB=( ).
01  LS-DCB-START            PIC 9(4) COMP-5.
01  LS-DCB-ITEM             PIC X(80).
01  LS-DCB-KEY              PIC X(8).
01  LS-DCB-VALUE            PIC X(40).
01  LS-DCB-LEN              PIC 9(9) COMP-5.
01  LS-DOT                  PIC 9(4) COMP-5.
01  LS-PARM                 PIC X(100) VALUE SPACES.
01  LS-FIELD-1              PIC X(100).
01  LS-FIELD-2              PIC X(100).
01  LS-FIELD-3              PIC X(100).
*> The DD whose in-stream data is being read.
01  LS-DATA-DD              PIC X(17) VALUE SPACES.
01  LS-RUN-AT               PIC 9(4) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
*> Backward references: the first of this file, the one resolved, its
*> parts, and the step and DD it names.
01  LS-FIRST-REFERENCE      PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-REF-STEP             PIC 9(9) COMP-5.
01  LS-PART-1               PIC X(8).
01  LS-PART-2               PIC X(8).
01  LS-PART-COUNT           PIC 9(4) COMP-5.
01  LS-REF-KEY              PIC X(5).
01  LS-REF-TEXT             PIC X(26).
LINKAGE SECTION.
COPY "plbjclc.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-FILE-ID              PIC 9(4) COMP-5.
COPY "plbjcl.cpy".
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-FILE-ID PLB-JCL LK-STATUS.
    MOVE 0 TO LK-STATUS
    COMPUTE LS-FIRST-REFERENCE = JR-COUNT + 1
    MOVE LK-PATH TO WS-PATH
    OPEN INPUT JCL-FILE
    IF WS-STATUS NOT = "00"
        MOVE 1 TO LK-STATUS
        GOBACK
    END-IF
    PERFORM UNTIL LS-DONE = "Y"
        MOVE SPACES TO JCL-RECORD
        READ JCL-FILE
        EVALUATE TRUE
            WHEN WS-READ-OK
                ADD 1 TO LS-LINE-NO
                MOVE JCL-RECORD(1:80) TO LS-TEXT
                PERFORM READ-LINE
            WHEN WS-AT-END
                MOVE "Y" TO LS-DONE
            WHEN OTHER
                MOVE 1 TO LK-STATUS
                MOVE "Y" TO LS-DONE
        END-EVALUATE
    END-PERFORM
    CLOSE JCL-FILE
    IF ST-ACTIVE = "Y"
        PERFORM FINISH-STATEMENT
    END-IF
    PERFORM VARYING LS-R FROM LS-FIRST-REFERENCE BY 1
            UNTIL LS-R > JR-COUNT
        PERFORM RESOLVE-REFERENCE
    END-PERFORM
    GOBACK.

READ-LINE.
    *> Columns 72 to 80: continuation mark and sequence number.
    MOVE SPACES TO LS-TEXT(72:)
    IF LS-IN-DATA = "Y"
        IF LS-DLM NOT = SPACES
            IF LS-TEXT(1:2) = LS-DLM
                MOVE "N" TO LS-IN-DATA
            ELSE
                PERFORM READ-DATA-LINE
            END-IF
            EXIT PARAGRAPH
        END-IF
        IF LS-TEXT(1:2) = "/*"
            MOVE "N" TO LS-IN-DATA
            EXIT PARAGRAPH
        END-IF
        IF LS-TEXT(1:2) NOT = "//"
            PERFORM READ-DATA-LINE
            EXIT PARAGRAPH
        END-IF
        MOVE "N" TO LS-IN-DATA
    END-IF
    IF LS-TEXT(1:3) = "//*" OR LS-TEXT(1:2) NOT = "//"
        EXIT PARAGRAPH
    END-IF
    *> A continuation: no name, the operands go on.
    IF ST-ACTIVE = "Y" AND ST-CONTINUES = "Y" AND LS-TEXT(3:1) = SPACE
       AND ST-OP = "IF"
        MOVE 3 TO LS-P
        PERFORM SKIP-BLANKS
        PERFORM READ-CONDITION
        IF ST-CONTINUES = "N"
            PERFORM FINISH-STATEMENT
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF ST-ACTIVE = "Y" AND ST-CONTINUES = "Y" AND LS-TEXT(3:1) = SPACE
        IF ST-IN-QUOTE = "Y"
            MOVE 16 TO LS-P
        ELSE
            MOVE 3 TO LS-P
            PERFORM SKIP-BLANKS
        END-IF
        PERFORM READ-OPERANDS
        IF ST-CONTINUES = "N"
            PERFORM FINISH-STATEMENT
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF ST-ACTIVE = "Y"
        PERFORM FINISH-STATEMENT
    END-IF
    *> // alone: the end of the job.
    IF LS-TEXT(3:) = SPACES
        MOVE 0 TO LS-JOB LS-STEP
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO ST-ACTIVE
    MOVE "N" TO ST-CONTINUES ST-IN-QUOTE
    MOVE LS-LINE-NO TO ST-LINE
    MOVE SPACES TO ST-NAME ST-OP ST-OPERANDS
    MOVE 0 TO ST-LEN
    MOVE 3 TO LS-P
    IF LS-TEXT(3:1) NOT = SPACE
        PERFORM READ-WORD
        MOVE FUNCTION UPPER-CASE(LS-TEXT(LS-Q:LS-P - LS-Q)) TO ST-NAME
    END-IF
    PERFORM SKIP-BLANKS
    IF LS-P > 71
        PERFORM FINISH-STATEMENT
        EXIT PARAGRAPH
    END-IF
    PERFORM READ-WORD
    MOVE FUNCTION UPPER-CASE(LS-TEXT(LS-Q:LS-P - LS-Q)) TO ST-OP
    PERFORM SKIP-BLANKS
    IF ST-OP = "IF"
        PERFORM READ-CONDITION
    ELSE
        IF LS-P <= 71
            PERFORM READ-OPERANDS
        END-IF
    END-IF
    IF ST-CONTINUES = "N"
        PERFORM FINISH-STATEMENT
    END-IF.

*> A line of in-stream data. In the SYSTSIN input of the TSO batch
*> program, RUN PROGRAM(name) names the DB2 program the step runs.
READ-DATA-LINE.
    IF LS-STEP = 0 OR LS-DATA-DD NOT = "SYSTSIN"
        EXIT PARAGRAPH
    END-IF
    IF JS-TARGET(LS-STEP)(1:6) NOT = "IKJEFT"
        EXIT PARAGRAPH
    END-IF
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    MOVE 0 TO LS-RUN-AT
    INSPECT LS-TEXT TALLYING LS-RUN-AT FOR CHARACTERS BEFORE "PROGRAM("
    IF LS-RUN-AT < 70
        MOVE SPACES TO LS-FIELD-1
        UNSTRING LS-TEXT(LS-RUN-AT + 9:) DELIMITED BY ")"
            INTO LS-FIELD-1
        MOVE FUNCTION TRIM(LS-FIELD-1) TO JS-INNER(LS-STEP)
    END-IF.

*> The condition of an IF, blanks and all, from LS-P to column 71; it
*> goes on until a line has THEN.
READ-CONDITION.
    IF LS-P <= 71 AND ST-LEN < 3900
        MOVE FUNCTION UPPER-CASE(LS-TEXT(LS-P:72 - LS-P))
            TO ST-OPERANDS(ST-LEN + 1:72 - LS-P)
        COMPUTE ST-LEN = ST-LEN + 72 - LS-P + 1
    END-IF
    MOVE 0 TO LS-D
    INSPECT ST-OPERANDS(1:ST-LEN) TALLYING LS-D FOR ALL "THEN"
    IF LS-D > 0
        MOVE "N" TO ST-CONTINUES
    ELSE
        MOVE "Y" TO ST-CONTINUES
    END-IF.

SKIP-BLANKS.
    PERFORM UNTIL LS-P > 71
        IF LS-TEXT(LS-P:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-P
    END-PERFORM.

*> The word at LS-P: LS-Q is its start, LS-P the blank after it.
READ-WORD.
    MOVE LS-P TO LS-Q
    PERFORM UNTIL LS-P > 71
        IF LS-TEXT(LS-P:1) = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-P
    END-PERFORM
    IF LS-P - LS-Q > 17
        COMPUTE LS-P = LS-Q + 17
    END-IF.

*> The operand text from LS-P, to the first blank outside quotes or
*> column 71, appended to ST-OPERANDS. ST-CONTINUES says whether the
*> next line goes on with it.
READ-OPERANDS.
    PERFORM UNTIL LS-P > 71
        IF LS-TEXT(LS-P:1) = SPACE AND ST-IN-QUOTE = "N"
            EXIT PERFORM
        END-IF
        IF LS-TEXT(LS-P:1) = "'"
            IF ST-IN-QUOTE = "Y"
                MOVE "N" TO ST-IN-QUOTE
            ELSE
                MOVE "Y" TO ST-IN-QUOTE
            END-IF
        END-IF
        IF ST-LEN < 4000
            ADD 1 TO ST-LEN
            MOVE LS-TEXT(LS-P:1) TO ST-OPERANDS(ST-LEN:1)
        END-IF
        ADD 1 TO LS-P
    END-PERFORM
    MOVE "N" TO ST-CONTINUES
    IF ST-IN-QUOTE = "Y"
        MOVE "Y" TO ST-CONTINUES
    ELSE
        IF ST-LEN > 0
            IF ST-OPERANDS(ST-LEN:1) = ","
                MOVE "Y" TO ST-CONTINUES
            END-IF
        END-IF
    END-IF.

FINISH-STATEMENT.
    MOVE "N" TO ST-ACTIVE ST-CONTINUES
    EVALUATE ST-OP
        WHEN "JOB"
            PERFORM ADD-JOB
        WHEN "PROC"
            PERFORM ADD-PROC
        WHEN "PEND"
            MOVE 0 TO LS-PROC LS-STEP
        WHEN "EXEC"
            PERFORM ADD-STEP
        WHEN "DD"
            PERFORM ADD-DD
        WHEN "IF"
            PERFORM ADD-IF
    END-EVALUATE.

*> Each STEP.RC, STEP.ABEND, STEP.ABENDCC, or STEP.RUN of the
*> condition (STEP.PROCSTEP.RC too): an entry for STEP. RC alone
*> tests the steps before, and names none.
ADD-IF.
    IF LS-JOB = 0 AND LS-PROC = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-P
    PERFORM UNTIL LS-P > ST-LEN
        IF ST-OPERANDS(LS-P:1) IS IF-NAME-CHAR
            MOVE LS-P TO LS-Q
            PERFORM UNTIL LS-P > ST-LEN
                IF ST-OPERANDS(LS-P:1) IS NOT IF-NAME-CHAR
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-P
            END-PERFORM
            PERFORM IF-WORD
        ELSE
            ADD 1 TO LS-P
        END-IF
    END-PERFORM.

*> The word from LS-Q to LS-P - 1.
IF-WORD.
    MOVE SPACES TO LS-FIELD-1 LS-FIELD-2 LS-FIELD-3
    UNSTRING ST-OPERANDS(LS-Q:LS-P - LS-Q) DELIMITED BY "."
        INTO LS-FIELD-1 LS-FIELD-2 LS-FIELD-3
    IF LS-FIELD-2 = SPACES
        EXIT PARAGRAPH
    END-IF
    IF LS-FIELD-3 NOT = SPACES
        MOVE LS-FIELD-3 TO LS-FIELD-2
    END-IF
    IF LS-FIELD-2 NOT = "RC" AND LS-FIELD-2 NOT = "ABEND"
       AND LS-FIELD-2 NOT = "ABENDCC" AND LS-FIELD-2 NOT = "RUN"
        EXIT PARAGRAPH
    END-IF
    IF JI-COUNT >= JI-MAX OR LS-FIELD-1(9:) NOT = SPACES
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JI-COUNT
    IF LS-PROC > 0
        MOVE 0 TO JI-JOB(JI-COUNT)
    ELSE
        MOVE LS-JOB TO JI-JOB(JI-COUNT)
    END-IF
    MOVE LS-PROC TO JI-PROC(JI-COUNT)
    MOVE JS-COUNT TO JI-BEFORE(JI-COUNT)
    MOVE LS-FIELD-1 TO JI-STEP(JI-COUNT)
    MOVE LK-FILE-ID TO JI-FILE-ID(JI-COUNT)
    MOVE ST-LINE TO JI-LINE(JI-COUNT).

ADD-JOB.
    MOVE 0 TO LS-PROC LS-STEP
    IF JJ-COUNT >= JJ-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JJ-COUNT
    MOVE JJ-COUNT TO LS-JOB
    MOVE ST-NAME TO JJ-NAME(LS-JOB)
    MOVE LK-FILE-ID TO JJ-FILE-ID(LS-JOB)
    MOVE ST-LINE TO JJ-LINE(LS-JOB).

ADD-PROC.
    MOVE 0 TO LS-STEP
    IF JP-COUNT >= JP-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JP-COUNT
    MOVE JP-COUNT TO LS-PROC
    MOVE ST-NAME TO JP-NAME(LS-PROC)
    MOVE LK-FILE-ID TO JP-FILE-ID(LS-PROC)
    MOVE ST-LINE TO JP-LINE(LS-PROC)
    IF LS-JOB > 0
        MOVE "Y" TO JP-INSTREAM(LS-PROC)
    ELSE
        MOVE "N" TO JP-INSTREAM(LS-PROC)
    END-IF.

*> EXEC PGM=name, EXEC PROC=name, or EXEC name (a procedure).
ADD-STEP.
    MOVE 0 TO LS-STEP
    IF JS-COUNT >= JS-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JS-COUNT
    MOVE JS-COUNT TO LS-STEP
    IF LS-PROC > 0
        MOVE 0 TO JS-JOB(LS-STEP)
    ELSE
        MOVE LS-JOB TO JS-JOB(LS-STEP)
    END-IF
    MOVE LS-PROC TO JS-PROC(LS-STEP)
    MOVE ST-NAME TO JS-NAME(LS-STEP)
    MOVE SPACE TO JS-KIND(LS-STEP)
    MOVE SPACES TO JS-TARGET(LS-STEP) JS-INNER(LS-STEP) JS-PSB(LS-STEP)
        JS-COND(LS-STEP)
    MOVE LK-FILE-ID TO JS-FILE-ID(LS-STEP)
    MOVE ST-LINE TO JS-LINE(LS-STEP)
    MOVE 0 TO JS-DD-FIRST(LS-STEP) JS-DD-COUNT(LS-STEP)
    MOVE 1 TO OP-START
    MOVE 0 TO OP-POSITION
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE TRUE
            WHEN OP-KEY = "PGM"
                MOVE "P" TO JS-KIND(LS-STEP)
                MOVE OP-VALUE TO JS-TARGET(LS-STEP)
            WHEN OP-KEY = "PROC"
                MOVE "R" TO JS-KIND(LS-STEP)
                MOVE OP-VALUE TO JS-TARGET(LS-STEP)
            WHEN OP-KEY = SPACES AND OP-POSITION = 1
                MOVE "R" TO JS-KIND(LS-STEP)
                MOVE OP-VALUE TO JS-TARGET(LS-STEP)
            WHEN OP-KEY = "PARM"
                MOVE OP-VALUE TO LS-PARM
            WHEN OP-KEY = "COND"
                MOVE OP-VALUE TO JS-COND(LS-STEP)
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM
    *> DFSRRC00 PARM='BMP,PROGRAM,PSB' (or DLI, BMH, ...): the program
    *> it runs, and the PSB.
    IF JS-TARGET(LS-STEP) = "DFSRRC00" AND LS-PARM NOT = SPACES
        INSPECT LS-PARM REPLACING ALL "'" BY SPACE ALL "(" BY SPACE
            ALL ")" BY SPACE
        MOVE SPACES TO LS-FIELD-1 LS-FIELD-2 LS-FIELD-3
        UNSTRING FUNCTION TRIM(LS-PARM) DELIMITED BY ","
            INTO LS-FIELD-1 LS-FIELD-2 LS-FIELD-3
        MOVE FUNCTION TRIM(LS-FIELD-2) TO JS-INNER(LS-STEP)
        MOVE FUNCTION TRIM(LS-FIELD-3) TO JS-PSB(LS-STEP)
    END-IF
    MOVE SPACES TO LS-PARM.

*> A DD of the current step. A DD without a name continues the one
*> before it (a concatenation) and gets its name; DDs before the first
*> step (JOBLIB, JOBCAT) belong to no step.
ADD-DD.
    IF LS-STEP = 0 OR JD-COUNT >= JD-MAX
        PERFORM SCAN-DD-DATA
        EXIT PARAGRAPH
    END-IF
    IF ST-NAME = SPACES AND JS-DD-COUNT(LS-STEP) = 0
        PERFORM SCAN-DD-DATA
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JD-COUNT
    MOVE JD-COUNT TO LS-D
    MOVE LS-STEP TO JD-STEP(LS-D)
    IF JS-DD-COUNT(LS-STEP) = 0
        MOVE LS-D TO JS-DD-FIRST(LS-STEP)
    END-IF
    ADD 1 TO JS-DD-COUNT(LS-STEP)
    MOVE SPACES TO JD-QUALIFIER(LS-D) JD-NAME(LS-D) JD-DSN(LS-D)
        JD-DISP(LS-D) JD-NORMAL(LS-D)
    MOVE "N" TO JD-CONCAT(LS-D)
    MOVE 0 TO JD-LRECL(LS-D)
    MOVE SPACES TO JD-RECFM(LS-D)
    MOVE 0 TO LS-DOT
    INSPECT ST-NAME TALLYING LS-DOT FOR CHARACTERS BEFORE "."
    EVALUATE TRUE
        WHEN ST-NAME = SPACES
            MOVE "Y" TO JD-CONCAT(LS-D)
            MOVE JD-NAME(LS-D - 1) TO JD-NAME(LS-D)
            MOVE JD-QUALIFIER(LS-D - 1) TO JD-QUALIFIER(LS-D)
        WHEN LS-DOT < 17 AND ST-NAME(LS-DOT + 1:1) = "."
            MOVE ST-NAME(1:LS-DOT) TO JD-QUALIFIER(LS-D)
            MOVE ST-NAME(LS-DOT + 2:) TO JD-NAME(LS-D)
        WHEN OTHER
            MOVE ST-NAME TO JD-NAME(LS-D)
    END-EVALUATE
    MOVE "O" TO JD-KIND(LS-D)
    MOVE LK-FILE-ID TO JD-FILE-ID(LS-D)
    MOVE ST-LINE TO JD-LINE(LS-D)
    MOVE 1 TO OP-START
    MOVE 0 TO OP-POSITION
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE TRUE
            WHEN OP-KEY = "DSN" OR OP-KEY = "DSNAME"
                MOVE "D" TO JD-KIND(LS-D)
                MOVE OP-VALUE TO JD-DSN(LS-D)
                IF OP-VALUE(1:2) = "*."
                    MOVE "DSN" TO LS-REF-KEY
                    MOVE OP-VALUE(3:) TO LS-REF-TEXT
                    PERFORM NOTE-REFERENCE
                END-IF
            WHEN (OP-KEY = "DCB" OR OP-KEY = "REFDD")
                 AND OP-VALUE(1:2) = "*."
                MOVE OP-KEY TO LS-REF-KEY
                MOVE OP-VALUE(3:) TO LS-REF-TEXT
                PERFORM NOTE-REFERENCE
            WHEN OP-KEY = "VOL" OR OP-KEY = "VOLUME"
                PERFORM VOLUME-REFERENCE
            WHEN OP-KEY = "SYSOUT"
                MOVE "S" TO JD-KIND(LS-D)
            WHEN OP-KEY = "DISP"
                PERFORM READ-DISP
            WHEN OP-KEY = "LRECL" OR OP-KEY = "RECFM"
                MOVE OP-KEY TO LS-DCB-KEY
                MOVE OP-VALUE TO LS-DCB-VALUE
                PERFORM DCB-PARAMETER
            WHEN OP-KEY = "DCB" AND OP-VALUE(1:1) = "("
                PERFORM READ-DCB
            WHEN OP-KEY = SPACES AND OP-VALUE = "DUMMY"
                MOVE "M" TO JD-KIND(LS-D)
            WHEN OP-KEY = SPACES
                 AND (OP-VALUE = "*" OR OP-VALUE = "DATA")
                MOVE "I" TO JD-KIND(LS-D)
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM
    PERFORM SCAN-DD-DATA.

*> VOL=REF=*.STEP.DD, also inside VOL=(,,,REF=*.STEP.DD).
VOLUME-REFERENCE.
    MOVE 0 TO LS-E
    INSPECT OP-VALUE TALLYING LS-E FOR CHARACTERS BEFORE "REF=*."
    IF LS-E < 3990
        MOVE "VOL" TO LS-REF-KEY
        MOVE SPACES TO LS-REF-TEXT
        UNSTRING OP-VALUE(LS-E + 7:) DELIMITED BY "," OR ")"
            INTO LS-REF-TEXT
        PERFORM NOTE-REFERENCE
    END-IF.

NOTE-REFERENCE.
    IF JR-COUNT >= JR-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JR-COUNT
    MOVE LS-D TO JR-DD(JR-COUNT)
    MOVE LS-REF-KEY TO JR-KEY(JR-COUNT)
    MOVE LS-REF-TEXT TO JR-TEXT(JR-COUNT)
    MOVE "Y" TO JR-STATE(JR-COUNT).

*> Backward reference LS-R: *.DD names an earlier DD of the same step;
*> *.STEP.DD a DD of an earlier step of the same job or procedure;
*> *.STEP.PROCSTEP.DD a DD in the procedure an earlier step runs, which
*> is not followed, so only the step is checked.
RESOLVE-REFERENCE.
    MOVE SPACES TO LS-PART-1 LS-PART-2
    MOVE 1 TO LS-PART-COUNT
    INSPECT JR-TEXT(LS-R) TALLYING LS-PART-COUNT FOR ALL "."
    UNSTRING JR-TEXT(LS-R) DELIMITED BY "."
        INTO LS-PART-1 LS-PART-2
    END-UNSTRING
    MOVE JD-STEP(JR-DD(LS-R)) TO LS-STEP
    EVALUATE LS-PART-COUNT
        WHEN 1
            MOVE LS-STEP TO LS-REF-STEP
            MOVE LS-PART-1 TO LS-PART-2
            PERFORM FIND-REFERENCED-DD
        WHEN 2
        WHEN 3
            MOVE 0 TO LS-REF-STEP
            PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E >= LS-STEP
                IF JS-NAME(LS-E) = LS-PART-1
                   AND ((JS-JOB(LS-STEP) > 0
                         AND JS-JOB(LS-E) = JS-JOB(LS-STEP))
                        OR (JS-PROC(LS-STEP) > 0
                            AND JS-PROC(LS-E) = JS-PROC(LS-STEP)))
                    MOVE LS-E TO LS-REF-STEP
                END-IF
            END-PERFORM
            IF LS-REF-STEP = 0
                MOVE "S" TO JR-STATE(LS-R)
            ELSE
                IF LS-PART-COUNT = 2
                    PERFORM FIND-REFERENCED-DD
                END-IF
            END-IF
    END-EVALUATE.

*> DD LS-PART-2 of step LS-REF-STEP, before DD JR-DD(LS-R): its data
*> set name goes to a DSN= that names it.
FIND-REFERENCED-DD.
    MOVE 0 TO LS-E
    PERFORM VARYING LS-D FROM JS-DD-FIRST(LS-REF-STEP) BY 1
            UNTIL LS-D >= JS-DD-FIRST(LS-REF-STEP)
                         + JS-DD-COUNT(LS-REF-STEP)
               OR LS-D >= JR-DD(LS-R)
        IF JD-NAME(LS-D) = LS-PART-2 AND JD-CONCAT(LS-D) = "N"
            MOVE LS-D TO LS-E
        END-IF
    END-PERFORM
    IF LS-E = 0 OR JS-DD-COUNT(LS-REF-STEP) = 0
        MOVE "D" TO JR-STATE(LS-R)
        EXIT PARAGRAPH
    END-IF
    IF JR-KEY(LS-R) = "DSN" AND JD-DSN(LS-E)(1:2) NOT = "*."
        MOVE JD-DSN(LS-E) TO JD-DSN(JR-DD(LS-R))
    END-IF.

*> DD * and DD DATA start in-stream data, ended by DLM= if given.
SCAN-DD-DATA.
    MOVE SPACES TO LS-DLM
    MOVE 1 TO OP-START
    MOVE 0 TO OP-POSITION
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        IF OP-KEY = SPACES AND (OP-VALUE = "*" OR OP-VALUE = "DATA")
            MOVE "Y" TO LS-IN-DATA
            MOVE ST-NAME TO LS-DATA-DD
        END-IF
        IF OP-KEY = "DLM"
            MOVE OP-VALUE(1:2) TO LS-DLM
            IF OP-VALUE(1:1) = "'"
                MOVE OP-VALUE(2:2) TO LS-DLM
            END-IF
        END-IF
        PERFORM NEXT-OPERAND
    END-PERFORM
    IF LS-IN-DATA = "N"
        MOVE SPACES TO LS-DLM
    END-IF.

*> DISP=SHR or DISP=(NEW,CATLG,DELETE): the first two subparameters.
*> DCB=(RECFM=FB,LRECL=80,BLKSIZE=0): each KEY=VALUE of the list.
READ-DCB.
    MOVE 2 TO LS-DCB-START
    PERFORM UNTIL LS-DCB-START > 4000
        MOVE SPACES TO LS-DCB-ITEM
        UNSTRING OP-VALUE DELIMITED BY "," OR ")"
            INTO LS-DCB-ITEM WITH POINTER LS-DCB-START
        END-UNSTRING
        IF LS-DCB-ITEM = SPACES
            EXIT PERFORM
        END-IF
        MOVE SPACES TO LS-DCB-KEY LS-DCB-VALUE
        UNSTRING LS-DCB-ITEM DELIMITED BY "="
            INTO LS-DCB-KEY LS-DCB-VALUE
        END-UNSTRING
        PERFORM DCB-PARAMETER
    END-PERFORM.

*> LRECL=n (a number) and RECFM=x, of the DD or of its DCB.
DCB-PARAMETER.
    EVALUATE LS-DCB-KEY
        WHEN "LRECL"
            MOVE FUNCTION TRIM(LS-DCB-VALUE) TO LS-DCB-VALUE
            CALL "PLB-STR-LENGTH" USING LS-DCB-VALUE LS-DCB-LEN
            IF LS-DCB-LEN > 0 AND LS-DCB-LEN < 10
                IF LS-DCB-VALUE(1:LS-DCB-LEN) IS NUMERIC
                    COMPUTE JD-LRECL(LS-D) =
                        FUNCTION NUMVAL(LS-DCB-VALUE(1:LS-DCB-LEN))
                END-IF
            END-IF
        WHEN "RECFM"
            MOVE FUNCTION TRIM(LS-DCB-VALUE) TO JD-RECFM(LS-D)
    END-EVALUATE.

READ-DISP.
    IF OP-VALUE(1:1) = "("
        UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
            INTO JD-DISP(LS-D) JD-NORMAL(LS-D)
    ELSE
        MOVE OP-VALUE TO JD-DISP(LS-D)
    END-IF.

*> The next operand of ST-OPERANDS from OP-START: OP-ITEM (length
*> OP-ITEM-LEN, 0 at the end), split into OP-KEY and OP-VALUE at an
*> = outside parentheses and quotes; OP-POSITION counts operands.
*> Commas inside parentheses or quotes do not separate operands.
NEXT-OPERAND.
    MOVE 0 TO OP-ITEM-LEN OP-DEPTH OP-EQ
    MOVE "N" TO OP-QUOTE
    MOVE SPACES TO OP-ITEM OP-KEY OP-VALUE
    IF OP-START > ST-LEN
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING OP-I FROM OP-START BY 1 UNTIL OP-I > ST-LEN
        EVALUATE TRUE
            WHEN ST-OPERANDS(OP-I:1) = "'"
                IF OP-QUOTE = "Y"
                    MOVE "N" TO OP-QUOTE
                ELSE
                    MOVE "Y" TO OP-QUOTE
                END-IF
            WHEN OP-QUOTE = "Y"
                CONTINUE
            WHEN ST-OPERANDS(OP-I:1) = "("
                ADD 1 TO OP-DEPTH
            WHEN ST-OPERANDS(OP-I:1) = ")" AND OP-DEPTH > 0
                SUBTRACT 1 FROM OP-DEPTH
            WHEN ST-OPERANDS(OP-I:1) = "," AND OP-DEPTH = 0
                EXIT PERFORM
            WHEN ST-OPERANDS(OP-I:1) = "=" AND OP-DEPTH = 0
                 AND OP-EQ = 0
                COMPUTE OP-EQ = OP-I - OP-START + 1
        END-EVALUATE
    END-PERFORM
    COMPUTE OP-ITEM-LEN = OP-I - OP-START
    IF OP-ITEM-LEN > 0
        MOVE ST-OPERANDS(OP-START:OP-ITEM-LEN) TO OP-ITEM
    END-IF
    COMPUTE OP-START = OP-I + 1
    ADD 1 TO OP-POSITION
    *> An empty positional operand (EXEC ,X) still counts.
    IF OP-ITEM-LEN = 0
        IF OP-START <= ST-LEN + 1 AND OP-I <= ST-LEN
            MOVE 1 TO OP-ITEM-LEN
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF OP-EQ > 1 AND OP-EQ <= 9
        MOVE FUNCTION UPPER-CASE(OP-ITEM(1:OP-EQ - 1)) TO OP-KEY
        IF OP-EQ < OP-ITEM-LEN
            MOVE OP-ITEM(OP-EQ + 1:OP-ITEM-LEN - OP-EQ) TO OP-VALUE
        END-IF
    ELSE
        MOVE OP-ITEM(1:OP-ITEM-LEN) TO OP-VALUE
    END-IF
    MOVE FUNCTION UPPER-CASE(OP-VALUE) TO OP-VALUE.
END PROGRAM PLB-JCL-READ.
