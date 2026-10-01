*> ---------------------------------------------------------------
*> plbbase: baselines, the findings a project has accepted for now.
*>
*>   PLB-BASELINE-KEY    the baseline line for one finding
*>   PLB-BASELINE-WRITE  write the findings not suppressed to a file
*>   PLB-BASELINE-APPLY  mark the findings a baseline file lists
*>
*> A baseline file is text. The first line is the header
*>     # plumbline baseline 1
*> and every other line that does not start with # is one finding:
*>     RULE | FILE | MESSAGE | SOURCE
*> where SOURCE is the text of the reported line with its spaces
*> collapsed (a line is at most 1200 characters, so very long source
*> lines are cut). The fields are not split again when the file is
*> read: a finding matches a line when its line is exactly the same.
*> (Tabs would be clearer separators, but line sequential files may
*> not contain them.) Line numbers are not part of it, so a finding still
*> matches after lines are added or removed above it; a change to the
*> line itself, or to what the finding says, makes it new.
*>
*> Each line matches one finding, so a line that two findings share
*> must be in the baseline twice. Baselined findings are marked "B"
*> in FN-SUPPRESSED and are left out of reports like suppressed ones.
*>
*> Diagnostics:
*>   BL001  error  cannot open or write the baseline file
*>   BL002  error  the file is not a Plumbline baseline
*>   BL003  error  too many lines in the baseline (the rest is ignored)
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-BASELINE-KEY.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-TAB                  PIC X VALUE X"09".
LOCAL-STORAGE SECTION.
01  LS-PATH                 PIC X(512).
01  LS-LINE                 PIC X(1024).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-START                PIC 9(9) COMP-5.
01  LS-SPACE                PIC X.
01  LS-RULE-LEN             PIC 9(9) COMP-5.
01  LS-SRC-LINE             PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-KEY                  PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-RULES PLB-FINDINGS
        LK-INDEX LK-KEY.
    MOVE SPACES TO LK-KEY
    MOVE 1 TO LS-PTR
    CALL "PLB-STR-LENGTH" USING RL-ID(FN-RULE(LK-INDEX)) LS-RULE-LEN
    IF LS-RULE-LEN > 0
        STRING RL-ID(FN-RULE(LK-INDEX))(1:LS-RULE-LEN) DELIMITED BY SIZE
            INTO LK-KEY WITH POINTER LS-PTR
    END-IF
    STRING " | " DELIMITED BY SIZE INTO LK-KEY WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET FN-FILE-ID(LK-INDEX)
        LS-PATH
    CALL "PLB-STR-LENGTH" USING LS-PATH LS-LEN
    IF LS-LEN > 0
        STRING LS-PATH(1:LS-LEN) DELIMITED BY SIZE
            INTO LK-KEY WITH POINTER LS-PTR
    END-IF
    STRING " | " DELIMITED BY SIZE INTO LK-KEY WITH POINTER LS-PTR
    CALL "PLB-STR-LENGTH" USING FN-MESSAGE(LK-INDEX) LS-LEN
    IF LS-LEN > 0
        STRING FN-MESSAGE(LK-INDEX)(1:LS-LEN) DELIMITED BY SIZE
            INTO LK-KEY WITH POINTER LS-PTR
    END-IF
    STRING " | " DELIMITED BY SIZE INTO LK-KEY WITH POINTER LS-PTR
    CALL "PLB-SRC-LINE-INDEX" USING PLB-SOURCE-SET FN-FILE-ID(LK-INDEX)
        FN-LINE(LK-INDEX) LS-SRC-LINE
    IF LS-SRC-LINE = 0
        GOBACK
    END-IF
    CALL "PLB-SRC-LINE-CONTENT" USING PLB-SOURCE-SET LS-SRC-LINE
        LS-LINE LS-LEN
    *> The line's text with runs of spaces and tabs as one space, and
    *> none at either end.
    MOVE LS-PTR TO LS-START
    MOVE "Y" TO LS-SPACE
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        IF LS-LINE(LS-I:1) = SPACE OR LS-LINE(LS-I:1) = WS-TAB
            MOVE "Y" TO LS-SPACE
        ELSE
            IF LS-SPACE = "Y" AND LS-PTR > LS-START
                STRING " " DELIMITED BY SIZE
                    INTO LK-KEY WITH POINTER LS-PTR
            END-IF
            MOVE "N" TO LS-SPACE
            STRING LS-LINE(LS-I:1) DELIMITED BY SIZE
                INTO LK-KEY WITH POINTER LS-PTR
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-BASELINE-KEY.

