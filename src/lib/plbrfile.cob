*> ---------------------------------------------------------------
*> plbrfile: rules about files and their I/O statements.
*>
*>   PLB-C020  file-status-not-checked
*>   PLB-C021  file-not-opened
*>   PLB-C022  open-mode-mismatch
*>   PLB-M008  file-not-closed
*>   PLB-C048  sort-procedure-no-record
*>   PLB-C050  record-read-at-end
*>   PLB-C058  read-not-handled
*>   PLB-C059  key-error-not-handled
*>
*> Each program on its own: its files (SELECT), their records (FD),
*> the declaratives that handle their errors (USE ... ERROR or
*> EXCEPTION PROCEDURE), and its I/O statements. The open modes of a
*> file are those of every OPEN that names it, anywhere in the
*> program: the rules do not follow the flow of control. An EXTERNAL
*> file is shared with other programs, which may open and close it, so
*> only its FILE STATUS checks apply.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-FILES.
DATA DIVISION.
WORKING-STORAGE SECTION.
78  FL-MAX                  VALUE 256.
78  RC-MAX                  VALUE 2048.
78  OP-MAX                  VALUE 20000.
01  WS-FILES.
    05  WS-FILE-COUNT       PIC 9(4) COMP-5.
    05  WS-FILE             OCCURS FL-MAX TIMES.
        10  FL-NAME         PIC X(31).
        10  FL-NAME-TOKEN   PIC 9(9) COMP-5.
        *> The FILE STATUS item, or spaces.
        10  FL-STATUS       PIC X(31).
        *> Opened INPUT, OUTPUT, I-O, EXTEND; closed; covered by a
        *> USE declarative.
        10  FL-INPUT        PIC X.
        10  FL-OUTPUT       PIC X.
        10  FL-I-O          PIC X.
        10  FL-EXTEND       PIC X.
        10  FL-CLOSED       PIC X.
        10  FL-COVERED      PIC X.
        *> "Y" for an EXTERNAL file: other programs open and close it.
        10  FL-EXTERNAL     PIC X.
        *> ORGANIZATION: S sequential (also LINE SEQUENTIAL), I indexed,
        *> R relative; ACCESS MODE: S sequential, R random, D dynamic.
        10  FL-ORGANIZATION PIC X.
        10  FL-ACCESS       PIC X.
01  WS-RECORDS.
    05  WS-RECORD-COUNT     PIC 9(4) COMP-5.
    05  WS-RECORD           OCCURS RC-MAX TIMES.
        10  RC-NAME         PIC X(31).
        10  RC-FILE         PIC 9(4) COMP-5.
*> I/O statements, one per file they name, in source order.
01  WS-OPS.
    05  WS-OP-COUNT         PIC 9(9) COMP-5.
    05  WS-OP               OCCURS OP-MAX TIMES.
        10  OP-STMT         PIC 9(9) COMP-5.
        10  OP-TOKEN        PIC 9(9) COMP-5.
        10  OP-FILE         PIC 9(4) COMP-5.
        10  OP-VERB         PIC X(10).
*> USE ... ON INPUT (OUTPUT, I-O, EXTEND): files opened that way.
01  WS-USE-MODES.
    05  WS-USE-INPUT        PIC X.
    05  WS-USE-OUTPUT       PIC X.
    05  WS-USE-I-O          PIC X.
    05  WS-USE-EXTEND       PIC X.
LOCAL-STORAGE SECTION.
COPY "plbnlist.cpy".
01  LS-RULE-STATUS          PIC 9(4) COMP-5.
01  LS-RULE-NOT-OPENED      PIC 9(4) COMP-5.
01  LS-RULE-MODE            PIC 9(4) COMP-5.
01  LS-RULE-NOT-CLOSED      PIC 9(4) COMP-5.
01  LS-RULE-NOT-HANDLED     PIC 9(4) COMP-5.
01  LS-RULE-KEY-ERROR       PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-PASS                 PIC 9.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(4) COMP-5.
01  LS-X                    PIC 9(4) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-STOP                 PIC 9(9) COMP-5.
01  LS-FOUND                PIC X.
01  LS-OK                   PIC X.
01  LS-AFTER-ON             PIC X.
01  LS-ALTERNATIVE          PIC X.
01  LS-MODE                 PIC X(10).
01  LS-VERB                 PIC X(20).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-MODES                PIC X(40).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbflow.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-FLOW PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C020" LS-RULE-STATUS
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C021" LS-RULE-NOT-OPENED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C022" LS-RULE-MODE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M008" LS-RULE-NOT-CLOSED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C058" LS-RULE-NOT-HANDLED
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C059" LS-RULE-KEY-ERROR
    IF AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-NODE
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "PROG"
            MOVE LS-NODE TO LS-PROGRAM
            PERFORM CHECK-PROGRAM
            MOVE LS-PROGRAM TO LS-NODE
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    GOBACK.

