*> ---------------------------------------------------------------
*> plbhtml: the findings of plumbline check as one HTML page.
*>
*> PLB-REPORT-HTML USING SOURCE DIAGNOSTICS RULES FINDINGS writes a
*> self-contained page (no scripts, no outside resources) to standard
*> output: a summary by severity and by rule, the findings of each
*> file with the source lines around them, and the diagnostics.
*> Suppressed and baselined findings are left out, as in the other
*> reports. Every text taken from the input is HTML-escaped.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REPORT-HTML.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
*> Findings per rule, for the summary.
01  WS-RULE-COUNTS.
    05  WS-RULE-FINDINGS    PIC 9(9) COMP-5 OCCURS 64 TIMES.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(4) COMP-5.
01  LS-FILE                 PIC 9(4) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-SRC                  PIC 9(9) COMP-5.
01  LS-ERRORS               PIC 9(9) COMP-5.
01  LS-WARNINGS             PIC 9(9) COMP-5.
01  LS-NOTES                PIC 9(9) COMP-5.
01  LS-SHOWN                PIC 9(9) COMP-5.
01  LS-PATH                 PIC X(512).
01  LS-TEXT                 PIC X(1024).
01  LS-TEXT-LEN             PIC 9(9) COMP-5.
01  LS-OUT                  PIC X(8192).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-CLASS                PIC X(8).
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-RULES
        PLB-FINDINGS.
    PERFORM COUNT-FINDINGS
    PERFORM WRITE-HEAD
    PERFORM WRITE-SUMMARY
    PERFORM WRITE-FINDINGS
    PERFORM WRITE-DIAGNOSTICS
    DISPLAY "</main>"
    DISPLAY "</body>"
    DISPLAY "</html>"
    GOBACK.

COUNT-FINDINGS.
    MOVE 0 TO LS-ERRORS LS-WARNINGS LS-NOTES LS-SHOWN
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > 64
        MOVE 0 TO WS-RULE-FINDINGS(LS-R)
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            ADD 1 TO LS-SHOWN
            ADD 1 TO WS-RULE-FINDINGS(FN-RULE(LS-I))
            EVALUATE FN-SEVERITY(LS-I)
                WHEN "E"   ADD 1 TO LS-ERRORS
                WHEN "W"   ADD 1 TO LS-WARNINGS
                WHEN OTHER ADD 1 TO LS-NOTES
            END-EVALUATE
        END-IF
    END-PERFORM.

WRITE-HEAD.
    DISPLAY "<!DOCTYPE html>"
    DISPLAY '<html lang="en">'
    DISPLAY "<head>"
    DISPLAY '<meta charset="utf-8">'
    DISPLAY '<meta name="viewport" content="width=device-width, '
            'initial-scale=1">'
    DISPLAY "<title>Plumbline report</title>"
    DISPLAY "<style>"
    DISPLAY ":root { --bg: #ffffff; --fg: #1d2129; --muted: #5d6573;"
    DISPLAY "  --line: #e3e6eb; --code: #f6f7f9; --mark: #fff4c2;"
    DISPLAY "  --error: #b3261e; --warning: #9a6700; --note: #3a5a9c; }"
    DISPLAY "@media (prefers-color-scheme: dark) {"
    DISPLAY "  :root { --bg: #16181d; --fg: #e4e6eb; --muted: #9aa1ad;"
    DISPLAY "    --line: #2c3038; --code: #1e2127; --mark: #3d3518;"
    DISPLAY "    --error: #f2b8b5; --warning: #f5c36a; --note: #a8c7fa; } }"
    DISPLAY "body { margin: 0; background: var(--bg); color: var(--fg);"
    DISPLAY "  font: 15px/1.5 system-ui, sans-serif; }"
    DISPLAY "main { max-width: 64rem; margin: 0 auto; padding: 1rem; }"
    DISPLAY "h1 { font-size: 1.5rem; margin: .5rem 0; }"
    DISPLAY "h2 { font-size: 1.1rem; margin: 2rem 0 .5rem;"
    DISPLAY "  overflow-wrap: anywhere; }"
    DISPLAY "p.meta { color: var(--muted); margin: 0 0 1rem; }"
    DISPLAY "table { border-collapse: collapse; width: 100%; }"
    DISPLAY "th, td { text-align: left; padding: .3rem .5rem;"
    DISPLAY "  border-bottom: 1px solid var(--line); }"
    DISPLAY "td.n { text-align: right; width: 4rem; }"
    DISPLAY ".finding { border: 1px solid var(--line); border-radius: 6px;"
    DISPLAY "  margin: .75rem 0; overflow: hidden; }"
    DISPLAY ".finding header { padding: .5rem .75rem; }"
    DISPLAY ".sev { font-weight: 600; text-transform: uppercase;"
    DISPLAY "  font-size: .8rem; margin-right: .5rem; }"
    DISPLAY ".error { color: var(--error); }"
    DISPLAY ".warning { color: var(--warning); }"
    DISPLAY ".note { color: var(--note); }"
    DISPLAY ".rule, .where { color: var(--muted); font-size: .85rem; }"
    DISPLAY "pre { margin: 0; padding: .5rem .75rem; background: var(--code);"
    DISPLAY "  overflow-x: auto; font-size: .85rem; }"
    DISPLAY "pre mark { background: var(--mark); color: inherit;"
    DISPLAY "  display: block; }"
    DISPLAY "</style>"
    DISPLAY "</head>"
    DISPLAY "<body>"
    DISPLAY "<main>"
    DISPLAY "<h1>Plumbline report</h1>"
    PERFORM START-OUT
    STRING '<p class="meta">' DELIMITED BY SIZE
           PLB-NAME DELIMITED BY SPACE
           " " DELIMITED BY SIZE
           PLB-VERSION DELIMITED BY SPACE
           " &middot; " DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    STRING "findings: " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-SHOWN TO LS-NUM
    PERFORM APPEND-NUM
    STRING " (errors " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-ERRORS TO LS-NUM
    PERFORM APPEND-NUM
    STRING ", warnings " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-WARNINGS TO LS-NUM
    PERFORM APPEND-NUM
    STRING ", notes " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE LS-NOTES TO LS-NUM
    PERFORM APPEND-NUM
    STRING ")</p>" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT.

