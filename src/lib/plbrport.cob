*> ---------------------------------------------------------------
*> plbrport: portability rules.
*>
*>   PLB-P001  vendor-routine
*>   PLB-P002  hard-coded-path
*>
*> A program moves between compilers and between machines. Library
*> routines such as CBL_CREATE_FILE belong to one compiler family, and
*> a file named "/var/data/in.dat" or "C:\DATA\IN.DAT" exists on one
*> machine.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-PORTABILITY.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE-VENDOR          PIC 9(4) COMP-5.
01  LS-RULE-PATH            PIC 9(4) COMP-5.
01  LS-ROOT                 PIC 9(9) COMP-5 VALUE 1.
01  LS-N                    PIC 9(9) COMP-5.
01  LS-DEPTH                PIC S9(9) COMP-5.
01  LS-PROGRAM              PIC 9(9) COMP-5.
01  LS-UP                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-CHILD                PIC 9(9) COMP-5.
01  LS-I                    PIC 9(4) COMP-5.
01  LS-TEXT                 PIC X(256).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-WORD                 PIC X(31).
01  LS-ITEM                 PIC X(31).
01  LS-PATH-TOKEN           PIC 9(9) COMP-5.
01  LS-IS-PATH              PIC X.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbsym.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-SYMBOLS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-P001" LS-RULE-VENDOR
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-P002" LS-RULE-PATH
    IF AS-COUNT = 0
        GOBACK
    END-IF
    MOVE 1 TO LS-N
    MOVE 0 TO LS-DEPTH
    PERFORM UNTIL LS-N = 0
        EVALUATE TRUE
            WHEN ND-KIND(LS-N) = "STMT" AND ND-DETAIL(LS-N) = "CALL"
                PERFORM CHECK-CALL
            WHEN ND-KIND(LS-N) = "SELE"
                PERFORM CHECK-ASSIGN
        END-EVALUATE
        CALL "PLB-AST-NEXT" USING PLB-AST LS-ROOT LS-N LS-DEPTH
    END-PERFORM
    GOBACK.

*> PLB-P001: CALL "CBL_..." or "C$...", the library routines of the
*> Micro Focus and ACUCOBOL families that GnuCOBOL also provides.
CHECK-CALL.
    IF RL-ENABLED(LS-RULE-VENDOR) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    COMPUTE LS-T = ND-TOK-FIRST(LS-N) + 1
    IF LS-T > ND-TOK-LAST(LS-N) OR NOT TK-IS-ALNUM(LS-T)
        EXIT PARAGRAPH
    END-IF
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-TEXT) TO LS-TEXT
    IF LS-TEXT(1:4) NOT = "CBL_" AND LS-TEXT(1:2) NOT = "C$"
       AND LS-TEXT NOT = "SYSTEM"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING LS-TEXT DELIMITED BY SPACE
           " is a library routine of some compilers, not standard"
           DELIMITED BY SIZE
           " COBOL; keep such calls in one place" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-VENDOR LS-T LS-MESSAGE.

*> PLB-P002: ASSIGN TO a literal that is a path, or to a data item
*> whose VALUE is one.
CHECK-ASSIGN.
    IF RL-ENABLED(LS-RULE-PATH) NOT = "Y"
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-N) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-N)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
            IF LS-WORD = "ASSIGN"
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    ADD 1 TO LS-T
    *> Skip TO, USING, and the DYNAMIC / EXTERNAL / DISK words that
    *> some compilers allow before the target.
    PERFORM UNTIL LS-T > ND-TOK-LAST(LS-N) OR NOT TK-IS-WORD(LS-T)
        CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-WORD LS-LEN
        EVALUATE LS-WORD
            WHEN "TO" WHEN "USING" WHEN "DYNAMIC" WHEN "EXTERNAL"
            WHEN "DISK"
                ADD 1 TO LS-T
            WHEN OTHER
                EXIT PERFORM
        END-EVALUATE
    END-PERFORM
    IF LS-T > ND-TOK-LAST(LS-N)
        EXIT PARAGRAPH
    END-IF
    EVALUATE TRUE
        WHEN TK-IS-ALNUM(LS-T)
            MOVE LS-T TO LS-PATH-TOKEN
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            PERFORM CHECK-PATH-TEXT
            IF LS-IS-PATH = "Y"
                MOVE SPACES TO LS-ITEM
                PERFORM REPORT-PATH
            END-IF
        WHEN TK-IS-WORD(LS-T)
            MOVE LS-WORD TO LS-ITEM
            PERFORM CHECK-ASSIGNED-ITEM
    END-EVALUATE.

