*> ---------------------------------------------------------------
*> plbrapp: rules about the application as a whole: its programs,
*> the jobs that run them, and the transactions that start them.
*>
*>   PLB-A001  unused-program   a program nothing in the run calls,
*>                              runs, starts, or names
*>   PLB-C053  exit-program-in-main  EXIT PROGRAM in a program a job
*>                              step runs (PLB-RULE-C053, below)
*>
*> A program is in use when another program of the run calls it
*> (CALL, or EXEC CICS XCTL, LINK, or LOAD with a constant name), a JCL
*> step runs it (also through IMS's DFSRRC00 or a DB2 RUN PROGRAM), a CICS transaction definition starts it, or another
*> program names it in a literal (a menu table, a name moved to the
*> item an XCTL uses). The rule needs a run that says how programs
*> start: one with JCL or CICS resource definitions among its inputs.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-APPLICATION.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
COPY "plbcsdc.cpy".
*> Per program: whether something in the run reaches it.
01  WS-USED                 PIC X OCCURS CP-MAX TIMES.
*> The literals, sorted, to look program names up in.
01  WS-LITERALS.
    05  WS-LIT-COUNT        PIC 9(9) COMP-5.
    05  WS-LIT              OCCURS 0 TO PL-MAX TIMES
                            DEPENDING ON WS-LIT-COUNT
                            ASCENDING KEY IS WS-LIT-NAME
                            INDEXED BY WS-LIT-IX.
        10  WS-LIT-NAME     PIC X(8).
        10  WS-LIT-OWNER    PIC 9(9) COMP-5.
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-OWNER                PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(8).
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbcall.cpy".
COPY "plbjcl.cpy".
COPY "plbcsd.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH PLB-JCL
        PLB-CSD.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-A001" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y"
        GOBACK
    END-IF
    IF JS-COUNT = 0 AND CR-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        MOVE "N" TO WS-USED(LS-P)
    END-PERFORM
    PERFORM MARK-CALLED
    PERFORM MARK-TRANSFERRED
    PERFORM MARK-RUN
    PERFORM SORT-LITERALS
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-KIND(LS-P) = "P" AND CP-PARENT(LS-P) = 0
           AND WS-USED(LS-P) = "N"
            PERFORM CHECK-NAMED
            IF WS-USED(LS-P) = "N"
                PERFORM REPORT-PROGRAM
            END-IF
        END-IF
    END-PERFORM
    GOBACK.

*> LS-OWNER = the outermost program that program LS-Q is in.
OUTERMOST.
    MOVE CP-OWNER(LS-Q) TO LS-OWNER
    PERFORM UNTIL CP-PARENT(LS-OWNER) = 0
        MOVE CP-PARENT(LS-OWNER) TO LS-OWNER
    END-PERFORM.

*> CALL from another program.
MARK-CALLED.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CC-COUNT
        IF CC-TO(LS-I) > 0
            MOVE CC-FROM(LS-I) TO LS-Q
            PERFORM OUTERMOST
            MOVE LS-OWNER TO LS-P
            MOVE CC-TO(LS-I) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER NOT = LS-P
                MOVE "Y" TO WS-USED(LS-OWNER)
            END-IF
        END-IF
    END-PERFORM.

*> EXEC CICS XCTL, LINK, or LOAD with a constant name.
MARK-TRANSFERRED.
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PU-COUNT
        IF PU-KIND(LS-I) = "P"
            MOVE PU-PROGRAM(LS-I) TO LS-Q
            PERFORM OUTERMOST
            MOVE LS-OWNER TO LS-Q
            MOVE PU-NAME(LS-I) TO LS-NAME
            PERFORM MARK-BY-NAME
        END-IF
    END-PERFORM.

*> JCL steps (EXEC PGM=) and transaction definitions (PROGRAM()).
MARK-RUN.
    MOVE 0 TO LS-Q
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        IF JS-KIND(LS-I) = "P"
            MOVE JS-TARGET(LS-I) TO LS-NAME
            PERFORM MARK-BY-NAME
            IF JS-INNER(LS-I) NOT = SPACES
                MOVE JS-INNER(LS-I) TO LS-NAME
                PERFORM MARK-BY-NAME
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > CR-COUNT
        IF CR-TYPE(LS-I) = "TRANSACTION" AND CR-TARGET(LS-I) NOT = SPACES
            MOVE CR-TARGET(LS-I) TO LS-NAME
            PERFORM MARK-BY-NAME
        END-IF
    END-PERFORM.

*> Every outermost program named LS-NAME, except program LS-Q itself.
MARK-BY-NAME.
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-NAME(LS-P) = LS-NAME AND CP-PARENT(LS-P) = 0
           AND LS-P NOT = LS-Q
            MOVE "Y" TO WS-USED(LS-P)
        END-IF
    END-PERFORM.

SORT-LITERALS.
    MOVE PL-COUNT TO WS-LIT-COUNT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PL-COUNT
        MOVE PL-NAME(LS-I) TO WS-LIT-NAME(LS-I)
        MOVE PL-PROGRAM(LS-I) TO LS-Q
        PERFORM OUTERMOST
        MOVE LS-OWNER TO WS-LIT-OWNER(LS-I)
    END-PERFORM
    IF WS-LIT-COUNT > 1
        SORT WS-LIT ON ASCENDING KEY WS-LIT-NAME
    END-IF.

*> Program LS-P is used when a literal of another program names it.
CHECK-NAMED.
    IF WS-LIT-COUNT = 0 OR CP-NAME(LS-P)(9:) NOT = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE CP-NAME(LS-P) TO LS-NAME
    SEARCH ALL WS-LIT
        AT END
            EXIT PARAGRAPH
        WHEN WS-LIT-NAME(WS-LIT-IX) = LS-NAME
            SET LS-I TO WS-LIT-IX
    END-SEARCH
    *> SEARCH ALL finds one of the equal entries: look at all of them.
    PERFORM UNTIL LS-I = 1
        IF WS-LIT-NAME(LS-I - 1) NOT = LS-NAME
            EXIT PERFORM
        END-IF
        SUBTRACT 1 FROM LS-I
    END-PERFORM
    PERFORM UNTIL LS-I > WS-LIT-COUNT
        IF WS-LIT-NAME(LS-I) NOT = LS-NAME
            EXIT PERFORM
        END-IF
        IF WS-LIT-OWNER(LS-I) NOT = LS-P
            MOVE "Y" TO WS-USED(LS-P)
            EXIT PERFORM
        END-IF
        ADD 1 TO LS-I
    END-PERFORM.

REPORT-PROGRAM.
    MOVE SPACES TO LS-MESSAGE
    STRING "program " DELIMITED BY SIZE
           CP-NAME(LS-P) DELIMITED BY SPACE
           " is not called, run by a job step, or started by a"
           DELIMITED BY SIZE
           " transaction of the run" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        CP-FILE-ID(LS-P) CP-LINE(LS-P) CP-COLUMN(LS-P) CP-SRC-LINE(LS-P)
        LS-MESSAGE.
END PROGRAM PLB-RULE-APPLICATION.

*> PLB-C053 exit-program-in-main: EXIT PROGRAM in a program that a
*> job step runs (EXEC PGM=name) and that no program of the run calls.
*> In a main program EXIT PROGRAM does nothing: execution goes on with
*> the next statement, through the paragraphs that follow, instead of
*> ending. GOBACK ends a main program and returns from a called one.
*>
*> A program run through another (DFSRRC00 for IMS, a DB2 RUN PROGRAM)
*> is called by it, and nested programs only run when called; neither
*> is reported. CICS programs are not run by job steps.
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-C053.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-STEP                 PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(8).
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbcall.cpy".
COPY "plbjcl.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH PLB-JCL.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-C053" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR JS-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
        IF CP-KIND(LS-P) = "P" AND CP-PARENT(LS-P) = 0
           AND CP-EXIT-LINE(LS-P) > 0 AND CP-NAME(LS-P) NOT = SPACES
            PERFORM CHECK-PROGRAM
        END-IF
    END-PERFORM
    GOBACK.

CHECK-PROGRAM.
    *> Called by a program of the run: EXIT PROGRAM returns.
    PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > CC-COUNT
        IF CC-TO(LS-C) > 0
            IF CP-OWNER(CC-TO(LS-C)) = LS-P
                EXIT PARAGRAPH
            END-IF
        END-IF
    END-PERFORM
    *> A step that runs it directly.
    MOVE 0 TO LS-STEP
    MOVE CP-NAME(LS-P) TO LS-NAME
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > JS-COUNT
        IF JS-KIND(LS-S) = "P" AND JS-TARGET(LS-S) = LS-NAME
           AND JS-INNER(LS-S) = SPACES
            MOVE LS-S TO LS-STEP
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-STEP = 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "EXIT PROGRAM does nothing in " DELIMITED BY SIZE
           CP-NAME(LS-P) DELIMITED BY SPACE
           ", which step " DELIMITED BY SIZE
           JS-NAME(LS-STEP) DELIMITED BY SPACE
           " runs as the main program: execution goes on past it;"
           " GOBACK ends the program" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        CP-EXIT-FILE-ID(LS-P) CP-EXIT-LINE(LS-P) CP-EXIT-COLUMN(LS-P)
        CP-EXIT-SRC-LINE(LS-P) LS-MESSAGE.
END PROGRAM PLB-RULE-C053.
