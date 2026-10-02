*> ---------------------------------------------------------------
*> plumbline: command-line entry point.
*>
*>   plumbline --help | --version
*>   plumbline check [-I DIR]... [--format ...] [--debug]
*>                   [--enable RULE]... [--disable RULE]...
*>                   [--fail-on error|warning|note|never]
*>                   [--report text|json|sarif] FILE...
*>   plumbline dump lines  [--format fixed|free|auto] FILE...
*>   plumbline dump tokens [--format fixed|free|auto] [--debug] FILE...
*>   plumbline dump expanded [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump ast [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump symbols [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump flow [-I DIR]... [--format ...] [--debug] FILE...
*>   plumbline dump refs [-I DIR]... [--format ...] [--debug] FILE...
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
COPY "plbref.cpy".
78  MAX-INPUTS                  VALUE 256.
01  WS-ARG-COUNT            PIC 9(4).
01  WS-ARG-INDEX            PIC 9(4).
01  WS-ARG                  PIC X(1024).
01  WS-ARG-LEN              PIC 9(9) COMP-5.
01  WS-EXIT-CODE            PIC 9(4) VALUE 0.
01  WS-MODE                 PIC X VALUE "A".
01  WS-DEBUG                PIC X VALUE "N".
01  WS-DUMP-TARGET          PIC X(8).
01  WS-INPUT-COUNT          PIC 9(4) COMP-5 VALUE 0.
01  WS-INPUTS.
    05  WS-INPUT            PIC X(512) OCCURS MAX-INPUTS TIMES.
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
01  WS-U                    PIC 9(9) COMP-5.
01  WS-E                    PIC 9(9) COMP-5.
01  WS-RULE                 PIC 9(4) COMP-5.
01  WS-FAIL-ON              PIC X VALUE "W".
01  WS-FAILING              PIC 9(9) COMP-5.
01  WS-REPORT               PIC X(5) VALUE "text".

PROCEDURE DIVISION.
MAIN-LOGIC.
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
    DISPLAY "       plumbline dump lines [--format FORMAT] FILE..."
    DISPLAY "       plumbline dump tokens [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump expanded [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump ast [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump symbols [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump flow [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "       plumbline dump refs [-I DIR]... [--format FORMAT] [--debug] FILE..."
    DISPLAY "Static analysis for COBOL programs."
    DISPLAY " "
    DISPLAY "Options:"
    DISPLAY "  -h, --help       show this help and exit"
    DISPLAY "  -V, --version    show version information and exit"
    DISPLAY " "
    DISPLAY "Commands:"
    DISPLAY "  check            analyze programs and report findings"
    DISPLAY "  dump lines       show how each source line was read"
    DISPLAY "  dump tokens      show the tokens of each source file"
    DISPLAY "  dump expanded    show the tokens after COPY and REPLACE"
    DISPLAY "  dump ast         show the syntax tree"
    DISPLAY "  dump symbols     show data items with sizes and offsets"
    DISPLAY "  dump flow        show paragraphs, sections, and control flow"
    DISPLAY "  dump refs        show what each name in the procedures refers to"
    DISPLAY " "
    DISPLAY "Command options:"
    DISPLAY "  --format FORMAT  reference format: fixed, free, or auto"
    DISPLAY "                   (default auto)"
    DISPLAY "  --debug          treat debugging lines as code"
    DISPLAY "  -I DIR           search DIR for copybooks (repeatable)"
    DISPLAY " "
    DISPLAY "Check options:"
    DISPLAY "  --enable RULE    enable a rule (id or name; repeatable)"
    DISPLAY "  --disable RULE   disable a rule (id or name; repeatable)"
    DISPLAY "  --fail-on LEVEL  exit 1 on findings at or above LEVEL:"
    DISPLAY "                   error, warning (default), note, never"
    DISPLAY "  --report FORMAT  text (default), json, or sarif".

*> check --------------------------------------------------------

CHECK-COMMAND.
    PERFORM PARSE-INPUT-ARGS
    IF WS-EXIT-CODE NOT = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM LOAD-INPUTS
    CALL "PLB-FIND-INIT" USING PLB-FINDINGS
    MOVE SS-FILE-COUNT TO WS-MAIN-FILES
    MOVE WS-MODE TO PO-FORMAT
    MOVE WS-DEBUG TO PO-DEBUG
    PERFORM VARYING WS-FILE-ID FROM 1 BY 1
            UNTIL WS-FILE-ID > WS-MAIN-FILES
        PERFORM ANALYZE-FILE
        CALL "PLB-CHECK-RUN" USING PLB-SOURCE-SET PLB-TOKENS PLB-AST
            PLB-SYMBOLS PLB-FLOW PLB-REFS PLB-RULES PLB-FINDINGS
    END-PERFORM
    CALL "PLB-FIND-SUPPRESS" USING PLB-SOURCE-SET PLB-RULES PLB-FINDINGS
    CALL "PLB-FIND-SORT" USING PLB-FINDINGS
    EVALUATE WS-REPORT
        WHEN "json"
            CALL "PLB-REPORT-JSON" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                PLB-RULES PLB-FINDINGS
        WHEN "sarif"
            CALL "PLB-REPORT-SARIF" USING PLB-SOURCE-SET
                PLB-DIAGNOSTICS PLB-RULES PLB-FINDINGS
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
       AND WS-ARG NOT = "refs"
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
    IF FE-KIND(WS-E) = "G"
        STRING "  go " DELIMITED BY SIZE INTO WS-OUT WITH POINTER WS-PTR
    ELSE
        STRING "  perform " DELIMITED BY SIZE
            INTO WS-OUT WITH POINTER WS-PTR
    END-IF
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
    CALL "PLB-PP-INIT-OPTIONS" USING PLB-PP-OPTIONS
    CALL "PLB-RULES-INIT" USING PLB-RULES
    PERFORM UNTIL WS-ARG-INDEX > WS-ARG-COUNT OR WS-EXIT-CODE NOT = 0
        PERFORM NEXT-ARG
        EVALUATE TRUE
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
            WHEN WS-INPUT-COUNT >= MAX-INPUTS
                DISPLAY PLB-NAME ": too many input files (limit "
                    MAX-INPUTS ")" UPON SYSERR
                MOVE 2 TO WS-EXIT-CODE
            WHEN WS-ARG-LEN > LENGTH OF WS-INPUT(1)
                DISPLAY PLB-NAME ": file name longer than 512 characters: "
                    WS-ARG(1:60) "..." UPON SYSERR
                MOVE 2 TO WS-EXIT-CODE
            WHEN OTHER
                ADD 1 TO WS-INPUT-COUNT
                MOVE WS-ARG TO WS-INPUT(WS-INPUT-COUNT)
        END-EVALUATE
    END-PERFORM
    IF WS-EXIT-CODE = 0 AND WS-INPUT-COUNT = 0
        DISPLAY PLB-NAME ": no input files" UPON SYSERR
        PERFORM SUGGEST-HELP
    END-IF.

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
    EVALUATE WS-ARG
        WHEN "text"
        WHEN "json"
        WHEN "sarif"
            MOVE WS-ARG TO WS-REPORT
        WHEN OTHER
            DISPLAY PLB-NAME ": invalid --report format '"
                WS-ARG(1:WS-ARG-LEN)
                "' (expected text, json, or sarif)" UPON SYSERR
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
        WHEN OTHER
            DISPLAY PLB-NAME ": invalid format '" WS-ARG(1:WS-ARG-LEN)
                "' (expected fixed, free, or auto)" UPON SYSERR
            MOVE 2 TO WS-EXIT-CODE
    END-EVALUATE.

LOAD-INPUTS.
    CALL "PLB-SRC-INIT" USING PLB-SOURCE-SET
    CALL "PLB-DIAG-INIT" USING PLB-DIAGNOSTICS
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-INPUT-COUNT
        CALL "PLB-SRC-LOAD" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            WS-INPUT(WS-I) WS-MODE WS-FILE-ID WS-STATUS
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
        WHEN SL-IS-CODE(WS-I)          MOVE "code"      TO WS-KIND-NAME
        WHEN SL-IS-BLANK(WS-I)         MOVE "blank"     TO WS-KIND-NAME
        WHEN SL-IS-COMMENT(WS-I)       MOVE "comment"   TO WS-KIND-NAME
        WHEN SL-IS-PAGE(WS-I)          MOVE "page"      TO WS-KIND-NAME
        WHEN SL-IS-DEBUG(WS-I)         MOVE "debug"     TO WS-KIND-NAME
        WHEN SL-IS-CONTINUATION(WS-I)  MOVE "cont"      TO WS-KIND-NAME
        WHEN SL-IS-DIRECTIVE(WS-I)     MOVE "directive" TO WS-KIND-NAME
        WHEN OTHER                     MOVE "?"         TO WS-KIND-NAME
    END-EVALUATE
    IF SL-FORMAT(WS-I) = "F"
        MOVE "free" TO WS-FORMAT-NAME
    ELSE
        MOVE "fixed" TO WS-FORMAT-NAME
    END-IF
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
