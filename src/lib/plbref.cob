*> ---------------------------------------------------------------
*> plbref: finding and resolving data references.
*>
*> PLB-REF-BUILD scans each procedure division for identifiers and
*> resolves every one (copy/plbref.cpy):
*>
*>   - a user-defined word that is not a procedure name (PERFORM or
*>     GO TO target, paragraph or section header), not an intrinsic
*>     function name (after FUNCTION), and not inside EXEC ... END-EXEC
*>     is an identifier;
*>   - "IN name" and "OF name" after it are qualifiers; a parenthesized
*>     group after it is a subscript list, or a reference modifier
*>     when it contains a colon;
*>   - the identifier resolves to the data items of its program (or
*>     GLOBAL items of a program containing it) with that name whose
*>     ancestors include each qualifier in order; a record in the file
*>     section may also be qualified by its file name;
*>   - a name that matches no data item may be a paragraph or section
*>     (as in SORT ... INPUT PROCEDURE P), or another kind of name
*>     declared in the environment division, an FD, or an INDEXED BY
*>     phrase; otherwise it is undefined.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-REF-BUILD.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  ON-MAX                      VALUE 20000.
*> Innermost statement of each token, and tokens that are not
*> identifiers even though they are user-defined words.
01  WS-TOKEN-STMT           PIC 9(9) COMP-5 OCCURS 500000 TIMES.
01  WS-TOKEN-SKIP           PIC X OCCURS 500000 TIMES.
*> Names that are not data items: files, mnemonic names, alphabets,
*> classes, indexes.
01  WS-OTHER-NAMES.
    05  WS-OTHER-COUNT      PIC 9(9) COMP-5.
    05  WS-OTHER            OCCURS 0 TO ON-MAX TIMES
                            DEPENDING ON WS-OTHER-COUNT
                            ASCENDING KEY IS ON-TEXT
                            INDEXED BY ON-IX.
        10  ON-TEXT         PIC X(31).
*> Names that embedded SQL and CICS declare for the program.
01  WS-SQLCA-ADDED          PIC X.
01  WS-EIB-ADDED            PIC X.
01  WS-DIB-ADDED            PIC X.
01  WS-SQLCA-NAMES.
    05  FILLER PIC X(31) VALUE "SQLCA".
    05  FILLER PIC X(31) VALUE "SQLCAID".
    05  FILLER PIC X(31) VALUE "SQLCABC".
    05  FILLER PIC X(31) VALUE "SQLCODE".
    05  FILLER PIC X(31) VALUE "SQLERRM".
    05  FILLER PIC X(31) VALUE "SQLERRML".
    05  FILLER PIC X(31) VALUE "SQLERRMC".
    05  FILLER PIC X(31) VALUE "SQLERRP".
    05  FILLER PIC X(31) VALUE "SQLERRD".
    05  FILLER PIC X(31) VALUE "SQLWARN".
    05  FILLER PIC X(31) VALUE "SQLWARN0".
    05  FILLER PIC X(31) VALUE "SQLWARN1".
    05  FILLER PIC X(31) VALUE "SQLWARN2".
    05  FILLER PIC X(31) VALUE "SQLWARN3".
    05  FILLER PIC X(31) VALUE "SQLWARN4".
    05  FILLER PIC X(31) VALUE "SQLWARN5".
    05  FILLER PIC X(31) VALUE "SQLWARN6".
    05  FILLER PIC X(31) VALUE "SQLWARN7".
    05  FILLER PIC X(31) VALUE "SQLSTATE".
    05  FILLER PIC X(31) VALUE "SQLEXT".
01  FILLER REDEFINES WS-SQLCA-NAMES.
    05  WS-SQLCA-NAME       PIC X(31) OCCURS 20 TIMES.
01  WS-EIB-NAMES.
    05  FILLER PIC X(31) VALUE "DFHEIBLK".
    05  FILLER PIC X(31) VALUE "EIBTIME".
    05  FILLER PIC X(31) VALUE "EIBDATE".
    05  FILLER PIC X(31) VALUE "EIBTRNID".
    05  FILLER PIC X(31) VALUE "EIBTASKN".
    05  FILLER PIC X(31) VALUE "EIBTRMID".
    05  FILLER PIC X(31) VALUE "EIBCPOSN".
    05  FILLER PIC X(31) VALUE "EIBCALEN".
    05  FILLER PIC X(31) VALUE "EIBAID".
    05  FILLER PIC X(31) VALUE "EIBFN".
    05  FILLER PIC X(31) VALUE "EIBRCODE".
    05  FILLER PIC X(31) VALUE "EIBDS".
    05  FILLER PIC X(31) VALUE "EIBREQID".
    05  FILLER PIC X(31) VALUE "EIBRSRCE".
    05  FILLER PIC X(31) VALUE "EIBSYNC".
    05  FILLER PIC X(31) VALUE "EIBFREE".
    05  FILLER PIC X(31) VALUE "EIBRECV".
    05  FILLER PIC X(31) VALUE "EIBATT".
    05  FILLER PIC X(31) VALUE "EIBEOC".
    05  FILLER PIC X(31) VALUE "EIBFMH".
    05  FILLER PIC X(31) VALUE "EIBCOMPL".
    05  FILLER PIC X(31) VALUE "EIBSIG".
    05  FILLER PIC X(31) VALUE "EIBCONF".
    05  FILLER PIC X(31) VALUE "EIBERR".
    05  FILLER PIC X(31) VALUE "EIBERRCD".
    05  FILLER PIC X(31) VALUE "EIBSYNRB".
    05  FILLER PIC X(31) VALUE "EIBNODAT".
    05  FILLER PIC X(31) VALUE "EIBRESP".
    05  FILLER PIC X(31) VALUE "EIBRESP2".
    05  FILLER PIC X(31) VALUE "EIBRLDBK".
    05  FILLER PIC X(31) VALUE "DFHCOMMAREA".
    05  FILLER PIC X(31) VALUE "DFHEIPTR".
    05  FILLER PIC X(31) VALUE "DFHEIBP".
