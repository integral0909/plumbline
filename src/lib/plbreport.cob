*> ---------------------------------------------------------------
*> plbreport: machine-readable reports of findings and diagnostics.
*>
*> PLB-REPORT-JSON writes a simple JSON document; PLB-REPORT-SARIF
*> writes SARIF 2.1.0, the format read by code-scanning services and
*> many editors. Both write to standard output, list findings in the
*> order of the findings table (callers sort it first), and leave out
*> suppressed findings.
*> ---------------------------------------------------------------

*> PLB-REPORT-JSON:
*>   {
*>     "tool": "plumbline",
*>     "version": "...",
*>     "findings": [
*>       {"rule": ..., "name": ..., "severity": ..., "file": ...,
*>        "line": ..., "column": ..., "message": ...},
*>       ...
*>     ],
*>     "diagnostics": [
*>       {"code": ..., "severity": ..., "file": ..., "line": ...,
*>        "column": ..., "message": ...},
*>       ...
*>     ]
*>   }
*> Each finding and diagnostic is written on one line.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REPORT-JSON.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
01  WS-LINE                 PIC X(4096).
LOCAL-STORAGE SECTION.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-PATH                 PIC X(512).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-SEVERITY             PIC X(8).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS.
    DISPLAY "{"
    DISPLAY '  "tool": "' PLB-NAME '",'
    DISPLAY '  "version": "' PLB-VERSION '",'
    DISPLAY '  "findings": ['
    *> The last finding written takes no trailing comma.
    MOVE 0 TO LS-LAST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            MOVE LS-I TO LS-LAST
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            PERFORM WRITE-FINDING
        END-IF
    END-PERFORM
    DISPLAY '  ],'
    DISPLAY '  "diagnostics": ['
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DG-COUNT
        PERFORM WRITE-DIAGNOSTIC
    END-PERFORM
    DISPLAY '  ]'
    DISPLAY "}"
    GOBACK.

