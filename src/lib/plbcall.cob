*> ---------------------------------------------------------------
*> plbcall: the call graph (copy/plbcall.cpy).
*>
*>   PLB-CALL-INIT     empty the graph at the start of a run
*>   PLB-CALL-COLLECT  add the programs, ENTRY points, and CALL
*>                     statements of the file just analyzed
*>   PLB-CALL-RESOLVE  match every CALL with a literal name to the
*>                     program it calls, once all files are collected
*>
*> A CALL "NAME" resolves the way COBOL scopes program names:
*>
*>   1. a program directly contained in the caller, or the caller
*>      itself;
*>   2. a COMMON program directly contained in a program that
*>      contains the caller;
*>   3. an outermost program, or an ENTRY point of one, in any file
*>      of the run.
*>
*> When step 3 finds more than one program, the call stays
*> unresolved (CC-MATCHES says how many matched). A CALL of a data
*> item is dynamic and is not resolved.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CALL-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-CALL-GRAPH.
    MOVE 0 TO CP-COUNT CA-COUNT CC-COUNT CG-COUNT CP-DROPPED
    GOBACK.
END PROGRAM PLB-CALL-INIT.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CALL-COLLECT.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbtokc.cpy".
*> The outermost data reference starting at each token (0: none).
01  WS-REF-AT               PIC 9(9) COMP-5 OCCURS TK-MAX TIMES.
*> The PROG nodes of this file and their programs in the graph.
78  WS-PROG-MAX             VALUE 2000.
01  WS-PROGRAMS.
    05  WS-PROG-COUNT       PIC 9(4) COMP-5.
    05  WS-PROG             OCCURS WS-PROG-MAX TIMES.
        10  WS-PROG-NODE    PIC 9(9) COMP-5.
        10  WS-PROG-INDEX   PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-OWNER                PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-LIMIT                PIC 9(9) COMP-5.
01  LS-DEPTH                PIC 9(9) COMP-5.
01  LS-SIZE                 PIC 9(9) COMP-5.
01  LS-MODE                 PIC X.
01  LS-KIND                 PIC X.
01  LS-TEXT                 PIC X(31).
01  LS-WORD                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-FILE-ID              PIC 9(4) COMP-5.
01  LS-LINE                 PIC 9(9) COMP-5.
01  LS-COLUMN               PIC 9(4) COMP-5.
01  LS-SRC-LINE             PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbref.cpy".
COPY "plbcallc.cpy".
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-REFS PLB-CALL-GRAPH.
    PERFORM VARYING LS-T FROM 1 BY 1 UNTIL LS-T > TK-COUNT
        MOVE 0 TO WS-REF-AT(LS-T)
    END-PERFORM
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF WS-REF-AT(RF-TOKEN(LS-R)) = 0
            MOVE LS-R TO WS-REF-AT(RF-TOKEN(LS-R))
        END-IF
    END-PERFORM
    MOVE 0 TO WS-PROG-COUNT
    PERFORM VARYING LS-N FROM 1 BY 1 UNTIL LS-N > AS-COUNT
        EVALUATE ND-KIND(LS-N)
            WHEN "PROG"
                PERFORM ADD-PROGRAM
            WHEN "USNG"
                IF ND-DETAIL(LS-N) = "USING"
                    PERFORM ADD-USING-PARAMETER
                END-IF
            WHEN "STMT"
                EVALUATE ND-DETAIL(LS-N)
                    WHEN "CALL"
                        PERFORM ADD-CALL
                    WHEN "ENTRY"
                        PERFORM ADD-ENTRY
                END-EVALUATE
        END-EVALUATE
    END-PERFORM
    GOBACK.

*> Programs and parameters ----------------------------------------