01  FILLER REDEFINES WS-EIB-NAMES.
    05  WS-EIB-NAME         PIC X(31) OCCURS 33 TIMES.
*> Token ranges to scan for identifiers, with their programs: each
*> procedure division, and the clauses of report descriptions that
*> name data (SOURCE, SUM, TYPE CONTROL ..., CONTROL, PRESENT WHEN).
78  DV-MAX                  VALUE 30000.
01  WS-DIVISIONS.
    05  WS-DIV-COUNT        PIC 9(4) COMP-5.
    05  WS-DIV              OCCURS DV-MAX TIMES.
        10  DV-NODE         PIC 9(9) COMP-5.
        10  DV-PROGRAM      PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-INTRINSIC            PIC X.
01  LS-FD-T                 PIC 9(9) COMP-5.
01  LS-OPTION-T             PIC 9(9) COMP-5.
01  LS-OPTION               PIC X(31).
01  LS-IN-SEGMENT           PIC X.
01  LS-IN-FUNCTION-LIST     PIC X.
01  LS-LISTED               PIC X.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-D                    PIC 9(4) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-ANCESTOR             PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(4) COMP-5.
*> Directives that define constants: a line and its first words.
01  LS-LINE-IX              PIC 9(9) COMP-5.
01  LS-DIRECTIVE            PIC X(1024).
01  LS-DIRECTIVE-REST       PIC X(1024).
01  LS-DIRECTIVE-WORDS.
    05  LS-DIRECTIVE-WORD   PIC X(40) OCCURS 3 TIMES.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-TEXT                 PIC X(31).
01  LS-NAME                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-KW                   PIC X.
01  LS-IN-INDEXED           PIC X.
01  LS-LEVEL                PIC 9(4) COMP-5.
01  LS-EXEC-LANGUAGE        PIC X(31).
01  LS-COLON                PIC X.
01  LS-CLOSE                PIC 9(9) COMP-5.
01  LS-MATCHES              PIC 9(9) COMP-5.
01  LS-FIRST-MATCH          PIC 9(9) COMP-5.
01  LS-OK                   PIC X.
01  LS-GLOBAL               PIC X.
01  LS-FULL                 PIC X VALUE "N".
*> Qualifiers of the reference being resolved, innermost first. Level
*> numbers go up to 49 and a file name can qualify a record, so 50
*> covers every valid reference.
78  LS-QUAL-MAX             VALUE 50.
01  LS-QUALIFIERS.
    05  LS-QUAL-COUNT       PIC 9(4) COMP-5.
    05  LS-QUAL             PIC X(31) OCCURS LS-QUAL-MAX TIMES.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdiag.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbflow.cpy".
COPY "plbref.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DIAGNOSTICS PLB-TOKENS
        PLB-AST PLB-SYMBOLS PLB-FLOW PLB-REFS.
    MOVE 0 TO RF-COUNT WS-OTHER-COUNT WS-DIV-COUNT
    MOVE "N" TO WS-SQLCA-ADDED WS-EIB-ADDED WS-DIB-ADDED
    IF AS-COUNT = 0 OR TK-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > TK-COUNT
        MOVE 0 TO WS-TOKEN-STMT(LS-T)
        MOVE "N" TO WS-TOKEN-SKIP(LS-T)
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        PERFORM MARK-NODE
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM DIRECTIVE-CONSTANTS
    IF WS-OTHER-COUNT > 1
        SORT WS-OTHER ON ASCENDING KEY ON-TEXT
    END-IF
    PERFORM VARYING LS-D FROM 1 BY 1 UNTIL LS-D > WS-DIV-COUNT
        MOVE DV-PROGRAM(LS-D) TO LS-PROGRAM
        PERFORM VARYING LS-T FROM ND-TOK-FIRST(DV-NODE(LS-D)) BY 1
                UNTIL LS-T > ND-TOK-LAST(DV-NODE(LS-D))
                   OR LS-FULL = "Y"
            PERFORM CONSIDER-TOKEN
        END-PERFORM
    END-PERFORM
    GOBACK.

*> Pass 1: what each node says about its tokens -------------------

MARK-NODE.
    EVALUATE ND-KIND(LS-NODE)
        WHEN "PROG"
            MOVE LS-NODE TO LS-PROGRAM
        WHEN "DIVN"
            EVALUATE ND-DETAIL(LS-NODE)
                WHEN "PROCEDURE"
                    IF WS-DIV-COUNT < DV-MAX
                        ADD 1 TO WS-DIV-COUNT
                        MOVE LS-NODE TO DV-NODE(WS-DIV-COUNT)
                        MOVE LS-PROGRAM TO DV-PROGRAM(WS-DIV-COUNT)
                    END-IF
                WHEN "ENVIRONMENT"
                    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
                            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
                        PERFORM ADD-OTHER-IF-USER-WORD
                    END-PERFORM
            END-EVALUATE
        WHEN "FD"
            IF ND-NAME(LS-NODE) > 0
                MOVE ND-NAME(LS-NODE) TO LS-T
                PERFORM ADD-OTHER-IF-USER-WORD
            END-IF
            *> A communication description declares the data names in
            *> its clauses (STATUS KEY IS name, or a list of names); the
            *> runtime gives them their values.
            IF ND-DETAIL(LS-NODE) = "CD"
                PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
                        UNTIL LS-T > ND-TOK-LAST(LS-NODE)
                    IF TK-IS-PERIOD(LS-T)
                        EXIT PERFORM
                    END-IF
                    PERFORM ADD-OTHER-IF-USER-WORD
                END-PERFORM
            END-IF
        WHEN "CLAU"
            EVALUATE ND-DETAIL(LS-NODE)
                WHEN "OCCURS"
                    PERFORM INDEX-NAMES
                WHEN "SOURCE" WHEN "SUM" WHEN "TYPE" WHEN "CONTROL"
                WHEN "PRESENT"
                    PERFORM ADD-REPORT-CLAUSE
            END-EVALUATE
        WHEN "STMT"
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-NODE)
                MOVE LS-NODE TO WS-TOKEN-STMT(LS-T)
            END-PERFORM
            IF ND-DETAIL(LS-NODE) = "EXEC"
                PERFORM MARK-EXEC-TOKENS
            END-IF
        WHEN "OTHR"
            *> EXEC SQL ... END-EXEC in the data division.
            IF ND-DETAIL(LS-NODE) = "EXEC"
                PERFORM EXEC-LANGUAGE
                IF LS-EXEC-LANGUAGE = "SQL"
                    PERFORM ADD-SQLCA-NAMES
                END-IF
            END-IF
        WHEN "PROC"
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-NODE)
                MOVE "Y" TO WS-TOKEN-SKIP(LS-T)
            END-PERFORM
        WHEN "PARA"
        WHEN "SECT"
            IF ND-NAME(LS-NODE) > 0
                MOVE "Y" TO WS-TOKEN-SKIP(ND-NAME(LS-NODE))
            END-IF
    END-EVALUATE.

