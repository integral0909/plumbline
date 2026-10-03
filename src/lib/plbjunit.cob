*> ---------------------------------------------------------------
*> plbjunit: the findings of plumbline check as a JUnit XML report.
*>
*> PLB-REPORT-JUNIT USING SOURCE DIAGNOSTICS RULES FINDINGS MAIN-FILES
*> writes to standard output the form of test report that Jenkins,
*> GitLab, Azure DevOps, and most other CI servers show:
*>
*>   <testsuites name="plumbline" tests="3" failures="1" errors="1">
*>     <testsuite name="plumbline check" tests="3" ...>
*>       <testcase classname="src/a.cob"
*>                 name="PLB-C011 read-never-set at 12:8">
*>         <failure type="warning" message="...">src/a.cob:12:8:
*>           warning: ... [PLB-C011]</failure>
*>       </testcase>
*>       <testcase classname="src/a.cob" name="PS008 at 30:12">
*>         <error type="error" message="...">...</error>
*>       </testcase>
*>       <testcase classname="src/b.cob" name="no findings"/>
*>     </testsuite>
*>   </testsuites>
*>
*> Each finding is a test case that fails, and each diagnostic one
*> that fails with an error when the diagnostic is an error. Each of
*> the first MAIN-FILES files (the files named on the command line)
*> with neither has one test case that passes, so the report also
*> shows what was checked. Suppressed and baselined findings are left
*> out, as in the other reports. Text is escaped for XML by
*> PLB-XML-TEXT.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REPORT-JUNIT.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> "Y" for a file with a finding or diagnostic.
01  WS-FILE-HIT             PIC X OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-FILE                 PIC 9(4) COMP-5.
01  LS-R                    PIC 9(4) COMP-5.
01  LS-TESTS                PIC 9(9) COMP-5.
01  LS-FAILURES             PIC 9(9) COMP-5.
01  LS-ERRORS               PIC 9(9) COMP-5.
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
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(9) COMP-5.
*> The test case being written: "failure" or "error".
01  LS-ELEMENT              PIC X(7).
01  LS-MESSAGE              PIC X(200).
01  LS-TAG                  PIC X(8).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-MAIN-FILES           PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS LK-MAIN-FILES.
    PERFORM COUNT-TESTS
    DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
    PERFORM START-OUT
    STRING '<testsuites name="plumbline"' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-COUNTS
    STRING ">" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    PERFORM START-OUT
    STRING '  <testsuite name="plumbline check"' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM APPEND-COUNTS
    STRING ">" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            PERFORM WRITE-FINDING
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DG-COUNT
        PERFORM WRITE-DIAGNOSTIC
    END-PERFORM
    PERFORM VARYING LS-FILE FROM 1 BY 1
            UNTIL LS-FILE > LK-MAIN-FILES OR LS-FILE > SS-FILE-COUNT
        IF WS-FILE-HIT(LS-FILE) = "N"
            PERFORM WRITE-PASSED
        END-IF
    END-PERFORM
    DISPLAY "  </testsuite>"
    DISPLAY "</testsuites>"
    GOBACK.

*> The test cases: one per finding and diagnostic, and one per main
*> file with neither.
COUNT-TESTS.
    MOVE 0 TO LS-TESTS LS-FAILURES LS-ERRORS
    PERFORM VARYING LS-FILE FROM 1 BY 1 UNTIL LS-FILE > SS-FILE-COUNT
        MOVE "N" TO WS-FILE-HIT(LS-FILE)
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            ADD 1 TO LS-TESTS LS-FAILURES
            MOVE FN-FILE-ID(LS-I) TO LS-FILE
            PERFORM MARK-FILE
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DG-COUNT
        ADD 1 TO LS-TESTS
        IF DG-IS-ERROR(LS-I)
            ADD 1 TO LS-ERRORS
        ELSE
            ADD 1 TO LS-FAILURES
        END-IF
        MOVE DG-FILE-ID(LS-I) TO LS-FILE
        PERFORM MARK-FILE
    END-PERFORM
    PERFORM VARYING LS-FILE FROM 1 BY 1
            UNTIL LS-FILE > LK-MAIN-FILES OR LS-FILE > SS-FILE-COUNT
        IF WS-FILE-HIT(LS-FILE) = "N"
            ADD 1 TO LS-TESTS
        END-IF
    END-PERFORM.

MARK-FILE.
    IF LS-FILE > 0 AND LS-FILE <= SS-FILE-COUNT
        MOVE "Y" TO WS-FILE-HIT(LS-FILE)
    END-IF.

*>  tests="T" failures="F" errors="E"
APPEND-COUNTS.
    STRING ' tests="' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-TESTS TO LS-NUM
    PERFORM APPEND-NUM
    STRING '" failures="' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-FAILURES TO LS-NUM
    PERFORM APPEND-NUM
    STRING '" errors="' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-ERRORS TO LS-NUM
    PERFORM APPEND-NUM
    STRING '"' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR.

