*> ---------------------------------------------------------------
*> plbparse: parser driver, identification and environment divisions.
*>
*> PLB-PARSE builds a syntax tree (copy/plbast.cpy) from the expanded
*> token stream of one source file. The parser is hand-written and
*> uses no recursion: nested programs are tracked on a program stack,
*> data entries on a level stack (plbpdata), and statement scopes on
*> a context stack (plbpproc).
*>
*> It is deliberately lenient. Clauses and statement operands it does
*> not model are kept as token ranges, and a construct it cannot parse
*> becomes an ERR node while parsing resumes after the next period.
*>
*> Diagnostic codes raised in this file:
*>   PS001  error    text outside any division or paragraph
*>   PS009  error    syntax tree full
*>   PS010  error    END PROGRAM names a different program
*>   PS011  warning  nested program not closed by END PROGRAM
*> ---------------------------------------------------------------

*> PLB-PX-TOKEN: fill VIEW for token INDEX. Past the end of the table
*> the view is an end-of-file token.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-TOKEN.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
COPY "plbptok.cpy".
PROCEDURE DIVISION USING PLB-TOKENS LK-INDEX PLB-PX-VIEW.
    MOVE SPACES TO PX-TEXT
    MOVE SPACE TO PX-KW
    IF LK-INDEX < 1 OR LK-INDEX > TK-COUNT
        MOVE "E" TO PX-KIND
        GOBACK
    END-IF
    MOVE TK-KIND(LK-INDEX) TO PX-KIND
    *> An alphanumeric literal's text starts with a quote so that no
    *> literal value ("ELSE", "USAGE") can pass for a keyword.
    IF TK-IS-ALNUM(LK-INDEX)
        MOVE '"' TO PX-TEXT
        IF TK-TEXT-LEN(LK-INDEX) > 0
            MOVE TK-TEXT(TK-TEXT-OFF(LK-INDEX):TK-TEXT-LEN(LK-INDEX))
                TO PX-TEXT(2:)
        END-IF
        GOBACK
    END-IF
    IF TK-TEXT-LEN(LK-INDEX) > 0
        MOVE TK-TEXT(TK-TEXT-OFF(LK-INDEX):TK-TEXT-LEN(LK-INDEX))
            TO PX-TEXT
    END-IF
    IF TK-IS-WORD(LK-INDEX)
        MOVE TK-KEYWORD(LK-INDEX) TO PX-KW
    END-IF
    GOBACK.
END PROGRAM PLB-PX-TOKEN.

*> PLB-PX-DIAG: report a diagnostic at token INDEX.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-DIAG.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-FILE-ID              PIC 9(4) COMP-5.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-SEVERITY             PIC X.
01  LK-CODE                 PIC X ANY LENGTH.
01  LK-MESSAGE              PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        LK-INDEX LK-SEVERITY LK-CODE LK-MESSAGE.
    MOVE 0 TO LS-FILE-ID LS-LINE LS-COLUMN
    IF LK-INDEX >= 1 AND LK-INDEX <= TK-COUNT
        MOVE TK-FILE-ID(LK-INDEX) TO LS-FILE-ID
        IF TK-SRC-LINE(LK-INDEX) > 0
            MOVE SL-LINE-NO(TK-SRC-LINE(LK-INDEX)) TO LS-LINE
        END-IF
        MOVE TK-COLUMN(LK-INDEX) TO LS-COLUMN
    END-IF
    CALL "PLB-DIAG-ADD" USING PLB-DIAGNOSTICS LK-SEVERITY LK-CODE
        LS-FILE-ID LS-LINE LS-COLUMN LK-MESSAGE
    GOBACK.
END PROGRAM PLB-PX-DIAG.

*> PLB-PX-SKIP-PERIOD: move PS-POS past the next period, or to the
*> end-of-file token if there is none.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-SKIP-PERIOD.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbpst.cpy".
PROCEDURE DIVISION USING PLB-TOKENS PLB-PARSE-STATE.
    PERFORM UNTIL PS-POS >= PS-END
        IF TK-IS-PERIOD(PS-POS)
            ADD 1 TO PS-POS
            EXIT PERFORM
        END-IF
        ADD 1 TO PS-POS
    END-PERFORM
    GOBACK.
