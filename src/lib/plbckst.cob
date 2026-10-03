*> ---------------------------------------------------------------
*> plbckst: the findings of plumbline check as a Checkstyle XML report.
*>
*> PLB-REPORT-CHECKSTYLE USING SOURCE DIAGNOSTICS RULES FINDINGS
*> MAIN-FILES writes to standard output the XML format of the
*> Checkstyle tool, which code review tools (reviewdog), CI plugins
*> (Jenkins Warnings NG), and editors read from many linters:
*>
*>   <checkstyle version="4.3">
*>     <file name="src/a.cob">
*>       <error line="12" column="8" severity="warning"
*>              message="..." source="plumbline.PLB-C011"/>
*>     </file>
*>     <file name="src/b.cob"/>
*>   </checkstyle>
*>
*> One file element for each file with findings or diagnostics, in the
*> order of the findings (sorted by file), and one, empty, for each of
*> the first MAIN-FILES files (those named on the command line) with
*> neither. Severities are error, warning, and info (for notes); a
*> diagnostic's source is plumbline.CODE. Suppressed and baselined
*> findings are left out, as in the other reports.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REPORT-CHECKSTYLE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
*> "Y" for a file written already.
01  WS-FILE-DONE            PIC X OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-FILE                 PIC 9(4) COMP-5.
01  LS-PATH                 PIC X(512).
01  LS-PATH-LEN             PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(1024).
01  LS-TEXT-LEN             PIC 9(9) COMP-5.
01  LS-OUT                  PIC X(8192).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-SEVERITY             PIC X(7).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-MAIN-FILES           PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS LK-MAIN-FILES.
    PERFORM VARYING LS-FILE FROM 1 BY 1 UNTIL LS-FILE > SS-FILE-COUNT
        MOVE "N" TO WS-FILE-DONE(LS-FILE)
    END-PERFORM
    DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
    DISPLAY '<checkstyle version="4.3">'
    *> Files with findings, then diagnostics of files with none.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            MOVE FN-FILE-ID(LS-I) TO LS-FILE
            IF LS-FILE > 0 AND LS-FILE <= SS-FILE-COUNT
                IF WS-FILE-DONE(LS-FILE) = "N"
                    PERFORM WRITE-FILE
                END-IF
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > DG-COUNT
        MOVE DG-FILE-ID(LS-J) TO LS-FILE
        IF LS-FILE > 0 AND LS-FILE <= SS-FILE-COUNT
            IF WS-FILE-DONE(LS-FILE) = "N"
                PERFORM WRITE-FILE
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-FILE FROM 1 BY 1
            UNTIL LS-FILE > LK-MAIN-FILES OR LS-FILE > SS-FILE-COUNT
        IF WS-FILE-DONE(LS-FILE) = "N"
            MOVE "Y" TO WS-FILE-DONE(LS-FILE)
            PERFORM START-FILE
            STRING '"/>' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    DISPLAY "</checkstyle>"
    GOBACK.

*> File LS-FILE with all its findings and diagnostics.
WRITE-FILE.
    MOVE "Y" TO WS-FILE-DONE(LS-FILE)
    PERFORM START-FILE
    STRING '">' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    *> The findings are sorted by file: the file's are together, from
    *> the one that brought it here (none, for a diagnostic's file).
    IF LS-I <= FN-COUNT
        PERFORM VARYING LS-K FROM LS-I BY 1 UNTIL LS-K > FN-COUNT
            IF FN-FILE-ID(LS-K) NOT = LS-FILE
                EXIT PERFORM
            END-IF
            IF FN-SUPPRESSED(LS-K) = "N"
                PERFORM WRITE-FINDING
            END-IF
        END-PERFORM
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > DG-COUNT
        IF DG-FILE-ID(LS-D) = LS-FILE
            PERFORM WRITE-DIAGNOSTIC
        END-IF
    END-PERFORM
    DISPLAY "  </file>".

*>   <file name="PATH
START-FILE.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-FILE LS-PATH
    CALL "PLB-STR-LENGTH" USING LS-PATH LS-PATH-LEN
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING '  <file name="' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-XML-TEXT" USING LS-PATH LS-PATH-LEN LS-OUT LS-PTR.

WRITE-FINDING.
    MOVE FN-SEVERITY(LS-K) TO LS-SEVERITY
    MOVE FN-LINE(LS-K) TO LS-NUM
    PERFORM START-ERROR
    MOVE FN-COLUMN(LS-K) TO LS-NUM
    PERFORM APPEND-COLUMN
    MOVE FN-MESSAGE(LS-K) TO LS-TEXT
    PERFORM APPEND-MESSAGE
    STRING RL-ID(FN-RULE(LS-K)) DELIMITED BY SPACE
           '"/>' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

WRITE-DIAGNOSTIC.
    MOVE DG-SEVERITY(LS-D) TO LS-SEVERITY
    MOVE DG-LINE(LS-D) TO LS-NUM
    PERFORM START-ERROR
    MOVE DG-COLUMN(LS-D) TO LS-NUM
    PERFORM APPEND-COLUMN
    MOVE DG-MESSAGE(LS-D) TO LS-TEXT
    PERFORM APPEND-MESSAGE
    STRING DG-CODE(LS-D) DELIMITED BY SPACE
           '"/>' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

*>     <error line="N"
START-ERROR.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR
    STRING '    <error line="' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-NUM
    STRING '"' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR.

*>  column="N" (left out when unknown)
APPEND-COLUMN.
    IF LS-NUM > 0
        STRING ' column="' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        PERFORM APPEND-NUM
        STRING '"' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF.

*>  severity="S" message="M" source="plumbline.
APPEND-MESSAGE.
    EVALUATE LS-SEVERITY(1:1)
        WHEN "E"   MOVE "error" TO LS-SEVERITY
        WHEN "W"   MOVE "warning" TO LS-SEVERITY
        WHEN OTHER MOVE "info" TO LS-SEVERITY
    END-EVALUATE
    STRING ' severity="' DELIMITED BY SIZE
           LS-SEVERITY DELIMITED BY SPACE
           '" message="' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-STR-LENGTH" USING LS-TEXT LS-TEXT-LEN
    CALL "PLB-XML-TEXT" USING LS-TEXT LS-TEXT-LEN LS-OUT LS-PTR
    STRING '" source="' PLB-NAME "." DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

PRINT-OUT.
    DISPLAY LS-OUT(1:LS-PTR - 1).
END PROGRAM PLB-REPORT-CHECKSTYLE.