ADD-PROGRAM.
    MOVE ND-PARENT(LS-N) TO LS-UP
    PERFORM PROGRAM-OF-NODE
    MOVE LS-P TO LS-OWNER
    IF CP-COUNT >= CP-MAX OR WS-PROG-COUNT >= WS-PROG-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CP-COUNT
    MOVE CP-COUNT TO LS-P
    ADD 1 TO WS-PROG-COUNT
    MOVE LS-N TO WS-PROG-NODE(WS-PROG-COUNT)
    MOVE LS-P TO WS-PROG-INDEX(WS-PROG-COUNT)
    MOVE "P" TO CP-KIND(LS-P)
    MOVE LS-P TO CP-OWNER(LS-P)
    MOVE LS-OWNER TO CP-PARENT(LS-P)
    MOVE "N" TO CP-COMMON(LS-P) CP-RECURSIVE(LS-P)
    MOVE CA-COUNT TO CP-PARAM-FIRST(LS-P)
    ADD 1 TO CP-PARAM-FIRST(LS-P)
    MOVE 0 TO CP-PARAM-COUNT(LS-P)
    MOVE ND-NAME(LS-N) TO LS-T
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CP-NAME(LS-P)
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO CP-FILE-ID(LS-P)
    MOVE LS-LINE TO CP-LINE(LS-P)
    MOVE LS-COLUMN TO CP-COLUMN(LS-P)
    MOVE LS-SRC-LINE TO CP-SRC-LINE(LS-P)
    *> PROGRAM-ID. NAME [IS] [COMMON] [INITIAL] [RECURSIVE] [PROGRAM].
    IF LS-T = 0
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    PERFORM UNTIL LS-T > TK-COUNT
        IF TK-IS-PERIOD(LS-T) OR TK-IS-EOF(LS-T)
            EXIT PERFORM
        END-IF
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE LS-WORD
                WHEN "COMMON"
                    MOVE "Y" TO CP-COMMON(LS-P)
                WHEN "RECURSIVE"
                    MOVE "Y" TO CP-RECURSIVE(LS-P)
            END-EVALUATE
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> LS-P = the program in the graph whose PROG node contains node
*> LS-UP (LS-UP itself included); 0 when there is none.
PROGRAM-OF-NODE.
    MOVE 0 TO LS-P
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "PROG"
            PERFORM VARYING LS-I FROM 1 BY 1
                    UNTIL LS-I > WS-PROG-COUNT
                IF WS-PROG-NODE(LS-I) = LS-UP
                    MOVE WS-PROG-INDEX(LS-I) TO LS-P
                    EXIT PERFORM
                END-IF
            END-PERFORM
            EXIT PERFORM
        END-IF
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM.

*> A PROCEDURE DIVISION USING item: BY VALUE when the nearest of
*> USING, REFERENCE, and VALUE before it is VALUE.
ADD-USING-PARAMETER.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    IF LS-P = 0
        EXIT PARAGRAPH
    END-IF
    MOVE "R" TO LS-MODE
    MOVE ND-TOK-FIRST(LS-N) TO LS-T
    PERFORM UNTIL LS-T <= 1
        SUBTRACT 1 FROM LS-T
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "VALUE"
                MOVE "V" TO LS-MODE
            END-IF
            IF LS-WORD = "VALUE" OR LS-WORD = "REFERENCE"
               OR LS-WORD = "USING"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    MOVE ND-NAME(LS-N) TO LS-T
    PERFORM ADD-PARAMETER.

*> Add the item named at token LS-T, passed in mode LS-MODE, to the
*> parameters of program LS-P.
ADD-PARAMETER.
    IF CA-COUNT >= CA-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    IF CP-PARAM-COUNT(LS-P) = 0
        MOVE CA-COUNT TO CP-PARAM-FIRST(LS-P)
        ADD 1 TO CP-PARAM-FIRST(LS-P)
    END-IF
    ADD 1 TO CA-COUNT
    ADD 1 TO CP-PARAM-COUNT(LS-P)
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CA-NAME(CA-COUNT)
    MOVE LS-MODE TO CA-MODE(CA-COUNT)
    PERFORM SIZE-AT-TOKEN
    MOVE LS-SIZE TO CA-SIZE(CA-COUNT).