END PROGRAM PLB-PX-SKIP-PERIOD.

*> PLB-PX-IS-HEADER: RESULT receives the division named at token
*> INDEX when it starts "<name> DIVISION" (IDENTIFICATION, ID,
*> ENVIRONMENT, DATA, PROCEDURE), "PROGRAM-ID" for "PROGRAM-ID." or
*> "FUNCTION-ID.", which start a program when the IDENTIFICATION
*> DIVISION header is left out (COBOL 2002 made it optional), "END"
*> for "END PROGRAM" and similar ends of a compilation unit, or
*> spaces.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-IS-HEADER.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-NEXT                 PIC 9(9) COMP-5.
COPY "plbptok.cpy".
01  LS-FIRST                PIC X(31).
LINKAGE SECTION.
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-RESULT               PIC X(16).
PROCEDURE DIVISION USING PLB-TOKENS LK-INDEX LK-RESULT.
    MOVE SPACES TO LK-RESULT
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS LK-INDEX PLB-PX-VIEW
    IF PX-KIND NOT = "W"
        GOBACK
    END-IF
    MOVE PX-TEXT TO LS-FIRST
    COMPUTE LS-NEXT = LK-INDEX + 1
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS LS-NEXT PLB-PX-VIEW
    EVALUATE LS-FIRST
        WHEN "IDENTIFICATION"
        WHEN "ID"
            IF PX-TEXT = "DIVISION"
                MOVE "IDENTIFICATION" TO LK-RESULT
            END-IF
        WHEN "ENVIRONMENT"
        WHEN "DATA"
        WHEN "PROCEDURE"
            IF PX-TEXT = "DIVISION"
                MOVE LS-FIRST TO LK-RESULT
            END-IF
        WHEN "PROGRAM-ID"
        WHEN "FUNCTION-ID"
            IF PX-KIND = "."
                MOVE "PROGRAM-ID" TO LK-RESULT
            END-IF
        WHEN "END"
            IF PX-TEXT = "PROGRAM" OR PX-TEXT = "FUNCTION"
               OR PX-TEXT = "CLASS" OR PX-TEXT = "METHOD"
                MOVE "END" TO LK-RESULT
            END-IF
    END-EVALUATE
    GOBACK.
END PROGRAM PLB-PX-IS-HEADER.

*> PLB-PARSE: parse the expanded tokens in TOKENS into AST.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PARSE.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  PG-MAX                      VALUE 64.
01  WS-PROGRAMS.
    05  WS-PROG-DEPTH       PIC 9(4) COMP-5.
    05  WS-PROG             PIC 9(9) COMP-5 OCCURS PG-MAX TIMES.
    *> "Y" once the program has had a division.
    05  WS-PROG-STARTED     PIC X OCCURS PG-MAX TIMES.