*> A table of the rules that found something.
WRITE-SUMMARY.
    IF LS-SHOWN = 0
        DISPLAY "<p>No findings.</p>"
        EXIT PARAGRAPH
    END-IF
    DISPLAY "<table>"
    DISPLAY "<thead><tr><th>Rule</th><th>Name</th><th>Severity</th>"
            '<th class="n">Findings</th></tr></thead>'
    DISPLAY "<tbody>"
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RL-COUNT
        IF WS-RULE-FINDINGS(LS-R) > 0
            PERFORM START-OUT
            PERFORM SEVERITY-CLASS-OF-RULE
            STRING "<tr><td>" DELIMITED BY SIZE
                   RL-ID(LS-R) DELIMITED BY SPACE
                   "</td><td>" DELIMITED BY SIZE
                   RL-NAME(LS-R) DELIMITED BY SPACE
                   '</td><td class="' DELIMITED BY SIZE
                   LS-CLASS DELIMITED BY SPACE
                   '">' DELIMITED BY SIZE
                   LS-CLASS DELIMITED BY SPACE
                   '</td><td class="n">' DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            MOVE WS-RULE-FINDINGS(LS-R) TO LS-NUM
            PERFORM APPEND-NUM
            STRING "</td></tr>" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
            PERFORM PRINT-OUT
        END-IF
    END-PERFORM
    DISPLAY "</tbody>"
    DISPLAY "</table>".

SEVERITY-CLASS-OF-RULE.
    EVALUATE RL-SEVERITY(LS-R)
        WHEN "E"   MOVE "error" TO LS-CLASS
        WHEN "W"   MOVE "warning" TO LS-CLASS
        WHEN OTHER MOVE "note" TO LS-CLASS
    END-EVALUATE.

*> Findings are sorted by file: a heading whenever the file changes.
WRITE-FINDINGS.
    MOVE 0 TO LS-FILE
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > FN-COUNT
        IF FN-SUPPRESSED(LS-I) = "N"
            IF FN-FILE-ID(LS-I) NOT = LS-FILE
                MOVE FN-FILE-ID(LS-I) TO LS-FILE
                PERFORM START-OUT
                STRING "<h2>" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
                CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET LS-FILE
                    LS-PATH
                CALL "PLB-STR-LENGTH" USING LS-PATH LS-TEXT-LEN
                MOVE LS-PATH TO LS-TEXT
                PERFORM APPEND-ESCAPED
                STRING "</h2>" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
                PERFORM PRINT-OUT
            END-IF
            PERFORM WRITE-FINDING
        END-IF
    END-PERFORM.

WRITE-FINDING.
    EVALUATE FN-SEVERITY(LS-I)
        WHEN "E"   MOVE "error" TO LS-CLASS
        WHEN "W"   MOVE "warning" TO LS-CLASS
        WHEN OTHER MOVE "note" TO LS-CLASS
    END-EVALUATE
    DISPLAY '<article class="finding">'
    PERFORM START-OUT
    STRING '<header><span class="sev ' DELIMITED BY SIZE
           LS-CLASS DELIMITED BY SPACE
           '">' DELIMITED BY SIZE
           LS-CLASS DELIMITED BY SPACE
           "</span>" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-STR-LENGTH" USING FN-MESSAGE(LS-I) LS-TEXT-LEN
    MOVE FN-MESSAGE(LS-I) TO LS-TEXT
    PERFORM APPEND-ESCAPED
    MOVE FN-RULE(LS-I) TO LS-R
    STRING ' <span class="rule">' DELIMITED BY SIZE
           RL-ID(LS-R) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
           RL-NAME(LS-R) DELIMITED BY SPACE
           '</span> <span class="where">line ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE FN-LINE(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ", column " DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    MOVE FN-COLUMN(LS-I) TO LS-NUM
    PERFORM APPEND-NUM
    STRING "</span></header>" DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    PERFORM PRINT-OUT
    PERFORM WRITE-EXCERPT
    DISPLAY "</article>".

