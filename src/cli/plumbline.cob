*> ---------------------------------------------------------------
*> plumbline: command-line entry point.
*>
*>   plumbline --help | --version
*>   plumbline check [-I DIR]... [--format ...] [--debug]
*>                   [--enable RULE]... [--disable RULE]...
*>                   [--fail-on error|warning|note|never]
*>                   [--report text|json|sarif|html|md]
*>                   [--baseline FILE | --write-baseline FILE] [--diff FILE] FILE...
*>
*> Every command first reads the settings in plumbline.conf in the
*> current directory, if there is one, or in the file given with
*> --config FILE; --no-config skips it. Settings are applied before
*> the command-line options, which can override them:
*>
*>   include DIR          like -I DIR
*>   format FORMAT        like --format FORMAT
*>   enable RULE          like --enable RULE
*>   disable RULE         like --disable RULE
*>   severity RULE LEVEL  report RULE as error, warning, or note
*>   limit RULE N         the threshold of a measuring rule
*>   fail-on LEVEL        like --fail-on LEVEL
*>   report FORMAT        like --report FORMAT
*>   baseline FILE        like --baseline FILE
*>   plumbline metrics [-I DIR]... [--format ...] [--debug]
*>                     [--report text|json|csv] FILE...
*>   plumbline graph [--kind performs|calls|copybooks|jobs|datasets|cics]
*>                   [--report dot|json] [-I DIR]... FILE...
*>   plumbline impact NAME [-I DIR]... FILE...
*>   plumbline format --to fixed|free [--format ...] FILE
*>   plumbline format --to fixed|free --check [--format ...] FILE...
*>   plumbline fix [-I DIR]... [--format ...] FILE
*>   plumbline fix --check [-I DIR]... [--format ...] FILE...
*>   plumbline fix --patch [-I DIR]... [--format ...] FILE...
*>   plumbline lsp [-I DIR]... [--format ...] [--enable RULE]...
*>       a language server on standard input and output
*>   plumbline dump lines  [--format fixed|free|variable|auto] FILE...
*>   plumbline dump tokens [--format fixed|free|variable|auto] [--debug]
*>                         FILE...
*>   plumbline dump expanded [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump ast [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump symbols [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump flow [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump refs [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump calls [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline inventory [--report text|json] [OPTION]... FILE...
*>   plumbline layout [--report text|json|csv|md] [OPTION]... FILE...
*>   plumbline doc [OPTION]... FILE...
*>   plumbline fields [--report text|json] [--unused] [OPTION]... FILE...
*>   plumbline xref [--report text|json] [OPTION]... FILE...
*>   plumbline duplicates [--min-tokens N] [--report text|json] [OPTION]... FILE...
*>   plumbline crud [--report text|csv|json] [OPTION]... FILE...
*>   plumbline summary [--report text|md|csv|json] [OPTION]... FILE...
*>   plumbline lineage NAME [--depth N] [--forward] [--report text|json] [OPTION]... FILE...
*>   plumbline dump jcl FILE...
*>   plumbline dump bms FILE...
*>   plumbline dump csd FILE...
*>   plumbline dump ims FILE...
*>
*> Exit codes:
*>   0  success
*>   1  findings at or above the --fail-on level (check), or errors
*>      in the input such as a file that could not be read
*>   2  usage error (unknown option or command, missing argument)
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLUMBLINE.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbppopt.cpy".
COPY "plbincl.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbflow.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbfix.cpy".
COPY "plbref.cpy".
COPY "plbcallc.cpy".
COPY "plbcall.cpy".
COPY "plbjclc.cpy".
COPY "plbdsetc.cpy".
COPY "plbfldc.cpy".
COPY "plbjcl.cpy".
COPY "plbdset.cpy".
COPY "plbfld.cpy".
COPY "plbdupt.cpy".
COPY "plbsqlm.cpy".
COPY "plbcrud.cpy".
COPY "plbbmsc.cpy".
COPY "plbbms.cpy".
COPY "plbcsdc.cpy".
COPY "plbcsd.cpy".
COPY "plbimsc.cpy".
COPY "plbims.cpy".
COPY "plbduse.cpy".
COPY "plbconf.cpy".
COPY "plbmetrc.cpy".
COPY "plbmetr.cpy".
COPY "plbsumm.cpy".
COPY "plbigrc.cpy".
COPY "plbigr.cpy".
01  WS-ARG-COUNT            PIC 9(4).
01  WS-ARG-INDEX            PIC 9(4).
01  WS-ARG                  PIC X(1024).
01  WS-ARG-LEN              PIC 9(9) COMP-5.
01  WS-EXIT-CODE            PIC 9(4) VALUE 0.
01  WS-MODE                 PIC X VALUE "A".
01  WS-DEBUG                PIC X VALUE "N".
01  WS-DUMP-TARGET          PIC X(8).
*> check: whether the input is JCL, by its extension.
01  WS-IS-JCL               PIC X VALUE "N".
01  WS-EXTENSION            PIC X(4).
*> layout: the program written to copy the copybooks given.
01  WS-LAYOUT-WRAPPER       PIC X(512).
COPY "plbinput.cpy".
*> impact --changed LIST: the paths of the changed files.
COPY "plbinput.cpy" REPLACING ==PLB-INPUTS== BY ==WS-CHANGED-FILES==
    ==IP-MAX== BY ==CH-MAX== ==IP-PATH-SIZE== BY ==CH-PATH-SIZE==
    ==IP-COUNT== BY ==CH-COUNT== ==IP-PATH== BY ==CH-PATH==.
*> --define NAME: names for conditional compilation (>>IF NAME DEFINED).
01  WS-DEFINE-COUNT         PIC 9(4) COMP-5 VALUE 0.
01  WS-TAB-WIDTH            PIC 9(4) COMP-5 VALUE 8.
*> --intrinsics: SS-INTRINSICS for the source set.
01  WS-INTRINSICS           PIC X(256) VALUE SPACES.
01  WS-DEFINES.
    05  WS-DEFINE           PIC X(31) OCCURS 64 TIMES.
01  WS-LIST-STATUS          PIC 9(4) COMP-5.
01  WS-LIST-LINE            PIC 9(9) COMP-5.
01  WS-I                    PIC 9(9) COMP-5.
01  WS-FILE-ID              PIC 9(4) COMP-5.
01  WS-STATUS               PIC 9(4) COMP-5.
01  WS-OUT                  PIC X(2048).
01  WS-OUT-LEN              PIC 9(9) COMP-5.
01  WS-PTR                  PIC 9(9) COMP-5.
01  WS-NUM                  PIC S9(18) COMP-5.
01  WS-NUM-TEXT             PIC X(20).
01  WS-NUM-LEN              PIC 9(9) COMP-5.
01  WS-CONTENT              PIC X(1024).
01  WS-CONTENT-LEN          PIC 9(9) COMP-5.
01  WS-PATH                 PIC X(512).
01  WS-PATH-LEN             PIC 9(9) COMP-5.
01  WS-KIND-NAME            PIC X(9).
01  WS-FORMAT-NAME          PIC X(5).
01  WS-LINE-INDEX           PIC 9(9) COMP-5.
01  WS-TOKEN-TEXT           PIC X(8192).
01  WS-TOKEN-LEN            PIC 9(9) COMP-5.
01  WS-J                    PIC 9(9) COMP-5.
01  WS-MAIN-FILES           PIC 9(4) COMP-5.
01  WS-PATH-STATUS          PIC 9(4) COMP-5.
01  WS-ROOT                 PIC 9(9) COMP-5.
01  WS-NODE                 PIC 9(9) COMP-5.
01  WS-DEPTH                PIC S9(9) COMP-5.
01  WS-TOK                  PIC 9(9) COMP-5.
01  WS-S                    PIC 9(9) COMP-5.
01  WS-P                    PIC 9(9) COMP-5.
*> The program of the metrics plumbline doc is writing.
01  WS-M                    PIC 9(9) COMP-5.
01  WS-DOC-FIRST            PIC X.
*> plumbline fields --unused: only the items no program names.
01  WS-FIELDS-UNUSED        PIC X VALUE "N".
*> plumbline xref: "Y" once a program has been listed.
01  WS-XREF-ANY             PIC X.
*> plumbline duplicates: the smallest paragraph body, in tokens.
01  WS-DUP-MIN              PIC 9(9) COMP-5 VALUE 50.
*> plumbline lineage: how many statements deep, and B(ackward) or
*> F(orward).
01  WS-LINEAGE-DEPTH        PIC 9(9) COMP-5 VALUE 3.
01  WS-LINEAGE-DIRECTION    PIC X VALUE "B".
01  WS-LINEAGE-ACTION       PIC X.
01  WS-U                    PIC 9(9) COMP-5.
01  WS-E                    PIC 9(9) COMP-5.
01  WS-RULE                 PIC 9(4) COMP-5.
01  WS-FAIL-ON              PIC X VALUE "W".
01  WS-FAILING              PIC 9(9) COMP-5.
*> The libraries see its first five characters; codeclimate is only
*> for check.
01  WS-REPORT               PIC X(11) VALUE "text".
01  WS-C                    PIC 9(9) COMP-5.
01  WS-K                    PIC 9(9) COMP-5.
01  WS-POS-FILE             PIC 9(4) COMP-5.
01  WS-POS-LINE             PIC 9(9) COMP-5.
01  WS-POS-COLUMN           PIC 9(4) COMP-5.
01  WS-USE-CONFIG           PIC X VALUE "Y".
01  WS-CONFIG-GIVEN         PIC X VALUE "N".
01  WS-CONFIG-PATH          PIC X(512) VALUE "plumbline.conf".
01  WS-CONFIG-PATH-LEN      PIC 9(9) COMP-5.
01  WS-SAVED-INDEX          PIC 9(4).
01  WS-SETTING              PIC 9(4) COMP-5.
01  WS-SEVERITY-RULE        PIC X(31).
01  WS-SEVERITY-LEVEL       PIC X(31).
01  WS-BASELINE             PIC X(512) VALUE SPACES.
01  WS-WRITE-BASELINE       PIC X(512) VALUE SPACES.
01  WS-BASELINE-COUNT       PIC 9(9) COMP-5.
*> check --diff FILE: report only the findings on the lines it adds.
01  WS-DIFF                 PIC X(512) VALUE SPACES.
01  WS-DIFF-COUNT           PIC 9(9) COMP-5.
01  WS-COMMAND              PIC X(12).
01  WS-FIRST                PIC X.
01  WS-GRAPH-KIND           PIC X(10) VALUE "performs".
01  WS-IMPACT-NAME          PIC X(512).
01  WS-FOUND                PIC X.
01  WS-FORMAT-TO            PIC X(5) VALUE SPACES.
01  WS-FORMAT-CHECK         PIC X VALUE "N".
01  WS-CHANGED              PIC X.
*> fix: the edits accepted for the file, what became of a fix, and the
*> fixes found.
COPY "plbfixl.cpy".
*> check: the fixes of the findings, for the JSON and SARIF reports.
COPY "plbfixs.cpy".
01  WS-FIX-RESULT           PIC X.
*> F: write the fixed file; D: a unified diff of the fixes (--patch).
01  WS-FIX-MODE             PIC X VALUE "F".
01  WS-FIX-COUNT            PIC 9(9) COMP-5.
*> Language server: one message in, one out, the text of a document.
78  LSP-SIZE                    VALUE 4000000.
01  WS-LSP-IN               PIC X(LSP-SIZE).
01  WS-LSP-IN-LEN           PIC 9(9) COMP-5.
01  WS-LSP-OUT              PIC X(LSP-SIZE).
01  WS-LSP-PTR              PIC 9(9) COMP-5.
01  WS-LSP-TEXT             PIC X(LSP-SIZE).
01  WS-LSP-TEXT-LEN         PIC 9(9) COMP-5.
01  WS-LSP-STATUS           PIC 9(4) COMP-5.
01  WS-LSP-METHOD           PIC X(64).
01  WS-LSP-ID               PIC X(64).
01  WS-LSP-ID-KIND          PIC X.
01  WS-LSP-KIND             PIC X.
01  WS-LSP-VALUE            PIC X(1024).
01  WS-LSP-VALUE-LEN        PIC 9(9) COMP-5.
01  WS-LSP-URI              PIC X(1024).
01  WS-LSP-SHUTDOWN         PIC X VALUE "N".
01  WS-LSP-DONE             PIC X VALUE "N".
01  WS-LSP-TMP              PIC X(400).
01  WS-LSP-STAMP            PIC X(21).
01  WS-LSP-LINE             PIC 9(9) COMP-5.
01  WS-LSP-CHAR             PIC 9(9) COMP-5.
01  WS-LSP-TOKEN            PIC 9(9) COMP-5.
*> textDocument/selectionRange: the position being answered, the
*> nodes that contain its token, and the range written last.
01  WS-SEL-N                PIC 9(9) COMP-5.
01  WS-SEL-K                PIC 9(9) COMP-5.
01  WS-SEL-NODE             PIC 9(9) COMP-5.
01  WS-SEL-CHILD            PIC 9(9) COMP-5.
01  WS-SEL-DEPTH            PIC 9(9) COMP-5.
01  WS-SEL-PATH             PIC 9(9) COMP-5 OCCURS 200 TIMES.
01  WS-SEL-FIRST            PIC 9(9) COMP-5.
01  WS-SEL-LAST             PIC 9(9) COMP-5.
01  WS-SEL-PREV-FIRST       PIC 9(9) COMP-5.
01  WS-SEL-PREV-LAST        PIC 9(9) COMP-5.
01  WS-SEL-OPEN             PIC 9(9) COMP-5.
01  WS-SEL-OFFSET           PIC 9(9) COMP-5.
*> Hover on a host variable: the statement, pair, and column.
01  WS-SQL-S                PIC 9(9) COMP-5.
01  WS-SQL-P                PIC 9(9) COMP-5.
01  WS-SQL-C                PIC 9(9) COMP-5.
01  WS-SEL-REST             PIC 9(9) COMP-5.
01  WS-LSP-SYMBOL           PIC 9(9) COMP-5.
01  WS-LSP-UNIT             PIC 9(9) COMP-5.
*> textDocument/documentHighlight rather than references, and whether
*> the declaration is listed.
01  WS-LSP-HIGHLIGHT        PIC X.
01  WS-LSP-DECLARATION      PIC X.
01  WS-LSP-QUALIFIER        PIC X(31).
*> workspace/symbol: the query, in upper case (spaces: every name).
01  WS-LSP-QUERY            PIC X(31).
*> callHierarchy: incoming (I) or outgoing (O), the unit at the other
*> end of the edges being listed, and the edge.
01  WS-LSP-DIRECTION        PIC X.
01  WS-LSP-OTHER            PIC 9(9) COMP-5.
01  WS-LSP-EDGE             PIC 9(9) COMP-5.
01  WS-LSP-EDGE-2           PIC 9(9) COMP-5.
01  WS-LSP-ITEM-UNIT        PIC 9(9) COMP-5.
01  WS-LSP-BRACE            PIC 9(9) COMP-5.
*> semanticTokens: per token, its type (an index into the legend, 9
*> for none) and whether it declares the name.
01  WS-LSP-TOKEN-TYPE       PIC 9 OCCURS TK-MAX TIMES.
01  WS-LSP-TOKEN-DECL       PIC 9 OCCURS TK-MAX TIMES.
01  WS-LSP-PREV-LINE        PIC 9(9) COMP-5.
01  WS-LSP-PREV-CHAR        PIC 9(9) COMP-5.
01  WS-LSP-SPAN             PIC 9(9) COMP-5.
*> textDocument/rename: the new name, and the tokens to change, by
*> file.
01  WS-LSP-NEW-NAME         PIC X(31).
01  WS-LSP-NEW-LEN          PIC 9(9) COMP-5.
01  WS-LSP-OLD-NAME         PIC X(31).
01  WS-LSP-UPPER-NAME       PIC X(31).
*> textDocument/completion: the names offered so far, by hash.
78  CS-BUCKETS                  VALUE 4093.
78  CS-MAX                      VALUE 120000.
01  WS-CS-HEAD              PIC 9(9) COMP-5 OCCURS CS-BUCKETS TIMES.
01  WS-CS-COUNT             PIC 9(9) COMP-5.
01  WS-CS-ENTRY             OCCURS CS-MAX TIMES.
    05  WS-CS-NAME          PIC X(31).
    05  WS-CS-NEXT          PIC 9(9) COMP-5.
01  WS-LSP-SEEN-NAME        PIC X(31).
01  WS-LSP-SEEN             PIC X.
01  WS-LSP-HASH             PIC 9(9) COMP-5.
*> textDocument/codeLens: PERFORM and GO TO statements naming a unit.
01  WS-LSP-PERFORMS         PIC 9(9) COMP-5.
01  WS-LSP-GOTOS            PIC 9(9) COMP-5.
*> textDocument/codeLens: the references to each record.
01  WS-LENS-READS           PIC 9(9) COMP-5 OCCURS 100000 TIMES.
01  WS-LENS-WRITES          PIC 9(9) COMP-5 OCCURS 100000 TIMES.
01  WS-LENS-PASSED          PIC 9(9) COMP-5 OCCURS 100000 TIMES.
01  WS-LENS-FIRST           PIC X.
01  WS-LENS-WORD            PIC X(8).
*> textDocument/codeAction: the rules already offered for the line.
01  WS-LSP-OFFERED          PIC X(400).
01  WS-LSP-INDENT           PIC 9(4) COMP-5.
01  WS-LSP-BLANKS           PIC X(64) VALUE SPACES.
01  WS-LSP-WORD-KIND        PIC X.
*> A token's text, for a hover that shows code as written.
01  WS-LSP-WORD             PIC X(256).
78  LSP-EDIT-MAX            VALUE 10000.
01  WS-LSP-EDITS.
    05  WS-LSP-EDIT-COUNT   PIC 9(9) COMP-5.
    05  WS-LSP-EDIT-TOKEN   PIC 9(9) COMP-5 OCCURS LSP-EDIT-MAX TIMES.
    05  WS-LSP-EDIT-DONE    PIC X OCCURS LSP-EDIT-MAX TIMES.
01  WS-LSP-FIRST            PIC X.
01  WS-LSP-SEVERITY         PIC X.
01  WS-LSP-TEXT-PATH        PIC X(512).
01  WS-LSP-NAME             PIC X(31).
*> textDocument/hover: the text of a table's hover.
01  WS-LSP-HOVER            PIC X(4096).
*> The program a CALL at the position names (LSP-FIND-CALLED).
01  WS-CALL-WHERE           PIC X.
01  WS-CALL-TOKEN           PIC 9(9) COMP-5.
01  WS-CALL-PATH            PIC X(1024).
01  WS-CALL-LINE            PIC 9(9) COMP-5.
01  WS-CALL-USING           PIC X(512).
01  WS-CALL-HOVER           PIC X(1024).
*> textDocument/signatureHelp: the token at or before the position,
*> whether the position is in or just after it, the CALL, its USING, the program's parameters, and
*> the one active.
01  WS-SIG-TOKEN            PIC 9(9) COMP-5.
01  WS-SIG-AT               PIC X.
01  WS-SIG-STMT             PIC 9(9) COMP-5.
01  WS-SIG-USING            PIC 9(9) COMP-5.
01  WS-SIG-SKIP             PIC X.
01  WS-SIG-WORD             PIC X(31).
01  WS-SIG-COUNT            PIC 9(4) COMP-5.
01  WS-SIG-PARAM            PIC X(31) OCCURS 64 TIMES.
01  WS-SIG-ACTIVE           PIC 9(4) COMP-5.
01  WS-LSP-PIC              PIC X(64).
01  WS-LSP-KIND-NUM         PIC 9(4) COMP-5.
78  LSP-DOC-MAX             VALUE 64.
01  WS-LSP-DOCS.
    05  WS-LSP-DOC          OCCURS LSP-DOC-MAX TIMES.
        10  DOC-URI         PIC X(1024).
        10  DOC-DIR         PIC X(512).
        10  DOC-TEMP        PIC X(512).
01  WS-LSP-DOC-INDEX        PIC 9(4) COMP-5.
01  WS-LSP-SLOT             PIC 9(4) COMP-5.
01  WS-LSP-EXIT-ROUTINE     PIC X(8) VALUE "_exit".
01  WS-LSP-EXIT-STATUS      PIC S9(9) COMP-5.
01  WS-LEN                  PIC 9(9) COMP-5.
*> check keeps the lines of one input (and its copybooks) at a time:
*> the source set as it was before the input was read, and the first
*> finding the input added.
01  WS-MARK-LINES           PIC 9(9) COMP-5.
01  WS-MARK-HEAP            PIC 9(9) COMP-5.
01  WS-FIRST-FINDING        PIC 9(9) COMP-5.

PROCEDURE DIVISION.
MAIN-LOGIC.
    *> A closed pipe (plumbline rules | head) ends the program quietly,
    *> as it does other tools: the run-time library would report it as
    *> a crash. SIGPIPE is 13 and SIG_DFL 0 on Linux and macOS.
    CALL STATIC "signal" USING BY VALUE 13 BY VALUE 0
    ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
    IF WS-ARG-COUNT = 0
        PERFORM SHOW-USAGE
        MOVE 2 TO WS-EXIT-CODE
    ELSE
        MOVE 1 TO WS-ARG-INDEX
        PERFORM NEXT-ARG
        EVALUATE WS-ARG
            WHEN "--version"
            WHEN "-V"
                DISPLAY PLB-NAME " " PLB-VERSION
            WHEN "--help"
            WHEN "-h"
                PERFORM SHOW-USAGE
            WHEN "dump"
                PERFORM DUMP-COMMAND
            WHEN "check"
                MOVE "check" TO WS-COMMAND
                PERFORM CHECK-COMMAND
            WHEN "metrics"
                MOVE "metrics" TO WS-COMMAND
                PERFORM METRICS-COMMAND
            WHEN "graph"
                MOVE "graph" TO WS-COMMAND
                MOVE "dot" TO WS-REPORT
                PERFORM GRAPH-COMMAND
            WHEN "impact"
                MOVE "impact" TO WS-COMMAND
                PERFORM IMPACT-COMMAND
            WHEN "format"
                MOVE "format" TO WS-COMMAND
                PERFORM FORMAT-COMMAND
            WHEN "fix"
                MOVE "fix" TO WS-COMMAND
                PERFORM FIX-COMMAND
            WHEN "lsp"
                MOVE "lsp" TO WS-COMMAND
                PERFORM LSP-COMMAND
            WHEN "rules"
                MOVE "rules" TO WS-COMMAND
                PERFORM RULES-COMMAND
            WHEN "inventory"
                MOVE "inventory" TO WS-COMMAND
                PERFORM INVENTORY-COMMAND
            WHEN "layout"
                MOVE "layout" TO WS-COMMAND
                PERFORM LAYOUT-COMMAND
            WHEN "doc"
                MOVE "doc" TO WS-COMMAND
                PERFORM DOC-COMMAND
            WHEN "fields"
                MOVE "fields" TO WS-COMMAND
                PERFORM FIELDS-COMMAND
            WHEN "xref"
                MOVE "xref" TO WS-COMMAND
                PERFORM XREF-COMMAND
            WHEN "duplicates"
                MOVE "duplicates" TO WS-COMMAND
                PERFORM DUPLICATES-COMMAND
            WHEN "lineage"
                MOVE "lineage" TO WS-COMMAND
                PERFORM LINEAGE-COMMAND
            WHEN "crud"
                MOVE "crud" TO WS-COMMAND
                PERFORM CRUD-COMMAND
            WHEN "summary"
                *> check, with a row per program instead of findings.
                MOVE "summary" TO WS-COMMAND
                PERFORM CHECK-COMMAND
            WHEN OTHER
                IF WS-ARG(1:1) = "-"
                    PERFORM UNKNOWN-OPTION
                ELSE
                    DISPLAY PLB-NAME ": unknown command '"
                        WS-ARG(1:WS-ARG-LEN) "'" UPON SYSERR
                    PERFORM SUGGEST-HELP
                END-IF
        END-EVALUATE
    END-IF
    MOVE WS-EXIT-CODE TO RETURN-CODE
    STOP RUN.

*> Fetch argument WS-ARG-INDEX into WS-ARG and advance the index.
NEXT-ARG.
    MOVE SPACES TO WS-ARG
    IF WS-ARG-INDEX <= WS-ARG-COUNT
        DISPLAY WS-ARG-INDEX UPON ARGUMENT-NUMBER
        ACCEPT WS-ARG FROM ARGUMENT-VALUE
    END-IF
    ADD 1 TO WS-ARG-INDEX
    CALL "PLB-STR-LENGTH" USING WS-ARG WS-ARG-LEN.

UNKNOWN-OPTION.
    DISPLAY PLB-NAME ": unknown option '" WS-ARG(1:WS-ARG-LEN) "'"
        UPON SYSERR
    PERFORM SUGGEST-HELP.

SUGGEST-HELP.
    DISPLAY "Try 'plumbline --help' for more information."
        UPON SYSERR
    MOVE 2 TO WS-EXIT-CODE.

SHOW-USAGE.
    DISPLAY "Usage: plumbline [OPTION]..."
    DISPLAY "       plumbline check [OPTION]... FILE..."
    DISPLAY "       plumbline metrics [OPTION]... FILE..."
    DISPLAY "       plumbline graph [--kind KIND] [OPTION]... FILE..."
    DISPLAY "       plumbline impact NAME [OPTION]... FILE..."
    DISPLAY "       plumbline impact --changed LIST [--report text|json] [OPTION]... FILE..."
    DISPLAY "       plumbline inventory [--report text|json] [OPTION]... FILE..."
    DISPLAY "       plumbline layout [--report text|json|csv|md] [OPTION]... FILE..."
    DISPLAY "       plumbline doc [OPTION]... FILE..."
    DISPLAY "       plumbline fields [--report text|json] [--unused] [OPTION]... FILE..."
    DISPLAY "       plumbline xref [--report text|json] [OPTION]... FILE..."
    DISPLAY "       plumbline duplicates [--min-tokens N] [--report text|json] [OPTION]... FILE..."
    DISPLAY "       plumbline crud [--report text|csv|json] [OPTION]... FILE..."
    DISPLAY "       plumbline summary [--report text|md|csv|json] [OPTION]... FILE..."
    DISPLAY "       plumbline lineage NAME [--depth N] [--forward] [--report text|json|dot] [OPTION]... FILE..."
    DISPLAY "       plumbline format --to fixed|free [--check] FILE..."
    DISPLAY "       plumbline fix [--check|--patch] [OPTION]... FILE..."
    DISPLAY "       plumbline lsp [OPTION]..."
    DISPLAY "       plumbline rules [--report text|json] [OPTION]..."
    DISPLAY "       plumbline dump lines [--format FORMAT] FILE..."
    DISPLAY "       plumbline dump tokens [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump expanded [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump ast [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump symbols [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump flow [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump refs [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump calls [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump sql [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump jcl FILE..."
    DISPLAY "       plumbline dump bms FILE..."
    DISPLAY "       plumbline dump csd FILE..."
    DISPLAY "       plumbline dump ims FILE..."
    DISPLAY "Static analysis for COBOL programs."
    CALL STATIC "putchar" USING BY VALUE 10
    DISPLAY "Options:"
    DISPLAY "  -h, --help       show this help and exit"
    DISPLAY "  -V, --version    show version information and exit"
    CALL STATIC "putchar" USING BY VALUE 10
    DISPLAY "Commands:"
    DISPLAY "  check            analyze programs and report findings"
    DISPLAY "  metrics          report size and complexity of programs"
    DISPLAY "                   and their paragraphs"
    DISPLAY "  graph            draw the PERFORM graph of each program"
    DISPLAY "                   (--kind performs), the CALL graph"
    DISPLAY "                   (calls), the copybook graph"
    DISPLAY "                   (copybooks), what JCL jobs run"
    DISPLAY "                   (jobs), or which job steps read and"
    DISPLAY "                   write which data sets (datasets), or"
    DISPLAY "                   how CICS transactions, programs, maps,"
    DISPLAY "                   and files connect (cics), or which"
    DISPLAY "                   programs create, read, update, and"
    DISPLAY "                   delete which tables and files (crud),"
    DISPLAY "                   as DOT or JSON"
    DISPLAY "  inventory        list the programs, jobs, transactions, and"
    DISPLAY "                   maps of the input, and how they fit together"
    DISPLAY "  layout           list the records of programs and copybooks"
    DISPLAY "                   with the start and length of each item"
    DISPLAY "  doc              write a Markdown page for each program: what"
    DISPLAY "                   starts it, what it uses, its paragraphs,"
    DISPLAY "                   and its records"
    DISPLAY "  fields           list the items of each copybook and how"
    DISPLAY "                   many programs name them (--unused: only"
    DISPLAY "                   those no program names)"
    DISPLAY "  xref             list the data items and paragraphs of each"
    DISPLAY "                   program with the lines that name them"
    DISPLAY "  duplicates       list paragraphs with the same code, in one"
    DISPLAY "                   program or across programs (--min-tokens:"
    DISPLAY "                   the smallest body counted, default 50)"
    DISPLAY "  crud             list which programs create, read, update,"
    DISPLAY "                   and delete which DB2 tables, files, and"
    DISPLAY "                   CICS files"
    DISPLAY "  summary          one row per program: lines, complexity,"
    DISPLAY "                   maintainability, and findings by"
    DISPLAY "                   severity"
    DISPLAY "  lineage NAME     show the statements that give data item NAME"
    DISPLAY "                   its value and the items they read, and"
    DISPLAY "                   theirs, to --depth (3); --forward: where"
    DISPLAY "                   its value goes"
    DISPLAY "  impact NAME      list what includes copybook NAME or"
    DISPLAY "                   calls program NAME, directly or not,"
    DISPLAY "                   where data item NAME is used, or which"
    DISPLAY "                   job steps read and write data set NAME;"
    DISPLAY "                   impact --changed LIST: the programs and"
    DISPLAY "                   job steps the files in LIST reach"
    DISPLAY "  format           rewrite a file in fixed or free format"
    DISPLAY "                   (--to); --check only tells whether"
    DISPLAY "                   that would change it"
    DISPLAY "  fix              rewrite a file with the fixes of its"
    DISPLAY "                   findings that have one; --check lists"
    DISPLAY "                   them, --patch writes them as a diff"
    DISPLAY "  rules            list the rules, with their severity and"
    DISPLAY "                   whether they are on, as configured"
    DISPLAY "  lsp              run as a language server for editors, on"
    DISPLAY "                   standard input and output"
    DISPLAY "  dump lines       show how each source line was read"
    DISPLAY "  dump tokens      show the tokens of each source file"
    DISPLAY "  dump expanded    show the tokens after COPY and REPLACE"
    DISPLAY "  dump ast         show the syntax tree"
    DISPLAY "  dump symbols     show data items with sizes and offsets"
    DISPLAY "  dump flow        show paragraphs, sections, and control flow"
    DISPLAY "  dump refs        show what each name in the procedures refers to"
    DISPLAY "  dump calls       show programs, their parameters, and CALLs"
    DISPLAY "  dump sql         show the tables, cursors, and host variables"
    DISPLAY "                   of embedded SQL"
    DISPLAY "  dump jcl         show the jobs, steps, and DD statements of JCL"
    DISPLAY "  dump bms         show the maps and fields of CICS BMS sources"
    DISPLAY "  dump csd         show the CICS resources DFHCSDUP input defines"
    DISPLAY "  dump ims         show the databases and PSBs of IMS DBD and PSB sources"
    CALL STATIC "putchar" USING BY VALUE 10
    DISPLAY "Command options:"
    DISPLAY "  --format FORMAT  reference format: fixed, free, variable,"
    DISPLAY "                   xopen, terminal, cobolx, xcard, crt,"
    DISPLAY "                   or auto"
    DISPLAY "                   (default auto)"
    DISPLAY "  --debug          treat debugging lines as code"
    DISPLAY "  -I DIR           search DIR for copybooks (repeatable)"
    DISPLAY "  --tab-width N    tab stops every N columns (default 8)"
    DISPLAY "  --intrinsics all|NAME,..."
    DISPLAY "                   intrinsic functions that may be named"
    DISPLAY "                   without FUNCTION (cobc -fintrinsics)"
    DISPLAY "  -D, --define NAME"
    DISPLAY "                   NAME is defined for conditional"
    DISPLAY "                   compilation (>>IF NAME DEFINED)"
    DISPLAY "  --files-from LIST"
    DISPLAY "                   also analyze the files listed in LIST,"
    DISPLAY "                   one per line (- for standard input)"
    DISPLAY "  --config FILE    read settings from FILE (default:"
    DISPLAY "                   plumbline.conf, when there is one)"
    DISPLAY "  --no-config      do not read a configuration file"
    CALL STATIC "putchar" USING BY VALUE 10
    DISPLAY "Check options:"
    DISPLAY "  --enable RULE    enable a rule (id or name; repeatable)"
    DISPLAY "  --disable RULE   disable a rule (id or name; repeatable)"
    DISPLAY "  --fail-on LEVEL  exit 1 on findings at or above LEVEL:"
    DISPLAY "                   error, warning (default), note, never"
    DISPLAY "  --report FORMAT  text (default), json, sarif, html, md,"
    DISPLAY "                   codeclimate, junit, or checkstyle; for"
    DISPLAY "                   metrics: text, json, or csv; for"
    DISPLAY "                   graph: dot (default) or json"
    DISPLAY "  --baseline FILE  do not report the findings listed in FILE"
    DISPLAY "  --diff FILE      report only the findings on lines the"
    DISPLAY "                   unified diff in FILE adds or changes"
    DISPLAY "  --write-baseline FILE"
    DISPLAY "                   write the findings to FILE instead of"
    DISPLAY "                   reporting them".

*> rules --------------------------------------------------------

*> The rules, with the settings of the configuration and the options
*> applied: what plumbline check would run.
RULES-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    IF IP-COUNT > 0
        DISPLAY PLB-NAME ": rules takes no files" UPON SYSERR
        PERFORM SUGGEST-HELP
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-RULES-LIST" USING PLB-RULES WS-REPORT.

*> check --------------------------------------------------------

CHECK-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    CALL "PLB-FIND-INIT" USING PLB-FINDINGS
    CALL "PLB-CALL-INIT" USING PLB-CALL-GRAPH
    MOVE 0 TO SM-COUNT SM-DROPPED FK-FIX-COUNT FK-EDIT-COUNT
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    *> One input at a time: read it, check it, settle which of its
    *> findings comments suppress, and let its lines go. What is kept
    *> (findings, the call graph) refers to files by id and line.
    *> JCL and BMS first, so that each program can be checked against
    *> the maps it copies.
    PERFORM READ-OTHER-INPUTS
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM TEST-JCL-INPUT
        IF WS-IS-JCL = "N"
            PERFORM START-INPUT
        END-IF
        IF WS-IS-JCL = "N" AND SF-LOADED(WS-FILE-ID) = "Y"
            COMPUTE WS-FIRST-FINDING = FN-COUNT + 1
            PERFORM ANALYZE-FILE
            CALL "PLB-CHECK-RUN" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-FLOW PLB-REFS PLB-INCLUSIONS
                PLB-RULES PLB-FINDINGS
            CALL "PLB-RULE-SYMBOLIC-MAPS" USING PLB-SOURCE-SET
                PLB-TOKENS PLB-SYMBOLS PLB-BMS PLB-RULES PLB-FINDINGS
            CALL "PLB-CALL-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-REFS PLB-CALL-GRAPH
            CALL "PLB-FIND-SUPPRESS-RANGE" USING PLB-SOURCE-SET
                PLB-RULES PLB-FINDINGS WS-FIRST-FINDING FN-COUNT
            IF WS-REPORT = "json" OR WS-REPORT = "sarif"
                PERFORM KEEP-FIXES
            END-IF
            IF WS-COMMAND = "summary"
                CALL "PLB-METRICS-COMPUTE" USING PLB-SOURCE-SET
                    PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-FLOW PLB-METRICS
                CALL "PLB-SUMMARY-ADD" USING PLB-METRICS PLB-SUMMARY
            END-IF
            PERFORM FORGET-SOURCE-LINES
        END-IF
    END-PERFORM
    *> Rules about calls between programs, in any of the files.
    COMPUTE WS-FIRST-FINDING = FN-COUNT + 1
    CALL "PLB-CALL-RESOLVE" USING PLB-CALL-GRAPH
    CALL "PLB-RULE-CALLS" USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH
    *> Maps, and the programs that send and receive them.
    CALL "PLB-RULE-BMS" USING PLB-RULES PLB-FINDINGS PLB-BMS
        PLB-CALL-GRAPH
    CALL "PLB-RULE-CICS" USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH
        PLB-CSD
    CALL "PLB-RULE-K007" USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH
    CALL "PLB-RULE-SQL-TABLES" USING PLB-RULES PLB-FINDINGS
        PLB-CALL-GRAPH
    CALL "PLB-RULE-IMS" USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH
        PLB-JCL PLB-IMS
    CALL "PLB-RULE-APPLICATION" USING PLB-RULES PLB-FINDINGS
        PLB-CALL-GRAPH PLB-JCL PLB-CSD
    CALL "PLB-RULE-C053" USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH
        PLB-JCL
    PERFORM SUPPRESS-LATE-FINDINGS
    *> Programs against the JCL that runs them. JCL has no suppression
    *> comments.
    CALL "PLB-RULE-JCL" USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH
        PLB-JCL
    IF FN-DROPPED > 0
        PERFORM REPORT-DROPPED-FINDINGS
    END-IF
    CALL "PLB-FIND-SORT" USING PLB-FINDINGS
    IF WS-WRITE-BASELINE NOT = SPACES
        PERFORM WRITE-BASELINE
        EXIT PARAGRAPH
    END-IF
    IF WS-BASELINE NOT = SPACES
        CALL "PLB-BASELINE-APPLY" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-RULES PLB-FINDINGS WS-BASELINE WS-BASELINE-COUNT
    END-IF
    IF WS-DIFF NOT = SPACES
        CALL "PLB-DIFF-APPLY" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-FINDINGS WS-DIFF WS-DIFF-COUNT
    END-IF
    *> summary: the table, and the diagnostics; it fails only when
    *> the input cannot be read.
    IF WS-COMMAND = "summary"
        CALL "PLB-SUMMARY-PRINT" USING PLB-SOURCE-SET PLB-FINDINGS
            PLB-SUMMARY WS-REPORT
        PERFORM REPORT-DIAGNOSTICS
        IF DG-ERRORS > 0
            MOVE 1 TO WS-EXIT-CODE
        END-IF
        EXIT PARAGRAPH
    END-IF
    EVALUATE WS-REPORT
        WHEN "json"
            CALL "PLB-REPORT-JSON" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                PLB-RULES PLB-FINDINGS PLB-FIX-STORE
        WHEN "sarif"
            CALL "PLB-REPORT-SARIF" USING PLB-SOURCE-SET
                PLB-DIAGNOSTICS PLB-RULES PLB-FINDINGS PLB-FIX-STORE
        WHEN "html"
            CALL "PLB-REPORT-HTML" USING PLB-SOURCE-SET
                PLB-DIAGNOSTICS PLB-RULES PLB-FINDINGS
        WHEN "md"
            CALL "PLB-REPORT-MD" USING PLB-SOURCE-SET
                PLB-DIAGNOSTICS PLB-RULES PLB-FINDINGS
        WHEN "codeclimate"
            CALL "PLB-REPORT-CODECLIMATE" USING PLB-SOURCE-SET
                PLB-DIAGNOSTICS PLB-RULES PLB-FINDINGS
        WHEN "junit"
            CALL "PLB-REPORT-JUNIT" USING PLB-SOURCE-SET
                PLB-DIAGNOSTICS PLB-RULES PLB-FINDINGS WS-MAIN-FILES
        WHEN "checkstyle"
            CALL "PLB-REPORT-CHECKSTYLE" USING PLB-SOURCE-SET
                PLB-DIAGNOSTICS PLB-RULES PLB-FINDINGS WS-MAIN-FILES
        WHEN OTHER
            PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
                IF FN-SUPPRESSED(WS-I) = "N"
                    PERFORM PRINT-FINDING
                END-IF
            END-PERFORM
            PERFORM REPORT-DIAGNOSTICS
    END-EVALUATE
    PERFORM COUNT-FAILING
    IF WS-FAILING > 0 OR DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> WS-IS-JCL = "Y" when input WS-FILE-ID is JCL: a file named
*> *.jcl or *.prc, in either case; "B" when it is a BMS map source,
*> *.bms; "C" for CICS resource definitions, *.csd; "I" for IMS
*> definitions, *.dbd and *.psb.
TEST-JCL-INPUT.
    MOVE "N" TO WS-IS-JCL
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET WS-FILE-ID WS-PATH
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-PATH-LEN
    IF WS-PATH-LEN > 4
        MOVE FUNCTION UPPER-CASE(WS-PATH(WS-PATH-LEN - 3:4))
            TO WS-EXTENSION
        IF WS-EXTENSION = ".JCL" OR WS-EXTENSION = ".PRC"
            MOVE "Y" TO WS-IS-JCL
        END-IF
        IF WS-EXTENSION = ".BMS"
            MOVE "B" TO WS-IS-JCL
        END-IF
        IF WS-EXTENSION = ".CSD"
            MOVE "C" TO WS-IS-JCL
        END-IF
        IF WS-EXTENSION = ".DBD" OR WS-EXTENSION = ".PSB"
            MOVE "I" TO WS-IS-JCL
        END-IF
    END-IF.

*> The JCL and BMS inputs of the run, into PLB-JCL and PLB-BMS.
READ-OTHER-INPUTS.
    CALL "PLB-JCL-INIT" USING PLB-JCL
    CALL "PLB-BMS-INIT" USING PLB-BMS
    CALL "PLB-CSD-INIT" USING PLB-CSD
    CALL "PLB-IMS-INIT" USING PLB-IMS
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM TEST-JCL-INPUT
        IF WS-IS-JCL NOT = "N"
            PERFORM READ-JCL-INPUT
        END-IF
    END-PERFORM.

READ-JCL-INPUT.
    IF WS-IS-JCL = "B"
        CALL "PLB-BMS-READ" USING WS-PATH(1:WS-PATH-LEN) WS-FILE-ID
            PLB-BMS WS-STATUS
    END-IF
    IF WS-IS-JCL = "C"
        CALL "PLB-CSD-READ" USING WS-PATH(1:WS-PATH-LEN) WS-FILE-ID
            PLB-CSD WS-STATUS
    END-IF
    IF WS-IS-JCL = "I"
        CALL "PLB-IMS-READ" USING WS-PATH(1:WS-PATH-LEN) WS-FILE-ID
            PLB-IMS WS-STATUS
    END-IF
    IF WS-IS-JCL = "Y"
        CALL "PLB-JCL-READ" USING WS-PATH(1:WS-PATH-LEN) WS-FILE-ID
            PLB-JCL WS-STATUS
    END-IF
    IF WS-STATUS NOT = 0
        MOVE SPACES TO WS-OUT
        STRING "cannot read " DELIMITED BY SIZE
               WS-PATH(1:WS-PATH-LEN) DELIMITED BY SIZE
            INTO WS-OUT
        MOVE 0 TO WS-POS-LINE WS-POS-COLUMN
        CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "JL001" WS-FILE-ID
            WS-POS-LINE WS-POS-COLUMN WS-OUT
    END-IF.

*> The fixes of the findings made since WS-FIRST-FINDING, kept while
*> the input's lines are loaded, for the JSON and SARIF reports.
KEEP-FIXES.
    PERFORM VARYING WS-I FROM WS-FIRST-FINDING BY 1
            UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N"
            CALL "PLB-FIX-FINDING" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-RULES PLB-FINDINGS WS-I PLB-FIX
            IF FX-EDIT-COUNT > 0
                CALL "PLB-FIX-KEEP" USING PLB-FINDINGS WS-I PLB-FIX
                    PLB-FIX-STORE
            END-IF
        END-IF
    END-PERFORM.

*> Release the input's lines. The SS-LINE indexes of findings made
*> since WS-FIRST-FINDING point at released lines now.
FORGET-SOURCE-LINES.
    PERFORM END-INPUT
    PERFORM VARYING WS-I FROM WS-FIRST-FINDING BY 1
            UNTIL WS-I > FN-COUNT
        MOVE 0 TO FN-SRC-LINE(WS-I)
    END-PERFORM.

*> A report that leaves findings out must say so.
REPORT-DROPPED-FINDINGS.
    MOVE FN-DROPPED TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    MOVE SPACES TO WS-OUT
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
           " findings were left out: a run keeps at most " DELIMITED BY SIZE
           FN-MAX DELIMITED BY SIZE
           "; check fewer files at a time" DELIMITED BY SIZE
        INTO WS-OUT
    MOVE 0 TO WS-POS-FILE WS-POS-LINE WS-POS-COLUMN
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS "E" "FN001" WS-POS-FILE
        WS-POS-LINE WS-POS-COLUMN WS-OUT.

*> Findings from WS-FIRST-FINDING on were made after the lines of
*> their files were released: read each file again to see its
*> suppression comments.
SUPPRESS-LATE-FINDINGS.
    PERFORM VARYING WS-I FROM WS-FIRST-FINDING BY 1
            UNTIL WS-I > FN-COUNT
        CALL "PLB-SRC-LINE-INDEX" USING PLB-SOURCE-SET FN-FILE-ID(WS-I)
            FN-LINE(WS-I) FN-SRC-LINE(WS-I)
        MOVE WS-I TO WS-J
        CALL "PLB-FIND-SUPPRESS-RANGE" USING PLB-SOURCE-SET PLB-RULES
            PLB-FINDINGS WS-I WS-J
        MOVE 0 TO FN-SRC-LINE(WS-I)
    END-PERFORM.

*> Record the findings as accepted, rather than report them. A
*> baseline that is in use is not applied: the new one lists all
*> findings.
WRITE-BASELINE.
    CALL "PLB-BASELINE-WRITE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-RULES PLB-FINDINGS WS-WRITE-BASELINE WS-BASELINE-COUNT
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    ELSE
        MOVE WS-BASELINE-COUNT TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        CALL "PLB-STR-LENGTH" USING WS-WRITE-BASELINE WS-PATH-LEN
        DISPLAY PLB-NAME ": wrote " WS-NUM-TEXT(1:WS-NUM-LEN)
            " findings to " WS-WRITE-BASELINE(1:WS-PATH-LEN) UPON SYSERR
    END-IF.

*> metrics ----------------------------------------------------------

METRICS-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    MOVE "Y" TO WS-FIRST
    IF WS-REPORT = "json"
        DISPLAY "{"
        DISPLAY '  "tool": "' PLB-NAME '",'
        DISPLAY '  "version": "' PLB-VERSION '",'
        DISPLAY '  "programs": ['
    END-IF
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM START-INPUT
        IF SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            CALL "PLB-METRICS-COMPUTE" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-FLOW PLB-METRICS
            EVALUATE WS-REPORT
                WHEN "json"
                    CALL "PLB-METRICS-JSON" USING PLB-SOURCE-SET
                        PLB-METRICS WS-FIRST
                WHEN "csv"
                    CALL "PLB-METRICS-CSV" USING PLB-SOURCE-SET
                        PLB-METRICS WS-FIRST
                WHEN OTHER
                    CALL "PLB-METRICS-TEXT" USING PLB-SOURCE-SET
                        PLB-METRICS
            END-EVALUATE
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    IF WS-REPORT = "json"
        DISPLAY "  ]"
        DISPLAY "}"
    END-IF
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> graph and impact -------------------------------------------------

*> Analyze every file, collecting what the graph or impact needs: the
*> include graph and the call graph of the run.
ANALYZE-RUN.
    CALL "PLB-CALL-INIT" USING PLB-CALL-GRAPH
    MOVE 0 TO DU-COUNT DU-DROPPED
    MOVE 0 TO GI-COUNT
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES GI-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    MOVE "Y" TO WS-FIRST
    PERFORM READ-OTHER-INPUTS
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM TEST-JCL-INPUT
        IF WS-IS-JCL = "N"
            PERFORM START-INPUT
        END-IF
        IF WS-IS-JCL = "N" AND SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            CALL "PLB-GRAPH-INCLUDES-ADD" USING PLB-INCLUSIONS
                PLB-INCLUDE-GRAPH
            CALL "PLB-CALL-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-REFS PLB-CALL-GRAPH
            IF WS-COMMAND = "impact"
                CALL "PLB-DATA-IMPACT-COLLECT" USING PLB-SOURCE-SET
                    PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-REFS
                    PLB-DATA-USES WS-IMPACT-NAME
            END-IF
            IF WS-COMMAND = "graph" AND WS-GRAPH-KIND = "crud"
                CALL "PLB-CRUD-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS
                    PLB-AST PLB-SYMBOLS PLB-CRUD
            END-IF
            IF WS-COMMAND = "graph" AND WS-GRAPH-KIND = "performs"
                CALL "PLB-GRAPH-PERFORMS" USING PLB-SOURCE-SET
                    PLB-TOKENS PLB-AST PLB-FLOW WS-REPORT WS-FIRST
            END-IF
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    CALL "PLB-CALL-RESOLVE" USING PLB-CALL-GRAPH.

GRAPH-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    CALL "PLB-GRAPH-START" USING WS-REPORT WS-GRAPH-KIND
    CALL "PLB-CRUD-INIT" USING PLB-CRUD
    PERFORM ANALYZE-RUN
    EVALUATE WS-GRAPH-KIND
        WHEN "calls"
            CALL "PLB-GRAPH-CALLS" USING PLB-SOURCE-SET PLB-CALL-GRAPH
                WS-REPORT
        WHEN "copybooks"
            CALL "PLB-GRAPH-INCLUDES" USING PLB-SOURCE-SET
                PLB-INCLUDE-GRAPH WS-REPORT
        WHEN "jobs"
            CALL "PLB-GRAPH-JOBS" USING PLB-CALL-GRAPH PLB-JCL WS-REPORT
        WHEN "datasets"
            CALL "PLB-DATASETS-COLLECT" USING PLB-CALL-GRAPH PLB-JCL
                PLB-DATASETS
            CALL "PLB-GRAPH-DATASETS" USING PLB-JCL PLB-DATASETS
                WS-REPORT
        WHEN "cics"
            CALL "PLB-GRAPH-CICS" USING PLB-CALL-GRAPH PLB-CSD WS-REPORT
        WHEN "crud"
            CALL "PLB-GRAPH-CRUD" USING PLB-CRUD WS-REPORT
    END-EVALUATE
    CALL "PLB-GRAPH-END" USING WS-REPORT
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> inventory: the programs, jobs, transactions, and maps of the run,
*> and how they fit together.
INVENTORY-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    PERFORM ANALYZE-RUN
    MOVE 0 TO WS-P
    CALL "PLB-INVENTORY" USING PLB-SOURCE-SET PLB-CALL-GRAPH PLB-JCL
        PLB-CSD PLB-BMS WS-REPORT WS-P
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> layout: the records of the programs and copybooks given. A copybook
*> is read through a program written for it in the temporary
*> directory, which copies it by name from its own directory.
LAYOUT-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM LAYOUT-WRAP-COPYBOOKS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    MOVE "Y" TO WS-FIRST
    CALL "PLB-LAYOUT-START" USING WS-REPORT
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM START-INPUT
        IF SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            MOVE 0 TO WS-P
            CALL "PLB-LAYOUT-RECORDS" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS WS-REPORT WS-FIRST WS-P
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    CALL "PLB-LAYOUT-END" USING WS-REPORT
    IF WS-LAYOUT-WRAPPER NOT = SPACES
        CALL "CBL_DELETE_FILE" USING WS-LAYOUT-WRAPPER
    END-IF
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> lineage NAME: where data item NAME gets its value, or where the value
*> goes, in each program that has an item of that name, and the calls
*> it crosses to other programs of the run.
LINEAGE-COMMAND.
    PERFORM NEXT-ARG
    IF WS-ARG-LEN = 0 OR WS-ARG(1:1) = "-"
        DISPLAY PLB-NAME ": lineage needs a data item name" UPON SYSERR
        PERFORM SUGGEST-HELP
        EXIT PARAGRAPH
    END-IF
    MOVE WS-ARG TO WS-IMPACT-NAME
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    *> The call graph of the whole run first, for the trail through
    *> CALL arguments.
    PERFORM ANALYZE-RUN
    MOVE "N" TO WS-FOUND
    MOVE "B" TO WS-LINEAGE-ACTION
    PERFORM CALL-LINEAGE
    MOVE "F" TO WS-LINEAGE-ACTION
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM START-INPUT
        IF SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            PERFORM CALL-LINEAGE
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    MOVE "E" TO WS-LINEAGE-ACTION
    PERFORM CALL-LINEAGE
    PERFORM REPORT-DIAGNOSTICS
    IF WS-FOUND = "N"
        CALL "PLB-STR-LENGTH" USING WS-IMPACT-NAME WS-PATH-LEN
        DISPLAY PLB-NAME ": no data item named "
            WS-IMPACT-NAME(1:WS-PATH-LEN) " in the input" UPON SYSERR
        MOVE 1 TO WS-EXIT-CODE
    END-IF
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> crud: the CRUD matrix of the run.
CRUD-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    CALL "PLB-CRUD-INIT" USING PLB-CRUD
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM START-INPUT
        IF SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            CALL "PLB-CRUD-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-CRUD
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    CALL "PLB-CRUD-PRINT" USING PLB-CRUD WS-REPORT
    IF CX-DROPPED > 0
        DISPLAY PLB-NAME ": " CX-DROPPED " uses did not fit and are"
            " left out" UPON SYSERR
    END-IF
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

CALL-LINEAGE.
    CALL "PLB-LINEAGE-FILE" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-SYMBOLS PLB-REFS PLB-CALL-GRAPH WS-IMPACT-NAME
        WS-LINEAGE-DEPTH
        WS-LINEAGE-DIRECTION WS-FOUND WS-REPORT WS-LINEAGE-ACTION.

*> duplicates: paragraphs with the same code across the run.
DUPLICATES-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    CALL "PLB-DUP-INIT" USING PLB-DUPLICATES
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM START-INPUT
        IF SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            CALL "PLB-DUP-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-FLOW PLB-DUPLICATES WS-DUP-MIN
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    CALL "PLB-DUP-PRINT" USING PLB-SOURCE-SET PLB-DUPLICATES WS-REPORT
    IF DP-DROPPED > 0
        DISPLAY PLB-NAME ": " DP-DROPPED " paragraphs did not fit"
            " and are left out" UPON SYSERR
    END-IF
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> xref: the cross-reference of each program.
XREF-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    CALL "PLB-XREF-BEGIN" USING WS-REPORT WS-XREF-ANY
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM START-INPUT
        IF SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            CALL "PLB-XREF-FILE" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-REFS PLB-FLOW WS-REPORT
                WS-XREF-ANY
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    CALL "PLB-XREF-END" USING WS-REPORT WS-XREF-ANY
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> fields: the data items of the copybooks of the run, and how many
*> programs name each.
FIELDS-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    CALL "PLB-FIELDS-INIT" USING PLB-FIELDS
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM START-INPUT
        IF SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            CALL "PLB-FIELDS-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-SYMBOLS PLB-REFS PLB-FIELDS WS-FILE-ID
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    CALL "PLB-FIELDS-PRINT" USING PLB-SOURCE-SET PLB-FIELDS WS-REPORT
        WS-FIELDS-UNUSED
    IF FI-DROPPED > 0
        DISPLAY PLB-NAME ": " FI-DROPPED " copybook items did not fit"
            " and are left out" UPON SYSERR
    END-IF
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> doc: a Markdown page for each program of the run. The first pass
*> gathers the call graph and the jobs, transactions, and maps; the
*> second reads each program again for its paragraphs and records.
DOC-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    PERFORM ANALYZE-RUN
    CALL "PLB-DATASETS-COLLECT" USING PLB-CALL-GRAPH PLB-JCL
        PLB-DATASETS
    MOVE "Y" TO WS-FIRST
    PERFORM DOC-INDEX
    MOVE "md" TO WS-REPORT
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM TEST-JCL-INPUT
        IF WS-IS-JCL = "N"
            PERFORM START-INPUT
        END-IF
        IF WS-IS-JCL = "N" AND SF-LOADED(WS-FILE-ID) = "Y"
            PERFORM ANALYZE-FILE
            CALL "PLB-METRICS-COMPUTE" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-FLOW PLB-METRICS
            CALL "PLB-CRUD-INIT" USING PLB-CRUD
            CALL "PLB-CRUD-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-SYMBOLS PLB-CRUD
            PERFORM VARYING WS-M FROM 1 BY 1 UNTIL WS-M > MP-COUNT
                PERFORM DOC-PROGRAM
            END-PERFORM
            PERFORM END-INPUT
        END-IF
    END-PERFORM
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> With more than one program, an index of them first.
DOC-INDEX.
    MOVE 0 TO WS-J
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > CP-COUNT
        IF CP-KIND(WS-I) = "P"
            ADD 1 TO WS-J
        END-IF
    END-PERFORM
    IF WS-J > 1
        DISPLAY "# Programs"
        CALL STATIC "putchar" USING BY VALUE 10
        MOVE "mdidx" TO WS-REPORT
        MOVE 0 TO WS-P
        CALL "PLB-INVENTORY" USING PLB-SOURCE-SET PLB-CALL-GRAPH PLB-JCL
            PLB-CSD PLB-BMS WS-REPORT WS-P
        CALL STATIC "putchar" USING BY VALUE 10
        MOVE "N" TO WS-FIRST
    END-IF.

*> The page of program WS-M of the metrics: its place in the run (the
*> program of the call graph defined at the same name in this file),
*> the data sets its job steps give it, its paragraphs, and its
*> records.
DOC-PROGRAM.
    IF WS-FIRST = "N"
        DISPLAY "---"
        CALL STATIC "putchar" USING BY VALUE 10
    END-IF
    MOVE "N" TO WS-FIRST
    DISPLAY "# " FUNCTION TRIM(MP-NAME(WS-M))
    CALL STATIC "putchar" USING BY VALUE 10
    MOVE 0 TO WS-P
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > CP-COUNT
        IF CP-KIND(WS-I) = "P" AND CP-FILE-ID(WS-I) = WS-FILE-ID
           AND CP-NAME(WS-I) = FUNCTION UPPER-CASE(MP-NAME(WS-M))
            MOVE WS-I TO WS-P
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF WS-P > 0
        CALL "PLB-INVENTORY" USING PLB-SOURCE-SET PLB-CALL-GRAPH PLB-JCL
            PLB-CSD PLB-BMS WS-REPORT WS-P
        CALL "PLB-DOC-DATASETS" USING PLB-CALL-GRAPH PLB-JCL
            PLB-DATASETS WS-P
    END-IF
    CALL "PLB-CRUD-DOC" USING PLB-CRUD MP-NAME(WS-M)
    CALL "PLB-DOC-PARAGRAPHS" USING PLB-FLOW PLB-METRICS WS-M
    DISPLAY "## Records"
    CALL STATIC "putchar" USING BY VALUE 10
    MOVE 0 TO WS-J
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > SY-COUNT
        IF SY-PARENT(WS-I) = 0 AND SY-NAME-TOKEN(WS-I) > 0
           AND (SY-LEVEL(WS-I) = 1 OR SY-LEVEL(WS-I) = 77)
           AND SY-CATEGORY(WS-I) NOT = "K"
           AND SY-PROGRAM(WS-I) = MP-NODE(WS-M)
            ADD 1 TO WS-J
        END-IF
    END-PERFORM
    IF WS-J = 0
        DISPLAY "The program has no records."
        CALL STATIC "putchar" USING BY VALUE 10
    ELSE
        MOVE "Y" TO WS-DOC-FIRST
        CALL "PLB-LAYOUT-RECORDS" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-AST PLB-SYMBOLS WS-REPORT WS-DOC-FIRST MP-NODE(WS-M)
    END-IF.

*> The inputs named *.cpy (in either case) become COPY statements of a
*> program in $TMPDIR, which takes their place among the inputs; their
*> directories are searched for copybooks.
LAYOUT-WRAP-COPYBOOKS.
    MOVE SPACES TO WS-LAYOUT-WRAPPER WS-LSP-TEXT
    MOVE 1 TO WS-LSP-TEXT-LEN
    MOVE 0 TO WS-J
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IP-COUNT
        CALL "PLB-STR-LENGTH" USING IP-PATH(WS-I) WS-PATH-LEN
        MOVE SPACES TO WS-EXTENSION
        IF WS-PATH-LEN > 4
            MOVE FUNCTION UPPER-CASE(IP-PATH(WS-I)(WS-PATH-LEN - 3:4))
                TO WS-EXTENSION
        END-IF
        IF WS-EXTENSION = ".CPY"
            PERFORM LAYOUT-COPY-STATEMENT
        ELSE
            ADD 1 TO WS-J
            MOVE IP-PATH(WS-I) TO IP-PATH(WS-J)
        END-IF
    END-PERFORM
    IF WS-LSP-TEXT-LEN = 1
        EXIT PARAGRAPH
    END-IF
    ACCEPT WS-LSP-TMP FROM ENVIRONMENT "TMPDIR"
    IF WS-LSP-TMP = SPACES
        MOVE "/tmp" TO WS-LSP-TMP
    END-IF
    MOVE FUNCTION CURRENT-DATE TO WS-LSP-STAMP
    STRING FUNCTION TRIM(WS-LSP-TMP TRAILING) DELIMITED BY SIZE
           "/plumbline-layout-" DELIMITED BY SIZE
           WS-LSP-STAMP(1:16) DELIMITED BY SIZE
           ".cob" DELIMITED BY SIZE
        INTO WS-LAYOUT-WRAPPER
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "       IDENTIFICATION DIVISION." X"0A"
           "       PROGRAM-ID. LAYOUT." X"0A"
           "       DATA DIVISION." X"0A"
           "       WORKING-STORAGE SECTION." X"0A"
           DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    STRING WS-OUT(1:WS-PTR - 1) DELIMITED BY SIZE
           WS-LSP-TEXT(1:WS-LSP-TEXT-LEN - 1) DELIMITED BY SIZE
        INTO WS-LSP-OUT
    COMPUTE WS-LEN = WS-PTR - 1 + WS-LSP-TEXT-LEN - 1
    CALL "PLB-LSP-WRITE-FILE" USING WS-LAYOUT-WRAPPER WS-LSP-OUT WS-LEN
        WS-STATUS
    IF WS-STATUS NOT = 0
        DISPLAY PLB-NAME ": cannot write " FUNCTION TRIM(WS-LAYOUT-WRAPPER)
            UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-J
    MOVE WS-LAYOUT-WRAPPER TO IP-PATH(WS-J)
    *> plumbline: ignore move-truncation -- at most the inputs there were
    MOVE WS-J TO IP-COUNT.

*> COPY name. for copybook IP-PATH(WS-I), its directory on the path.
LAYOUT-COPY-STATEMENT.
    MOVE 0 TO WS-K WS-C
    PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > WS-PATH-LEN
        IF IP-PATH(WS-I)(WS-P:1) = "/"
            MOVE WS-P TO WS-K
        END-IF
    END-PERFORM
    IF WS-K > 1
        MOVE IP-PATH(WS-I)(1:WS-K - 1) TO WS-ARG
    ELSE
        IF WS-K = 1
            MOVE "/" TO WS-ARG
        ELSE
            MOVE "." TO WS-ARG
        END-IF
    END-IF
    PERFORM ADD-COPY-PATH
    COMPUTE WS-C = WS-PATH-LEN - WS-K - 4
    STRING "       COPY " DELIMITED BY SIZE
           IP-PATH(WS-I)(WS-K + 1:WS-C) DELIMITED BY SIZE
           "." X"0A" DELIMITED BY SIZE
        INTO WS-LSP-TEXT WITH POINTER WS-LSP-TEXT-LEN.

IMPACT-COMMAND.
    PERFORM NEXT-ARG
    IF WS-ARG = "--changed"
        PERFORM IMPACT-CHANGED
        EXIT PARAGRAPH
    END-IF
    IF WS-ARG-LEN = 0 OR WS-ARG(1:1) = "-"
        DISPLAY PLB-NAME ": impact needs a copybook or program name"
            UPON SYSERR
        PERFORM SUGGEST-HELP
        EXIT PARAGRAPH
    END-IF
    MOVE WS-ARG TO WS-IMPACT-NAME
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    PERFORM ANALYZE-RUN
    CALL "PLB-IMPACT" USING PLB-SOURCE-SET PLB-CALL-GRAPH
        PLB-INCLUDE-GRAPH PLB-JCL WS-IMPACT-NAME WS-FOUND
    CALL "PLB-DATA-IMPACT-PRINT" USING PLB-SOURCE-SET PLB-DATA-USES
        WS-IMPACT-NAME
    CALL "PLB-DATASETS-COLLECT" USING PLB-CALL-GRAPH PLB-JCL
        PLB-DATASETS
    CALL "PLB-DATASET-IMPACT" USING PLB-SOURCE-SET PLB-JCL PLB-DATASETS
        WS-IMPACT-NAME WS-FOUND
    IF DU-COUNT > 0
        MOVE "Y" TO WS-FOUND
    END-IF
    PERFORM REPORT-DIAGNOSTICS
    IF WS-FOUND = "N"
        CALL "PLB-STR-LENGTH" USING WS-IMPACT-NAME WS-PATH-LEN
        DISPLAY PLB-NAME ": no copybook, program, data item, or data"
            " set named "
            WS-IMPACT-NAME(1:WS-PATH-LEN) " in the input" UPON SYSERR
        MOVE 1 TO WS-EXIT-CODE
    END-IF
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> impact --changed LIST: what the files LIST names reach ("-": the
*> list on standard input, as git diff --name-only writes it).
IMPACT-CHANGED.
    PERFORM NEXT-ARG
    IF WS-ARG-LEN = 0
        DISPLAY PLB-NAME ": --changed needs a list of changed files"
            UPON SYSERR
        PERFORM SUGGEST-HELP
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO CH-COUNT
    CALL "PLB-INPUTS-READ-LIST" USING WS-ARG(1:WS-ARG-LEN)
        WS-CHANGED-FILES
        WS-LIST-STATUS WS-LIST-LINE
    IF WS-LIST-STATUS NOT = 0
        DISPLAY PLB-NAME ": cannot read the list of changed files "
            WS-ARG(1:WS-ARG-LEN) UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    PERFORM ANALYZE-RUN
    CALL "PLB-IMPACT-CHANGED" USING PLB-SOURCE-SET PLB-CALL-GRAPH
        PLB-INCLUDE-GRAPH PLB-JCL WS-CHANGED-FILES WS-REPORT
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> format -----------------------------------------------------------

FORMAT-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    IF WS-FORMAT-TO = SPACES
        DISPLAY PLB-NAME ": format needs --to fixed or --to free"
            UPON SYSERR
        PERFORM SUGGEST-HELP
        EXIT PARAGRAPH
    END-IF
    IF WS-FORMAT-CHECK = "N" AND IP-COUNT > 1
        DISPLAY PLB-NAME ": format writes one file to standard output;"
            " give one file, or use --check" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    PERFORM LOAD-INPUTS
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        CALL "PLB-FORMAT" USING PLB-SOURCE-SET WS-FILE-ID WS-FORMAT-TO
            WS-FORMAT-CHECK WS-CHANGED
        IF WS-FORMAT-CHECK = "Y" AND WS-CHANGED = "Y"
            CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET WS-FILE-ID
                WS-PATH
            CALL "PLB-STR-LENGTH" USING WS-PATH WS-PATH-LEN
            DISPLAY PLB-NAME ": " WS-PATH(1:WS-PATH-LEN)
                " is not in " FUNCTION TRIM(WS-FORMAT-TO) " format"
                UPON SYSERR
            MOVE 1 TO WS-EXIT-CODE
        END-IF
    END-PERFORM.

*> fix --------------------------------------------------------------

*> Each input is checked as by check, and the findings that have a fix
*> (PLB-FIX-FINDING) are fixed: the file is written to standard output
*> with the fixes made, or, with --check, the fixes are listed and the
*> exit code is 1 when there are any. A fix that cannot be made here
*> (one that spans lines, or would push a fixed-format line past
*> column 72) is reported on standard error.
FIX-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    IF WS-FORMAT-CHECK = "N" AND WS-FIX-MODE = "F" AND IP-COUNT > 1
        DISPLAY PLB-NAME ": fix writes one file to standard output;"
            " give one file, or use --check or --patch" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    PERFORM ADD-INPUTS
    CALL "PLB-FIND-INIT" USING PLB-FINDINGS
    MOVE 0 TO WS-FIX-COUNT
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM TEST-JCL-INPUT
        IF WS-IS-JCL = "N"
            PERFORM START-INPUT
            IF SF-LOADED(WS-FILE-ID) = "Y"
                COMPUTE WS-FIRST-FINDING = FN-COUNT + 1
                PERFORM ANALYZE-FILE
                CALL "PLB-CHECK-RUN" USING PLB-SOURCE-SET PLB-TOKENS
                    PLB-AST PLB-SYMBOLS PLB-FLOW PLB-REFS
                    PLB-INCLUSIONS PLB-RULES PLB-FINDINGS
                CALL "PLB-FIND-SUPPRESS-RANGE" USING PLB-SOURCE-SET
                    PLB-RULES PLB-FINDINGS WS-FIRST-FINDING FN-COUNT
                PERFORM FIX-FILE
                PERFORM FORGET-SOURCE-LINES
            END-IF
        END-IF
    END-PERFORM
    PERFORM REPORT-DIAGNOSTICS
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF
    IF WS-FORMAT-CHECK = "Y" AND WS-FIX-COUNT > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.

*> The fixes of the findings of input WS-FILE-ID, made since
*> WS-FIRST-FINDING; then the file with them, unless --check, or the
*> file has errors.
FIX-FILE.
    MOVE 0 TO FXL-COUNT
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET WS-FILE-ID WS-PATH
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-PATH-LEN
    PERFORM VARYING WS-I FROM WS-FIRST-FINDING BY 1
            UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N" AND FN-FILE-ID(WS-I) = WS-FILE-ID
            CALL "PLB-FIX-FINDING" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-RULES PLB-FINDINGS WS-I PLB-FIX
            IF FX-EDIT-COUNT > 0
                CALL "PLB-FIX-ACCEPT" USING PLB-SOURCE-SET WS-FILE-ID
                    PLB-FIX PLB-FIX-LIST WS-FIX-RESULT
                PERFORM REPORT-FIX
            END-IF
        END-IF
    END-PERFORM
    IF WS-FORMAT-CHECK = "N" AND DG-ERRORS = 0
        CALL "PLB-FIX-WRITE" USING PLB-SOURCE-SET WS-FILE-ID
            PLB-FIX-LIST WS-FIX-MODE WS-PATH(1:WS-PATH-LEN)
    END-IF.

*> path:line:column: RULE: title, on standard output for a fix that
*> --check lists, on standard error for one that cannot be made.
REPORT-FIX.
    MOVE FN-LINE(WS-I) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING WS-PATH(1:WS-PATH-LEN) ":" WS-NUM-TEXT(1:WS-NUM-LEN) ":"
           DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE FN-COLUMN(WS-I) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) ": " DELIMITED BY SIZE
           RL-ID(FN-RULE(WS-I)) DELIMITED BY SPACE
           ": " DELIMITED BY SIZE
           FX-TITLE DELIMITED BY "  "
        INTO WS-OUT WITH POINTER WS-PTR
    EVALUATE WS-FIX-RESULT
        WHEN "Y"
            ADD 1 TO WS-FIX-COUNT
            IF WS-FORMAT-CHECK = "Y"
                DISPLAY WS-OUT(1:WS-PTR - 1)
            END-IF
            EXIT PARAGRAPH
        WHEN "S"
            STRING ": not made, as it spans lines (an editor can make"
                   " it)" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "M"
            STRING ": not made, as the line would run past column 72"
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        WHEN "O"
            STRING ": not made, as it overlaps another fix"
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        WHEN OTHER
            STRING ": not made, as the file has too many fixes"
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    DISPLAY WS-OUT(1:WS-PTR - 1) UPON SYSERR.

*> lsp --------------------------------------------------------------

*> The language server: read messages until "exit" or the end of
*> input. Documents are analyzed from a copy of the editor's text in
*> the temporary directory, with the document's own directory added to
*> the copybook search paths.
LSP-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    ACCEPT WS-LSP-TMP FROM ENVIRONMENT "TMPDIR"
    IF WS-LSP-TMP = SPACES
        MOVE "/tmp" TO WS-LSP-TMP
    END-IF
    MOVE FUNCTION CURRENT-DATE TO WS-LSP-STAMP
    PERFORM VARYING WS-LSP-DOC-INDEX FROM 1 BY 1
            UNTIL WS-LSP-DOC-INDEX > LSP-DOC-MAX
        MOVE SPACES TO DOC-URI(WS-LSP-DOC-INDEX)
    END-PERFORM
    PERFORM UNTIL WS-LSP-DONE = "Y"
        CALL "PLB-LSP-RECEIVE" USING WS-LSP-IN WS-LSP-IN-LEN WS-LSP-STATUS
        EVALUATE WS-LSP-STATUS
            WHEN 0
                PERFORM LSP-MESSAGE
            WHEN 1
                MOVE "Y" TO WS-LSP-DONE
        END-EVALUATE
    END-PERFORM
    PERFORM LSP-REMOVE-COPIES
    IF WS-LSP-SHUTDOWN = "Y"
        MOVE 0 TO WS-EXIT-CODE
    ELSE
        MOVE 1 TO WS-EXIT-CODE
    END-IF
    *> End here, without closing standard input: the runtime's close
    *> of a pipe read as a record file reports a spurious unlock error
    *> on standard error, which editors show to their users. The
    *> output is flushed and the copies are gone, so the C library's
    *> _exit is enough.
    *> Called by name at run time: a static call would redeclare it.
    CALL "fflush" USING BY VALUE 0
    MOVE WS-EXIT-CODE TO WS-LSP-EXIT-STATUS
    CALL WS-LSP-EXIT-ROUTINE USING BY VALUE WS-LSP-EXIT-STATUS.

LSP-MESSAGE.
    MOVE "method" TO WS-LSP-NAME
    PERFORM LSP-GET
    MOVE WS-LSP-VALUE TO WS-LSP-METHOD
    CALL "PLB-JSON-GET" USING WS-LSP-IN WS-LSP-IN-LEN "id" WS-LSP-ID-KIND
        WS-LSP-ID WS-LSP-VALUE-LEN
    EVALUATE WS-LSP-METHOD
        WHEN "initialize"
            PERFORM LSP-INITIALIZE
        WHEN "shutdown"
            MOVE "Y" TO WS-LSP-SHUTDOWN
            PERFORM LSP-START-RESPONSE
            STRING '"result":null}' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            PERFORM LSP-SEND-OUT
        WHEN "exit"
            MOVE "Y" TO WS-LSP-DONE
        WHEN "textDocument/didOpen"
        WHEN "textDocument/didChange"
            PERFORM LSP-DOCUMENT-TEXT
        WHEN "textDocument/didSave"
            PERFORM LSP-FIND-DOCUMENT
            IF WS-LSP-DOC-INDEX > 0
                PERFORM LSP-PUBLISH
            END-IF
        WHEN "textDocument/didClose"
            PERFORM LSP-CLOSE-DOCUMENT
        WHEN "textDocument/documentSymbol"
            PERFORM LSP-DOCUMENT-SYMBOLS
        WHEN "textDocument/definition"
            PERFORM LSP-DEFINITION
        WHEN "textDocument/hover"
            PERFORM LSP-HOVER
        WHEN "textDocument/references"
            MOVE "N" TO WS-LSP-HIGHLIGHT
            PERFORM LSP-REFERENCES
        WHEN "textDocument/documentHighlight"
            MOVE "Y" TO WS-LSP-HIGHLIGHT
            PERFORM LSP-REFERENCES
        WHEN "workspace/symbol"
            PERFORM LSP-WORKSPACE-SYMBOLS
        WHEN "textDocument/semanticTokens/full"
            PERFORM LSP-SEMANTIC-TOKENS
        WHEN "textDocument/prepareCallHierarchy"
            PERFORM LSP-PREPARE-CALL-HIERARCHY
        WHEN "callHierarchy/incomingCalls"
            MOVE "I" TO WS-LSP-DIRECTION
            PERFORM LSP-HIERARCHY-CALLS
        WHEN "callHierarchy/outgoingCalls"
            MOVE "O" TO WS-LSP-DIRECTION
            PERFORM LSP-HIERARCHY-CALLS
        WHEN "textDocument/codeAction"
            PERFORM LSP-CODE-ACTIONS
        WHEN "textDocument/foldingRange"
            PERFORM LSP-FOLDING-RANGES
        WHEN "textDocument/codeLens"
            PERFORM LSP-CODE-LENSES
        WHEN "textDocument/documentLink"
            PERFORM LSP-DOCUMENT-LINKS
        WHEN "textDocument/selectionRange"
            PERFORM LSP-SELECTION-RANGES
        WHEN "textDocument/inlayHint"
            PERFORM LSP-INLAY-HINTS
        WHEN "textDocument/completion"
            PERFORM LSP-COMPLETION
        WHEN "textDocument/prepareRename"
            PERFORM LSP-PREPARE-RENAME
        WHEN "textDocument/rename"
            PERFORM LSP-RENAME
        WHEN "textDocument/signatureHelp"
            PERFORM LSP-SIGNATURE-HELP
        WHEN OTHER
            *> A request (with an id) must be answered.
            IF WS-LSP-ID-KIND NOT = "-"
                PERFORM LSP-START-RESPONSE
                STRING '"error":{"code":-32601,"message":"method not '
                       'supported"}}' DELIMITED BY SIZE
                    INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
                PERFORM LSP-SEND-OUT
            END-IF
    END-EVALUATE.

*> WS-LSP-VALUE = the value of key WS-LSP-NAME in the message.
LSP-GET.
    CALL "PLB-JSON-GET" USING WS-LSP-IN WS-LSP-IN-LEN WS-LSP-NAME
        WS-LSP-KIND WS-LSP-VALUE WS-LSP-VALUE-LEN.

LSP-INITIALIZE.
    PERFORM LSP-START-RESPONSE
    STRING '"result":{"capabilities":{' DELIMITED BY SIZE
           '"textDocumentSync":{"openClose":true,"change":1,'
           DELIMITED BY SIZE
           '"save":true},' DELIMITED BY SIZE
           '"documentSymbolProvider":true,' DELIMITED BY SIZE
           '"workspaceSymbolProvider":true,' DELIMITED BY SIZE
           '"definitionProvider":true,' DELIMITED BY SIZE
           '"hoverProvider":true,' DELIMITED BY SIZE
           '"referencesProvider":true,' DELIMITED BY SIZE
           '"documentHighlightProvider":true,' DELIMITED BY SIZE
           '"foldingRangeProvider":true,' DELIMITED BY SIZE
           '"codeLensProvider":{"resolveProvider":false},'
           DELIMITED BY SIZE
           '"documentLinkProvider":{"resolveProvider":false},'
           DELIMITED BY SIZE
           '"inlayHintProvider":true,' DELIMITED BY SIZE
           '"selectionRangeProvider":true,' DELIMITED BY SIZE
           '"completionProvider":{"triggerCharacters":["-"]},'
           DELIMITED BY SIZE
           '"callHierarchyProvider":true,' DELIMITED BY SIZE
           '"semanticTokensProvider":{"legend":{"tokenTypes":'
           DELIMITED BY SIZE
           '["keyword","variable","function","string","number",'
           DELIMITED BY SIZE
           '"operator","type"],"tokenModifiers":["declaration"]},'
           DELIMITED BY SIZE
           '"full":true},' DELIMITED BY SIZE
           '"codeActionProvider":{"codeActionKinds":["quickfix",'
           '"source.fixAll"]},'
           DELIMITED BY SIZE
           '"signatureHelpProvider":{},'
           '"renameProvider":{"prepareProvider":true}},'
           DELIMITED BY SIZE
           '"serverInfo":{"name":"' DELIMITED BY SIZE
           PLB-NAME DELIMITED BY SPACE
           '","version":"' DELIMITED BY SIZE
           PLB-VERSION DELIMITED BY SPACE
           '"}}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> {"jsonrpc":"2.0","id":ID, ... the caller adds the rest.
LSP-START-RESPONSE.
    MOVE 1 TO WS-LSP-PTR
    STRING '{"jsonrpc":"2.0","id":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-ID-KIND = "S"
        CALL "PLB-JSON-STRING" USING WS-LSP-ID WS-LSP-OUT WS-LSP-PTR
    ELSE
        IF WS-LSP-ID-KIND = "-"
            STRING "null" DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        ELSE
            STRING WS-LSP-ID DELIMITED BY SPACE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
    END-IF
    STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

LSP-SEND-OUT.
    COMPUTE WS-LSP-IN-LEN = WS-LSP-PTR - 1
    CALL "PLB-LSP-SEND" USING WS-LSP-OUT WS-LSP-IN-LEN.

*> Documents ---------------------------------------------------------

*> WS-LSP-DOC-INDEX = the slot of the message's document, or 0.
LSP-FIND-DOCUMENT.
    MOVE "uri" TO WS-LSP-NAME
    PERFORM LSP-GET
    MOVE WS-LSP-VALUE TO WS-LSP-URI
    MOVE 0 TO WS-LSP-DOC-INDEX
    PERFORM VARYING WS-LSP-SLOT FROM 1 BY 1 UNTIL WS-LSP-SLOT > LSP-DOC-MAX
        IF DOC-URI(WS-LSP-SLOT) = WS-LSP-URI
            MOVE WS-LSP-SLOT TO WS-LSP-DOC-INDEX
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> didOpen or didChange (whole text): keep a copy and publish.
LSP-DOCUMENT-TEXT.
    PERFORM LSP-FIND-DOCUMENT
    IF WS-LSP-DOC-INDEX = 0
        PERFORM VARYING WS-LSP-SLOT FROM 1 BY 1
                UNTIL WS-LSP-SLOT > LSP-DOC-MAX
            IF DOC-URI(WS-LSP-SLOT) = SPACES
                MOVE WS-LSP-SLOT TO WS-LSP-DOC-INDEX
                EXIT PERFORM
            END-IF
        END-PERFORM
        IF WS-LSP-DOC-INDEX = 0
            EXIT PARAGRAPH
        END-IF
        PERFORM LSP-NEW-DOCUMENT
    END-IF
    CALL "PLB-JSON-GET" USING WS-LSP-IN WS-LSP-IN-LEN "text" WS-LSP-KIND
        WS-LSP-TEXT WS-LSP-TEXT-LEN
    IF WS-LSP-KIND NOT = "S" OR WS-LSP-TEXT-LEN > LSP-SIZE
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-LSP-WRITE-FILE" USING DOC-TEMP(WS-LSP-DOC-INDEX)
        WS-LSP-TEXT WS-LSP-TEXT-LEN WS-LSP-STATUS
    IF WS-LSP-STATUS = 0
        PERFORM LSP-PUBLISH
    END-IF.

*> Slot WS-LSP-DOC-INDEX for document WS-LSP-URI: its directory, for
*> copybooks, and the name of its copy.
LSP-NEW-DOCUMENT.
    MOVE WS-LSP-URI TO DOC-URI(WS-LSP-DOC-INDEX)
    CALL "PLB-LSP-URI-PATH" USING WS-LSP-URI WS-LSP-TEXT-PATH
    MOVE SPACES TO DOC-DIR(WS-LSP-DOC-INDEX)
    CALL "PLB-STR-LENGTH" USING WS-LSP-TEXT-PATH WS-PATH-LEN
    PERFORM VARYING WS-K FROM WS-PATH-LEN BY -1 UNTIL WS-K = 0
        IF WS-LSP-TEXT-PATH(WS-K:1) = "/"
            IF WS-K > 1
                MOVE WS-LSP-TEXT-PATH(1:WS-K - 1)
                    TO DOC-DIR(WS-LSP-DOC-INDEX)
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF DOC-DIR(WS-LSP-DOC-INDEX) NOT = SPACES
        MOVE "N" TO WS-FOUND
        PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > PO-PATH-COUNT
            IF PO-PATH(WS-K) = DOC-DIR(WS-LSP-DOC-INDEX)
                MOVE "Y" TO WS-FOUND
            END-IF
        END-PERFORM
        IF WS-FOUND = "N"
            CALL "PLB-PP-ADD-PATH" USING PLB-PP-OPTIONS
                DOC-DIR(WS-LSP-DOC-INDEX) WS-PATH-STATUS
        END-IF
    END-IF
    MOVE WS-LSP-DOC-INDEX TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    MOVE SPACES TO DOC-TEMP(WS-LSP-DOC-INDEX)
    STRING FUNCTION TRIM(WS-LSP-TMP) DELIMITED BY SIZE
           "/plumbline-lsp-" DELIMITED BY SIZE
           WS-LSP-STAMP(1:16) DELIMITED BY SIZE
           "-" DELIMITED BY SIZE
           WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
           ".cbl" DELIMITED BY SIZE
        INTO DOC-TEMP(WS-LSP-DOC-INDEX).

LSP-CLOSE-DOCUMENT.
    PERFORM LSP-FIND-DOCUMENT
    IF WS-LSP-DOC-INDEX = 0
        EXIT PARAGRAPH
    END-IF
    *> Clear the document's diagnostics in the editor.
    MOVE 1 TO WS-LSP-PTR
    STRING '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics",'
           '"params":{"uri":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING WS-LSP-URI WS-LSP-OUT WS-LSP-PTR
    STRING ',"diagnostics":[]}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT
    CALL "CBL_DELETE_FILE" USING DOC-TEMP(WS-LSP-DOC-INDEX)
    MOVE SPACES TO DOC-URI(WS-LSP-DOC-INDEX) DOC-TEMP(WS-LSP-DOC-INDEX).

LSP-REMOVE-COPIES.
    PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > LSP-DOC-MAX
        IF DOC-URI(WS-J) NOT = SPACES
            CALL "CBL_DELETE_FILE" USING DOC-TEMP(WS-J)
        END-IF
    END-PERFORM.

*> Analyze the copy of document WS-LSP-DOC-INDEX: file 1 of the
*> source set, with its tokens, tree, symbols, flow, references, and
*> findings.
LSP-ANALYZE.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    CALL "PLB-SRC-LOAD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        DOC-TEMP(WS-LSP-DOC-INDEX) WS-MODE WS-FILE-ID WS-STATUS
    CALL "PLB-FIND-INIT" USING PLB-FINDINGS
    IF WS-FILE-ID = 0
        EXIT PARAGRAPH
    END-IF
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM ANALYZE-FILE
    CALL "PLB-CHECK-RUN" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-SYMBOLS PLB-FLOW PLB-REFS PLB-INCLUSIONS PLB-RULES
        PLB-FINDINGS
    CALL "PLB-FIND-SUPPRESS" USING PLB-SOURCE-SET PLB-RULES PLB-FINDINGS
    CALL "PLB-FIND-SORT" USING PLB-FINDINGS.

*> Diagnostics -------------------------------------------------------

*> textDocument/publishDiagnostics: the findings and input problems
*> in the document itself (not in its copybooks).
LSP-PUBLISH.
    PERFORM LSP-ANALYZE
    MOVE 1 TO WS-LSP-PTR
    STRING '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics",'
           '"params":{"uri":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING DOC-URI(WS-LSP-DOC-INDEX) WS-LSP-OUT
        WS-LSP-PTR
    STRING ',"diagnostics":[' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-LSP-FIRST
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N" AND FN-FILE-ID(WS-I) = 1
           AND FN-LINE(WS-I) > 0
            MOVE FN-LINE(WS-I) TO WS-LSP-LINE
            MOVE FN-COLUMN(WS-I) TO WS-LSP-CHAR
            MOVE FN-SEVERITY(WS-I) TO WS-LSP-SEVERITY
            PERFORM LSP-DIAGNOSTIC-START
            *> The code links to the rule's section of the reference.
            STRING '"code":"' DELIMITED BY SIZE
                   RL-ID(FN-RULE(WS-I)) DELIMITED BY SPACE
                   '","codeDescription":{"href":"' DELIMITED BY SIZE
                   PLB-RULES-URL DELIMITED BY SIZE
                   "#" FUNCTION LOWER-CASE(RL-ID(FN-RULE(WS-I)))
                   DELIMITED BY SPACE
                   "-" DELIMITED BY SIZE
                   RL-NAME(FN-RULE(WS-I)) DELIMITED BY SPACE
                   '"},"source":"plumbline","message":' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            CALL "PLB-JSON-STRING" USING FN-MESSAGE(WS-I) WS-LSP-OUT
                WS-LSP-PTR
            PERFORM LSP-DIAGNOSTIC-TAGS
            STRING "}" DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > DG-COUNT
        IF DG-FILE-ID(WS-I) = 1 AND DG-LINE(WS-I) > 0
            MOVE DG-LINE(WS-I) TO WS-LSP-LINE
            MOVE DG-COLUMN(WS-I) TO WS-LSP-CHAR
            MOVE DG-SEVERITY(WS-I) TO WS-LSP-SEVERITY
            PERFORM LSP-DIAGNOSTIC-START
            STRING '"code":"' DELIMITED BY SIZE
                   DG-CODE(WS-I) DELIMITED BY SPACE
                   '","source":"plumbline","message":' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            CALL "PLB-JSON-STRING" USING DG-MESSAGE(WS-I) WS-LSP-OUT
                WS-LSP-PTR
            STRING "}" DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
    END-PERFORM
    STRING "]}}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> Tags of finding WS-I: code that never runs or is never used is
*> Unnecessary (1), which editors fade out; ALTER is Deprecated (2).
LSP-DIAGNOSTIC-TAGS.
    EVALUATE RL-ID(FN-RULE(WS-I))
        WHEN "PLB-C001" WHEN "PLB-M003" WHEN "PLB-M013"
            STRING ',"tags":[1]' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN "PLB-M002"
            STRING ',"tags":[2]' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-EVALUATE.

*> {"range":..., "severity":N, of a diagnostic at WS-LSP-LINE and
*> WS-LSP-CHAR (1-based), as wide as the token there.
LSP-DIAGNOSTIC-START.
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    PERFORM LSP-TOKEN-AT-LINE-COLUMN
    STRING '{"range":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-RANGE
    STRING ',"severity":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    EVALUATE WS-LSP-SEVERITY
        WHEN "E"   STRING "1," DELIMITED BY SIZE
                       INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN "W"   STRING "2," DELIMITED BY SIZE
                       INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN OTHER STRING "3," DELIMITED BY SIZE
                       INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-EVALUATE.

*> WS-LSP-TOKEN = the token of file 1 that starts at line WS-LSP-LINE,
*> column WS-LSP-CHAR (1-based), or 0.
LSP-TOKEN-AT-LINE-COLUMN.
    MOVE 0 TO WS-LSP-TOKEN
    PERFORM VARYING WS-TOK FROM 1 BY 1 UNTIL WS-TOK > TK-COUNT
        IF TK-FILE-ID(WS-TOK) = 1 AND TK-SRC-LINE(WS-TOK) > 0
            IF SL-LINE-NO(TK-SRC-LINE(WS-TOK)) = WS-LSP-LINE
               AND TK-COLUMN(WS-TOK) = WS-LSP-CHAR
                MOVE WS-TOK TO WS-LSP-TOKEN
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> {"start":{...},"end":{...}} for WS-LSP-LINE and WS-LSP-CHAR, to the
*> end of token WS-LSP-TOKEN (one character when there is none).
LSP-APPEND-RANGE.
    STRING '{"start":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = WS-LSP-LINE - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"character":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = WS-LSP-CHAR - 1
    PERFORM LSP-APPEND-NUM
    STRING '},"end":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = WS-LSP-LINE - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"character":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-TOKEN > 0
        COMPUTE WS-NUM = WS-LSP-CHAR - 1 + TK-SPAN(WS-LSP-TOKEN)
    ELSE
        MOVE WS-LSP-CHAR TO WS-NUM
    END-IF
    PERFORM LSP-APPEND-NUM
    STRING '}}' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

LSP-APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> A location for token WS-LSP-TOKEN: {"uri":...,"range":...}.
LSP-APPEND-LOCATION.
    STRING '{"uri":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF TK-FILE-ID(WS-LSP-TOKEN) = 1
        CALL "PLB-JSON-STRING" USING DOC-URI(WS-LSP-DOC-INDEX) WS-LSP-OUT
            WS-LSP-PTR
    ELSE
        *> A copybook, by its path on disk.
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET
            TK-FILE-ID(WS-LSP-TOKEN) WS-PATH
        MOVE SPACES TO WS-LSP-TEXT-PATH
        STRING "file://" DELIMITED BY SIZE
               WS-PATH DELIMITED BY SPACE
            INTO WS-LSP-TEXT-PATH
        CALL "PLB-JSON-STRING" USING WS-LSP-TEXT-PATH WS-LSP-OUT
            WS-LSP-PTR
    END-IF
    STRING ',"range":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-LSP-TOKEN)) TO WS-LSP-LINE
    MOVE TK-COLUMN(WS-LSP-TOKEN) TO WS-LSP-CHAR
    PERFORM LSP-APPEND-RANGE
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Requests about a position -------------------------------------------

*> Analyze the request's document, and find the token at its position
*> (line and character are 0-based): WS-LSP-TOKEN, or 0.
LSP-POSITION.
    MOVE 0 TO WS-LSP-TOKEN
    PERFORM LSP-FIND-DOCUMENT
    IF WS-LSP-DOC-INDEX = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM LSP-ANALYZE
    MOVE "line" TO WS-LSP-NAME
    PERFORM LSP-GET
    COMPUTE WS-LSP-LINE = FUNCTION NUMVAL(WS-LSP-VALUE) + 1
    MOVE "character" TO WS-LSP-NAME
    PERFORM LSP-GET
    COMPUTE WS-LSP-CHAR = FUNCTION NUMVAL(WS-LSP-VALUE) + 1
    PERFORM VARYING WS-TOK FROM 1 BY 1 UNTIL WS-TOK > TK-COUNT
        IF TK-FILE-ID(WS-TOK) = 1 AND TK-SRC-LINE(WS-TOK) > 0
            IF SL-LINE-NO(TK-SRC-LINE(WS-TOK)) = WS-LSP-LINE
               AND TK-COLUMN(WS-TOK) <= WS-LSP-CHAR
               AND TK-COLUMN(WS-TOK) + TK-SPAN(WS-TOK) > WS-LSP-CHAR
                MOVE WS-TOK TO WS-LSP-TOKEN
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> WS-LSP-SYMBOL = the data item the reference at WS-LSP-TOKEN names,
*> or 0; WS-LSP-UNIT = the paragraph or section a procedure name
*> there names, or 0.
LSP-TARGET.
    MOVE 0 TO WS-LSP-SYMBOL WS-LSP-UNIT
    IF WS-LSP-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > RF-COUNT
        IF RF-TOKEN(WS-I) = WS-LSP-TOKEN
            IF RF-KIND(WS-I) = "D" OR RF-KIND(WS-I) = "A"
                MOVE RF-SYMBOL(WS-I) TO WS-LSP-SYMBOL
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM
    *> The name in a data description entry.
    IF WS-LSP-SYMBOL = 0
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > SY-COUNT
            IF SY-NAME-TOKEN(WS-I) = WS-LSP-TOKEN
                MOVE WS-I TO WS-LSP-SYMBOL
                EXIT PERFORM
            END-IF
        END-PERFORM
    END-IF
    IF WS-LSP-SYMBOL > 0
        EXIT PARAGRAPH
    END-IF
    *> A procedure name: the unit of that name in the same program.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-LSP-TOKEN WS-LSP-NAME
        WS-TOKEN-LEN
    PERFORM VARYING WS-U FROM 1 BY 1 UNTIL WS-U > FU-COUNT
        IF FU-NAME(WS-U) = WS-LSP-NAME AND FU-KIND(WS-U) NOT = "D"
           AND ND-TOK-FIRST(FU-PROGRAM(WS-U)) <= WS-LSP-TOKEN
           AND ND-TOK-LAST(FU-PROGRAM(WS-U)) >= WS-LSP-TOKEN
            MOVE WS-U TO WS-LSP-UNIT
        END-IF
    END-PERFORM.

*> textDocument/selectionRange: for each position, the token there and
*> the syntax tree nodes around it, innermost first, each the parent of
*> the one before: a name, its reference, its statement, the sentence,
*> the paragraph, the section, the division, the program. A node whose
*> range is the one before's is left out; one that starts or ends in a
*> copybook is cut to the document's own tokens.
LSP-SELECTION-RANGES.
    PERFORM LSP-FIND-DOCUMENT
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
    END-IF
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE 1 TO WS-SEL-N
    PERFORM UNTIL WS-SEL-N = 0
        *> The N-th line and character of the list of positions.
        CALL "PLB-JSON-FIND-NTH" USING WS-LSP-IN WS-LSP-IN-LEN "line"
            WS-SEL-N WS-SEL-OFFSET
        IF WS-SEL-OFFSET = 0
            MOVE 0 TO WS-SEL-N
        ELSE
            COMPUTE WS-SEL-REST = WS-LSP-IN-LEN - WS-SEL-OFFSET + 1
            CALL "PLB-JSON-GET" USING
                WS-LSP-IN(WS-SEL-OFFSET:WS-SEL-REST) WS-SEL-REST "line"
                WS-LSP-KIND WS-LSP-VALUE WS-LSP-VALUE-LEN
            COMPUTE WS-LSP-LINE = FUNCTION NUMVAL(WS-LSP-VALUE) + 1
            CALL "PLB-JSON-FIND-NTH" USING WS-LSP-IN WS-LSP-IN-LEN
                "character" WS-SEL-N WS-SEL-OFFSET
            MOVE 1 TO WS-LSP-CHAR
            IF WS-SEL-OFFSET > 0
                COMPUTE WS-SEL-REST = WS-LSP-IN-LEN - WS-SEL-OFFSET + 1
                CALL "PLB-JSON-GET" USING
                    WS-LSP-IN(WS-SEL-OFFSET:WS-SEL-REST) WS-SEL-REST
                    "character" WS-LSP-KIND WS-LSP-VALUE
                    WS-LSP-VALUE-LEN
                COMPUTE WS-LSP-CHAR = FUNCTION NUMVAL(WS-LSP-VALUE) + 1
            END-IF
            IF WS-SEL-N > 1
                STRING "," DELIMITED BY SIZE
                    INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            END-IF
            PERFORM LSP-SELECTION-RANGE
            ADD 1 TO WS-SEL-N
        END-IF
    END-PERFORM
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> The selection range at WS-LSP-LINE and WS-LSP-CHAR. Off any token,
*> an empty range there.
LSP-SELECTION-RANGE.
    MOVE 0 TO WS-LSP-TOKEN
    IF WS-LSP-DOC-INDEX > 0
        PERFORM VARYING WS-TOK FROM 1 BY 1 UNTIL WS-TOK > TK-COUNT
            IF TK-FILE-ID(WS-TOK) = 1 AND TK-SRC-LINE(WS-TOK) > 0
                IF SL-LINE-NO(TK-SRC-LINE(WS-TOK)) = WS-LSP-LINE
                   AND TK-COLUMN(WS-TOK) <= WS-LSP-CHAR
                   AND TK-COLUMN(WS-TOK) + TK-SPAN(WS-TOK) > WS-LSP-CHAR
                    MOVE WS-TOK TO WS-LSP-TOKEN
                    EXIT PERFORM
                END-IF
            END-IF
        END-PERFORM
    END-IF
    IF WS-LSP-TOKEN = 0
        STRING '{"range":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        PERFORM LSP-APPEND-RANGE
        STRING "}" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        EXIT PARAGRAPH
    END-IF
    *> The nodes that contain the token, from the root down.
    MOVE 0 TO WS-SEL-DEPTH
    MOVE 1 TO WS-SEL-NODE
    PERFORM UNTIL WS-SEL-NODE = 0 OR WS-SEL-DEPTH >= 200
        ADD 1 TO WS-SEL-DEPTH
        MOVE WS-SEL-NODE TO WS-SEL-PATH(WS-SEL-DEPTH)
        MOVE ND-FIRST(WS-SEL-NODE) TO WS-SEL-CHILD
        MOVE 0 TO WS-SEL-NODE
        PERFORM UNTIL WS-SEL-CHILD = 0
            IF ND-TOK-FIRST(WS-SEL-CHILD) <= WS-LSP-TOKEN
               AND ND-TOK-LAST(WS-SEL-CHILD) >= WS-LSP-TOKEN
                MOVE WS-SEL-CHILD TO WS-SEL-NODE
                EXIT PERFORM
            END-IF
            MOVE ND-NEXT(WS-SEL-CHILD) TO WS-SEL-CHILD
        END-PERFORM
    END-PERFORM
    *> The token, then the nodes from the innermost out.
    MOVE WS-LSP-TOKEN TO WS-SEL-FIRST WS-SEL-LAST
    MOVE 0 TO WS-SEL-OPEN
    PERFORM LSP-SELECTION-LEVEL
    PERFORM VARYING WS-SEL-K FROM WS-SEL-DEPTH BY -1 UNTIL WS-SEL-K < 1
        MOVE WS-SEL-PATH(WS-SEL-K) TO WS-SEL-NODE
        PERFORM LSP-SELECTION-NODE-SPAN
        IF WS-SEL-FIRST NOT = WS-SEL-PREV-FIRST
           OR WS-SEL-LAST NOT = WS-SEL-PREV-LAST
            STRING ',"parent":' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            PERFORM LSP-SELECTION-LEVEL
        END-IF
    END-PERFORM
    PERFORM WS-SEL-OPEN TIMES
        STRING "}" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-PERFORM.

*> {"range": from token WS-SEL-FIRST to the end of WS-SEL-LAST, left
*> open for its parent.
LSP-SELECTION-LEVEL.
    STRING '{"range":{"start":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = SL-LINE-NO(TK-SRC-LINE(WS-SEL-FIRST)) - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"character":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = TK-COLUMN(WS-SEL-FIRST) - 1
    PERFORM LSP-APPEND-NUM
    STRING '},"end":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = SL-LINE-NO(TK-SRC-LINE(WS-SEL-LAST)) - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"character":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = TK-COLUMN(WS-SEL-LAST) - 1 + TK-SPAN(WS-SEL-LAST)
    PERFORM LSP-APPEND-NUM
    STRING '}}' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ADD 1 TO WS-SEL-OPEN
    MOVE WS-SEL-FIRST TO WS-SEL-PREV-FIRST
    MOVE WS-SEL-LAST TO WS-SEL-PREV-LAST.

*> WS-SEL-FIRST and WS-SEL-LAST: the first and last tokens of node
*> WS-SEL-NODE that are the document's own text: not a copybook's, and
*> not the end of the file, which has no width. A node with none keeps
*> the range before it.
LSP-SELECTION-NODE-SPAN.
    MOVE WS-SEL-PREV-FIRST TO WS-SEL-FIRST
    MOVE WS-SEL-PREV-LAST TO WS-SEL-LAST
    PERFORM VARYING WS-TOK FROM ND-TOK-FIRST(WS-SEL-NODE) BY 1
            UNTIL WS-TOK > ND-TOK-LAST(WS-SEL-NODE)
        IF TK-FILE-ID(WS-TOK) = 1 AND TK-SRC-LINE(WS-TOK) > 0
           AND TK-SPAN(WS-TOK) > 0
            MOVE WS-TOK TO WS-SEL-FIRST
            EXIT PERFORM
        END-IF
    END-PERFORM
    PERFORM VARYING WS-TOK FROM ND-TOK-LAST(WS-SEL-NODE) BY -1
            UNTIL WS-TOK < ND-TOK-FIRST(WS-SEL-NODE) OR WS-TOK = 0
        IF TK-FILE-ID(WS-TOK) = 1 AND TK-SRC-LINE(WS-TOK) > 0
           AND TK-SPAN(WS-TOK) > 0
            MOVE WS-TOK TO WS-SEL-LAST
            EXIT PERFORM
        END-IF
    END-PERFORM
    *> Each range holds the one inside it, even where a node's tokens
    *> stop short of its last child's (a program's closing period).
    IF WS-SEL-FIRST > WS-SEL-PREV-FIRST
        MOVE WS-SEL-PREV-FIRST TO WS-SEL-FIRST
    END-IF
    IF WS-SEL-LAST < WS-SEL-PREV-LAST
        MOVE WS-SEL-PREV-LAST TO WS-SEL-LAST
    END-IF.

LSP-DEFINITION.
    PERFORM LSP-POSITION
    PERFORM LSP-TARGET
    PERFORM LSP-START-RESPONSE
    STRING '"result":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    EVALUATE TRUE
        WHEN WS-LSP-SYMBOL > 0 AND SY-NAME-TOKEN(WS-LSP-SYMBOL) > 0
            MOVE SY-NAME-TOKEN(WS-LSP-SYMBOL) TO WS-LSP-TOKEN
            PERFORM LSP-APPEND-LOCATION
        WHEN WS-LSP-UNIT > 0 AND ND-NAME(FU-NODE(WS-LSP-UNIT)) > 0
            MOVE ND-NAME(FU-NODE(WS-LSP-UNIT)) TO WS-LSP-TOKEN
            PERFORM LSP-APPEND-LOCATION
        WHEN OTHER
            PERFORM LSP-CALL-DEFINITION
            IF WS-FOUND = "N"
                PERFORM LSP-COPYBOOK-AT-LINE
                IF WS-I > 0
                    PERFORM LSP-APPEND-COPYBOOK
                ELSE
                    STRING "null" DELIMITED BY SIZE
                        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
                END-IF
            END-IF
    END-EVALUATE
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> The program a CALL "NAME" at the position calls: a program of the
*> same document, then one of the other open documents, then a file
*> NAME.cbl or NAME.cob (or in upper case) in the document's directory.
*> WS-FOUND = "Y" when its location was written.
LSP-CALL-DEFINITION.
    PERFORM LSP-FIND-CALLED
    EVALUATE WS-CALL-WHERE
        WHEN "D"
            MOVE WS-CALL-TOKEN TO WS-LSP-TOKEN
            PERFORM LSP-APPEND-LOCATION
            MOVE "Y" TO WS-FOUND
        WHEN "O" WHEN "F"
            PERFORM LSP-APPEND-FOUND-PROGRAM
    END-EVALUATE.

*> Where the program of a CALL "NAME" at the position is, as
*> LSP-CALL-DEFINITION looks for it. WS-CALL-WHERE: D in the document
*> (WS-CALL-TOKEN its name), O in another open document, F in a file
*> (WS-LSP-TEXT-PATH its URI, WS-LSP-LINE and WS-LSP-CHAR its name),
*> space nowhere. WS-CALL-PATH: the file to read it from (the copy of
*> an open document's text, or the file).
LSP-FIND-CALLED.
    MOVE SPACE TO WS-CALL-WHERE
    MOVE "N" TO WS-FOUND
    MOVE SPACES TO WS-CALL-PATH
    IF WS-LSP-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-ALNUM(WS-LSP-TOKEN) OR WS-LSP-TOKEN < 2
        EXIT PARAGRAPH
    END-IF
    COMPUTE WS-TOK = WS-LSP-TOKEN - 1
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-TOK WS-LSP-NAME WS-TOKEN-LEN
    IF FUNCTION UPPER-CASE(WS-LSP-NAME) NOT = "CALL"
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-LSP-TOKEN WS-LSP-NAME
        WS-TOKEN-LEN
    MOVE FUNCTION UPPER-CASE(WS-LSP-NAME) TO WS-LSP-NAME
    *> A program of the document (a nested or a following one).
    PERFORM VARYING WS-NODE FROM 1 BY 1 UNTIL WS-NODE > AS-COUNT
        IF ND-KIND(WS-NODE) = "PROG" AND ND-NAME(WS-NODE) > 0
            MOVE ND-NAME(WS-NODE) TO WS-TOK
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-TOK
                WS-LSP-QUALIFIER WS-TOKEN-LEN
            IF FUNCTION UPPER-CASE(WS-LSP-QUALIFIER) = WS-LSP-NAME
               AND TK-SRC-LINE(WS-TOK) > 0
                MOVE "D" TO WS-CALL-WHERE
                MOVE WS-TOK TO WS-CALL-TOKEN
                MOVE DOC-TEMP(WS-LSP-DOC-INDEX) TO WS-CALL-PATH
                MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-CALL-LINE
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    *> Another open document, from the copy of its text.
    PERFORM VARYING WS-LSP-SLOT FROM 1 BY 1
            UNTIL WS-LSP-SLOT > LSP-DOC-MAX
        IF DOC-URI(WS-LSP-SLOT) NOT = SPACES
           AND WS-LSP-SLOT NOT = WS-LSP-DOC-INDEX
            CALL "PLB-FIND-PROGRAM-ID" USING DOC-TEMP(WS-LSP-SLOT)
                WS-LSP-NAME WS-LSP-LINE WS-LSP-CHAR
            IF WS-LSP-LINE > 0
                MOVE "O" TO WS-CALL-WHERE
                MOVE DOC-URI(WS-LSP-SLOT) TO WS-LSP-TEXT-PATH
                MOVE DOC-TEMP(WS-LSP-SLOT) TO WS-CALL-PATH
                MOVE WS-LSP-LINE TO WS-CALL-LINE
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    *> A file named after the program beside the document.
    IF DOC-DIR(WS-LSP-DOC-INDEX) = SPACES
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > 4
        MOVE SPACES TO WS-PATH
        EVALUATE WS-K
            WHEN 1
                STRING FUNCTION TRIM(DOC-DIR(WS-LSP-DOC-INDEX)) "/"
                       FUNCTION TRIM(WS-LSP-NAME) ".cbl"
                       DELIMITED BY SIZE INTO WS-PATH
            WHEN 2
                STRING FUNCTION TRIM(DOC-DIR(WS-LSP-DOC-INDEX)) "/"
                       FUNCTION TRIM(WS-LSP-NAME) ".cob"
                       DELIMITED BY SIZE INTO WS-PATH
            WHEN 3
                STRING FUNCTION TRIM(DOC-DIR(WS-LSP-DOC-INDEX)) "/"
                       FUNCTION LOWER-CASE(FUNCTION TRIM(WS-LSP-NAME))
                       ".cbl" DELIMITED BY SIZE INTO WS-PATH
            WHEN 4
                STRING FUNCTION TRIM(DOC-DIR(WS-LSP-DOC-INDEX)) "/"
                       FUNCTION LOWER-CASE(FUNCTION TRIM(WS-LSP-NAME))
                       ".cob" DELIMITED BY SIZE INTO WS-PATH
        END-EVALUATE
        CALL "PLB-FIND-PROGRAM-ID" USING WS-PATH WS-LSP-NAME
            WS-LSP-LINE WS-LSP-CHAR
        IF WS-LSP-LINE > 0
            MOVE "F" TO WS-CALL-WHERE
            MOVE SPACES TO WS-LSP-TEXT-PATH
            STRING "file://" DELIMITED BY SIZE
                   WS-PATH DELIMITED BY SPACE
                INTO WS-LSP-TEXT-PATH
            MOVE WS-PATH TO WS-CALL-PATH
            MOVE WS-LSP-LINE TO WS-CALL-LINE
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> textDocument/signatureHelp: inside the USING phrase of a CALL
*> "NAME", the parameters of the program called, with the one the
*> position is at or just after (the arguments before it counted)
*> active. Null when
*> the position is not in such a CALL, or its program is not found.
LSP-SIGNATURE-HELP.
    PERFORM LSP-POSITION
    PERFORM LSP-START-RESPONSE
    STRING '"result":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SIGNATURE-CALL
    IF WS-FOUND = "N"
        STRING "null" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> The CALL statement around the position: the last token of the
*> document at or before it (WS-SIG-TOKEN; WS-SIG-AT "Y" when the
*> position is in it or just after it), and the statement whose tokens
*> hold it.
LSP-SIGNATURE-CALL.
    MOVE "N" TO WS-FOUND
    IF WS-LSP-DOC-INDEX = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO WS-SIG-TOKEN
    PERFORM VARYING WS-TOK FROM 1 BY 1 UNTIL WS-TOK > TK-COUNT
        IF TK-FILE-ID(WS-TOK) = 1 AND TK-SRC-LINE(WS-TOK) > 0
            IF SL-LINE-NO(TK-SRC-LINE(WS-TOK)) < WS-LSP-LINE
               OR (SL-LINE-NO(TK-SRC-LINE(WS-TOK)) = WS-LSP-LINE
                   AND TK-COLUMN(WS-TOK) <= WS-LSP-CHAR)
                MOVE WS-TOK TO WS-SIG-TOKEN
            END-IF
        END-IF
    END-PERFORM
    IF WS-SIG-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO WS-SIG-AT
    IF SL-LINE-NO(TK-SRC-LINE(WS-SIG-TOKEN)) = WS-LSP-LINE
       AND TK-COLUMN(WS-SIG-TOKEN) + TK-SPAN(WS-SIG-TOKEN)
           >= WS-LSP-CHAR
        MOVE "Y" TO WS-SIG-AT
    END-IF
    MOVE 0 TO WS-SIG-STMT
    PERFORM VARYING WS-NODE FROM 1 BY 1 UNTIL WS-NODE > AS-COUNT
        IF ND-KIND(WS-NODE) = "STMT" AND ND-DETAIL(WS-NODE) = "CALL"
           AND ND-TOK-FIRST(WS-NODE) <= WS-SIG-TOKEN
           AND ND-TOK-LAST(WS-NODE) >= WS-SIG-TOKEN
            MOVE WS-NODE TO WS-SIG-STMT
        END-IF
    END-PERFORM
    IF WS-SIG-STMT = 0
        EXIT PARAGRAPH
    END-IF
    *> The program name, as hover and definition find its program.
    COMPUTE WS-LSP-TOKEN = ND-TOK-FIRST(WS-SIG-STMT) + 1
    PERFORM LSP-FIND-CALLED
    IF WS-CALL-WHERE = SPACE
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-FIND-PROGRAM-USING" USING WS-CALL-PATH WS-CALL-LINE
        WS-CALL-USING
    PERFORM LSP-SIGNATURE-PARAMETERS
    PERFORM LSP-SIGNATURE-ACTIVE
    PERFORM LSP-APPEND-SIGNATURE
    MOVE "Y" TO WS-FOUND.

*> WS-SIG-PARAM(1..WS-SIG-COUNT): the names of WS-CALL-USING after
*> USING, without BY REFERENCE, BY VALUE, and the like.
LSP-SIGNATURE-PARAMETERS.
    MOVE 0 TO WS-SIG-COUNT
    MOVE 1 TO WS-PTR
    PERFORM UNTIL WS-PTR > LENGTH OF WS-CALL-USING
        MOVE SPACES TO WS-SIG-WORD
        UNSTRING WS-CALL-USING DELIMITED BY ALL SPACE
            INTO WS-SIG-WORD WITH POINTER WS-PTR
        END-UNSTRING
        EVALUATE WS-SIG-WORD
            WHEN SPACES
                EXIT PERFORM
            WHEN "USING" WHEN "BY" WHEN "REFERENCE" WHEN "CONTENT"
            WHEN "VALUE" WHEN "RETURNING" WHEN "OPTIONAL"
                CONTINUE
            WHEN OTHER
                IF WS-SIG-COUNT < 64
                    ADD 1 TO WS-SIG-COUNT
                    MOVE WS-SIG-WORD TO WS-SIG-PARAM(WS-SIG-COUNT)
                END-IF
        END-EVALUATE
    END-PERFORM.

*> WS-SIG-ACTIVE: the arguments of the CALL after USING up to the
*> position, less one when the position is on the last of them.
LSP-SIGNATURE-ACTIVE.
    MOVE 0 TO WS-SIG-ACTIVE WS-SIG-USING
    MOVE "N" TO WS-SIG-SKIP
    PERFORM VARYING WS-TOK FROM ND-TOK-FIRST(WS-SIG-STMT) BY 1
            UNTIL WS-TOK > WS-SIG-TOKEN
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-TOK WS-SIG-WORD
            WS-TOKEN-LEN
        MOVE FUNCTION UPPER-CASE(WS-SIG-WORD) TO WS-SIG-WORD
        EVALUATE TRUE
            WHEN WS-SIG-USING = 0
                IF WS-SIG-WORD = "USING"
                    MOVE WS-TOK TO WS-SIG-USING
                END-IF
            WHEN WS-SIG-WORD = "BY" OR "REFERENCE" OR "CONTENT"
                 OR "VALUE" OR "ADDRESS" OR "LENGTH"
                CONTINUE
            WHEN WS-SIG-WORD = "OF" OR "IN"
                *> The qualifier after it is part of the same argument.
                MOVE "Y" TO WS-SIG-SKIP
            WHEN WS-SIG-SKIP = "Y"
                MOVE "N" TO WS-SIG-SKIP
            WHEN TK-IS-WORD(WS-TOK) OR TK-IS-ALNUM(WS-TOK)
                 OR TK-IS-NUMBER(WS-TOK)
                ADD 1 TO WS-SIG-ACTIVE
        END-EVALUATE
    END-PERFORM
    IF WS-SIG-AT = "Y" AND WS-SIG-ACTIVE > 0
        SUBTRACT 1 FROM WS-SIG-ACTIVE
    END-IF
    IF WS-SIG-COUNT > 0 AND WS-SIG-ACTIVE >= WS-SIG-COUNT
        COMPUTE WS-SIG-ACTIVE = WS-SIG-COUNT - 1
    END-IF.

*> {"signatures":[{"label":"NAME USING A B","parameters":[{"label":
*> "A"},{"label":"B"}]}],"activeSignature":0,"activeParameter":N}
LSP-APPEND-SIGNATURE.
    MOVE SPACES TO WS-CALL-HOVER
    STRING FUNCTION TRIM(WS-LSP-NAME) " " DELIMITED BY SIZE
           FUNCTION TRIM(WS-CALL-USING) DELIMITED BY SIZE
        INTO WS-CALL-HOVER
    STRING '{"signatures":[{"label":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING WS-CALL-HOVER WS-LSP-OUT WS-LSP-PTR
    STRING ',"parameters":[' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-SIG-COUNT
        IF WS-I > 1
            STRING "," DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
        STRING '{"label":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        CALL "PLB-JSON-STRING" USING WS-SIG-PARAM(WS-I) WS-LSP-OUT
            WS-LSP-PTR
        STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-PERFORM
    STRING ']}],"activeSignature":0,"activeParameter":'
        DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE WS-SIG-ACTIVE TO WS-NUM
    PERFORM LSP-APPEND-NUM
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Hover over the program name of a CALL "NAME": where the program is,
*> and what its PROCEDURE DIVISION takes.
*>     ```cobol
*>     PROGRAM-ID. CUSTLOOK.
*>     PROCEDURE DIVISION USING LK-CUST-ID LK-CUST-NAME.
*>     ```
*>     custlook.cbl, line 3
LSP-HOVER-CALL.
    PERFORM LSP-FIND-CALLED
    IF WS-CALL-WHERE = SPACE
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-FIND-PROGRAM-USING" USING WS-CALL-PATH WS-CALL-LINE
        WS-CALL-USING
    MOVE SPACES TO WS-LSP-HOVER
    MOVE 1 TO WS-PTR
    *> Real line ends: PLB-JSON-STRING escapes the text below.
    STRING "```cobol" X"0A" "PROGRAM-ID. " DELIMITED BY SIZE
           WS-LSP-NAME DELIMITED BY SPACE
           "." X"0A" "PROCEDURE DIVISION" DELIMITED BY SIZE
        INTO WS-LSP-HOVER WITH POINTER WS-PTR
    IF WS-CALL-USING NOT = SPACES
        STRING " " DELIMITED BY SIZE
               FUNCTION TRIM(WS-CALL-USING) DELIMITED BY SIZE
            INTO WS-LSP-HOVER WITH POINTER WS-PTR
    END-IF
    STRING "." X"0A" "```" X"0A" DELIMITED BY SIZE
        INTO WS-LSP-HOVER WITH POINTER WS-PTR
    MOVE WS-CALL-LINE TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    EVALUATE WS-CALL-WHERE
        WHEN "D"
            STRING "In this file, line " WS-NUM-TEXT(1:WS-NUM-LEN)
                   "." DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
        WHEN OTHER
            *> The file's name, after the last slash of its URI.
            CALL "PLB-STR-LENGTH" USING WS-LSP-TEXT-PATH WS-LEN
            PERFORM VARYING WS-K FROM WS-LEN BY -1 UNTIL WS-K < 1
                IF WS-LSP-TEXT-PATH(WS-K:1) = "/"
                    EXIT PERFORM
                END-IF
            END-PERFORM
            STRING "`" WS-LSP-TEXT-PATH(WS-K + 1:WS-LEN - WS-K)
                   "`, line " WS-NUM-TEXT(1:WS-NUM-LEN) "."
                   DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
    END-EVALUATE
    STRING '{"contents":{"kind":"markdown","value":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-LEN = WS-PTR - 1
    MOVE WS-LSP-HOVER(1:WS-LEN) TO WS-CALL-HOVER
    CALL "PLB-JSON-STRING" USING WS-CALL-HOVER WS-LSP-OUT WS-LSP-PTR
    *> The contents, the hover, and the response.
    STRING '}}}' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-FOUND.

*> The location WS-LSP-TEXT-PATH (a URI), WS-LSP-LINE, WS-LSP-CHAR.
LSP-APPEND-FOUND-PROGRAM.
    MOVE 0 TO WS-LSP-TOKEN
    STRING '{"uri":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING WS-LSP-TEXT-PATH WS-LSP-OUT WS-LSP-PTR
    STRING ',"range":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-RANGE
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-FOUND.

*> WS-I: the inclusion made by a COPY statement of the document on the
*> line of the position, at or before its character, or 0. The COPY
*> statement itself leaves no tokens, so this is found by its place.
LSP-COPYBOOK-AT-LINE.
    MOVE 0 TO WS-J
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IN-COUNT
        IF IN-PARENT(WS-I) = 0 AND IN-FROM-FILE-ID(WS-I) = 1
           AND IN-FROM-LINE(WS-I) = WS-LSP-LINE
           AND IN-FROM-COLUMN(WS-I) <= WS-LSP-CHAR
            MOVE WS-I TO WS-J
        END-IF
    END-PERFORM
    MOVE WS-J TO WS-I.

*> The first line of the copybook of inclusion WS-I.
LSP-APPEND-COPYBOOK.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET IN-FILE-ID(WS-I)
        WS-PATH
    MOVE SPACES TO WS-LSP-TEXT-PATH
    STRING "file://" DELIMITED BY SIZE
           WS-PATH DELIMITED BY SPACE
        INTO WS-LSP-TEXT-PATH
    STRING '{"uri":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING WS-LSP-TEXT-PATH WS-LSP-OUT WS-LSP-PTR
    STRING ',"range":{"start":{"line":0,"character":0},'
           '"end":{"line":0,"character":0}}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> textDocument/references and textDocument/documentHighlight: the
*> declaration of the data item or procedure at the position, and every
*> reference to it. References list locations in copybooks too, and
*> leave out the declaration unless the request includes it;
*> highlights stay in the document, and tell reads from writes.
LSP-REFERENCES.
    PERFORM LSP-POSITION
    PERFORM LSP-TARGET
    MOVE "Y" TO WS-LSP-DECLARATION
    IF WS-LSP-HIGHLIGHT = "N"
        MOVE "includeDeclaration" TO WS-LSP-NAME
        PERFORM LSP-GET
        IF WS-LSP-VALUE(1:5) = "false"
            MOVE "N" TO WS-LSP-DECLARATION
        END-IF
    END-IF
    PERFORM LSP-START-RESPONSE
    STRING '"result":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-SYMBOL = 0 AND WS-LSP-UNIT = 0
        STRING "null}" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        PERFORM LSP-SEND-OUT
        EXIT PARAGRAPH
    END-IF
    STRING "[" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-LSP-FIRST
    PERFORM LSP-COLLECT-REFERENCES
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> LSP-APPEND-REFERENCE for the declaration of the target (when
*> WS-LSP-DECLARATION is "Y") and each reference to it.
LSP-COLLECT-REFERENCES.
    IF WS-LSP-SYMBOL > 0
        IF WS-LSP-DECLARATION = "Y"
            MOVE SY-NAME-TOKEN(WS-LSP-SYMBOL) TO WS-LSP-TOKEN
            MOVE "3" TO WS-LSP-KIND
            PERFORM LSP-APPEND-REFERENCE
        END-IF
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > RF-COUNT
            IF RF-KIND(WS-I) = "D" AND RF-SYMBOL(WS-I) = WS-LSP-SYMBOL
                MOVE RF-TOKEN(WS-I) TO WS-LSP-TOKEN
                EVALUATE RF-ROLE(WS-I)
                    WHEN "U"
                        MOVE "2" TO WS-LSP-KIND
                    WHEN "D"
                    WHEN "B"
                        MOVE "3" TO WS-LSP-KIND
                    WHEN OTHER
                        MOVE "1" TO WS-LSP-KIND
                END-EVALUATE
                PERFORM LSP-APPEND-REFERENCE
            END-IF
        END-PERFORM
    ELSE
        IF WS-LSP-DECLARATION = "Y"
            MOVE ND-NAME(FU-NODE(WS-LSP-UNIT)) TO WS-LSP-TOKEN
            MOVE "1" TO WS-LSP-KIND
            PERFORM LSP-APPEND-REFERENCE
        END-IF
        *> The procedure names in the same program that name the unit:
        *> by name, and by section when qualified.
        MOVE FU-PROGRAM(WS-LSP-UNIT) TO WS-ROOT
        PERFORM VARYING WS-NODE FROM 1 BY 1 UNTIL WS-NODE > AS-COUNT
            IF ND-KIND(WS-NODE) = "PROC" AND ND-NAME(WS-NODE) > 0
               AND ND-NAME(WS-NODE) >= ND-TOK-FIRST(WS-ROOT)
               AND ND-NAME(WS-NODE) <= ND-TOK-LAST(WS-ROOT)
                PERFORM LSP-PROC-NAMES-UNIT
            END-IF
        END-PERFORM
    END-IF.

*> PROC node WS-NODE names unit WS-LSP-UNIT: list it.
LSP-PROC-NAMES-UNIT.
    MOVE ND-NAME(WS-NODE) TO WS-LSP-TOKEN
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-LSP-TOKEN WS-LSP-NAME
        WS-TOKEN-LEN
    IF WS-LSP-NAME NOT = FU-NAME(WS-LSP-UNIT)
        EXIT PARAGRAPH
    END-IF
    *> Not in a program nested in the unit's program.
    MOVE ND-PARENT(WS-NODE) TO WS-P
    PERFORM UNTIL WS-P = 0
        IF ND-KIND(WS-P) = "PROG"
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(WS-P) TO WS-P
    END-PERFORM
    IF WS-P NOT = WS-ROOT
        EXIT PARAGRAPH
    END-IF
    IF ND-TOK-LAST(WS-NODE) >= WS-LSP-TOKEN + 2
        COMPUTE WS-TOK = WS-LSP-TOKEN + 2
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-TOK WS-LSP-QUALIFIER
            WS-TOKEN-LEN
        IF FU-SECTION(WS-LSP-UNIT) = 0
            EXIT PARAGRAPH
        END-IF
        IF WS-LSP-QUALIFIER NOT = FU-NAME(FU-SECTION(WS-LSP-UNIT))
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE "1" TO WS-LSP-KIND
    PERFORM LSP-APPEND-REFERENCE.

*> One location (references) or highlight (or for a rename, an edit) of WS-LSP-KIND (1 text,
*> 2 read, 3 write) for token WS-LSP-TOKEN, unless it is outside the
*> document for a highlight, or has no source line.
LSP-APPEND-REFERENCE.
    IF WS-LSP-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    IF TK-SRC-LINE(WS-LSP-TOKEN) = 0
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-HIGHLIGHT = "R"
        PERFORM LSP-ADD-EDIT
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-HIGHLIGHT = "Y" AND TK-FILE-ID(WS-LSP-TOKEN) NOT = 1
        EXIT PARAGRAPH
    END-IF
    *> Leave room for the closing brackets.
    IF WS-LSP-PTR > LSP-SIZE - 2048
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    IF WS-LSP-HIGHLIGHT = "Y"
        STRING '{"range":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        MOVE SL-LINE-NO(TK-SRC-LINE(WS-LSP-TOKEN)) TO WS-LSP-LINE
        MOVE TK-COLUMN(WS-LSP-TOKEN) TO WS-LSP-CHAR
        PERFORM LSP-APPEND-RANGE
        STRING ',"kind":' DELIMITED BY SIZE
               WS-LSP-KIND DELIMITED BY SIZE
               "}" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        PERFORM LSP-APPEND-LOCATION
    END-IF.

*> Quick fixes -----------------------------------------------------

*> textDocument/codeAction: for each rule with a finding on the first
*> line of the request's range, an edit that puts a suppression comment
*> on the line before it, indented like the line (in fixed format, in
*> the indicator column). The line is the first "line" in the request,
*> which is the start of its range: clients send the range before the
*> context.
LSP-CODE-ACTIONS.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        MOVE "line" TO WS-LSP-NAME
        PERFORM LSP-GET
        COMPUTE WS-LSP-LINE = FUNCTION NUMVAL(WS-LSP-VALUE) + 1
        MOVE "Y" TO WS-LSP-FIRST
        MOVE SPACES TO WS-LSP-OFFERED
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
            IF FN-SUPPRESSED(WS-I) = "N" AND FN-FILE-ID(WS-I) = 1
               AND FN-LINE(WS-I) = WS-LSP-LINE AND FN-SRC-LINE(WS-I) > 0
                PERFORM LSP-APPEND-SUPPRESS-ACTION
                CALL "PLB-FIX-FINDING" USING PLB-SOURCE-SET PLB-TOKENS
                    PLB-AST PLB-RULES PLB-FINDINGS WS-I PLB-FIX
                IF FX-EDIT-COUNT > 0
                    PERFORM LSP-APPEND-FIX-ACTION
                END-IF
            END-IF
        END-PERFORM
        PERFORM LSP-APPEND-FIX-ALL-ACTION
    END-IF
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> A source.fixAll action: the fixes of every finding of the document
*> that has one, taken together as plumbline fix takes them
*> (PLB-FIX-ACCEPT: whole or not at all, none overlapping another).
LSP-APPEND-FIX-ALL-ACTION.
    MOVE 0 TO FXL-COUNT WS-FIX-COUNT
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N" AND FN-FILE-ID(WS-I) = 1
           AND FN-SRC-LINE(WS-I) > 0
            CALL "PLB-FIX-FINDING" USING PLB-SOURCE-SET PLB-TOKENS
                PLB-AST PLB-RULES PLB-FINDINGS WS-I PLB-FIX
            IF FX-EDIT-COUNT > 0
                MOVE 1 TO WS-FILE-ID
                CALL "PLB-FIX-ACCEPT" USING PLB-SOURCE-SET WS-FILE-ID
                    PLB-FIX PLB-FIX-LIST WS-FIX-RESULT
                IF WS-FIX-RESULT = "Y"
                    ADD 1 TO WS-FIX-COUNT
                END-IF
            END-IF
        END-IF
    END-PERFORM
    IF FXL-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    *> Columns 73 on stay where they are, as with plumbline fix.
    CALL "PLB-FIX-ALIGN" USING PLB-SOURCE-SET WS-FILE-ID PLB-FIX-LIST
    *> All the edits or none: an action that would not fit is left out.
    COMPUTE WS-NUM = WS-LSP-PTR + 1024
    PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > FXL-COUNT
        COMPUTE WS-NUM = WS-NUM + 120 + 2 * FXL-TEXT-LEN(WS-K)
    END-PERFORM
    IF WS-NUM > LSP-SIZE
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    STRING '{"title":"Make the fixes of Plumbline findings in this file",'
           DELIMITED BY SIZE
           '"kind":"source.fixAll","edit":{"changes":{' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING DOC-URI(WS-LSP-DOC-INDEX) WS-LSP-OUT
        WS-LSP-PTR
    STRING ":[" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > FXL-COUNT
        IF WS-K > 1
            STRING "," DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
        STRING '{"range":{"start":{"line":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FXL-LINE(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING ',"character":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FXL-COLUMN(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING '},"end":{"line":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FXL-LINE(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING ',"character":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FXL-END-COLUMN(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING '}},"newText":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        IF FXL-TEXT-LEN(WS-K) = 0
            STRING '""' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        ELSE
            CALL "PLB-JSON-STRING" USING
                FXL-TEXT(WS-K)(1:FXL-TEXT-LEN(WS-K)) WS-LSP-OUT WS-LSP-PTR
        END-IF
        STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-PERFORM
    STRING "]}}}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> A quick fix suppressing finding WS-I's rule, once per rule.
LSP-APPEND-SUPPRESS-ACTION.
    MOVE 0 TO WS-K
    INSPECT WS-LSP-OFFERED TALLYING WS-K
        FOR ALL RL-ID(FN-RULE(WS-I))(1:8)
    IF WS-K > 0 OR WS-LSP-PTR > LSP-SIZE - 4096
        EXIT PARAGRAPH
    END-IF
    MOVE 1 TO WS-PTR
    INSPECT WS-LSP-OFFERED TALLYING WS-PTR FOR CHARACTERS BEFORE "  "
    IF WS-PTR < 390
        MOVE RL-ID(FN-RULE(WS-I))(1:8) TO WS-LSP-OFFERED(WS-PTR + 1:8)
    END-IF
    IF SL-FORMAT(FN-SRC-LINE(WS-I)) = "X"
       OR SL-FORMAT(FN-SRC-LINE(WS-I)) = "V"
        MOVE 6 TO WS-LSP-INDENT
    ELSE
        COMPUTE WS-LSP-INDENT = SL-CONTENT-COL(FN-SRC-LINE(WS-I)) - 1
        IF WS-LSP-INDENT > 60
            MOVE 0 TO WS-LSP-INDENT
        END-IF
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    STRING '{"title":"Suppress ' DELIMITED BY SIZE
           RL-ID(FN-RULE(WS-I)) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
           RL-NAME(FN-RULE(WS-I)) DELIMITED BY SPACE
           ' on this line","kind":"quickfix",' DELIMITED BY SIZE
           '"edit":{"changes":{' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING DOC-URI(WS-LSP-DOC-INDEX) WS-LSP-OUT
        WS-LSP-PTR
    COMPUTE WS-NUM = WS-LSP-LINE - 1
    STRING ':[{"range":{"start":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-NUM
    STRING ',"character":0},"end":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-NUM
    STRING ',"character":0}},"newText":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-INDENT > 0
        STRING WS-LSP-BLANKS(1:WS-LSP-INDENT) DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    STRING "*> plumbline: ignore " DELIMITED BY SIZE
           RL-NAME(FN-RULE(WS-I)) DELIMITED BY SPACE
           '\n"}]}}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> The fix of finding WS-I (PLB-FIX-FINDING) as a quick fix: its
*> title, and its edits as TextEdits of the document.
LSP-APPEND-FIX-ACTION.
    IF WS-LSP-PTR > LSP-SIZE - 8192
        EXIT PARAGRAPH
    END-IF
    STRING ',{"title":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING FX-TITLE WS-LSP-OUT WS-LSP-PTR
    STRING ',"kind":"quickfix","edit":{"changes":{' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING DOC-URI(WS-LSP-DOC-INDEX) WS-LSP-OUT
        WS-LSP-PTR
    STRING ":[" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > FX-EDIT-COUNT
        IF WS-K > 1
            STRING "," DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
        STRING '{"range":{"start":{"line":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FX-LINE(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING ',"character":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FX-COLUMN(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING '},"end":{"line":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FX-END-LINE(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING ',"character":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        COMPUTE WS-NUM = FX-END-COLUMN(WS-K) - 1
        PERFORM LSP-APPEND-NUM
        STRING '}},"newText":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        IF FX-TEXT-LEN(WS-K) = 0
            STRING '""' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        ELSE
            CALL "PLB-JSON-STRING" USING
                FX-TEXT(WS-K)(1:FX-TEXT-LEN(WS-K)) WS-LSP-OUT WS-LSP-PTR
        END-IF
        STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-PERFORM
    STRING "]}}}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Semantic tokens --------------------------------------------------

*> textDocument/semanticTokens/full: the tokens of the document (not
*> of its copybooks), classified from the analysis: reserved words,
*> data names, paragraph and section names, literals, operators, and
*> pictures; data and procedure names where they are declared carry
*> the declaration modifier. Encoded as LSP asks: five numbers a token,
*> each place relative to the token before.
LSP-SEMANTIC-TOKENS.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":{"data":[' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        PERFORM LSP-CLASSIFY-TOKENS
        MOVE "Y" TO WS-LSP-FIRST
        MOVE 1 TO WS-LSP-PREV-LINE WS-LSP-PREV-CHAR
        PERFORM VARYING WS-TOK FROM 1 BY 1 UNTIL WS-TOK > TK-COUNT
            IF WS-LSP-TOKEN-TYPE(WS-TOK) < 9
               AND WS-LSP-PTR < LSP-SIZE - 256
                PERFORM LSP-APPEND-SEMANTIC-TOKEN
            END-IF
        END-PERFORM
    END-IF
    STRING "]}}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> WS-LSP-TOKEN-TYPE and WS-LSP-TOKEN-DECL for the tokens of the
*> document written in it: not those a copybook brought in.
LSP-CLASSIFY-TOKENS.
    PERFORM VARYING WS-TOK FROM 1 BY 1 UNTIL WS-TOK > TK-COUNT
        MOVE 9 TO WS-LSP-TOKEN-TYPE(WS-TOK)
        MOVE 0 TO WS-LSP-TOKEN-DECL(WS-TOK)
        IF TK-FILE-ID(WS-TOK) = 1 AND TK-INCL(WS-TOK) = 0
           AND TK-SRC-LINE(WS-TOK) > 0
            EVALUATE TRUE
                WHEN TK-IS-ALNUM(WS-TOK)
                    MOVE 3 TO WS-LSP-TOKEN-TYPE(WS-TOK)
                WHEN TK-IS-NUMBER(WS-TOK)
                    MOVE 4 TO WS-LSP-TOKEN-TYPE(WS-TOK)
                WHEN TK-IS-OPERATOR(WS-TOK)
                    MOVE 5 TO WS-LSP-TOKEN-TYPE(WS-TOK)
                WHEN TK-IS-PICTURE(WS-TOK)
                    MOVE 6 TO WS-LSP-TOKEN-TYPE(WS-TOK)
                WHEN TK-IS-WORD(WS-TOK) AND TK-KEYWORD(WS-TOK) = "S"
                    MOVE 1 TO WS-LSP-TOKEN-TYPE(WS-TOK)
                WHEN TK-IS-WORD(WS-TOK) AND TK-KEYWORD(WS-TOK) NOT = SPACE
                    MOVE 0 TO WS-LSP-TOKEN-TYPE(WS-TOK)
            END-EVALUATE
        END-IF
    END-PERFORM
    *> Names: data references, declared data items, procedures.
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > RF-COUNT
        IF RF-KIND(WS-I) = "D" OR RF-KIND(WS-I) = "A"
            MOVE RF-TOKEN(WS-I) TO WS-TOK
            PERFORM LSP-NAME-TOKEN-AS-VARIABLE
        END-IF
    END-PERFORM
    PERFORM VARYING WS-S FROM 1 BY 1 UNTIL WS-S > SY-COUNT
        IF SY-NAME-TOKEN(WS-S) > 0
            MOVE SY-NAME-TOKEN(WS-S) TO WS-TOK
            PERFORM LSP-NAME-TOKEN-AS-VARIABLE
            IF WS-LSP-TOKEN-TYPE(WS-TOK) = 1
                MOVE 1 TO WS-LSP-TOKEN-DECL(WS-TOK)
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING WS-NODE FROM 1 BY 1 UNTIL WS-NODE > AS-COUNT
        IF ND-NAME(WS-NODE) > 0
            EVALUATE ND-KIND(WS-NODE)
                WHEN "PARA" WHEN "SECT"
                    MOVE ND-NAME(WS-NODE) TO WS-TOK
                    PERFORM LSP-NAME-TOKEN-AS-FUNCTION
                    IF WS-LSP-TOKEN-TYPE(WS-TOK) = 2
                        MOVE 1 TO WS-LSP-TOKEN-DECL(WS-TOK)
                    END-IF
                WHEN "PROC"
                    MOVE ND-NAME(WS-NODE) TO WS-TOK
                    PERFORM LSP-NAME-TOKEN-AS-FUNCTION
            END-EVALUATE
        END-IF
    END-PERFORM.

LSP-NAME-TOKEN-AS-VARIABLE.
    IF TK-FILE-ID(WS-TOK) = 1 AND TK-INCL(WS-TOK) = 0
       AND TK-SRC-LINE(WS-TOK) > 0 AND TK-IS-WORD(WS-TOK)
        MOVE 1 TO WS-LSP-TOKEN-TYPE(WS-TOK)
    END-IF.

LSP-NAME-TOKEN-AS-FUNCTION.
    IF TK-FILE-ID(WS-TOK) = 1 AND TK-INCL(WS-TOK) = 0
       AND TK-SRC-LINE(WS-TOK) > 0 AND TK-IS-WORD(WS-TOK)
        MOVE 2 TO WS-LSP-TOKEN-TYPE(WS-TOK)
    END-IF.

*> deltaLine, deltaStart, length, type, modifiers of token WS-TOK. A
*> token continued onto the next line counts to its line's end.
LSP-APPEND-SEMANTIC-TOKEN.
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-LSP-LINE
    MOVE TK-COLUMN(WS-TOK) TO WS-LSP-CHAR
    MOVE TK-SPAN(WS-TOK) TO WS-LSP-SPAN
    IF WS-LSP-CHAR + WS-LSP-SPAN - 1 > SL-TEXT-LEN(TK-SRC-LINE(WS-TOK))
        COMPUTE WS-LSP-SPAN =
            SL-TEXT-LEN(TK-SRC-LINE(WS-TOK)) - WS-LSP-CHAR + 1
    END-IF
    IF WS-LSP-SPAN = 0 OR WS-LSP-LINE < WS-LSP-PREV-LINE
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-LINE = WS-LSP-PREV-LINE AND WS-LSP-CHAR < WS-LSP-PREV-CHAR
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    COMPUTE WS-NUM = WS-LSP-LINE - WS-LSP-PREV-LINE
    PERFORM LSP-APPEND-NUM
    STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-LINE = WS-LSP-PREV-LINE
        COMPUTE WS-NUM = WS-LSP-CHAR - WS-LSP-PREV-CHAR
    ELSE
        COMPUTE WS-NUM = WS-LSP-CHAR - 1
    END-IF
    PERFORM LSP-APPEND-NUM
    STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE WS-LSP-SPAN TO WS-NUM
    PERFORM LSP-APPEND-NUM
    STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE WS-LSP-TOKEN-TYPE(WS-TOK) TO WS-NUM
    PERFORM LSP-APPEND-NUM
    STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE WS-LSP-TOKEN-DECL(WS-TOK) TO WS-NUM
    PERFORM LSP-APPEND-NUM
    MOVE WS-LSP-LINE TO WS-LSP-PREV-LINE
    MOVE WS-LSP-CHAR TO WS-LSP-PREV-CHAR.

*> Call hierarchy ---------------------------------------------------

*> textDocument/prepareCallHierarchy: the paragraph or section named
*> at the position, as a call hierarchy item; null for anything else.
*> The hierarchy follows PERFORM, GO TO, and ALTER, as the procedure
*> graph does.
LSP-PREPARE-CALL-HIERARCHY.
    PERFORM LSP-POSITION
    PERFORM LSP-TARGET
    PERFORM LSP-START-RESPONSE
    STRING '"result":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-UNIT = 0
        STRING "null}" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        STRING "[" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        MOVE WS-LSP-UNIT TO WS-LSP-ITEM-UNIT
        PERFORM LSP-APPEND-HIERARCHY-ITEM
        STRING "]}" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    PERFORM LSP-SEND-OUT.

*> callHierarchy/incomingCalls and outgoingCalls. The item comes back
*> as the request's first uri and line: the place of the unit's name.
*> Each unit at the other end of the edges is listed once, with the
*> procedure names of all its edges as fromRanges.
LSP-HIERARCHY-CALLS.
    PERFORM LSP-POSITION
    PERFORM LSP-TARGET
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-LSP-FIRST
    IF WS-LSP-UNIT > 0
        PERFORM VARYING WS-LSP-EDGE FROM 1 BY 1
                UNTIL WS-LSP-EDGE > FE-COUNT
            PERFORM LSP-EDGE-OTHER-END
            IF WS-LSP-OTHER > 0
                PERFORM LSP-FIRST-EDGE-TO-OTHER
                IF WS-LSP-EDGE-2 = WS-LSP-EDGE
                   AND WS-LSP-PTR < LSP-SIZE - 8192
                    PERFORM LSP-APPEND-HIERARCHY-CALL
                END-IF
            END-IF
        END-PERFORM
    END-IF
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> WS-LSP-OTHER = the unit at the other end of edge WS-LSP-EDGE when
*> the edge touches WS-LSP-UNIT the way asked, else 0.
LSP-EDGE-OTHER-END.
    MOVE 0 TO WS-LSP-OTHER
    IF FE-TO(WS-LSP-EDGE) = 0
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-DIRECTION = "I"
        IF FE-TO(WS-LSP-EDGE) = WS-LSP-UNIT
            MOVE FE-FROM(WS-LSP-EDGE) TO WS-LSP-OTHER
        END-IF
    ELSE
        IF FE-FROM(WS-LSP-EDGE) = WS-LSP-UNIT
            MOVE FE-TO(WS-LSP-EDGE) TO WS-LSP-OTHER
        END-IF
    END-IF.

*> WS-LSP-EDGE-2 = the first edge with the same other end.
LSP-FIRST-EDGE-TO-OTHER.
    MOVE WS-LSP-OTHER TO WS-K
    MOVE WS-LSP-EDGE TO WS-J
    PERFORM VARYING WS-LSP-EDGE-2 FROM 1 BY 1
            UNTIL WS-LSP-EDGE-2 >= WS-J
        MOVE WS-LSP-EDGE-2 TO WS-LSP-EDGE
        PERFORM LSP-EDGE-OTHER-END
        IF WS-LSP-OTHER = WS-K
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE WS-J TO WS-LSP-EDGE
    MOVE WS-K TO WS-LSP-OTHER.

*> {"from"|"to": item, "fromRanges": [the procedure names]}.
LSP-APPEND-HIERARCHY-CALL.
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    IF WS-LSP-DIRECTION = "I"
        STRING '{"from":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        STRING '{"to":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE WS-LSP-OTHER TO WS-LSP-ITEM-UNIT
    PERFORM LSP-APPEND-HIERARCHY-ITEM
    STRING ',"fromRanges":[' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE WS-LSP-EDGE TO WS-J
    MOVE WS-LSP-OTHER TO WS-K
    MOVE "Y" TO WS-LSP-SEVERITY
    PERFORM VARYING WS-LSP-EDGE FROM WS-J BY 1
            UNTIL WS-LSP-EDGE > FE-COUNT
        PERFORM LSP-EDGE-OTHER-END
        IF WS-LSP-OTHER = WS-K AND FE-PROC(WS-LSP-EDGE) > 0
            MOVE ND-NAME(FE-PROC(WS-LSP-EDGE)) TO WS-LSP-TOKEN
            IF WS-LSP-TOKEN > 0
                IF TK-SRC-LINE(WS-LSP-TOKEN) > 0
                    IF WS-LSP-SEVERITY = "N"
                        STRING "," DELIMITED BY SIZE
                            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
                    END-IF
                    MOVE "N" TO WS-LSP-SEVERITY
                    MOVE SL-LINE-NO(TK-SRC-LINE(WS-LSP-TOKEN))
                        TO WS-LSP-LINE
                    MOVE TK-COLUMN(WS-LSP-TOKEN) TO WS-LSP-CHAR
                    PERFORM LSP-APPEND-RANGE
                END-IF
            END-IF
        END-IF
    END-PERFORM
    MOVE WS-J TO WS-LSP-EDGE
    MOVE WS-K TO WS-LSP-OTHER
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> A CallHierarchyItem for unit WS-LSP-ITEM-UNIT: its name (or that of
*> the division, for the code before the first paragraph), and the
*> place of the name as range and selectionRange.
LSP-APPEND-HIERARCHY-ITEM.
    MOVE ND-NAME(FU-NODE(WS-LSP-ITEM-UNIT)) TO WS-LSP-TOKEN
    IF WS-LSP-TOKEN = 0
        MOVE ND-TOK-FIRST(FU-NODE(WS-LSP-ITEM-UNIT)) TO WS-LSP-TOKEN
    END-IF
    STRING '{"name":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF FU-KIND(WS-LSP-ITEM-UNIT) = "D"
        STRING '"PROCEDURE DIVISION"' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        CALL "PLB-JSON-STRING" USING FU-NAME(WS-LSP-ITEM-UNIT)
            WS-LSP-OUT WS-LSP-PTR
    END-IF
    STRING ',"kind":12,"detail":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    EVALUATE FU-KIND(WS-LSP-ITEM-UNIT)
        WHEN "S"
            STRING '"section",' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN "P"
            STRING '"paragraph",' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN OTHER
            STRING '"start",' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-EVALUATE
    *> {"uri":...,"range":...} without its braces, then the same range
    *> as selectionRange.
    MOVE WS-LSP-PTR TO WS-LSP-BRACE
    PERFORM LSP-APPEND-LOCATION
    MOVE SPACE TO WS-LSP-OUT(WS-LSP-BRACE:1)
    SUBTRACT 1 FROM WS-LSP-PTR
    STRING ',"selectionRange":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-RANGE
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Folding --------------------------------------------------------

*> textDocument/foldingRange: divisions, sections, paragraphs, and
*> statements with a body (IF, EVALUATE, inline PERFORM, ...) that span
*> more than one line of the document. A range ends at the last line
*> of the document it covers: the lines a COPY brings in are not in it.
LSP-FOLDING-RANGES.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        MOVE "Y" TO WS-LSP-FIRST
        PERFORM VARYING WS-NODE FROM 1 BY 1 UNTIL WS-NODE > AS-COUNT
            EVALUATE ND-KIND(WS-NODE)
                WHEN "PROG"
                WHEN "DIVN"
                WHEN "SECT"
                WHEN "PARA"
                    PERFORM LSP-APPEND-FOLD
                WHEN "STMT"
                    *> Only statements with a body.
                    MOVE ND-FIRST(WS-NODE) TO WS-U
                    PERFORM UNTIL WS-U = 0
                        IF ND-KIND(WS-U) = "BLCK"
                            PERFORM LSP-APPEND-FOLD
                            EXIT PERFORM
                        END-IF
                        MOVE ND-NEXT(WS-U) TO WS-U
                    END-PERFORM
            END-EVALUATE
        END-PERFORM
    END-IF
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> {"startLine":N,"endLine":M} for node WS-NODE, when it starts in the
*> document and ends on a later line of it.
LSP-APPEND-FOLD.
    MOVE ND-TOK-FIRST(WS-NODE) TO WS-TOK
    IF WS-TOK = 0 OR TK-FILE-ID(WS-TOK) NOT = 1
       OR TK-SRC-LINE(WS-TOK) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-LSP-LINE
    MOVE ND-TOK-LAST(WS-NODE) TO WS-TOK
    PERFORM UNTIL WS-TOK <= ND-TOK-FIRST(WS-NODE)
        IF TK-FILE-ID(WS-TOK) = 1 AND TK-SRC-LINE(WS-TOK) > 0
           AND NOT TK-IS-EOF(WS-TOK)
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM WS-TOK
    END-PERFORM
    IF TK-SRC-LINE(WS-TOK) = 0
        EXIT PARAGRAPH
    END-IF
    IF SL-LINE-NO(TK-SRC-LINE(WS-TOK)) <= WS-LSP-LINE
       OR WS-LSP-PTR > LSP-SIZE - 1024
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    STRING '{"startLine":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = WS-LSP-LINE - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"endLine":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = SL-LINE-NO(TK-SRC-LINE(WS-TOK)) - 1
    PERFORM LSP-APPEND-NUM
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> textDocument/completion: the names of the data items (also from
*> copybooks), paragraphs, and sections of the document, each once.
*> The editor filters them by what has been typed. A data item's
*> detail is its picture (or group), usage, and size; a procedure's,
*> paragraph or section.
LSP-COMPLETION.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":{"isIncomplete":false,"items":[' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        MOVE "Y" TO WS-LSP-FIRST
        MOVE 0 TO WS-CS-COUNT
        PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > CS-BUCKETS
            MOVE 0 TO WS-CS-HEAD(WS-K)
        END-PERFORM
        PERFORM VARYING WS-S FROM 1 BY 1 UNTIL WS-S > SY-COUNT
            IF SY-NAME-TOKEN(WS-S) > 0 AND SY-NAME(WS-S) NOT = "FILLER"
               AND WS-LSP-PTR < LSP-SIZE - 1024
                PERFORM LSP-COMPLETION-SYMBOL
            END-IF
        END-PERFORM
        PERFORM VARYING WS-U FROM 1 BY 1 UNTIL WS-U > FU-COUNT
            IF (FU-KIND(WS-U) = "P" OR FU-KIND(WS-U) = "S")
               AND WS-LSP-PTR < LSP-SIZE - 1024
                PERFORM LSP-COMPLETION-UNIT
            END-IF
        END-PERFORM
    END-IF
    STRING "]}}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> Data item WS-S, unless an item of the same name came before.
LSP-COMPLETION-SYMBOL.
    MOVE SY-NAME(WS-S) TO WS-LSP-SEEN-NAME
    PERFORM LSP-COMPLETION-SEEN
    IF WS-LSP-SEEN = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM LSP-COMPLETION-SEPARATOR
    STRING '{"label":"' DELIMITED BY SIZE
           SY-NAME(WS-S) DELIMITED BY SPACE
           '","kind":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    *> 21 Constant for 78 and condition names, else 6 Variable.
    IF SY-LEVEL(WS-S) = 88 OR SY-LEVEL(WS-S) = 78
        STRING '21' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        STRING '6' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    STRING ',"detail":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    *> PIC x [usage], or group, and the size.
    MOVE SPACES TO WS-LSP-PIC
    MOVE ND-FIRST(SY-NODE(WS-S)) TO WS-NODE
    PERFORM UNTIL WS-NODE = 0
        IF ND-KIND(WS-NODE) = "CLAU" AND ND-DETAIL(WS-NODE) = "PICTURE"
           AND ND-NAME(WS-NODE) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(WS-NODE)
                WS-LSP-PIC WS-TOKEN-LEN
        END-IF
        MOVE ND-NEXT(WS-NODE) TO WS-NODE
    END-PERFORM
    EVALUATE TRUE
        WHEN WS-LSP-PIC NOT = SPACES
            STRING "PIC " DELIMITED BY SIZE
                   WS-LSP-PIC DELIMITED BY SPACE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN SY-CATEGORY(WS-S) = "G"
            STRING "group" DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN SY-LEVEL(WS-S) = 88
            STRING "condition" DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN OTHER
            MOVE SY-LEVEL(WS-S) TO WS-NUM
            STRING "level " DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            PERFORM LSP-APPEND-NUM
    END-EVALUATE
    IF SY-USAGE(WS-S) NOT = SPACES
        STRING " " DELIMITED BY SIZE
               SY-USAGE(WS-S) DELIMITED BY SPACE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    IF SY-SIZE(WS-S) > 0 AND SY-LEVEL(WS-S) NOT = 88
        STRING ", " DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        MOVE SY-SIZE(WS-S) TO WS-NUM
        PERFORM LSP-APPEND-NUM
        STRING " bytes" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    STRING '"}' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Paragraph or section WS-U, unless a name like it came before.
LSP-COMPLETION-UNIT.
    MOVE FU-NAME(WS-U) TO WS-LSP-SEEN-NAME
    PERFORM LSP-COMPLETION-SEEN
    IF WS-LSP-SEEN = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM LSP-COMPLETION-SEPARATOR
    STRING '{"label":"' DELIMITED BY SIZE
           FU-NAME(WS-U) DELIMITED BY SPACE
           '","kind":3,"detail":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF FU-KIND(WS-U) = "S"
        STRING 'section"}' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        STRING 'paragraph"}' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF.

*> WS-LSP-SEEN = "Y" when WS-LSP-SEEN-NAME was offered already; else
*> it is noted. The names offered are kept in buckets by a hash of the
*> name.
LSP-COMPLETION-SEEN.
    MOVE "N" TO WS-LSP-SEEN
    MOVE 0 TO WS-LSP-HASH
    PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > 31
        IF WS-LSP-SEEN-NAME(WS-K:1) = SPACE
            EXIT PERFORM
        END-IF
        COMPUTE WS-LSP-HASH = FUNCTION MOD(WS-LSP-HASH * 31
            + FUNCTION ORD(WS-LSP-SEEN-NAME(WS-K:1)), CS-BUCKETS)
    END-PERFORM
    ADD 1 TO WS-LSP-HASH
    MOVE WS-CS-HEAD(WS-LSP-HASH) TO WS-K
    PERFORM UNTIL WS-K = 0
        IF WS-CS-NAME(WS-K) = WS-LSP-SEEN-NAME
            MOVE "Y" TO WS-LSP-SEEN
            EXIT PARAGRAPH
        END-IF
        MOVE WS-CS-NEXT(WS-K) TO WS-K
    END-PERFORM
    IF WS-CS-COUNT < CS-MAX
        ADD 1 TO WS-CS-COUNT
        MOVE WS-LSP-SEEN-NAME TO WS-CS-NAME(WS-CS-COUNT)
        MOVE WS-CS-HEAD(WS-LSP-HASH) TO WS-CS-NEXT(WS-CS-COUNT)
        MOVE WS-CS-COUNT TO WS-CS-HEAD(WS-LSP-HASH)
    END-IF.

LSP-COMPLETION-SEPARATOR.
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST.

*> textDocument/inlayHint: after each data description entry of the
*> document, the item's size and offset in its record, as hover shows
*> them ("8 bytes at offset 17"; a table entry's size is that of one
*> occurrence). Condition names, constants, and items of unknown size
*> have none.
LSP-INLAY-HINTS.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        MOVE "Y" TO WS-LSP-FIRST
        PERFORM VARYING WS-S FROM 1 BY 1 UNTIL WS-S > SY-COUNT
            IF SY-SIZE(WS-S) > 0 AND SY-NODE(WS-S) > 0
               AND SY-LEVEL(WS-S) NOT = 88 AND SY-LEVEL(WS-S) NOT = 66
               AND SY-LEVEL(WS-S) NOT = 78
               AND WS-LSP-PTR < LSP-SIZE - 1024
                PERFORM LSP-APPEND-INLAY
            END-IF
        END-PERFORM
    END-IF
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> The hint for item WS-S, after the period that ends its own entry
*> (the node of a group, or of an item with condition names, also
*> spans the entries under it), when that is in the document.
LSP-APPEND-INLAY.
    MOVE SY-NAME-TOKEN(WS-S) TO WS-TOK
    IF WS-TOK = 0
        MOVE ND-TOK-FIRST(SY-NODE(WS-S)) TO WS-TOK
    END-IF
    PERFORM UNTIL WS-TOK >= ND-TOK-LAST(SY-NODE(WS-S))
                  OR TK-IS-PERIOD(WS-TOK)
        ADD 1 TO WS-TOK
    END-PERFORM
    IF WS-TOK = 0
        EXIT PARAGRAPH
    END-IF
    IF TK-FILE-ID(WS-TOK) NOT = 1 OR TK-SRC-LINE(WS-TOK) = 0
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    STRING '{"position":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = SL-LINE-NO(TK-SRC-LINE(WS-TOK)) - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"character":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = TK-COLUMN(WS-TOK) - 1 + TK-SPAN(WS-TOK)
    PERFORM LSP-APPEND-NUM
    STRING '},"label":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE SY-SIZE(WS-S) TO WS-NUM
    PERFORM LSP-APPEND-NUM
    IF SY-SIZE(WS-S) = 1
        STRING " byte at offset " DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        STRING " bytes at offset " DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE SY-OFFSET(WS-S) TO WS-NUM
    PERFORM LSP-APPEND-NUM
    STRING '","kind":1,"paddingLeft":true}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> textDocument/documentLink: the name of each copybook a COPY
*> statement of the document includes, linked to the copybook. The name
*> is the word after COPY on the same line.
LSP-DOCUMENT-LINKS.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        MOVE "Y" TO WS-LSP-FIRST
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IN-COUNT
            IF IN-PARENT(WS-I) = 0 AND IN-FROM-FILE-ID(WS-I) = 1
               AND IN-FROM-LINE(WS-I) > 0
               AND WS-LSP-PTR < LSP-SIZE - 2048
                PERFORM LSP-APPEND-LINK
            END-IF
        END-PERFORM
    END-IF
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> {"range":...,"target":"file://..."} for inclusion WS-I, when the
*> copybook's name follows COPY on its line.
LSP-APPEND-LINK.
    IF SF-LOADED(1) NOT = "Y"
       OR IN-FROM-LINE(WS-I) > SF-LINE-COUNT(1)
        EXIT PARAGRAPH
    END-IF
    COMPUTE WS-J = SF-FIRST-LINE(1) + IN-FROM-LINE(WS-I) - 1
    *> After the word COPY, past blanks: the name, to a blank or a
    *> period.
    COMPUTE WS-K = IN-FROM-COLUMN(WS-I) + 4
    PERFORM UNTIL WS-K > SL-TEXT-LEN(WS-J)
        IF SS-HEAP(SL-TEXT-OFF(WS-J) + WS-K - 1:1) NOT = SPACE
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-K
    END-PERFORM
    MOVE WS-K TO WS-LSP-CHAR
    PERFORM UNTIL WS-K > SL-TEXT-LEN(WS-J)
        IF SS-HEAP(SL-TEXT-OFF(WS-J) + WS-K - 1:1) = SPACE
           OR SS-HEAP(SL-TEXT-OFF(WS-J) + WS-K - 1:1) = "."
            EXIT PERFORM
        END-IF
        ADD 1 TO WS-K
    END-PERFORM
    IF WS-K = WS-LSP-CHAR
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    STRING '{"range":{"start":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = IN-FROM-LINE(WS-I) - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"character":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = WS-LSP-CHAR - 1
    PERFORM LSP-APPEND-NUM
    STRING '},"end":{"line":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = IN-FROM-LINE(WS-I) - 1
    PERFORM LSP-APPEND-NUM
    STRING ',"character":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-NUM = WS-K - 1
    PERFORM LSP-APPEND-NUM
    STRING '}},"target":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET IN-FILE-ID(WS-I)
        WS-PATH
    MOVE SPACES TO WS-LSP-TEXT-PATH
    STRING "file://" DELIMITED BY SIZE
           WS-PATH DELIMITED BY SPACE
        INTO WS-LSP-TEXT-PATH
    CALL "PLB-JSON-STRING" USING WS-LSP-TEXT-PATH WS-LSP-OUT WS-LSP-PTR
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> textDocument/codeLens: above each section and paragraph of the
*> document, how many PERFORM and GO TO statements name it (a PERFORM
*> ... THRU counts for its first procedure), or that none does; above
*> each record (01 or 77) declared in the document, how many references
*> read it or an item in it, give them values, or pass them to a CALL.
*> The lenses are plain text: their command does nothing.
LSP-CODE-LENSES.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        MOVE "Y" TO WS-LSP-FIRST
        PERFORM VARYING WS-U FROM 1 BY 1 UNTIL WS-U > FU-COUNT
            IF FU-KIND(WS-U) = "P" OR FU-KIND(WS-U) = "S"
                PERFORM LSP-APPEND-LENS
            END-IF
        END-PERFORM
        PERFORM LSP-RECORD-USES
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > SY-COUNT
            IF SY-PARENT(WS-I) = 0 AND SY-NAME-TOKEN(WS-I) > 0
               AND SY-CATEGORY(WS-I) NOT = "C"
                PERFORM LSP-APPEND-RECORD-LENS
            END-IF
        END-PERFORM
    END-IF
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> {"range":...,"command":{"title":"...","command":""}} for unit WS-U,
*> when its name is in the document.
LSP-APPEND-LENS.
    MOVE ND-NAME(FU-NODE(WS-U)) TO WS-LSP-TOKEN
    IF WS-LSP-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    IF TK-FILE-ID(WS-LSP-TOKEN) NOT = 1
       OR TK-SRC-LINE(WS-LSP-TOKEN) = 0
       OR WS-LSP-PTR > LSP-SIZE - 1024
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO WS-LSP-PERFORMS WS-LSP-GOTOS
    PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > FE-COUNT
        IF FE-TO(WS-J) = WS-U
            EVALUATE FE-KIND(WS-J)
                WHEN "P" ADD 1 TO WS-LSP-PERFORMS
                WHEN "G" ADD 1 TO WS-LSP-GOTOS
            END-EVALUATE
        END-IF
    END-PERFORM
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-LSP-TOKEN)) TO WS-LSP-LINE
    MOVE TK-COLUMN(WS-LSP-TOKEN) TO WS-LSP-CHAR
    STRING '{"range":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-RANGE
    STRING ',"command":{"title":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    EVALUATE TRUE
        WHEN WS-LSP-PERFORMS = 0 AND WS-LSP-GOTOS = 0
            STRING "no PERFORM or GO TO" DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        WHEN OTHER
            IF WS-LSP-PERFORMS > 0
                MOVE WS-LSP-PERFORMS TO WS-NUM
                PERFORM LSP-APPEND-NUM
                STRING " PERFORM" DELIMITED BY SIZE
                    INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            END-IF
            IF WS-LSP-PERFORMS > 0 AND WS-LSP-GOTOS > 0
                STRING ", " DELIMITED BY SIZE
                    INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            END-IF
            IF WS-LSP-GOTOS > 0
                MOVE WS-LSP-GOTOS TO WS-NUM
                PERFORM LSP-APPEND-NUM
                STRING " GO TO" DELIMITED BY SIZE
                    INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            END-IF
    END-EVALUATE
    STRING '","command":""}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> For each record, the references to it or an item in it, by what
*> they do: WS-LENS-READS, WS-LENS-WRITES, and WS-LENS-PASSED (a CALL
*> BY REFERENCE, which may do either). Each reference is counted for
*> the record it is in, found by going up from its item.
LSP-RECORD-USES.
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > SY-COUNT
        MOVE 0 TO WS-LENS-READS(WS-I) WS-LENS-WRITES(WS-I)
            WS-LENS-PASSED(WS-I)
    END-PERFORM
    PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > RF-COUNT
        IF RF-KIND(WS-J) = "D" AND RF-SYMBOL(WS-J) > 0
            MOVE RF-SYMBOL(WS-J) TO WS-K
            PERFORM UNTIL SY-PARENT(WS-K) = 0
                MOVE SY-PARENT(WS-K) TO WS-K
            END-PERFORM
            EVALUATE RF-ROLE(WS-J)
                WHEN "U"
                    ADD 1 TO WS-LENS-READS(WS-K)
                WHEN "D"
                    ADD 1 TO WS-LENS-WRITES(WS-K)
                WHEN "B"
                    ADD 1 TO WS-LENS-READS(WS-K) WS-LENS-WRITES(WS-K)
                WHEN "X"
                    ADD 1 TO WS-LENS-PASSED(WS-K)
            END-EVALUATE
        END-IF
    END-PERFORM.

*> The lens of record WS-I, when its name is in the document:
*> "2 reads, 1 write, 1 CALL", or "never referenced".
LSP-APPEND-RECORD-LENS.
    MOVE SY-NAME-TOKEN(WS-I) TO WS-LSP-TOKEN
    IF TK-FILE-ID(WS-LSP-TOKEN) NOT = 1
       OR TK-SRC-LINE(WS-LSP-TOKEN) = 0
       OR WS-LSP-PTR > LSP-SIZE - 1024
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-LSP-TOKEN)) TO WS-LSP-LINE
    MOVE TK-COLUMN(WS-LSP-TOKEN) TO WS-LSP-CHAR
    STRING '{"range":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-RANGE
    STRING ',"command":{"title":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LENS-READS(WS-I) = 0 AND WS-LENS-WRITES(WS-I) = 0
       AND WS-LENS-PASSED(WS-I) = 0
        STRING "never referenced" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        MOVE "Y" TO WS-LENS-FIRST
        MOVE WS-LENS-READS(WS-I) TO WS-NUM
        MOVE "read" TO WS-LENS-WORD
        PERFORM LSP-APPEND-LENS-COUNT
        MOVE WS-LENS-WRITES(WS-I) TO WS-NUM
        MOVE "write" TO WS-LENS-WORD
        PERFORM LSP-APPEND-LENS-COUNT
        MOVE WS-LENS-PASSED(WS-I) TO WS-NUM
        MOVE "CALL" TO WS-LENS-WORD
        PERFORM LSP-APPEND-LENS-COUNT
    END-IF
    STRING '","command":""}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> ", N words" (no comma first; nothing for 0; no s for 1).
LSP-APPEND-LENS-COUNT.
    IF WS-NUM = 0
        EXIT PARAGRAPH
    END-IF
    IF WS-LENS-FIRST = "N"
        STRING ", " DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LENS-FIRST
    PERFORM LSP-APPEND-NUM
    STRING " " DELIMITED BY SIZE
           WS-LENS-WORD DELIMITED BY SPACE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-NUM > 1
        STRING "s" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF.

*> Renaming ---------------------------------------------------------

*> textDocument/prepareRename: the range of the name at the position
*> when it names a data item or procedure, else null.
LSP-PREPARE-RENAME.
    PERFORM LSP-POSITION
    PERFORM LSP-TARGET
    PERFORM LSP-START-RESPONSE
    STRING '"result":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-SYMBOL = 0 AND WS-LSP-UNIT = 0
        STRING "null" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    ELSE
        MOVE SL-LINE-NO(TK-SRC-LINE(WS-LSP-TOKEN)) TO WS-LSP-LINE
        MOVE TK-COLUMN(WS-LSP-TOKEN) TO WS-LSP-CHAR
        PERFORM LSP-APPEND-RANGE
    END-IF
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> textDocument/rename: a workspace edit that changes the declaration
*> and every reference, in the document and its copybooks. Names that
*> come from COPY REPLACING are not where the old name is written, and
*> are left alone; the new name must be a user-defined word.
LSP-RENAME.
    MOVE "newName" TO WS-LSP-NAME
    PERFORM LSP-GET
    MOVE SPACES TO WS-LSP-NEW-NAME
    MOVE 0 TO WS-LSP-NEW-LEN
    IF WS-LSP-VALUE-LEN >= 1 AND WS-LSP-VALUE-LEN <= 31
        MOVE WS-LSP-VALUE-LEN TO WS-LSP-NEW-LEN
        MOVE WS-LSP-VALUE(1:WS-LSP-NEW-LEN) TO WS-LSP-NEW-NAME
    END-IF
    PERFORM LSP-CHECK-NEW-NAME
    IF WS-LSP-NEW-LEN = 0
        PERFORM LSP-START-RESPONSE
        STRING '"error":{"code":-32602,"message":"not a COBOL '
               'user-defined word"}}' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        PERFORM LSP-SEND-OUT
        EXIT PARAGRAPH
    END-IF
    PERFORM LSP-POSITION
    PERFORM LSP-TARGET
    PERFORM LSP-START-RESPONSE
    STRING '"result":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-SYMBOL = 0 AND WS-LSP-UNIT = 0
        STRING "null}" DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        PERFORM LSP-SEND-OUT
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-SYMBOL > 0
        MOVE SY-NAME(WS-LSP-SYMBOL) TO WS-LSP-OLD-NAME
    ELSE
        MOVE FU-NAME(WS-LSP-UNIT) TO WS-LSP-OLD-NAME
    END-IF
    MOVE FUNCTION UPPER-CASE(WS-LSP-OLD-NAME) TO WS-LSP-OLD-NAME
    MOVE "R" TO WS-LSP-HIGHLIGHT
    MOVE "Y" TO WS-LSP-DECLARATION
    MOVE 0 TO WS-LSP-EDIT-COUNT
    PERFORM LSP-COLLECT-REFERENCES
    *> {"changes":{URI:[edits], ...}}, one key per file.
    STRING '{"changes":{' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-LSP-FIRST
    PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > WS-LSP-EDIT-COUNT
        IF WS-LSP-EDIT-DONE(WS-J) = "N"
            PERFORM LSP-APPEND-FILE-EDITS
        END-IF
    END-PERFORM
    STRING "}}}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> WS-LSP-NEW-LEN = 0 unless WS-LSP-NEW-NAME is a user-defined word:
*> letters, digits, hyphens, and underscores, with a letter, no hyphen
*> at either end, and not a reserved word. Its case is kept.
LSP-CHECK-NEW-NAME.
    IF WS-LSP-NEW-LEN = 0
        EXIT PARAGRAPH
    END-IF
    MOVE FUNCTION UPPER-CASE(WS-LSP-NEW-NAME) TO WS-LSP-UPPER-NAME
    MOVE 0 TO WS-K
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > WS-LSP-NEW-LEN
        EVALUATE WS-LSP-UPPER-NAME(WS-C:1)
            WHEN "A" THRU "Z"
                ADD 1 TO WS-K
            WHEN "0" THRU "9"
            WHEN "-"
            WHEN "_"
                CONTINUE
            WHEN OTHER
                MOVE 0 TO WS-LSP-NEW-LEN
                EXIT PARAGRAPH
        END-EVALUATE
    END-PERFORM
    IF WS-K = 0 OR WS-LSP-NEW-NAME(1:1) = "-"
       OR WS-LSP-NEW-NAME(WS-LSP-NEW-LEN:1) = "-"
        MOVE 0 TO WS-LSP-NEW-LEN
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-KW-LOOKUP" USING WS-LSP-UPPER-NAME WS-LSP-WORD-KIND
    IF WS-LSP-WORD-KIND NOT = SPACE
        MOVE 0 TO WS-LSP-NEW-LEN
    END-IF.

*> Keep token WS-LSP-TOKEN for the rename when the old name is written
*> there, once.
LSP-ADD-EDIT.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-LSP-TOKEN WS-LSP-NAME
        WS-TOKEN-LEN
    IF FUNCTION UPPER-CASE(WS-LSP-NAME) NOT = WS-LSP-OLD-NAME
       OR TK-SPAN(WS-LSP-TOKEN) NOT = WS-TOKEN-LEN
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > WS-LSP-EDIT-COUNT
        IF TK-FILE-ID(WS-LSP-EDIT-TOKEN(WS-K)) = TK-FILE-ID(WS-LSP-TOKEN)
           AND TK-SRC-LINE(WS-LSP-EDIT-TOKEN(WS-K))
               = TK-SRC-LINE(WS-LSP-TOKEN)
           AND TK-COLUMN(WS-LSP-EDIT-TOKEN(WS-K)) = TK-COLUMN(WS-LSP-TOKEN)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    IF WS-LSP-EDIT-COUNT < LSP-EDIT-MAX
        ADD 1 TO WS-LSP-EDIT-COUNT
        MOVE WS-LSP-TOKEN TO WS-LSP-EDIT-TOKEN(WS-LSP-EDIT-COUNT)
        MOVE "N" TO WS-LSP-EDIT-DONE(WS-LSP-EDIT-COUNT)
    END-IF.

*> "URI":[edits] for the file of edit WS-J and the later edits in it.
LSP-APPEND-FILE-EDITS.
    IF WS-LSP-PTR > LSP-SIZE - 4096
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    MOVE WS-LSP-EDIT-TOKEN(WS-J) TO WS-LSP-TOKEN
    IF TK-FILE-ID(WS-LSP-TOKEN) = 1
        CALL "PLB-JSON-STRING" USING DOC-URI(WS-LSP-DOC-INDEX) WS-LSP-OUT
            WS-LSP-PTR
    ELSE
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET
            TK-FILE-ID(WS-LSP-TOKEN) WS-PATH
        MOVE SPACES TO WS-LSP-TEXT-PATH
        STRING "file://" DELIMITED BY SIZE
               WS-PATH DELIMITED BY SPACE
            INTO WS-LSP-TEXT-PATH
        CALL "PLB-JSON-STRING" USING WS-LSP-TEXT-PATH WS-LSP-OUT
            WS-LSP-PTR
    END-IF
    STRING ":[" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM VARYING WS-K FROM WS-J BY 1 UNTIL WS-K > WS-LSP-EDIT-COUNT
        IF WS-LSP-EDIT-DONE(WS-K) = "N"
           AND TK-FILE-ID(WS-LSP-EDIT-TOKEN(WS-K))
               = TK-FILE-ID(WS-LSP-EDIT-TOKEN(WS-J))
           AND WS-LSP-PTR <= LSP-SIZE - 2048
            IF WS-K > WS-J
                STRING "," DELIMITED BY SIZE
                    INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            END-IF
            MOVE "Y" TO WS-LSP-EDIT-DONE(WS-K)
            MOVE WS-LSP-EDIT-TOKEN(WS-K) TO WS-LSP-TOKEN
            MOVE SL-LINE-NO(TK-SRC-LINE(WS-LSP-TOKEN)) TO WS-LSP-LINE
            MOVE TK-COLUMN(WS-LSP-TOKEN) TO WS-LSP-CHAR
            STRING '{"range":' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
            PERFORM LSP-APPEND-RANGE
            STRING ',"newText":"' DELIMITED BY SIZE
                   WS-LSP-NEW-NAME(1:WS-LSP-NEW-LEN) DELIMITED BY SIZE
                   '"}' DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
    END-PERFORM
    STRING "]" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Hover over a data item: its level, name, picture, usage, size, and
*> place in its record.
LSP-HOVER.
    PERFORM LSP-POSITION
    PERFORM LSP-TARGET
    PERFORM LSP-START-RESPONSE
    STRING '"result":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    IF WS-LSP-SYMBOL = 0 AND WS-LSP-UNIT > 0
        PERFORM LSP-HOVER-UNIT
        EXIT PARAGRAPH
    END-IF
    IF WS-LSP-SYMBOL = 0
        PERFORM LSP-HOVER-CALL
        IF WS-FOUND = "N"
            PERFORM LSP-HOVER-SQL-TABLE
        END-IF
        IF WS-FOUND = "N"
            STRING "null}" DELIMITED BY SIZE
                INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        END-IF
        PERFORM LSP-SEND-OUT
        EXIT PARAGRAPH
    END-IF
    MOVE WS-LSP-SYMBOL TO WS-S
    IF SY-LEVEL(WS-S) = 88 AND SY-PARENT(WS-S) > 0
        PERFORM LSP-HOVER-CONDITION
        PERFORM LSP-SEND-OUT
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO WS-LSP-PIC
    MOVE ND-FIRST(SY-NODE(WS-S)) TO WS-NODE
    PERFORM UNTIL WS-NODE = 0
        IF ND-KIND(WS-NODE) = "CLAU" AND ND-DETAIL(WS-NODE) = "PICTURE"
           AND ND-NAME(WS-NODE) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(WS-NODE)
                WS-LSP-PIC WS-TOKEN-LEN
        END-IF
        MOVE ND-NEXT(WS-NODE) TO WS-NODE
    END-PERFORM
    MOVE SPACES TO WS-LSP-TEXT-PATH
    MOVE 1 TO WS-PTR
    MOVE SY-LEVEL(WS-S) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING "```cobol\n" DELIMITED BY SIZE
           WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
           " " DELIMITED BY SIZE
           SY-NAME(WS-S) DELIMITED BY SPACE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    IF WS-LSP-PIC NOT = SPACES
        STRING " PIC " DELIMITED BY SIZE
               WS-LSP-PIC DELIMITED BY SPACE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    IF SY-USAGE(WS-S) NOT = SPACES
        STRING " " DELIMITED BY SIZE
               SY-USAGE(WS-S) DELIMITED BY SPACE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    STRING "\n```\n" DELIMITED BY SIZE INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    MOVE SY-SIZE(WS-S) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
           " bytes at offset " DELIMITED BY SIZE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    MOVE SY-OFFSET(WS-S) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    *> The record it is in.
    MOVE WS-S TO WS-P
    PERFORM UNTIL SY-PARENT(WS-P) = 0
        MOVE SY-PARENT(WS-P) TO WS-P
    END-PERFORM
    IF WS-P NOT = WS-S
        STRING " of " DELIMITED BY SIZE
               SY-NAME(WS-P) DELIMITED BY SPACE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    IF SY-OCCURS(WS-S) > 0
        MOVE SY-OCCURS(WS-S) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING ", occurs " DELIMITED BY SIZE
               WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
               " times" DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    PERFORM LSP-HOVER-SQL-COLUMN
    STRING '{"contents":{"kind":"markdown","value":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    *> Already JSON-safe: names, pictures, numbers, and \n escapes.
    COMPUTE WS-LEN = WS-PTR - 1
    STRING WS-LSP-TEXT-PATH(1:WS-LEN) DELIMITED BY SIZE
           '"}}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> Hover over a condition name (symbol WS-S, level 88): its VALUE clause
*> as written, and the item it tests:
*>     ```cobol
*>     88 STATUS-OPEN VALUE "O" "R".
*>     ```
*>     Condition of `ACCOUNT-STATUS` (`PIC X`).
LSP-HOVER-CONDITION.
    MOVE SPACES TO WS-LSP-HOVER
    MOVE 1 TO WS-PTR
    *> Real line ends: PLB-JSON-STRING escapes the text below.
    STRING "```cobol" X"0A" "88 " DELIMITED BY SIZE
           SY-NAME(WS-S) DELIMITED BY SPACE
        INTO WS-LSP-HOVER WITH POINTER WS-PTR
    MOVE ND-FIRST(SY-NODE(WS-S)) TO WS-NODE
    PERFORM UNTIL WS-NODE = 0
        IF ND-KIND(WS-NODE) = "CLAU" AND ND-DETAIL(WS-NODE) = "VALUE"
            PERFORM VARYING WS-TOK FROM ND-TOK-FIRST(WS-NODE) BY 1
                    UNTIL WS-TOK > ND-TOK-LAST(WS-NODE)
                    OR WS-PTR > LENGTH OF WS-LSP-HOVER - 300
                PERFORM LSP-APPEND-HOVER-TOKEN
            END-PERFORM
        END-IF
        MOVE ND-NEXT(WS-NODE) TO WS-NODE
    END-PERFORM
    MOVE SY-PARENT(WS-S) TO WS-P
    MOVE SPACES TO WS-LSP-PIC
    MOVE ND-FIRST(SY-NODE(WS-P)) TO WS-NODE
    PERFORM UNTIL WS-NODE = 0
        IF ND-KIND(WS-NODE) = "CLAU" AND ND-DETAIL(WS-NODE) = "PICTURE"
           AND ND-NAME(WS-NODE) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(WS-NODE)
                WS-LSP-PIC WS-TOKEN-LEN
        END-IF
        MOVE ND-NEXT(WS-NODE) TO WS-NODE
    END-PERFORM
    STRING "." X"0A" "```" X"0A" "Condition of `" DELIMITED BY SIZE
           SY-NAME(WS-P) DELIMITED BY SPACE
           "`" DELIMITED BY SIZE
        INTO WS-LSP-HOVER WITH POINTER WS-PTR
    IF WS-LSP-PIC NOT = SPACES
        STRING " (`PIC " DELIMITED BY SIZE
               WS-LSP-PIC DELIMITED BY SPACE
               "`)" DELIMITED BY SIZE
            INTO WS-LSP-HOVER WITH POINTER WS-PTR
    END-IF
    STRING "." DELIMITED BY SIZE INTO WS-LSP-HOVER WITH POINTER WS-PTR
    STRING '{"contents":{"kind":"markdown","value":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-LEN = WS-PTR - 1
    MOVE WS-LSP-HOVER(1:WS-LEN) TO WS-CALL-HOVER
    CALL "PLB-JSON-STRING" USING WS-CALL-HOVER WS-LSP-OUT WS-LSP-PTR
    STRING '}}}' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Token WS-TOK after a space, as written: an alphanumeric literal in
*> quotes, with its prefix and its quotes doubled.
LSP-APPEND-HOVER-TOKEN.
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-TOK WS-LSP-WORD WS-TOKEN-LEN
    STRING " " DELIMITED BY SIZE INTO WS-LSP-HOVER WITH POINTER WS-PTR
    IF NOT TK-IS-ALNUM(WS-TOK)
        IF WS-TOKEN-LEN > 0
            STRING WS-LSP-WORD(1:WS-TOKEN-LEN) DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF TK-PREFIX(WS-TOK) NOT = SPACES
        STRING TK-PREFIX(WS-TOK) DELIMITED BY SPACE
            INTO WS-LSP-HOVER WITH POINTER WS-PTR
    END-IF
    STRING '"' DELIMITED BY SIZE INTO WS-LSP-HOVER WITH POINTER WS-PTR
    PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > WS-TOKEN-LEN
        IF WS-LSP-WORD(WS-K:1) = '"'
            STRING '""' DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
        ELSE
            STRING WS-LSP-WORD(WS-K:1) DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
        END-IF
    END-PERFORM
    STRING '"' DELIMITED BY SIZE INTO WS-LSP-HOVER WITH POINTER WS-PTR.

*> Hover over a paragraph or section name (unit WS-LSP-UNIT): its
*> size and complexity from the metrics, the PERFORM and GO TO
*> statements naming it, and whether it can run at all.
*> A host variable of embedded SQL: the column it is paired with.
*>     Column `ACCT_ID` DECIMAL(11), not null: fetched into this item.
LSP-HOVER-SQL-COLUMN.
    CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-SQL-MODEL
    PERFORM VARYING WS-SQL-S FROM 1 BY 1 UNTIL WS-SQL-S > QS-COUNT
        PERFORM VARYING WS-SQL-P FROM QS-PAIR-FIRST(WS-SQL-S) BY 1
                UNTIL WS-SQL-P >=
                      QS-PAIR-FIRST(WS-SQL-S) + QS-PAIR-COUNT(WS-SQL-S)
            IF QP-HOST-TOKEN(WS-SQL-P) = WS-LSP-TOKEN
                CALL "PLB-SQL-FIND-COLUMN" USING PLB-SQL-MODEL WS-SQL-S
                    WS-SQL-P WS-SQL-C
                IF WS-SQL-C > 0
                    PERFORM LSP-APPEND-SQL-COLUMN
                    EXIT PARAGRAPH
                END-IF
            END-IF
        END-PERFORM
    END-PERFORM.

*> A table name in embedded SQL, where a statement uses it or DECLARE
*> TABLE declares it: the table's columns, from the declaration.
*>     Table `ACCOUNT`, 3 columns:
*>     | ACCT_ID | CHAR(8) | not null |
*> WS-FOUND = "Y" when the hover was written.
LSP-HOVER-SQL-TABLE.
    MOVE "N" TO WS-FOUND
    IF WS-LSP-TOKEN = 0
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-WORD(WS-LSP-TOKEN)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
        PLB-SQL-MODEL
    *> Inside an SQL statement of the model, or the declaration itself.
    MOVE "N" TO WS-LSP-SEEN
    PERFORM VARYING WS-SQL-S FROM 1 BY 1 UNTIL WS-SQL-S > QS-COUNT
        IF QS-TOKEN(WS-SQL-S) <= WS-LSP-TOKEN
           AND QS-END(WS-SQL-S) >= WS-LSP-TOKEN
            MOVE "Y" TO WS-LSP-SEEN
            EXIT PERFORM
        END-IF
    END-PERFORM
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-LSP-TOKEN WS-LSP-NAME
        WS-TOKEN-LEN
    MOVE FUNCTION UPPER-CASE(WS-LSP-NAME) TO WS-LSP-NAME
    MOVE 0 TO WS-SQL-C
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > QT-COUNT
        *> QT-TOKEN is the EXEC of EXEC SQL DECLARE [qualifier.]name.
        IF QT-SHORT(WS-I) = WS-LSP-NAME
           AND (WS-LSP-SEEN = "Y"
                OR (WS-LSP-TOKEN > QT-TOKEN(WS-I)
                    AND WS-LSP-TOKEN <= QT-TOKEN(WS-I) + 5))
            MOVE WS-I TO WS-SQL-C
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF WS-SQL-C = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO WS-LSP-HOVER
    MOVE 1 TO WS-PTR
    MOVE QT-COL-COUNT(WS-SQL-C) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING "Table `" DELIMITED BY SIZE
           QT-NAME(WS-SQL-C) DELIMITED BY SPACE
           "`, " WS-NUM-TEXT(1:WS-NUM-LEN) " columns:\n\n"
           "| Column | Type | |\n|---|---|---|" DELIMITED BY SIZE
        INTO WS-LSP-HOVER WITH POINTER WS-PTR
    PERFORM VARYING WS-J FROM QT-COL-FIRST(WS-SQL-C) BY 1
            UNTIL WS-J >= QT-COL-FIRST(WS-SQL-C) + QT-COL-COUNT(WS-SQL-C)
               OR WS-PTR > 3900
        STRING "\n| " DELIMITED BY SIZE
               QL-NAME(WS-J) DELIMITED BY SPACE
               " | " DELIMITED BY SIZE
               QL-TYPE(WS-J) DELIMITED BY SPACE
            INTO WS-LSP-HOVER WITH POINTER WS-PTR
        IF QL-LENGTH(WS-J) > 0
            MOVE QL-LENGTH(WS-J) TO WS-NUM
            CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
            STRING "(" WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
            IF QL-SCALE(WS-J) > 0
                MOVE QL-SCALE(WS-J) TO WS-NUM
                CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT
                    WS-NUM-LEN
                STRING "," WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
                    INTO WS-LSP-HOVER WITH POINTER WS-PTR
            END-IF
            STRING ")" DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
        END-IF
        IF QL-NULLS(WS-J) = "N"
            STRING " | not null |" DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
        ELSE
            STRING " | |" DELIMITED BY SIZE
                INTO WS-LSP-HOVER WITH POINTER WS-PTR
        END-IF
    END-PERFORM
    STRING '{"contents":{"kind":"markdown","value":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    *> Already JSON-safe: names, types, numbers, and \n escapes.
    COMPUTE WS-LEN = WS-PTR - 1
    STRING WS-LSP-HOVER(1:WS-LEN) DELIMITED BY SIZE
           '"}}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-FOUND.

LSP-APPEND-SQL-COLUMN.
    STRING "\n\nColumn `" DELIMITED BY SIZE
           QL-NAME(WS-SQL-C) DELIMITED BY SPACE
           "` " DELIMITED BY SIZE
           QL-TYPE(WS-SQL-C) DELIMITED BY SPACE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    IF QL-LENGTH(WS-SQL-C) > 0
        MOVE QL-LENGTH(WS-SQL-C) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING "(" WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
        IF QL-SCALE(WS-SQL-C) > 0
            MOVE QL-SCALE(WS-SQL-C) TO WS-NUM
            CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
            STRING "," WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
                INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
        END-IF
        STRING ")" DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    IF QL-NULLS(WS-SQL-C) = "N"
        STRING ", not null" DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    IF QS-KIND(WS-SQL-S) = "S" OR QS-KIND(WS-SQL-S) = "F"
        STRING ": fetched into this item." DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    ELSE
        STRING ": stored from this item." DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF.

LSP-HOVER-UNIT.
    CALL "PLB-METRICS-COMPUTE" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
        PLB-SYMBOLS PLB-FLOW PLB-METRICS
    MOVE 0 TO WS-M
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > MU-COUNT
        IF MU-UNIT(WS-I) = WS-LSP-UNIT
            MOVE WS-I TO WS-M
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE SPACES TO WS-LSP-TEXT-PATH
    MOVE 1 TO WS-PTR
    STRING "```cobol\n" DELIMITED BY SIZE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    IF FU-KIND(WS-LSP-UNIT) = "S"
        STRING "section " DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    ELSE
        STRING "paragraph " DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    STRING FU-NAME(WS-LSP-UNIT) DELIMITED BY SPACE
           "\n```\n" DELIMITED BY SIZE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    IF WS-M > 0
        MOVE MU-LINES(WS-M) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING WS-NUM-TEXT(1:WS-NUM-LEN) " lines, " DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
        MOVE MU-STATEMENTS(WS-M) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING WS-NUM-TEXT(1:WS-NUM-LEN) " statements, complexity "
            DELIMITED BY SIZE INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
        MOVE MU-COMPLEXITY(WS-M) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING WS-NUM-TEXT(1:WS-NUM-LEN) ". " DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    MOVE 0 TO WS-LSP-PERFORMS WS-LSP-GOTOS
    PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > FE-COUNT
        IF FE-TO(WS-J) = WS-LSP-UNIT
            EVALUATE FE-KIND(WS-J)
                WHEN "P" ADD 1 TO WS-LSP-PERFORMS
                WHEN "G" ADD 1 TO WS-LSP-GOTOS
            END-EVALUATE
        END-IF
    END-PERFORM
    MOVE WS-LSP-PERFORMS TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) " PERFORM, " DELIMITED BY SIZE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    MOVE WS-LSP-GOTOS TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) " GO TO." DELIMITED BY SIZE
        INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    IF FU-REACHED(WS-LSP-UNIT) NOT = "Y"
        STRING " It never runs." DELIMITED BY SIZE
            INTO WS-LSP-TEXT-PATH WITH POINTER WS-PTR
    END-IF
    STRING '{"contents":{"kind":"markdown","value":"' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    COMPUTE WS-LEN = WS-PTR - 1
    STRING WS-LSP-TEXT-PATH(1:WS-LEN) DELIMITED BY SIZE
           '"}}}' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> Outline ------------------------------------------------------------

*> textDocument/documentSymbol: programs, sections, paragraphs, and
*> named data items of the document (not of its copybooks), as a flat
*> list with container names.
LSP-DOCUMENT-SYMBOLS.
    PERFORM LSP-FIND-DOCUMENT
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE SPACES TO WS-LSP-QUERY
    MOVE "Y" TO WS-LSP-FIRST
    IF WS-LSP-DOC-INDEX > 0
        PERFORM LSP-ANALYZE
        PERFORM LSP-COLLECT-SYMBOLS
    END-IF
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> workspace/symbol: the symbols of every open document whose names
*> contain the query, ignoring case.
LSP-WORKSPACE-SYMBOLS.
    MOVE "query" TO WS-LSP-NAME
    PERFORM LSP-GET
    MOVE SPACES TO WS-LSP-QUERY
    IF WS-LSP-KIND = "S" AND WS-LSP-VALUE-LEN > 0
       AND WS-LSP-VALUE-LEN <= 31
        MOVE FUNCTION UPPER-CASE(WS-LSP-VALUE(1:WS-LSP-VALUE-LEN))
            TO WS-LSP-QUERY
    END-IF
    PERFORM LSP-START-RESPONSE
    STRING '"result":[' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE "Y" TO WS-LSP-FIRST
    PERFORM VARYING WS-LSP-SLOT FROM 1 BY 1 UNTIL WS-LSP-SLOT > LSP-DOC-MAX
        IF DOC-URI(WS-LSP-SLOT) NOT = SPACES
            MOVE WS-LSP-SLOT TO WS-LSP-DOC-INDEX
            PERFORM LSP-ANALYZE
            PERFORM LSP-COLLECT-SYMBOLS
        END-IF
    END-PERFORM
    STRING "]}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-SEND-OUT.

*> LSP-APPEND-SYMBOL for the programs, sections, paragraphs, and named
*> data items of the analyzed document.
LSP-COLLECT-SYMBOLS.
    MOVE 1 TO WS-ROOT WS-NODE
    MOVE 0 TO WS-DEPTH
    PERFORM UNTIL WS-NODE = 0
        IF ND-KIND(WS-NODE) = "PROG" AND ND-NAME(WS-NODE) > 0
            MOVE ND-NAME(WS-NODE) TO WS-LSP-TOKEN
            MOVE 2 TO WS-LSP-KIND-NUM
            MOVE SPACES TO WS-LSP-NAME
            PERFORM LSP-APPEND-SYMBOL
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST WS-ROOT WS-NODE WS-DEPTH
    END-PERFORM
    PERFORM VARYING WS-U FROM 1 BY 1 UNTIL WS-U > FU-COUNT
        IF FU-KIND(WS-U) NOT = "D" AND ND-NAME(FU-NODE(WS-U)) > 0
            MOVE ND-NAME(FU-NODE(WS-U)) TO WS-LSP-TOKEN
            IF FU-KIND(WS-U) = "S"
                MOVE 3 TO WS-LSP-KIND-NUM
            ELSE
                MOVE 6 TO WS-LSP-KIND-NUM
            END-IF
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS
                ND-NAME(FU-PROGRAM(WS-U)) WS-LSP-NAME WS-TOKEN-LEN
            IF FU-SECTION(WS-U) > 0
                MOVE FU-NAME(FU-SECTION(WS-U)) TO WS-LSP-NAME
            END-IF
            PERFORM LSP-APPEND-SYMBOL
        END-IF
    END-PERFORM
    PERFORM VARYING WS-S FROM 1 BY 1 UNTIL WS-S > SY-COUNT
        IF SY-NAME-TOKEN(WS-S) > 0
            MOVE SY-NAME-TOKEN(WS-S) TO WS-LSP-TOKEN
            EVALUATE TRUE
                WHEN SY-LEVEL(WS-S) = 88
                    MOVE 22 TO WS-LSP-KIND-NUM
                WHEN SY-LEVEL(WS-S) = 78
                    MOVE 14 TO WS-LSP-KIND-NUM
                WHEN SY-CATEGORY(WS-S) = "G"
                    MOVE 23 TO WS-LSP-KIND-NUM
                WHEN SY-PARENT(WS-S) > 0
                    MOVE 8 TO WS-LSP-KIND-NUM
                WHEN OTHER
                    MOVE 13 TO WS-LSP-KIND-NUM
            END-EVALUATE
            IF SY-PARENT(WS-S) > 0
                MOVE SY-NAME(SY-PARENT(WS-S)) TO WS-LSP-NAME
            ELSE
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS
                    ND-NAME(SY-PROGRAM(WS-S)) WS-LSP-NAME WS-TOKEN-LEN
            END-IF
            PERFORM LSP-APPEND-SYMBOL
        END-IF
    END-PERFORM.

*> A SymbolInformation for the name at WS-LSP-TOKEN, of kind
*> WS-LSP-KIND-NUM, in container WS-LSP-NAME; only for names in the
*> document itself, and that contain WS-LSP-QUERY when it is set.
LSP-APPEND-SYMBOL.
    IF TK-FILE-ID(WS-LSP-TOKEN) NOT = 1
       OR WS-LSP-PTR > LSP-SIZE - 4096
        EXIT PARAGRAPH
    END-IF
    *> workspace/symbol: only names that contain the query.
    IF WS-LSP-QUERY NOT = SPACES
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-LSP-TOKEN WS-TOKEN-TEXT
            WS-TOKEN-LEN
        MOVE 0 TO WS-K
        INSPECT FUNCTION UPPER-CASE(WS-TOKEN-TEXT(1:WS-TOKEN-LEN))
            TALLYING WS-K FOR ALL FUNCTION TRIM(WS-LSP-QUERY)
        IF WS-K = 0
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF WS-LSP-FIRST = "N"
        STRING "," DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    END-IF
    MOVE "N" TO WS-LSP-FIRST
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-LSP-TOKEN WS-TOKEN-TEXT
        WS-TOKEN-LEN
    STRING '{"name":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    CALL "PLB-JSON-STRING" USING WS-TOKEN-TEXT(1:WS-TOKEN-LEN) WS-LSP-OUT
        WS-LSP-PTR
    STRING ',"kind":' DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    MOVE WS-LSP-KIND-NUM TO WS-NUM
    PERFORM LSP-APPEND-NUM
    IF WS-LSP-NAME NOT = SPACES
        STRING ',"containerName":' DELIMITED BY SIZE
            INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
        CALL "PLB-JSON-STRING" USING WS-LSP-NAME WS-LSP-OUT WS-LSP-PTR
    END-IF
    STRING ',"location":' DELIMITED BY SIZE
        INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR
    PERFORM LSP-APPEND-LOCATION
    STRING "}" DELIMITED BY SIZE INTO WS-LSP-OUT WITH POINTER WS-LSP-PTR.

*> Findings at or above the --fail-on level.
COUNT-FAILING.
    MOVE 0 TO WS-FAILING
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > FN-COUNT
        IF FN-SUPPRESSED(WS-I) = "N"
            EVALUATE TRUE
                WHEN WS-FAIL-ON = "-"
                    CONTINUE
                WHEN FN-SEVERITY(WS-I) = "E"
                    ADD 1 TO WS-FAILING
                WHEN FN-SEVERITY(WS-I) = "W" AND WS-FAIL-ON NOT = "E"
                    ADD 1 TO WS-FAILING
                WHEN FN-SEVERITY(WS-I) = "N" AND WS-FAIL-ON = "N"
                    ADD 1 TO WS-FAILING
            END-EVALUATE
        END-IF
    END-PERFORM.

*> Expand, parse, and model file WS-FILE-ID.
ANALYZE-FILE.
    CALL "PLB-PP-RUN" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-PP-OPTIONS PLB-TOKENS PLB-INCLUSIONS WS-FILE-ID
    CALL "PLB-PARSE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST
    CALL "PLB-SYM-BUILD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-TOKENS PLB-AST PLB-SYMBOLS
    CALL "PLB-FLOW-BUILD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-TOKENS PLB-AST PLB-FLOW
    CALL "PLB-REF-BUILD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        PLB-TOKENS PLB-AST PLB-SYMBOLS PLB-FLOW PLB-REFS
    CALL "PLB-REF-ROLES" USING PLB-TOKENS PLB-AST PLB-REFS.

PRINT-FINDING.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET FN-FILE-ID(WS-I)
        WS-PATH
    CALL "PLB-FIND-FORMAT" USING PLB-RULES PLB-FINDINGS WS-I WS-PATH
        WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

*> dump ---------------------------------------------------------

DUMP-COMMAND.
    PERFORM NEXT-ARG
    MOVE WS-ARG TO WS-DUMP-TARGET
    IF WS-ARG NOT = "lines" AND WS-ARG NOT = "tokens"
       AND WS-ARG NOT = "expanded" AND WS-ARG NOT = "ast"
       AND WS-ARG NOT = "symbols" AND WS-ARG NOT = "flow"
       AND WS-ARG NOT = "refs" AND WS-ARG NOT = "calls"
       AND WS-ARG NOT = "jcl" AND WS-ARG NOT = "bms"
       AND WS-ARG NOT = "csd" AND WS-ARG NOT = "ims"
       AND WS-ARG NOT = "sql"
        IF WS-ARG-LEN = 0
            DISPLAY PLB-NAME ": dump: missing what to dump"
                UPON SYSERR
        ELSE
            DISPLAY PLB-NAME ": dump: unknown target '"
                WS-ARG(1:WS-ARG-LEN) "'" UPON SYSERR
        END-IF
        PERFORM SUGGEST-HELP
        EXIT PARAGRAPH
    END-IF

    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    IF WS-DUMP-TARGET = "jcl"
        PERFORM DUMP-JCL
        EXIT PARAGRAPH
    END-IF
    IF WS-DUMP-TARGET = "bms"
        PERFORM DUMP-BMS
        EXIT PARAGRAPH
    END-IF
    IF WS-DUMP-TARGET = "csd"
        PERFORM DUMP-CSD
        EXIT PARAGRAPH
    END-IF
    IF WS-DUMP-TARGET = "ims"
        PERFORM DUMP-IMS
        EXIT PARAGRAPH
    END-IF
    PERFORM LOAD-INPUTS

    EVALUATE WS-DUMP-TARGET
    WHEN "lines"
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > SS-LINE-COUNT
            PERFORM DUMP-ONE-LINE
        END-PERFORM
    WHEN "expanded"
        PERFORM DUMP-EXPANDED
    WHEN "ast"
        PERFORM DUMP-AST
    WHEN "symbols"
        PERFORM DUMP-SYMBOLS
    WHEN "flow"
        PERFORM DUMP-FLOW
    WHEN "refs"
        PERFORM DUMP-REFS
    WHEN "sql"
        PERFORM DUMP-SQL
    WHEN "calls"
        PERFORM DUMP-CALLS
    WHEN OTHER
        CALL "PLB-LEX-INIT" USING PLB-TOKENS
        PERFORM VARYING WS-FILE-ID FROM 1 BY 1
                UNTIL WS-FILE-ID > SS-FILE-COUNT
            CALL "PLB-LEX-FILE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                PLB-TOKENS WS-FILE-ID WS-DEBUG
        END-PERFORM
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > TK-COUNT
            PERFORM DUMP-ONE-TOKEN
        END-PERFORM
    END-EVALUATE
    PERFORM REPORT-DIAGNOSTICS.

*> Expand each input file in turn. Copybooks are added to the source
*> set as they are read, so only the files named on the command line
*> (the first WS-MAIN-FILES ids) are expanded.
DUMP-EXPANDED.
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        CALL "PLB-PP-RUN" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-PP-OPTIONS PLB-TOKENS PLB-INCLUSIONS WS-FILE-ID
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > TK-COUNT
            PERFORM DUMP-ONE-TOKEN
        END-PERFORM
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IN-COUNT
            PERFORM DUMP-ONE-INCLUSION
        END-PERFORM
    END-PERFORM.

*> Expand and parse each input file and print its tree, one node per
*> line, indented by depth:
*>     KIND [detail] [level] [name] @line:column [in copybook-path]
DUMP-AST.
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        CALL "PLB-PP-RUN" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-PP-OPTIONS PLB-TOKENS PLB-INCLUSIONS WS-FILE-ID
        CALL "PLB-PARSE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PLB-AST
        MOVE 1 TO WS-ROOT WS-NODE
        MOVE 0 TO WS-DEPTH
        PERFORM UNTIL WS-NODE = 0
            PERFORM DUMP-ONE-NODE
            CALL "PLB-AST-NEXT" USING PLB-AST WS-ROOT WS-NODE WS-DEPTH
        END-PERFORM
    END-PERFORM.

*> One line per data item, indented by nesting:
*>     level name category size=n offset=n [attributes] @line:column
DUMP-SYMBOLS.
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        CALL "PLB-PP-RUN" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-PP-OPTIONS PLB-TOKENS PLB-INCLUSIONS WS-FILE-ID
        CALL "PLB-PARSE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PLB-AST
        CALL "PLB-SYM-BUILD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PLB-AST PLB-SYMBOLS
        PERFORM VARYING WS-S FROM 1 BY 1 UNTIL WS-S > SY-COUNT
            PERFORM DUMP-ONE-SYMBOL
        END-PERFORM
    END-PERFORM.

DUMP-ONE-SYMBOL.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE SY-PARENT(WS-S) TO WS-P
    PERFORM UNTIL WS-P = 0
        STRING "  " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        MOVE SY-PARENT(WS-P) TO WS-P
    END-PERFORM
    MOVE SY-LEVEL(WS-S) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    IF SY-NAME(WS-S) = SPACES
        STRING "FILLER" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING SY-NAME(WS-S) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING " " SY-CATEGORY(WS-S) " size=" DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE SY-SIZE(WS-S) TO WS-NUM
    PERFORM APPEND-NUM
    STRING " offset=" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE SY-OFFSET(WS-S) TO WS-NUM
    PERFORM APPEND-NUM
    IF SY-USAGE(WS-S) NOT = SPACES
        STRING " usage=" SY-USAGE(WS-S) DELIMITED BY "  "
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF SY-DIGITS(WS-S) > 0
        STRING " digits=" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        MOVE SY-DIGITS(WS-S) TO WS-NUM
        PERFORM APPEND-NUM
    END-IF
    IF SY-SCALE(WS-S) NOT = 0
        STRING " scale=" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        MOVE SY-SCALE(WS-S) TO WS-NUM
        PERFORM APPEND-NUM
    END-IF
    IF SY-SIGNED(WS-S) = "Y"
        STRING " signed" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF SY-OCCURS(WS-S) > 0
        STRING " occurs=" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        MOVE SY-OCCURS(WS-S) TO WS-NUM
        PERFORM APPEND-NUM
    END-IF
    IF SY-ODO-TOKEN(WS-S) > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS SY-ODO-TOKEN(WS-S)
            WS-TOKEN-TEXT WS-TOKEN-LEN
        STRING " depending=" WS-TOKEN-TEXT(1:WS-TOKEN-LEN)
            DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF SY-REDEFINES(WS-S) > 0
        STRING " redefines=" DELIMITED BY SIZE
               SY-NAME(SY-REDEFINES(WS-S)) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF SY-HAS-VALUE(WS-S) = "Y"
        STRING " value" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING " section=" SY-SECTION(WS-S) DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE ND-TOK-FIRST(SY-NODE(WS-S)) TO WS-TOK
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-NUM
    STRING " @" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    PERFORM APPEND-NUM
    STRING ":" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE TK-COLUMN(WS-TOK) TO WS-NUM
    PERFORM APPEND-NUM
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

*> One line per unit, then one per edge leaving it:
*>     KIND NAME [in SECTION] flags @line:column
*>       perform|go NAME [thru NAME]
DUMP-FLOW.
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        CALL "PLB-PP-RUN" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-PP-OPTIONS PLB-TOKENS PLB-INCLUSIONS WS-FILE-ID
        CALL "PLB-PARSE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PLB-AST
        CALL "PLB-FLOW-BUILD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PLB-AST PLB-FLOW
        MOVE 1 TO WS-E
        PERFORM VARYING WS-U FROM 1 BY 1 UNTIL WS-U > FU-COUNT
            PERFORM DUMP-ONE-UNIT
        END-PERFORM
    END-PERFORM.

DUMP-ONE-UNIT.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    EVALUATE FU-KIND(WS-U)
        WHEN "S"
            STRING "section " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "P"
            STRING "paragraph " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN OTHER
            STRING "start" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    STRING FU-NAME(WS-U) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    IF FU-SECTION(WS-U) > 0
        STRING " in " DELIMITED BY SIZE
               FU-NAME(FU-SECTION(WS-U)) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF FU-DECLARATIVE(WS-U) = "Y"
        STRING " declarative" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF FU-REACHED(WS-U) = "Y"
        STRING " reached" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING " unreachable" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF FU-FLOWED(WS-U) = "Y"
        STRING " flowed" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF FU-PERFORMED(WS-U) = "Y"
        STRING " performed" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF FU-JUMPED-TO(WS-U) = "Y"
        STRING " jumped-to" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF FU-FALLS(WS-U) = "N"
        STRING " ends" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    MOVE ND-TOK-FIRST(FU-NODE(WS-U)) TO WS-TOK
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-NUM
    STRING " @" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    PERFORM APPEND-NUM
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN)
    PERFORM UNTIL WS-E > FE-COUNT
        IF FE-FROM(WS-E) NOT = WS-U
            EXIT PERFORM
        END-IF
        PERFORM DUMP-ONE-EDGE
        ADD 1 TO WS-E
    END-PERFORM.

DUMP-ONE-EDGE.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    EVALUATE FE-KIND(WS-E)
        WHEN "G"
            STRING "  go " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "A"
            *>  alter PARA-1 to PARA-2: the GO TO in PARA-1 may now go
            *>  to PARA-2.
            STRING "  alter " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
            IF FE-ALTERED(WS-E) = 0
                STRING "?" DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            ELSE
                STRING FU-NAME(FE-ALTERED(WS-E)) DELIMITED BY SPACE
                    INTO WS-OUT WITH POINTER WS-PTR
            END-IF
            STRING " to " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN OTHER
            STRING "  perform " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    IF FE-TO(WS-E) = 0
        STRING "?" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING FU-NAME(FE-TO(WS-E)) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        IF FE-THRU(WS-E) NOT = FE-TO(WS-E) AND FE-THRU(WS-E) > 0
            STRING " thru " DELIMITED BY SIZE
                   FU-NAME(FE-THRU(WS-E)) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
    END-IF
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

*> One line per reference:
*>     line:column NAME [(VERB)] -> what [flags] [role=R]
*> The embedded SQL of each file: its tables, cursors, and the pairs of
*> a column and a host variable of its statements.
DUMP-SQL.
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM ANALYZE-FILE
        CALL "PLB-SQL-MODEL-BUILD" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-SQL-MODEL
        CALL "PLB-SQL-MODEL-PRINT" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-SQL-MODEL
    END-PERFORM.

DUMP-REFS.
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM ANALYZE-FILE
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > RF-COUNT
            PERFORM DUMP-ONE-REF
        END-PERFORM
    END-PERFORM.

*> One line per program or ENTRY point, then its parameters; one
*> line per CALL, then its arguments:
*>     program NAME path:line:col [in OUTER] [common] [recursive]
*>       parameter NAME reference|value SIZE
*>     entry NAME path:line:col in PROGRAM
*>     call path:line:col CALLER -> TARGET RESOLUTION
*>       argument item|literal|omitted|other TEXT MODE SIZE
*> SIZE is in bytes, or ? when not known.
*> JCL is not COBOL source: each file is registered for its path and
*> read by the JCL reader.
DUMP-JCL.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    CALL "PLB-JCL-INIT" USING PLB-JCL
    CALL "PLB-BMS-INIT" USING PLB-BMS
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IP-COUNT
        CALL "PLB-SRC-ADD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            IP-PATH(WS-I) WS-MODE WS-FILE-ID
        CALL "PLB-JCL-READ" USING IP-PATH(WS-I) WS-FILE-ID PLB-JCL
            WS-STATUS
        IF WS-STATUS NOT = 0
            CALL "PLB-STR-LENGTH" USING IP-PATH(WS-I) WS-PATH-LEN
            DISPLAY PLB-NAME ": cannot read "
                IP-PATH(WS-I)(1:WS-PATH-LEN) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        END-IF
    END-PERFORM
    *> In source order: jobs and procedures, their steps, each step's
    *> DDs.
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > JJ-COUNT
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        MOVE JJ-FILE-ID(WS-I) TO WS-POS-FILE
        MOVE JJ-LINE(WS-I) TO WS-POS-LINE
        PERFORM APPEND-JCL-POSITION
        STRING "job " DELIMITED BY SIZE
               JJ-NAME(WS-I) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        DISPLAY WS-OUT(1:WS-PTR - 1)
        PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > JS-COUNT
            IF JS-JOB(WS-P) = WS-I
                PERFORM DUMP-JCL-STEP
            END-IF
        END-PERFORM
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > JP-COUNT
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        MOVE JP-FILE-ID(WS-I) TO WS-POS-FILE
        MOVE JP-LINE(WS-I) TO WS-POS-LINE
        PERFORM APPEND-JCL-POSITION
        STRING "proc " DELIMITED BY SIZE
               JP-NAME(WS-I) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        IF JP-INSTREAM(WS-I) = "Y"
            STRING " in-stream" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        DISPLAY WS-OUT(1:WS-PTR - 1)
        PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > JS-COUNT
            IF JS-PROC(WS-P) = WS-I
                PERFORM DUMP-JCL-STEP
            END-IF
        END-PERFORM
    END-PERFORM.

DUMP-JCL-STEP.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE JS-FILE-ID(WS-P) TO WS-POS-FILE
    MOVE JS-LINE(WS-P) TO WS-POS-LINE
    PERFORM APPEND-JCL-POSITION
    STRING "  step " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    IF JS-NAME(WS-P) = SPACES
        STRING "-" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING JS-NAME(WS-P) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    EVALUATE JS-KIND(WS-P)
        WHEN "P"
            STRING " pgm " DELIMITED BY SIZE
                   JS-TARGET(WS-P) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "R"
            STRING " proc " DELIMITED BY SIZE
                   JS-TARGET(WS-P) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    IF JS-INNER(WS-P) NOT = SPACES
        STRING " runs " DELIMITED BY SIZE
               JS-INNER(WS-P) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF JS-PSB(WS-P) NOT = SPACES
        STRING " psb " DELIMITED BY SIZE
               JS-PSB(WS-P) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    DISPLAY WS-OUT(1:WS-PTR - 1)
    PERFORM VARYING WS-C FROM JS-DD-FIRST(WS-P) BY 1
            UNTIL WS-C >= JS-DD-FIRST(WS-P) + JS-DD-COUNT(WS-P)
        PERFORM DUMP-JCL-DD
    END-PERFORM.

DUMP-JCL-DD.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE JD-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE JD-LINE(WS-C) TO WS-POS-LINE
    PERFORM APPEND-JCL-POSITION
    STRING "    dd " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    IF JD-QUALIFIER(WS-C) NOT = SPACES
        STRING JD-QUALIFIER(WS-C) DELIMITED BY SPACE
               "." DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING JD-NAME(WS-C) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    EVALUATE JD-KIND(WS-C)
        WHEN "D"
            STRING " dsn " DELIMITED BY SIZE
                   JD-DSN(WS-C) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "S"
            STRING " sysout" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "M"
            STRING " dummy" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "I"
            STRING " in-stream data" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN OTHER
            STRING " other" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    IF JD-DISP(WS-C) NOT = SPACES
        STRING " disp " DELIMITED BY SIZE
               JD-DISP(WS-C) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF JD-RECFM(WS-C) NOT = SPACES
        STRING " recfm " DELIMITED BY SIZE
               JD-RECFM(WS-C) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF JD-LRECL(WS-C) > 0
        STRING " lrecl " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
        MOVE JD-LRECL(WS-C) TO WS-NUM
        PERFORM APPEND-NUM
    END-IF
    IF JD-CONCAT(WS-C) = "Y"
        STRING " concatenated" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    DISPLAY WS-OUT(1:WS-PTR - 1).

*> path:line: for a position in a JCL file.
APPEND-JCL-POSITION.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET WS-POS-FILE WS-PATH
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-PATH-LEN
    IF WS-PATH-LEN > 0
        STRING WS-PATH(1:WS-PATH-LEN) DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING ":" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE WS-POS-LINE TO WS-NUM
    PERFORM APPEND-NUM
    STRING ": " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR.

*> BMS sources, like JCL, are registered for their paths and read by
*> their own reader.
DUMP-BMS.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    CALL "PLB-BMS-INIT" USING PLB-BMS
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IP-COUNT
        CALL "PLB-SRC-ADD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            IP-PATH(WS-I) WS-MODE WS-FILE-ID
        CALL "PLB-BMS-READ" USING IP-PATH(WS-I) WS-FILE-ID PLB-BMS
            WS-STATUS
        IF WS-STATUS NOT = 0
            CALL "PLB-STR-LENGTH" USING IP-PATH(WS-I) WS-PATH-LEN
            DISPLAY PLB-NAME ": cannot read "
                IP-PATH(WS-I)(1:WS-PATH-LEN) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > BS-COUNT
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        MOVE BS-FILE-ID(WS-I) TO WS-POS-FILE
        MOVE BS-LINE(WS-I) TO WS-POS-LINE
        PERFORM APPEND-JCL-POSITION
        STRING "mapset " DELIMITED BY SIZE
               BS-NAME(WS-I) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        DISPLAY WS-OUT(1:WS-PTR - 1)
        PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > BM-COUNT
            IF BM-MAPSET(WS-P) = WS-I
                PERFORM DUMP-BMS-MAP
            END-IF
        END-PERFORM
    END-PERFORM.

DUMP-BMS-MAP.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE BM-FILE-ID(WS-P) TO WS-POS-FILE
    MOVE BM-LINE(WS-P) TO WS-POS-LINE
    PERFORM APPEND-JCL-POSITION
    STRING "  map " DELIMITED BY SIZE
           BM-NAME(WS-P) DELIMITED BY SPACE
           " size " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE BM-LINES(WS-P) TO WS-NUM
    PERFORM APPEND-NUM
    STRING "x" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE BM-COLUMNS(WS-P) TO WS-NUM
    PERFORM APPEND-NUM
    DISPLAY WS-OUT(1:WS-PTR - 1)
    PERFORM VARYING WS-C FROM BM-FIELD-FIRST(WS-P) BY 1
            UNTIL WS-C >= BM-FIELD-FIRST(WS-P) + BM-FIELD-COUNT(WS-P)
        PERFORM DUMP-BMS-FIELD
    END-PERFORM.

DUMP-BMS-FIELD.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE BF-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE BF-LINE(WS-C) TO WS-POS-LINE
    PERFORM APPEND-JCL-POSITION
    STRING "    field " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    IF BF-NAME(WS-C) = SPACES
        STRING "-" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING BF-NAME(WS-C) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING " at " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE BF-ROW(WS-C) TO WS-NUM
    PERFORM APPEND-NUM
    STRING "," DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE BF-COLUMN(WS-C) TO WS-NUM
    PERFORM APPEND-NUM
    STRING " length " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE BF-LENGTH(WS-C) TO WS-NUM
    PERFORM APPEND-NUM
    IF BF-OCCURS(WS-C) > 1
        STRING " occurs " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
        MOVE BF-OCCURS(WS-C) TO WS-NUM
        PERFORM APPEND-NUM
    END-IF
    IF BF-PROTECTED(WS-C) = "Y"
        STRING " protected" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING " input" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF BF-NUMERIC(WS-C) = "Y"
        STRING " numeric" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF BF-HAS-INITIAL(WS-C) = "Y"
        STRING " initial" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    DISPLAY WS-OUT(1:WS-PTR - 1).

*> path:line: TYPE NAME group GROUP [program P | dsname D]
DUMP-CSD.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    CALL "PLB-CSD-INIT" USING PLB-CSD
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IP-COUNT
        CALL "PLB-SRC-ADD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            IP-PATH(WS-I) WS-MODE WS-FILE-ID
        CALL "PLB-CSD-READ" USING IP-PATH(WS-I) WS-FILE-ID PLB-CSD
            WS-STATUS
        IF WS-STATUS NOT = 0
            CALL "PLB-STR-LENGTH" USING IP-PATH(WS-I) WS-PATH-LEN
            DISPLAY PLB-NAME ": cannot read "
                IP-PATH(WS-I)(1:WS-PATH-LEN) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > CR-COUNT
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        MOVE CR-FILE-ID(WS-I) TO WS-POS-FILE
        MOVE CR-LINE(WS-I) TO WS-POS-LINE
        PERFORM APPEND-JCL-POSITION
        STRING FUNCTION LOWER-CASE(CR-TYPE(WS-I)) DELIMITED BY SPACE
               " " DELIMITED BY SIZE
               CR-NAME(WS-I) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        IF CR-GROUP(WS-I) NOT = SPACES
            STRING " group " DELIMITED BY SIZE
                   CR-GROUP(WS-I) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        IF CR-TARGET(WS-I) NOT = SPACES
            IF CR-TYPE(WS-I) = "FILE"
                STRING " dsname " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            ELSE
                STRING " program " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            END-IF
            STRING CR-TARGET(WS-I) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        DISPLAY WS-OUT(1:WS-PTR - 1)
    END-PERFORM.

*> The databases (DBD) and program views (PSB) of IMS sources.
DUMP-IMS.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    CALL "PLB-IMS-INIT" USING PLB-IMS
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IP-COUNT
        CALL "PLB-SRC-ADD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            IP-PATH(WS-I) WS-MODE WS-FILE-ID
        CALL "PLB-IMS-READ" USING IP-PATH(WS-I) WS-FILE-ID PLB-IMS
            WS-STATUS
        IF WS-STATUS NOT = 0
            CALL "PLB-STR-LENGTH" USING IP-PATH(WS-I) WS-PATH-LEN
            DISPLAY PLB-NAME ": cannot read "
                IP-PATH(WS-I)(1:WS-PATH-LEN) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        END-IF
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > XD-COUNT
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        MOVE XD-FILE-ID(WS-I) TO WS-POS-FILE
        MOVE XD-LINE(WS-I) TO WS-POS-LINE
        PERFORM APPEND-JCL-POSITION
        STRING "dbd " DELIMITED BY SIZE
               XD-NAME(WS-I) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        IF XD-ACCESS(WS-I) NOT = SPACES
            STRING " access " DELIMITED BY SIZE
                   XD-ACCESS(WS-I) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        DISPLAY WS-OUT(1:WS-PTR - 1)
        PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > XG-COUNT
            IF XG-DBD(WS-P) = WS-I
                PERFORM DUMP-IMS-SEGMENT
            END-IF
        END-PERFORM
    END-PERFORM
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > XP-COUNT
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        MOVE XP-FILE-ID(WS-I) TO WS-POS-FILE
        MOVE XP-LINE(WS-I) TO WS-POS-LINE
        PERFORM APPEND-JCL-POSITION
        STRING "psb " DELIMITED BY SIZE
               XP-NAME(WS-I) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        DISPLAY WS-OUT(1:WS-PTR - 1)
        PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > XC-COUNT
            IF XC-PSB(WS-P) = WS-I
                PERFORM DUMP-IMS-PCB
            END-IF
        END-PERFORM
    END-PERFORM.

DUMP-IMS-SEGMENT.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE XG-FILE-ID(WS-P) TO WS-POS-FILE
    MOVE XG-LINE(WS-P) TO WS-POS-LINE
    PERFORM APPEND-JCL-POSITION
    STRING "  segment " DELIMITED BY SIZE
           XG-NAME(WS-P) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    IF XG-PARENT(WS-P) NOT = SPACES
        STRING " parent " DELIMITED BY SIZE
               XG-PARENT(WS-P) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING " bytes " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE XG-BYTES(WS-P) TO WS-NUM
    PERFORM APPEND-NUM
    DISPLAY WS-OUT(1:WS-PTR - 1)
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > XF-COUNT
        IF XF-SEGMENT(WS-C) = WS-P
            MOVE SPACES TO WS-OUT
            MOVE 1 TO WS-PTR
            MOVE XG-FILE-ID(WS-P) TO WS-POS-FILE
            MOVE XF-LINE(WS-C) TO WS-POS-LINE
            PERFORM APPEND-JCL-POSITION
            STRING "    field " DELIMITED BY SIZE
                   XF-NAME(WS-C) DELIMITED BY SPACE
                   " start " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
            MOVE XF-START(WS-C) TO WS-NUM
            PERFORM APPEND-NUM
            STRING " bytes " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
            MOVE XF-BYTES(WS-C) TO WS-NUM
            PERFORM APPEND-NUM
            IF XF-SEQUENCE(WS-C) = "Y"
                STRING " sequence" DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            END-IF
            DISPLAY WS-OUT(1:WS-PTR - 1)
        END-IF
    END-PERFORM.

DUMP-IMS-PCB.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE XC-FILE-ID(WS-P) TO WS-POS-FILE
    MOVE XC-LINE(WS-P) TO WS-POS-LINE
    PERFORM APPEND-JCL-POSITION
    STRING "  pcb " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    IF XC-NAME(WS-P) NOT = SPACES
        STRING XC-NAME(WS-P) DELIMITED BY SPACE
               " " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING "type " DELIMITED BY SIZE
           XC-TYPE(WS-P) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    IF XC-DBD(WS-P) NOT = SPACES
        STRING " dbd " DELIMITED BY SIZE
               XC-DBD(WS-P) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF XC-PROCOPT(WS-P) NOT = SPACES
        STRING " procopt " DELIMITED BY SIZE
               XC-PROCOPT(WS-P) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    DISPLAY WS-OUT(1:WS-PTR - 1)
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > XS-COUNT
        IF XS-PCB(WS-C) = WS-P
            MOVE SPACES TO WS-OUT
            MOVE 1 TO WS-PTR
            MOVE XS-FILE-ID(WS-C) TO WS-POS-FILE
            MOVE XS-LINE(WS-C) TO WS-POS-LINE
            PERFORM APPEND-JCL-POSITION
            STRING "    senseg " DELIMITED BY SIZE
                   XS-NAME(WS-C) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
            IF XS-PARENT(WS-C) NOT = SPACES
                STRING " parent " DELIMITED BY SIZE
                       XS-PARENT(WS-C) DELIMITED BY SPACE
                    INTO WS-OUT WITH POINTER WS-PTR
            END-IF
            DISPLAY WS-OUT(1:WS-PTR - 1)
        END-IF
    END-PERFORM.

DUMP-CALLS.
    CALL "PLB-CALL-INIT" USING PLB-CALL-GRAPH
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM ANALYZE-FILE
        CALL "PLB-CALL-COLLECT" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
            PLB-SYMBOLS PLB-REFS PLB-CALL-GRAPH
    END-PERFORM
    CALL "PLB-CALL-RESOLVE" USING PLB-CALL-GRAPH
    PERFORM VARYING WS-P FROM 1 BY 1 UNTIL WS-P > CP-COUNT
        PERFORM DUMP-ONE-PROGRAM
    END-PERFORM
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > CC-COUNT
        PERFORM DUMP-ONE-CALL
    END-PERFORM
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > PF-COUNT
        PERFORM DUMP-ONE-FILE
    END-PERFORM
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > PM-COUNT
        PERFORM DUMP-ONE-MAP
    END-PERFORM
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > PU-COUNT
        PERFORM DUMP-ONE-RESOURCE
    END-PERFORM
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > PQ-COUNT
        PERFORM DUMP-ONE-TABLE
    END-PERFORM
    PERFORM VARYING WS-C FROM 1 BY 1 UNTIL WS-C > PD-COUNT
        PERFORM DUMP-ONE-DLI
    END-PERFORM
    IF CP-DROPPED > 0
        MOVE CP-DROPPED TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        DISPLAY "dropped " WS-NUM-TEXT(1:WS-NUM-LEN)
            " entries over the call graph's limits"
    END-IF.

*> file NAME path:line:col of PROGRAM dd DDNAME [optional] [sort]
*> [opened MODES]
*> map NAME of mapset SET path:line:col sent|received by PROGRAM
*> resource KIND NAME path:line:col COMMAND by PROGRAM
DUMP-ONE-RESOURCE.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "resource " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    EVALUATE PU-KIND(WS-C)
        WHEN "F" STRING "file " DELIMITED BY SIZE
                     INTO WS-OUT WITH POINTER WS-PTR
        WHEN "T" STRING "transaction " DELIMITED BY SIZE
                     INTO WS-OUT WITH POINTER WS-PTR
        WHEN "P" STRING "program " DELIMITED BY SIZE
                     INTO WS-OUT WITH POINTER WS-PTR
        WHEN "M" STRING "mapset " DELIMITED BY SIZE
                     INTO WS-OUT WITH POINTER WS-PTR
        WHEN "Q" STRING "tdqueue " DELIMITED BY SIZE
                     INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    STRING PU-NAME(WS-C) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE PU-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE PU-LINE(WS-C) TO WS-POS-LINE
    MOVE PU-COLUMN(WS-C) TO WS-POS-COLUMN
    PERFORM APPEND-POSITION
    STRING " " DELIMITED BY SIZE
           PU-COMMAND(WS-C) DELIMITED BY SPACE
           " by " DELIMITED BY SIZE
           CP-NAME(PU-PROGRAM(WS-C)) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    DISPLAY WS-OUT(1:WS-PTR - 1).

*> table NAME path:line:col USE by PROGRAM
DUMP-ONE-TABLE.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "table " DELIMITED BY SIZE
           PQ-TABLE(WS-C) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE PQ-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE PQ-LINE(WS-C) TO WS-POS-LINE
    MOVE PQ-COLUMN(WS-C) TO WS-POS-COLUMN
    PERFORM APPEND-POSITION
    EVALUATE PQ-KIND(WS-C)
        WHEN "S" MOVE "selected" TO WS-KIND-NAME
        WHEN "I" MOVE "inserted" TO WS-KIND-NAME
        WHEN "U" MOVE "updated" TO WS-KIND-NAME
        WHEN "D" MOVE "deleted" TO WS-KIND-NAME
        WHEN "M" MOVE "merged" TO WS-KIND-NAME
        WHEN "T" MOVE "declared" TO WS-KIND-NAME
    END-EVALUATE
    STRING " " DELIMITED BY SIZE
           WS-KIND-NAME DELIMITED BY SPACE
           " by " DELIMITED BY SIZE
           CP-NAME(PQ-PROGRAM(WS-C)) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    DISPLAY WS-OUT(1:WS-PTR - 1).

*> dli FUNCTION segment|psb NAME path:line:col by PROGRAM
DUMP-ONE-DLI.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "dli " DELIMITED BY SIZE
           PD-FUNCTION(WS-C) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    IF PD-KIND(WS-C) = "P"
        STRING " psb " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING " segment " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING PD-NAME(WS-C) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE PD-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE PD-LINE(WS-C) TO WS-POS-LINE
    MOVE PD-COLUMN(WS-C) TO WS-POS-COLUMN
    PERFORM APPEND-POSITION
    STRING " by " DELIMITED BY SIZE
           CP-NAME(PD-PROGRAM(WS-C)) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    DISPLAY WS-OUT(1:WS-PTR - 1).

DUMP-ONE-MAP.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "map " DELIMITED BY SIZE
           PM-MAP(WS-C) DELIMITED BY SPACE
           " of mapset " DELIMITED BY SIZE
           PM-MAPSET(WS-C) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE PM-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE PM-LINE(WS-C) TO WS-POS-LINE
    MOVE PM-COLUMN(WS-C) TO WS-POS-COLUMN
    PERFORM APPEND-POSITION
    IF PM-COMMAND(WS-C) = "S"
        STRING " sent by " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING " received by " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING CP-NAME(PM-PROGRAM(WS-C)) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    DISPLAY WS-OUT(1:WS-PTR - 1).

DUMP-ONE-FILE.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "file " DELIMITED BY SIZE
           PF-NAME(WS-C) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE PF-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE PF-LINE(WS-C) TO WS-POS-LINE
    MOVE PF-COLUMN(WS-C) TO WS-POS-COLUMN
    PERFORM APPEND-POSITION
    STRING " of " DELIMITED BY SIZE
           CP-NAME(PF-PROGRAM(WS-C)) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    IF PF-DDNAME(WS-C) = SPACES
        STRING " dd ?" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING " dd " DELIMITED BY SIZE
               PF-DDNAME(WS-C) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF PF-OPTIONAL(WS-C) = "Y"
        STRING " optional" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF PF-SORT(WS-C) = "Y"
        STRING " sort" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF PF-INPUT(WS-C) = "Y"
        STRING " input" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF PF-OUTPUT(WS-C) = "Y"
        STRING " output" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF PF-I-O(WS-C) = "Y"
        STRING " i-o" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF PF-EXTEND(WS-C) = "Y"
        STRING " extend" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF PF-RECORD-SIZE(WS-C) > 0
        STRING " record " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
        MOVE PF-RECORD-SIZE(WS-C) TO WS-NUM
        PERFORM APPEND-NUM
    END-IF
    DISPLAY WS-OUT(1:WS-PTR - 1).

DUMP-ONE-PROGRAM.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    IF CP-KIND(WS-P) = "E"
        STRING "entry " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING "program " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING CP-NAME(WS-P) DELIMITED BY SPACE " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    MOVE CP-FILE-ID(WS-P) TO WS-POS-FILE
    MOVE CP-LINE(WS-P) TO WS-POS-LINE
    MOVE CP-COLUMN(WS-P) TO WS-POS-COLUMN
    PERFORM APPEND-POSITION
    IF CP-KIND(WS-P) = "E"
        STRING " in " DELIMITED BY SIZE
               CP-NAME(CP-OWNER(WS-P)) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        IF CP-PARENT(WS-P) > 0
            STRING " in " DELIMITED BY SIZE
                   CP-NAME(CP-PARENT(WS-P)) DELIMITED BY SPACE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        IF CP-COMMON(WS-P) = "Y"
            STRING " common" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        IF CP-RECURSIVE(WS-P) = "Y"
            STRING " recursive" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
    END-IF
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN)
    PERFORM VARYING WS-K FROM CP-PARAM-FIRST(WS-P) BY 1
            UNTIL WS-K >= CP-PARAM-FIRST(WS-P) + CP-PARAM-COUNT(WS-P)
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        STRING "  parameter " DELIMITED BY SIZE
               CA-NAME(WS-K) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        IF CA-MODE(WS-K) = "V"
            STRING " value " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        ELSE
            STRING " reference " DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        MOVE CA-SIZE(WS-K) TO WS-NUM
        PERFORM APPEND-SIZE
        CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
        DISPLAY WS-OUT(1:WS-OUT-LEN)
    END-PERFORM.

DUMP-ONE-CALL.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    STRING "call " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE CC-FILE-ID(WS-C) TO WS-POS-FILE
    MOVE CC-LINE(WS-C) TO WS-POS-LINE
    MOVE CC-COLUMN(WS-C) TO WS-POS-COLUMN
    PERFORM APPEND-POSITION
    STRING " " DELIMITED BY SIZE
           CP-NAME(CC-FROM(WS-C)) DELIMITED BY SPACE
           " -> " DELIMITED BY SIZE
           CC-TARGET(WS-C) DELIMITED BY SPACE
           " " DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR
    EVALUATE TRUE
        WHEN CC-DYNAMIC(WS-C) = "Y"
            STRING "dynamic" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN CC-TO(WS-C) > 0
            MOVE CC-TO(WS-C) TO WS-K
            MOVE CP-FILE-ID(WS-K) TO WS-POS-FILE
            MOVE CP-LINE(WS-K) TO WS-POS-LINE
            MOVE CP-COLUMN(WS-K) TO WS-POS-COLUMN
            PERFORM APPEND-POSITION
        WHEN CC-MATCHES(WS-C) > 1
            MOVE CC-MATCHES(WS-C) TO WS-NUM
            PERFORM APPEND-NUM
            STRING " programs" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN OTHER
            STRING "not found" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN)
    PERFORM VARYING WS-K FROM CC-ARG-FIRST(WS-C) BY 1
            UNTIL WS-K >= CC-ARG-FIRST(WS-C) + CC-ARG-COUNT(WS-C)
        MOVE SPACES TO WS-OUT
        MOVE 1 TO WS-PTR
        STRING "  argument " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
        EVALUATE CG-KIND(WS-K)
            WHEN "D"
                STRING "item " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            WHEN "L"
                STRING "literal " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            WHEN "O"
                STRING "omitted " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            WHEN OTHER
                STRING "other " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
        END-EVALUATE
        STRING CG-TEXT(WS-K) DELIMITED BY SPACE
            INTO WS-OUT WITH POINTER WS-PTR
        EVALUATE CG-MODE(WS-K)
            WHEN "C"
                STRING " content " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            WHEN "V"
                STRING " value " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            WHEN OTHER
                STRING " reference " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
        END-EVALUATE
        MOVE CG-SIZE(WS-K) TO WS-NUM
        PERFORM APPEND-SIZE
        CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
        DISPLAY WS-OUT(1:WS-OUT-LEN)
    END-PERFORM.

*> path:line:column of WS-POS-FILE, WS-POS-LINE, WS-POS-COLUMN.
APPEND-POSITION.
    CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET WS-POS-FILE WS-PATH
    CALL "PLB-STR-LENGTH" USING WS-PATH WS-PATH-LEN
    IF WS-PATH-LEN > 0
        STRING WS-PATH(1:WS-PATH-LEN) DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING ":" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE WS-POS-LINE TO WS-NUM
    PERFORM APPEND-NUM
    STRING ":" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE WS-POS-COLUMN TO WS-NUM
    PERFORM APPEND-NUM.

*> WS-NUM bytes, or ? for 0.
APPEND-SIZE.
    IF WS-NUM = 0
        STRING "?" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        PERFORM APPEND-NUM
    END-IF.

DUMP-ONE-REF.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE RF-TOKEN(WS-I) TO WS-TOK
    MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-NUM
    PERFORM APPEND-NUM
    STRING ":" DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE TK-COLUMN(WS-TOK) TO WS-NUM
    PERFORM APPEND-NUM
    STRING " " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    PERFORM VARYING WS-J FROM RF-TOKEN(WS-I) BY 1
            UNTIL WS-J > RF-LAST(WS-I)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-J WS-TOKEN-TEXT
            WS-TOKEN-LEN
        *> Spaces between words, none around ( ) and :.
        IF WS-J > RF-TOKEN(WS-I) AND NOT TK-IS-RPAREN(WS-J)
           AND NOT TK-IS-COLON(WS-J) AND NOT TK-IS-LPAREN(WS-J)
           AND NOT TK-IS-LPAREN(WS-J - 1) AND NOT TK-IS-COLON(WS-J - 1)
            STRING " " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        IF WS-TOKEN-LEN > 0
            STRING WS-TOKEN-TEXT(1:WS-TOKEN-LEN) DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
    END-PERFORM
    IF RF-STMT(WS-I) > 0
        STRING " (" DELIMITED BY SIZE
               ND-DETAIL(RF-STMT(WS-I)) DELIMITED BY "  "
               ")" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    STRING " -> " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    EVALUATE RF-KIND(WS-I)
        WHEN "D"
        WHEN "A"
            MOVE RF-SYMBOL(WS-I) TO WS-S
            IF RF-KIND(WS-I) = "A"
                STRING "ambiguous, first " DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            END-IF
            MOVE SY-LEVEL(WS-S) TO WS-NUM
            PERFORM APPEND-NUM
            STRING " " DELIMITED BY SIZE
                   SY-NAME(WS-S) DELIMITED BY SPACE
                   " @" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
            MOVE ND-TOK-FIRST(SY-NODE(WS-S)) TO WS-TOK
            MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-NUM
            PERFORM APPEND-NUM
        WHEN "P"
            STRING "procedure" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN "O"
            STRING "other name" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        WHEN OTHER
            STRING "undefined" DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
    END-EVALUATE
    IF RF-SUBSCRIPTED(WS-I) = "Y"
        STRING " subscripted" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF RF-REFMOD(WS-I) = "Y"
        STRING " refmod" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF RF-ROLE(WS-I) NOT = "-"
        STRING " role=" RF-ROLE(WS-I) DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR.

DUMP-ONE-NODE.
    MOVE SPACES TO WS-OUT
    COMPUTE WS-PTR = WS-DEPTH * 2 + 1
    STRING ND-KIND(WS-NODE) DELIMITED BY SPACE
        INTO WS-OUT WITH POINTER WS-PTR
    IF ND-KIND(WS-NODE) = "DATA"
        MOVE ND-NUM(WS-NODE) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING " " WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF ND-DETAIL(WS-NODE) NOT = SPACES
        STRING " " FUNCTION TRIM(ND-DETAIL(WS-NODE)) DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    IF ND-NAME(WS-NODE) > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(WS-NODE)
            WS-TOKEN-TEXT WS-TOKEN-LEN
        IF WS-TOKEN-LEN > 0
            STRING " " WS-TOKEN-TEXT(1:WS-TOKEN-LEN) DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
    END-IF
    MOVE ND-TOK-FIRST(WS-NODE) TO WS-TOK
    IF WS-TOK >= 1 AND WS-TOK <= TK-COUNT
        MOVE 0 TO WS-NUM
        IF TK-SRC-LINE(WS-TOK) > 0
            MOVE SL-LINE-NO(TK-SRC-LINE(WS-TOK)) TO WS-NUM
        END-IF
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING " @" WS-NUM-TEXT(1:WS-NUM-LEN) ":" DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
        MOVE TK-COLUMN(WS-TOK) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING WS-NUM-TEXT(1:WS-NUM-LEN) DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
        IF TK-FILE-ID(WS-TOK) NOT = WS-FILE-ID
            CALL "PLB-STR-LENGTH" USING SF-PATH(TK-FILE-ID(WS-TOK))
                WS-PATH-LEN
            STRING " in " SF-PATH(TK-FILE-ID(WS-TOK))(1:WS-PATH-LEN)
                DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        END-IF
    END-IF
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

*> One line per inclusion:
*>     inclusion N: copybook-path from path:line:column [in inclusion P]
DUMP-ONE-INCLUSION.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    MOVE WS-I TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING "inclusion " WS-NUM-TEXT(1:WS-NUM-LEN) ": "
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    CALL "PLB-STR-LENGTH" USING SF-PATH(IN-FILE-ID(WS-I)) WS-PATH-LEN
    STRING SF-PATH(IN-FILE-ID(WS-I))(1:WS-PATH-LEN) " from "
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    CALL "PLB-STR-LENGTH" USING SF-PATH(IN-FROM-FILE-ID(WS-I))
        WS-PATH-LEN
    STRING SF-PATH(IN-FROM-FILE-ID(WS-I))(1:WS-PATH-LEN) ":"
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE IN-FROM-LINE(WS-I) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) ":"
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE IN-FROM-COLUMN(WS-I) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN)
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    IF IN-PARENT(WS-I) > 0
        MOVE IN-PARENT(WS-I) TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        STRING " in inclusion " WS-NUM-TEXT(1:WS-NUM-LEN)
            DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