LOCAL-STORAGE SECTION.
COPY "plbpst.cpy".
COPY "plbptok.cpy".
01  LS-HEADER               PIC X(16).
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-PARENT               PIC 9(9) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-SAME                 PIC X.
01  LS-END-NAME             PIC X(64).
01  LS-PROGRAM-NAME         PIC X(64).
01  LS-NAME-LEN             PIC 9(9) COMP-5.
01  LS-DETAIL               PIC X(16).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST.
    CALL "PLB-AST-INIT" USING PLB-AST
    MOVE 0 TO WS-PROG-DEPTH PS-PROGRAM PS-DIVISION
    MOVE "N" TO PS-FULL
    MOVE 1 TO PS-POS
    MOVE TK-COUNT TO PS-END
    CALL "PLB-AST-ADD" USING PLB-AST LS-ZERO "UNIT" " " PS-POS PS-UNIT
    IF TK-COUNT = 0
        GOBACK
    END-IF
    MOVE PS-END TO ND-TOK-LAST(PS-UNIT)

    PERFORM UNTIL PS-POS >= PS-END OR PS-FULL = "Y"
        CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        EVALUATE TRUE
            WHEN LS-HEADER = "IDENTIFICATION"
                PERFORM START-PROGRAM
                PERFORM START-DIVISION
                PERFORM SKIP-HEADER
                CALL "PLB-PX-IDENT" USING PLB-SOURCE-SET
                    PLB-DIAGNOSTICS PLB-TOKENS PLB-AST PLB-PARSE-STATE
            WHEN PX-TEXT = "PROGRAM-ID" OR PX-TEXT = "FUNCTION-ID"
                *> A program may start without IDENTIFICATION DIVISION.
                PERFORM START-PROGRAM
                MOVE "IDENTIFICATION" TO LS-HEADER
                PERFORM START-DIVISION
                CALL "PLB-PX-IDENT" USING PLB-SOURCE-SET
                    PLB-DIAGNOSTICS PLB-TOKENS PLB-AST PLB-PARSE-STATE
            WHEN LS-HEADER = "ENVIRONMENT"
                PERFORM ENSURE-PROGRAM
                PERFORM START-DIVISION
                PERFORM SKIP-HEADER
                CALL "PLB-PX-ENV" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                    PLB-TOKENS PLB-AST PLB-PARSE-STATE
            WHEN LS-HEADER = "DATA"
                PERFORM ENSURE-PROGRAM
                PERFORM START-DIVISION
                PERFORM SKIP-HEADER
                CALL "PLB-PX-DATA" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                    PLB-TOKENS PLB-AST PLB-PARSE-STATE
            WHEN LS-HEADER = "PROCEDURE"
                PERFORM ENSURE-PROGRAM
                PERFORM START-DIVISION
                CALL "PLB-PX-PROC" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                    PLB-TOKENS PLB-AST PLB-PARSE-STATE
            WHEN LS-HEADER = "END"
                PERFORM END-PROGRAM
            WHEN OTHER
                PERFORM UNEXPECTED
        END-EVALUATE
        PERFORM CLOSE-DIVISION
    END-PERFORM

    *> Programs still open at the end of the file end there. Only
    *> nested programs are required to have END PROGRAM.
    PERFORM UNTIL WS-PROG-DEPTH = 0
        MOVE WS-PROG(WS-PROG-DEPTH) TO LS-NODE
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-END - 1
        IF WS-PROG-DEPTH > 1
            MOVE ND-TOK-FIRST(LS-NODE) TO LS-I
            CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                PLB-TOKENS LS-I "W" "PS011"
                "nested program has no END PROGRAM"
        END-IF
        SUBTRACT 1 FROM WS-PROG-DEPTH
    END-PERFORM
    IF PS-FULL = "Y"
        CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
            PLB-TOKENS PS-POS "E" "PS009"
            "program too large: syntax tree is full"
    END-IF
    GOBACK.

*> A new program is nested in the current one if that program has
*> already had a division; otherwise it is a sibling at the top.
START-PROGRAM.
    MOVE PS-UNIT TO LS-PARENT
    IF WS-PROG-DEPTH > 0
        IF WS-PROG-STARTED(WS-PROG-DEPTH) = "Y"
            MOVE WS-PROG(WS-PROG-DEPTH) TO LS-PARENT
        ELSE
            *> An empty program header followed by another: replace it.
            SUBTRACT 1 FROM WS-PROG-DEPTH
            IF WS-PROG-DEPTH > 0
                MOVE WS-PROG(WS-PROG-DEPTH) TO LS-PARENT
            END-IF
        END-IF
    END-IF
    IF WS-PROG-DEPTH >= PG-MAX
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "PROG" "PROGRAM" PS-POS
        LS-NODE
    PERFORM CHECK-NODE
    ADD 1 TO WS-PROG-DEPTH
    MOVE LS-NODE TO WS-PROG(WS-PROG-DEPTH)
    MOVE "N" TO WS-PROG-STARTED(WS-PROG-DEPTH)
    MOVE LS-NODE TO PS-PROGRAM.

