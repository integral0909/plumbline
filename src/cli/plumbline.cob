*> ---------------------------------------------------------------
*> plumbline: command-line entry point.
*>
*>   plumbline --help | --version
*>   plumbline dump lines  [--format fixed|free|auto] FILE...
*>   plumbline dump tokens [--format fixed|free|auto] [--debug] FILE...
*>
*> Exit codes:
*>   0  success
*>   1  the input had errors (e.g. a file could not be read)
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
    DISPLAY "       plumbline dump lines [--format FORMAT] FILE..."
    DISPLAY "       plumbline dump tokens [--format FORMAT] [--debug] FILE..."
    DISPLAY "Static analysis for COBOL programs."
    DISPLAY " "
    DISPLAY "Options:"
    DISPLAY "  -h, --help       show this help and exit"
    DISPLAY "  -V, --version    show version information and exit"
    DISPLAY " "
    DISPLAY "Commands:"
    DISPLAY "  dump lines       show how each source line was read"
    DISPLAY "  dump tokens      show the tokens of each source file"
    DISPLAY " "
    DISPLAY "Command options:"
    DISPLAY "  --format FORMAT  reference format: fixed, free, or auto"
    DISPLAY "                   (default auto)"
    DISPLAY "  --debug          treat debugging lines as code".

*> dump ---------------------------------------------------------

DUMP-COMMAND.
    PERFORM NEXT-ARG
    MOVE WS-ARG TO WS-DUMP-TARGET
    IF WS-ARG NOT = "lines" AND WS-ARG NOT = "tokens"
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

    IF WS-DUMP-TARGET = "lines"
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > SS-LINE-COUNT
            PERFORM DUMP-ONE-LINE
        END-PERFORM
    ELSE
        CALL "PLB-LEX-INIT" USING PLB-TOKENS
        PERFORM VARYING WS-FILE-ID FROM 1 BY 1
                UNTIL WS-FILE-ID > SS-FILE-COUNT
            CALL "PLB-LEX-FILE" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                PLB-TOKENS WS-FILE-ID WS-DEBUG
        END-PERFORM
        PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > TK-COUNT
            PERFORM DUMP-ONE-TOKEN
        END-PERFORM
    END-IF
    PERFORM REPORT-DIAGNOSTICS.

*> Collect --format and file operands up to the end of the arguments.
PARSE-INPUT-ARGS.
    PERFORM UNTIL WS-ARG-INDEX > WS-ARG-COUNT OR WS-EXIT-CODE NOT = 0
        PERFORM NEXT-ARG
        EVALUATE TRUE
            WHEN WS-ARG = "--format"
                PERFORM NEXT-ARG
                PERFORM SET-MODE
            WHEN WS-ARG = "--debug"
                MOVE "Y" TO WS-DEBUG
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
            WHEN OTHER
                ADD 1 TO WS-INPUT-COUNT
                MOVE WS-ARG TO WS-INPUT(WS-INPUT-COUNT)
        END-EVALUATE
    END-PERFORM
    IF WS-EXIT-CODE = 0 AND WS-INPUT-COUNT = 0
        DISPLAY PLB-NAME ": no input files" UPON SYSERR
        PERFORM SUGGEST-HELP
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
