*> ---------------------------------------------------------------
*> plbdup: paragraphs with the same code (plumbline duplicates).
*>
*> A fix made in one copy of a paragraph is easily missed in the
*> others. PLB-DUP-COLLECT adds, after each file is analyzed, a hash
*> of each paragraph's body: its tokens after the name and period,
*> with words in upper case and literals as written, so that layout,
*> comments, and the case of words do not count. PLB-DUP-PRINT groups
*> paragraphs with the same hash and length, across the whole run, and
*> lists the groups from the largest paragraph down.
*>
*> Two hashes of 31 bits each are kept, so that different bodies that
*> share both are not a practical concern; the token count must agree
*> too. Paragraphs shorter than the minimum (--min-tokens) are left
*> out: short ones (MOVE ZERO TO X. EXIT.) repeat everywhere. So are
*> paragraphs that a COPY brings in: the copybook is their one source.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DUP-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbdupt.cpy".
PROCEDURE DIVISION USING PLB-DUPLICATES.
    MOVE 0 TO DP-COUNT DP-DROPPED
    GOBACK.
END PROGRAM PLB-DUP-INIT.

*> PLB-DUP-COLLECT: the paragraphs of the file just analyzed with at
*> least MIN-TOKENS tokens in their bodies.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DUP-COLLECT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-WORD                 PIC X(4096).
LOCAL-STORAGE SECTION.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-FIRST                PIC 9(9) COMP-5.
01  LS-LAST                 PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-V                    PIC S9(18) COMP-5.
01  LS-H1                   PIC S9(18) COMP-5.
01  LS-H2                   PIC S9(18) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-STATEMENTS           PIC 9(9) COMP-5.
01  LS-PROGRAM-TOKEN        PIC 9(9) COMP-5.
01  LS-PROGRAM-NAME         PIC X(31).
*> Two hashes, modulo primes below 2**31, with different multipliers.
78  LS-PRIME-1              VALUE 2147483647.
78  LS-PRIME-2              VALUE 2147483629.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbflow.cpy".
COPY "plbdupt.cpy".
01  LK-MIN-TOKENS           PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-FLOW
        PLB-DUPLICATES LK-MIN-TOKENS.
    *> A paragraph that comes from a copybook is one piece of source,
    *> however many programs copy it: not counted.
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > FU-COUNT
        IF FU-KIND(LS-U) = "P" AND ND-NAME(FU-NODE(LS-U)) > 0
            IF TK-INCL(ND-NAME(FU-NODE(LS-U))) = 0
                PERFORM PARAGRAPH-BODY
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> The body: from after the name and its period to the paragraph's
*> last token.
PARAGRAPH-BODY.
    COMPUTE LS-FIRST = ND-NAME(FU-NODE(LS-U)) + 1
    IF LS-FIRST <= TK-COUNT
        IF TK-IS-PERIOD(LS-FIRST)
            ADD 1 TO LS-FIRST
        END-IF
    END-IF
    MOVE ND-TOK-LAST(FU-NODE(LS-U)) TO LS-LAST
    IF LS-LAST < LS-FIRST
       OR LS-LAST - LS-FIRST + 1 < LK-MIN-TOKENS
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-H1 LS-H2
    PERFORM VARYING LS-T FROM LS-FIRST BY 1 UNTIL LS-T > LS-LAST
        PERFORM HASH-TOKEN
    END-PERFORM
    PERFORM COUNT-STATEMENTS
    IF DP-COUNT >= DP-MAX
        ADD 1 TO DP-DROPPED
        EXIT PARAGRAPH
    END-IF
    ADD 1 TO DP-COUNT
    MOVE LS-H1 TO DP-HASH-1(DP-COUNT)
    MOVE LS-H2 TO DP-HASH-2(DP-COUNT)
    COMPUTE DP-TOKENS(DP-COUNT) = LS-LAST - LS-FIRST + 1
    MOVE LS-STATEMENTS TO DP-STATEMENTS(DP-COUNT)
    MOVE FU-NAME(LS-U) TO DP-NAME(DP-COUNT)
    MOVE ND-NAME(FU-NODE(LS-U)) TO LS-T
    MOVE 0 TO DP-FILE-ID(DP-COUNT) DP-LINE(DP-COUNT)
    IF TK-SRC-LINE(LS-T) > 0
        MOVE SL-FILE-ID(TK-SRC-LINE(LS-T)) TO DP-FILE-ID(DP-COUNT)
        MOVE SL-LINE-NO(TK-SRC-LINE(LS-T)) TO DP-LINE(DP-COUNT)
    END-IF
    MOVE SPACES TO LS-PROGRAM-NAME
    IF FU-PROGRAM(LS-U) > 0
        MOVE ND-NAME(FU-PROGRAM(LS-U)) TO LS-PROGRAM-TOKEN
        IF LS-PROGRAM-TOKEN > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-PROGRAM-TOKEN
                LS-PROGRAM-NAME LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-PROGRAM-NAME) TO LS-PROGRAM-NAME
        END-IF
    END-IF
    MOVE LS-PROGRAM-NAME TO DP-PROGRAM(DP-COUNT).

