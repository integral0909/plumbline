*> ---------------------------------------------------------------
*> plbims: reading IMS database and program specifications.
*>
*> DBD and PSB sources are assembler macros (read by plbasm):
*>
*>     DBD     NAME=DBPAUTP0,ACCESS=(HIDAM,VSAM)
*>     SEGM    NAME=PAUTSUM0,PARENT=0,BYTES=100
*>     FIELD   NAME=(ACCNTID,SEQ,U),START=1,BYTES=6,TYPE=P
*>     ...
*>     PCB     TYPE=DB,DBDNAME=DBPAUTP0,PROCOPT=AP,KEYLEN=14
*>     SENSEG  NAME=PAUTSUM0,PARENT=0
*>     PSBGEN  LANG=COBOL,PSBNAME=PSBPAUTB
*>
*> A DBD statement starts a database, and SEGM and FIELD statements
*> add to it. PCB statements start a PSB, which PSBGEN names and ends;
*> SENSEG statements add to the PCB before them. END ends the source.
*> ---------------------------------------------------------------

*> PLB-IMS-INIT: an empty model.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-IMS-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbimsc.cpy".
COPY "plbims.cpy".
PROCEDURE DIVISION USING PLB-IMS.
    MOVE 0 TO XD-COUNT XG-COUNT XF-COUNT XP-COUNT XC-COUNT XS-COUNT
    GOBACK.
END PROGRAM PLB-IMS-INIT.

*> PLB-IMS-READ: add the DBDs and PSBs of file PATH, as file FILE-ID of
*> the run, to the model. STATUS receives 0, or 1 when the file cannot
*> be opened or read.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-IMS-READ.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbasms.cpy".
LOCAL-STORAGE SECTION.
01  LS-DBD                  PIC 9(9) COMP-5 VALUE 0.
01  LS-SEGMENT              PIC 9(9) COMP-5 VALUE 0.
01  LS-PSB                  PIC 9(9) COMP-5 VALUE 0.
01  LS-PCB                  PIC 9(9) COMP-5 VALUE 0.
01  LS-ENDED                PIC X VALUE "N".
01  OP-START                PIC 9(4) COMP-5.
01  OP-KEY                  PIC X(8).
01  OP-VALUE                PIC X(4000).
01  OP-ITEM-LEN             PIC 9(4) COMP-5.
01  OP-KEEP-CASE            PIC X VALUE "N".
*> The first name in a value: NAME, (NAME,...), ((NAME,...)).
01  LS-FIRST-NAME           PIC X(8).
01  LS-REST                 PIC X(100).
01  LS-NUMBER               PIC 9(9) COMP-5.
01  LS-PATH                 PIC X(1024).
01  LS-I                    PIC 9(9) COMP-5.
01  LS-SLASH                PIC 9(9) COMP-5.
01  LS-DOT                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbimsc.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-FILE-ID              PIC 9(4) COMP-5.
COPY "plbims.cpy".
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-FILE-ID PLB-IMS LK-STATUS.
    MOVE 0 TO LK-STATUS
    CALL "PLB-ASM-READER" USING "O" LK-PATH PLB-ASM-STATEMENT
    PERFORM UNTIL AT-STATUS NOT = 0 OR LS-ENDED = "Y"
        PERFORM DO-STATEMENT
        CALL "PLB-ASM-READER" USING "N" LK-PATH PLB-ASM-STATEMENT
    END-PERFORM
    IF AT-STATUS = 2
        MOVE 1 TO LK-STATUS
    END-IF
    CALL "PLB-ASM-READER" USING "C" LK-PATH PLB-ASM-STATEMENT
    *> A PSB that PSBGEN does not name takes the file's name.
    IF LS-PSB > 0
        IF XP-NAME(LS-PSB) = SPACES
            PERFORM NAME-FROM-FILE
        END-IF
    END-IF
    GOBACK.

DO-STATEMENT.
    EVALUATE AT-OP
        WHEN "DBD"
            PERFORM ADD-DBD
        WHEN "SEGM"
            PERFORM ADD-SEGMENT
        WHEN "FIELD"
            PERFORM ADD-FIELD
        WHEN "PCB"
            PERFORM ADD-PCB
        WHEN "SENSEG"
            PERFORM ADD-SENSEG
        WHEN "PSBGEN"
            PERFORM END-PSB
        WHEN "END"
            MOVE "Y" TO LS-ENDED
    END-EVALUATE.