*> ENTRY "NAME" [USING [BY REFERENCE|VALUE] item...]: another way
*> into the program containing it, with parameters of its own.
ADD-ENTRY.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    MOVE LS-P TO LS-OWNER
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF LS-OWNER = 0 OR LS-T > ND-TOK-LAST(LS-N)
        EXIT PARAGRAPH
    END-IF
    IF NOT TK-IS-ALNUM(LS-T)
        EXIT PARAGRAPH
    END-IF
    IF CP-COUNT >= CP-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CP-COUNT
    MOVE CP-COUNT TO LS-P
    MOVE "E" TO CP-KIND(LS-P)
    MOVE LS-OWNER TO CP-OWNER(LS-P)
    MOVE CP-PARENT(LS-OWNER) TO CP-PARENT(LS-P)
    MOVE "N" TO CP-COMMON(LS-P)
    MOVE CP-RECURSIVE(LS-OWNER) TO CP-RECURSIVE(LS-P)
    MOVE CA-COUNT TO CP-PARAM-FIRST(LS-P)
    ADD 1 TO CP-PARAM-FIRST(LS-P)
    MOVE 0 TO CP-PARAM-COUNT(LS-P)
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CP-NAME(LS-P)
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO CP-FILE-ID(LS-P)
    MOVE LS-LINE TO CP-LINE(LS-P)
    MOVE LS-COLUMN TO CP-COLUMN(LS-P)
    MOVE LS-SRC-LINE TO CP-SRC-LINE(LS-P)
    MOVE "R" TO LS-MODE
    ADD 1 TO LS-T
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            EVALUATE LS-WORD
                WHEN "REFERENCE"
                    MOVE "R" TO LS-MODE
                WHEN "VALUE"
                    MOVE "V" TO LS-MODE
            END-EVALUATE
            IF WS-REF-AT(LS-T) > 0
                MOVE WS-REF-AT(LS-T) TO LS-R
                PERFORM ADD-PARAMETER
                MOVE RF-LAST(LS-R) TO LS-T
            END-IF
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> Calls ----------------------------------------------------------

ADD-CALL.
    MOVE LS-N TO LS-UP
    PERFORM PROGRAM-OF-NODE
    PERFORM CALL-LIMIT
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF LS-P = 0 OR LS-T > LS-LIMIT
        EXIT PARAGRAPH
    END-IF
    IF CC-COUNT >= CC-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CC-COUNT
    MOVE CC-COUNT TO LS-C
    MOVE LS-P TO CC-FROM(LS-C)
    MOVE 0 TO CC-TO(LS-C) CC-MATCHES(LS-C) CC-ARG-COUNT(LS-C)
    MOVE CG-COUNT TO CC-ARG-FIRST(LS-C)
    ADD 1 TO CC-ARG-FIRST(LS-C)
    PERFORM TOKEN-POSITION
    MOVE LS-FILE-ID TO CC-FILE-ID(LS-C)
    MOVE LS-LINE TO CC-LINE(LS-C)
    MOVE LS-COLUMN TO CC-COLUMN(LS-C)
    MOVE LS-SRC-LINE TO CC-SRC-LINE(LS-C)
    PERFORM TOKEN-NAME
    MOVE LS-TEXT TO CC-TARGET(LS-C)
    IF TK-IS-ALNUM(LS-T)
        MOVE "N" TO CC-DYNAMIC(LS-C)
        ADD 1 TO LS-T
    ELSE
        MOVE "Y" TO CC-DYNAMIC(LS-C)
        IF WS-REF-AT(LS-T) > 0
            MOVE RF-LAST(WS-REF-AT(LS-T)) TO LS-T
        END-IF
        ADD 1 TO LS-T
    END-IF
    PERFORM UNTIL LS-T > LS-LIMIT
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "USING"
                ADD 1 TO LS-T
                PERFORM CALL-ARGUMENTS
                EXIT PERFORM
            END-IF
            IF LS-WORD = "RETURNING" OR LS-WORD = "GIVING"
                EXIT PERFORM
            END-IF
        END-IF
        ADD 1 TO LS-T
    END-PERFORM.

