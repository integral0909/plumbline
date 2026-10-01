*> ---------------------------------------------------------------
*> plbrule: the rule catalog and the findings table.
*> ---------------------------------------------------------------

*> PLB-RULES-INIT: the catalog of rules, all enabled at their
*> default severity.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULES-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbrules.cpy".
PROCEDURE DIVISION USING PLB-RULES.
    MOVE 0 TO RL-COUNT
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C001"
        "unreachable-code" "W"
        "Paragraph or section can never be executed"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C002"
        "perform-and-fall-through" "W"
        "Paragraph is both performed and fallen into"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C003"
        "fall-off-end" "W"
        "Control can run off the end of the procedure division"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C004"
        "next-sentence-in-scope" "W"
        "NEXT SENTENCE inside a scope ended by an END- terminator"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C005"
        "perform-thru-backwards" "E"
        "PERFORM THRU range ends before it starts"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C006"
        "recursive-perform" "E"
        "Paragraph performs a range that contains itself"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C007"
        "redefines-larger" "E"
        "REDEFINES item is larger than the item it redefines"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C008"
        "move-truncation" "W"
        "MOVE loses characters or high-order digits"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C009"
        "undefined-name" "E"
        "Name is not declared"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C010"
        "ambiguous-name" "E"
        "Name refers to more than one data item"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C011"
        "read-never-set" "W"
        "Data item is read but never given a value"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C012"
        "use-before-set" "W"
        "Data item is read before any path gives it a value"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C013"
        "call-argument-count" "W"
        "CALL passes a different number of arguments than the program takes"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C014"
        "call-argument-mismatch" "W"
        "CALL argument is passed differently or is smaller than its parameter"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C015"
        "recursive-call" "E"
        "Program that is not RECURSIVE can be called while it is running"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C016"
        "report-not-initiated" "W"
        "Report is generated or terminated but never initiated"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C017"
        "report-not-terminated" "W"
        "Report is initiated but never terminated"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C018"
        "sql-not-checked" "W"
        "Result of an SQL statement is not checked"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C019"
        "cics-response-not-checked" "W"
        "Response of a CICS command is not checked"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C020"
        "file-status-not-checked" "W"
        "FILE STATUS is not tested after an I/O statement"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C021"
        "file-not-opened" "W"
        "File is used but never opened"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C022"
        "open-mode-mismatch" "E"
        "I/O statement needs an open mode the file is never opened in"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M001"
        "go-to" "N"
        "GO TO statement"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M002"
        "alter" "W"
        "ALTER statement (obsolete)"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M003"
        "unused-data-item" "W"
        "Data item is never referenced"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M005"
        "set-never-read" "N"
        "Data item is given values but never read"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M004"
        "alnum-narrowing" "N"
        "MOVE from a larger alphanumeric item to a smaller one"
    *> Moving a large buffer into a smaller field is common and often
    *> intended, so this rule is only run on request.
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M006"
        "dynamic-call" "N"
        "CALL of a program named by a data item"
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M007"
        "detail-never-generated" "N"
        "Report detail group is never generated"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M008"
        "file-not-closed" "N"
        "File is opened but never closed"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M009"
        "complex-paragraph" "N"
        "Paragraph or section is more complex than the limit"
    MOVE 15 TO RL-LIMIT(RL-COUNT)
    *> Size limits are a team's choice, and a paragraph that dispatches
    *> through one long EVALUATE is complex by count but easy to read:
    *> these rules only run on request.
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M010"
        "long-paragraph" "N"
        "Paragraph or section has more statements than the limit"
    MOVE 50 TO RL-LIMIT(RL-COUNT)
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-S001"
        "dynamic-sql" "N"
        "SQL text is built at run time"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-S002"
        "hard-coded-credential" "W"
        "Credential is written into the program"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-S003"
        "sensitive-data-displayed" "W"
        "DISPLAY writes a credential or personal data"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-S004"
        "shell-command" "N"
        "Shell command is taken from a data item"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-P001"
        "vendor-routine" "N"
        "CALL of a compiler library routine"
    *> Most programs built with one compiler call its library on
    *> purpose: this rule is for code meant to move between compilers.
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-P002"
        "hard-coded-path" "W"
        "File is assigned to a path on one machine"
    GOBACK.
END PROGRAM PLB-RULES-INIT.