*> Collect options and file operands up to the end of the arguments.
PARSE-INPUT-ARGS.
    MOVE 0 TO IP-COUNT
    CALL "PLB-PP-INIT-OPTIONS" USING PLB-PP-OPTIONS
    CALL "PLB-RULES-INIT" USING PLB-RULES
    PERFORM FIND-CONFIG-OPTIONS
    IF WS-EXIT-CODE = 0
        PERFORM LOAD-CONFIG
    END-IF
    PERFORM UNTIL WS-ARG-INDEX > WS-ARG-COUNT OR WS-EXIT-CODE NOT = 0
        PERFORM NEXT-ARG
        EVALUATE TRUE
            WHEN WS-ARG = "--config"
                *> Read by FIND-CONFIG-OPTIONS.
                PERFORM NEXT-ARG
            WHEN WS-ARG = "--no-config"
                CONTINUE
            WHEN WS-ARG = "--baseline"
                PERFORM NEXT-ARG
                IF WS-ARG-LEN = 0
                    DISPLAY PLB-NAME ": --baseline needs a file" UPON SYSERR
                    PERFORM SUGGEST-HELP
                ELSE
                    MOVE WS-ARG TO WS-BASELINE
                END-IF
            WHEN WS-ARG = "--diff"
                PERFORM NEXT-ARG
                IF WS-ARG-LEN = 0
                    DISPLAY PLB-NAME ": --diff needs a file" UPON SYSERR
                    PERFORM SUGGEST-HELP
                ELSE
                    MOVE WS-ARG TO WS-DIFF
                END-IF
            WHEN WS-ARG = "--write-baseline"
                PERFORM NEXT-ARG
                IF WS-ARG-LEN = 0
                    DISPLAY PLB-NAME ": --write-baseline needs a file"
                        UPON SYSERR
                    PERFORM SUGGEST-HELP
                ELSE
                    MOVE WS-ARG TO WS-WRITE-BASELINE
                END-IF
            WHEN WS-ARG = "--tab-width"
                PERFORM NEXT-ARG
                PERFORM SET-TAB-WIDTH
            WHEN WS-ARG = "--intrinsics"
                PERFORM NEXT-ARG
                PERFORM SET-INTRINSICS
            WHEN WS-ARG = "--define" OR WS-ARG = "-D"
                PERFORM NEXT-ARG
                PERFORM ADD-DEFINE
            WHEN WS-ARG = "--files-from"
                PERFORM NEXT-ARG
                IF WS-ARG-LEN = 0
                    DISPLAY PLB-NAME ": --files-from needs a file"
                        UPON SYSERR
                    PERFORM SUGGEST-HELP
                ELSE
                    PERFORM READ-FILE-LIST
                END-IF
            WHEN WS-ARG = "--format"
                PERFORM NEXT-ARG
                PERFORM SET-MODE
            WHEN WS-ARG = "--debug"
                MOVE "Y" TO WS-DEBUG
            WHEN WS-ARG = "--enable" OR WS-ARG = "--disable"
                MOVE WS-ARG TO WS-CONTENT
                PERFORM NEXT-ARG
                PERFORM SET-RULE-ENABLED
            WHEN WS-ARG = "--fail-on"
                PERFORM NEXT-ARG
                PERFORM SET-FAIL-ON
            WHEN WS-ARG = "--report"
                PERFORM NEXT-ARG
                PERFORM SET-REPORT
            WHEN WS-ARG = "--to" AND WS-COMMAND = "format"
                PERFORM NEXT-ARG
                IF WS-ARG = "fixed" OR WS-ARG = "free"
                    MOVE WS-ARG TO WS-FORMAT-TO
                ELSE
                    DISPLAY PLB-NAME ": invalid --to '"
                        WS-ARG(1:WS-ARG-LEN) "' (expected fixed or free)"
                        UPON SYSERR
                    MOVE 2 TO WS-EXIT-CODE
                END-IF
            WHEN WS-ARG = "--unused" AND WS-COMMAND = "fields"
                MOVE "Y" TO WS-FIELDS-UNUSED
            WHEN WS-ARG = "--forward" AND WS-COMMAND = "lineage"
                MOVE "F" TO WS-LINEAGE-DIRECTION
            WHEN WS-ARG = "--depth" AND WS-COMMAND = "lineage"
                PERFORM NEXT-ARG
                IF WS-ARG-LEN > 0 AND WS-ARG-LEN < 4
                   AND WS-ARG(1:WS-ARG-LEN) IS NUMERIC
                    COMPUTE WS-LINEAGE-DEPTH =
                        FUNCTION NUMVAL(WS-ARG(1:WS-ARG-LEN))
                ELSE
                    DISPLAY PLB-NAME ": invalid --depth '"
                        WS-ARG(1:WS-ARG-LEN) "' (expected a number)"
                        UPON SYSERR
                    MOVE 2 TO WS-EXIT-CODE
                END-IF
            WHEN WS-ARG = "--min-tokens" AND WS-COMMAND = "duplicates"
                PERFORM NEXT-ARG
                IF WS-ARG-LEN > 0 AND WS-ARG-LEN < 7
                   AND WS-ARG(1:WS-ARG-LEN) IS NUMERIC
                    COMPUTE WS-DUP-MIN =
                        FUNCTION NUMVAL(WS-ARG(1:WS-ARG-LEN))
                ELSE
                    DISPLAY PLB-NAME ": invalid --min-tokens '"
                        WS-ARG(1:WS-ARG-LEN) "' (expected a number)"
                        UPON SYSERR
                    MOVE 2 TO WS-EXIT-CODE
                END-IF
            WHEN WS-ARG = "--patch" AND WS-COMMAND = "fix"
                MOVE "D" TO WS-FIX-MODE
            WHEN WS-ARG = "--check"
                 AND (WS-COMMAND = "format" OR WS-COMMAND = "fix")
                MOVE "Y" TO WS-FORMAT-CHECK
            WHEN WS-ARG = "--kind" AND WS-COMMAND = "graph"
                PERFORM NEXT-ARG
                EVALUATE WS-ARG
                    WHEN "performs" WHEN "calls" WHEN "copybooks"
                    WHEN "jobs" WHEN "datasets" WHEN "cics" WHEN "crud"
                        MOVE WS-ARG TO WS-GRAPH-KIND
                    WHEN OTHER
                        DISPLAY PLB-NAME ": invalid --kind '"
                            WS-ARG(1:WS-ARG-LEN)
                            "' (expected performs, calls, copybooks, jobs,"
                            " datasets, cics, or crud)"
                            UPON SYSERR
                        MOVE 2 TO WS-EXIT-CODE
                END-EVALUATE
            WHEN WS-ARG = "-I"
                IF WS-ARG-INDEX > WS-ARG-COUNT
                    DISPLAY PLB-NAME ": -I needs a directory" UPON SYSERR
                    PERFORM SUGGEST-HELP
                ELSE
                    PERFORM NEXT-ARG
                    PERFORM ADD-COPY-PATH
                END-IF
            WHEN WS-ARG(1:2) = "-I"
                MOVE WS-ARG(3:) TO WS-CONTENT
                MOVE WS-CONTENT TO WS-ARG
                PERFORM ADD-COPY-PATH
            WHEN WS-ARG(1:9) = "--format="
                MOVE WS-ARG(10:) TO WS-CONTENT
                MOVE WS-CONTENT TO WS-ARG
                CALL "PLB-STR-LENGTH" USING WS-ARG WS-ARG-LEN
                PERFORM SET-MODE
            WHEN WS-ARG(1:1) = "-" AND WS-ARG-LEN > 1
                PERFORM UNKNOWN-OPTION
            WHEN IP-COUNT >= IP-MAX
                DISPLAY PLB-NAME ": too many input files (limit "
                    IP-MAX ")" UPON SYSERR
                MOVE 2 TO WS-EXIT-CODE
            WHEN WS-ARG-LEN > LENGTH OF IP-PATH(1)
                DISPLAY PLB-NAME ": file name longer than 512 characters: "
                    WS-ARG(1:60) "..." UPON SYSERR
                MOVE 2 TO WS-EXIT-CODE
            WHEN OTHER
                ADD 1 TO IP-COUNT
                MOVE WS-ARG TO IP-PATH(IP-COUNT)
        END-EVALUATE
    END-PERFORM
    IF WS-EXIT-CODE = 0 AND IP-COUNT = 0 AND WS-COMMAND NOT = "lsp"
       AND WS-COMMAND NOT = "rules"
        DISPLAY PLB-NAME ": no input files" UPON SYSERR
        PERFORM SUGGEST-HELP
    END-IF.

