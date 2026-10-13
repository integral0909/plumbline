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
    MOVE 0 TO JN-COUNT JO-COUNT
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
01  LS-NOT-WITH-SYSOUT      PIC X(8).
01  LS-TIME-OF              PIC X.
01  LS-EXPDT                PIC X(20).
01  LS-SP-I                 PIC 9(4) COMP-5.
01  LS-SP-PART              PIC 9(4) COMP-5.
01  LS-SP-DEPTH             PIC 9(4) COMP-5.
01  LS-SP-LEN               PIC 9(4) COMP-5.
01  LS-SP-TEXT              PIC X(20).
01  LS-SP-Q1                PIC X(20).
01  LS-SP-Q2                PIC X(20).
01  LS-SP-Q3                PIC X(20).
01  LS-SPACE-ITEM           PIC X(20).
01  LS-RETPD                PIC X(20).
01  LS-YEAR                 PIC 9(4) COMP-5.
01  LS-DAY                  PIC 9(4) COMP-5.
01  LS-YEAR-DAYS            PIC 9(4) COMP-5.
01  LS-CLASS-TEXT           PIC X(40).
01  LS-CLASS-OK             PIC X.
01  LS-CLASS-QUOTED         PIC X(39).
01  LS-TIME-BAD             PIC X(20).
01  LS-TIME-MIN             PIC X(20).
01  LS-TIME-SEC             PIC X(20).
01  LS-TIME-PART            PIC X(20).
01  LS-TIME-N               PIC 9(4) COMP-5.
01  LS-TIME-MAX             PIC 9(9) COMP-5.
01  LS-PATH-I               PIC 9(4) COMP-5.
01  LS-PATH-START           PIC 9(4) COMP-5.
01  LS-PATH-END             PIC 9(4) COMP-5.
01  LS-MEMBER               PIC X(31).
01  LS-GEN                  PIC X(10).
01  LS-GEN-LEN              PIC 9(4) COMP-5.
01  LS-ONLY-WITH-SYSOUT     PIC X(8).
01  LS-OUTPUT-CODED         PIC X.
01  LS-PRE-DD               PIC X(17).
01  LS-IN-DCB               PIC X VALUE "N".
01  LS-LRECL-KW             PIC X.
01  LS-LRECL-DCB            PIC X.
01  LS-RECFM-KW             PIC X.
01  LS-RECFM-DCB            PIC X.
01  LS-DSORG-DCB            PIC X.
01  LS-DSNTYPE-CODED        PIC X.
01  LS-FREE-CLOSE           PIC X.
01  LS-AVGREC-CODED         PIC X.
01  LS-SPACE-UNIT           PIC X.
01  LS-SUBSYS-CODED         PIC X.
01  LS-DCB-VALUE            PIC X(40).
01  LS-DCB-LEN              PIC 9(9) COMP-5.
01  LS-DOT                  PIC 9(4) COMP-5.
01  LS-PARM                 PIC X(100) VALUE SPACES.
*> COUNT-PARM: where the value starts and ends, and its characters.
01  LS-PARM-AT              PIC 9(9) COMP-5.
01  LS-PARM-END             PIC S9(9) COMP-5.
01  LS-PARM-COUNT           PIC 9(9) COMP-5.
*> CHECK-NAME: the name's end and length, where it is, the part, its
*> length so far, and what is wrong with it.
01  LS-NM-END               PIC 9(9) COMP-5.
01  LS-NM-LEN               PIC 9(9) COMP-5.
01  LS-NM-AT                PIC 9(9) COMP-5.
01  LS-NM-CH                PIC X.
01  LS-NM-PART              PIC 9(4) COMP-5.
01  LS-NM-PART-LEN          PIC 9(9) COMP-5.
01  LS-NM-PROBLEM           PIC X.
01  LS-NM-TEXT              PIC X(80).
01  LS-NM-KIND              PIC X.
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
*> Checking the name in DSN=: its length without a member or
*> generation, the position in it, and the current qualifier's number
*> and length.
01  LS-NAME-LEN             PIC 9(4) COMP-5.
01  LS-DSN-I                PIC 9(4) COMP-5.
01  LS-QUAL-NO              PIC 9(4) COMP-5.
01  LS-QUAL-LEN             PIC 9(4) COMP-5.
01  LS-CHAR                 PIC X.
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
        PERFORM CHECK-NAME
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

*> The name from column 3 to the first blank, as the name field.
CHECK-NAME.
    MOVE 3 TO LS-NM-END
    PERFORM UNTIL LS-NM-END > 71
        IF LS-TEXT(LS-NM-END:1) = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-NM-END
    END-PERFORM
    COMPUTE LS-NM-LEN = LS-NM-END - 3
    MOVE SPACES TO LS-NM-TEXT
    MOVE LS-TEXT(3:LS-NM-LEN) TO LS-NM-TEXT
    MOVE "N" TO LS-NM-KIND
    PERFORM CHECK-NAME-TEXT.

*> The program or procedure an EXEC names, OP-VALUE, unless it is a
*> backward reference (PGM=*.STEP.DD).
CHECK-TARGET-NAME.
    IF OP-KEY = SPACES
        MOVE OP-ITEM-LEN TO LS-NM-LEN
    ELSE
        COMPUTE LS-NM-LEN = OP-ITEM-LEN - OP-EQ
    END-IF
    IF LS-NM-LEN < 1 OR LS-NM-LEN > 80 OR OP-VALUE(1:1) = "*"
        EXIT PARAGRAPH
    END-IF
    MOVE OP-VALUE(1:LS-NM-LEN) TO LS-NM-TEXT
    PERFORM CHECK-NAME-TEXT.

*> LS-NM-TEXT(1:LS-NM-LEN), a name of kind LS-NM-KIND: each part (a
*> STEP.DDNAME in the name field has two) 1 to 8 letters, digits, or
*> national characters, not starting with a digit. A wrong one is
*> added to JN-ENTRY.
CHECK-NAME-TEXT.
    MOVE 0 TO LS-D
    INSPECT LS-NM-TEXT(1:LS-NM-LEN) TALLYING LS-D FOR ALL "&"
    IF LS-D > 0 OR JN-COUNT >= JN-MAX
        EXIT PARAGRAPH
    END-IF
    MOVE SPACE TO LS-NM-PROBLEM
    MOVE 1 TO LS-NM-PART
    MOVE 0 TO LS-NM-PART-LEN
    PERFORM VARYING LS-NM-AT FROM 1 BY 1
            UNTIL LS-NM-AT > LS-NM-LEN
            OR LS-NM-PROBLEM NOT = SPACE
        MOVE FUNCTION UPPER-CASE(LS-NM-TEXT(LS-NM-AT:1)) TO LS-NM-CH
        EVALUATE TRUE
            WHEN LS-NM-CH = "." AND LS-NM-PART = 1 AND LS-NM-KIND = "N"
                IF LS-NM-PART-LEN = 0
                    MOVE "E" TO LS-NM-PROBLEM
                ELSE
                    ADD 1 TO LS-NM-PART
                    MOVE 0 TO LS-NM-PART-LEN
                END-IF
            WHEN (LS-NM-CH >= "A" AND LS-NM-CH <= "Z")
                 OR LS-NM-CH = "$" OR "#" OR "@"
                ADD 1 TO LS-NM-PART-LEN
            WHEN LS-NM-CH >= "0" AND LS-NM-CH <= "9"
                IF LS-NM-PART-LEN = 0
                    MOVE "F" TO LS-NM-PROBLEM
                END-IF
                ADD 1 TO LS-NM-PART-LEN
            WHEN OTHER
                IF LS-NM-PART-LEN = 0
                    MOVE "F" TO LS-NM-PROBLEM
                ELSE
                    MOVE "C" TO LS-NM-PROBLEM
                END-IF
        END-EVALUATE
        IF LS-NM-PART-LEN > 8 AND LS-NM-PROBLEM = SPACE
            MOVE "L" TO LS-NM-PROBLEM
        END-IF
    END-PERFORM
    IF LS-NM-PROBLEM = SPACE AND LS-NM-PART-LEN = 0
        MOVE "E" TO LS-NM-PROBLEM
    END-IF
    IF LS-NM-PROBLEM = SPACE
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JN-COUNT
    MOVE LS-NM-KIND TO JN-KIND(JN-COUNT)
    MOVE FUNCTION UPPER-CASE(LS-NM-TEXT(1:LS-NM-LEN))
        TO JN-NAME(JN-COUNT)
    MOVE LS-NM-LEN TO JN-LEN(JN-COUNT)
    MOVE LS-NM-PART TO JN-PART(JN-COUNT)
    MOVE LS-NM-PROBLEM TO JN-PROBLEM(JN-COUNT)
    MOVE LK-FILE-ID TO JN-FILE-ID(JN-COUNT)
    MOVE LS-LINE-NO TO JN-LINE(JN-COUNT).

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
        WHEN "OUTPUT"
            PERFORM ADD-OUTPUT
    END-EVALUATE.