CHECK-PROGRAM.
    MOVE 0 TO WS-FILE-COUNT WS-RECORD-COUNT WS-OP-COUNT
    MOVE "N" TO WS-USE-INPUT WS-USE-OUTPUT WS-USE-I-O WS-USE-EXTEND
    *> Pass 1: files, records, declaratives. Pass 2: I/O statements.
    PERFORM VARYING LS-PASS FROM 1 BY 1 UNTIL LS-PASS > 2
        PERFORM VARYING LS-CHILD FROM LS-PROGRAM BY 1
                UNTIL LS-CHILD > AS-COUNT
            IF ND-TOK-FIRST(LS-CHILD) > ND-TOK-LAST(LS-PROGRAM)
                EXIT PERFORM
            END-IF
            PERFORM OWNED-BY-PROGRAM
            IF LS-OK = "Y"
                PERFORM CHECK-NODE
            END-IF
        END-PERFORM
    END-PERFORM
    IF WS-FILE-COUNT > 0
        PERFORM NOTE-COVERED-MODES
        PERFORM REPORT-FINDINGS
    END-IF.

*> LS-OK = "Y" when node LS-CHILD belongs to LS-PROGRAM and not to a
*> program nested in it.
OWNED-BY-PROGRAM.
    MOVE "N" TO LS-OK
    MOVE LS-CHILD TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "PROG"
            IF LS-UP = LS-PROGRAM
                MOVE "Y" TO LS-OK
            END-IF
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

CHECK-NODE.
    EVALUATE TRUE
        WHEN LS-PASS = 1 AND ND-KIND(LS-CHILD) = "SELE"
            PERFORM ADD-FILE
        WHEN LS-PASS = 1 AND ND-KIND(LS-CHILD) = "FD"
             AND (ND-DETAIL(LS-CHILD) = "FD" OR ND-DETAIL(LS-CHILD) = "SD")
            PERFORM ADD-RECORDS
        WHEN LS-PASS = 1 AND ND-KIND(LS-CHILD) = "STMT"
             AND ND-DETAIL(LS-CHILD) = "USE"
            PERFORM NOTE-USE
        WHEN LS-PASS = 2 AND ND-KIND(LS-CHILD) = "STMT"
            MOVE ND-DETAIL(LS-CHILD) TO LS-VERB
            EVALUATE LS-VERB
                WHEN "OPEN"
                WHEN "CLOSE"
                    PERFORM OPEN-OR-CLOSE
                WHEN "READ" WHEN "DELETE" WHEN "START"
                WHEN "WRITE" WHEN "REWRITE"
                    PERFORM RECORD-STATEMENT
            END-EVALUATE
    END-EVALUATE.

*> Pass 1 ----------------------------------------------------------

*> SELECT name ... [FILE] STATUS [IS] item.
ADD-FILE.
    IF WS-FILE-COUNT >= FL-MAX OR ND-NAME(LS-CHILD) = 0
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-FILE-COUNT
    MOVE WS-FILE-COUNT TO LS-F
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-CHILD) FL-NAME(LS-F)
        LS-LEN
    MOVE ND-NAME(LS-CHILD) TO FL-NAME-TOKEN(LS-F)
    MOVE SPACES TO FL-STATUS(LS-F)
    MOVE "N" TO FL-INPUT(LS-F) FL-OUTPUT(LS-F) FL-I-O(LS-F)
        FL-EXTEND(LS-F) FL-CLOSED(LS-F) FL-COVERED(LS-F)
        FL-EXTERNAL(LS-F)
    MOVE "S" TO FL-ORGANIZATION(LS-F) FL-ACCESS(LS-F)
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
            UNTIL LS-T >= ND-TOK-LAST(LS-CHILD)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            *> ORGANIZATION IS INDEXED, or INDEXED alone; ACCESS MODE IS
            *> RANDOM. (RECORD KEY, RELATIVE KEY, and STATUS come later
            *> in the clause than the word they could be taken for.)
            EVALUATE LS-TEXT
                WHEN "INDEXED"
                    MOVE "I" TO FL-ORGANIZATION(LS-F)
                WHEN "RELATIVE"
                    PERFORM NOTE-RELATIVE
                WHEN "RANDOM"
                    MOVE "R" TO FL-ACCESS(LS-F)
                WHEN "DYNAMIC"
                    MOVE "D" TO FL-ACCESS(LS-F)
            END-EVALUATE
            IF LS-TEXT = "STATUS"
                COMPUTE LS-K = LS-T + 1
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
                IF LS-TEXT = "IS"
                    ADD 1 TO LS-K
                END-IF
                IF LS-K <= ND-TOK-LAST(LS-CHILD) AND TK-IS-WORD(LS-K)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K
                        FL-STATUS(LS-F) LS-LEN
                END-IF
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.

*> RELATIVE is the organization, unless it starts RELATIVE KEY.
NOTE-RELATIVE.
    COMPUTE LS-K = LS-T + 1
    IF LS-K <= ND-TOK-LAST(LS-CHILD) AND TK-IS-WORD(LS-K)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
        IF LS-TEXT = "KEY"
            MOVE "RELATIVE" TO LS-TEXT
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE "R" TO FL-ORGANIZATION(LS-F)
    MOVE "RELATIVE" TO LS-TEXT.