WRITE-FINDING.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '    {"rule": "' DELIMITED BY SIZE
           RL-ID(FN-RULE(LS-I)) DELIMITED BY SPACE
           '", "name": "' DELIMITED BY SIZE
           RL-NAME(FN-RULE(LS-I)) DELIMITED BY SPACE
           '", "severity": "' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE FN-SEVERITY(LS-I) TO LS-SEVERITY
    PERFORM SEVERITY-NAME
    STRING LS-SEVERITY DELIMITED BY SPACE
           '", "file": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET FN-FILE-ID(LS-I)
        LS-PATH
    CALL "PLB-JSON-STRING" USING LS-PATH WS-LINE LS-PTR
    STRING ', "line": ' DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    MOVE FN-LINE(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "column": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE FN-COLUMN(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "message": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING FN-MESSAGE(LS-I) WS-LINE LS-PTR
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-I NOT = LS-LAST
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    COMPUTE LS-LEN = LS-PTR - 1
    DISPLAY WS-LINE(1:LS-LEN).

WRITE-DIAGNOSTIC.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '    {"code": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING DG-CODE(LS-I) WS-LINE LS-PTR
    STRING ', "severity": "' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DG-SEVERITY(LS-I) TO LS-SEVERITY
    PERFORM SEVERITY-NAME
    STRING LS-SEVERITY DELIMITED BY SPACE
           '", "file": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET DG-FILE-ID(LS-I)
        LS-PATH
    CALL "PLB-JSON-STRING" USING LS-PATH WS-LINE LS-PTR
    STRING ', "line": ' DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    MOVE DG-LINE(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "column": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DG-COLUMN(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "message": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING DG-MESSAGE(LS-I) WS-LINE LS-PTR
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-I < DG-COUNT
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    COMPUTE LS-LEN = LS-PTR - 1
    DISPLAY WS-LINE(1:LS-LEN).

SEVERITY-NAME.
    EVALUATE LS-SEVERITY(1:1)
        WHEN "E"  MOVE "error" TO LS-SEVERITY
        WHEN "N"  MOVE "note" TO LS-SEVERITY
        WHEN OTHER MOVE "warning" TO LS-SEVERITY
    END-EVALUATE.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR.
END PROGRAM PLB-REPORT-JSON.

*> PLB-REPORT-SARIF: a SARIF 2.1.0 log with one run. The run's tool
*> lists every rule in the catalog; each unsuppressed finding is a
*> result pointing at its rule by index; diagnostics are reported as
*> tool execution notifications of the run's invocation.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REPORT-SARIF.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
01  WS-LINE                 PIC X(4096).
LOCAL-STORAGE SECTION.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-PATH                 PIC X(512).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-LEVEL                PIC X(8).
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS.
    DISPLAY "{"
    DISPLAY '  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",'
    DISPLAY '  "version": "2.1.0",'
    DISPLAY '  "runs": ['
    DISPLAY '    {'
    DISPLAY '      "tool": {'
    DISPLAY '        "driver": {'
    DISPLAY '          "name": "' PLB-NAME '",'
    DISPLAY '          "version": "' PLB-VERSION '",'
    DISPLAY '          "informationUri": "' PLB-HOME '",'
    DISPLAY '          "rules": ['
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > RL-COUNT
        PERFORM WRITE-RULE
    END-PERFORM
    DISPLAY '          ]'
    DISPLAY '        }'
    DISPLAY '      },'
    DISPLAY '      "invocations": ['
    DISPLAY '        {'
    DISPLAY '          "executionSuccessful": true,'
    DISPLAY '          "toolExecutionNotifications": ['
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DG-COUNT
        PERFORM WRITE-NOTIFICATION
    END-PERFORM
    DISPLAY '          ]'
    DISPLAY '        }'
    DISPLAY '      ],'
    DISPLAY '      "results": ['
    MOVE 0 TO LS-LAST
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            MOVE LS-I TO LS-LAST
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            PERFORM WRITE-RESULT
        END-IF
    END-PERFORM
    DISPLAY '      ]'
    DISPLAY '    }'
    DISPLAY '  ]'
    DISPLAY "}"
    GOBACK.

WRITE-RULE.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '            {"id": "' DELIMITED BY SIZE
           RL-ID(LS-I) DELIMITED BY SPACE
           '", "name": "' DELIMITED BY SIZE
           RL-NAME(LS-I) DELIMITED BY SPACE
           '", "shortDescription": {"text": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING RL-TITLE(LS-I) WS-LINE LS-PTR
    *> The rule's section of the reference: #plb-c001-unreachable-code.
    STRING '}, "helpUri": "' DELIMITED BY SIZE
           PLB-RULES-URL DELIMITED BY SIZE
           "#" FUNCTION LOWER-CASE(RL-ID(LS-I)) DELIMITED BY SPACE
           "-" DELIMITED BY SIZE
           RL-NAME(LS-I) DELIMITED BY SPACE
           '"' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    STRING ', "defaultConfiguration": {"level": "' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE RL-SEVERITY(LS-I) TO LS-LEVEL
    PERFORM LEVEL-NAME
    STRING LS-LEVEL DELIMITED BY SPACE
           '", "enabled": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    IF RL-ENABLED(LS-I) = "Y"
        STRING "true" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING "false" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    STRING "}}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-I < RL-COUNT
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    COMPUTE LS-LEN = LS-PTR - 1
    DISPLAY WS-LINE(1:LS-LEN).

WRITE-NOTIFICATION.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '            {"descriptor": {"id": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING DG-CODE(LS-I) WS-LINE LS-PTR
    STRING '}, "level": "' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DG-SEVERITY(LS-I) TO LS-LEVEL
    PERFORM LEVEL-NAME
    STRING LS-LEVEL DELIMITED BY SPACE
           '", "message": {"text": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING DG-MESSAGE(LS-I) WS-LINE LS-PTR
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF DG-FILE-ID(LS-I) > 0
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET DG-FILE-ID(LS-I)
            LS-PATH
        MOVE DG-LINE(LS-I) TO LS-LINE-NO
        MOVE DG-COLUMN(LS-I) TO LS-COLUMN
        PERFORM WRITE-LOCATION
    END-IF
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-I < DG-COUNT
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    COMPUTE LS-LEN = LS-PTR - 1
    DISPLAY WS-LINE(1:LS-LEN).

WRITE-RESULT.
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '        {"ruleId": "' DELIMITED BY SIZE
           RL-ID(FN-RULE(LS-I)) DELIMITED BY SPACE
           '", "ruleIndex": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    COMPUTE LS-NUM = FN-RULE(LS-I) - 1
    PERFORM APPEND-NUM
    STRING ', "level": "' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE FN-SEVERITY(LS-I) TO LS-LEVEL
    PERFORM LEVEL-NAME
    STRING LS-LEVEL DELIMITED BY SPACE
           '", "message": {"text": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING FN-MESSAGE(LS-I) WS-LINE LS-PTR
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET FN-FILE-ID(LS-I)
        LS-PATH
    MOVE FN-LINE(LS-I) TO LS-LINE-NO
    MOVE FN-COLUMN(LS-I) TO LS-COLUMN
    PERFORM WRITE-LOCATION
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-I NOT = LS-LAST
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    COMPUTE LS-LEN = LS-PTR - 1
    DISPLAY WS-LINE(1:LS-LEN).

*> ', "locations": [...]' for LS-PATH at line LS-LINE-NO and column
*> LS-COLUMN (either may be 0 for "unknown").
WRITE-LOCATION.
    STRING ', "locations": [{"physicalLocation": {'
           '"artifactLocation": {"uri": "' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-URI-PATH" USING LS-PATH WS-LINE LS-PTR
    STRING '"}' DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-LINE-NO > 0
        STRING ', "region": {"startLine": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE LS-LINE-NO TO LS-NUM
        PERFORM APPEND-NUM
        IF LS-COLUMN > 0
            STRING ', "startColumn": ' DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
            MOVE LS-COLUMN TO LS-NUM
            PERFORM APPEND-NUM
        END-IF
        STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    STRING "}}]" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR.

LEVEL-NAME.
    EVALUATE LS-LEVEL(1:1)
        WHEN "E"  MOVE "error" TO LS-LEVEL
        WHEN "N"  MOVE "note" TO LS-LEVEL
        WHEN OTHER MOVE "warning" TO LS-LEVEL
    END-EVALUATE.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR.
END PROGRAM PLB-REPORT-SARIF.