*> Divisions outside any program get an unnamed program.
ENSURE-PROGRAM.
    IF WS-PROG-DEPTH = 0
        PERFORM START-PROGRAM
    END-IF.

START-DIVISION.
    MOVE "Y" TO WS-PROG-STARTED(WS-PROG-DEPTH)
    MOVE LS-HEADER TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST PS-PROGRAM "DIVN" LS-DETAIL PS-POS
        PS-DIVISION
    MOVE PS-DIVISION TO LS-NODE
    PERFORM CHECK-NODE.

*> The division just parsed ends before the current token.
CLOSE-DIVISION.
    IF PS-DIVISION > 0 AND PS-POS > ND-TOK-FIRST(PS-DIVISION)
        COMPUTE ND-TOK-LAST(PS-DIVISION) = PS-POS - 1
    END-IF
    MOVE 0 TO PS-DIVISION.

*> Skip "<name> DIVISION ." (the period is optional here).
SKIP-HEADER.
    ADD 2 TO PS-POS
    IF PS-POS < PS-END
        IF TK-IS-PERIOD(PS-POS)
            ADD 1 TO PS-POS
        END-IF
    END-IF.

*> END PROGRAM name . closes the innermost open program.
END-PROGRAM.
    IF WS-PROG-DEPTH = 0
        PERFORM UNEXPECTED
        EXIT PARAGRAPH
    END-IF
    MOVE WS-PROG(WS-PROG-DEPTH) TO LS-NODE
    COMPUTE LS-I = PS-POS + 2
    IF LS-I < PS-END AND ND-NAME(LS-NODE) > 0
        *> A name may be written as a word or as a literal, here or in
        *> PROGRAM-ID ("callee"); case and the spaces around a literal
        *> name do not matter.
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-END-NAME LS-NAME-LEN
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-NODE)
            LS-PROGRAM-NAME LS-NAME-LEN
        IF FUNCTION UPPER-CASE(FUNCTION TRIM(LS-END-NAME))
           = FUNCTION UPPER-CASE(FUNCTION TRIM(LS-PROGRAM-NAME))
            MOVE "Y" TO LS-SAME
        ELSE
            MOVE "N" TO LS-SAME
        END-IF
        IF LS-SAME = "N"
            CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                PLB-TOKENS LS-I "E" "PS010"
                "END PROGRAM does not name the program it ends"
        END-IF
    END-IF
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE
    COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    SUBTRACT 1 FROM WS-PROG-DEPTH
    IF WS-PROG-DEPTH > 0
        MOVE WS-PROG(WS-PROG-DEPTH) TO PS-PROGRAM
    ELSE
        MOVE 0 TO PS-PROGRAM
    END-IF.

UNEXPECTED.
    MOVE PS-UNIT TO LS-PARENT
    IF PS-PROGRAM > 0
        MOVE PS-PROGRAM TO LS-PARENT
    END-IF
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "ERR " " " PS-POS LS-NODE
    PERFORM CHECK-NODE
    CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PS-POS "E" "PS001" "text outside any division or paragraph"
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE
    IF LS-NODE > 0
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    END-IF.

CHECK-NODE.
    IF LS-NODE = 0
        MOVE "Y" TO PS-FULL
    END-IF.
END PROGRAM PLB-PARSE.