*> Each token adds its kind and its characters (words in upper case),
*> and a separator, so that A B and AB differ.
HASH-TOKEN.
    MOVE TK-TEXT-LEN(LS-T) TO LS-LEN
    IF LS-LEN > FUNCTION LENGTH(WS-WORD)
        MOVE FUNCTION LENGTH(WS-WORD) TO LS-LEN
    END-IF
    IF LS-LEN > 0
        MOVE TK-TEXT(TK-TEXT-OFF(LS-T):LS-LEN) TO WS-WORD(1:LS-LEN)
        IF TK-IS-WORD(LS-T)
            INSPECT WS-WORD(1:LS-LEN) CONVERTING
                "abcdefghijklmnopqrstuvwxyz"
                TO "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        END-IF
    END-IF
    COMPUTE LS-V = FUNCTION ORD(TK-KIND(LS-T))
    PERFORM ADD-VALUE
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        COMPUTE LS-V = FUNCTION ORD(WS-WORD(LS-I:1))
        PERFORM ADD-VALUE
    END-PERFORM
    MOVE 0 TO LS-V
    PERFORM ADD-VALUE.

ADD-VALUE.
    COMPUTE LS-H1 = FUNCTION MOD(LS-H1 * 131 + LS-V, LS-PRIME-1)
    COMPUTE LS-H2 = FUNCTION MOD(LS-H2 * 257 + LS-V, LS-PRIME-2).

*> LS-STATEMENTS: the statements of the paragraph, nested ones too.
COUNT-STATEMENTS.
    MOVE 0 TO LS-STATEMENTS LS-DEPTH
    MOVE FU-NODE(LS-U) TO LS-NODE
    PERFORM UNTIL LS-NODE = 0
        IF ND-KIND(LS-NODE) = "STMT"
            ADD 1 TO LS-STATEMENTS
        END-IF
        CALL "PLB-AST-NEXT" USING PLB-AST FU-NODE(LS-U) LS-NODE LS-DEPTH
    END-PERFORM.
END PROGRAM PLB-DUP-COLLECT.

*> PLB-DUP-PRINT: the groups of paragraphs with the same body, largest
*> first; as text or JSON (FORMAT "json").
*>   text:  4 copies of 37 tokens, 6 statements:
*>            src/a.cob:120 FORMAT-TOTALS in RPTA
*>            ...
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-DUP-PRINT.
DATA DIVISION.
WORKING-STORAGE SECTION.
01  WS-LINE                 PIC X(1024).
01  WS-PATH                 PIC X(512).
*> The entries in group order: by tokens (down), then by hashes, then
*> by file and line.
01  WS-ORDER-COUNT          PIC 9(9) COMP-5.
01  WS-ORDER                OCCURS 0 TO 50000 TIMES
                            DEPENDING ON WS-ORDER-COUNT.
    05  WS-OR-TOKENS        PIC 9(9) COMP-5.
    05  WS-OR-HASH-1        PIC S9(18) COMP-5.
    05  WS-OR-HASH-2        PIC S9(18) COMP-5.
    05  WS-OR-FILE          PIC 9(4) COMP-5.
    05  WS-OR-LINE          PIC 9(9) COMP-5.
    05  WS-OR-ENTRY         PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-J                    PIC 9(9) COMP-5.