*> --define NAME[=VALUE]: NAME is defined for >>IF NAME DEFINED and
*> $IF NAME DEFINED. The value is not used.
ADD-DEFINE.
    MOVE 0 TO WS-J
    INSPECT WS-ARG(1:WS-ARG-LEN + 1) TALLYING WS-J
        FOR CHARACTERS BEFORE INITIAL "="
    EVALUATE TRUE
        WHEN WS-ARG-LEN = 0 OR WS-J = 0
            DISPLAY PLB-NAME ": --define needs a name" UPON SYSERR
            PERFORM SUGGEST-HELP
        WHEN WS-J > 31
            DISPLAY PLB-NAME ": name longer than 31 characters: "
                WS-ARG(1:WS-J) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN WS-DEFINE-COUNT >= 64
            DISPLAY PLB-NAME ": too many --define names (limit 64)"
                UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN OTHER
            ADD 1 TO WS-DEFINE-COUNT
            MOVE FUNCTION UPPER-CASE(WS-ARG(1:WS-J))
                TO WS-DEFINE(WS-DEFINE-COUNT)
    END-EVALUATE.

*> --tab-width N: tab stops every N columns, 1 to 12, as cobc's
*> -ftab-width.
SET-TAB-WIDTH.
    IF WS-ARG-LEN = 0 OR WS-ARG-LEN > 2
       OR WS-ARG(1:WS-ARG-LEN) IS NOT NUMERIC
        DISPLAY PLB-NAME ": invalid tab width '" WS-ARG(1:WS-ARG-LEN)
            "' (expected 1 to 12)" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    COMPUTE WS-NUM = FUNCTION NUMVAL(WS-ARG(1:WS-ARG-LEN))
    IF WS-NUM < 1 OR WS-NUM > 12
        DISPLAY PLB-NAME ": invalid tab width '" WS-ARG(1:WS-ARG-LEN)
            "' (expected 1 to 12)" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    *> plumbline: ignore move-truncation -- checked to be 1 to 12 above
    MOVE WS-NUM TO WS-TAB-WIDTH.

