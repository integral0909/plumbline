*> ---------------------------------------------------------------
*> plbrfunused: PLB-M023 file-unused.
*>
*> A file that a SELECT declares and no statement of the procedure
*> division names:
*>
*>     SELECT SPARE-FILE ASSIGN TO SPAREDD.
*>
*> Every use of a file names it: OPEN, CLOSE, READ, START, DELETE,
*> SORT, MERGE, and USE in declaratives. A file none of them names is
*> never opened, and its SELECT, FD, and record are dead. A file whose
*> records a statement uses (WRITE of one, without an OPEN) is
*> PLB-C021's, and not reported here. It still
*> asks for a DD in the JCL that runs the program (PLB-J001), or its
*> DD is there for nothing. EXTERNAL and GLOBAL files, which other
*> programs can use, are not reported.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-M023.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-NODE                 PIC 9(9) COMP-5.
01  LS-FD                   PIC 9(9) COMP-5.
01  LS-T                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-NAME-TOKEN           PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(31).
01  LS-TEXT                 PIC X(31).
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-SHARED               PIC X.
01  LS-THE-FD               PIC 9(9) COMP-5.
01  LS-REC                  PIC 9(9) COMP-5.
01  LS-REC-NAME             PIC X(31).
01  LS-USED                 PIC X.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbsrcc.cpy".
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbastc.cpy".
COPY "plbast.cpy".
COPY "plbref.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-AST PLB-REFS
        PLB-RULES PLB-FINDINGS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-M023" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR AS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-NODE FROM 1 BY 1 UNTIL LS-NODE > AS-COUNT
        IF ND-KIND(LS-NODE) = "SELE" AND ND-NAME(LS-NODE) > 0
            PERFORM CHECK-FILE
        END-IF
    END-PERFORM
    GOBACK.

*> SELECT LS-NODE: its FD is not EXTERNAL or GLOBAL, and some statement
*> names the file.
CHECK-FILE.
    MOVE ND-NAME(LS-NODE) TO LS-NAME-TOKEN
    CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-NAME-TOKEN LS-NAME LS-LEN
    MOVE FUNCTION UPPER-CASE(LS-NAME) TO LS-NAME
    MOVE "N" TO LS-SHARED
    MOVE 0 TO LS-THE-FD
    PERFORM VARYING LS-FD FROM 1 BY 1 UNTIL LS-FD > AS-COUNT
        IF ND-KIND(LS-FD) = "FD" AND ND-NAME(LS-FD) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-FD) LS-TEXT
                LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = LS-NAME
                PERFORM FD-SHARED
                MOVE LS-FD TO LS-THE-FD
            END-IF
        END-IF
    END-PERFORM
    IF LS-SHARED = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE "N" TO LS-USED
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
        IF RF-STMT(LS-R) > 0 AND RF-KIND(LS-R) NOT = "D"
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS RF-TOKEN(LS-R) LS-TEXT
                LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = LS-NAME
                MOVE "Y" TO LS-USED
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM
    IF LS-USED = "Y"
        EXIT PARAGRAPH
    END-IF
    IF LS-THE-FD > 0
        PERFORM RECORD-USED
        IF LS-USED = "Y"
            EXIT PARAGRAPH
        END-IF
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "file " DELIMITED BY SIZE
           LS-NAME DELIMITED BY SPACE
           " is declared but no statement opens or names it"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT-TOKEN" USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LS-RULE LS-NAME-TOKEN LS-MESSAGE.

*> LS-USED = "Y" when a statement names a record of FD LS-THE-FD (a
*> level-01 entry under it).
RECORD-USED.
    MOVE ND-FIRST(LS-THE-FD) TO LS-REC
    PERFORM UNTIL LS-REC = 0 OR LS-USED = "Y"
        IF ND-KIND(LS-REC) = "DATA" AND ND-NAME(LS-REC) > 0
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS ND-NAME(LS-REC)
                LS-REC-NAME LS-LEN
            MOVE FUNCTION UPPER-CASE(LS-REC-NAME) TO LS-REC-NAME
            PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RF-COUNT
                IF RF-STMT(LS-R) > 0
                    CALL "PLB-TOK-TEXT" USING PLB-TOKENS RF-TOKEN(LS-R)
                        LS-TEXT LS-LEN
                    IF FUNCTION UPPER-CASE(LS-TEXT) = LS-REC-NAME
                        MOVE "Y" TO LS-USED
                        EXIT PERFORM
                    END-IF
                END-IF
            END-PERFORM
        END-IF
        MOVE ND-NEXT(LS-REC) TO LS-REC
    END-PERFORM.

*> LS-SHARED = "Y" when FD LS-FD says EXTERNAL or GLOBAL.
FD-SHARED.
    PERFORM VARYING LS-T FROM ND-TOK-FIRST(LS-FD) BY 1
            UNTIL LS-T > ND-TOK-LAST(LS-FD)
        IF TK-IS-WORD(LS-T)
            CALL "PLB-TOK-TEXT" USING PLB-TOKENS LS-T LS-TEXT LS-LEN
            IF FUNCTION UPPER-CASE(LS-TEXT) = "EXTERNAL"
               OR FUNCTION UPPER-CASE(LS-TEXT) = "GLOBAL"
                MOVE "Y" TO LS-SHARED
                EXIT PERFORM
            END-IF
        END-IF
    END-PERFORM.
END PROGRAM PLB-RULE-M023.