*> An OUTPUT JCL statement, where a DD's OUTPUT=*.name finds it.
ADD-OUTPUT.
    IF JO-COUNT >= JO-MAX OR ST-NAME = SPACES
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO JO-COUNT
    MOVE ST-NAME TO JO-NAME(JO-COUNT)
    IF LS-PROC > 0
        MOVE 0 TO JO-JOB(JO-COUNT)
    ELSE
        MOVE LS-JOB TO JO-JOB(JO-COUNT)
    END-IF
    MOVE LS-PROC TO JO-PROC(JO-COUNT)
    MOVE LS-STEP TO JO-STEP(JO-COUNT)
    MOVE LK-FILE-ID TO JO-FILE-ID(JO-COUNT)
    MOVE ST-LINE TO JO-LINE(JO-COUNT).

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
    MOVE ST-LINE TO JJ-LINE(LS-JOB)
    MOVE SPACES TO JJ-TIME-BAD(LS-JOB) JJ-REGION-BAD(LS-JOB)
        JJ-MSGLEVEL-BAD(LS-JOB) JJ-CLASS-BAD(LS-JOB) JJ-CLASS-KEY(LS-JOB)
        JJ-COND(LS-JOB) JJ-VALUE-KEY(LS-JOB) JJ-VALUE-BAD(LS-JOB)
        JJ-JOBLIB-AFTER(LS-JOB) LS-PRE-DD
    MOVE 0 TO JJ-JOBLIB-LINE(LS-JOB)
    MOVE 1 TO OP-START
    MOVE 0 TO OP-POSITION
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        IF OP-KEY = "TIME"
            MOVE "J" TO LS-TIME-OF
            PERFORM CHECK-TIME
            MOVE LS-TIME-BAD TO JJ-TIME-BAD(LS-JOB)
        END-IF
        IF OP-KEY = "REGION"
            PERFORM CHECK-REGION
            MOVE LS-TIME-BAD TO JJ-REGION-BAD(LS-JOB)
        END-IF
        IF OP-KEY = "COND"
            MOVE OP-VALUE TO JJ-COND(LS-JOB)
        END-IF
        IF JJ-VALUE-KEY(LS-JOB) = SPACES
            PERFORM CHECK-EXEC-VALUE
            IF LS-TIME-BAD NOT = SPACES
                MOVE OP-KEY TO JJ-VALUE-KEY(LS-JOB)
                MOVE LS-TIME-BAD TO JJ-VALUE-BAD(LS-JOB)
            END-IF
        END-IF
        IF OP-KEY = "MSGLEVEL"
            PERFORM CHECK-MSGLEVEL
            MOVE LS-TIME-BAD TO JJ-MSGLEVEL-BAD(LS-JOB)
        END-IF
        IF (OP-KEY = "CLASS" OR OP-KEY = "MSGCLASS")
           AND JJ-CLASS-BAD(LS-JOB) = SPACES
            MOVE OP-VALUE TO LS-CLASS-TEXT
            IF OP-KEY = "CLASS"
                PERFORM CHECK-JOB-CLASS
            ELSE
                PERFORM CHECK-OUTPUT-CLASS
            END-IF
            IF LS-CLASS-OK = "N"
                MOVE OP-VALUE TO JJ-CLASS-BAD(LS-JOB)
                MOVE OP-KEY TO JJ-CLASS-KEY(LS-JOB)
            END-IF
        END-IF
        PERFORM NEXT-OPERAND
    END-PERFORM.

*> LS-TIME-BAD: OP-VALUE, a TIME= value, when the z/OS MVS JCL
*> Reference does not allow it ("TIME parameter" of EXEC and JOB):
*> minutes from 0 through 357912, seconds from 0 through 59, as
*> minutes, (minutes,seconds), or (,seconds); or 1440, NOLIMIT,
*> MAXIMUM, or 0, and not 0 on a JOB statement (LS-TIME-OF "J"), where
*> "the results are unpredictable". Values with symbols are not read.
CHECK-TIME.
    MOVE SPACES TO LS-TIME-BAD LS-TIME-MIN LS-TIME-SEC
    IF OP-VALUE = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN OP-VALUE = "NOLIMIT" OR OP-VALUE = "MAXIMUM"
             OR OP-VALUE = "1440"
            EXIT PARAGRAPH
        WHEN OP-VALUE = "0" OR OP-VALUE = "(0)"
            IF LS-TIME-OF = "J"
                MOVE OP-VALUE TO LS-TIME-BAD
            END-IF
            EXIT PARAGRAPH
        WHEN OP-VALUE(1:1) = "("
            UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
                INTO LS-TIME-MIN LS-TIME-SEC
        WHEN OTHER
            MOVE OP-VALUE TO LS-TIME-MIN
    END-EVALUATE
    MOVE LS-TIME-MIN TO LS-TIME-PART
    MOVE 357912 TO LS-TIME-MAX
    PERFORM CHECK-TIME-PART
    MOVE LS-TIME-SEC TO LS-TIME-PART
    MOVE 59 TO LS-TIME-MAX
    PERFORM CHECK-TIME-PART.

*> LS-TIME-BAD: OP-VALUE, a REGION= value, when the z/OS MVS JCL
*> Reference does not allow it ("REGION parameter" of EXEC and JOB):
*> valueK, 1 to 7 digits from 1 through 2096128, or valueM, 1 to 4
*> digits from 1 through 2047; 0K and 0M give all the storage there
*> is. Values with symbols are not read.
CHECK-REGION.
    MOVE SPACES TO LS-TIME-BAD LS-TIME-PART
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR OP-VALUE = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N
        FOR CHARACTERS BEFORE INITIAL " "
    IF LS-TIME-N < 2 OR LS-TIME-N > 21
        MOVE OP-VALUE TO LS-TIME-BAD
        EXIT PARAGRAPH
    END-IF
    EVALUATE OP-VALUE(LS-TIME-N:1)
        WHEN "K"
            MOVE 2096128 TO LS-TIME-MAX
        WHEN "M"
            MOVE 2047 TO LS-TIME-MAX
        WHEN OTHER
            MOVE OP-VALUE TO LS-TIME-BAD
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE OP-VALUE(1:LS-TIME-N - 1) TO LS-TIME-PART
    PERFORM CHECK-TIME-PART.

*> LS-TIME-BAD: OP-VALUE when OP-KEY is ADDRSPC, RD, or MEMLIMIT (or
*> KEY.procstep), or of a JOB statement TYPRUN, PRTY, or JESLOG, and the
*> z/OS MVS JCL Reference does not list it: ADDRSPC VIRT or REAL; RD R,
*> RNC, NR, or NC; MEMLIMIT NOLIMIT or nnnnn (0 to 99999) with M, G, T,
*> or P, at most 16384P; TYPRUN COPY, HOLD, JCLHOLD, or SCAN; PRTY 0
*> through 15; JESLOG SPIN (first, in parentheses), NOSPIN, or SUPPRESS.
*> Values with symbols are not read.
CHECK-EXEC-VALUE.
    MOVE SPACES TO LS-TIME-BAD
    MOVE SPACES TO LS-SP-Q1
    UNSTRING OP-KEY DELIMITED BY "." INTO LS-SP-Q1
    IF LS-SP-Q1 NOT = "ADDRSPC" AND LS-SP-Q1 NOT = "RD"
       AND LS-SP-Q1 NOT = "MEMLIMIT" AND LS-SP-Q1 NOT = "TYPRUN"
       AND LS-SP-Q1 NOT = "PRTY" AND LS-SP-Q1 NOT = "JESLOG"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR OP-VALUE = SPACES
        EXIT PARAGRAPH
    END-IF
    EVALUATE LS-SP-Q1
        WHEN "ADDRSPC"
            IF OP-VALUE NOT = "VIRT" AND OP-VALUE NOT = "REAL"
                MOVE OP-VALUE TO LS-TIME-BAD
            END-IF
        WHEN "RD"
            IF OP-VALUE NOT = "R" AND OP-VALUE NOT = "RNC"
               AND OP-VALUE NOT = "NR" AND OP-VALUE NOT = "NC"
                MOVE OP-VALUE TO LS-TIME-BAD
            END-IF
        WHEN "TYPRUN"
            IF OP-VALUE NOT = "COPY" AND OP-VALUE NOT = "HOLD"
               AND OP-VALUE NOT = "JCLHOLD" AND OP-VALUE NOT = "SCAN"
                MOVE OP-VALUE TO LS-TIME-BAD
            END-IF
        WHEN "PRTY"
            MOVE OP-VALUE TO LS-SPACE-ITEM
            MOVE 15 TO LS-TIME-MAX
            PERFORM SPACE-NUMBER
            IF LS-CLASS-OK = "N"
                MOVE OP-VALUE TO LS-TIME-BAD
            END-IF
        WHEN "JESLOG"
            MOVE SPACES TO LS-SP-Q2
            IF OP-VALUE(1:1) = "("
                UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
                    INTO LS-SP-Q2
            ELSE
                MOVE OP-VALUE TO LS-SP-Q2
            END-IF
            IF LS-SP-Q2 NOT = "SPIN" AND LS-SP-Q2 NOT = "NOSPIN"
               AND LS-SP-Q2 NOT = "SUPPRESS"
                MOVE OP-VALUE TO LS-TIME-BAD
            END-IF
        WHEN OTHER
            IF OP-VALUE = "NOLIMIT"
                EXIT PARAGRAPH
            END-IF
            MOVE 0 TO LS-TIME-N
            INSPECT OP-VALUE TALLYING LS-TIME-N
                FOR CHARACTERS BEFORE INITIAL " "
            IF LS-TIME-N < 2 OR LS-TIME-N > 6
                MOVE OP-VALUE TO LS-TIME-BAD
                EXIT PARAGRAPH
            END-IF
            IF OP-VALUE(1:LS-TIME-N - 1) IS NOT NUMERIC
                MOVE OP-VALUE TO LS-TIME-BAD
                EXIT PARAGRAPH
            END-IF
            EVALUATE OP-VALUE(LS-TIME-N:1)
                WHEN "M" WHEN "G" WHEN "T"
                    CONTINUE
                WHEN "P"
                    IF FUNCTION NUMVAL(OP-VALUE(1:LS-TIME-N - 1)) > 16384
                        MOVE OP-VALUE TO LS-TIME-BAD
                    END-IF
                WHEN OTHER
                    MOVE OP-VALUE TO LS-TIME-BAD
            END-EVALUATE
    END-EVALUATE.