*> The 01 records of an FD or SD belong to its file.
ADD-RECORDS.
    IF ND-NAME(LS-CHILD) = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-CHILD) LS-TEXT LS-LEN
    PERFORM FIND-FILE
    IF LS-F = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-K FROM ND-TOK-FIRST(LS-CHILD) BY 1
            UNTIL LS-K > ND-TOK-LAST(LS-CHILD)
        IF TK-IS-PERIOD(LS-K)
            EXIT PERFORM
        END-IF
        IF TK-IS-WORD(LS-K)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-K LS-TEXT LS-LEN
            IF LS-TEXT = "EXTERNAL"
                MOVE "Y" TO FL-EXTERNAL(LS-F)
            END-IF
        END-IF
    END-PERFORM
    MOVE ND-FIRST(LS-CHILD) TO LS-K
    PERFORM UNTIL LS-K = 0
        IF ND-KIND(LS-K) = "DATA" AND ND-NAME(LS-K) > 0
           AND WS-RECORD-COUNT < RC-MAX
            ADD 1 TO WS-RECORD-COUNT
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-K)
                RC-NAME(WS-RECORD-COUNT) LS-LEN
            MOVE LS-F TO RC-FILE(WS-RECORD-COUNT)
        END-IF
        MOVE ND-NEXT(LS-K) TO LS-K
    END-PERFORM.

*> USE AFTER [STANDARD] {ERROR | EXCEPTION} PROCEDURE [ON] {file... |
*> INPUT | OUTPUT | I-O | EXTEND}: those files' errors are handled.
NOTE-USE.
    MOVE "N" TO LS-FOUND LS-AFTER-ON
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE LS-TEXT
                WHEN "ERROR" WHEN "EXCEPTION"
                    MOVE "Y" TO LS-FOUND
                WHEN "PROCEDURE" WHEN "ON"
                    IF LS-FOUND = "Y"
                        MOVE "Y" TO LS-AFTER-ON
                    END-IF
                WHEN "INPUT"
                    IF LS-AFTER-ON = "Y"
                        MOVE "Y" TO WS-USE-INPUT
                    END-IF
                WHEN "OUTPUT"
                    IF LS-AFTER-ON = "Y"
                        MOVE "Y" TO WS-USE-OUTPUT
                    END-IF
                WHEN "I-O"
                    IF LS-AFTER-ON = "Y"
                        MOVE "Y" TO WS-USE-I-O
                    END-IF
                WHEN "EXTEND"
                    IF LS-AFTER-ON = "Y"
                        MOVE "Y" TO WS-USE-EXTEND
                    END-IF
                WHEN OTHER
                    IF LS-AFTER-ON = "Y"
                        PERFORM FIND-FILE
                        IF LS-F > 0
                            MOVE "Y" TO FL-COVERED(LS-F)
                        END-IF
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM.

*> LS-F = the file named LS-TEXT, or 0.
FIND-FILE.
    MOVE 0 TO LS-F
    PERFORM VARYING LS-X FROM 1 BY 1 UNTIL LS-X > WS-FILE-COUNT
        IF FL-NAME(LS-X) = LS-TEXT
            MOVE LS-X TO LS-F
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Pass 2 ----------------------------------------------------------

*> OPEN {INPUT | OUTPUT | I-O | EXTEND} file... ..., CLOSE file...
OPEN-OR-CLOSE.
    MOVE SPACES TO LS-MODE
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            EVALUATE LS-TEXT
                WHEN "INPUT" WHEN "OUTPUT" WHEN "I-O" WHEN "EXTEND"
                    MOVE LS-TEXT TO LS-MODE
                WHEN OTHER
                    PERFORM FIND-FILE
                    IF LS-F > 0
                        PERFORM ADD-OPERATION
                        IF LS-VERB = "OPEN"
                            PERFORM NOTE-OPEN-MODE
                        ELSE
                            MOVE "Y" TO FL-CLOSED(LS-F)
                        END-IF
                    END-IF
            END-EVALUATE
        END-IF
    END-PERFORM.

NOTE-OPEN-MODE.
    EVALUATE LS-MODE
        WHEN "INPUT"    MOVE "Y" TO FL-INPUT(LS-F)
        WHEN "OUTPUT"   MOVE "Y" TO FL-OUTPUT(LS-F)
        WHEN "I-O"      MOVE "Y" TO FL-I-O(LS-F)
        WHEN "EXTEND"   MOVE "Y" TO FL-EXTEND(LS-F)
    END-EVALUATE.

*> READ file, DELETE file, START file; WRITE record, REWRITE record.
RECORD-STATEMENT.
    COMPUTE LS-T = ND-TOK-FIRST(LS-CHILD) + 1
    IF LS-T > ND-TOK-LAST(LS-CHILD) OR NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    IF LS-VERB = "WRITE" OR LS-VERB = "REWRITE"
        MOVE 0 TO LS-F
        PERFORM VARYING LS-X FROM 1 BY 1 UNTIL LS-X > WS-RECORD-COUNT
            IF RC-NAME(LS-X) = LS-TEXT
                MOVE RC-FILE(LS-X) TO LS-F
                EXIT PERFORM
            END-IF
        END-PERFORM
    ELSE
        PERFORM FIND-FILE
    END-IF
    IF LS-F > 0
        PERFORM ADD-OPERATION
    END-IF.

ADD-OPERATION.
    IF WS-OP-COUNT >= OP-MAX
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO WS-OP-COUNT
    MOVE LS-CHILD TO OP-STMT(WS-OP-COUNT)
    MOVE LS-T TO OP-TOKEN(WS-OP-COUNT)
    MOVE LS-F TO OP-FILE(WS-OP-COUNT)
    MOVE LS-VERB TO OP-VERB(WS-OP-COUNT).