*> PLB-PX-IDENT: the paragraphs of the identification division, up to
*> the next division header or END PROGRAM.
*>   PROGRAM-ID. name [AS literal] [IS COMMON|INITIAL|RECURSIVE ...].
*>   FUNCTION-ID. name ...
*>   AUTHOR. INSTALLATION. DATE-WRITTEN. DATE-COMPILED. SECURITY.
*>   REMARKS.  (obsolete; their text runs to the next paragraph)
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-IDENT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
COPY "plbptok.cpy".
01  LS-HEADER               PIC X(16).
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DETAIL               PIC X(16).
01  LS-DONE                 PIC X VALUE "N".
*> "Y" once the division's PROGRAM-ID is read: another one starts the
*> next program.
01  LS-HAS-ID               PIC X VALUE "N".
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbpst.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST PLB-PARSE-STATE.
    PERFORM UNTIL PS-POS >= PS-END OR LS-DONE = "Y" OR PS-FULL = "Y"
        CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
        IF LS-HEADER = "PROGRAM-ID" AND LS-HAS-ID = "N"
            MOVE "Y" TO LS-HAS-ID
            MOVE SPACES TO LS-HEADER
        END-IF
        IF LS-HEADER NOT = SPACES
            EXIT PERFORM
        END-IF
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        EVALUATE PX-TEXT
            WHEN "PROGRAM-ID"
            WHEN "FUNCTION-ID"
                PERFORM PROGRAM-ID-PARAGRAPH
            WHEN "AUTHOR"
            WHEN "INSTALLATION"
            WHEN "DATE-WRITTEN"
            WHEN "DATE-COMPILED"
            WHEN "SECURITY"
            WHEN "REMARKS"
            *> COBOL 2014: DEFAULT ROUNDED MODE, ENTRY-CONVENTION, ...
            WHEN "OPTIONS"
                PERFORM COMMENT-PARAGRAPH
            WHEN OTHER
                CALL "PLB-AST-ADD" USING PLB-AST PS-DIVISION "ERR " " "
                    PS-POS LS-NODE
                CALL "PLB-PX-DIAG" USING PLB-SOURCE-SET PLB-DIAGNOSTICS
                    PLB-TOKENS PS-POS "E" "PS001"
                    "unexpected text in IDENTIFICATION DIVISION"
                CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS
                    PLB-PARSE-STATE
                PERFORM CLOSE-NODE
        END-EVALUATE
    END-PERFORM
    GOBACK.

PROGRAM-ID-PARAGRAPH.
    MOVE PX-TEXT TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST PS-DIVISION "IDPA" LS-DETAIL
        PS-POS LS-NODE
    IF LS-NODE = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    IF PX-TEXT = "FUNCTION-ID"
        MOVE "FUNCTION" TO ND-DETAIL(PS-PROGRAM)
    END-IF
    ADD 1 TO PS-POS
    IF TK-IS-PERIOD(PS-POS)
        ADD 1 TO PS-POS
    END-IF
    IF TK-IS-WORD(PS-POS) OR TK-IS-ALNUM(PS-POS)
        MOVE PS-POS TO ND-NAME(PS-PROGRAM) ND-NAME(LS-NODE)
    END-IF
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE
    PERFORM CLOSE-NODE.

*> A comment entry is free text: it runs to the next identification
*> paragraph or division header, whatever periods it contains. The
*> clauses of OPTIONS are kept the same way: no rule reads them yet.
COMMENT-PARAGRAPH.
    MOVE PX-TEXT TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST PS-DIVISION "IDPA" LS-DETAIL
        PS-POS LS-NODE
    IF LS-NODE = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PS-POS
    PERFORM UNTIL PS-POS >= PS-END
        CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
        IF LS-HEADER NOT = SPACES
            EXIT PERFORM
        END-IF
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        IF PX-TEXT = "PROGRAM-ID" OR "FUNCTION-ID" OR "AUTHOR"
                OR "INSTALLATION" OR "DATE-WRITTEN" OR "DATE-COMPILED"
                OR "SECURITY" OR "REMARKS" OR "OPTIONS"
            EXIT PERFORM
        END-IF
        ADD 1 TO PS-POS
    END-PERFORM
    PERFORM CLOSE-NODE.

CLOSE-NODE.
    IF LS-NODE > 0 AND PS-POS > ND-TOK-FIRST(LS-NODE)
        COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1
    END-IF.
END PROGRAM PLB-PX-IDENT.