*> LS-LIMIT = the last token of CALL statement LS-N's own phrases,
*> before any conditional phrase (ON EXCEPTION ...) it contains.
CALL-LIMIT.
    MOVE ND-TOK-LAST(LS-N) TO LS-LIMIT
    MOVE ND-FIRST(LS-N) TO LS-UP
    PERFORM UNTIL LS-UP = 0
        IF ND-KIND(LS-UP) = "BLCK" OR ND-KIND(LS-UP) = "STMT"
            COMPUTE LS-LIMIT = ND-TOK-FIRST(LS-UP) - 1
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-UP) TO LS-UP
    END-PERFORM.

*> The arguments after USING, up to RETURNING, a conditional phrase,
*> or the end of the statement. BY REFERENCE, CONTENT, and VALUE
*> apply to the arguments after them until the next one.
CALL-ARGUMENTS.
    MOVE "R" TO LS-MODE
    PERFORM UNTIL LS-T > LS-LIMIT
        EVALUATE TRUE
            WHEN TK-IS-WORD(LS-T)
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
                EVALUATE LS-WORD
                    WHEN "RETURNING" WHEN "GIVING" WHEN "ON"
                    WHEN "EXCEPTION" WHEN "OVERFLOW" WHEN "NOT"
                    WHEN "END-CALL"
                        EXIT PERFORM
                    WHEN "BY"
                        ADD 1 TO LS-T
                    WHEN "REFERENCE"
                        MOVE "R" TO LS-MODE
                        ADD 1 TO LS-T
                    WHEN "CONTENT"
                        MOVE "C" TO LS-MODE
                        ADD 1 TO LS-T
                    WHEN "VALUE"
                        MOVE "V" TO LS-MODE
                        ADD 1 TO LS-T
                    WHEN "SIZE"
                        *> BY VALUE ... SIZE [IS] n|AUTO|DEFAULT
                        PERFORM SKIP-SIZE-PHRASE
                    WHEN "OMITTED"
                        MOVE "O" TO LS-KIND
                        MOVE 0 TO LS-SIZE
                        MOVE LS-WORD TO LS-TEXT
                        PERFORM ADD-ARGUMENT
                        ADD 1 TO LS-T
                    WHEN "ADDRESS" WHEN "LENGTH" WHEN "BYTE-LENGTH"
                        PERFORM SPECIAL-REGISTER-ARGUMENT
                    WHEN "FUNCTION"
                        PERFORM FUNCTION-ARGUMENT
                    WHEN OTHER
                        PERFORM WORD-ARGUMENT
                END-EVALUATE
            WHEN TK-IS-ALNUM(LS-T)
                MOVE "L" TO LS-KIND
                MOVE 0 TO LS-SIZE
                IF TK-PREFIX(LS-T) = SPACES
                    MOVE TK-TEXT-LEN(LS-T) TO LS-SIZE
                END-IF
                CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
                PERFORM JOIN-CONCATENATED
                PERFORM ADD-ARGUMENT
                ADD 1 TO LS-T
            WHEN TK-IS-NUMBER(LS-T)
                *> The size of a numeric literal depends on the
                *> compiler.
                MOVE "L" TO LS-KIND
                MOVE 0 TO LS-SIZE
                PERFORM TOKEN-NAME
                PERFORM ADD-ARGUMENT
                ADD 1 TO LS-T
            WHEN OTHER
                ADD 1 TO LS-T
        END-EVALUATE
    END-PERFORM.

