*> ---------------------------------------------------------------
*> plbcsd: reading CICS resource definitions.
*>
*> The input of DFHCSDUP, the program that loads the CICS system
*> definition file: commands such as
*>
*>     DEFINE TRANSACTION(CC00) GROUP(CARDDEMO)
*>            PROGRAM(COSGN00C) TWASIZE(0)
*>
*> A command runs from its verb (DEFINE, ADD, ALTER, ...) to the next
*> one, over as many lines as it needs. Its words stand alone or take
*> a value in parentheses, which may hold spaces and parentheses of its
*> own (DESCRIPTION(CARD TO ACCOUNT XREF)). Lines starting with * are
*> comments. Only DEFINE is kept: the type and name of each resource,
*> its group, and for a transaction its program.
*> ---------------------------------------------------------------

*> PLB-CSD-INIT: an empty model.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CSD-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbcsdc.cpy".
COPY "plbcsd.cpy".
PROCEDURE DIVISION USING PLB-CSD.
    MOVE 0 TO CR-COUNT
    GOBACK.
END PROGRAM PLB-CSD-INIT.

*> PLB-CSD-READ: add the definitions of file PATH, as file FILE-ID of
*> the run, to the model. STATUS receives 0, or 1 when the file cannot
*> be opened or read.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CSD-READ.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT CSD-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  CSD-FILE.
01  CSD-RECORD              PIC X(256).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(1024).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
    88  WS-AT-END                 VALUE "10".
LOCAL-STORAGE SECTION.
01  LS-DONE                 PIC X VALUE "N".
01  LS-LINE-NO              PIC 9(9) COMP-5 VALUE 0.
01  LS-TEXT                 PIC X(256).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-P                    PIC 9(4) COMP-5.
*> The word being read, and its value: WORD(VALUE).
01  WD-ACTIVE               PIC X VALUE "N".
01  WD-WORD                 PIC X(31).
01  WD-WORD-LEN             PIC 9(4) COMP-5.
01  WD-VALUE                PIC X(256).
01  WD-VALUE-LEN            PIC 9(4) COMP-5.
01  WD-DEPTH                PIC 9(4) COMP-5.
01  WD-LINE                 PIC 9(9) COMP-5.
*> The command being read: "D" for DEFINE, "O" for another, space
*> before the first.
01  CM-KIND                 PIC X VALUE SPACE.
01  CM-WORDS                PIC 9(4) COMP-5.
01  LS-R                    PIC 9(9) COMP-5 VALUE 0.
LINKAGE SECTION.
COPY "plbcsdc.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-FILE-ID              PIC 9(4) COMP-5.
COPY "plbcsd.cpy".
01  LK-STATUS               PIC 9(4) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-FILE-ID PLB-CSD LK-STATUS.
    MOVE 0 TO LK-STATUS
    MOVE LK-PATH TO WS-PATH
    OPEN INPUT CSD-FILE
    IF WS-STATUS NOT = "00"
        MOVE 1 TO LK-STATUS
        GOBACK
    END-IF
    PERFORM UNTIL LS-DONE = "Y"
        MOVE SPACES TO CSD-RECORD
        READ CSD-FILE
        EVALUATE TRUE
            WHEN WS-READ-OK
                ADD 1 TO LS-LINE-NO
                MOVE CSD-RECORD TO LS-TEXT
                PERFORM READ-LINE
            WHEN WS-AT-END
                MOVE "Y" TO LS-DONE
            WHEN OTHER
                MOVE 1 TO LK-STATUS
                MOVE "Y" TO LS-DONE
        END-EVALUATE
    END-PERFORM
    CLOSE CSD-FILE
    IF WD-ACTIVE = "Y"
        PERFORM FINISH-WORD
    END-IF
    GOBACK.