*> Findings --------------------------------------------------------

*> A USE for a mode covers the files opened in that mode.
NOTE-COVERED-MODES.
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > WS-FILE-COUNT
        IF WS-USE-INPUT = "Y" AND FL-INPUT(LS-F) = "Y"
           OR WS-USE-OUTPUT = "Y" AND FL-OUTPUT(LS-F) = "Y"
           OR WS-USE-I-O = "Y" AND FL-I-O(LS-F) = "Y"
           OR WS-USE-EXTEND = "Y" AND FL-EXTEND(LS-F) = "Y"
            MOVE "Y" TO FL-COVERED(LS-F)
        END-IF
    END-PERFORM.

REPORT-FINDINGS.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-OP-COUNT
        MOVE OP-FILE(LS-I) TO LS-F
        IF OP-VERB(LS-I) NOT = "OPEN" AND FL-EXTERNAL(LS-F) = "N"
            PERFORM CHECK-OPENED
        END-IF
        IF OP-VERB(LS-I) NOT = "CLOSE"
            PERFORM CHECK-STATUS-TESTED
        END-IF
        EVALUATE OP-VERB(LS-I)
            WHEN "READ"
                PERFORM CHECK-READ-HANDLED
            WHEN "WRITE" WHEN "REWRITE" WHEN "DELETE" WHEN "START"
                PERFORM CHECK-KEY-HANDLED
        END-EVALUATE
    END-PERFORM
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > WS-FILE-COUNT
        PERFORM CHECK-CLOSED
    END-PERFORM.

*> PLB-C021, or PLB-C022 when the file is opened, but not in a mode
*> that allows operation LS-I.
CHECK-OPENED.
    PERFORM DESCRIBE-MODES
    IF LS-MODES = SPACES
        MOVE SPACES TO LS-MESSAGE
        STRING OP-VERB(LS-I) DELIMITED BY SPACE
               " of " DELIMITED BY SIZE
               FL-NAME(LS-F) DELIMITED BY SPACE
               ", which no OPEN in the program opens" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-NOT-OPENED OP-TOKEN(LS-I)
            LS-MESSAGE
        EXIT PARAGRAPH
    END-IF
    MOVE "Y" TO LS-OK
    EVALUATE OP-VERB(LS-I)
        WHEN "READ" WHEN "START"
            IF FL-INPUT(LS-F) = "N" AND FL-I-O(LS-F) = "N"
                MOVE "N" TO LS-OK
            END-IF
        WHEN "WRITE"
            IF FL-OUTPUT(LS-F) = "N" AND FL-EXTEND(LS-F) = "N"
               AND FL-I-O(LS-F) = "N"
                MOVE "N" TO LS-OK
            END-IF
        WHEN "REWRITE" WHEN "DELETE"
            IF FL-I-O(LS-F) = "N"
                MOVE "N" TO LS-OK
            END-IF
    END-EVALUATE
    IF LS-OK = "N"
        MOVE SPACES TO LS-MESSAGE
        STRING OP-VERB(LS-I) DELIMITED BY SPACE
               " of " DELIMITED BY SIZE
               FL-NAME(LS-F) DELIMITED BY SPACE
               ", which the program opens only " DELIMITED BY SIZE
               LS-MODES DELIMITED BY "  "
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-MODE OP-TOKEN(LS-I) LS-MESSAGE
    END-IF.

*> LS-MODES = the modes file LS-F is opened in, as "INPUT and I-O".
DESCRIBE-MODES.
    MOVE SPACES TO LS-MODES
    MOVE 1 TO LS-PTR
    IF FL-INPUT(LS-F) = "Y"
        MOVE "INPUT" TO LS-TEXT
        PERFORM APPEND-MODE
    END-IF
    IF FL-OUTPUT(LS-F) = "Y"
        MOVE "OUTPUT" TO LS-TEXT
        PERFORM APPEND-MODE
    END-IF
    IF FL-I-O(LS-F) = "Y"
        MOVE "I-O" TO LS-TEXT
        PERFORM APPEND-MODE
    END-IF
    IF FL-EXTEND(LS-F) = "Y"
        MOVE "EXTEND" TO LS-TEXT
        PERFORM APPEND-MODE
    END-IF.

APPEND-MODE.
    IF LS-PTR > 1
        STRING " and " DELIMITED BY SIZE INTO LS-MODES WITH POINTER LS-PTR
    END-IF
    STRING LS-TEXT DELIMITED BY SPACE INTO LS-MODES WITH POINTER LS-PTR.