*> LS-TIME-BAD: OP-VALUE, a MSGLEVEL= value, when the z/OS MVS JCL
*> Reference does not allow it ("MSGLEVEL parameter"): statements, 0,
*> 1, or 2, and messages, 0 or 1, as statements, (statements,messages),
*> or (,messages). Values with symbols are not read.
CHECK-MSGLEVEL.
    MOVE SPACES TO LS-TIME-BAD LS-TIME-MIN LS-TIME-SEC
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR OP-VALUE = SPACES
        EXIT PARAGRAPH
    END-IF
    IF OP-VALUE(1:1) = "("
        UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
            INTO LS-TIME-MIN LS-TIME-SEC
    ELSE
        MOVE OP-VALUE TO LS-TIME-MIN
    END-IF
    IF LS-TIME-MIN NOT = SPACES AND LS-TIME-MIN NOT = "0"
       AND LS-TIME-MIN NOT = "1" AND LS-TIME-MIN NOT = "2"
        MOVE OP-VALUE TO LS-TIME-BAD
    END-IF
    IF LS-TIME-SEC NOT = SPACES AND LS-TIME-SEC NOT = "0"
       AND LS-TIME-SEC NOT = "1"
        MOVE OP-VALUE TO LS-TIME-BAD
    END-IF.