01  LS-K                    PIC 9(9) COMP-5.
01  LS-E                    PIC 9(9) COMP-5.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-GROUPS               PIC 9(9) COMP-5.
01  LS-FIRST-GROUP          PIC X.
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbdupt.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-DUPLICATES LK-FORMAT.
    MOVE DP-COUNT TO WS-ORDER-COUNT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > DP-COUNT
        MOVE DP-TOKENS(LS-I) TO WS-OR-TOKENS(LS-I)
        MOVE DP-HASH-1(LS-I) TO WS-OR-HASH-1(LS-I)
        MOVE DP-HASH-2(LS-I) TO WS-OR-HASH-2(LS-I)
        MOVE DP-FILE-ID(LS-I) TO WS-OR-FILE(LS-I)
        MOVE DP-LINE(LS-I) TO WS-OR-LINE(LS-I)
        MOVE LS-I TO WS-OR-ENTRY(LS-I)
    END-PERFORM
    IF WS-ORDER-COUNT > 1
        SORT WS-ORDER ON DESCENDING KEY WS-OR-TOKENS
                         ASCENDING KEY WS-OR-HASH-1 WS-OR-HASH-2
                                       WS-OR-FILE WS-OR-LINE
    END-IF
    IF LK-FORMAT = "json"
        DISPLAY "{"
        DISPLAY '  "groups": ['
    END-IF
    MOVE 0 TO LS-GROUPS
    MOVE "Y" TO LS-FIRST-GROUP
    MOVE 1 TO LS-I
    PERFORM UNTIL LS-I > WS-ORDER-COUNT
        *> LS-J: the last entry of the group that starts at LS-I.
        MOVE LS-I TO LS-J
        PERFORM UNTIL LS-J >= WS-ORDER-COUNT
            IF WS-OR-TOKENS(LS-J + 1) NOT = WS-OR-TOKENS(LS-I)
               OR WS-OR-HASH-1(LS-J + 1) NOT = WS-OR-HASH-1(LS-I)
               OR WS-OR-HASH-2(LS-J + 1) NOT = WS-OR-HASH-2(LS-I)
                EXIT PERFORM
            END-IF
            ADD 1 TO LS-J
        END-PERFORM
        IF LS-J > LS-I
            ADD 1 TO LS-GROUPS
            IF LK-FORMAT = "json"
                PERFORM JSON-GROUP
            ELSE
                PERFORM TEXT-GROUP
            END-IF
        END-IF
        COMPUTE LS-I = LS-J + 1
    END-PERFORM
    IF LK-FORMAT = "json"
        IF LS-GROUPS > 0
            DISPLAY "    }"
        END-IF
        DISPLAY "  ]"
        DISPLAY "}"
    ELSE
        IF LS-GROUPS = 0
            DISPLAY "no paragraphs with the same code"
        END-IF
    END-IF
    GOBACK.