*> EXEC SQL, EXEC CICS, and EXEC DLI name COBOL data among their own
*> words: the host variables of SQL (:NAME, :RECORD.FIELD) and the
*> arguments of CICS and DL/I options (INTO(NAME), RESP(NAME)), except
*> the segment names of SEGMENT(...). Every other token of an EXEC
*> statement is skipped, and so is all of any other EXEC.
MARK-EXEC-TOKENS.
    PERFORM EXEC-LANGUAGE
    MOVE 0 TO LS-LEVEL
    MOVE "N" TO LS-IN-SEGMENT
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        MOVE "Y" TO WS-TOKEN-SKIP(LS-T)
        EVALUATE TRUE
            WHEN LS-EXEC-LANGUAGE = "SQL" AND LS-T > ND-TOK-FIRST(LS-NODE)
                IF TK-IS-COLON(LS-T - 1) AND TK-IS-WORD(LS-T)
                    MOVE "N" TO WS-TOKEN-SKIP(LS-T)
                END-IF
            WHEN LS-EXEC-LANGUAGE = "CICS" OR LS-EXEC-LANGUAGE = "DLI"
                IF TK-IS-LPAREN(LS-T)
                    ADD 1 TO LS-LEVEL
                    *> EXEC DLI ... SEGMENT(name): a segment, not data.
                    IF LS-LEVEL = 1 AND LS-EXEC-LANGUAGE = "DLI"
                        COMPUTE LS-OPTION-T = LS-T - 1
                        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-OPTION-T
                            LS-OPTION LS-LEN
                        IF LS-OPTION = "SEGMENT"
                            MOVE "Y" TO LS-IN-SEGMENT
                        END-IF
                    END-IF
                END-IF
                IF TK-IS-RPAREN(LS-T) AND LS-LEVEL > 0
                    SUBTRACT 1 FROM LS-LEVEL
                    IF LS-LEVEL = 0
                        MOVE "N" TO LS-IN-SEGMENT
                    END-IF
                END-IF
                IF LS-LEVEL > 0 AND TK-IS-WORD(LS-T)
                   AND LS-IN-SEGMENT = "N"
                    MOVE "N" TO WS-TOKEN-SKIP(LS-T)
                END-IF
        END-EVALUATE
    END-PERFORM
    EVALUATE LS-EXEC-LANGUAGE
        WHEN "SQL"
            PERFORM ADD-SQLCA-NAMES
        WHEN "CICS"
            PERFORM ADD-EIB-NAMES
        WHEN "DLI"
            PERFORM ADD-DIB-NAMES
    END-EVALUATE.

*> LS-EXEC-LANGUAGE = the word after EXEC in node LS-NODE.
EXEC-LANGUAGE.
    MOVE SPACES TO LS-EXEC-LANGUAGE
    COMPUTE LS-K = ND-TOK-FIRST(LS-NODE) + 1
    IF LS-K <= ND-TOK-LAST(LS-NODE) AND TK-IS-WORD(LS-K)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-EXEC-LANGUAGE LS-LEN
    END-IF.

*> The fields of the SQL communication area, which the precompiler
*> declares (EXEC SQL INCLUDE SQLCA): the database sets them.
ADD-SQLCA-NAMES.
    IF WS-SQLCA-ADDED = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO WS-SQLCA-ADDED
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > 20
        MOVE WS-SQLCA-NAME(LS-Q) TO LS-TEXT
        PERFORM ADD-OTHER-NAME
    END-PERFORM.

*> The fields of the CICS EXEC interface block (EIBRESP, EIBCALEN,
*> ...), which the translator declares.
ADD-EIB-NAMES.
    IF WS-EIB-ADDED = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO WS-EIB-ADDED
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > 33
        MOVE WS-EIB-NAME(LS-Q) TO LS-TEXT
        PERFORM ADD-OTHER-NAME
    END-PERFORM.

*> Compile-time constants that directives define, which the program
*> may use like literals: $SET CONSTANT NAME "value" (Micro Focus),
*> >>DEFINE [CONSTANT] NAME AS value (COBOL 2014).
DIRECTIVE-CONSTANTS.
    PERFORM VARYING LS-LINE-IX FROM 1 BY 1
            UNTIL LS-LINE-IX > SS-LINE-COUNT
        IF SL-IS-DIRECTIVE(LS-LINE-IX)
            CALL "PLB-SRC-LINE-CONTENT" USING PLB-SOURCE-SET LS-LINE-IX
                LS-DIRECTIVE LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-DIRECTIVE) TO LS-DIRECTIVE
            *> ">> DEFINE" with a space reads as ">>DEFINE".
            IF LS-DIRECTIVE(1:3) = ">> "
                MOVE LS-DIRECTIVE(4:) TO LS-DIRECTIVE-REST
                MOVE LS-DIRECTIVE-REST TO LS-DIRECTIVE(3:)
            END-IF
            MOVE SPACES TO LS-DIRECTIVE-WORD(1) LS-DIRECTIVE-WORD(2)
                LS-DIRECTIVE-WORD(3)
            UNSTRING LS-DIRECTIVE DELIMITED BY ALL SPACE
                INTO LS-DIRECTIVE-WORD(1) LS-DIRECTIVE-WORD(2)
                    LS-DIRECTIVE-WORD(3)
            MOVE SPACES TO LS-TEXT
            EVALUATE TRUE
                WHEN (LS-DIRECTIVE-WORD(1) = "$SET"
                      OR LS-DIRECTIVE-WORD(1) = ">>SET")
                     AND LS-DIRECTIVE-WORD(2) = "CONSTANT"
                WHEN LS-DIRECTIVE-WORD(1) = ">>DEFINE"
                     AND LS-DIRECTIVE-WORD(2) = "CONSTANT"
                    MOVE LS-DIRECTIVE-WORD(3) TO LS-TEXT
                WHEN LS-DIRECTIVE-WORD(1) = ">>DEFINE"
                    MOVE LS-DIRECTIVE-WORD(2) TO LS-TEXT
            END-EVALUATE
            IF LS-TEXT NOT = SPACES
                PERFORM ADD-OTHER-NAME
            END-IF
        END-IF
    END-PERFORM.