*> --intrinsics all|NAME,...: "ALL", or the names in upper case between
*> commas, as SS-INTRINSICS holds them.
SET-INTRINSICS.
    IF WS-ARG-LEN = 0 OR WS-ARG-LEN > 250
        DISPLAY PLB-NAME ": --intrinsics needs all or a list of names"
            UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    IF FUNCTION UPPER-CASE(WS-ARG(1:WS-ARG-LEN)) = "ALL"
        MOVE "ALL" TO WS-INTRINSICS
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO WS-INTRINSICS
    STRING "," FUNCTION UPPER-CASE(WS-ARG(1:WS-ARG-LEN)) ","
        DELIMITED BY SIZE INTO WS-INTRINSICS.

*> The --define names, the tab width, and the intrinsics, for the
*> source set just initialized.
APPLY-DEFINES.
    PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > WS-DEFINE-COUNT
        MOVE WS-DEFINE(WS-J) TO SS-DEFINE(WS-J)
    END-PERFORM
    MOVE WS-DEFINE-COUNT TO SS-DEFINE-COUNT
    MOVE WS-TAB-WIDTH TO SS-TAB-WIDTH
    MOVE WS-INTRINSICS TO SS-INTRINSICS.

*> --files-from WS-ARG: add the files it lists ("-": standard input).
READ-FILE-LIST.
    CALL "PLB-INPUTS-READ-LIST" USING WS-ARG(1:WS-ARG-LEN) PLB-INPUTS
        WS-LIST-STATUS WS-LIST-LINE
    EVALUATE WS-LIST-STATUS
        WHEN 1
            DISPLAY PLB-NAME ": cannot read file list "
                WS-ARG(1:WS-ARG-LEN) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN 2
            DISPLAY PLB-NAME ": too many input files (limit "
                IP-MAX ")" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN 3
            MOVE WS-LIST-LINE TO WS-NUM
            CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
            DISPLAY PLB-NAME ": file name longer than 512 characters"
                " in " WS-ARG(1:WS-ARG-LEN) " line "
                WS-NUM-TEXT(1:WS-NUM-LEN) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
    END-EVALUATE.

