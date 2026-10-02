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
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M011"
        "evaluate-without-other" "N"
        "EVALUATE has no WHEN OTHER"
    *> A team's convention, like the size limits.
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M012"
        "deep-nesting" "N"
        "Statements are nested deeper than the limit"
    MOVE 5 TO RL-LIMIT(RL-COUNT)
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M013"
        "unused-copybook" "N"
        "Copybook declares data the program never uses"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M014"
        "sql-select-star" "N"
        "Embedded SQL selects every column with SELECT *"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M015"
        "packed-even-digits" "N"
        "Packed-decimal item has an even number of digits"
    *> A shop's coding standard: on request.
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M016"
        "signed-to-alphanumeric" "N"
        "MOVE of a signed integer to an alphanumeric item"
    *> Most signed items moved to text (counts, response codes) are
    *> never negative, so this rule is only run on request.
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-M017"
        "two-digit-year" "N"
        "ACCEPT FROM DATE or DAY gives a two-digit year"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-Q001"
        "sql-table-undeclared" "N"
        "Embedded SQL uses a table the program does not declare"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-Q002"
        "cursor-not-closed" "W"
        "SQL cursor is opened but never closed"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-Q003"
        "cursor-not-opened" "E"
        "SQL cursor is fetched or closed but never opened"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-Q004"
        "sql-no-where" "W"
        "SQL UPDATE or DELETE without WHERE changes every row"
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
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C023"
        "subscript-out-of-range" "E"
        "Literal subscript is outside the table"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C024"
        "refmod-out-of-range" "E"
        "Literal reference modification is outside the item"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C025"
        "stop-run-in-called-program" "W"
        "STOP RUN in a program that is called"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C026"
        "varying-limit-unreachable" "W"
        "PERFORM VARYING waits for a value its counter cannot hold"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C027"
        "divide-by-zero" "E"
        "Divisor is a literal zero"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C028"
        "comparison-never-true" "W"
        "Data item is compared with a value it cannot hold"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C029"
        "go-to-leaves-perform" "W"
        "GO TO leaves the range of a PERFORM, which then does not return"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C030"
        "value-never-used" "W"
        "Value is replaced before it is used"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C031"
        "string-overflow" "W"
        "STRING always sends more than its receiver holds"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-A001"
        "unused-program" "N"
        "Program is not called, run by a job, or started by a transaction"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-B001"
        "map-fields-overlap" "E"
        "Two fields of a BMS map share screen positions"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-B002"
        "field-outside-map" "E"
        "A BMS field ends past the end of its map"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-B003"
        "map-not-in-mapset" "E"
        "Program sends or receives a map its mapset does not define"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-B004"
        "symbolic-map-stale" "E"
        "Symbolic map copybook does not match its BMS map"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C032"
        "duplicate-when" "W"
        "EVALUATE has a WHEN that repeats an earlier one"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C033"
        "self-move" "W"
        "MOVE of an item to itself"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C034"
        "linkage-not-addressed" "E"
        "LINKAGE record is used but nothing gives it an address"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C035"
        "duplicate-paragraph" "W"
        "Paragraph or section name defined twice in the same scope"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C036"
        "arithmetic-overflow" "W"
        "ADD, SUBTRACT, or MULTIPLY into a receiver narrower than an operand"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C037"
        "search-index-not-set" "W"
        "Serial SEARCH whose index the paragraph does not set first"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C038"
        "condition-value-unfit" "W"
        "Condition name with a value its item cannot hold"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C039"
        "decimal-to-alphanumeric" "W"
        "MOVE of a number with decimal places to an alphanumeric item"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C040"
        "odo-object-too-small" "W"
        "OCCURS DEPENDING ON object cannot hold the table's largest count"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C041"
        "write-from-truncation" "W"
        "WRITE or REWRITE FROM an item longer than the record"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C042"
        "inspect-count-not-reset" "W"
        "INSPECT TALLYING adds to a count the paragraph does not reset"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C043"
        "pointer-not-reset" "W"
        "STRING or UNSTRING POINTER that no statement sets"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C044"
        "varying-control-changed" "W"
        "Statement in a PERFORM VARYING loop changes the loop's control"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C045"
        "alnum-compared-to-number" "W"
        "Alphanumeric item compared with a shorter numeric literal"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C046"
        "overlapping-move" "W"
        "MOVE between items that share storage"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C047"
        "foreign-index" "W"
        "Index of one table subscripts a table with entries of another length"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C048"
        "sort-procedure-no-record" "W"
        "SORT procedure never RELEASEs or RETURNs a record"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-C049"
        "loop-condition-unchanged" "W"
        "PERFORM UNTIL loop never changes what its condition reads"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-I001"
        "pcb-dbd-unknown" "E"
        "PCB names a database no DBD of the run defines"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-I002"
        "senseg-not-in-dbd" "E"
        "Sensitive segment is not in its database as written"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-I003"
        "segment-not-sensitive" "E"
        "DL/I call names a segment the program's PSB is not sensitive to"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-I004"
        "procopt-forbids-call" "E"
        "DL/I call that no PCB of the segment allows"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-K001"
        "cics-resource-undefined" "E"
        "EXEC CICS names a resource the CICS definitions do not define"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-K002"
        "read-update-not-released" "W"
        "CICS READ UPDATE of a file the program never rewrites or unlocks"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-J001"
        "dd-missing" "E"
        "A file the step's programs open has no DD in the step"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-J002"
        "dd-unused" "N"
        "DD is not a file of the step's programs"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-J003"
        "program-not-in-run" "N"
        "Step runs a program that is not among those checked"
    *> Most jobs also run utilities (IDCAMS, SORT, IEBGENER): on
    *> request, for runs meant to hold every program of the jobs.
    MOVE "N" TO RL-ENABLED(RL-COUNT)
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-J004"
        "dd-cannot-be-read" "E"
        "A file the program only reads has a DD that gives it no data"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-J005"
        "temp-not-created" "E"
        "Temporary data set read before any step creates it"
    CALL "PLB-RULE-DEFINE" USING PLB-RULES "PLB-J006"
        "lrecl-mismatch" "E"
        "DD record length differs from the program's records"
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
    ELSE
        *> A rule left out would change what the next MOVE to
        *> RL-ENABLED(RL-COUNT) or RL-LIMIT(RL-COUNT) applies to.
        DISPLAY "plumbline: internal error: the rule catalog is full ("
            "raise RL-MAX in plbrules.cpy)" UPON SYSERR
        MOVE 3 TO RETURN-CODE
        *> plumbline: ignore stop-run-in-called-program -- nothing can go on
        STOP RUN
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
COPY "plbsrcc.cpy".
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

