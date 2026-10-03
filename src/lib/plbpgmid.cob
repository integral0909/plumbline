*> ---------------------------------------------------------------
*> plbpgmid: where a source file names a program.
*>
*> PLB-FIND-PROGRAM-ID USING PATH NAME LINE COLUMN reads the file at
*> PATH, line by line, for PROGRAM-ID. NAME (NAME in upper case,
*> compared without regard to case, also as a literal: PROGRAM-ID.
*> "name"). LINE and COLUMN receive where the name starts, from 1, or
*> 0 when the file cannot be read or does not name the program. Lines
*> that are comments (*> before PROGRAM-ID, or * or / in column 7 of a
*> fixed-format line) are passed over. It reads the file as it is,
*> without COPY or REPLACE: it is for finding a program's source, as
*> the language server does for go to definition on a CALL.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-PROGRAM-ID.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT SOURCE-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  SOURCE-FILE.
01  SOURCE-RECORD           PIC X(1024).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(1024).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
LOCAL-STORAGE SECTION.
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(1024).
01  LS-AT                   PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(64).
01  LS-QUOTE                PIC X.
01  LS-DONE                 PIC X VALUE "N".
LINKAGE SECTION.
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-NAME                 PIC X ANY LENGTH.
01  LK-LINE                 PIC 9(9) COMP-5.
01  LK-COLUMN               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-PATH LK-NAME LK-LINE LK-COLUMN.
    MOVE 0 TO LK-LINE LK-COLUMN LS-LINE-NO
    MOVE LK-PATH TO WS-PATH
    OPEN INPUT SOURCE-FILE
    IF WS-STATUS NOT = "00"
        GOBACK
    END-IF
    PERFORM UNTIL LS-DONE = "Y"
        MOVE SPACES TO SOURCE-RECORD
        READ SOURCE-FILE
            AT END
                MOVE "Y" TO LS-DONE
            NOT AT END
                ADD 1 TO LS-LINE-NO
                MOVE FUNCTION UPPER-CASE(SOURCE-RECORD) TO LS-TEXT
                PERFORM CHECK-LINE
        END-READ
        IF NOT WS-READ-OK
            MOVE "Y" TO LS-DONE
        END-IF
    END-PERFORM
    CLOSE SOURCE-FILE
    GOBACK.

*> PROGRAM-ID on this line, not in a comment, naming LK-NAME.
CHECK-LINE.
    MOVE 0 TO LS-AT
    INSPECT LS-TEXT TALLYING LS-AT FOR CHARACTERS BEFORE "PROGRAM-ID"
    IF LS-AT >= 1014
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-AT
    IF LS-TEXT(7:1) = "*" OR LS-TEXT(7:1) = "/"
        IF LS-AT > 7
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE 0 TO LS-P
    INSPECT LS-TEXT(1:LS-AT) TALLYING LS-P FOR ALL "*>"
    IF LS-P > 0
        EXIT PARAGRAPH
    END-IF
    *> After PROGRAM-ID: the period, then blanks, then the name.
    COMPUTE LS-P = LS-AT + 10
    IF LS-TEXT(LS-P:1) = "."
        ADD 1 TO LS-P
    END-IF
    PERFORM UNTIL LS-P > 1024
        IF LS-TEXT(LS-P:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-P
    END-PERFORM
    IF LS-P > 1024
        EXIT PARAGRAPH
    END-IF
    MOVE SPACE TO LS-QUOTE
    IF LS-TEXT(LS-P:1) = '"' OR LS-TEXT(LS-P:1) = "'"
        MOVE LS-TEXT(LS-P:1) TO LS-QUOTE
        ADD 1 TO LS-P
    END-IF
    MOVE LS-P TO LS-Q
    PERFORM UNTIL LS-Q > 1024
        IF LS-QUOTE NOT = SPACE
            IF LS-TEXT(LS-Q:1) = LS-QUOTE
                EXIT PERFORM
            END-IF
        ELSE
            IF LS-TEXT(LS-Q:1) = SPACE OR LS-TEXT(LS-Q:1) = "."
                EXIT PERFORM
            END-IF
        END-IF
        ADD 1 TO LS-Q
    END-PERFORM
    IF LS-Q = LS-P OR LS-Q - LS-P > 64
        EXIT PARAGRAPH
    END-IF
    MOVE LS-TEXT(LS-P:LS-Q - LS-P) TO LS-NAME
    IF LS-NAME = FUNCTION UPPER-CASE(LK-NAME)
        MOVE LS-LINE-NO TO LK-LINE
        MOVE LS-P TO LK-COLUMN
        MOVE "Y" TO LS-DONE
    END-IF.
END PROGRAM PLB-FIND-PROGRAM-ID.