*> PLB-C058 read-not-handled: a READ with no AT END or INVALID KEY
*> phrase, of a file with no FILE STATUS and no USE declarative. When
*> the file ends, or the record is not there, nothing handles it, and
*> the run stops with an I/O error (GnuCOBOL: "end of file (status =
*> 10)"). A READ inside another I/O statement's AT END is not special:
*> each READ needs its own handling.
CHECK-READ-HANDLED.
    IF RL-ENABLED(LS-RULE-NOT-HANDLED) NOT = "Y"
       OR FL-STATUS(LS-F) NOT = SPACES OR FL-COVERED(LS-F) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(OP-STMT(LS-I)) TO LS-K
    PERFORM UNTIL LS-K = 0
        IF ND-KIND(LS-K) = "BLCK"
            EVALUATE ND-DETAIL(LS-K)
                WHEN "AT-END" WHEN "NOT-AT-END"
                WHEN "INVALID-KEY" WHEN "NOT-INVALID-KEY"
                    EXIT PARAGRAPH
            END-EVALUATE
        END-IF
        MOVE ND-NEXT(LS-K) TO LS-K
    END-PERFORM
    MOVE SPACES TO LS-MESSAGE
    STRING "nothing handles the end of " DELIMITED BY SIZE
           FL-NAME(LS-F) DELIMITED BY SPACE
           " or a record not found: no AT END or INVALID KEY, FILE"
           " STATUS, or USE declarative, so the run stops there"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-NOT-HANDLED OP-TOKEN(LS-I) LS-MESSAGE.

*> PLB-C059 key-error-not-handled: WRITE, REWRITE, DELETE, or START of
*> an indexed or relative file with no INVALID KEY phrase, of a file
*> with no FILE STATUS and no USE declarative. A duplicate key, or a
*> record that is not there, stops the run with an I/O error (GnuCOBOL:
*> "record key already exists (status = 22)"). DELETE in sequential
*> access takes no INVALID KEY and is left alone.
CHECK-KEY-HANDLED.
    IF RL-ENABLED(LS-RULE-KEY-ERROR) NOT = "Y"
       OR FL-STATUS(LS-F) NOT = SPACES OR FL-COVERED(LS-F) = "Y"
       OR FL-ORGANIZATION(LS-F) = "S"
        EXIT PARAGRAPH
    END-IF
    IF OP-VERB(LS-I) = "DELETE" AND FL-ACCESS(LS-F) = "S"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(OP-STMT(LS-I)) TO LS-K
    PERFORM UNTIL LS-K = 0
        IF ND-KIND(LS-K) = "BLCK"
            EVALUATE ND-DETAIL(LS-K)
                WHEN "INVALID-KEY" WHEN "NOT-INVALID-KEY"
                    EXIT PARAGRAPH
            END-EVALUATE
        END-IF
        MOVE ND-NEXT(LS-K) TO LS-K
    END-PERFORM
    MOVE SPACES TO LS-MESSAGE
    STRING "nothing handles a key error of this " DELIMITED BY SIZE
           OP-VERB(LS-I) DELIMITED BY SPACE
           " on " DELIMITED BY SIZE
           FL-NAME(LS-F) DELIMITED BY SPACE
           ": no INVALID KEY, FILE STATUS, or USE declarative, so a"
           " duplicate or missing key stops the run" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-KEY-ERROR OP-TOKEN(LS-I) LS-MESSAGE.

*> PLB-C020: the FILE STATUS of the file (or a condition name of it)
*> is not named after the statement, before the next statement on the
*> same file, unless an AT END or INVALID KEY phrase or a USE
*> declarative handles its errors.
CHECK-STATUS-TESTED.
    IF RL-ENABLED(LS-RULE-STATUS) NOT = "Y"
       OR FL-STATUS(LS-F) = SPACES OR FL-COVERED(LS-F) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE ND-FIRST(OP-STMT(LS-I)) TO LS-K
    PERFORM UNTIL LS-K = 0
        IF ND-KIND(LS-K) = "BLCK"
            EVALUATE ND-DETAIL(LS-K)
                WHEN "AT-END" WHEN "NOT-AT-END"
                WHEN "INVALID-KEY" WHEN "NOT-INVALID-KEY"
                    EXIT PARAGRAPH
            END-EVALUATE
        END-IF
        MOVE ND-NEXT(LS-K) TO LS-K
    END-PERFORM
    PERFORM STATUS-NAMES
    *> The next statement on the same file that can run after this
    *> one: not one in another branch of the same IF or EVALUATE.
    MOVE 0 TO LS-STOP
    PERFORM VARYING LS-J FROM LS-I BY 1 UNTIL LS-J > WS-OP-COUNT
        IF OP-FILE(LS-J) = LS-F
           AND ND-TOK-FIRST(OP-STMT(LS-J)) > ND-TOK-LAST(OP-STMT(LS-I))
            PERFORM CHECK-ALTERNATIVE
            IF LS-ALTERNATIVE = "N"
                MOVE ND-TOK-FIRST(OP-STMT(LS-J)) TO LS-STOP
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    CALL "PLB-NAMED-AFTER" USING PLB-TOKENS PLB-AST PLB-FLOW
        OP-STMT(LS-I) LS-STOP PLB-NAME-LIST LS-FOUND
    IF LS-FOUND = "N"
        MOVE SPACES TO LS-MESSAGE
        STRING "the FILE STATUS of " DELIMITED BY SIZE
               FL-NAME(LS-F) DELIMITED BY SPACE
               " (" DELIMITED BY SIZE
               FL-STATUS(LS-F) DELIMITED BY SPACE
               ") is not tested after this " DELIMITED BY SIZE
               OP-VERB(LS-I) DELIMITED BY SPACE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS
            PLB-RULES PLB-FINDINGS LS-RULE-STATUS OP-TOKEN(LS-I)
            LS-MESSAGE
    END-IF.

