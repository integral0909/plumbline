*> ---------------------------------------------------------------
*> plbreport: machine-readable reports of findings and diagnostics.
*>
*> PLB-REPORT-JSON writes a simple JSON document; PLB-REPORT-SARIF
*> writes SARIF 2.1.0, the format read by code-scanning services and
*> many editors, with the fixes kept for the findings (plbfixs.cpy) as
*> SARIF fixes; PLB-REPORT-CODECLIMATE writes the Code Climate issues
*> GitLab shows in merge requests. All write to standard output, list
*> findings in the order of the findings table (callers sort it
*> first), and leave out suppressed findings.
*> ---------------------------------------------------------------

*> PLB-REPORT-JSON:
*>   {
*>     "tool": "plumbline",
*>     "version": "...",
*>     "findings": [
*>       {"rule": ..., "name": ..., "severity": ..., "file": ...,
*>        "line": ..., "column": ..., "message": ...,
*>        "fix": {"title": ..., "edits": [{"line": ..., "column": ...,
*>                "endLine": ..., "endColumn": ..., "text": ...}]}},
*>       ...
*>     ],
*>     "diagnostics": [
*>       {"code": ..., "severity": ..., "file": ..., "line": ...,
*>        "column": ..., "message": ...},
*>       ...
*>     ]
*>   }
*> Each finding and diagnostic is written on one line. "fix" is there
*> for a finding with a fix (PLB-FIX-FINDING): each edit puts "text" in
*> place of the characters from line and column up to, not including,
*> endLine and endColumn.
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
01  LS-FIX                  PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-SEVERITY             PIC X(8).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbfixs.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS PLB-FIX-STORE.
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
    CALL "PLB-FIX-FOR" USING PLB-FINDINGS LS-I PLB-FIX-STORE LS-FIX
    IF LS-FIX > 0
        PERFORM WRITE-FIX
    END-IF
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-I NOT = LS-LAST
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    COMPUTE LS-LEN = LS-PTR - 1
    DISPLAY WS-LINE(1:LS-LEN).

