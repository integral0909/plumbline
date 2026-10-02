*> ---------------------------------------------------------------
*> plbrims: IMS definitions, and the programs that use them.
*>
*>   PLB-I001  pcb-dbd-unknown          a PCB names a database that
*>                                      no DBD of the run defines
*>   PLB-I002  senseg-not-in-dbd        a sensitive segment that its
*>                                      database does not have, or
*>                                      under another parent
*>   PLB-I003  segment-not-sensitive    a DL/I call names a segment
*>                                      the program's PSB is not
*>                                      sensitive to
*>   PLB-I004  procopt-forbids-call     a DL/I call that no PCB of the
*>                                      segment allows (PROCOPT)
*>
*> I001 and I002 need the DBDs among the inputs; I003 and I004 need
*> the PSBs, and a program's PSB, from EXEC DLI SCHD PSB(name) or from
*> the JCL step that runs it (DFSRRC00 PARM='BMP,program,psb').
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-IMS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbjclc.cpy".
COPY "plbimsc.cpy".
*> The PSBs of the program being checked.
01  WS-PSBS.
    05  WS-PSB-COUNT        PIC 9(4) COMP-5.
    05  WS-PSB              PIC 9(9) COMP-5 OCCURS 20 TIMES.
LOCAL-STORAGE SECTION.
01  LS-RULE-DBD             PIC 9(4) COMP-5.
01  LS-RULE-SENSEG          PIC 9(4) COMP-5.
01  LS-RULE-SENSITIVE       PIC 9(4) COMP-5.
01  LS-RULE-PROCOPT         PIC 9(4) COMP-5.
01  LS-C                    PIC 9(9) COMP-5.
01  LS-S                    PIC 9(9) COMP-5.
01  LS-D                    PIC 9(9) COMP-5.
01  LS-G                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-I                    PIC 9(9) COMP-5.
01  LS-Q                    PIC 9(9) COMP-5.
01  LS-OWNER                PIC 9(9) COMP-5.
01  LS-NAME                 PIC X(8).
01  LS-NEED                 PIC X.
01  LS-SENSITIVE            PIC X.
01  LS-ALLOWED              PIC X.
01  LS-COUNT                PIC 9(4) COMP-5.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-COLUMN               PIC 9(4) COMP-5 VALUE 1.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbcall.cpy".
COPY "plbjcl.cpy".
COPY "plbims.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH PLB-JCL
        PLB-IMS.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-I001" LS-RULE-DBD
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-I002" LS-RULE-SENSEG
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-I003" LS-RULE-SENSITIVE
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-I004" LS-RULE-PROCOPT
    IF XD-COUNT > 0
        PERFORM VARYING LS-C FROM 1 BY 1 UNTIL LS-C > XC-COUNT
            PERFORM CHECK-PCB
        END-PERFORM
        PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > XS-COUNT
            PERFORM CHECK-SENSEG
        END-PERFORM
    END-IF
    IF XP-COUNT > 0
        PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > PD-COUNT
            IF PD-KIND(LS-U) = "S"
                PERFORM CHECK-CALL
            END-IF
        END-PERFORM
    END-IF
    GOBACK.

*> PLB-I001.
CHECK-PCB.
    IF XC-DBD(LS-C) = SPACES
        EXIT PARAGRAPH
    END-IF
    MOVE XC-DBD(LS-C) TO LS-NAME
    PERFORM FIND-DBD
    IF LS-D > 0
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "PCB names database " DELIMITED BY SIZE
           XC-DBD(LS-C) DELIMITED BY SPACE
           ", which no DBD of the run defines" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-DBD
        XC-FILE-ID(LS-C) XC-LINE(LS-C) LS-COLUMN LS-ZERO LS-MESSAGE.