*> PLB-PX-ENV: the environment division. Sections and paragraphs are
*> kept as nodes with their token ranges; each SELECT entry of
*> FILE-CONTROL becomes a SELE node named after its file.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-PX-ENV.
DATA DIVISION.
LOCAL-STORAGE SECTION.
COPY "plbptok.cpy".
01  LS-HEADER               PIC X(16).
01  LS-SECTION              PIC 9(9) COMP-5.
01  LS-PARAGRAPH            PIC 9(9) COMP-5.
01  LS-PARENT               PIC 9(9) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DETAIL               PIC X(16).
01  LS-NEXT                 PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbpst.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST PLB-PARSE-STATE.
    MOVE 0 TO LS-SECTION LS-PARAGRAPH
    PERFORM UNTIL PS-POS >= PS-END OR PS-FULL = "Y"
        CALL "PLB-PX-IS-HEADER" USING PLB-TOKENS PS-POS LS-HEADER
        IF LS-HEADER NOT = SPACES
            EXIT PERFORM
        END-IF
        CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
        COMPUTE LS-NEXT = PS-POS + 1
        EVALUATE TRUE
            WHEN (PX-TEXT = "CONFIGURATION" OR PX-TEXT = "INPUT-OUTPUT")
                 AND TK-IS-WORD(LS-NEXT)
                PERFORM ENV-SECTION
            WHEN PX-TEXT = "SOURCE-COMPUTER" OR "OBJECT-COMPUTER"
                    OR "SPECIAL-NAMES" OR "REPOSITORY" OR "FILE-CONTROL"
                    OR "I-O-CONTROL"
                PERFORM ENV-PARAGRAPH
            WHEN PX-TEXT = "SELECT"
                PERFORM SELECT-ENTRY
            WHEN OTHER
                *> Paragraph text such as SPECIAL-NAMES clauses: a
                *> sentence at a time, inside the current paragraph.
                CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS
                    PLB-PARSE-STATE
        END-EVALUATE
        PERFORM EXTEND-OPEN-NODES
    END-PERFORM
    GOBACK.

ENV-SECTION.
    MOVE PX-TEXT TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST PS-DIVISION "SECT" LS-DETAIL
        PS-POS LS-SECTION
    MOVE 0 TO LS-PARAGRAPH
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE.

ENV-PARAGRAPH.
    MOVE PS-DIVISION TO LS-PARENT
    IF LS-SECTION > 0
        MOVE LS-SECTION TO LS-PARENT
    END-IF
    MOVE PX-TEXT TO LS-DETAIL
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "OTHR" LS-DETAIL PS-POS
        LS-PARAGRAPH
    ADD 1 TO PS-POS
    IF TK-IS-PERIOD(PS-POS)
        ADD 1 TO PS-POS
    END-IF.

*> SELECT [OPTIONAL] file-name ASSIGN ... .
SELECT-ENTRY.
    MOVE PS-DIVISION TO LS-PARENT
    IF LS-PARAGRAPH > 0
        MOVE LS-PARAGRAPH TO LS-PARENT
    END-IF
    CALL "PLB-AST-ADD" USING PLB-AST LS-PARENT "SELE" " " PS-POS
        LS-NODE
    IF LS-NODE = 0
        MOVE "Y" TO PS-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO PS-POS
    CALL "PLB-PX-TOKEN" USING PLB-TOKENS PS-POS PLB-PX-VIEW
    IF PX-TEXT = "OPTIONAL"
        ADD 1 TO PS-POS
    END-IF
    IF TK-IS-WORD(PS-POS)
        MOVE PS-POS TO ND-NAME(LS-NODE)
    END-IF
    CALL "PLB-PX-SKIP-PERIOD" USING PLB-TOKENS PLB-PARSE-STATE
    COMPUTE ND-TOK-LAST(LS-NODE) = PS-POS - 1.

*> The open section and paragraph extend to the current position.
EXTEND-OPEN-NODES.
    IF LS-SECTION > 0
        COMPUTE ND-TOK-LAST(LS-SECTION) = PS-POS - 1
    END-IF
    IF LS-PARAGRAPH > 0
        COMPUTE ND-TOK-LAST(LS-PARAGRAPH) = PS-POS - 1
    END-IF.
END PROGRAM PLB-PX-ENV.