*> The item named in ASSIGN TO: an item of the same program with a
*> VALUE literal that is a path.
CHECK-ASSIGNED-ITEM.
    MOVE LS-N TO LS-UP
    PERFORM UNTIL LS-UP = 0 OR ND-KIND(LS-UP) = "PROG"
        MOVE ND-PARENT(LS-UP) TO LS-UP
    END-PERFORM
    MOVE LS-UP TO LS-PROGRAM
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > SY-COUNT
        IF SY-PROGRAM(LS-S) = LS-PROGRAM AND SY-NAME(LS-S) = LS-ITEM
           AND SY-HAS-VALUE(LS-S) = "Y"
            PERFORM CHECK-ITEM-VALUE
            EXIT PERFORM
        END-IF
    END-PERFORM.

CHECK-ITEM-VALUE.
    MOVE ND-FIRST(SY-NODE(LS-S)) TO LS-CHILD
    PERFORM UNTIL LS-CHILD = 0
        IF ND-KIND(LS-CHILD) = "CLAU" AND ND-DETAIL(LS-CHILD) = "VALUE"
            PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-CHILD) BY 1
                    UNTIL LS-T > ND-TOK-LAST(LS-CHILD)
                IF TK-IS-ALNUM(LS-T)
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT
                        LS-LEN
                    PERFORM CHECK-PATH-TEXT
                    IF LS-IS-PATH = "Y"
                        MOVE LS-T TO LS-PATH-TOKEN
                        PERFORM REPORT-PATH
                    END-IF
                    EXIT PERFORM
                END-IF
            END-PERFORM
            EXIT PERFORM
        END-IF
        MOVE ND-NEXT(LS-CHILD) TO LS-CHILD
    END-PERFORM.

*> LS-IS-PATH = "Y" when LS-TEXT (LS-LEN characters) holds a directory
*> separator or starts with a drive letter. A bare name such as
*> "INFILE" or "in.dat" is resolved at run time (by a DD statement or
*> an environment variable) and is portable.
CHECK-PATH-TEXT.
    MOVE "N" TO LS-IS-PATH
    IF LS-LEN = 0
        EXIT PARAGRAPH
    END-IF
    IF LS-LEN > 256
        MOVE 256 TO LS-LEN
    END-IF
    IF LS-LEN >= 2 AND LS-TEXT(2:1) = ":"
       AND LS-TEXT(1:1) IS ALPHABETIC
        MOVE "Y" TO LS-IS-PATH
        EXIT PARAGRAPH
    END-IF
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > LS-LEN
        IF LS-TEXT(LS-I:1) = "/" OR LS-TEXT(LS-I:1) = "\"
            MOVE "Y" TO LS-IS-PATH
            EXIT PERFORM
        END-IF
    END-PERFORM.

REPORT-PATH.
    MOVE SPACES TO LS-MESSAGE
    IF LS-ITEM = SPACES
        STRING "file " DELIMITED BY SIZE
               LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
               " is a path on one machine; assign a name resolved at"
               DELIMITED BY SIZE
               " run time" DELIMITED BY SIZE
            INTO LS-MESSAGE
    ELSE
        STRING "file " DELIMITED BY SIZE
               LS-TEXT(1:LS-LEN) DELIMITED BY SIZE
               " (VALUE of " DELIMITED BY SIZE
               LS-ITEM DELIMITED BY SPACE
               ") is a path on one machine; assign a name resolved at"
               DELIMITED BY SIZE
               " run time" DELIMITED BY SIZE
            INTO LS-MESSAGE
    END-IF
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE-PATH LS-PATH-TOKEN LS-MESSAGE.
END PROGRAM PLB-RULE-PORTABILITY.