*> Look ahead in the arguments for --config FILE and --no-config, which
*> decide what is read before the other options.
FIND-CONFIG-OPTIONS.
    MOVE WS-ARG-INDEX TO WS-SAVED-INDEX
    PERFORM UNTIL WS-ARG-INDEX > WS-ARG-COUNT
        PERFORM NEXT-ARG
        EVALUATE WS-ARG
            WHEN "--no-config"
                MOVE "N" TO WS-USE-CONFIG
            WHEN "--config"
                PERFORM NEXT-ARG
                IF WS-ARG-LEN = 0
                    DISPLAY PLB-NAME ": --config needs a file" UPON SYSERR
                    PERFORM SUGGEST-HELP
                    EXIT PERFORM
                END-IF
                MOVE WS-ARG TO WS-CONFIG-PATH
                MOVE "Y" TO WS-CONFIG-GIVEN
        END-EVALUATE
    END-PERFORM
    MOVE WS-SAVED-INDEX TO WS-ARG-INDEX.

*> Apply the settings of the configuration file. A missing default
*> file is fine; a missing file given with --config is an error.
LOAD-CONFIG.
    IF WS-USE-CONFIG = "N"
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-CONF-READ" USING WS-CONFIG-PATH PLB-CONFIG WS-STATUS
    CALL "PLB-STR-LENGTH" USING WS-CONFIG-PATH WS-CONFIG-PATH-LEN
    IF WS-STATUS NOT = 0
        IF WS-CONFIG-GIVEN = "Y"
            DISPLAY PLB-NAME ": cannot read configuration file "
                WS-CONFIG-PATH(1:WS-CONFIG-PATH-LEN) UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        END-IF
        EXIT PARAGRAPH
    END-IF
    IF CF-OVERFLOW = "Y"
        DISPLAY PLB-NAME ": " WS-CONFIG-PATH(1:WS-CONFIG-PATH-LEN)
            ": too many settings (limit " CF-MAX ")" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING WS-SETTING FROM 1 BY 1
            UNTIL WS-SETTING > CF-COUNT OR WS-EXIT-CODE NOT = 0
        PERFORM APPLY-SETTING
        IF WS-EXIT-CODE NOT = 0
            MOVE CF-LINE-NO(WS-SETTING) TO WS-NUM
            CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
            DISPLAY PLB-NAME ": in " WS-CONFIG-PATH(1:WS-CONFIG-PATH-LEN)
                " line " WS-NUM-TEXT(1:WS-NUM-LEN) UPON SYSERR
        END-IF
    END-PERFORM.

