*> ---------------------------------------------------------------
*> plblist: reading the list of files to analyze from a file.
*>
*> A list file has one path per line. Leading and trailing spaces are
*> not part of the path, and blank lines and lines starting with # are
*> skipped, so that
*>
*>     find src -name '*.cbl' | plumbline check --files-from -
*>
*> and a hand-written list both work. "-" reads the list from
*> standard input, with ACCEPT: a file opened on /dev/stdin draws a
*> warning from libcob when it is closed on a pipe.
*> ---------------------------------------------------------------

*> PLB-INPUTS-READ-LIST: append the paths listed in file LIST to the
*> inputs. STATUS receives
*>   0  the whole list was read
*>   1  the list cannot be opened or read
*>   2  more paths than IP-MAX in all; those that fit were added
*>   3  a path longer than IP-PATH-SIZE on line LINE; nothing after it
*>      was added
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-INPUTS-READ-LIST.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT LIST-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  LIST-FILE.
01  LIST-RECORD             PIC X(1024).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(1024).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
    88  WS-AT-END                 VALUE "10".
LOCAL-STORAGE SECTION.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-DONE                 PIC X VALUE "N".
01  LS-ENTRY                PIC X(1024).
LINKAGE SECTION.
01  LK-LIST                 PIC X ANY LENGTH.
COPY "plbinput.cpy".
01  LK-STATUS               PIC 9(4) COMP-5.
01  LK-LINE                 PIC 9(9) COMP-5.
PROCEDURE DIVISION USING LK-LIST PLB-INPUTS LK-STATUS LK-LINE.
    MOVE 0 TO LK-STATUS LK-LINE
    IF LK-LIST = "-"
        PERFORM READ-STANDARD-INPUT
    ELSE
        PERFORM READ-LIST-FILE
    END-IF
    GOBACK.

READ-LIST-FILE.
    MOVE LK-LIST TO WS-PATH
    OPEN INPUT LIST-FILE
    IF WS-STATUS NOT = "00"
        MOVE 1 TO LK-STATUS
        EXIT PARAGRAPH
    END-IF
    PERFORM UNTIL LS-DONE = "Y"
        READ LIST-FILE INTO LS-ENTRY
        EVALUATE TRUE
            WHEN WS-READ-OK
                ADD 1 TO LK-LINE
                *> A line longer than the record comes back in pieces
                *> with status 06; such a path is too long anyway.
                IF WS-STATUS = "06"
                    MOVE 3 TO LK-STATUS
                    MOVE "Y" TO LS-DONE
                ELSE
                    PERFORM ADD-LISTED-PATH
                END-IF
            WHEN WS-AT-END
                MOVE "Y" TO LS-DONE
            WHEN OTHER
                MOVE 1 TO LK-STATUS
                MOVE "Y" TO LS-DONE
        END-EVALUATE
    END-PERFORM
    CLOSE LIST-FILE.

*> At the end of the input ACCEPT raises its exception; a last line
*> without a newline is in LS-ENTRY then.
READ-STANDARD-INPUT.
    PERFORM UNTIL LS-DONE = "Y"
        MOVE SPACES TO LS-ENTRY
        ACCEPT LS-ENTRY
            ON EXCEPTION
                MOVE "Y" TO LS-DONE
        END-ACCEPT
        IF LS-DONE = "N" OR LS-ENTRY NOT = SPACES
            ADD 1 TO LK-LINE
            PERFORM ADD-LISTED-PATH
        END-IF
    END-PERFORM.

*> The path on the line in LS-ENTRY, if any.
ADD-LISTED-PATH.
    CALL "PLB-STR-LENGTH" USING LS-ENTRY LS-LEN
    IF LS-LEN = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-FIRST
    INSPECT LS-ENTRY(1:LS-LEN) TALLYING LS-FIRST
        FOR LEADING SPACES
    ADD 1 TO LS-FIRST
    IF LS-ENTRY(LS-FIRST:1) = "#"
        EXIT PARAGRAPH
    END-IF
    IF LS-LEN - LS-FIRST + 1 > IP-PATH-SIZE
        MOVE 3 TO LK-STATUS
        MOVE "Y" TO LS-DONE
        EXIT PARAGRAPH
    END-IF
    IF IP-COUNT >= IP-MAX
        MOVE 2 TO LK-STATUS
        MOVE "Y" TO LS-DONE
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO IP-COUNT
    MOVE LS-ENTRY(LS-FIRST:LS-LEN - LS-FIRST + 1)
        TO IP-PATH(IP-COUNT).
END PROGRAM PLB-INPUTS-READ-LIST.