*> The fields of the DL/I interface block, which the IMS translator
*> declares for EXEC DLI (DIBSTAT, the status code, above all).
ADD-DIB-NAMES.
    IF WS-DIB-ADDED = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO WS-DIB-ADDED
    MOVE "DIBVER" TO LS-TEXT
    PERFORM ADD-OTHER-NAME
    MOVE "DIBSTAT" TO LS-TEXT
    PERFORM ADD-OTHER-NAME
    MOVE "DIBSEGM" TO LS-TEXT
    PERFORM ADD-OTHER-NAME
    MOVE "DIBSEGLV" TO LS-TEXT
    PERFORM ADD-OTHER-NAME
    MOVE "DIBKFBL" TO LS-TEXT
    PERFORM ADD-OTHER-NAME
    MOVE "DIBDBDNM" TO LS-TEXT
    PERFORM ADD-OTHER-NAME
    MOVE "DIBDBORG" TO LS-TEXT
    PERFORM ADD-OTHER-NAME.

ADD-OTHER-NAME.
    IF WS-OTHER-COUNT < ON-MAX
        ADD 1 TO WS-OTHER-COUNT
        MOVE LS-TEXT TO ON-TEXT(WS-OTHER-COUNT)
    END-IF.

*> A report clause that names data items: scan its operands, with the
*> clause as their statement.
ADD-REPORT-CLAUSE.
    IF WS-DIV-COUNT >= DV-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-DIV-COUNT
    MOVE LS-NODE TO DV-NODE(WS-DIV-COUNT)
    MOVE LS-PROGRAM TO DV-PROGRAM(WS-DIV-COUNT)
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        MOVE LS-NODE TO WS-TOKEN-STMT(LS-T)
    END-PERFORM.

*> Words after INDEXED [BY] in an OCCURS clause name indexes.
INDEX-NAMES.
    MOVE "N" TO LS-IN-INDEXED
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-NODE) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-NODE)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        EVALUATE TRUE
            WHEN LS-TEXT = "INDEXED"
                MOVE "Y" TO LS-IN-INDEXED
            WHEN LS-TEXT = "ASCENDING" OR LS-TEXT = "DESCENDING"
                MOVE "N" TO LS-IN-INDEXED
            *> Report Writer: OCCURS n TIMES VARYING counter FROM ...
            *> declares the counter.
            WHEN LS-TEXT = "VARYING"
                MOVE "V" TO LS-IN-INDEXED
            WHEN LS-IN-INDEXED = "V"
                PERFORM ADD-OTHER-IF-USER-WORD
                MOVE "N" TO LS-IN-INDEXED
            WHEN LS-IN-INDEXED = "Y"
                PERFORM ADD-OTHER-IF-USER-WORD
        END-EVALUATE
    END-PERFORM.

ADD-OTHER-IF-USER-WORD.
    IF TK-IS-WORD(LS-T) AND TK-TEXT-LEN(LS-T) <= 31
       AND WS-OTHER-COUNT < ON-MAX
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        CALL "PLB-KW-LOOKUP" USING LS-TEXT LS-KW
        IF LS-KW = SPACE
            ADD 1 TO WS-OTHER-COUNT
            MOVE LS-TEXT TO ON-TEXT(WS-OTHER-COUNT)
        END-IF
    END-IF.

*> Pass 2: identifiers ----------------------------------------------