*> PLB-BASELINE-WRITE: write a baseline of every finding that is not
*> suppressed to PATH; COUNT is how many were written. Reports BL001
*> when the file cannot be written.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-BASELINE-WRITE.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT BASELINE-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  BASELINE-FILE.
01  BASELINE-RECORD         PIC X(1200).
WORKING-STORAGE SECTION.
01  WS-PATH                 PIC X(512).
01  WS-STATUS               PIC XX.
01  WS-KEY                  PIC X(1200).
01  WS-LEN                  PIC 9(9) COMP-5.
01  WS-I                    PIC 9(9) COMP-5.
01  WS-NO-POSITION          PIC 9(9) COMP-5 VALUE 0.
01  WS-NO-FILE              PIC 9(4) COMP-5 VALUE 0.
01  WS-NO-COLUMN            PIC 9(4) COMP-5 VALUE 0.
01  WS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-COUNT                PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS LK-PATH LK-COUNT.
    MOVE 0 TO LK-COUNT
    MOVE LK-PATH TO WS-PATH
    OPEN OUTPUT BASELINE-FILE
    IF WS-STATUS NOT = "00"
        PERFORM REPORT-WRITE-ERROR
        GOBACK
    END-IF
    MOVE "# plumbline baseline 1" TO BASELINE-RECORD
    WRITE BASELINE-RECORD
    IF WS-STATUS NOT = "00"
        PERFORM REPORT-WRITE-ERROR
        CLOSE BASELINE-FILE
        GOBACK
    END-IF
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N"
            CALL "PLB-BASELINE-KEY" USING PLB-SOURCE-SET PLB-RULES
                PLB-FINDINGS WS-I WS-KEY
            CALL "PLB-STR-LENGTH" USING WS-KEY WS-LEN
            WRITE BASELINE-RECORD FROM WS-KEY(1:WS-LEN)
            IF WS-STATUS NOT = "00"
                PERFORM REPORT-WRITE-ERROR
                EXIT PERFORM
            END-IF
            ADD 1 TO LK-COUNT
        END-IF
    END-PERFORM
    CLOSE BASELINE-FILE
    GOBACK.

REPORT-WRITE-ERROR.
    MOVE SPACES TO WS-MESSAGE
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-LEN
    STRING "cannot write baseline " DELIMITED BY SIZE
           WS-PATH(1:WS-LEN) DELIMITED BY SIZE
           " (file status " DELIMITED BY SIZE
           WS-STATUS DELIMITED BY SIZE
           ")" DELIMITED BY SIZE
        INTO WS-MESSAGE
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "BL001" WS-NO-FILE
        WS-NO-POSITION WS-NO-COLUMN WS-MESSAGE.
END PROGRAM PLB-BASELINE-WRITE.

*> PLB-BASELINE-APPLY: mark with "B" every finding not suppressed
*> that baseline PATH lists; COUNT is how many were marked.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-BASELINE-APPLY.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT BASELINE-FILE ASSIGN TO WS-PATH
        ORGANIZATION IS LINE SEQUENTIAL
        FILE STATUS IS WS-STATUS.
DATA DIVISION.
FILE SECTION.
FD  BASELINE-FILE.
01  BASELINE-RECORD         PIC X(1200).
WORKING-STORAGE SECTION.
78  BE-MAX                  VALUE 10000.
01  WS-PATH                 PIC X(512).
01  WS-STATUS               PIC XX.
    88  WS-READ-OK                VALUE "00" "04" "06".
01  WS-ENTRIES.
    05  WS-ENTRY-COUNT      PIC 9(9) COMP-5.
    05  WS-ENTRY            OCCURS 0 TO BE-MAX TIMES
                            DEPENDING ON WS-ENTRY-COUNT
                            ASCENDING KEY WS-ENTRY-KEY
                            INDEXED BY WS-X.
        10  WS-ENTRY-KEY    PIC X(1200).
        10  WS-ENTRY-USED   PIC X.
01  WS-KEY                  PIC X(1200).
01  WS-LEN                  PIC 9(9) COMP-5.
01  WS-I                    PIC 9(9) COMP-5.
01  WS-J                    PIC 9(9) COMP-5.
01  WS-FIRST                PIC X.
01  WS-FOUND                PIC X.
01  WS-NO-POSITION          PIC 9(9) COMP-5 VALUE 0.
01  WS-NO-FILE              PIC 9(4) COMP-5 VALUE 0.
01  WS-NO-COLUMN            PIC 9(4) COMP-5 VALUE 0.
01  WS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-COUNT                PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS LK-PATH LK-COUNT.
    MOVE 0 TO LK-COUNT
    MOVE LK-PATH TO WS-PATH
    PERFORM LOAD-ENTRIES
    IF WS-ENTRY-COUNT = 0
        GOBACK
    END-IF
    SORT WS-ENTRY ON ASCENDING KEY WS-ENTRY-KEY
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N"
            CALL "PLB-BASELINE-KEY" USING PLB-SOURCE-SET PLB-RULES
                PLB-FINDINGS WS-I WS-KEY
            PERFORM CLAIM-ENTRY
            IF WS-FOUND = "Y"
                MOVE "B" TO FN-SUPPRESSED(WS-I)
                ADD 1 TO LK-COUNT
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

