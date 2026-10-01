*> ---------------------------------------------------------------
*> plbrcics: programs checked against the CICS resource definitions.
*>
*>   PLB-K001  cics-resource-undefined   an EXEC CICS command names a
*>                                       file, transaction, program,
*>                                       mapset, or transient data
*>                                       queue the definitions do not
*>                                       have
*>
*> Only runs with definitions (DFHCSDUP input among the inputs) are
*> checked, and only names that are constants in the program: literals,
*> and data items whose VALUE is a literal and that no statement
*> changes. A program that a command names counts as defined when it
*> is a program of the run, since CICS can also install programs by
*> autoinstall. Resources that CICS supplies are left out: transient
*> data queues whose names start with C (CSSL, CSMT, ...) and programs
*> whose names start with DFH or CEE.
*> ---------------------------------------------------------------
IDENTIFICATION DIVISION.
PROGRAM-ID. PLB-RULE-CICS.
DATA DIVISION.
WORKING-STORAGE SECTION.
COPY "plbcallc.cpy".
COPY "plbcsdc.cpy".
LOCAL-STORAGE SECTION.
01  LS-RULE                 PIC 9(4) COMP-5.
01  LS-U                    PIC 9(9) COMP-5.
01  LS-R                    PIC 9(9) COMP-5.
01  LS-P                    PIC 9(9) COMP-5.
01  LS-TYPE                 PIC X(31).
01  LS-WHAT                 PIC X(31).
01  LS-FOUND                PIC X.
01  LS-ZERO                 PIC 9(9) COMP-5 VALUE 0.
01  LS-MESSAGE              PIC X(200).
LINKAGE SECTION.
COPY "plbrules.cpy".
COPY "plbfind.cpy".
COPY "plbcall.cpy".
COPY "plbcsd.cpy".
PROCEDURE DIVISION USING PLB-RULES PLB-FINDINGS PLB-CALL-GRAPH PLB-CSD.
    CALL "PLB-RULE-FIND" USING PLB-RULES "PLB-K001" LS-RULE
    IF RL-ENABLED(LS-RULE) NOT = "Y" OR CR-COUNT = 0
        GOBACK
    END-IF
    PERFORM VARYING LS-U FROM 1 BY 1 UNTIL LS-U > PU-COUNT
        PERFORM CHECK-USE
    END-PERFORM
    GOBACK.

CHECK-USE.
    IF (PU-KIND(LS-U) = "Q" AND PU-NAME(LS-U)(1:1) = "C")
       OR (PU-KIND(LS-U) = "P" AND (PU-NAME(LS-U)(1:3) = "DFH"
                                     OR PU-NAME(LS-U)(1:3) = "CEE"))
        EXIT PARAGRAPH
    END-IF
    EVALUATE PU-KIND(LS-U)
        WHEN "F"
            MOVE "FILE" TO LS-TYPE
            MOVE "file" TO LS-WHAT
        WHEN "T"
            MOVE "TRANSACTION" TO LS-TYPE
            MOVE "transaction" TO LS-WHAT
        WHEN "P"
            MOVE "PROGRAM" TO LS-TYPE
            MOVE "program" TO LS-WHAT
        WHEN "M"
            MOVE "MAPSET" TO LS-TYPE
            MOVE "mapset" TO LS-WHAT
        WHEN "Q"
            MOVE "TDQUEUE" TO LS-TYPE
            MOVE "transient data queue" TO LS-WHAT
        WHEN OTHER
            EXIT PARAGRAPH
    END-EVALUATE
    MOVE "N" TO LS-FOUND
    PERFORM VARYING LS-R FROM 1 BY 1 UNTIL LS-R > CR-COUNT
        IF CR-TYPE(LS-R) = LS-TYPE AND CR-NAME(LS-R) = PU-NAME(LS-U)
            MOVE "Y" TO LS-FOUND
            EXIT PERFORM
        END-IF
    END-PERFORM
    IF LS-FOUND = "N" AND PU-KIND(LS-U) = "P"
        PERFORM VARYING LS-P FROM 1 BY 1 UNTIL LS-P > CP-COUNT
            IF CP-NAME(LS-P) = PU-NAME(LS-U)
                MOVE "Y" TO LS-FOUND
                EXIT PERFORM
            END-IF
        END-PERFORM
    END-IF
    IF LS-FOUND = "Y"
        EXIT PARAGRAPH
    END-IF
    MOVE SPACES TO LS-MESSAGE
    STRING "EXEC CICS " DELIMITED BY SIZE
           PU-COMMAND(LS-U) DELIMITED BY SPACE
           " names " DELIMITED BY SIZE
           LS-WHAT DELIMITED BY "  "
           " " DELIMITED BY SIZE
           PU-NAME(LS-U) DELIMITED BY SPACE
           ", which the CICS definitions do not define"
           DELIMITED BY SIZE
        INTO LS-MESSAGE
    CALL "PLB-FIND-AT" USING PLB-RULES PLB-FINDINGS LS-RULE
        PU-FILE-ID(LS-U) PU-LINE(LS-U) PU-COLUMN(LS-U) LS-ZERO LS-MESSAGE.
END PROGRAM PLB-RULE-CICS.