CONSIDER-TOKEN.
    IF NOT TK-IS-WORD(LS-T) OR WS-TOKEN-SKIP(LS-T) = "Y"
       OR TK-TEXT-LEN(LS-T) > 31
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-NAME LS-LEN
    *> DFHRESP(NORMAL) and DFHVALUE(...) are CICS translator functions:
    *> neither they nor their argument are data names.
    IF (LS-NAME = "DFHRESP" OR LS-NAME = "DFHVALUE")
       AND LS-T < TK-COUNT
        IF TK-IS-LPAREN(LS-T + 1)
            PERFORM VARYING LS-K FROM LS-T BY 1 UNTIL LS-K > TK-COUNT
                MOVE "Y" TO WS-TOKEN-SKIP(LS-K)
                IF TK-IS-RPAREN(LS-K)
                    EXIT PERFORM
                END-IF
            END-PERFORM
            EXIT PARAGRAPH
        END-IF
    END-IF
    CALL "PLB-KW-LOOKUP" USING LS-NAME LS-KW
    IF LS-KW NOT = SPACE
        EXIT PARAGRAPH
    END-IF
    *> XML GENERATE ... NAME OF item IS literal, TYPE OF item IS ...:
    *> the item after OF is the operand, not a qualifier.
    IF (LS-NAME = "NAME" OR LS-NAME = "TYPE") AND LS-T < TK-COUNT
       AND WS-TOKEN-STMT(LS-T) > 0
        IF ND-DETAIL(WS-TOKEN-STMT(LS-T)) = "XML"
           OR ND-DETAIL(WS-TOKEN-STMT(LS-T)) = "JSON"
            COMPUTE LS-J = LS-T + 1
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-J LS-TEXT LS-LEN
            IF LS-TEXT = "OF" AND TK-IS-WORD(LS-J)
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-IF
    IF LS-T > 1
        COMPUTE LS-J = LS-T - 1
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-J LS-TEXT LS-LEN
        IF LS-TEXT = "FUNCTION" AND TK-IS-WORD(LS-J)
            EXIT PARAGRAPH
        END-IF
    END-IF
    IF RF-COUNT >= RF-MAX
        MOVE "Y" TO LS-FULL
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO RF-COUNT
    MOVE LS-T TO RF-TOKEN(RF-COUNT)
    MOVE WS-TOKEN-STMT(LS-T) TO RF-STMT(RF-COUNT)
    MOVE "N" TO RF-SUBSCRIPTED(RF-COUNT) RF-REFMOD(RF-COUNT)
    MOVE 0 TO LS-QUAL-COUNT
    MOVE LS-T TO LS-J
    *> SQL qualification, outermost first: :RECORD.GROUP.FIELD is
    *> FIELD OF GROUP OF RECORD, named at the token of FIELD.
    PERFORM UNTIL LS-J + 2 > TK-COUNT
        IF NOT TK-IS-OPERATOR(LS-J + 1) OR NOT TK-IS-WORD(LS-J + 2)
           OR TK-TEXT-LEN(LS-J + 2) > 31
            EXIT PERFORM
        END-IF
        IF TK-TEXT(TK-TEXT-OFF(LS-J + 1):1) NOT = "."
            EXIT PERFORM
        END-IF
        IF LS-QUAL-COUNT < LS-QUAL-MAX
            PERFORM VARYING LS-Q FROM LS-QUAL-COUNT BY -1 UNTIL LS-Q = 0
                MOVE LS-QUAL(LS-Q) TO LS-QUAL(LS-Q + 1)
            END-PERFORM
            ADD 1 TO LS-QUAL-COUNT
            MOVE LS-NAME TO LS-QUAL(1)
        END-IF
        ADD 2 TO LS-J
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-J LS-NAME LS-LEN
        MOVE "Y" TO WS-TOKEN-SKIP(LS-J)
        MOVE LS-J TO RF-TOKEN(RF-COUNT)
    END-PERFORM

    *> Qualifiers.
    ADD 1 TO LS-J
    PERFORM UNTIL LS-J >= TK-COUNT
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-J LS-TEXT LS-LEN
        IF (LS-TEXT NOT = "IN" AND LS-TEXT NOT = "OF")
           OR NOT TK-IS-WORD(LS-J)
            EXIT PERFORM
        END-IF
        COMPUTE LS-K = LS-J + 1
        IF NOT TK-IS-WORD(LS-K) OR TK-TEXT-LEN(LS-K) > 31
            EXIT PERFORM
        END-IF
        IF LS-QUAL-COUNT < LS-QUAL-MAX
            ADD 1 TO LS-QUAL-COUNT
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K
                LS-QUAL(LS-QUAL-COUNT) LS-LEN
        END-IF
        MOVE "Y" TO WS-TOKEN-SKIP(LS-K)
        ADD 2 TO LS-J
    END-PERFORM
    COMPUTE RF-LAST(RF-COUNT) = LS-J - 1

    *> Subscripts and reference modification: up to two groups.
    PERFORM 2 TIMES
        IF LS-J <= TK-COUNT
            IF TK-IS-LPAREN(LS-J)
                PERFORM MATCH-PARENTHESIS
                IF LS-CLOSE > 0
                    IF LS-COLON = "Y"
                        MOVE "Y" TO RF-REFMOD(RF-COUNT)
                    ELSE
                        MOVE "Y" TO RF-SUBSCRIPTED(RF-COUNT)
                    END-IF
                    MOVE LS-CLOSE TO RF-LAST(RF-COUNT)
                    COMPUTE LS-J = LS-CLOSE + 1
                END-IF
            END-IF
        END-IF
    END-PERFORM
    PERFORM RESOLVE.

*> LS-J is on "(": set LS-CLOSE to its matching ")" (0 if none) and
*> LS-COLON to "Y" if a colon appears at the top level inside.
MATCH-PARENTHESIS.
    MOVE 0 TO LS-CLOSE LS-LEVEL
    MOVE "N" TO LS-COLON
    PERFORM VARYING LS-K FROM LS-J BY 1 UNTIL LS-K > TK-COUNT
        EVALUATE TRUE
            WHEN TK-IS-LPAREN(LS-K)
                ADD 1 TO LS-LEVEL
            WHEN TK-IS-RPAREN(LS-K)
                SUBTRACT 1 FROM LS-LEVEL
                IF LS-LEVEL = 0
                    MOVE LS-K TO LS-CLOSE
                    EXIT PERFORM
                END-IF
            WHEN TK-IS-COLON(LS-K) AND LS-LEVEL = 1
                MOVE "Y" TO LS-COLON
            WHEN TK-IS-PERIOD(LS-K)
                EXIT PERFORM
        END-EVALUATE
    END-PERFORM.

*> Resolution --------------------------------------------------------

