*> ---------------------------------------------------------------
*> plbdiff: report only the findings on the lines a change touches.
*>
*> PLB-DIFF-APPLY USING SOURCE DIAGNOSTICS FINDINGS PATH COUNT reads
*> the unified diff at PATH (as git diff writes it, with any number of
*> context lines) and marks with "D" every finding not suppressed that
*> is not on a line the diff adds or changes; COUNT is how many were
*> marked. Reports leave the marked findings out, and they do not fail
*> the run, as with a baseline: a project can then hold new and changed
*> code to the rules before the old code is clean.
*>
*>     git diff -U0 origin/main > changes.diff
*>     plumbline check --diff changes.diff src/*.cbl
*>
*> The new side's path of each file (+++ b/src/pay.cbl) is matched with
*> the path of the finding's file as the run names it, whole or as its
*> end after a slash, so a diff from the repository's root matches
*> files named from there or from above it. Lines are those of the new
*> side: a "+" line is added or changed; a " " line is context, and a
*> "-" line is gone. Findings in files the diff does not touch are all
*> marked. Diagnostics are not filtered.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DIFF-APPLY.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT DIFF-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  DIFF-FILE.
01  DIFF-RECORD             PIC X(2048).
WORKING-STORAGE SECTION.
78  DF-MAX                  VALUE 200000.
78  DP-MAX                  VALUE 5000.
01  WS-PATH                 PIC X(512).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
*> The files of the diff (new side), and the lines it adds or changes.
01  WS-FILES.
    05  WS-FILE-COUNT       PIC 9(9) COMP-5.
    05  WS-FILE-PATH        PIC X(512) OCCURS DP-MAX TIMES.
01  WS-LINES.
    05  WS-LINE-COUNT       PIC 9(9) COMP-5.
    05  WS-LINE-ENTRY       OCCURS DF-MAX TIMES.
        10  WS-LINE-FILE    PIC 9(9) COMP-5.
        10  WS-LINE-NO      PIC 9(9) COMP-5.
*> Where the diff is: the file (0 before the first, or /dev/null); in
*> a hunk, the next line number of the new side, and how many lines of
*> the old and the new side are still to come (both 0: not in a hunk).
01  WS-CURRENT-FILE         PIC 9(9) COMP-5.
01  WS-NEW-LINE             PIC 9(9) COMP-5.
01  WS-OLD-LEFT             PIC 9(9) COMP-5.
01  WS-NEW-LEFT             PIC 9(9) COMP-5.
01  WS-NEW-PATH             PIC X(512).
01  WS-RANGE                PIC X(40).
01  WS-START-TEXT           PIC X(20).
01  WS-COUNT-TEXT           PIC X(20).
01  WS-NUMBER               PIC 9(9) COMP-5.
01  WS-I                    PIC 9(9) COMP-5.
01  WS-J                    PIC 9(9) COMP-5.
01  WS-P                    PIC 9(9) COMP-5.
01  WS-LEN                  PIC 9(9) COMP-5.
01  WS-NUM-TEXT             PIC X(20).
01  WS-FINDING-PATH         PIC X(512).
01  WS-FINDING-LEN          PIC 9(9) COMP-5.
01  WS-DIFF-LEN             PIC 9(9) COMP-5.
01  WS-FILE-MATCH           PIC 9(9) COMP-5.
01  WS-KEEP                 PIC X.
01  WS-NO-POSITION          PIC 9(9) COMP-5 VALUE 0.
01  WS-NO-FILE              PIC 9(4) COMP-5 VALUE 0.
01  WS-NO-COLUMN            PIC 9(4) COMP-5 VALUE 0.
01  WS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbfind.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-COUNT                PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-FINDINGS
        LK-PATH LK-COUNT.
    MOVE 0 TO LK-COUNT WS-FILE-COUNT WS-LINE-COUNT WS-CURRENT-FILE
        WS-NEW-LINE WS-OLD-LEFT WS-NEW-LEFT
    MOVE LK-PATH TO WS-PATH
    OPEN INPUT DIFF-FILE
    IF WS-STATUS NOT = "00"
        PERFORM REPORT-OPEN-ERROR
        GOBACK
    END-IF
    PERFORM UNTIL EXIT
        MOVE SPACES TO DIFF-RECORD
        READ DIFF-FILE
            AT END
                EXIT PERFORM
        END-READ
        IF NOT WS-READ-OK
            EXIT PERFORM
        END-IF
        PERFORM READ-DIFF-LINE
    END-PERFORM
    CLOSE DIFF-FILE
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N"
            PERFORM TEST-FINDING
            IF WS-KEEP = "N"
                MOVE "D" TO FN-SUPPRESSED(WS-I)
                ADD 1 TO LK-COUNT
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> One line of the diff: in a hunk, a line of it; outside, a new file
*> or a hunk header. A hunk ends when its lines are all read, so a
*> line of it that starts with "+++" is not taken for a file.
READ-DIFF-LINE.
    IF WS-OLD-LEFT > 0 OR WS-NEW-LEFT > 0
        EVALUATE DIFF-RECORD(1:1)
            WHEN "+"
                IF WS-CURRENT-FILE > 0
                    PERFORM ADD-LINE
                END-IF
                ADD 1 TO WS-NEW-LINE
                IF WS-NEW-LEFT > 0
                    SUBTRACT 1 FROM WS-NEW-LEFT
                END-IF
            WHEN "-"
                IF WS-OLD-LEFT > 0
                    SUBTRACT 1 FROM WS-OLD-LEFT
                END-IF
            WHEN "\"
                *> \ No newline at end of file
                CONTINUE
            WHEN OTHER
                ADD 1 TO WS-NEW-LINE
                IF WS-NEW-LEFT > 0
                    SUBTRACT 1 FROM WS-NEW-LEFT
                END-IF
                IF WS-OLD-LEFT > 0
                    SUBTRACT 1 FROM WS-OLD-LEFT
                END-IF
        END-EVALUATE
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN DIFF-RECORD(1:4) = "+++ "
            PERFORM NEW-FILE
        WHEN DIFF-RECORD(1:3) = "@@ "
            PERFORM HUNK-HEADER
    END-EVALUATE.

*> +++ b/PATH (or +++ PATH, or +++ /dev/null), up to a tab.
NEW-FILE.
    MOVE 0 TO WS-CURRENT-FILE
    MOVE SPACES TO WS-NEW-PATH
    UNSTRING DIFF-RECORD(5:) DELIMITED BY X"09" INTO WS-NEW-PATH
    IF WS-NEW-PATH = "/dev/null"
        EXIT PARAGRAPH
    END-IF
    IF WS-FILE-COUNT >= DP-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-FILE-COUNT
    IF WS-NEW-PATH(1:2) = "b/"
        MOVE WS-NEW-PATH(3:) TO WS-FILE-PATH(WS-FILE-COUNT)
    ELSE
        MOVE WS-NEW-PATH TO WS-FILE-PATH(WS-FILE-COUNT)
    END-IF
    MOVE WS-FILE-COUNT TO WS-CURRENT-FILE.

*> @@ -a[,b] +c[,d] @@: the old side has b lines (1 when not given),
*> the new side d lines from line c.
HUNK-HEADER.
    MOVE 0 TO WS-P
    INSPECT DIFF-RECORD TALLYING WS-P FOR CHARACTERS BEFORE " -"
    IF WS-P < 2040
        COMPUTE WS-P = WS-P + 3
        PERFORM READ-RANGE
        MOVE WS-NUMBER TO WS-OLD-LEFT
    END-IF
    MOVE 0 TO WS-P
    INSPECT DIFF-RECORD TALLYING WS-P FOR CHARACTERS BEFORE " +"
    IF WS-P < 2040
        COMPUTE WS-P = WS-P + 3
        PERFORM READ-RANGE
        MOVE WS-NUMBER TO WS-NEW-LEFT
        MOVE WS-START-TEXT TO WS-NUM-TEXT
        PERFORM TEXT-NUMBER
        MOVE WS-NUMBER TO WS-NEW-LINE
    END-IF.

*> START[,COUNT] at WS-P: WS-START-TEXT, and in WS-NUMBER the count.
READ-RANGE.
    MOVE SPACES TO WS-RANGE WS-START-TEXT WS-COUNT-TEXT
    UNSTRING DIFF-RECORD(WS-P:) DELIMITED BY " " INTO WS-RANGE
    UNSTRING WS-RANGE DELIMITED BY ","
        INTO WS-START-TEXT WS-COUNT-TEXT
    IF WS-COUNT-TEXT = SPACES
        MOVE 1 TO WS-NUMBER
    ELSE
        MOVE WS-COUNT-TEXT TO WS-NUM-TEXT
        PERFORM TEXT-NUMBER
    END-IF.

*> WS-NUMBER: the digits in WS-NUM-TEXT, or 0.
TEXT-NUMBER.
    MOVE 0 TO WS-NUMBER
    CALL "PLB-STR-LENGTH" USING WS-NUM-TEXT WS-LEN
    IF WS-LEN > 0 AND WS-LEN < 10
        IF WS-NUM-TEXT(1:WS-LEN) IS NUMERIC
            COMPUTE WS-NUMBER = FUNCTION NUMVAL(WS-NUM-TEXT(1:WS-LEN))
        END-IF
    END-IF.

ADD-LINE.
    IF WS-LINE-COUNT < DF-MAX
        ADD 1 TO WS-LINE-COUNT
        MOVE WS-CURRENT-FILE TO WS-LINE-FILE(WS-LINE-COUNT)
        MOVE WS-NEW-LINE TO WS-LINE-NO(WS-LINE-COUNT)
    END-IF.

*> WS-KEEP = "Y" when finding WS-I is on a line the diff adds, in a
*> file of the diff that is the finding's file.
TEST-FINDING.
    MOVE "N" TO WS-KEEP
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET FN-FILE-ID(WS-I)
        WS-FINDING-PATH
    CALL "PLB-STR-LENGTH" USING WS-FINDING-PATH WS-FINDING-LEN
    IF WS-FINDING-LEN = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > WS-LINE-COUNT
        IF WS-LINE-NO(WS-J) = FN-LINE(WS-I)
            MOVE WS-LINE-FILE(WS-J) TO WS-FILE-MATCH
            PERFORM TEST-SAME-FILE
            IF WS-KEEP = "Y"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> WS-KEEP = "Y" when diff file WS-FILE-MATCH is the finding's file:
*> the same path, or one path the end of the other after a slash.
TEST-SAME-FILE.
    CALL "PLB-STR-LENGTH" USING WS-FILE-PATH(WS-FILE-MATCH)
        WS-DIFF-LEN
    EVALUATE TRUE
        WHEN WS-DIFF-LEN = 0
            CONTINUE
        WHEN WS-DIFF-LEN = WS-FINDING-LEN
            IF WS-FILE-PATH(WS-FILE-MATCH)(1:WS-DIFF-LEN)
               = WS-FINDING-PATH(1:WS-FINDING-LEN)
                MOVE "Y" TO WS-KEEP
            END-IF
        WHEN WS-DIFF-LEN < WS-FINDING-LEN
            COMPUTE WS-P = WS-FINDING-LEN - WS-DIFF-LEN
            IF WS-FINDING-PATH(WS-P:1) = "/"
               AND WS-FINDING-PATH(WS-P + 1:WS-DIFF-LEN)
                   = WS-FILE-PATH(WS-FILE-MATCH)(1:WS-DIFF-LEN)
                MOVE "Y" TO WS-KEEP
            END-IF
        WHEN OTHER
            COMPUTE WS-P = WS-DIFF-LEN - WS-FINDING-LEN
            IF WS-FILE-PATH(WS-FILE-MATCH)(WS-P:1) = "/"
               AND WS-FILE-PATH(WS-FILE-MATCH)(WS-P + 1:WS-FINDING-LEN)
                   = WS-FINDING-PATH(1:WS-FINDING-LEN)
                MOVE "Y" TO WS-KEEP
            END-IF
    END-EVALUATE.

REPORT-OPEN-ERROR.
    MOVE SPACES TO WS-MESSAGE
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-LEN
    STRING "cannot open diff " DELIMITED BY SIZE
           WS-PATH(1:WS-LEN) DELIMITED BY SIZE
           " (file status " DELIMITED BY SIZE
           WS-STATUS DELIMITED BY SIZE
           ")" DELIMITED BY SIZE
        INTO WS-MESSAGE
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "DF001" WS-NO-FILE
        WS-NO-POSITION WS-NO-COLUMN WS-MESSAGE.
END PROGRAM PLB-DIFF-APPLY.