*> PLB-RULES-LIST: write the rule catalog, as configured, to standard
*> output. FORMAT is "text" (one line per rule) or "json".
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULES-LIST.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbver.cpy".
LOCAL-STORAGE SECTION.
01  LS-R                    PIC 9(4) COMP-5.
01  LS-SEVERITY             PIC X(7).
01  LS-STATE                PIC X(3).
01  LS-OUT                  PIC X(400).
01  LS-PTR                  PIC 9(9) COMP-5.
01  LS-LEN                  PIC 9(9) COMP-5.
01  LS-NUM                  PIC S9(18) COMP-5.
01  LS-NUM-TEXT             PIC X(20).
01  LS-NUM-LEN              PIC 9(9) COMP-5.
01  LS-SEPARATOR            PIC X.
LINKAGE SECTION.
COPY "plbrules.cpy".
01  LK-FORMAT               PIC X(5).
PROCEDURE DIVISION USING PLB-RULES LK-FORMAT.
    IF LK-FORMAT = "json"
        DISPLAY "{"
        DISPLAY '  "tool": "' PLB-NAME '",'
        DISPLAY '  "version": "' PLB-VERSION '",'
        DISPLAY '  "rules": ['
    END-IF
    MOVE SPACE TO LS-SEPARATOR
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > RL-COUNT
        EVALUATE RL-SEVERITY(LS-R)
            WHEN "E"
                MOVE "error" TO LS-SEVERITY
            WHEN "W"
                MOVE "warning" TO LS-SEVERITY
            WHEN OTHER
                MOVE "note" TO LS-SEVERITY
        END-EVALUATE
        MOVE SPACES TO LS-OUT
        MOVE 1 TO LS-PTR
        IF LK-FORMAT = "json"
            PERFORM JSON-RULE
        ELSE
            PERFORM TEXT-RULE
        END-IF
        CALL "PLB-STR-LENGTH" USING LS-OUT LS-LEN
        DISPLAY LS-OUT(1:LS-LEN)
    END-PERFORM
    IF LK-FORMAT = "json"
        DISPLAY "  ]"
        DISPLAY "}"
    END-IF
    GOBACK.

*> PLB-C001  unreachable-code  warning  on  Title [limit N]
TEXT-RULE.
    IF RL-ENABLED(LS-R) = "Y"
        MOVE "on" TO LS-STATE
    ELSE
        MOVE "off" TO LS-STATE
    END-IF
    STRING RL-ID(LS-R) DELIMITED BY SIZE
           "  " DELIMITED BY SIZE
           RL-NAME(LS-R)(1:28) DELIMITED BY SIZE
           LS-SEVERITY DELIMITED BY SIZE
           "  " DELIMITED BY SIZE
           LS-STATE DELIMITED BY SIZE
           "  " DELIMITED BY SIZE
           RL-TITLE(LS-R) DELIMITED BY "  "
        INTO LS-OUT WITH POINTER LS-PTR
    IF RL-LIMIT(LS-R) > 0
        STRING " (limit " DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        MOVE RL-LIMIT(LS-R) TO LS-NUM
        PERFORM APPEND-NUM
        STRING ")" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF.

JSON-RULE.
    STRING "    " LS-SEPARATOR '{"id": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    MOVE "," TO LS-SEPARATOR
    CALL "PLB-JSON-STRING" USING RL-ID(LS-R) LS-OUT LS-PTR
    STRING ', "name": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING RL-NAME(LS-R) LS-OUT LS-PTR
    STRING ', "severity": "' DELIMITED BY SIZE
           LS-SEVERITY DELIMITED BY SPACE
           '", "enabled": ' DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR
    IF RL-ENABLED(LS-R) = "Y"
        STRING "true" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    ELSE
        STRING "false" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    END-IF
    IF RL-LIMIT(LS-R) > 0
        STRING ', "limit": ' DELIMITED BY SIZE
            INTO LS-OUT WITH POINTER LS-PTR
        MOVE RL-LIMIT(LS-R) TO LS-NUM
        PERFORM APPEND-NUM
    END-IF
    STRING ', "title": ' DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR
    CALL "PLB-JSON-STRING" USING RL-TITLE(LS-R) LS-OUT LS-PTR
    STRING "}" DELIMITED BY SIZE INTO LS-OUT WITH POINTER LS-PTR.

APPEND-NUM.
    CALL "PLB-STR-FROM-INT" USING LS-NUM LS-NUM-TEXT LS-NUM-LEN
    STRING LS-NUM-TEXT(1:LS-NUM-LEN) DELIMITED BY SIZE
        INTO LS-OUT WITH POINTER LS-PTR.
END PROGRAM PLB-RULES-LIST.
