*> plbflow.cpy: the procedure graph.
*>
*> Units are the sections and paragraphs of each procedure division,
*> in source order (a section comes before its paragraphs). Execution
*> falls from each unit into the next one in the same program unless
*> the unit's last statement ends it (STOP RUN, GOBACK, EXIT PROGRAM,
*> or an unconditional GO TO). Edges record PERFORM and GO TO.
78  FU-MAX                      VALUE 20000.
78  FE-MAX                      VALUE 100000.
01  PLB-FLOW.
    05  FU-COUNT                PIC 9(9) COMP-5.
    05  FU-ENTRY                OCCURS FU-MAX TIMES.
        *> PARA or SECT node; for statements before the first
        *> section or paragraph, the PROCEDURE division node.
        10  FU-NODE             PIC 9(9) COMP-5.
        *>   P paragraph   S section   D division start (unnamed)
        10  FU-KIND             PIC X.
        10  FU-NAME             PIC X(31).
        10  FU-PROGRAM          PIC 9(9) COMP-5.
        *> Unit of the section containing this paragraph (0: none).
        10  FU-SECTION          PIC 9(9) COMP-5.
        *> "Y" inside DECLARATIVES.
        10  FU-DECLARATIVE      PIC X.
        *> Next unit in the same program in source order (0: last).
        10  FU-NEXT             PIC 9(9) COMP-5.
        *> Last statement directly in the unit, and whether control
        *> can pass it and fall into the next unit.
        10  FU-LAST-STMT        PIC 9(9) COMP-5.
        10  FU-FALLS            PIC X.
        *> Reachability from the program's entry points: FU-REACHED
        *> when the unit can execute at all; FU-FLOWED when control can
        *> arrive by falling or jumping into it (not only by PERFORM),
        *> and so can continue into the next unit.
        10  FU-REACHED          PIC X.
        10  FU-FLOWED           PIC X.
        *> "Y" when some PERFORM or GO TO names this unit.
        10  FU-PERFORMED        PIC X.
        10  FU-JUMPED-TO        PIC X.
    05  FE-COUNT                PIC 9(9) COMP-5.
    05  FE-ENTRY                OCCURS FE-MAX TIMES.
        *>   P  PERFORM          G  GO TO
        10  FE-KIND             PIC X.
        10  FE-FROM             PIC 9(9) COMP-5.
        *> Target unit, and for PERFORM ... THRU the last unit of the
        *> range (FE-TO when there is no THRU). 0 when unresolved.
        10  FE-TO               PIC 9(9) COMP-5.
        10  FE-THRU             PIC 9(9) COMP-5.
        *> The statement and the PROC node naming the target.
        10  FE-STMT             PIC 9(9) COMP-5.
        10  FE-PROC             PIC 9(9) COMP-5.