ADD-DBD.
    MOVE 0 TO LS-DBD LS-SEGMENT
    IF XD-COUNT >= XD-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO XD-COUNT
    MOVE XD-COUNT TO LS-DBD
    MOVE SPACES TO XD-NAME(LS-DBD) XD-ACCESS(LS-DBD)
    MOVE LK-FILE-ID TO XD-FILE-ID(LS-DBD)
    MOVE AT-LINE TO XD-LINE(LS-DBD)
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE OP-KEY
            WHEN "NAME"
                MOVE OP-VALUE TO XD-NAME(LS-DBD)
            WHEN "ACCESS"
                PERFORM FIRST-NAME
                MOVE LS-FIRST-NAME TO XD-ACCESS(LS-DBD)
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM.

ADD-SEGMENT.
    MOVE 0 TO LS-SEGMENT
    IF LS-DBD = 0 OR XG-COUNT >= XG-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO XG-COUNT
    MOVE XG-COUNT TO LS-SEGMENT
    MOVE LS-DBD TO XG-DBD(LS-SEGMENT)
    MOVE SPACES TO XG-NAME(LS-SEGMENT) XG-PARENT(LS-SEGMENT)
    MOVE 0 TO XG-BYTES(LS-SEGMENT)
    MOVE LK-FILE-ID TO XG-FILE-ID(LS-SEGMENT)
    MOVE AT-LINE TO XG-LINE(LS-SEGMENT)
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE OP-KEY
            WHEN "NAME"
                PERFORM FIRST-NAME
                MOVE LS-FIRST-NAME TO XG-NAME(LS-SEGMENT)
            WHEN "PARENT"
                PERFORM FIRST-NAME
                IF LS-FIRST-NAME NOT = "0"
                    MOVE LS-FIRST-NAME TO XG-PARENT(LS-SEGMENT)
                END-IF
            WHEN "BYTES"
                PERFORM FIRST-NUMBER
                MOVE LS-NUMBER TO XG-BYTES(LS-SEGMENT)
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM.

ADD-FIELD.
    IF LS-SEGMENT = 0 OR XF-COUNT >= XF-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO XF-COUNT
    MOVE LS-SEGMENT TO XF-SEGMENT(XF-COUNT)
    MOVE SPACES TO XF-NAME(XF-COUNT)
    MOVE "N" TO XF-SEQUENCE(XF-COUNT)
    MOVE 0 TO XF-START(XF-COUNT) XF-BYTES(XF-COUNT)
    MOVE AT-LINE TO XF-LINE(XF-COUNT)
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE OP-KEY
            WHEN "NAME"
                PERFORM FIRST-NAME
                MOVE LS-FIRST-NAME TO XF-NAME(XF-COUNT)
                MOVE 0 TO LS-I
                INSPECT OP-VALUE TALLYING LS-I FOR ALL ",SEQ"
                IF LS-I > 0
                    MOVE "Y" TO XF-SEQUENCE(XF-COUNT)
                END-IF
            WHEN "START"
                PERFORM FIRST-NUMBER
                MOVE LS-NUMBER TO XF-START(XF-COUNT)
            WHEN "BYTES"
                PERFORM FIRST-NUMBER
                MOVE LS-NUMBER TO XF-BYTES(XF-COUNT)
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM.

*> PCB: in the PSB being read, or a new one.
ADD-PCB.
    MOVE 0 TO LS-PCB
    IF LS-PSB = 0
        IF XP-COUNT >= XP-MAX
            EXIT PARAGRAPH
        END-IF
        ADD 1 TO XP-COUNT
        MOVE XP-COUNT TO LS-PSB
        MOVE SPACES TO XP-NAME(LS-PSB)
        MOVE LK-FILE-ID TO XP-FILE-ID(LS-PSB)
        MOVE AT-LINE TO XP-LINE(LS-PSB)
    END-IF
    IF XC-COUNT >= XC-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO XC-COUNT
    MOVE XC-COUNT TO LS-PCB
    MOVE LS-PSB TO XC-PSB(LS-PCB)
    MOVE AT-NAME TO XC-NAME(LS-PCB)
    MOVE SPACES TO XC-TYPE(LS-PCB) XC-DBD(LS-PCB) XC-PROCOPT(LS-PCB)
    MOVE LK-FILE-ID TO XC-FILE-ID(LS-PCB)
    MOVE AT-LINE TO XC-LINE(LS-PCB)
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE OP-KEY
            WHEN "TYPE"
                MOVE OP-VALUE TO XC-TYPE(LS-PCB)
            WHEN "DBDNAME"
                MOVE OP-VALUE TO XC-DBD(LS-PCB)
            WHEN "PROCOPT"
                MOVE OP-VALUE TO XC-PROCOPT(LS-PCB)
            WHEN "PCBNAME"
                MOVE OP-VALUE TO XC-NAME(LS-PCB)
            WHEN SPACES
                *> PCB TYPE=DB,name,...: the DBD as a positional operand.
                IF XC-DBD(LS-PCB) = SPACES AND XC-TYPE(LS-PCB) = "DB"
                    MOVE OP-VALUE TO XC-DBD(LS-PCB)
                END-IF
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM
    *> GSAM is a PCB of TYPE=GSAM; PROCOPT defaults to A.
    IF XC-PROCOPT(LS-PCB) = SPACES AND XC-TYPE(LS-PCB) NOT = "TP"
        MOVE "A" TO XC-PROCOPT(LS-PCB)
    END-IF.