*> LS-ALTERNATIVE = "Y" when the statements of operations LS-I and LS-J
*> are in different branches (THEN and ELSE, two WHENs) of one
*> statement, so that only one of them runs.
CHECK-ALTERNATIVE.
    MOVE "N" TO LS-ALTERNATIVE
    MOVE ND-PARENT(OP-STMT(LS-I)) TO LS-UP
    PERFORM UNTIL LS-UP = 0 OR LS-ALTERNATIVE = "Y"
        IF ND-KIND(LS-UP) = "SENT" OR ND-KIND(LS-UP) = "PARA"
            EXIT PERFORM
        END-IF
        IF ND-KIND(LS-UP) = "BLCK"
            MOVE ND-PARENT(OP-STMT(LS-J)) TO LS-K
            PERFORM UNTIL LS-K = 0
                IF ND-KIND(LS-K) = "SENT" OR ND-KIND(LS-K) = "PARA"
                    EXIT PERFORM
                END-IF
                IF ND-KIND(LS-K) = "BLCK"
                   AND ND-PARENT(LS-K) = ND-PARENT(LS-UP)
                   AND LS-K NOT = LS-UP
                    MOVE "Y" TO LS-ALTERNATIVE
                    EXIT PERFORM
                END-IF
                MOVE ND-PARENT(LS-K) TO LS-K
            END-PERFORM
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> The status item of file LS-F and its condition names (88 levels).
STATUS-NAMES.
    MOVE 1 TO NL-COUNT
    MOVE FL-STATUS(LS-F) TO NL-NAME(1)
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-LEVEL(LS-S) = 88 AND SY-PARENT(LS-S) > 0 AND NL-COUNT < 32
            IF SY-NAME(SY-PARENT(LS-S)) = FL-STATUS(LS-F)
               AND SY-PROGRAM(LS-S) = LS-PROGRAM
                ADD 1 TO NL-COUNT
                MOVE SY-NAME(LS-S) TO NL-NAME(NL-COUNT)
            END-IF
        END-IF
    END-PERFORM.

*> PLB-M008.
CHECK-CLOSED.
    IF FL-CLOSED(LS-F) = "Y" OR FL-EXTERNAL(LS-F) = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM DESCRIBE-MODES
    IF LS-MODES = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING FL-NAME(LS-F) DELIMITED BY SPACE
           " is opened but never closed" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-NOT-CLOSED FL-NAME-TOKEN(LS-F) LS-MESSAGE.
END PROGRAM PLB-RULE-FILES.