RESOLVE.
    MOVE 0 TO LS-MATCHES LS-FIRST-MATCH
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-NAME(LS-S) = LS-NAME AND SY-PROGRAM(LS-S) = LS-PROGRAM
            PERFORM CHECK-QUALIFIERS
            IF LS-OK = "Y"
                PERFORM COUNT-MATCH
            END-IF
        END-IF
    END-PERFORM
    *> GLOBAL items of the programs this one is nested in.
    IF LS-MATCHES = 0
        MOVE ND-PARENT(LS-PROGRAM) TO LS-ANCESTOR
        PERFORM UNTIL LS-ANCESTOR = 0 OR LS-MATCHES > 0
            IF ND-KIND(LS-ANCESTOR) = "PROG"
                PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
                    IF SY-NAME(LS-S) = LS-NAME
                       AND SY-PROGRAM(LS-S) = LS-ANCESTOR
                        PERFORM CHECK-GLOBAL
                        IF LS-GLOBAL = "Y"
                            PERFORM CHECK-QUALIFIERS
                            IF LS-OK = "Y"
                                PERFORM COUNT-MATCH
                            END-IF
                        END-IF
                    END-IF
                END-PERFORM
            END-IF
            MOVE ND-PARENT(LS-ANCESTOR) TO LS-ANCESTOR
        END-PERFORM
    END-IF

    MOVE LS-FIRST-MATCH TO RF-SYMBOL(RF-COUNT)
    EVALUATE TRUE
        WHEN LS-MATCHES = 1
            MOVE "D" TO RF-KIND(RF-COUNT)
        WHEN LS-MATCHES > 1
            MOVE "A" TO RF-KIND(RF-COUNT)
        WHEN OTHER
            PERFORM RESOLVE-OTHER
    END-EVALUATE.

COUNT-MATCH.
    ADD 1 TO LS-MATCHES
    IF LS-FIRST-MATCH = 0
        MOVE LS-S TO LS-FIRST-MATCH
    END-IF.

*> LS-OK = "Y" when symbol LS-S has each qualifier among its
*> ancestors, innermost first; the last may also be the file name of
*> the FD its record belongs to.
CHECK-QUALIFIERS.
    MOVE "Y" TO LS-OK
    MOVE LS-S TO LS-A
    PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > LS-QUAL-COUNT
        MOVE SY-PARENT(LS-A) TO LS-A
        PERFORM UNTIL LS-A = 0
            IF SY-NAME(LS-A) = LS-QUAL(LS-Q)
                EXIT PERFORM
            END-IF
            MOVE SY-PARENT(LS-A) TO LS-A
        END-PERFORM
        IF LS-A = 0
            IF LS-Q = LS-QUAL-COUNT
                PERFORM CHECK-FILE-QUALIFIER
            ELSE
                MOVE "N" TO LS-OK
            END-IF
            EXIT PERFORM
        END-IF
    END-PERFORM.

CHECK-FILE-QUALIFIER.
    MOVE "N" TO LS-OK
    *> The record: the outermost ancestor of the symbol.
    MOVE LS-S TO LS-A
    PERFORM UNTIL SY-PARENT(LS-A) = 0
        MOVE SY-PARENT(LS-A) TO LS-A
    END-PERFORM
    MOVE ND-PARENT(SY-NODE(LS-A)) TO LS-U
    IF ND-KIND(LS-U) = "FD" AND ND-NAME(LS-U) > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-U) LS-TEXT LS-LEN
        IF LS-TEXT = LS-QUAL(LS-QUAL-COUNT)
            MOVE "Y" TO LS-OK
        END-IF
    END-IF.

*> LS-GLOBAL = "Y" when LS-S or its record has a GLOBAL clause.
CHECK-GLOBAL.
    MOVE "N" TO LS-GLOBAL
    MOVE LS-S TO LS-A
    PERFORM UNTIL LS-A = 0 OR LS-GLOBAL = "Y"
        MOVE ND-FIRST(SY-NODE(LS-A)) TO LS-U
        PERFORM UNTIL LS-U = 0
            IF ND-KIND(LS-U) = "CLAU" AND ND-DETAIL(LS-U) = "GLOBAL"
                MOVE "Y" TO LS-GLOBAL
                EXIT PERFORM
            END-IF
            MOVE ND-NEXT(LS-U) TO LS-U
        END-PERFORM
        *> The records of FD file GLOBAL are global too.
        IF SY-PARENT(LS-A) = 0 AND LS-GLOBAL = "N"
            MOVE ND-PARENT(SY-NODE(LS-A)) TO LS-U
            IF LS-U > 0
                IF ND-KIND(LS-U) = "FD"
                    PERFORM FD-IS-GLOBAL
                END-IF
            END-IF
        END-IF
        MOVE SY-PARENT(LS-A) TO LS-A
    END-PERFORM.

