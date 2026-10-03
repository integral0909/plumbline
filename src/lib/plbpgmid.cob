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

*> ---------------------------------------------------------------
*> PLB-FIND-PROGRAM-USING USING PATH LINE USING-TEXT: the text after
*> PROCEDURE DIVISION, up to its period, of the program whose
*> PROGRAM-ID is on line LINE of the file at PATH (as
*> PLB-FIND-PROGRAM-ID finds it): "USING LK-ID LK-NAME" for a program
*> that takes parameters, spaces for one that takes none or when the
*> header is not found. Blanks are made single, comment lines are
*> passed over, and the text may run over several lines.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-PROGRAM-USING.
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
01  WS-LINE-NO              PIC 9(9) COMP-5.
01  WS-TEXT                 PIC X(1024).
01  WS-AT                   PIC 9(9) COMP-5.
01  WS-P                    PIC 9(9) COMP-5.
01  WS-OUT-PTR              PIC 9(9) COMP-5.
01  WS-STATE                PIC X.
    88  WS-LOOKING                VALUE "L".
    88  WS-TAKING                 VALUE "T".
    88  WS-DONE                   VALUE "D".
01  WS-PENDING-BLANK        PIC X.
01  WS-END                  PIC 9(9) COMP-5.
LINKAGE SECTION.
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-LINE                 PIC 9(9) COMP-5.
01  LK-USING                PIC X ANY LENGTH.
PROCEDURE DIVISION USING LK-PATH LK-LINE LK-USING.
    MOVE SPACES TO LK-USING
    MOVE 1 TO WS-OUT-PTR
    MOVE 0 TO WS-LINE-NO
    MOVE "N" TO WS-PENDING-BLANK
    SET WS-LOOKING TO TRUE
    MOVE LK-PATH TO WS-PATH
    OPEN INPUT SOURCE-FILE
    IF WS-STATUS NOT = "00"
        GOBACK
    END-IF
    PERFORM UNTIL WS-DONE
        MOVE SPACES TO SOURCE-RECORD
        READ SOURCE-FILE
            AT END
                SET WS-DONE TO TRUE
            NOT AT END
                ADD 1 TO WS-LINE-NO
                IF WS-LINE-NO >= LK-LINE
                    MOVE FUNCTION UPPER-CASE(SOURCE-RECORD) TO WS-TEXT
                    PERFORM READ-LINE
                END-IF
        END-READ
        IF NOT WS-READ-OK
            SET WS-DONE TO TRUE
        END-IF
    END-PERFORM
    CLOSE SOURCE-FILE
    GOBACK.

*> Comment lines are passed over; otherwise the header is looked for,
*> or the text after it taken.
READ-LINE.
    IF WS-TEXT(7:1) = "*" OR WS-TEXT(7:1) = "/"
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO WS-P
    IF WS-LOOKING
        MOVE 0 TO WS-AT
        INSPECT WS-TEXT TALLYING WS-AT
            FOR CHARACTERS BEFORE "PROCEDURE DIVISION"
        IF WS-AT >= 1000
            EXIT PARAGRAPH
        END-IF
        MOVE 0 TO WS-P
        INSPECT WS-TEXT(1:WS-AT + 1) TALLYING WS-P FOR ALL "*>"
        IF WS-P > 0
            EXIT PARAGRAPH
        END-IF
        SET WS-TAKING TO TRUE
        COMPUTE WS-P = WS-AT + 19
    END-IF
    PERFORM TAKE-TEXT.

*> Characters from WS-P to the period, or to the end of the line or an
*> inline comment. A line with a sequence area (blank or numeric
*> columns 1 to 6) and text past column 72 ends at column 72: the
*> rest is the identification area of fixed format.
TAKE-TEXT.
    CALL "PLB-STR-LENGTH" USING WS-TEXT WS-END
    IF WS-END > 72
        IF WS-TEXT(1:6) = SPACES OR WS-TEXT(1:6) IS NUMERIC
            MOVE 72 TO WS-END
        END-IF
    END-IF
    PERFORM UNTIL WS-P > WS-END
        IF WS-TEXT(WS-P:1) = "."
            SET WS-DONE TO TRUE
            EXIT PERFORM
        END-IF
        IF WS-P < WS-END
            IF WS-TEXT(WS-P:2) = "*>"
                EXIT PERFORM
            END-IF
        END-IF
        IF WS-TEXT(WS-P:1) = SPACE
            MOVE "Y" TO WS-PENDING-BLANK
        ELSE
            IF WS-PENDING-BLANK = "Y" AND WS-OUT-PTR > 1
               AND WS-OUT-PTR < FUNCTION LENGTH(LK-USING)
                STRING " " DELIMITED BY SIZE
                    INTO LK-USING WITH POINTER WS-OUT-PTR
            END-IF
            MOVE "N" TO WS-PENDING-BLANK
            IF WS-OUT-PTR <= FUNCTION LENGTH(LK-USING)
                STRING WS-TEXT(WS-P:1) DELIMITED BY SIZE
                    INTO LK-USING WITH POINTER WS-OUT-PTR
            END-IF
        END-IF
        ADD 1 TO WS-P
    END-PERFORM
    *> The next line's text follows after a blank.
    MOVE "Y" TO WS-PENDING-BLANK.
END PROGRAM PLB-FIND-PROGRAM-USING.