*> PLB-C048 sort-procedure-no-record: the INPUT PROCEDURE of a SORT
*> that never RELEASEs a record, so the sort sorts nothing, or the
*> OUTPUT PROCEDURE of a SORT or MERGE that never RETURNs one, so its
*> records are never read.
*>
*> The procedure is the range it names (with THRU), and every
*> paragraph and section that range performs or goes to, and those
*> they perform or go to in turn. A procedure with a GO TO or PERFORM
*> the analysis could not resolve is not reported.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C048.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Which units hold a RELEASE and which a RETURN statement (a section
*> counts its paragraphs' statements too).
01  WS-HAS-RELEASE          PIC X OCCURS 20000 TIMES.
01  WS-HAS-RETURN           PIC X OCCURS 20000 TIMES.
*> The units of the procedure being checked: a work list, and the mark
*> of each unit already on it.
01  WS-IN-SET               PIC X OCCURS 20000 TIMES.
01  WS-SET                  PIC 9(9) COMP-5 OCCURS 20000 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-V                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-F                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-SET-COUNT            PIC 9(9) COMP-5.
01  LS-SET-NEXT             PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-TO                   PIC 9(9) COMP-5.
01  LS-NAME-TOKEN           PIC 9(9) COMP-5.
01  LS-PHASE                PIC X(6).
01  LS-FOUND                PIC X.
01  LS-UNRESOLVED           PIC X.
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbflow.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-FLOW
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C048" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0 OR FU-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        MOVE "N" TO WS-HAS-RELEASE(LS-U) WS-HAS-RETURN(LS-U)
            WS-IN-SET(LS-U)
    END-PERFORM
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        IF ND-KIND(LS-N) = "STMT"
           AND (ND-DETAIL(LS-N) = "RELEASE" OR ND-DETAIL(LS-N) = "RETURN")
            PERFORM MARK-STATEMENT
        END-IF
    END-PERFORM
    PERFORM VARYING LS-E FROM 1 BY 1 UNTIL LS-E > FE-COUNT
        IF FE-KIND(LS-E) = "P" AND FE-TO(LS-E) > 0 AND FE-STMT(LS-E) > 0
            IF ND-DETAIL(FE-STMT(LS-E)) = "SORT"
               OR ND-DETAIL(FE-STMT(LS-E)) = "MERGE"
                PERFORM CHECK-PROCEDURE
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> Statement LS-N belongs to the last unit that starts before it, and
*> to that unit's section.
MARK-STATEMENT.
    MOVE 0 TO LS-V
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-KIND(LS-U) NOT = "D"
           AND ND-TOK-FIRST(FU-NODE(LS-U)) <= ND-TOK-FIRST(LS-N)
           AND ND-TOK-LAST(FU-NODE(LS-U)) >= ND-TOK-FIRST(LS-N)
            MOVE LS-U TO LS-V
        END-IF
    END-PERFORM
    IF LS-V = 0
        EXIT PARAGRAPH
    END-IF
    PERFORM MARK-UNIT
    IF FU-SECTION(LS-V) > 0
        MOVE FU-SECTION(LS-V) TO LS-V
        PERFORM MARK-UNIT
    END-IF.

MARK-UNIT.
    IF ND-DETAIL(LS-N) = "RELEASE"
        MOVE "Y" TO WS-HAS-RELEASE(LS-V)
    ELSE
        MOVE "Y" TO WS-HAS-RETURN(LS-V)
    END-IF.

*> Edge LS-E runs a procedure of a SORT or MERGE: which one, and does
*> anything it runs RELEASE or RETURN?
CHECK-PROCEDURE.
    MOVE FE-STMT(LS-E) TO LS-STMT
    MOVE ND-NAME(FE-PROC(LS-E)) TO LS-NAME-TOKEN
    IF LS-NAME-TOKEN = 0
        MOVE ND-TOK-FIRST(FE-PROC(LS-E)) TO LS-NAME-TOKEN
    END-IF
    *> The phase is the last INPUT or OUTPUT before the name.
    MOVE SPACES TO LS-PHASE
    PERFORM VARYING LS-T FROM LS-NAME-TOKEN BY -1
            UNTIL LS-T <= ND-TOK-FIRST(LS-STMT) OR LS-PHASE NOT = SPACES
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
            IF LS-WORD = "INPUT" OR LS-WORD = "OUTPUT"
                MOVE LS-WORD TO LS-PHASE
            END-IF
        END-IF
    END-PERFORM
    IF LS-PHASE = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-SET-COUNT
    MOVE "N" TO LS-FOUND LS-UNRESOLVED
    MOVE FE-TO(LS-E) TO LS-FROM
    MOVE FE-THRU(LS-E) TO LS-TO
    PERFORM ADD-RANGE
    MOVE 1 TO LS-SET-NEXT
    PERFORM UNTIL LS-SET-NEXT > LS-SET-COUNT OR LS-FOUND = "Y"
        MOVE WS-SET(LS-SET-NEXT) TO LS-U
        PERFORM VISIT-UNIT
        ADD 1 TO LS-SET-NEXT
    END-PERFORM
    PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > LS-SET-COUNT
        MOVE "N" TO WS-IN-SET(WS-SET(LS-V))
    END-PERFORM
    IF LS-FOUND = "N" AND LS-UNRESOLVED = "N"
        PERFORM REPORT-PROCEDURE
    END-IF.

*> Units LS-FROM through LS-TO (LS-FROM alone when LS-TO is 0), in
*> source order, onto the work list.
ADD-RANGE.
    MOVE LS-FROM TO LS-V
    PERFORM UNTIL LS-V = 0
        IF WS-IN-SET(LS-V) = "N" AND LS-SET-COUNT < 20000
            MOVE "Y" TO WS-IN-SET(LS-V)
            ADD 1 TO LS-SET-COUNT
            MOVE LS-V TO WS-SET(LS-SET-COUNT)
        END-IF
        IF LS-TO = 0 OR LS-V = LS-TO
            EXIT PERFORM
        END-IF
        MOVE FU-NEXT(LS-V) TO LS-V
    END-PERFORM.

*> Unit LS-U: done if it has the statement, else add what it runs. A
*> section runs its paragraphs, which go on the list for what they
*> perform and go to.
VISIT-UNIT.
    IF (LS-PHASE = "INPUT" AND WS-HAS-RELEASE(LS-U) = "Y")
       OR (LS-PHASE = "OUTPUT" AND WS-HAS-RETURN(LS-U) = "Y")
        MOVE "Y" TO LS-FOUND
        EXIT PARAGRAPH
    END-IF
    IF FU-KIND(LS-U) = "S"
        PERFORM VARYING LS-V FROM 1 BY 1 UNTIL LS-V > FU-COUNT
            IF FU-SECTION(LS-V) = LS-U AND WS-IN-SET(LS-V) = "N"
               AND LS-SET-COUNT < 20000
                MOVE "Y" TO WS-IN-SET(LS-V)
                ADD 1 TO LS-SET-COUNT
                MOVE LS-V TO WS-SET(LS-SET-COUNT)
            END-IF
        END-PERFORM
    END-IF
    PERFORM VARYING LS-F FROM 1 BY 1 UNTIL LS-F > FE-COUNT
        IF FE-FROM(LS-F) = LS-U
            IF FE-TO(LS-F) = 0
                MOVE "Y" TO LS-UNRESOLVED
            ELSE
                MOVE FE-TO(LS-F) TO LS-FROM
                MOVE FE-THRU(LS-F) TO LS-TO
                IF FE-KIND(LS-F) NOT = "P"
                    MOVE 0 TO LS-TO
                END-IF
                PERFORM ADD-RANGE
            END-IF
        END-IF
    END-PERFORM.

REPORT-PROCEDURE.
    MOVE SPACES TO LS-MESSAGE
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-NAME-TOKEN LS-WORD LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-WORD) TO LS-WORD
    IF LS-PHASE = "INPUT"
        STRING "INPUT PROCEDURE " DELIMITED BY SIZE
               LS-WORD DELIMITED BY SPACE
               " never RELEASEs a record: the SORT sorts nothing"
               DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "OUTPUT PROCEDURE " DELIMITED BY SIZE
               LS-WORD DELIMITED BY SPACE
               " never RETURNs a record: the " DELIMITED BY SIZE
               ND-DETAIL(LS-STMT) DELIMITED BY SPACE
               " output is never read" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-NAME-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-C048.