*> LS-GLOBAL = "Y" when the FD entry LS-U, up to its period, has the
*> word GLOBAL.
FD-IS-GLOBAL.
    PERFORM VARYING LS-FD-T FROM ND-TOK-FIRST(LS-U) BY 1
            UNTIL LS-FD-T > ND-TOK-LAST(LS-U)
        IF TK-IS-PERIOD(LS-FD-T)
            EXIT PERFORM
        END-IF
        IF TK-IS-WORD(LS-FD-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-FD-T LS-TEXT LS-LEN
            IF LS-TEXT = "GLOBAL"
                MOVE "Y" TO LS-GLOBAL
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> Not a data item: a procedure of the program, another declared
*> name, a device name compilers accept without SPECIAL-NAMES, or
*> nothing.
RESOLVE-OTHER.
    MOVE "U" TO RF-KIND(RF-COUNT)
    EVALUATE LS-NAME
        WHEN "CONSOLE" WHEN "SYSIN" WHEN "SYSOUT" WHEN "SYSERR"
        WHEN "SYSIPT" WHEN "SYSLST" WHEN "SYSPCH" WHEN "SYSPUNCH"
        WHEN "PRINTER" WHEN "PRINTER-1" WHEN "CSP" WHEN "TOP"
        WHEN "C01" WHEN "C02" WHEN "C03" WHEN "C04" WHEN "C05"
        WHEN "C06" WHEN "C07" WHEN "C08" WHEN "C09" WHEN "C10"
        WHEN "C11" WHEN "C12" WHEN "S01" WHEN "S02" WHEN "S03"
        WHEN "S04" WHEN "S05"
            MOVE "O" TO RF-KIND(RF-COUNT)
            EXIT PARAGRAPH
    END-EVALUATE
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-NAME(LS-U) = LS-NAME AND FU-PROGRAM(LS-U) = LS-PROGRAM
            MOVE "P" TO RF-KIND(RF-COUNT)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    PERFORM CONTEXT-WORD
    IF RF-KIND(RF-COUNT) = "O"
        EXIT PARAGRAPH
    END-IF
    *> IBM reserves names starting with DFH for CICS: in a program with
    *> EXEC CICS, an undeclared one comes from a CICS copybook such as
    *> DFHAID (DFHENTER, DFHPF3) or DFHBMSCA (DFHRED, DFHBMPRO).
    IF LS-NAME(1:3) = "DFH" AND WS-EIB-ADDED = "Y"
        MOVE "O" TO RF-KIND(RF-COUNT)
        EXIT PARAGRAPH
    END-IF
    PERFORM INTRINSIC-WITHOUT-FUNCTION
    IF RF-KIND(RF-COUNT) = "O"
        EXIT PARAGRAPH
    END-IF
    IF WS-OTHER-COUNT > 0
        SEARCH ALL WS-OTHER
            AT END
                CONTINUE
            WHEN ON-TEXT(ON-IX) = LS-NAME
                MOVE "O" TO RF-KIND(RF-COUNT)
        END-SEARCH
    END-IF.
*> An intrinsic function named without FUNCTION, which the program's
*> REPOSITORY allows: FUNCTION ALL INTRINSIC, or FUNCTION name ...
*> INTRINSIC that lists it.
INTRINSIC-WITHOUT-FUNCTION.
    MOVE "N" TO LS-INTRINSIC
    EVALUATE LS-NAME
        WHEN "ABS" WHEN "ABSOLUTE-VALUE" WHEN "ACOS" WHEN "ANNUITY"
        WHEN "ASIN" WHEN "ATAN" WHEN "BASECONVERT" WHEN "BIT-OF"
        WHEN "BIT-TO-CHAR" WHEN "BOOLEAN-OF-INTEGER"
        WHEN "BYTE-LENGTH" WHEN "CHAR" WHEN "CHAR-NATIONAL"
        WHEN "COMBINED-DATETIME" WHEN "CONCAT" WHEN "CONCATENATE"
        WHEN "CONTENT-LENGTH" WHEN "CONTENT-OF" WHEN "CONVERT"
        WHEN "COS" WHEN "CURRENCY-SYMBOL" WHEN "CURRENT-DATE"
        WHEN "DATE-OF-INTEGER" WHEN "DATE-TO-YYYYMMDD"
        WHEN "DAY-OF-INTEGER" WHEN "DAY-TO-YYYYDDD" WHEN "DISPLAY-OF"
        WHEN "E" WHEN "EXCEPTION-FILE" WHEN "EXCEPTION-FILE-N"
        WHEN "EXCEPTION-LOCATION" WHEN "EXCEPTION-LOCATION-N"
        WHEN "EXCEPTION-STATEMENT" WHEN "EXCEPTION-STATUS" WHEN "EXP"
        WHEN "EXP10" WHEN "FACTORIAL" WHEN "FIND-STRING"
        WHEN "FORMATTED-CURRENT-DATE" WHEN "FORMATTED-DATE"
        WHEN "FORMATTED-DATETIME" WHEN "FORMATTED-TIME"
        WHEN "FRACTION-PART" WHEN "HEX-OF" WHEN "HEX-TO-CHAR"
        WHEN "HIGHEST-ALGEBRAIC" WHEN "INTEGER"
        WHEN "INTEGER-OF-BOOLEAN" WHEN "INTEGER-OF-DATE"
        WHEN "INTEGER-OF-DAY" WHEN "INTEGER-OF-FORMATTED-DATE"
        WHEN "INTEGER-PART" WHEN "LENGTH" WHEN "LENGTH-AN"
        WHEN "LOCALE-COMPARE" WHEN "LOCALE-DATE" WHEN "LOCALE-TIME"
        WHEN "LOCALE-TIME-FROM-SECONDS" WHEN "LOG" WHEN "LOG10"
        WHEN "LOWER-CASE" WHEN "LOWEST-ALGEBRAIC" WHEN "MAX"
        WHEN "MEAN" WHEN "MEDIAN" WHEN "MIDRANGE" WHEN "MIN"
        WHEN "MOD" WHEN "MODULE-CALLER-ID" WHEN "MODULE-DATE"
        WHEN "MODULE-FORMATTED-DATE" WHEN "MODULE-ID"
        WHEN "MODULE-NAME" WHEN "MODULE-PATH" WHEN "MODULE-SOURCE"
        WHEN "MODULE-TIME" WHEN "MONETARY-DECIMAL-POINT"
        WHEN "MONETARY-THOUSANDS-SEPARATOR" WHEN "NATIONAL-OF"
        WHEN "NUMERIC-DECIMAL-POINT"
        WHEN "NUMERIC-THOUSANDS-SEPARATOR" WHEN "NUMVAL"
        WHEN "NUMVAL-C" WHEN "NUMVAL-F" WHEN "ORD" WHEN "ORD-MAX"
        WHEN "ORD-MIN" WHEN "PI" WHEN "PRESENT-VALUE" WHEN "RANDOM"
        WHEN "RANGE" WHEN "REM" WHEN "REVERSE"
        WHEN "SECONDS-FROM-FORMATTED-TIME"
        WHEN "SECONDS-PAST-MIDNIGHT" WHEN "SIGN" WHEN "SIN"
        WHEN "SQRT" WHEN "STANDARD-COMPARE" WHEN "STANDARD-DEVIATION"
        WHEN "STORED-CHAR-LENGTH" WHEN "SUBSTITUTE"
        WHEN "SUBSTITUTE-CASE" WHEN "SUM" WHEN "TAN"
        WHEN "TEST-DATE-YYYYMMDD" WHEN "TEST-DAY-YYYYDDD"
        WHEN "TEST-FORMATTED-DATETIME" WHEN "TEST-NUMVAL"
        WHEN "TEST-NUMVAL-C" WHEN "TEST-NUMVAL-F" WHEN "TRIM"
        WHEN "UPPER-CASE" WHEN "VARIANCE" WHEN "WHEN-COMPILED"
        WHEN "YEAR-TO-YYYY"
            MOVE "Y" TO LS-INTRINSIC
    END-EVALUATE
    IF LS-INTRINSIC = "N" OR LS-PROGRAM = 0
        EXIT PARAGRAPH
    END-IF
    *> The REPOSITORY is in the program's environment division.
    MOVE ND-FIRST(LS-PROGRAM) TO LS-K
    PERFORM UNTIL LS-K = 0
        IF ND-KIND(LS-K) = "DIVN" AND ND-DETAIL(LS-K) = "ENVIRONMENT"
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-K) TO LS-K
    END-PERFORM
    IF LS-K = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-IN-FUNCTION-LIST
    PERFORM VARYING LS-J FROM ND-TOK-FIRST(LS-K) BY 1
            UNTIL LS-J > ND-TOK-LAST(LS-K)
        IF TK-IS-WORD(LS-J)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-J LS-TEXT LS-LEN
            EVALUATE TRUE
                WHEN LS-TEXT = "FUNCTION"
                    MOVE "Y" TO LS-IN-FUNCTION-LIST
                    MOVE "N" TO LS-LISTED
                WHEN LS-TEXT = "INTRINSIC" AND LS-IN-FUNCTION-LIST = "Y"
                    IF LS-LISTED = "Y"
                        MOVE "O" TO RF-KIND(RF-COUNT)
                        EXIT PERFORM
                    END-IF
                    MOVE "N" TO LS-IN-FUNCTION-LIST
                WHEN LS-IN-FUNCTION-LIST = "Y"
                     AND (LS-TEXT = "ALL" OR LS-TEXT = LS-NAME)
                    MOVE "Y" TO LS-LISTED
            END-EVALUATE
        END-IF
    END-PERFORM.