APPLY-SETTING.
    MOVE CF-VALUE(WS-SETTING) TO WS-ARG
    CALL "PLB-STR-LENGTH" USING WS-ARG WS-ARG-LEN
    IF WS-ARG-LEN = 0
        DISPLAY PLB-NAME ": setting '" FUNCTION TRIM(CF-KEY(WS-SETTING))
            "' needs a value" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    EVALUATE CF-KEY(WS-SETTING)
        WHEN "include"
            PERFORM ADD-COPY-PATH
        WHEN "format"
            PERFORM SET-MODE
        WHEN "enable"
            MOVE "--enable" TO WS-CONTENT
            PERFORM SET-RULE-ENABLED
        WHEN "disable"
            MOVE "--disable" TO WS-CONTENT
            PERFORM SET-RULE-ENABLED
        WHEN "severity"
            PERFORM SET-SEVERITY
        WHEN "limit"
            PERFORM SET-LIMIT
        WHEN "fail-on"
            PERFORM SET-FAIL-ON
        WHEN "report"
            PERFORM SET-REPORT
        WHEN "baseline"
            MOVE WS-ARG TO WS-BASELINE
        WHEN "define"
            PERFORM ADD-DEFINE
        WHEN "tab-width"
            PERFORM SET-TAB-WIDTH
        WHEN "intrinsics"
            PERFORM SET-INTRINSICS
        WHEN OTHER
            DISPLAY PLB-NAME ": unknown setting '"
                FUNCTION TRIM(CF-KEY(WS-SETTING)) "'" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
    END-EVALUATE.