*> Characters of the line, into words and values. A value in
*> parentheses runs on over line ends.
READ-LINE.
    IF WD-DEPTH = 0 AND LS-TEXT(1:1) = "*"
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-STR-LENGTH" USING LS-TEXT LS-LEN
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > LS-LEN
        EVALUATE TRUE
            WHEN WD-DEPTH > 0
                IF LS-TEXT(LS-P:1) = ")"
                    SUBTRACT 1 FROM WD-DEPTH
                END-IF
                IF LS-TEXT(LS-P:1) = "("
                    ADD 1 TO WD-DEPTH
                END-IF
                IF WD-DEPTH > 0 AND WD-VALUE-LEN < 256
                    ADD 1 TO WD-VALUE-LEN
                    MOVE LS-TEXT(LS-P:1) TO WD-VALUE(WD-VALUE-LEN:1)
                END-IF
                IF WD-DEPTH = 0
                    PERFORM FINISH-WORD
                END-IF
            WHEN LS-TEXT(LS-P:1) = SPACE OR LS-TEXT(LS-P:1) = ","
                IF WD-ACTIVE = "Y"
                    PERFORM FINISH-WORD
                END-IF
            WHEN LS-TEXT(LS-P:1) = "("
                IF WD-ACTIVE = "N"
                    PERFORM START-WORD
                END-IF
                MOVE 1 TO WD-DEPTH
            WHEN OTHER
                IF WD-ACTIVE = "N"
                    PERFORM START-WORD
                END-IF
                IF WD-WORD-LEN < 31
                    ADD 1 TO WD-WORD-LEN
                    MOVE FUNCTION UPPER-CASE(LS-TEXT(LS-P:1))
                        TO WD-WORD(WD-WORD-LEN:1)
                END-IF
        END-EVALUATE
    END-PERFORM
    *> A word without a value ends with its line.
    IF WD-ACTIVE = "Y" AND WD-DEPTH = 0
        PERFORM FINISH-WORD
    END-IF.

START-WORD.
    MOVE "Y" TO WD-ACTIVE
    MOVE SPACES TO WD-WORD WD-VALUE
    MOVE 0 TO WD-WORD-LEN WD-VALUE-LEN WD-DEPTH
    MOVE LS-LINE-NO TO WD-LINE.

*> A whole word, with its value if it has one: a command verb starts
*> a command; the first word after DEFINE names the resource; the
*> others are its attributes.
FINISH-WORD.
    MOVE "N" TO WD-ACTIVE
    IF WD-VALUE-LEN = 0
        EVALUATE WD-WORD
            WHEN "DEFINE"
                MOVE "D" TO CM-KIND
                MOVE 0 TO CM-WORDS LS-R
                EXIT PARAGRAPH
            WHEN "ADD" WHEN "ALTER" WHEN "APPEND" WHEN "COPY"
            WHEN "DELETE" WHEN "INITIALIZE" WHEN "LIST" WHEN "REMOVE"
            WHEN "SERVICE" WHEN "UPGRADE" WHEN "USERDEFINE"
            WHEN "VERIFY" WHEN "CHECK" WHEN "EXTRACT" WHEN "MIGRATE"
            WHEN "PROCESS" WHEN "SCAN"
                MOVE "O" TO CM-KIND
                MOVE 0 TO LS-R
                EXIT PARAGRAPH
        END-EVALUATE
    END-IF
    IF CM-KIND NOT = "D"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CM-WORDS
    IF CM-WORDS = 1
        PERFORM ADD-RESOURCE
        EXIT PARAGRAPH
    END-IF
    IF LS-R = 0
        EXIT PARAGRAPH
    END-IF
    EVALUATE WD-WORD
        WHEN "GROUP"
            MOVE FUNCTION UPPER-CASE(WD-VALUE) TO CR-GROUP(LS-R)
        WHEN "PROGRAM"
            IF CR-TYPE(LS-R) = "TRANSACTION"
                MOVE FUNCTION UPPER-CASE(WD-VALUE) TO CR-TARGET(LS-R)
            END-IF
        WHEN "DSNAME"
            IF CR-TYPE(LS-R) = "FILE"
                MOVE FUNCTION UPPER-CASE(WD-VALUE) TO CR-TARGET(LS-R)
            END-IF
    END-EVALUATE.

*> DEFINE TYPE(NAME).
ADD-RESOURCE.
    MOVE 0 TO LS-R
    IF WD-VALUE-LEN = 0 OR CR-COUNT >= CR-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CR-COUNT
    MOVE CR-COUNT TO LS-R
    MOVE WD-WORD TO CR-TYPE(LS-R)
    MOVE FUNCTION UPPER-CASE(WD-VALUE) TO CR-NAME(LS-R)
    MOVE SPACES TO CR-GROUP(LS-R) CR-TARGET(LS-R)
    MOVE LK-FILE-ID TO CR-FILE-ID(LS-R)
    MOVE WD-LINE TO CR-LINE(LS-R).
END PROGRAM PLB-CSD-READ.