*> "abc" & "def" is one literal: add the size of each further part
*> to LS-SIZE, and leave LS-T at the last part.
JOIN-CONCATENATED.
    PERFORM UNTIL LS-T + 2 > LS-LIMIT
        IF NOT TK-IS-OPERATOR(LS-T + 1)
           OR NOT TK-IS-ALNUM(LS-T + 2)
            EXIT PERFORM
        END-IF
        COMPUTE LS-I = LS-T + 1
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-I LS-WORD LS-LEN
        IF LS-WORD NOT = "&"
            EXIT PERFORM
        END-IF
        ADD 2 TO LS-T
        IF LS-SIZE > 0 AND TK-PREFIX(LS-T) = SPACES
            ADD TK-TEXT-LEN(LS-T) TO LS-SIZE
        ELSE
            MOVE 0 TO LS-SIZE
        END-IF
    END-PERFORM.

SKIP-SIZE-PHRASE.
    ADD 1 TO LS-T
    IF LS-T <= LS-LIMIT AND TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        IF LS-WORD = "IS"
            ADD 1 TO LS-T
        END-IF
    END-IF
    ADD 1 TO LS-T.

*> A data item argument, or a word Plumbline does not resolve (a
*> figurative constant such as ZERO or NULL).
WORD-ARGUMENT.
    PERFORM TOKEN-NAME
    MOVE WS-REF-AT(LS-T) TO LS-R
    IF LS-R > 0
        MOVE "D" TO LS-KIND
        PERFORM SIZE-AT-TOKEN
        PERFORM ADD-ARGUMENT
        MOVE RF-LAST(LS-R) TO LS-T
    ELSE
        MOVE "X" TO LS-KIND
        MOVE 0 TO LS-SIZE
        PERFORM ADD-ARGUMENT
    END-IF
    ADD 1 TO LS-T.