*> PLB-RULE-DEFINE: append a rule to the catalog.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-DEFINE.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbrules.cpy".
01  LK-ID                   PIC X ANY LENGTH.
01  LK-NAME                 PIC X ANY LENGTH.
01  LK-SEVERITY             PIC X.
01  LK-TITLE                PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-RULES LK-ID LK-NAME LK-SEVERITY LK-TITLE.
    IF RL-COUNT < RL-MAX
        ADD 1 TO RL-COUNT
        MOVE LK-ID TO RL-ID(RL-COUNT)
        MOVE LK-NAME TO RL-NAME(RL-COUNT)
        MOVE LK-SEVERITY TO RL-SEVERITY(RL-COUNT)
        MOVE "Y" TO RL-ENABLED(RL-COUNT)
        MOVE LK-TITLE TO RL-TITLE(RL-COUNT)
        MOVE 0 TO RL-LIMIT(RL-COUNT)
    END-IF
    GOBACK.
END PROGRAM PLB-RULE-DEFINE.

*> PLB-RULE-FIND: INDEX receives the catalog index of the rule whose
*> id or name is KEY (case-insensitive), or 0.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-FIND.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-KEY                  PIC X(32).
01  LS-I                    PIC 9(4) COMP-5.
LINKAGE SECTION.
COPY "plbrules.cpy".
01  LK-KEY                  PIC X ANY LENGTH.
01  LK-INDEX                PIC 9(4) COMP-5.
PROCEDURE DIVISION USING PLB-RULES LK-KEY LK-INDEX.
    MOVE 0 TO LK-INDEX
    MOVE LK-KEY TO LS-KEY
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > RL-COUNT
        IF FUNCTION UPPER-CASE(LS-KEY) = RL-ID(LS-I)
           OR FUNCTION LOWER-CASE(LS-KEY) = RL-NAME(LS-I)
            MOVE LS-I TO LK-INDEX
            EXIT PERFORM
        END-IF
    END-PERFORM
    GOBACK.
END PROGRAM PLB-RULE-FIND.

*> PLB-FIND-INIT: empty the findings table.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-INIT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-FINDINGS.
    MOVE 0 TO FN-COUNT FN-DROPPED
    GOBACK.
END PROGRAM PLB-FIND-INIT.

*> PLB-FIND-AT-TOKEN: report rule RULE at token TOKEN with MESSAGE,
*> at the rule's configured severity. Disabled rules report nothing.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-AT-TOKEN.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-FILE-ID              PIC 9(4) COMP-5 VALUE 0.
01  LS-LINE                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 0.
01  LS-SRC-LINE             PIC 9(9) COMP-5 VALUE 0.
LINKAGE SECTION.
COPY "plbsrc.cpy".
COPY "plbtokc.cpy".
COPY "plbtok.cpy".
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-RULE                 PIC 9(4) COMP-5.
01  LK-TOKEN                PIC 9(9) COMP-5.
01  LK-MESSAGE              PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-SOURCE-SET PLB-TOKENS PLB-RULES
        PLB-FINDINGS LK-RULE LK-TOKEN LK-MESSAGE.
    IF LK-TOKEN >= 1 AND LK-TOKEN <= TK-COUNT
        MOVE TK-FILE-ID(LK-TOKEN) TO LS-FILE-ID
        MOVE TK-SRC-LINE(LK-TOKEN) TO LS-SRC-LINE
        IF LS-SRC-LINE > 0
            MOVE SL-LINE-NO(LS-SRC-LINE) TO LS-LINE
        END-IF
        MOVE TK-COLUMN(LK-TOKEN) TO LS-COLUMN
    END-IF
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LK-RULE LS-FILE-ID
        LS-LINE LS-COLUMN LS-SRC-LINE LK-MESSAGE
    GOBACK.
END PROGRAM PLB-FIND-AT-TOKEN.