*> WS-ARG holds "RULE N": the threshold of a measuring rule.
SET-LIMIT.
    MOVE SPACES TO WS-SEVERITY-RULE WS-SEVERITY-LEVEL
    UNSTRING WS-ARG DELIMITED BY ALL SPACE
        INTO WS-SEVERITY-RULE WS-SEVERITY-LEVEL
    CALL "PLB-RULE-FIND" USING PLB-RULES WS-SEVERITY-RULE WS-RULE
    EVALUATE TRUE
        WHEN WS-RULE = 0
            DISPLAY PLB-NAME ": unknown rule '"
                FUNCTION TRIM(WS-SEVERITY-RULE) "'" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN RL-LIMIT(WS-RULE) = 0
            DISPLAY PLB-NAME ": rule '" FUNCTION TRIM(WS-SEVERITY-RULE)
                "' has no limit" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN FUNCTION TEST-NUMVAL(WS-SEVERITY-LEVEL) NOT = 0
        WHEN WS-SEVERITY-LEVEL = SPACES
            DISPLAY PLB-NAME ": invalid limit '"
                FUNCTION TRIM(WS-SEVERITY-LEVEL) "'" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN FUNCTION NUMVAL(WS-SEVERITY-LEVEL) < 1
            DISPLAY PLB-NAME ": invalid limit '"
                FUNCTION TRIM(WS-SEVERITY-LEVEL) "'" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN OTHER
            MOVE FUNCTION NUMVAL(WS-SEVERITY-LEVEL) TO RL-LIMIT(WS-RULE)
    END-EVALUATE.