*> A word that is a keyword only in some statements or clauses, so a
*> program may also use it as a name: when no item of that name is
*> declared, it is the keyword. Which statement it is in is not
*> checked; an undeclared item that happens to have one of these
*> names is not reported.
CONTEXT-WORD.
    EVALUATE LS-NAME
        *> ROUNDED MODE IS ... (COBOL 2014)
        WHEN "AWAY-FROM-ZERO" WHEN "NEAREST-AWAY-FROM-ZERO"
        WHEN "NEAREST-EVEN" WHEN "NEAREST-TOWARD-ZERO" WHEN "PROHIBITED"
        WHEN "TOWARD-GREATER" WHEN "TOWARD-LESSER" WHEN "TRUNCATION"
        *> READ ... PREVIOUS, START ... WITH, OPEN ... SHARING
        WHEN "PREVIOUS" WHEN "IGNORING" WHEN "WAIT" WHEN "UPDATE"
        *> PERFORM FOREVER
        WHEN "FOREVER"
        *> STOP RUN [WITH] NORMAL|ERROR [STATUS]; EXHIBIT [CHANGED]
        *> [NAMED]; ALLOCATE ... LOC n; PRESENT AFTER NEW name;
        *> PROCEDURE DIVISION WITH C LINKAGE
        WHEN "NORMAL" WHEN "CHANGED" WHEN "NAMED" WHEN "LOC" WHEN "NEW"
        WHEN "C"
        *> GnuCOBOL bit operators and the EQUALS of IF A EQUALS B
        WHEN "B-AND" WHEN "B-OR" WHEN "B-XOR" WHEN "B-NOT" WHEN "B-LEFT"
        WHEN "B-RIGHT" WHEN "B-SHIFT-L" WHEN "B-SHIFT-R" WHEN "B-SHIFT-LC"
        WHEN "B-SHIFT-RC" WHEN "EQUALS"
        *> FUNCTION FORMATTED-DATETIME (..., SYSTEM-OFFSET)
        WHEN "SYSTEM-OFFSET"
        *> The file control block GnuCOBOL keeps per file:
        *> FH--FCD OF file, FH--KEYDEF OF file
        WHEN "FH--FCD" WHEN "FH--KEYDEF"
        *> PROCEDURE DIVISION CHAINING, CALL STATIC / STDCALL,
        *> RETURNING NOTHING
        WHEN "CHAINING" WHEN "STATIC" WHEN "STDCALL" WHEN "NOTHING"
        *> ACCEPT ... FROM DATE YYYYMMDD, DAY YYYYDDD
        WHEN "YYYYMMDD" WHEN "YYYYDDD" WHEN "MICROSECOND-TIME"
        *> Screen attributes in ACCEPT and DISPLAY
        WHEN "AUTO" WHEN "AUTO-SKIP" WHEN "AUTOTERMINATE" WHEN "BEEP"
        WHEN "BELL" WHEN "BLINK" WHEN "COLOR" WHEN "CONVERSION"
        WHEN "EOL" WHEN "EOS" WHEN "ERASE" WHEN "FULL" WHEN "HIGHLIGHT"
        WHEN "LEFTLINE" WHEN "LOWLIGHT" WHEN "NO-ECHO" WHEN "OVERLINE"
        WHEN "PROMPT" WHEN "REQUIRED" WHEN "REVERSE-VIDEO" WHEN "SECURE"
        WHEN "TIME-OUT" WHEN "TIMEOUT" WHEN "UNDERLINE" WHEN "UPPER"
        WHEN "LOWER" WHEN "SCROLL" WHEN "TAB" WHEN "UNSIGNED"
        *> Devices of DISPLAY ... UPON
        WHEN "STDOUT" WHEN "STDERR" WHEN "SYSLIST"
        *> XML GENERATE ... SUPPRESS ... WHEN, TYPE OF ... IS
        WHEN "NONNUMERIC" WHEN "EVERY" WHEN "ATTRIBUTE" WHEN "ELEMENT"
        WHEN "XML-DECLARATION" WHEN "NAMESPACE" WHEN "NAMESPACE-PREFIX"
        WHEN "ENCODING" WHEN "VALIDATING" WHEN "ATTRIBUTES"
        WHEN "PROCESSING" WHEN "CONTENT"
            MOVE "O" TO RF-KIND(RF-COUNT)
    END-EVALUATE.
END PROGRAM PLB-REF-BUILD.