LOAD-ENTRIES.
    MOVE 0 TO WS-ENTRY-COUNT
    OPEN INPUT BASELINE-FILE
    IF WS-STATUS NOT = "00"
        MOVE "cannot open baseline " TO WS-MESSAGE
        PERFORM REPORT-FILE-ERROR
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO WS-FIRST
    PERFORM UNTIL EXIT
        MOVE SPACES TO BASELINE-RECORD
        READ BASELINE-FILE
            AT END
                EXIT PERFORM
        END-READ
        IF NOT WS-READ-OK
            MOVE "cannot read baseline " TO WS-MESSAGE
            PERFORM REPORT-FILE-ERROR
            EXIT PERFORM
        END-IF
        IF WS-FIRST = "Y"
            MOVE "N" TO WS-FIRST
            IF BASELINE-RECORD NOT = "# plumbline baseline 1"
                PERFORM REPORT-NOT-A-BASELINE
                EXIT PERFORM
            END-IF
        ELSE
            IF BASELINE-RECORD(1:1) NOT = "#"
               AND BASELINE-RECORD NOT = SPACES
                IF WS-ENTRY-COUNT >= BE-MAX
                    PERFORM REPORT-TOO-MANY
                    EXIT PERFORM
                END-IF
                ADD 1 TO WS-ENTRY-COUNT
                MOVE BASELINE-RECORD TO WS-ENTRY-KEY(WS-ENTRY-COUNT)
                MOVE "N" TO WS-ENTRY-USED(WS-ENTRY-COUNT)
            END-IF
        END-IF
    END-PERFORM
    CLOSE BASELINE-FILE.

*> WS-FOUND = "Y" when an unused entry equals WS-KEY; that entry is
*> then used. Equal entries are next to each other once sorted.
CLAIM-ENTRY.
    MOVE "N" TO WS-FOUND
    SEARCH ALL WS-ENTRY
        AT END
            EXIT PARAGRAPH
        WHEN WS-ENTRY-KEY(WS-X) = WS-KEY
            SET WS-J TO WS-X
    END-SEARCH
    PERFORM UNTIL WS-J <= 1
        IF WS-ENTRY-KEY(WS-J - 1) NOT = WS-KEY
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM WS-J
    END-PERFORM
    PERFORM UNTIL WS-J > WS-ENTRY-COUNT
        IF WS-ENTRY-KEY(WS-J) NOT = WS-KEY
            EXIT PERFORM
        END-IF
        IF WS-ENTRY-USED(WS-J) = "N"
            MOVE "Y" TO WS-ENTRY-USED(WS-J)
            MOVE "Y" TO WS-FOUND
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-J
    END-PERFORM.

*> WS-MESSAGE holds the start of the message.
REPORT-FILE-ERROR.
    *> After the message and one space.
    CALL "PLB-STR-LENGTH" USING WS-MESSAGE WS-LEN
    ADD 2 TO WS-LEN
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-I
    STRING WS-PATH(1:WS-I) DELIMITED BY SIZE
           " (file status " DELIMITED BY SIZE
           WS-STATUS DELIMITED BY SIZE
           ")" DELIMITED BY SIZE
        INTO WS-MESSAGE WITH POINTER WS-LEN
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "BL001" WS-NO-FILE
        WS-NO-POSITION WS-NO-COLUMN WS-MESSAGE.

REPORT-NOT-A-BASELINE.
    MOVE SPACES TO WS-MESSAGE
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-I
    STRING WS-PATH(1:WS-I) DELIMITED BY SIZE
           " is not a Plumbline baseline (no '# plumbline baseline 1'"
           DELIMITED BY SIZE
           " header)" DELIMITED BY SIZE
        INTO WS-MESSAGE
    MOVE 0 TO WS-ENTRY-COUNT
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "BL002" WS-NO-FILE
        WS-NO-POSITION WS-NO-COLUMN WS-MESSAGE.

REPORT-TOO-MANY.
    MOVE SPACES TO WS-MESSAGE
    STRING "baseline has more than " DELIMITED BY SIZE
           BE-MAX DELIMITED BY SIZE
           " findings; the rest are ignored" DELIMITED BY SIZE
        INTO WS-MESSAGE
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "BL003" WS-NO-FILE
        WS-NO-POSITION WS-NO-COLUMN WS-MESSAGE.
END PROGRAM PLB-BASELINE-APPLY.