*> The reported line and two lines on either side, numbered; the
*> reported line marked.
WRITE-EXCERPT.
    MOVE FN-SRC-LINE(LS-I) TO LS-SRC
    IF LS-SRC = 0 OR LS-FILE = 0
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-FROM = LS-SRC - 2
    IF LS-SRC <= 2 OR LS-FROM < SF-FIRST-LINE(LS-FILE)
        MOVE SF-FIRST-LINE(LS-FILE) TO LS-FROM
    END-IF
    COMPUTE LS-TO = LS-SRC + 2
    IF LS-TO >= SF-FIRST-LINE(LS-FILE) + SF-LINE-COUNT(LS-FILE)
        COMPUTE LS-TO = SF-FIRST-LINE(LS-FILE)
            + SF-LINE-COUNT(LS-FILE) - 1
    END-IF
    DISPLAY "<pre>" WITH NO ADVANCING
    PERFORM VARYING LS-K FROM LS-FROM BY 1 UNTIL LS-K > LS-TO
        PERFORM START-OUT
        IF LS-K = LS-SRC
            STRING "<mark>" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        MOVE SL-LINE-NO(LS-K) TO LS-NUM
        CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
        *> Line numbers right-aligned in six columns.
        IF LS-NUM-LEN < 6
            MOVE SPACES TO LS-TEXT
            COMPUTE LS-LEN = 6 - LS-NUM-LEN
            STRING LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
               "  " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        MOVE SPACES TO LS-TEXT
        MOVE SL-TEXT-LEN(LS-K) TO LS-TEXT-LEN
        IF LS-TEXT-LEN > LENGTH OF LS-TEXT
            MOVE LENGTH OF LS-TEXT TO LS-TEXT-LEN
        END-IF
        IF LS-TEXT-LEN > 0
            MOVE SS-HEAP(SL-TEXT-OFF(LS-K):LS-TEXT-LEN) TO LS-TEXT
        END-IF
        PERFORM APPEND-ESCAPED
        IF LS-K = LS-SRC
            STRING "</mark>" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        IF LS-K = LS-TO
            STRING "</pre>" DELIMITED BY SIZE
                INTO LS-OUT WITH POINTER LS-PTR
        END-IF
        PERFORM PRINT-OUT
    END-PERFORM.

WRITE-DIAGNOSTICS.
    IF DG-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    DISPLAY "<h2>Problems reading the input</h2>"
    DISPLAY "<ul>"
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DG-COUNT
        PERFORM START-OUT
        STRING "<li>" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET DG-FILE-ID(LS-I)
            LS-PATH
        CALL "PLB-DIAG-FORMAT" USING PLB-DIAGNOSTICS LS-I LS-PATH LS-TEXT
            LS-TEXT-LEN
        PERFORM APPEND-ESCAPED
        STRING "</li>" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
        PERFORM PRINT-OUT
    END-PERFORM
    DISPLAY "</ul>".

*> LS-TEXT(1:LS-TEXT-LEN) into LS-OUT, with & < > " escaped.
APPEND-ESCAPED.
    PERFORM VARYING LS-LEN FROM 1 BY 1 UNTIL LS-LEN > LS-TEXT-LEN
        EVALUATE LS-TEXT(LS-LEN:1)
            WHEN "&"
                STRING "&amp;" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN "<"
                STRING "&lt;" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN ">"
                STRING "&gt;" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN '"'
                STRING "&quot;" DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
            WHEN OTHER
                STRING LS-TEXT(LS-LEN:1) DELIMITED BY SIZE
                    INTO LS-OUT WITH POINTER LS-PTR
        END-EVALUATE
    END-PERFORM.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.

START-OUT.
    MOVE SPACES TO LS-OUT
    MOVE 1 TO LS-PTR.

*> Up to the pointer: trailing spaces of a source line are kept.
PRINT-OUT.
    COMPUTE LS-LEN = LS-PTR - 1
    IF LS-LEN > 0
        DISPLAY LS-OUT(1:LS-LEN)
    ELSE
        DISPLAY " "
    END-IF.
END PROGRAM PLB-REPORT-HTML.