TEXT-GROUP.
    IF LS-FIRST-GROUP = "N"
        CALL STATIC "putchar" USING BY VALUE 10
    END-IF
    MOVE "N" TO LS-FIRST-GROUP
    MOVE WS-OR-ENTRY(LS-I) TO LS-E
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    COMPUTE LS-NUM = LS-J - LS-I + 1
    PERFORM APPEND-NUM
    STRING " copies of " DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DP-TOKENS(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    STRING " tokens, " DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DP-STATEMENTS(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    IF DP-STATEMENTS(LS-E) = 1
        STRING " statement:" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    ELSE
        STRING " statements:" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    DISPLAY WS-LINE(1:LS-PTR - 1)
    PERFORM VARYING LS-K FROM LS-I BY 1 UNTIL LS-K > LS-J
        MOVE WS-OR-ENTRY(LS-K) TO LS-E
        MOVE SPACES TO WS-LINE
        MOVE 1 TO LS-PTR
        STRING "  " DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
        PERFORM APPEND-POSITION
        STRING " " DELIMITED BY SIZE
               DP-NAME(LS-E) DELIMITED BY SPACE
            INTO WS-LINE WITH POINTER LS-PTR
        IF DP-PROGRAM(LS-E) NOT = SPACES
            STRING " in " DELIMITED BY SIZE
                   DP-PROGRAM(LS-E) DELIMITED BY SPACE
                INTO WS-LINE WITH POINTER LS-PTR
        END-IF
        DISPLAY WS-LINE(1:LS-PTR - 1)
    END-PERFORM.

JSON-GROUP.
    IF LS-FIRST-GROUP = "N"
        DISPLAY "    },"
    END-IF
    MOVE "N" TO LS-FIRST-GROUP
    MOVE WS-OR-ENTRY(LS-I) TO LS-E
    DISPLAY "    {"
    MOVE SPACES TO WS-LINE
    MOVE 1 TO LS-PTR
    STRING '      "tokens": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DP-TOKENS(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    STRING ', "statements": ' DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR
    MOVE DP-STATEMENTS(LS-E) TO LS-NUM
    PERFORM APPEND-NUM
    STRING "," DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
    DISPLAY WS-LINE(1:LS-PTR - 1)
    DISPLAY '      "paragraphs": ['
    PERFORM VARYING LS-K FROM LS-I BY 1 UNTIL LS-K > LS-J
        MOVE WS-OR-ENTRY(LS-K) TO LS-E
        MOVE SPACES TO WS-LINE
        MOVE 1 TO LS-PTR
        STRING '        {"name": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        CALL "PLB-JSON-STRING" USING DP-NAME(LS-E) WS-LINE LS-PTR
        STRING ', "program": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        CALL "PLB-JSON-STRING" USING DP-PROGRAM(LS-E) WS-LINE LS-PTR
        STRING ', "file": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        PERFORM ENTRY-PATH
        CALL "PLB-JSON-STRING" USING WS-PATH WS-LINE LS-PTR
        STRING ', "line": ' DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
        MOVE DP-LINE(LS-E) TO LS-NUM
        PERFORM APPEND-NUM
        STRING "}" DELIMITED BY SIZE INTO WS-LINE WITH POINTER LS-PTR
        IF LS-K < LS-J
            STRING "," DELIMITED BY SIZE
                INTO WS-LINE WITH POINTER LS-PTR
        END-IF
        DISPLAY WS-LINE(1:LS-PTR - 1)
    END-PERFORM
    DISPLAY "      ]".

*> WS-PATH: the path of the file of entry LS-E.
ENTRY-PATH.
    MOVE SPACES TO WS-PATH
    IF DP-FILE-ID(LS-E) > 0
        CALL "PLB-SRC-FILE-PATH" USING PLB-SOURCE-SET DP-FILE-ID(LS-E)
            WS-PATH
    END-IF.

APPEND-POSITION.
    PERFORM ENTRY-PATH
    CALL "PLB-STR-LENGTH" USING WS-PATH LS-LEN
    IF LS-LEN > 0
        STRING WS-PATH(1:LS-LEN) ":" DELIMITED BY SIZE
            INTO WS-LINE WITH POINTER LS-PTR
    END-IF
    MOVE DP-LINE(LS-E) TO LS-NUM
    PERFORM APPEND-NUM.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO WS-LINE WITH POINTER LS-PTR.
END PROGRAM PLB-DUP-PRINT.