*> ADDRESS OF x, LENGTH OF x, BYTE-LENGTH OF x.
SPECIAL-REGISTER-ARGUMENT.
    MOVE "X" TO LS-KIND
    MOVE 0 TO LS-SIZE
    MOVE LS-WORD TO LS-TEXT
    PERFORM ADD-ARGUMENT
    ADD 1 TO LS-T
    IF LS-T > LS-LIMIT OR NOT TK-IS-WORD(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
    IF LS-WORD NOT = "OF"
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO LS-T
    IF LS-T <= LS-LIMIT AND WS-REF-AT(LS-T) > 0
        MOVE RF-LAST(WS-REF-AT(LS-T)) TO LS-T
    END-IF
    ADD 1 TO LS-T.

*> FUNCTION name [(arguments)].
FUNCTION-ARGUMENT.
    MOVE "X" TO LS-KIND
    MOVE 0 TO LS-SIZE
    ADD 1 TO LS-T
    PERFORM TOKEN-NAME
    PERFORM ADD-ARGUMENT
    ADD 1 TO LS-T
    IF LS-T > LS-LIMIT OR NOT TK-IS-LPAREN(LS-T)
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-T > LS-LIMIT
        IF TK-IS-LPAREN(LS-T)
            ADD 1 TO LS-DEPTH
        END-IF
        IF TK-IS-RPAREN(LS-T)
            SUBTRACT 1 FROM LS-DEPTH
        END-IF
        ADD 1 TO LS-T
        IF LS-DEPTH = 0
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> Add argument LS-TEXT (kind LS-KIND, size LS-SIZE, mode LS-MODE)
*> to call LS-C.
ADD-ARGUMENT.
    IF CG-COUNT >= CG-MAX
        ADD 1 TO CP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO CG-COUNT
    ADD 1 TO CC-ARG-COUNT(LS-C)
    MOVE LS-TEXT TO CG-TEXT(CG-COUNT)
    MOVE LS-KIND TO CG-KIND(CG-COUNT)
    MOVE LS-MODE TO CG-MODE(CG-COUNT)
    MOVE LS-SIZE TO CG-SIZE(CG-COUNT).

*> Helpers --------------------------------------------------------

*> LS-SIZE = bytes of the data item referenced at token LS-T, or 0
*> when not known: unresolved, reference-modified, a whole table, or
*> an item without a fixed size (ANY LENGTH).
SIZE-AT-TOKEN.
    MOVE 0 TO LS-SIZE
    MOVE WS-REF-AT(LS-T) TO LS-R
    IF LS-R = 0
        EXIT PARAGRAPH
    END-IF
    IF RF-KIND(LS-R) NOT = "D" OR RF-REFMOD(LS-R) = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE RF-SYMBOL(LS-R) TO LS-S
    IF SY-LEVEL(LS-S) = 88 OR SY-LEVEL(LS-S) = 66
       OR SY-LEVEL(LS-S) = 78
        EXIT PARAGRAPH
    END-IF
    IF SY-OCCURS(LS-S) > 0 AND RF-SUBSCRIPTED(LS-R) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SY-SIZE(LS-S) TO LS-SIZE.

*> LS-TEXT = the upper-cased text of token LS-T (spaces for 0).
TOKEN-NAME.
    MOVE SPACES TO LS-TEXT
    IF LS-T > 0
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
        MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    END-IF.

*> Where token LS-T is.
TOKEN-POSITION.
    MOVE 0 TO LS-FILE-ID LS-LINE LS-COLUMN LS-SRC-LINE
    IF LS-T < 1 OR LS-T > TK-COUNT
        EXIT PARAGRAPH
    END-IF
    MOVE TK-FILE-ID(LS-T) TO LS-FILE-ID
    MOVE TK-SRC-LINE(LS-T) TO LS-SRC-LINE
    MOVE TK-COLUMN(LS-T) TO LS-COLUMN
    IF LS-SRC-LINE > 0
        MOVE SL-LINE-NO(LS-SRC-LINE) TO LS-LINE
    END-IF.
END PROGRAM PLB-CALL-COLLECT.

IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-CALL-RESOLVE.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-A                    PIC 9(9) COMP-5.
01  LS-FROM                 PIC 9(9) COMP-5.
01  LS-FOUND                PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbcall.cpy".
PROCEDURE DIVISION USING PLB-CALL-GRAPH.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        MOVE 0 TO CC-TO(LS-C) CC-MATCHES(LS-C)
        IF CC-DYNAMIC(LS-C) = "N" AND CC-FROM(LS-C) > 0
            PERFORM RESOLVE-CALL
        END-IF
    END-PERFORM
    GOBACK.

RESOLVE-CALL.
    MOVE CC-FROM(LS-C) TO LS-FROM
    *> 1. Contained in the caller, or the caller itself.
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-KIND(LS-P) = "P"
           AND (CP-PARENT(LS-P) = LS-FROM OR LS-P = LS-FROM)
            MOVE LS-P TO CC-TO(LS-C)
            MOVE 1 TO CC-MATCHES(LS-C)
            EXIT PARAGRAPH
        END-IF
    END-PERFORM
    *> 2. COMMON programs of the programs containing the caller.
    MOVE CP-PARENT(LS-FROM) TO LS-A
    PERFORM UNTIL LS-A = 0
        PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
            IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-KIND(LS-P) = "P"
               AND CP-COMMON(LS-P) = "Y" AND CP-PARENT(LS-P) = LS-A
                MOVE LS-P TO CC-TO(LS-C)
                MOVE 1 TO CC-MATCHES(LS-C)
                EXIT PARAGRAPH
            END-IF
        END-PERFORM
        MOVE CP-PARENT(LS-A) TO LS-A
    END-PERFORM
    *> 3. Outermost programs and their entry points.
    MOVE 0 TO LS-FOUND
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-NAME(LS-P) = CC-TARGET(LS-C) AND CP-PARENT(LS-P) = 0
            ADD 1 TO CC-MATCHES(LS-C)
            MOVE LS-P TO LS-FOUND
        END-IF
    END-PERFORM
    IF CC-MATCHES(LS-C) = 1
        MOVE LS-FOUND TO CC-TO(LS-C)
    END-IF.
END PROGRAM PLB-CALL-RESOLVE.