*> ', "fix": {...}' for fix LS-FIX.
WRITE-FIX.
    STRING ', "fix": {"title": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING FK-TITLE(LS-FIX) WS-LINE LS-PTR
    STRING ', "edits": [' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    PERFORM VARYING LS-E FROM FK-FIRST-EDIT(LS-FIX) BY 1
            UNTIL LS-E >= FK-FIRST-EDIT(LS-FIX) + FK-EDITS(LS-FIX)
        IF LS-E > FK-FIRST-EDIT(LS-FIX)
            STRING ", " DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        END-IF
        STRING '{"line": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-LINE(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ', "column": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-COLUMN(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ', "endLine": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-END-LINE(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ', "endColumn": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-END-COLUMN(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ', "text": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        PERFORM APPEND-EDIT-TEXT
        STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-PERFORM
    STRING "]}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR.

*> The text of edit LS-E as a JSON string.
APPEND-EDIT-TEXT.
    IF FK-EDIT-TEXT-LEN(LS-E) = 0
        STRING '""' DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        CALL "PLB-JSON-STRING" USING
            FK-EDIT-TEXT(LS-E)(1:FK-EDIT-TEXT-LEN(LS-E)) WS-LINE LS-PTR
    END-IF.

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
01  LS-FIX                  PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-LEVEL                PIC X(8).
01  LS-LINE-NO              PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbfixs.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS PLB-FIX-STORE.
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
    CALL "PLB-FIX-FOR" USING PLB-FINDINGS LS-I PLB-FIX-STORE LS-FIX
    IF LS-FIX > 0
        PERFORM WRITE-FIXES
    END-IF
    STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    IF LS-I NOT = LS-LAST
        STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    COMPUTE LS-LEN = LS-PTR - 1
    DISPLAY WS-LINE(1:LS-LEN).

*> ', "fixes": [...]' for fix LS-FIX, of the file at LS-PATH: one
*> replacement for each edit.
WRITE-FIXES.
    STRING ', "fixes": [{"description": {"text": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING FK-TITLE(LS-FIX) WS-LINE LS-PTR
    STRING '}, "artifactChanges": [{"artifactLocation": {"uri": "'
           DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-URI-PATH" USING LS-PATH WS-LINE LS-PTR
    STRING '"}, "replacements": [' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    PERFORM VARYING LS-E FROM FK-FIRST-EDIT(LS-FIX) BY 1
            UNTIL LS-E >= FK-FIRST-EDIT(LS-FIX) + FK-EDITS(LS-FIX)
        IF LS-E > FK-FIRST-EDIT(LS-FIX)
            STRING ", " DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        END-IF
        STRING '{"deletedRegion": {"startLine": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-LINE(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ', "startColumn": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-COLUMN(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ', "endLine": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-END-LINE(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ', "endColumn": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE FK-EDIT-END-COLUMN(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING '}, "insertedContent": {"text": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        IF FK-EDIT-TEXT-LEN(LS-E) = 0
            STRING '""' DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        ELSE
            CALL "PLB-JSON-STRING" USING
                FK-EDIT-TEXT(LS-E)(1:FK-EDIT-TEXT-LEN(LS-E)) WS-LINE
                LS-PTR
        END-IF
        STRING "}}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    END-PERFORM
    STRING "]}]}]" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR.

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

*> PLB-REPORT-CODECLIMATE: a JSON array of Code Climate issues, the
*> format of GitLab's code quality reports:
*>   [
*>     {"type": "issue", "check_name": RULE, "description": MESSAGE,
*>      "categories": [...], "severity": ..., "fingerprint": ...,
*>      "location": {"path": FILE, "lines": {"begin": LINE}}},
*>     ...
*>   ]
*> one issue per line, findings first, then diagnostics.
*>
*> GitLab tells new issues from old ones by the fingerprint, so it
*> must stay the same while the finding does. It is a hash of the
*> finding's baseline line (rule, file, message, and the reported
*> source line, without its number: see plbbase), and of how many
*> findings before it in the same file have that line, so that two
*> alike findings differ. A diagnostic's fingerprint hashes its code,
*> file, message, and line number.
*>
*> Severities: error is critical, warning major, note minor. The
*> category follows the rule's family: S rules are Security, P rules
*> Compatibility, M rules Clarity, and the others Bug Risk.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REPORT-CODECLIMATE.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-LINE                 PIC X(4096).
01  WS-KEY                  PIC X(1400).
*> The hash of each finding's key, to count earlier alike findings.
01  WS-HASH-1               PIC S9(18) COMP-5 OCCURS 100000 TIMES.
01  WS-HASH-2               PIC S9(18) COMP-5 OCCURS 100000 TIMES.
01  WS-HEX                  PIC X(16) VALUE "0123456789abcdef".
LOCAL-STORAGE SECTION.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-ANY                  PIC X.
01  LS-PATH                 PIC X(512).
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-SEVERITY             PIC X.
01  LS-CHECK                PIC X(31).
01  LS-H1                   PIC S9(18) COMP-5.
01  LS-H2                   PIC S9(18) COMP-5.
01  LS-V                    PIC S9(18) COMP-5.
01  LS-DIGIT                PIC 9(4) COMP-5.
01  LS-SEEN                 PIC 9(9) COMP-5.
01  LS-FINGERPRINT          PIC X(16).
01  LS-KEY-PTR              PIC 9(9) COMP-5.
01  LS-PENDING-LEN          PIC 9(9) COMP-5.
*> Two hashes of 31 bits each, modulo two primes below 2**31, with
*> different multipliers: 62 bits of fingerprint.
78  LS-PRIME-1              VALUE 2147483647.
78  LS-PRIME-2              VALUE 2147483629.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS.
    DISPLAY "["
    MOVE "N" TO LS-ANY
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            PERFORM WRITE-FINDING
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DG-COUNT
        PERFORM WRITE-DIAGNOSTIC
    END-PERFORM
    IF LS-ANY = "Y"
        PERFORM END-ISSUE
    END-IF
    DISPLAY "]"
    GOBACK.

WRITE-FINDING.
    CALL "PLB-BASELINE-KEY" USING PLB-SOURCE-SET PLB-RULES PLB-FINDINGS
        LS-I WS-KEY
    PERFORM HASH-KEY
    MOVE LS-H1 TO WS-HASH-1(LS-I)
    MOVE LS-H2 TO WS-HASH-2(LS-I)
    *> Alike findings before this one: the findings of a file are
    *> together, since the table is sorted by file.
    MOVE 0 TO LS-SEEN
    PERFORM VARYING LS-J FROM LS-I BY -1 UNTIL LS-J <= 1
        COMPUTE LS-K = LS-J - 1
        IF FN-FILE-ID(LS-K) NOT = FN-FILE-ID(LS-I)
            EXIT PERFORM
        END-IF
        IF FN-SUPPRESSED(LS-K) = "N"
           AND WS-HASH-1(LS-K) = LS-H1 AND WS-HASH-2(LS-K) = LS-H2
            ADD 1 TO LS-SEEN
        END-IF
    END-PERFORM
    PERFORM ADD-SEEN
    MOVE RL-ID(FN-RULE(LS-I)) TO LS-CHECK
    MOVE FN-SEVERITY(LS-I) TO LS-SEVERITY
    PERFORM START-ISSUE
    CALL "PLB-JSON-STRING" USING FN-MESSAGE(LS-I) WS-LINE LS-PTR
    PERFORM APPEND-CATEGORY
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET FN-FILE-ID(LS-I)
        LS-PATH
    MOVE FN-LINE(LS-I) TO LS-NUM
    PERFORM FINISH-ISSUE.

WRITE-DIAGNOSTIC.
    MOVE SPACES TO WS-KEY
    MOVE 1 TO LS-KEY-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET DG-FILE-ID(LS-I)
        LS-PATH
    MOVE DG-LINE(LS-I) TO LS-NUM
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING DG-CODE(LS-I) DELIMITED BY SPACE
           " | " DELIMITED BY SIZE
           LS-PATH DELIMITED BY SPACE
           " | " DELIMITED BY SIZE
           DG-MESSAGE(LS-I) DELIMITED BY SIZE
           " | " LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-KEY WITH POINTER LS-KEY-PTR
    PERFORM HASH-KEY
    MOVE 0 TO LS-SEEN
    PERFORM ADD-SEEN
    MOVE DG-CODE(LS-I) TO LS-CHECK
    MOVE DG-SEVERITY(LS-I) TO LS-SEVERITY
    PERFORM START-ISSUE
    CALL "PLB-JSON-STRING" USING DG-MESSAGE(LS-I) WS-LINE LS-PTR
    STRING ', "categories": ["Bug Risk"]' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DG-LINE(LS-I) TO LS-NUM
    PERFORM FINISH-ISSUE.

*> The issue before this one is written here, with its comma, so that
*> the last one has none.
START-ISSUE.
    IF LS-ANY = "Y"
        PERFORM END-ISSUE-COMMA
    END-IF
    MOVE "Y" TO LS-ANY
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '  {"type": "issue", "check_name": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING LS-CHECK WS-LINE LS-PTR
    STRING ', "description": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR.

APPEND-CATEGORY.
    EVALUATE LS-CHECK(5:1)
        WHEN "S"
            STRING ', "categories": ["Security"]' DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        WHEN "P"
            STRING ', "categories": ["Compatibility"]' DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        WHEN "M"
            STRING ', "categories": ["Clarity"]' DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        WHEN OTHER
            STRING ', "categories": ["Bug Risk"]' DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
    END-EVALUATE.

*> Severity, fingerprint, and location (LS-PATH, line LS-NUM); the
*> line is kept until the next issue or the end tells whether a comma
*> follows it.
FINISH-ISSUE.
    STRING ', "severity": "' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    EVALUATE LS-SEVERITY
        WHEN "E"
            STRING "critical" DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        WHEN "N"
            STRING "minor" DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        WHEN OTHER
            STRING "major" DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
    END-EVALUATE
    PERFORM FORMAT-FINGERPRINT
    STRING '", "fingerprint": "' LS-FINGERPRINT
           '", "location": {"path": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING LS-PATH WS-LINE LS-PTR
    STRING ', "lines": {"begin": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    *> Line 0 is a whole-file diagnostic: GitLab wants a line.
    IF LS-NUM < 1
        MOVE 1 TO LS-NUM
    END-IF
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) "}}}" DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    COMPUTE LS-PENDING-LEN = LS-PTR - 1.

*> The pending issue, with a comma when another follows.
END-ISSUE.
    DISPLAY WS-LINE(1:LS-PENDING-LEN).

END-ISSUE-COMMA.
    DISPLAY WS-LINE(1:LS-PENDING-LEN) ",".

*> LS-H1 and LS-H2 over WS-KEY up to its last non-space character.
HASH-KEY.
    MOVE 0 TO LS-H1 LS-H2
    CALL "PLB-STR-LENGTH" USING WS-KEY LS-LEN
    PERFORM VARYING LS-J FROM 1 BY 1 UNTIL LS-J > LS-LEN
        COMPUTE LS-V = FUNCTION ORD(WS-KEY(LS-J:1))
        COMPUTE LS-H1 = FUNCTION MOD(LS-H1 * 131 + LS-V, LS-PRIME-1)
        COMPUTE LS-H2 = FUNCTION MOD(LS-H2 * 257 + LS-V, LS-PRIME-2)
    END-PERFORM.

*> Fold the count of alike findings before this one into the hashes.
ADD-SEEN.
    COMPUTE LS-H1 = FUNCTION MOD(LS-H1 * 131 + 1000 + LS-SEEN,
        LS-PRIME-1)
    COMPUTE LS-H2 = FUNCTION MOD(LS-H2 * 257 + 1000 + LS-SEEN,
        LS-PRIME-2).

*> Sixteen hexadecimal digits: eight of each hash.
FORMAT-FINGERPRINT.
    MOVE LS-H1 TO LS-V
    PERFORM VARYING LS-J FROM 8 BY -1 UNTIL LS-J < 1
        COMPUTE LS-DIGIT = FUNCTION MOD(LS-V, 16)
        MOVE WS-HEX(LS-DIGIT + 1:1) TO LS-FINGERPRINT(LS-J:1)
        COMPUTE LS-V = LS-V / 16
    END-PERFORM
    MOVE LS-H2 TO LS-V
    PERFORM VARYING LS-J FROM 16 BY -1 UNTIL LS-J < 9
        COMPUTE LS-DIGIT = FUNCTION MOD(LS-V, 16)
        MOVE WS-HEX(LS-DIGIT + 1:1) TO LS-FINGERPRINT(LS-J:1)
        COMPUTE LS-V = LS-V / 16
    END-PERFORM.
END PROGRAM PLB-REPORT-CODECLIMATE.