*> PLB-I002.
CHECK-SENSEG.
    MOVE XS-PCB(LS-S) TO LS-C
    MOVE XC-DBD(LS-C) TO LS-NAME
    PERFORM FIND-DBD
    IF LS-D = 0
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-G
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > XG-COUNT
        IF XG-DBD(LS-I) = LS-D AND XG-NAME(LS-I) = XS-NAME(LS-S)
            MOVE LS-I TO LS-G
            EXIT PERFORM
        END-IF
    END-PERFORM
    MOVE SPACES TO LS-MESSAGE
    IF LS-G = 0
        STRING "sensitive segment " DELIMITED BY SIZE
               XS-NAME(LS-S) DELIMITED BY SPACE
               " is not a segment of database " DELIMITED BY SIZE
               XD-NAME(LS-D) DELIMITED BY SPACE
            INTO LS-MESSAGE
    ELSE
        IF XS-PARENT(LS-S) = XG-PARENT(LS-G)
            EXIT PARAGRAPH
        END-IF
        STRING "sensitive segment " DELIMITED BY SIZE
               XS-NAME(LS-S) DELIMITED BY SPACE
               " has parent " DELIMITED BY SIZE
            INTO LS-MESSAGE
        IF XS-PARENT(LS-S) = SPACES
            STRING LS-MESSAGE DELIMITED BY "  "
                   " 0" DELIMITED BY SIZE
                INTO LS-MESSAGE
        ELSE
            STRING LS-MESSAGE DELIMITED BY "  "
                   " " DELIMITED BY SIZE
                   XS-PARENT(LS-S) DELIMITED BY SPACE
                INTO LS-MESSAGE
        END-IF
        IF XG-PARENT(LS-G) = SPACES
            STRING LS-MESSAGE DELIMITED BY "  "
                   ", but is a root of database " DELIMITED BY SIZE
                   XD-NAME(LS-D) DELIMITED BY SPACE
                INTO LS-MESSAGE
        ELSE
            STRING LS-MESSAGE DELIMITED BY "  "
                   ", but its parent in database " DELIMITED BY SIZE
                   XD-NAME(LS-D) DELIMITED BY SPACE
                   " is " DELIMITED BY SIZE
                   XG-PARENT(LS-G) DELIMITED BY SPACE
                INTO LS-MESSAGE
        END-IF
    END-IF
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-SENSEG
        XS-FILE-ID(LS-S) XS-LINE(LS-S) LS-COLUMN LS-ZERO LS-MESSAGE.

*> LS-D = the DBD named LS-NAME, or 0.
FIND-DBD.
    MOVE 0 TO LS-D
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > XD-COUNT
        IF XD-NAME(LS-I) = LS-NAME
            MOVE LS-I TO LS-D
            EXIT PERFORM
        END-IF
    END-PERFORM.

*> PLB-I003 and PLB-I004 for the segment of DL/I call LS-U.
CHECK-CALL.
    MOVE PD-PROGRAM(LS-U) TO LS-Q
    PERFORM OUTERMOST
    MOVE LS-OWNER TO LS-P
    PERFORM COLLECT-PSBS
    IF WS-PSB-COUNT = 0
        EXIT PARAGRAPH
    END-IF
    *> What the function needs of PROCOPT.
    EVALUATE PD-FUNCTION(LS-U)
        WHEN "ISRT"  MOVE "I" TO LS-NEED
        WHEN "REPL"  MOVE "R" TO LS-NEED
        WHEN "DLET"  MOVE "D" TO LS-NEED
        WHEN "GU" WHEN "GN" WHEN "GNP" WHEN "GHU" WHEN "GHN" WHEN "GHNP"
        WHEN "GET"
            MOVE "G" TO LS-NEED
        WHEN OTHER
            MOVE SPACE TO LS-NEED
    END-EVALUATE
    MOVE "N" TO LS-SENSITIVE LS-ALLOWED
    PERFORM VARYING LS-S FROM 1 BY 1 UNTIL LS-S > XS-COUNT
        IF XS-NAME(LS-S) = PD-NAME(LS-U)
            MOVE XS-PCB(LS-S) TO LS-C
            PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > WS-PSB-COUNT
                IF XC-PSB(LS-C) = WS-PSB(LS-I)
                    MOVE "Y" TO LS-SENSITIVE
                    PERFORM TEST-PROCOPT
                END-IF
            END-PERFORM
        END-IF
    END-PERFORM
    IF LS-SENSITIVE = "N"
        MOVE SPACES TO LS-MESSAGE
        STRING "EXEC DLI " DELIMITED BY SIZE
               PD-FUNCTION(LS-U) DELIMITED BY SPACE
               " names segment " DELIMITED BY SIZE
               PD-NAME(LS-U) DELIMITED BY SPACE
               ", which PSB " DELIMITED BY SIZE
               XP-NAME(WS-PSB(1)) DELIMITED BY SPACE
               " is not sensitive to" DELIMITED BY SIZE
            INTO LS-MESSAGE
        CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS
            LS-RULE-SENSITIVE PD-FILE-ID(LS-U) PD-LINE(LS-U)
            PD-COLUMN(LS-U) PD-SRC-LINE(LS-U) LS-MESSAGE
        EXIT PARAGRAPH
    END-IF
    IF LS-ALLOWED = "Y" OR LS-NEED = SPACE
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "EXEC DLI " DELIMITED BY SIZE
           PD-FUNCTION(LS-U) DELIMITED BY SPACE
           " on segment " DELIMITED BY SIZE
           PD-NAME(LS-U) DELIMITED BY SPACE
           ", but no PCB of PSB " DELIMITED BY SIZE
           XP-NAME(WS-PSB(1)) DELIMITED BY SPACE
           " for it has PROCOPT " DELIMITED BY SIZE
           LS-NEED DELIMITED BY SIZE
           " or A" DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE-PROCOPT
        PD-FILE-ID(LS-U) PD-LINE(LS-U) PD-COLUMN(LS-U) PD-SRC-LINE(LS-U)
        LS-MESSAGE.