*> EXPDT= (LS-EXPDT) and RETPD= (LS-RETPD) of DD LS-D, as the z/OS MVS
*> JCL Reference describes them: EXPDT yyddd (year 1900 + yy) or
*> yyyy/ddd (year 1900 through 2155), with ddd from 001 through 365, or
*> 366 in a leap year (1999's 365 and 366 are "never-scratch" dates);
*> RETPD 1 to 5 digits from 0 through 93000; not both ("Do not code the
*> following DD parameters with the EXPDT parameter": RETPD); and
*> neither for a temporary data set (&&NAME). Symbols are not read.
CHECK-RETENTION.
    MOVE 0 TO LS-TIME-N
    INSPECT LS-EXPDT TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    INSPECT LS-RETPD TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN JD-DSN(LS-D)(1:2) = "&&"
            MOVE "T" TO JD-RETAIN-PROBLEM(LS-D)
            IF LS-EXPDT NOT = SPACES
                MOVE LS-EXPDT TO JD-RETAIN-VALUE(LS-D)
            ELSE
                MOVE LS-RETPD TO JD-RETAIN-VALUE(LS-D)
            END-IF
        WHEN LS-EXPDT NOT = SPACES AND LS-RETPD NOT = SPACES
            MOVE "B" TO JD-RETAIN-PROBLEM(LS-D)
        WHEN LS-EXPDT NOT = SPACES
            PERFORM CHECK-EXPDT
        WHEN OTHER
            MOVE 0 TO LS-TIME-N
            INSPECT LS-RETPD TALLYING LS-TIME-N
                FOR CHARACTERS BEFORE INITIAL " "
            IF LS-TIME-N > 5
                MOVE "R" TO JD-RETAIN-PROBLEM(LS-D)
            ELSE
                IF LS-RETPD(1:LS-TIME-N) IS NOT NUMERIC
                    MOVE "R" TO JD-RETAIN-PROBLEM(LS-D)
                ELSE
                    IF FUNCTION NUMVAL(LS-RETPD(1:LS-TIME-N)) > 93000
                        MOVE "R" TO JD-RETAIN-PROBLEM(LS-D)
                    END-IF
                END-IF
            END-IF
            IF JD-RETAIN-PROBLEM(LS-D) = "R"
                MOVE LS-RETPD TO JD-RETAIN-VALUE(LS-D)
            END-IF
    END-EVALUATE.

*> The keywords of the DD that CHECK-PAIRS reads.
NOTE-PAIR-KEY.
    EVALUATE TRUE
        WHEN OP-KEY = "LRECL"
            MOVE "Y" TO LS-LRECL-KW
        WHEN OP-KEY = "RECFM"
            MOVE "Y" TO LS-RECFM-KW
        WHEN OP-KEY = "DSNTYPE"
            MOVE "Y" TO LS-DSNTYPE-CODED
        WHEN OP-KEY = "FREE" AND OP-VALUE = "CLOSE"
            MOVE "Y" TO LS-FREE-CLOSE
        WHEN OP-KEY = "AVGREC"
            MOVE "Y" TO LS-AVGREC-CODED
        WHEN OP-KEY = "SPACE"
            IF OP-VALUE(1:5) = "(TRK," OR OP-VALUE(1:5) = "(CYL,"
               OR OP-VALUE(1:7) = "(ABSTR,"
                MOVE "Y" TO LS-SPACE-UNIT
            END-IF
    END-EVALUATE.

*> Parameters of DD LS-D that the z/OS MVS JCL Reference says not to
*> code together ("Relationship to other parameters" of each): RECORG
*> with RECFM (or DCB=RECFM), DSNTYPE, DCB=DSORG, or FREE=CLOSE; AVGREC
*> with a SPACE in TRK, CYL, or ABSTR; LRECL with DCB=LRECL; RECFM with
*> DCB=RECFM.
CHECK-PAIRS.
    EVALUATE TRUE
        WHEN JD-RECORG(LS-D) = "Y"
             AND (LS-RECFM-KW = "Y" OR LS-RECFM-DCB = "Y")
            MOVE "RECORG" TO JD-CONFLICT-1(LS-D)
            MOVE "RECFM" TO JD-CONFLICT-2(LS-D)
        WHEN JD-RECORG(LS-D) = "Y" AND LS-DSNTYPE-CODED = "Y"
            MOVE "RECORG" TO JD-CONFLICT-1(LS-D)
            MOVE "DSNTYPE" TO JD-CONFLICT-2(LS-D)
        WHEN JD-RECORG(LS-D) = "Y" AND LS-DSORG-DCB = "Y"
            MOVE "RECORG" TO JD-CONFLICT-1(LS-D)
            MOVE "DCB=DSORG" TO JD-CONFLICT-2(LS-D)
        WHEN JD-RECORG(LS-D) = "Y" AND LS-FREE-CLOSE = "Y"
            MOVE "RECORG" TO JD-CONFLICT-1(LS-D)
            MOVE "FREE=CLOSE" TO JD-CONFLICT-2(LS-D)
        WHEN LS-AVGREC-CODED = "Y" AND LS-SPACE-UNIT = "Y"
            MOVE "AVGREC" TO JD-CONFLICT-1(LS-D)
            MOVE "SPACE in TRK, CYL, or ABSTR" TO JD-CONFLICT-2(LS-D)
        WHEN LS-LRECL-KW = "Y" AND LS-LRECL-DCB = "Y"
            MOVE "LRECL" TO JD-CONFLICT-1(LS-D)
            MOVE "DCB=LRECL" TO JD-CONFLICT-2(LS-D)
        WHEN LS-RECFM-KW = "Y" AND LS-RECFM-DCB = "Y"
            MOVE "RECFM" TO JD-CONFLICT-1(LS-D)
            MOVE "DCB=RECFM" TO JD-CONFLICT-2(LS-D)
    END-EVALUATE.

*> HOLD=, FREE=, SPIN=, AVGREC=, RECORG=, and DSNTYPE= of DD LS-D: the
*> values the z/OS MVS JCL Reference lists for each. HOLD YES, Y, NO,
*> or N; FREE END or CLOSE; SPIN NO or UNALLOC (first, in
*> parentheses); AVGREC U, K, or M; RECORG KS, ES, RR, or LS; DSNTYPE
*> LIBRARY, HFS, PDS, PIPE, EXTREQ, EXTPREF, LARGE, or BASIC, with a
*> version 1 or 2 after LIBRARY, EXTREQ, and EXTPREF. Values with
*> symbols are not read.
CHECK-DD-VALUE.
    IF OP-KEY = "LABEL"
        PERFORM CHECK-LABEL
        EXIT PARAGRAPH
    END-IF
    IF OP-KEY NOT = "HOLD" AND OP-KEY NOT = "FREE" AND OP-KEY NOT = "SPIN"
       AND OP-KEY NOT = "AVGREC" AND OP-KEY NOT = "RECORG"
       AND OP-KEY NOT = "DSNTYPE"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR OP-VALUE = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-SP-Q1 LS-SP-Q2
    IF OP-VALUE(1:1) = "("
        UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")" INTO LS-SP-Q1
            LS-SP-Q2
    ELSE
        MOVE OP-VALUE TO LS-SP-Q1
    END-IF
    MOVE "Y" TO LS-CLASS-OK
    EVALUATE OP-KEY
        WHEN "HOLD"
            IF LS-SP-Q1 NOT = "YES" AND LS-SP-Q1 NOT = "Y"
               AND LS-SP-Q1 NOT = "NO" AND LS-SP-Q1 NOT = "N"
                MOVE "N" TO LS-CLASS-OK
            END-IF
        WHEN "FREE"
            IF LS-SP-Q1 NOT = "END" AND LS-SP-Q1 NOT = "CLOSE"
                MOVE "N" TO LS-CLASS-OK
            END-IF
        WHEN "SPIN"
            IF LS-SP-Q1 NOT = "NO" AND LS-SP-Q1 NOT = "UNALLOC"
                MOVE "N" TO LS-CLASS-OK
            END-IF
        WHEN "AVGREC"
            IF LS-SP-Q1 NOT = "U" AND LS-SP-Q1 NOT = "K"
               AND LS-SP-Q1 NOT = "M"
                MOVE "N" TO LS-CLASS-OK
            END-IF
        WHEN "DSNTYPE"
            EVALUATE TRUE
                WHEN LS-SP-Q1 = "LIBRARY" OR LS-SP-Q1 = "EXTREQ"
                     OR LS-SP-Q1 = "EXTPREF"
                    IF LS-SP-Q2 NOT = SPACES AND LS-SP-Q2 NOT = "1"
                       AND LS-SP-Q2 NOT = "2"
                        MOVE "N" TO LS-CLASS-OK
                    END-IF
                WHEN LS-SP-Q1 = "HFS" OR LS-SP-Q1 = "PDS"
                     OR LS-SP-Q1 = "PIPE" OR LS-SP-Q1 = "LARGE"
                     OR LS-SP-Q1 = "BASIC"
                    CONTINUE
                WHEN OTHER
                    MOVE "N" TO LS-CLASS-OK
            END-EVALUATE
        WHEN OTHER
            IF LS-SP-Q1 NOT = "KS" AND LS-SP-Q1 NOT = "ES"
               AND LS-SP-Q1 NOT = "RR" AND LS-SP-Q1 NOT = "LS"
                MOVE "N" TO LS-CLASS-OK
            END-IF
    END-EVALUATE
    IF LS-CLASS-OK = "N"
        MOVE OP-KEY TO JD-VALUE-KEY(LS-D)
        MOVE OP-VALUE TO JD-VALUE-BAD(LS-D)
    END-IF.

*> LABEL=(sequence,label,PASSWORD|NOPWREAD,IN|OUT,...) of DD LS-D: the
*> sequence number up to 65535, the label AL, AUL, BLP, LTM, NL, NSL,
*> SL, or SUL, then PASSWORD or NOPWREAD, then IN or OUT (z/OS MVS JCL
*> Reference, "LABEL parameter"). EXPDT= and RETPD= in the list are not
*> read here; values with symbols are not read.
CHECK-LABEL.
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR OP-VALUE = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-SP-Q1 LS-SP-Q2 LS-SP-Q3 LS-SP-TEXT
    IF OP-VALUE(1:1) = "("
        UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
            INTO LS-SP-Q1 LS-SP-Q2 LS-SP-Q3 LS-SP-TEXT
    ELSE
        MOVE OP-VALUE TO LS-SP-Q1
    END-IF
    MOVE SPACES TO LS-CLASS-TEXT
    *> A keyword subparameter (EXPDT=, RETPD=) ends the positional ones.
    MOVE 0 TO LS-TIME-N
    INSPECT LS-SP-Q1 TALLYING LS-TIME-N FOR ALL "="
    IF LS-TIME-N > 0
        EXIT PARAGRAPH
    END-IF
    IF LS-SP-Q1 NOT = SPACES
        MOVE LS-SP-Q1 TO LS-SPACE-ITEM
        MOVE 65535 TO LS-TIME-MAX
        PERFORM SPACE-NUMBER
        IF LS-CLASS-OK = "N"
            MOVE LS-SP-Q1 TO LS-CLASS-TEXT
        END-IF
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT LS-SP-Q2 TALLYING LS-TIME-N FOR ALL "="
    IF LS-CLASS-TEXT = SPACES AND LS-TIME-N = 0 AND LS-SP-Q2 NOT = SPACES
       AND LS-SP-Q2 NOT = "AL" AND LS-SP-Q2 NOT = "AUL"
       AND LS-SP-Q2 NOT = "BLP" AND LS-SP-Q2 NOT = "LTM"
       AND LS-SP-Q2 NOT = "NL" AND LS-SP-Q2 NOT = "NSL"
       AND LS-SP-Q2 NOT = "SL" AND LS-SP-Q2 NOT = "SUL"
        MOVE LS-SP-Q2 TO LS-CLASS-TEXT
    END-IF
    IF LS-TIME-N > 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT LS-SP-Q3 TALLYING LS-TIME-N FOR ALL "="
    IF LS-CLASS-TEXT = SPACES AND LS-TIME-N = 0 AND LS-SP-Q3 NOT = SPACES
       AND LS-SP-Q3 NOT = "PASSWORD" AND LS-SP-Q3 NOT = "NOPWREAD"
        MOVE LS-SP-Q3 TO LS-CLASS-TEXT
    END-IF
    IF LS-TIME-N > 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT LS-SP-TEXT TALLYING LS-TIME-N FOR ALL "="
    IF LS-CLASS-TEXT = SPACES AND LS-TIME-N = 0 AND LS-SP-TEXT NOT = SPACES
       AND LS-SP-TEXT NOT = "IN" AND LS-SP-TEXT NOT = "OUT"
        MOVE LS-SP-TEXT TO LS-CLASS-TEXT
    END-IF
    IF LS-CLASS-TEXT NOT = SPACES
        MOVE "LABEL" TO JD-VALUE-KEY(LS-D)
        MOVE LS-CLASS-TEXT TO JD-VALUE-BAD(LS-D)
    END-IF.

*> DISP= of DD LS-D, OP-VALUE: the status NEW, OLD, SHR, or MOD; the
*> normal termination disposition DELETE, KEEP, PASS, CATLG, or UNCATLG;
*> the abnormal one DELETE, KEEP, CATLG, or UNCATLG; each may be left
*> out (z/OS MVS JCL Reference, "DISP parameter"). Values with symbols
*> are not read.
CHECK-DISP.
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR OP-VALUE = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-SP-Q1 LS-SP-Q2 LS-SP-Q3 LS-SP-TEXT
    IF OP-VALUE(1:1) = "("
        UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
            INTO LS-SP-Q1 LS-SP-Q2 LS-SP-Q3 LS-SP-TEXT
    ELSE
        MOVE OP-VALUE TO LS-SP-Q1
    END-IF
    EVALUATE TRUE
        WHEN LS-SP-Q1 NOT = SPACES AND LS-SP-Q1 NOT = "NEW"
             AND LS-SP-Q1 NOT = "OLD" AND LS-SP-Q1 NOT = "SHR"
             AND LS-SP-Q1 NOT = "MOD"
            MOVE "S" TO JD-DISP-PART(LS-D)
            MOVE LS-SP-Q1 TO JD-DISP-BAD(LS-D)
        WHEN LS-SP-Q2 NOT = SPACES AND LS-SP-Q2 NOT = "DELETE"
             AND LS-SP-Q2 NOT = "KEEP" AND LS-SP-Q2 NOT = "PASS"
             AND LS-SP-Q2 NOT = "CATLG" AND LS-SP-Q2 NOT = "UNCATLG"
            MOVE "N" TO JD-DISP-PART(LS-D)
            MOVE LS-SP-Q2 TO JD-DISP-BAD(LS-D)
        WHEN LS-SP-Q3 NOT = SPACES AND LS-SP-Q3 NOT = "DELETE"
             AND LS-SP-Q3 NOT = "KEEP" AND LS-SP-Q3 NOT = "CATLG"
             AND LS-SP-Q3 NOT = "UNCATLG"
            MOVE "A" TO JD-DISP-PART(LS-D)
            MOVE LS-SP-Q3 TO JD-DISP-BAD(LS-D)
        WHEN LS-SP-TEXT NOT = SPACES
            MOVE "X" TO JD-DISP-PART(LS-D)
            MOVE LS-SP-TEXT TO JD-DISP-BAD(LS-D)
    END-EVALUATE.

*> SPACE=(unit,quantities,options...) of DD LS-D, OP-VALUE, as the
*> z/OS MVS JCL Reference describes it: the unit TRK, CYL, ABSTR, or a
*> block or record length "from 0 through 65535"; quantities, in
*> parentheses or alone, that "syntax allows for values of 0-16777215";
*> and the options RLSE, CONTIG, MXIG, ALX, and ROUND. Each part is read
*> between the commas outside the inner parentheses; values with
*> symbols are not read.
CHECK-SPACE.
    MOVE 0 TO LS-TIME-N
    INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR OP-VALUE(1:1) NOT = "("
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-SP-PART
    MOVE 0 TO LS-SP-DEPTH LS-SP-LEN
    MOVE SPACES TO LS-SP-TEXT
    PERFORM VARYING LS-SP-I FROM 2 BY 1
            UNTIL LS-SP-I > LENGTH OF OP-VALUE
        MOVE OP-VALUE(LS-SP-I:1) TO LS-CHAR
        EVALUATE TRUE
            WHEN LS-CHAR = "("
                ADD 1 TO LS-SP-DEPTH
                PERFORM SPACE-ADD-CHAR
            WHEN LS-CHAR = ")" AND LS-SP-DEPTH > 0
                SUBTRACT 1 FROM LS-SP-DEPTH
                PERFORM SPACE-ADD-CHAR
            WHEN (LS-CHAR = "," OR LS-CHAR = ")") AND LS-SP-DEPTH = 0
                PERFORM CHECK-SPACE-PART
                IF JD-SPACE-PART(LS-D) NOT = SPACE OR LS-CHAR = ")"
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-SP-PART
                MOVE 0 TO LS-SP-LEN
                MOVE SPACES TO LS-SP-TEXT
            WHEN LS-CHAR = SPACE
                EXIT PERFORM
            WHEN OTHER
                PERFORM SPACE-ADD-CHAR
        END-EVALUATE
    END-PERFORM.

SPACE-ADD-CHAR.
    IF LS-SP-LEN < 20
        ADD 1 TO LS-SP-LEN
        MOVE LS-CHAR TO LS-SP-TEXT(LS-SP-LEN:1)
    END-IF.

*> Part LS-SP-PART of SPACE=, LS-SP-TEXT.
CHECK-SPACE-PART.
    IF LS-SP-TEXT = SPACES
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN LS-SP-PART = 1
            IF LS-SP-TEXT NOT = "TRK" AND LS-SP-TEXT NOT = "CYL"
               AND LS-SP-TEXT NOT = "ABSTR"
                MOVE LS-SP-TEXT TO LS-SPACE-ITEM
                MOVE 65535 TO LS-TIME-MAX
                PERFORM SPACE-NUMBER
                IF LS-CLASS-OK = "N"
                    MOVE "U" TO JD-SPACE-PART(LS-D)
                END-IF
            END-IF
        WHEN LS-SP-PART = 2
            *> One quantity, or (primary,secondary,directory).
            MOVE 16777215 TO LS-TIME-MAX
            IF LS-SP-TEXT(1:1) = "("
                MOVE SPACES TO LS-SP-Q1 LS-SP-Q2 LS-SP-Q3
                UNSTRING LS-SP-TEXT(2:) DELIMITED BY "," OR ")"
                    INTO LS-SP-Q1 LS-SP-Q2 LS-SP-Q3
                MOVE LS-SP-Q1 TO LS-SPACE-ITEM
                PERFORM SPACE-NUMBER
                IF LS-CLASS-OK = "Y"
                    MOVE LS-SP-Q2 TO LS-SPACE-ITEM
                    PERFORM SPACE-NUMBER
                END-IF
                IF LS-CLASS-OK = "Y"
                    MOVE LS-SP-Q3 TO LS-SPACE-ITEM
                    PERFORM SPACE-NUMBER
                END-IF
            ELSE
                MOVE LS-SP-TEXT TO LS-SPACE-ITEM
                PERFORM SPACE-NUMBER
            END-IF
            IF LS-CLASS-OK = "N"
                MOVE "Q" TO JD-SPACE-PART(LS-D)
            END-IF
        WHEN OTHER
            IF LS-SP-TEXT NOT = "RLSE" AND LS-SP-TEXT NOT = "CONTIG"
               AND LS-SP-TEXT NOT = "MXIG" AND LS-SP-TEXT NOT = "ALX"
               AND LS-SP-TEXT NOT = "ROUND"
                MOVE "O" TO JD-SPACE-PART(LS-D)
            END-IF
    END-EVALUATE
    IF JD-SPACE-PART(LS-D) NOT = SPACE
        MOVE LS-SP-TEXT TO JD-SPACE-BAD(LS-D)
    END-IF.

*> LS-CLASS-OK: "N" when LS-SPACE-ITEM is not empty or 1 to 8 digits
*> no more than LS-TIME-MAX.
SPACE-NUMBER.
    MOVE "Y" TO LS-CLASS-OK
    IF LS-SPACE-ITEM = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT LS-SPACE-ITEM TALLYING LS-TIME-N
        FOR CHARACTERS BEFORE INITIAL " "
    IF LS-TIME-N > 8
        MOVE "N" TO LS-CLASS-OK
        EXIT PARAGRAPH
    END-IF
    IF LS-SPACE-ITEM(1:LS-TIME-N) IS NOT NUMERIC
        MOVE "N" TO LS-CLASS-OK
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION NUMVAL(LS-SPACE-ITEM(1:LS-TIME-N)) > LS-TIME-MAX
        MOVE "N" TO LS-CLASS-OK
    END-IF.

*> LS-EXPDT: yyddd or yyyy/ddd of a day there is.
CHECK-EXPDT.
    MOVE 0 TO LS-YEAR LS-DAY
    EVALUATE TRUE
        WHEN LS-EXPDT(6:) = SPACES AND LS-EXPDT(1:5) IS NUMERIC
            COMPUTE LS-YEAR = 1900 + FUNCTION NUMVAL(LS-EXPDT(1:2))
            COMPUTE LS-DAY = FUNCTION NUMVAL(LS-EXPDT(3:3))
        WHEN LS-EXPDT(9:) = SPACES AND LS-EXPDT(5:1) = "/"
             AND LS-EXPDT(1:4) IS NUMERIC AND LS-EXPDT(6:3) IS NUMERIC
            COMPUTE LS-YEAR = FUNCTION NUMVAL(LS-EXPDT(1:4))
            COMPUTE LS-DAY = FUNCTION NUMVAL(LS-EXPDT(6:3))
    END-EVALUATE
    MOVE 365 TO LS-YEAR-DAYS
    IF (FUNCTION MOD(LS-YEAR, 4) = 0 AND FUNCTION MOD(LS-YEAR, 100) > 0)
       OR FUNCTION MOD(LS-YEAR, 400) = 0 OR LS-YEAR = 1999
        MOVE 366 TO LS-YEAR-DAYS
    END-IF
    IF LS-YEAR < 1900 OR LS-YEAR > 2155 OR LS-DAY < 1
       OR LS-DAY > LS-YEAR-DAYS
        MOVE "E" TO JD-RETAIN-PROBLEM(LS-D)
        MOVE LS-EXPDT TO JD-RETAIN-VALUE(LS-D)
    END-IF.

*> LS-CLASS-OK: "N" when LS-CLASS-TEXT, a MSGCLASS= or SYSOUT= class,
*> is not what the z/OS MVS JCL Reference allows: "one character: A
*> through Z or 0 through 9", which may be in quotation marks. Empty
*> (the null class of SYSOUT=(,)), *, and symbols are left alone.
CHECK-OUTPUT-CLASS.
    MOVE "Y" TO LS-CLASS-OK
    IF LS-CLASS-TEXT(1:1) = "'"
        MOVE LS-CLASS-TEXT(2:) TO LS-CLASS-QUOTED
        MOVE LS-CLASS-QUOTED TO LS-CLASS-TEXT
        INSPECT LS-CLASS-TEXT REPLACING FIRST "'" BY SPACE
    END-IF
    IF LS-CLASS-TEXT = SPACES OR LS-CLASS-TEXT = "*"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT LS-CLASS-TEXT TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0
        EXIT PARAGRAPH
    END-IF
    IF LS-CLASS-TEXT(2:) NOT = SPACES
        MOVE "N" TO LS-CLASS-OK
        EXIT PARAGRAPH
    END-IF
    IF NOT ((LS-CLASS-TEXT(1:1) >= "A" AND LS-CLASS-TEXT(1:1) <= "Z")
            OR (LS-CLASS-TEXT(1:1) >= "0" AND LS-CLASS-TEXT(1:1) <= "9"))
        MOVE "N" TO LS-CLASS-OK
    END-IF.

*> The same for CLASS= of a JOB statement: "1-8 characters", the first
*> "a member of the 36-character set A-Z and 0-9", the others
*> alphabetic, national, or numeric.
CHECK-JOB-CLASS.
    MOVE "Y" TO LS-CLASS-OK
    MOVE 0 TO LS-TIME-N
    INSPECT LS-CLASS-TEXT TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR LS-CLASS-TEXT = SPACES
        EXIT PARAGRAPH
    END-IF
    IF LS-CLASS-TEXT(9:) NOT = SPACES
        MOVE "N" TO LS-CLASS-OK
        EXIT PARAGRAPH
    END-IF
    IF NOT ((LS-CLASS-TEXT(1:1) >= "A" AND LS-CLASS-TEXT(1:1) <= "Z")
            OR (LS-CLASS-TEXT(1:1) >= "0" AND LS-CLASS-TEXT(1:1) <= "9"))
        MOVE "N" TO LS-CLASS-OK
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-TIME-N FROM 2 BY 1 UNTIL LS-TIME-N > 8
        IF LS-CLASS-TEXT(LS-TIME-N:1) = SPACE
            EXIT PERFORM
        END-IF
        IF NOT ((LS-CLASS-TEXT(LS-TIME-N:1) >= "A"
                 AND LS-CLASS-TEXT(LS-TIME-N:1) <= "Z")
                OR (LS-CLASS-TEXT(LS-TIME-N:1) >= "0"
                    AND LS-CLASS-TEXT(LS-TIME-N:1) <= "9")
                OR LS-CLASS-TEXT(LS-TIME-N:1) = "#"
                OR LS-CLASS-TEXT(LS-TIME-N:1) = "@"
                OR LS-CLASS-TEXT(LS-TIME-N:1) = "$")
            MOVE "N" TO LS-CLASS-OK
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> A part of TIME= or REGION=: empty, or 1 to 7 digits no more than
*> LS-TIME-MAX.
CHECK-TIME-PART.
    IF LS-TIME-PART = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT LS-TIME-PART TALLYING LS-TIME-N
        FOR CHARACTERS BEFORE INITIAL " "
    IF LS-TIME-N > 7
        MOVE OP-VALUE TO LS-TIME-BAD
        EXIT PARAGRAPH
    END-IF
    IF LS-TIME-PART(1:LS-TIME-N) IS NOT NUMERIC
        MOVE OP-VALUE TO LS-TIME-BAD
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION NUMVAL(LS-TIME-PART(1:LS-TIME-N)) > LS-TIME-MAX
        MOVE OP-VALUE TO LS-TIME-BAD
    END-IF.

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
    MOVE LS-JOB TO JP-JOB(LS-PROC)
    IF LS-JOB > 0
        MOVE "Y" TO JP-INSTREAM(LS-PROC)
    ELSE
        MOVE "N" TO JP-INSTREAM(LS-PROC)
        PERFORM MEMBER-NAME
    END-IF.

*> A cataloged procedure is called by its member name, not the name on
*> its PROC statement (z/OS MVS JCL Reference, "Cataloging a
*> procedure"): the file's name up to its first period, when that is a
*> name of 1 to 8 characters starting with a letter or national
*> character.
MEMBER-NAME.
    MOVE 0 TO LS-PATH-END
    PERFORM VARYING LS-PATH-I FROM LENGTH OF WS-PATH BY -1
            UNTIL LS-PATH-I = 0
        IF WS-PATH(LS-PATH-I:1) NOT = SPACE
            MOVE LS-PATH-I TO LS-PATH-END
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE 1 TO LS-PATH-START
    PERFORM VARYING LS-PATH-I FROM LS-PATH-END BY -1
            UNTIL LS-PATH-I = 0
        IF WS-PATH(LS-PATH-I:1) = "/"
            COMPUTE LS-PATH-START = LS-PATH-I + 1
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-PATH-START > LS-PATH-END
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MEMBER
    UNSTRING WS-PATH(LS-PATH-START:LS-PATH-END - LS-PATH-START + 1)
        DELIMITED BY "." INTO LS-MEMBER
    MOVE FUNCTION UPPER-CASE(LS-MEMBER) TO LS-MEMBER
    IF LS-MEMBER(9:) NOT = SPACES OR LS-MEMBER = SPACES
        EXIT PARAGRAPH
    END-IF
    IF (LS-MEMBER(1:1) >= "A" AND LS-MEMBER(1:1) <= "Z")
       OR LS-MEMBER(1:1) = "#" OR LS-MEMBER(1:1) = "@"
       OR LS-MEMBER(1:1) = "$"
        MOVE LS-MEMBER TO JP-NAME(LS-PROC)
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
    MOVE 0 TO JS-PARM-LEN(LS-STEP)
    MOVE SPACES TO JS-TIME-BAD(LS-STEP) JS-REGION-BAD(LS-STEP)
        JS-VALUE-KEY(LS-STEP) JS-VALUE-BAD(LS-STEP)
    MOVE 1 TO OP-START
    MOVE 0 TO OP-POSITION
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE TRUE
            WHEN OP-KEY = "PGM"
                MOVE "P" TO JS-KIND(LS-STEP)
                MOVE OP-VALUE TO JS-TARGET(LS-STEP)
                MOVE "P" TO LS-NM-KIND
                PERFORM CHECK-TARGET-NAME
            WHEN OP-KEY = "PROC"
                MOVE "R" TO JS-KIND(LS-STEP)
                MOVE OP-VALUE TO JS-TARGET(LS-STEP)
                MOVE "R" TO LS-NM-KIND
                PERFORM CHECK-TARGET-NAME
            WHEN OP-KEY = SPACES AND OP-POSITION = 1
                MOVE "R" TO JS-KIND(LS-STEP)
                MOVE OP-VALUE TO JS-TARGET(LS-STEP)
                MOVE "R" TO LS-NM-KIND
                PERFORM CHECK-TARGET-NAME
            WHEN OP-KEY = "PARM"
                MOVE OP-VALUE TO LS-PARM
                PERFORM COUNT-PARM
            WHEN OP-KEY = "COND"
                MOVE OP-VALUE TO JS-COND(LS-STEP)
            WHEN OP-KEY = "TIME" OR OP-KEY(1:5) = "TIME."
                MOVE "S" TO LS-TIME-OF
                PERFORM CHECK-TIME
                IF JS-TIME-BAD(LS-STEP) = SPACES
                    MOVE LS-TIME-BAD TO JS-TIME-BAD(LS-STEP)
                END-IF
            WHEN OP-KEY = "REGION" OR OP-KEY(1:7) = "REGION."
                PERFORM CHECK-REGION
                IF JS-REGION-BAD(LS-STEP) = SPACES
                    MOVE LS-TIME-BAD TO JS-REGION-BAD(LS-STEP)
                END-IF
            WHEN JS-VALUE-KEY(LS-STEP) = SPACES
                PERFORM CHECK-EXEC-VALUE
                IF LS-TIME-BAD NOT = SPACES
                    MOVE OP-KEY TO JS-VALUE-KEY(LS-STEP)
                    MOVE LS-TIME-BAD TO JS-VALUE-BAD(LS-STEP)
                END-IF
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

*> JS-PARM-LEN of the step from PARM's value, OP-VALUE. In the form
*> ('A','B') the apostrophes around each part are left out too, so
*> the count is never more than what the program is passed.
COUNT-PARM.
    COMPUTE LS-PARM-END = OP-ITEM-LEN - OP-EQ
    IF LS-PARM-END < 1
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-D
    INSPECT OP-VALUE(1:LS-PARM-END) TALLYING LS-D FOR ALL "&"
    IF LS-D > 0
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-PARM-AT
    IF LS-PARM-END > 1
        IF (OP-VALUE(1:1) = "(" AND OP-VALUE(LS-PARM-END:1) = ")")
           OR (OP-VALUE(1:1) = "'" AND OP-VALUE(LS-PARM-END:1) = "'")
            MOVE 2 TO LS-PARM-AT
            SUBTRACT 1 FROM LS-PARM-END
        END-IF
    END-IF
    MOVE 0 TO LS-PARM-COUNT
    MOVE LS-PARM-AT TO LS-D
    PERFORM UNTIL LS-D > LS-PARM-END
        IF OP-VALUE(LS-D:1) = "'"
            *> A doubled apostrophe passes one; a single one encloses.
            IF LS-D < LS-PARM-END
                IF OP-VALUE(LS-D + 1:1) = "'"
                    ADD 1 TO LS-PARM-COUNT
                    ADD 1 TO LS-D
                END-IF
            END-IF
        ELSE
            ADD 1 TO LS-PARM-COUNT
        END-IF
        ADD 1 TO LS-D
    END-PERFORM
    MOVE LS-PARM-COUNT TO JS-PARM-LEN(LS-STEP).

*> A DD of the current step. A DD without a name continues the one
*> before it (a concatenation) and gets its name; DDs before the first
*> step (JOBLIB, JOBCAT) belong to no step.
ADD-DD.
    *> Before the first EXEC of a job: a JOBLIB after another DD.
    IF LS-STEP = 0 AND LS-JOB > 0 AND LS-PROC = 0
        IF ST-NAME = "JOBLIB" AND LS-PRE-DD NOT = SPACES
           AND LS-PRE-DD NOT = "JOBLIB"
           AND JJ-JOBLIB-AFTER(LS-JOB) = SPACES
            MOVE LS-PRE-DD TO JJ-JOBLIB-AFTER(LS-JOB)
            MOVE ST-LINE TO JJ-JOBLIB-LINE(LS-JOB)
        END-IF
        IF ST-NAME NOT = SPACES
            MOVE ST-NAME TO LS-PRE-DD
        END-IF
    END-IF
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
    MOVE 0 TO JD-LRECL(LS-D) JD-BLKSIZE(LS-D) JD-DSN-AT(LS-D)
    MOVE SPACES TO JD-RECFM(LS-D) JD-DSN-PROBLEM(LS-D) JD-DSN-GEN(LS-D)
    MOVE "N" TO JD-SYSOUT(LS-D) JD-DLM(LS-D) JD-LRECL-CODED(LS-D)
        JD-RECORG(LS-D) JD-INTRDR(LS-D) LS-OUTPUT-CODED LS-SUBSYS-CODED
    MOVE SPACES TO JD-OUTPUT(LS-D)
    MOVE SPACES TO JD-RETAIN-PROBLEM(LS-D) JD-RETAIN-VALUE(LS-D)
        LS-EXPDT LS-RETPD JD-SPACE-BAD(LS-D) JD-SPACE-PART(LS-D)
        JD-DISP-BAD(LS-D) JD-DISP-PART(LS-D) JD-VALUE-KEY(LS-D)
        JD-VALUE-BAD(LS-D) JD-RECFM-BAD(LS-D) JD-CONFLICT-1(LS-D)
        JD-CONFLICT-2(LS-D)
    MOVE "N" TO LS-LRECL-KW LS-LRECL-DCB LS-RECFM-KW LS-RECFM-DCB
        LS-DSORG-DCB LS-DSNTYPE-CODED LS-FREE-CLOSE LS-AVGREC-CODED
        LS-SPACE-UNIT LS-IN-DCB
    MOVE SPACES TO JD-CLASS-BAD(LS-D)
    MOVE SPACES TO JD-SYSOUT-CLASH(LS-D) LS-NOT-WITH-SYSOUT
        LS-ONLY-WITH-SYSOUT
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
                PERFORM CHECK-DSN-NAME
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
                MOVE "Y" TO JD-SYSOUT(LS-D)
                MOVE SPACES TO LS-CLASS-TEXT
                IF OP-VALUE(1:1) = "("
                    UNSTRING OP-VALUE(2:) DELIMITED BY "," OR ")"
                        INTO LS-CLASS-TEXT
                ELSE
                    MOVE OP-VALUE TO LS-CLASS-TEXT
                END-IF
                PERFORM CHECK-OUTPUT-CLASS
                IF LS-CLASS-OK = "N"
                    MOVE LS-CLASS-TEXT TO JD-CLASS-BAD(LS-D)
                END-IF
                MOVE 0 TO LS-TIME-N
                INSPECT OP-VALUE TALLYING LS-TIME-N FOR ALL ",INTRDR"
                IF LS-TIME-N > 0
                    MOVE "Y" TO JD-INTRDR(LS-D)
                END-IF
            WHEN OP-KEY = "DLM"
                MOVE "Y" TO JD-DLM(LS-D)
            WHEN OP-KEY = "RECORG"
                MOVE "Y" TO JD-RECORG(LS-D)
            WHEN OP-KEY = "SPACE"
                PERFORM CHECK-SPACE
            WHEN OP-KEY = "EXPDT"
                MOVE OP-VALUE TO LS-EXPDT
            WHEN OP-KEY = "RETPD"
                MOVE OP-VALUE TO LS-RETPD
            WHEN OP-KEY = "DISP"
                PERFORM READ-DISP
                PERFORM CHECK-DISP
            WHEN OP-KEY = "LRECL" OR OP-KEY = "RECFM"
                 OR OP-KEY = "BLKSIZE"
                MOVE OP-KEY TO LS-DCB-KEY
                MOVE OP-VALUE TO LS-DCB-VALUE
                PERFORM DCB-PARAMETER
            WHEN OP-KEY = "DCB" AND OP-VALUE(1:1) = "("
                MOVE "Y" TO LS-IN-DCB
                PERFORM READ-DCB
                MOVE "N" TO LS-IN-DCB
            WHEN OP-KEY = SPACES AND OP-VALUE = "DUMMY"
                MOVE "M" TO JD-KIND(LS-D)
            WHEN OP-KEY = SPACES
                 AND (OP-VALUE = "*" OR OP-VALUE = "DATA")
                MOVE "I" TO JD-KIND(LS-D)
        END-EVALUATE
        PERFORM NOTE-SYSOUT-KEY
        IF JD-VALUE-KEY(LS-D) = SPACES
            PERFORM CHECK-DD-VALUE
        END-IF
        PERFORM NOTE-PAIR-KEY
        PERFORM NEXT-OPERAND
    END-PERFORM
    *> OUTPUT goes on a DD with SYSOUT or SUBSYS, and not with a SYSOUT
    *> that names the JES2 internal reader.
    IF JD-SYSOUT(LS-D) = "Y"
        MOVE LS-NOT-WITH-SYSOUT TO JD-SYSOUT-CLASH(LS-D)
        IF LS-NOT-WITH-SYSOUT = SPACES AND LS-OUTPUT-CODED = "Y"
           AND JD-INTRDR(LS-D) = "Y"
            MOVE "OUTPUT" TO JD-SYSOUT-CLASH(LS-D)
        END-IF
    ELSE
        MOVE LS-ONLY-WITH-SYSOUT TO JD-SYSOUT-CLASH(LS-D)
        IF LS-ONLY-WITH-SYSOUT = SPACES AND LS-OUTPUT-CODED = "Y"
           AND LS-SUBSYS-CODED = "N"
            MOVE "OUTPUT" TO JD-SYSOUT-CLASH(LS-D)
        END-IF
    END-IF
    IF LS-EXPDT NOT = SPACES OR LS-RETPD NOT = SPACES
        PERFORM CHECK-RETENTION
    END-IF
    PERFORM CHECK-PAIRS
    PERFORM SCAN-DD-DATA.

*> The first keyword of the DD not to code with SYSOUT, and the first
*> to code only with it (z/OS MVS JCL Reference, "Relationship to other
*> parameters" of SYSOUT, DEST, HOLD, and OUTLIM).
NOTE-SYSOUT-KEY.
    IF OP-KEY = "OUTPUT"
        MOVE "Y" TO LS-OUTPUT-CODED
        MOVE OP-VALUE TO JD-OUTPUT(LS-D)
    END-IF
    IF OP-KEY = "SUBSYS"
        MOVE "Y" TO LS-SUBSYS-CODED
    END-IF
    IF LS-NOT-WITH-SYSOUT = SPACES
        EVALUATE OP-KEY
            WHEN "AMP" WHEN "CHKPT" WHEN "DATACLAS" WHEN "DDNAME"
            WHEN "DISP" WHEN "DYNAM" WHEN "EXPDT" WHEN "LABEL"
            WHEN "LIKE" WHEN "PROTECT" WHEN "QNAME" WHEN "RETPD"
            WHEN "ROACCESS" WHEN "SUBSYS" WHEN "VOL" WHEN "VOLUME"
                MOVE OP-KEY TO LS-NOT-WITH-SYSOUT
        END-EVALUATE
    END-IF
    IF LS-ONLY-WITH-SYSOUT = SPACES
        EVALUATE OP-KEY
            WHEN "DEST" WHEN "HOLD" WHEN "OUTLIM"
                MOVE OP-KEY TO LS-ONLY-WITH-SYSOUT
        END-EVALUATE
    END-IF.

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

*> JD-DSN-PROBLEM and JD-DSN-AT for the name in OP-VALUE. Names the
*> system resolves or substitutes are not checked: temporary data sets
*> (&&NAME), symbols (&NAME, and the %% variables of schedulers),
*> backward references (*.), quoted names, and NULLFILE. A member or
*> generation in parentheses is not part of the name.
CHECK-DSN-NAME.
    IF OP-VALUE(1:2) = "*." OR OP-VALUE(1:1) = "'"
       OR OP-VALUE = "NULLFILE"
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-NAME-LEN
    INSPECT OP-VALUE TALLYING LS-NAME-LEN FOR ALL "&" ALL "%"
    IF LS-NAME-LEN > 0
        EXIT PARAGRAPH
    END-IF
    INSPECT OP-VALUE TALLYING LS-NAME-LEN
        FOR CHARACTERS BEFORE INITIAL "("
    IF LS-NAME-LEN > LENGTH OF OP-VALUE
        MOVE LENGTH OF OP-VALUE TO LS-NAME-LEN
    END-IF
    PERFORM UNTIL LS-NAME-LEN = 0
        IF OP-VALUE(LS-NAME-LEN:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-NAME-LEN
    END-PERFORM
    IF LS-NAME-LEN = 0
        EXIT PARAGRAPH
    END-IF
    IF LS-NAME-LEN > 44
        MOVE "L" TO JD-DSN-PROBLEM(LS-D)
        MOVE LS-NAME-LEN TO JD-DSN-AT(LS-D)
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO LS-QUAL-NO
    MOVE 0 TO LS-QUAL-LEN
    PERFORM VARYING LS-DSN-I FROM 1 BY 1
            UNTIL LS-DSN-I > LS-NAME-LEN + 1
        IF LS-DSN-I > LS-NAME-LEN
            MOVE "." TO LS-CHAR
        ELSE
            MOVE OP-VALUE(LS-DSN-I:1) TO LS-CHAR
        END-IF
        EVALUATE TRUE
            WHEN LS-CHAR = "."
                EVALUATE TRUE
                    WHEN LS-QUAL-LEN = 0
                        MOVE "E" TO JD-DSN-PROBLEM(LS-D)
                    WHEN LS-QUAL-LEN > 8
                        MOVE "Q" TO JD-DSN-PROBLEM(LS-D)
                END-EVALUATE
                IF JD-DSN-PROBLEM(LS-D) NOT = SPACE
                    EXIT PERFORM
                END-IF
                ADD 1 TO LS-QUAL-NO
                MOVE 0 TO LS-QUAL-LEN
            WHEN LS-QUAL-LEN = 0
                 AND NOT ((LS-CHAR >= "A" AND LS-CHAR <= "Z")
                          OR LS-CHAR = "#" OR LS-CHAR = "@"
                          OR LS-CHAR = "$")
                MOVE "F" TO JD-DSN-PROBLEM(LS-D)
                EXIT PERFORM
            WHEN (LS-CHAR >= "A" AND LS-CHAR <= "Z")
                 OR (LS-CHAR >= "0" AND LS-CHAR <= "9")
                 OR LS-CHAR = "#" OR LS-CHAR = "@" OR LS-CHAR = "$"
                 OR LS-CHAR = "-"
                ADD 1 TO LS-QUAL-LEN
            WHEN OTHER
                MOVE "C" TO JD-DSN-PROBLEM(LS-D)
                EXIT PERFORM
        END-EVALUATE
    END-PERFORM
    IF JD-DSN-PROBLEM(LS-D) NOT = SPACE
        MOVE LS-QUAL-NO TO JD-DSN-AT(LS-D)
        EXIT PARAGRAPH
    END-IF
    PERFORM CHECK-DSN-GENERATION.

*> A relative generation in the parentheses after the name: +, -, or 0
*> first, then digits, at most 3 after a sign, and at most 255 (z/OS
*> MVS JCL Reference, DSNAME). What starts with a letter or national
*> character is a member name, and is not read here.
CHECK-DSN-GENERATION.
    IF LS-NAME-LEN >= LENGTH OF OP-VALUE
        EXIT PARAGRAPH
    END-IF
    IF OP-VALUE(LS-NAME-LEN + 1:1) NOT = "("
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-GEN
    UNSTRING OP-VALUE(LS-NAME-LEN + 2:) DELIMITED BY ")" INTO LS-GEN
    MOVE 0 TO LS-GEN-LEN
    INSPECT LS-GEN TALLYING LS-GEN-LEN FOR CHARACTERS BEFORE INITIAL " "
    IF LS-GEN-LEN = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN LS-GEN(1:1) = "+" OR LS-GEN(1:1) = "-"
            IF LS-GEN-LEN < 2 OR LS-GEN-LEN > 4
                MOVE "H" TO JD-DSN-PROBLEM(LS-D)
            ELSE
                IF LS-GEN(2:LS-GEN-LEN - 1) IS NOT NUMERIC
                    MOVE "H" TO JD-DSN-PROBLEM(LS-D)
                ELSE
                    IF FUNCTION NUMVAL(LS-GEN(2:LS-GEN-LEN - 1)) > 255
                        MOVE "G" TO JD-DSN-PROBLEM(LS-D)
                    END-IF
                END-IF
            END-IF
        WHEN LS-GEN(1:1) = "0"
            IF LS-GEN-LEN > 3 OR LS-GEN(1:LS-GEN-LEN) IS NOT NUMERIC
                MOVE "H" TO JD-DSN-PROBLEM(LS-D)
            END-IF
        WHEN LS-GEN(1:1) >= "1" AND LS-GEN(1:1) <= "9"
            MOVE "H" TO JD-DSN-PROBLEM(LS-D)
    END-EVALUATE
    IF JD-DSN-PROBLEM(LS-D) NOT = SPACE
        MOVE LS-GEN TO JD-DSN-GEN(LS-D)
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

*> LRECL=n and BLKSIZE=n (numbers) and RECFM=x, of the DD or of its
*> DCB.
DCB-PARAMETER.
    IF LS-IN-DCB = "Y"
        EVALUATE LS-DCB-KEY
            WHEN "LRECL"
                MOVE "Y" TO LS-LRECL-DCB
            WHEN "RECFM"
                MOVE "Y" TO LS-RECFM-DCB
            WHEN "DSORG"
                MOVE "Y" TO LS-DSORG-DCB
        END-EVALUATE
    END-IF
    *> DCB=(DSORG=...): one of the organizations of the DCB table of the
    *> JCL Reference, PS, PSU, DA, DAU, PO, POU, CX, or GS.
    IF LS-DCB-KEY = "DSORG" AND JD-VALUE-KEY(LS-D) = SPACES
        MOVE FUNCTION TRIM(LS-DCB-VALUE) TO LS-SP-Q1
        MOVE 0 TO LS-TIME-N
        INSPECT LS-SP-Q1 TALLYING LS-TIME-N FOR ALL "&" ALL "%"
        IF LS-TIME-N = 0 AND LS-SP-Q1 NOT = "PS" AND LS-SP-Q1 NOT = "PSU"
           AND LS-SP-Q1 NOT = "DA" AND LS-SP-Q1 NOT = "DAU"
           AND LS-SP-Q1 NOT = "PO" AND LS-SP-Q1 NOT = "POU"
           AND LS-SP-Q1 NOT = "CX" AND LS-SP-Q1 NOT = "GS"
            MOVE "DSORG" TO JD-VALUE-KEY(LS-D)
            MOVE LS-SP-Q1 TO JD-VALUE-BAD(LS-D)
        END-IF
    END-IF
    EVALUATE LS-DCB-KEY
        WHEN "LRECL" WHEN "BLKSIZE"
            MOVE FUNCTION TRIM(LS-DCB-VALUE) TO LS-DCB-VALUE
            CALL "PLB-STR-LENGTH" USING LS-DCB-VALUE LS-DCB-LEN
            IF LS-DCB-LEN > 0 AND LS-DCB-LEN < 10
                IF LS-DCB-VALUE(1:LS-DCB-LEN) IS NUMERIC
                    IF LS-DCB-KEY = "LRECL"
                        COMPUTE JD-LRECL(LS-D) =
                            FUNCTION NUMVAL(LS-DCB-VALUE(1:LS-DCB-LEN))
                        MOVE "Y" TO JD-LRECL-CODED(LS-D)
                    ELSE
                        COMPUTE JD-BLKSIZE(LS-D) =
                            FUNCTION NUMVAL(LS-DCB-VALUE(1:LS-DCB-LEN))
                    END-IF
                END-IF
            END-IF
        WHEN "RECFM"
            MOVE FUNCTION TRIM(LS-DCB-VALUE) TO JD-RECFM(LS-D)
            PERFORM CHECK-RECFM
    END-EVALUATE.

*> The RECFM in LS-DCB-VALUE: one of the formats of the z/OS MVS JCL
*> Reference ("RECFM parameter", for BDAM, BPAM, BSAM, EXCP, and QSAM):
*> U, UT, F, FB, FS, FT, FBS, FBT, V, VB, VS, VT, VBS, VBT, VBST, and
*> for ISO/ANSI tapes D, DB, DS, DBS, each followed by A or M at most
*> (A only, after a D format). Values with symbols are not read.
CHECK-RECFM.
    MOVE FUNCTION TRIM(LS-DCB-VALUE) TO LS-SP-TEXT
    MOVE 0 TO LS-TIME-N
    INSPECT LS-SP-TEXT TALLYING LS-TIME-N FOR ALL "&" ALL "%"
    IF LS-TIME-N > 0 OR LS-SP-TEXT = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-TIME-N
    INSPECT LS-SP-TEXT TALLYING LS-TIME-N
        FOR CHARACTERS BEFORE INITIAL " "
    MOVE LS-SP-TEXT TO LS-SP-Q1
    *> The control character, last.
    IF LS-TIME-N > 1
        IF LS-SP-TEXT(LS-TIME-N:1) = "A"
           OR (LS-SP-TEXT(LS-TIME-N:1) = "M" AND LS-SP-TEXT(1:1) NOT = "D")
            MOVE SPACES TO LS-SP-Q1
            MOVE LS-SP-TEXT(1:LS-TIME-N - 1) TO LS-SP-Q1
        END-IF
    END-IF
    EVALUATE LS-SP-Q1
        WHEN "U" WHEN "UT" WHEN "F" WHEN "FB" WHEN "FS" WHEN "FT"
        WHEN "FBS" WHEN "FBT" WHEN "V" WHEN "VB" WHEN "VS" WHEN "VT"
        WHEN "VBS" WHEN "VBT" WHEN "VBST" WHEN "D" WHEN "DB" WHEN "DS"
        WHEN "DBS"
            CONTINUE
        WHEN OTHER
            MOVE LS-SP-TEXT TO JD-RECFM-BAD(LS-D)
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