*> PLB-FIND-AT: report rule RULE with MESSAGE at a position given as
*> file, line, column, and SS-LINE index (0 when unknown), at the
*> rule's configured severity. Disabled rules report nothing.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-AT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-RULE                 PIC 9(4) COMP-5.
01  LK-FILE-ID              PIC 9(4) COMP-5.
01  LK-LINE                 PIC 9(9) COMP-5.
01  LK-COLUMN               PIC 9(4) COMP-5.
01  LK-SRC-LINE             PIC 9(9) COMP-5.
01  LK-MESSAGE              PIC X ANY LENGTH.
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS LK-RULE LK-FILE-ID
        LK-LINE LK-COLUMN LK-SRC-LINE LK-MESSAGE.
    IF LK-RULE < 1 OR LK-RULE > RL-COUNT
        GOBACK
    END-IF
    IF RL-ENABLED(LK-RULE) NOT = "Y"
        GOBACK
    END-IF
    IF FN-COUNT >= FN-MAX
        ADD 1 TO FN-DROPPED
        GOBACK
    END-IF
    ADD 1 TO FN-COUNT
    MOVE LK-RULE TO FN-RULE(FN-COUNT)
    MOVE RL-SEVERITY(LK-RULE) TO FN-SEVERITY(FN-COUNT)
    MOVE LK-MESSAGE TO FN-MESSAGE(FN-COUNT)
    MOVE "N" TO FN-SUPPRESSED(FN-COUNT)
    MOVE LK-FILE-ID TO FN-FILE-ID(FN-COUNT)
    MOVE LK-LINE TO FN-LINE(FN-COUNT)
    MOVE LK-COLUMN TO FN-COLUMN(FN-COUNT)
    MOVE LK-SRC-LINE TO FN-SRC-LINE(FN-COUNT)
    GOBACK.
END PROGRAM PLB-FIND-AT.

*> PLB-FIND-SORT: order findings by file, line, column, and rule.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-SORT.
DATA DIVISION.
LINKAGE SECTION.
COPY "plbfind.cpy".
PROCEDURE DIVISION USING PLB-FINDINGS.
    IF FN-COUNT > 1
        SORT FN-ENTRY ON ASCENDING KEY FN-FILE-ID FN-LINE FN-COLUMN
            FN-RULE
    END-IF
    GOBACK.
END PROGRAM PLB-FIND-SORT.

*> PLB-FIND-FORMAT: finding INDEX as one line of text:
*>     path:line:column: severity: message [PLB-C001]
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-FIND-FORMAT.
DATA DIVISION.
LOCAL-STORAGE SECTION.
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
01  LK-INDEX                PIC 9(9) COMP-5.
01  LK-PATH                 PIC X ANY LENGTH.
01  LK-TEXT                 PIC X ANY LENGTH.
01  LK-LENGTH               PIC 9(9) COMP-5.
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS LK-INDEX LK-PATH
        LK-TEXT LK-LENGTH.
    MOVE SPACES TO LK-TEXT
    MOVE 1 TO LS-PTR
    CALL "PLB-STR-LENGTH" USING LK-PATH LS-LEN
    IF LS-LEN > 0
        STRING LK-PATH(1:LS-LEN) DELIMITED BY SIZE
            INTO LK-TEXT WITH POINTER LS-PTR
    END-IF
    MOVE FN-LINE(LK-INDEX) TO LS-NUM
    PERFORM APPEND-NUMBER
    MOVE FN-COLUMN(LK-INDEX) TO LS-NUM
    PERFORM APPEND-NUMBER
    EVALUATE FN-SEVERITY(LK-INDEX)
        WHEN "E"
            STRING ": error: " DELIMITED BY SIZE
                INTO LK-TEXT WITH POINTER LS-PTR
        WHEN "N"
            STRING ": note: " DELIMITED BY SIZE
                INTO LK-TEXT WITH POINTER LS-PTR
        WHEN OTHER
            STRING ": warning: " DELIMITED BY SIZE
                INTO LK-TEXT WITH POINTER LS-PTR
    END-EVALUATE
    CALL "PLB-STR-LENGTH" USING FN-MESSAGE(LK-INDEX) LS-LEN
    IF LS-LEN > 0
        STRING FN-MESSAGE(LK-INDEX)(1:LS-LEN) DELIMITED BY SIZE
            INTO LK-TEXT WITH POINTER LS-PTR
    END-IF
    STRING " [" DELIMITED BY SIZE
           RL-ID(FN-RULE(LK-INDEX)) DELIMITED BY SPACE
           "]" DELIMITED BY SIZE
        INTO LK-TEXT WITH POINTER LS-PTR
    COMPUTE LK-LENGTH = LS-PTR - 1
    GOBACK.

APPEND-NUMBER.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING ":" LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LK-TEXT WITH POINTER LS-PTR.
END PROGRAM PLB-FIND-FORMAT.