*> LS-ALLOWED = "Y" when PCB LS-C allows LS-NEED: PROCOPT has the
*> letter, or A (all).
TEST-PROCOPT.
    IF LS-NEED = SPACE
        MOVE "Y" TO LS-ALLOWED
        EXIT PARAGRAPH
    END-IF
    MOVE 0 TO LS-COUNT
    INSPECT XC-PROCOPT(LS-C) TALLYING LS-COUNT FOR ALL LS-NEED
    INSPECT XC-PROCOPT(LS-C) TALLYING LS-COUNT FOR ALL "A"
    IF LS-COUNT > 0
        MOVE "Y" TO LS-ALLOWED
    END-IF.

*> WS-PSB = the PSBs of the run that program LS-P schedules (SCHD) or
*> that the JCL steps running it schedule.
COLLECT-PSBS.
    MOVE 0 TO WS-PSB-COUNT
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > PD-COUNT
        IF PD-KIND(LS-I) = "P"
            MOVE PD-PROGRAM(LS-I) TO LS-Q
            PERFORM OUTERMOST
            IF LS-OWNER = LS-P
                MOVE PD-NAME(LS-I) TO LS-NAME
                PERFORM ADD-PSB
            END-IF
        END-IF
    END-PERFORM
    PERFORM VARYING LS-I FROM 1 BY 1 UNTIL LS-I > JS-COUNT
        IF JS-INNER(LS-I) = CP-NAME(LS-P) AND JS-PSB(LS-I) NOT = SPACES
            MOVE JS-PSB(LS-I) TO LS-NAME
            PERFORM ADD-PSB
        END-IF
    END-PERFORM.

ADD-PSB.
    PERFORM VARYING LS-G FROM 1 BY 1 UNTIL LS-G > XP-COUNT
        IF XP-NAME(LS-G) = LS-NAME
            PERFORM VARYING LS-Q FROM 1 BY 1 UNTIL LS-Q > WS-PSB-COUNT
                IF WS-PSB(LS-Q) = LS-G
                    EXIT PARAGRAPH
                END-IF
            END-PERFORM
            IF WS-PSB-COUNT < 20
                ADD 1 TO WS-PSB-COUNT
                MOVE LS-G TO WS-PSB(WS-PSB-COUNT)
            END-IF
            EXIT PARAGRAPH
        END-IF
    END-PERFORM.

OUTERMOST.
    MOVE CP-OWNER(LS-Q) TO LS-OWNER
    PERFORM UNTIL CP-PARENT(LS-OWNER) = 0
        MOVE CP-PARENT(LS-OWNER) TO LS-OWNER
    END-PERFORM.
END PROGRAM PLB-RULE-IMS.