*> WS-ARG holds "RULE LEVEL".
SET-SEVERITY.
    MOVE SPACES TO WS-SEVERITY-RULE WS-SEVERITY-LEVEL
    UNSTRING WS-ARG DELIMITED BY ALL SPACE
        INTO WS-SEVERITY-RULE WS-SEVERITY-LEVEL
    CALL "PLB-RULE-FIND" USING PLB-RULES WS-SEVERITY-RULE WS-RULE
    IF WS-RULE = 0
        DISPLAY PLB-NAME ": unknown rule '"
            FUNCTION TRIM(WS-SEVERITY-RULE) "'" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
        EXIT PARAGRAPH
    END-IF
    EVALUATE WS-SEVERITY-LEVEL
        WHEN "error"    MOVE "E" TO RL-SEVERITY(WS-RULE)
        WHEN "warning"  MOVE "W" TO RL-SEVERITY(WS-RULE)
        WHEN "note"     MOVE "N" TO RL-SEVERITY(WS-RULE)
        WHEN OTHER
            DISPLAY PLB-NAME ": invalid severity '"
                FUNCTION TRIM(WS-SEVERITY-LEVEL)
                "' (expected error, warning, or note)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
    END-EVALUATE.

*> WS-CONTENT holds the option (--enable or --disable), WS-ARG the
*> rule id or name.
SET-RULE-ENABLED.
    CALL "PLB-RULE-FIND" USING PLB-RULES WS-ARG WS-RULE
    IF WS-RULE = 0
        DISPLAY PLB-NAME ": unknown rule '" WS-ARG(1:WS-ARG-LEN) "'"
            UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
    ELSE
        IF WS-CONTENT = "--enable"
            MOVE "Y" TO RL-ENABLED(WS-RULE)
        ELSE
            MOVE "N" TO RL-ENABLED(WS-RULE)
        END-IF
    END-IF.

SET-FAIL-ON.
    EVALUATE WS-ARG
        WHEN "error"    MOVE "E" TO WS-FAIL-ON
        WHEN "warning"  MOVE "W" TO WS-FAIL-ON
        WHEN "note"     MOVE "N" TO WS-FAIL-ON
        WHEN "never"    MOVE "-" TO WS-FAIL-ON
        WHEN OTHER
            DISPLAY PLB-NAME ": invalid --fail-on level '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected error, warning, note, or never)"
                UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
    END-EVALUATE.

SET-REPORT.
    EVALUATE TRUE
        WHEN WS-COMMAND = "doc"
            DISPLAY PLB-NAME ": doc writes Markdown only"
                " (--report is not supported)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN WS-ARG = "json"
            MOVE WS-ARG TO WS-REPORT
        WHEN WS-ARG = "text" AND WS-COMMAND NOT = "graph"
            MOVE WS-ARG TO WS-REPORT
        WHEN WS-ARG = "sarif" AND WS-COMMAND NOT = "metrics"
             AND WS-COMMAND NOT = "summary"
             AND WS-COMMAND NOT = "rules" AND WS-COMMAND NOT = "inventory"
             AND WS-COMMAND NOT = "fields" AND WS-COMMAND NOT = "xref"
             AND WS-COMMAND NOT = "duplicates" AND WS-COMMAND NOT = "lineage"
             AND WS-COMMAND NOT = "crud"
             AND WS-COMMAND NOT = "layout"
            MOVE WS-ARG TO WS-REPORT
        WHEN (WS-ARG = "html" OR WS-ARG = "md" OR WS-ARG = "codeclimate"
              OR WS-ARG = "junit" OR WS-ARG = "checkstyle")
             AND WS-COMMAND = "check"
            MOVE WS-ARG TO WS-REPORT
        WHEN WS-ARG = "csv"
             AND (WS-COMMAND = "metrics" OR WS-COMMAND = "layout"
                  OR WS-COMMAND = "crud")
            MOVE WS-ARG TO WS-REPORT
        WHEN WS-ARG = "dot"
             AND (WS-COMMAND = "graph" OR WS-COMMAND = "lineage")
            MOVE WS-ARG TO WS-REPORT
        WHEN WS-ARG = "md" AND WS-COMMAND = "layout"
            MOVE WS-ARG TO WS-REPORT
        WHEN (WS-ARG = "md" OR WS-ARG = "csv") AND WS-COMMAND = "summary"
            MOVE WS-ARG TO WS-REPORT
        WHEN WS-COMMAND = "summary"
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected text, md, csv, or json)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN WS-COMMAND = "graph"
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected dot or json)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN WS-COMMAND = "metrics" OR WS-COMMAND = "crud"
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected text, json, or csv)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN WS-COMMAND = "layout"
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected text, json, csv, or md)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN WS-COMMAND = "lineage"
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected text, json, or dot)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN WS-COMMAND = "rules" OR WS-COMMAND = "inventory"
             OR WS-COMMAND = "fields" OR WS-COMMAND = "xref"
             OR WS-COMMAND = "duplicates"
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected text or json)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
        WHEN OTHER
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected text, json, sarif, html, md, codeclimate,"
                " junit, or checkstyle)"
                UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
    END-EVALUATE.

ADD-COPY-PATH.
    CALL "PLB-PP-ADD-PATH" USING PLB-PP-OPTIONS WS-ARG WS-PATH-STATUS
    IF WS-PATH-STATUS NOT = 0
        DISPLAY PLB-NAME ": too many -I directories (limit "
            PO-MAX-PATHS ")" UPON SYSERR
        MOVE 2 TO WS-EXIT-CODE
    END-IF.

SET-MODE.
    EVALUATE WS-ARG
        WHEN "fixed"
            MOVE "X" TO WS-MODE
        WHEN "free"
            MOVE "F" TO WS-MODE
        WHEN "auto"
            MOVE "A" TO WS-MODE
        WHEN "variable"
            MOVE "V" TO WS-MODE
        WHEN "xopen"
            MOVE "O" TO WS-MODE
        WHEN "terminal"
            MOVE "T" TO WS-MODE
        WHEN "cobolx"
            MOVE "C" TO WS-MODE
        WHEN "xcard"
            MOVE "K" TO WS-MODE
        WHEN "crt"
            MOVE "R" TO WS-MODE
        WHEN OTHER
            DISPLAY PLB-NAME ": invalid format '" WS-ARG(1:WS-ARG-LEN)
                "' (expected fixed, free, variable, xopen, terminal,"
                " cobolx, xcard, crt, or auto)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
    END-EVALUATE.

*> Read input WS-FILE-ID, noting what to release after it; its lines
*> are in memory when SF-LOADED(WS-FILE-ID) is "Y".
START-INPUT.
    MOVE SS-LINE-COUNT TO WS-MARK-LINES
    MOVE SS-HEAP-USED TO WS-MARK-HEAP
    CALL "PLB-SRC-ENSURE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
        WS-FILE-ID WS-STATUS.

*> Release the lines of the input and of the copybooks read for it.
END-INPUT.
    CALL "PLB-SRC-RELEASE" USING PLB-SOURCE-SET WS-MARK-LINES
        WS-MARK-HEAP.

*> Give every input an id, in order, without reading it yet.
ADD-INPUTS.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    PERFORM APPLY-DEFINES
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IP-COUNT
        CALL "PLB-SRC-ADD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            IP-PATH(WS-I) WS-MODE WS-FILE-ID
    END-PERFORM.

LOAD-INPUTS.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    PERFORM APPLY-DEFINES
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > IP-COUNT
        CALL "PLB-SRC-LOAD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            IP-PATH(WS-I) WS-MODE WS-FILE-ID WS-STATUS
    END-PERFORM.

*> One output line per source line:
*>     path:line: kind      format area content
DUMP-ONE-LINE.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    CALL "PLB-STR-LENGTH" USING SF-PATH(SL-FILE-ID(WS-I)) WS-PATH-LEN
    STRING SF-PATH(SL-FILE-ID(WS-I))(1:WS-PATH-LEN) ":"
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE SL-LINE-NO(WS-I) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) ": "
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR

    EVALUATE TRUE
        WHEN SL-SKIPPED(WS-I) = "Y"    MOVE "skipped"   TO WS-KIND-NAME
        WHEN SL-IS-CODE(WS-I)          MOVE "code"      TO WS-KIND-NAME
        WHEN SL-IS-BLANK(WS-I)         MOVE "blank"     TO WS-KIND-NAME
        WHEN SL-IS-COMMENT(WS-I)       MOVE "comment"   TO WS-KIND-NAME
        WHEN SL-IS-PAGE(WS-I)          MOVE "page"      TO WS-KIND-NAME
        WHEN SL-IS-DEBUG(WS-I)         MOVE "debug"     TO WS-KIND-NAME
        WHEN SL-IS-CONTINUATION(WS-I)  MOVE "cont"      TO WS-KIND-NAME
        WHEN SL-IS-DIRECTIVE(WS-I)     MOVE "directive" TO WS-KIND-NAME
        WHEN OTHER                     MOVE "?"         TO WS-KIND-NAME
    END-EVALUATE
    EVALUATE SL-FORMAT(WS-I)
        WHEN "F"   MOVE "free" TO WS-FORMAT-NAME
        WHEN "V"   MOVE "var" TO WS-FORMAT-NAME
        WHEN "O"   MOVE "xopen" TO WS-FORMAT-NAME
        WHEN "T"   MOVE "term" TO WS-FORMAT-NAME
        WHEN "C"   MOVE "cblx" TO WS-FORMAT-NAME
        WHEN "K"   MOVE "xcard" TO WS-FORMAT-NAME
        WHEN "R"   MOVE "crt" TO WS-FORMAT-NAME
        WHEN OTHER MOVE "fixed" TO WS-FORMAT-NAME
    END-EVALUATE
    STRING WS-KIND-NAME " " WS-FORMAT-NAME " "
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    IF SL-AREA-A(WS-I) = "Y"
        STRING "A " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING "- " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF

    CALL "PLB-SRC-LINE-CONTENT" USING PLB-SOURCE-SET WS-I
        WS-CONTENT WS-CONTENT-LEN
    IF WS-CONTENT-LEN > 0
        STRING WS-CONTENT(1:WS-CONTENT-LEN)
            DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    END-IF
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

*> One output line per token:
*>     path:line:column: kind     text
*> Alphanumeric literals are shown quoted, with any prefix, and with
*> embedded quotes doubled so the output reads as COBOL.
DUMP-ONE-TOKEN.
    MOVE SPACES TO WS-OUT
    MOVE 1 TO WS-PTR
    CALL "PLB-STR-LENGTH" USING SF-PATH(TK-FILE-ID(WS-I)) WS-PATH-LEN
    STRING SF-PATH(TK-FILE-ID(WS-I))(1:WS-PATH-LEN) ":"
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE TK-SRC-LINE(WS-I) TO WS-LINE-INDEX
    MOVE 0 TO WS-NUM
    IF WS-LINE-INDEX > 0
        MOVE SL-LINE-NO(WS-LINE-INDEX) TO WS-NUM
    END-IF
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) ":"
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    MOVE TK-COLUMN(WS-I) TO WS-NUM
    CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
    STRING WS-NUM-TEXT(1:WS-NUM-LEN) ": "
        DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR

    EVALUATE TRUE
        WHEN TK-IS-WORD(WS-I)      MOVE "word"      TO WS-KIND-NAME
        WHEN TK-IS-NUMBER(WS-I)    MOVE "number"    TO WS-KIND-NAME
        WHEN TK-IS-ALNUM(WS-I)     MOVE "alnum"     TO WS-KIND-NAME
        WHEN TK-IS-PICTURE(WS-I)   MOVE "picture"   TO WS-KIND-NAME
        WHEN TK-IS-PERIOD(WS-I)    MOVE "period"    TO WS-KIND-NAME
        WHEN TK-IS-LPAREN(WS-I)    MOVE "lparen"    TO WS-KIND-NAME
        WHEN TK-IS-RPAREN(WS-I)    MOVE "rparen"    TO WS-KIND-NAME
        WHEN TK-IS-COLON(WS-I)     MOVE "colon"     TO WS-KIND-NAME
        WHEN TK-IS-OPERATOR(WS-I)  MOVE "operator"  TO WS-KIND-NAME
        WHEN TK-IS-PSEUDO(WS-I)    MOVE "pseudo"    TO WS-KIND-NAME
        WHEN TK-IS-EOF(WS-I)       MOVE "eof"       TO WS-KIND-NAME
        WHEN OTHER                 MOVE "?"         TO WS-KIND-NAME
    END-EVALUATE
    STRING WS-KIND-NAME DELIMITED BY SIZE
        INTO WS-OUT WITH POINTER WS-PTR

    CALL "PLB-TOK-TEXT" USING PLB-TOKENS WS-I WS-TOKEN-TEXT
        WS-TOKEN-LEN
    IF TK-IS-ALNUM(WS-I)
        CALL "PLB-STR-LENGTH" USING TK-PREFIX(WS-I) WS-NUM-LEN
        IF WS-NUM-LEN > 0
            STRING TK-PREFIX(WS-I)(1:WS-NUM-LEN) DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
        STRING '"' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
        PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > WS-TOKEN-LEN
            IF WS-TOKEN-TEXT(WS-J:1) = '"'
                STRING '""' DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            ELSE
                STRING WS-TOKEN-TEXT(WS-J:1) DELIMITED BY SIZE
                    INTO WS-OUT WITH POINTER WS-PTR
            END-IF
        END-PERFORM
        STRING '"' DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        IF WS-TOKEN-LEN > 0
            STRING WS-TOKEN-TEXT(1:WS-TOKEN-LEN) DELIMITED BY SIZE
                INTO WS-OUT WITH POINTER WS-PTR
        END-IF
    END-IF
    *> Only literals can end in spaces, and they end in a quote here.
    CALL "PLB-STR-LENGTH" USING WS-OUT WS-OUT-LEN
    DISPLAY WS-OUT(1:WS-OUT-LEN).

*> Diagnostics go to standard error; any error makes the exit code 1.
REPORT-DIAGNOSTICS.
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > DG-COUNT
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET DG-FILE-ID(WS-I)
            WS-PATH
        CALL "PLB-DIAG-FORMAT" USING PLB-DIAGNOSTICS WS-I WS-PATH
            WS-OUT WS-OUT-LEN
        DISPLAY WS-OUT(1:WS-OUT-LEN) UPON SYSERR
    END-PERFORM
    IF DG-DROPPED > 0
        MOVE DG-DROPPED TO WS-NUM
        CALL "PLB-STR-FROM-INT" USING WS-NUM WS-NUM-TEXT WS-NUM-LEN
        DISPLAY PLB-NAME ": " WS-NUM-TEXT(1:WS-NUM-LEN)
            " more diagnostics not shown" UPON SYSERR
    END-IF
    IF DG-ERRORS > 0
        MOVE 1 TO WS-EXIT-CODE
    END-IF.
END PROGRAM PLUMBLINE.