WRITE-FINDING.
    MOVE FN-RULE(LS-I) TO LS-R
    MOVE FN-FILE-ID(LS-I) TO LS-FILE
    MOVE FN-LINE(LS-I) TO LS-LINE
    MOVE FN-COLUMN(LS-I) TO LS-COLUMN
    MOVE FN-MESSAGE(LS-I) TO LS-MESSAGE
    MOVE FN-SEVERITY(LS-I) TO LS-SEVERITY
    PERFORM SEVERITY-WORD
    MOVE "failure" TO LS-ELEMENT
    MOVE RL-ID(LS-R) TO LS-TAG
    PERFORM START-CASE
    STRING RL-ID(LS-R) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
           RL-NAME(LS-R) DELIMITED BY SPACE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM FINISH-CASE.

WRITE-DIAGNOSTIC.
    MOVE DG-FILE-ID(LS-I) TO LS-FILE
    MOVE DG-LINE(LS-I) TO LS-LINE
    MOVE DG-COLUMN(LS-I) TO LS-COLUMN
    MOVE DG-MESSAGE(LS-I) TO LS-MESSAGE
    MOVE DG-SEVERITY(LS-I) TO LS-SEVERITY
    PERFORM SEVERITY-WORD
    IF DG-IS-ERROR(LS-I)
        MOVE "error" TO LS-ELEMENT
    ELSE
        MOVE "failure" TO LS-ELEMENT
    END-IF
    MOVE DG-CODE(LS-I) TO LS-TAG
    PERFORM START-CASE
    STRING DG-CODE(LS-I) DELIMITED BY SPACE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM FINISH-CASE.

SEVERITY-WORD.
    EVALUATE LS-SEVERITY(1:1)
        WHEN "E"   MOVE "error" TO LS-SEVERITY
        WHEN "W"   MOVE "warning" TO LS-SEVERITY
        WHEN OTHER MOVE "note" TO LS-SEVERITY
    END-EVALUATE.

*>     <testcase classname="PATH" name="
START-CASE.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-FILE LS-PATH
    CALL "PLB-STR-LENGTH" USING LS-PATH LS-PATH-LEN
    PERFORM START-OUT
    STRING '    <testcase classname="' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-PATH TO LS-TEXT
    MOVE LS-PATH-LEN TO LS-TEXT-LEN
    PERFORM APPEND-ESCAPED
    STRING '" name="' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR.

*> The rest of the name ( at LINE:COLUMN), and the failure or error
*> with the message, and the report's text line as its body.
FINISH-CASE.
    STRING " at " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-LINE TO LS-NUM
    PERFORM APPEND-NUM
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-COLUMN TO LS-NUM
    PERFORM APPEND-NUM
    STRING '">' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    PERFORM START-OUT
    STRING "      <" DELIMITED BY SIZE
           LS-ELEMENT DELIMITED BY SPACE
           ' type="' DELIMITED BY SIZE
           LS-SEVERITY DELIMITED BY SPACE
           '" message="' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-STR-LENGTH" USING LS-MESSAGE LS-TEXT-LEN
    MOVE LS-MESSAGE TO LS-TEXT
    PERFORM APPEND-ESCAPED
    STRING '">' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    *> PATH:LINE:COLUMN: SEVERITY: MESSAGE [TAG]
    MOVE LS-PATH TO LS-TEXT
    MOVE LS-PATH-LEN TO LS-TEXT-LEN
    PERFORM APPEND-ESCAPED
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-LINE TO LS-NUM
    PERFORM APPEND-NUM
    STRING ":" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-COLUMN TO LS-NUM
    PERFORM APPEND-NUM
    STRING ": " DELIMITED BY SIZE
           LS-SEVERITY DELIMITED BY SPACE
           ": " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-STR-LENGTH" USING LS-MESSAGE LS-TEXT-LEN
    MOVE LS-MESSAGE TO LS-TEXT
    PERFORM APPEND-ESCAPED
    STRING " [" DELIMITED BY SIZE
           LS-TAG DELIMITED BY SPACE
           "]</" DELIMITED BY SIZE
           LS-ELEMENT DELIMITED BY SPACE
           ">" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    DISPLAY "    </testcase>".

WRITE-PASSED.
    PERFORM START-CASE
    STRING 'no findings"/>' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

*> LS-TEXT(1:LS-TEXT-LEN) into LS-OUT, escaped for XML.
APPEND-ESCAPED.
    CALL "PLB-XML-TEXT" USING LS-TEXT LS-TEXT-LEN LS-OUT LS-PTR.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

START-OUT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR.

PRINT-OUT.
    DISPLAY LS-OUT(1:LS-PTR - 1).
END PROGRAM PLB-REPORT-JUNIT.