*> PLB-C050 record-read-at-end: the AT END phrase of a READ (or of a
*> RETURN from a sort file) reads the file's record:
*>
*>     READ IN-FILE
*>         AT END DISPLAY "LAST KEY " IN-KEY
*>
*> After the end of the file the record area holds nothing the
*> standard defines: on some systems the last record read, on others
*> what the buffer held, and after a READ that found nothing at all,
*> spaces or garbage. Keep what is needed from each record in
*> WORKING-STORAGE (READ ... INTO does it) and read that copy.
*>
*> Stores into the record (MOVE HIGH-VALUES TO IN-KEY) are fine; reads
*> are reported, once per item and phrase. A file's records are the
*> entries under its FD or SD.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C050.
DATA DIVISION.
WORKING-STORAGE SECTION.
*> Reference starting at each token (0: none), for the tokens of the
*> current file.
01  WS-TOKEN-REF            PIC 9(9) COMP-5 OCCURS 500000 TIMES.
*> Items already reported in the current phrase.
78  WS-SEEN-MAX             VALUE 100.
01  WS-SEEN-COUNT           PIC 9(4) COMP-5.
01  WS-SEEN                 PIC 9(9) COMP-5 OCCURS WS-SEEN-MAX TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-STMT                 PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-FD                   PIC 9(9) COMP-5.
01  LS-FILE                 PIC X(31).
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-SEEN-IT              PIC X.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C050" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE LS-R TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    MOVE 1 TO LS-NODE
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
           AND (ND-DETAIL(LS-NODE) = "READ"
                OR ND-DETAIL(LS-NODE) = "RETURN")
            MOVE LS-NODE TO LS-STMT
            PERFORM CHECK-READ
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-NODE LS-DEPTH
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        MOVE 0 TO WS-TOKEN-REF(RF-TOKEN(LS-R))
    END-PERFORM
    GOBACK.

*> The file is the word after the verb; each AT END phrase of the
*> statement is checked.
CHECK-READ.
    COMPUTE LS-T = ND-TOK-FIRST(LS-STMT) + 1
    IF LS-T > ND-TOK-LAST(LS-STMT) OR NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-FILE LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-FILE) TO LS-FILE
    MOVE ND-FIRST(LS-STMT) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "BLCK" AND ND-DETAIL(LS-CHILD) = "AT-END"
            PERFORM CHECK-PHRASE
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

CHECK-PHRASE.
    MOVE 0 TO WS-SEEN-COUNT
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
        MOVE WS-TOKEN-REF(LS-T) TO LS-R
        IF LS-R > 0
            IF RF-KIND(LS-R) = "D" AND RF-SYMBOL(LS-R) > 0
               AND (RF-ROLE(LS-R) = "U" OR RF-ROLE(LS-R) = "B")
                MOVE RF-SYMBOL(LS-R) TO LS-S
                IF SY-SECTION(LS-S) = "F"
                    PERFORM CHECK-ITEM
                END-IF
            END-IF
        END-IF
    END-PERFORM.

*> Item LS-S is in the FILE SECTION: is its record under this file's
*> FD or SD?
CHECK-ITEM.
    MOVE LS-S TO LS-UP
    PERFORM UNTIL SY-PARENT(LS-UP) = 0
        MOVE SY-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    IF SY-NODE(LS-UP) = 0
        EXIT PARAGRAPH
    END-IF
    MOVE ND-PARENT(SY-NODE(LS-UP)) TO LS-FD
    IF LS-FD = 0
        EXIT PARAGRAPH
    END-IF
    IF ND-KIND(LS-FD) NOT = "FD" OR ND-NAME(LS-FD) = 0
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-FD) LS-WORD LS-LEN
    IF FUNCTION UPPER-CASE(LS-WORD) NOT = LS-FILE
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-SEEN-IT
    PERFORM VARYING LS-K FROM 1 BY 1 UNTIL LS-K > WS-SEEN-COUNT
        IF WS-SEEN(LS-K) = LS-S
            MOVE "Y" TO LS-SEEN-IT
        END-IF
    END-PERFORM
    IF LS-SEEN-IT = "Y"
        EXIT PARAGRAPH
    END-IF
    IF WS-SEEN-COUNT < WS-SEEN-MAX
        ADD 1 TO WS-SEEN-COUNT
        MOVE LS-S TO WS-SEEN(WS-SEEN-COUNT)
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "AT END reads " DELIMITED BY SIZE
           SY-NAME(LS-S) DELIMITED BY SPACE
           ", in the record of " DELIMITED BY SIZE
           LS-FILE DELIMITED BY SPACE
           ", which is undefined at the end of the file"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE RF-TOKEN(LS-R) LS-MESSAGE.
END PROGRAM PLB-RULE-C050.