ADD-SENSEG.
    IF LS-PCB = 0 OR XS-COUNT >= XS-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO XS-COUNT
    MOVE LS-PCB TO XS-PCB(XS-COUNT)
    MOVE SPACES TO XS-NAME(XS-COUNT) XS-PARENT(XS-COUNT)
    MOVE LK-FILE-ID TO XS-FILE-ID(XS-COUNT)
    MOVE AT-LINE TO XS-LINE(XS-COUNT)
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        EVALUATE OP-KEY
            WHEN "NAME"
                PERFORM FIRST-NAME
                MOVE LS-FIRST-NAME TO XS-NAME(XS-COUNT)
            WHEN "PARENT"
                PERFORM FIRST-NAME
                IF LS-FIRST-NAME NOT = "0"
                    MOVE LS-FIRST-NAME TO XS-PARENT(XS-COUNT)
                END-IF
            WHEN SPACES
                *> SENSEG name,parent as positional operands.
                IF XS-NAME(XS-COUNT) = SPACES
                    MOVE OP-VALUE TO XS-NAME(XS-COUNT)
                ELSE
                    IF XS-PARENT(XS-COUNT) = SPACES
                       AND OP-VALUE NOT = "0"
                        MOVE OP-VALUE TO XS-PARENT(XS-COUNT)
                    END-IF
                END-IF
        END-EVALUATE
        PERFORM NEXT-OPERAND
    END-PERFORM.

*> PSBGEN PSBNAME=name ends the PSB.
END-PSB.
    IF LS-PSB = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO OP-START
    PERFORM NEXT-OPERAND
    PERFORM UNTIL OP-ITEM-LEN = 0
        IF OP-KEY = "PSBNAME"
            MOVE OP-VALUE TO XP-NAME(LS-PSB)
        END-IF
        PERFORM NEXT-OPERAND
    END-PERFORM
    IF XP-NAME(LS-PSB) = SPACES
        PERFORM NAME-FROM-FILE
    END-IF
    MOVE 0 TO LS-PSB LS-PCB.

*> XP-NAME(LS-PSB) = the file's name, without directory or extension.
NAME-FROM-FILE.
    MOVE LK-PATH TO LS-PATH
    CALL "PLB-STR-LENGTH" USING LS-PATH LS-LEN
    MOVE 0 TO LS-SLASH LS-DOT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        IF LS-PATH(LS-I:1) = "/"
            MOVE LS-I TO LS-SLASH
            MOVE 0 TO LS-DOT
        END-IF
        IF LS-PATH(LS-I:1) = "."
            MOVE LS-I TO LS-DOT
        END-IF
    END-PERFORM
    IF LS-DOT = 0
        COMPUTE LS-DOT = LS-LEN + 1
    END-IF
    IF LS-DOT > LS-SLASH + 1
        MOVE FUNCTION UPPER-CASE(LS-PATH(LS-SLASH + 1:
                                         LS-DOT - LS-SLASH - 1))
            TO XP-NAME(LS-PSB)
    END-IF.

*> LS-FIRST-NAME = the first name of OP-VALUE, inside any parentheses.
FIRST-NAME.
    MOVE SPACES TO LS-FIRST-NAME LS-REST
    MOVE OP-VALUE(1:100) TO LS-REST
    INSPECT LS-REST REPLACING ALL "(" BY SPACE
    UNSTRING FUNCTION TRIM(LS-REST) DELIMITED BY "," OR ")" OR SPACE
        INTO LS-FIRST-NAME.

*> LS-NUMBER = the first number of OP-VALUE, as for FIRST-NAME; 0 when
*> it is not a number.
FIRST-NUMBER.
    MOVE 0 TO LS-NUMBER
    PERFORM FIRST-NAME
    IF LS-FIRST-NAME NOT = SPACES
       AND FUNCTION TRIM(LS-FIRST-NAME) IS NUMERIC
        MOVE FUNCTION NUMVAL(LS-FIRST-NAME) TO LS-NUMBER
    END-IF.

NEXT-OPERAND.
    CALL "PLB-ASM-OPERAND" USING PLB-ASM-STATEMENT OP-START OP-KEY
        OP-VALUE OP-ITEM-LEN OP-KEEP-CASE.
END PROGRAM PLB-IMS-READ.
