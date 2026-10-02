*> plbmetr.cpy: size and complexity of the programs of one file, and
*> of their paragraphs and sections (PLB-METRICS-COMPUTE).
*>
*> Complexity is McCabe's: 1 plus the decisions, which are IF, each
*> WHEN of EVALUATE and SEARCH (not WHEN OTHER), each looping PERFORM
*> (UNTIL, VARYING, TIMES, FOREVER), each conditional phrase (AT END,
*> INVALID KEY, ON SIZE ERROR, ON EXCEPTION, ...), each AND and OR of
*> a condition, and each target of GO TO ... DEPENDING ON. Nesting is
*> the deepest statement: one for a statement directly in a sentence,
*> one more inside each IF, EVALUATE, SEARCH, inline PERFORM, or
*> conditional phrase.
*>
*> A program's lines run from its first to its last token, in the file
*> that holds its PROGRAM-ID, and include the programs nested in it.
*> The limits are in plbmetrc.cpy.
01  PLB-METRICS.
    05  MP-COUNT                PIC 9(4) COMP-5.
    05  MP-ENTRY                OCCURS MP-MAX TIMES.
        10  MP-NODE             PIC 9(9) COMP-5.
        10  MP-NAME             PIC X(31).
        10  MP-FILE-ID          PIC 9(4) COMP-5.
        10  MP-LINE             PIC 9(9) COMP-5.
        10  MP-LINES            PIC 9(9) COMP-5.
        10  MP-CODE-LINES       PIC 9(9) COMP-5.
        10  MP-COMMENT-LINES    PIC 9(9) COMP-5.
        10  MP-BLANK-LINES      PIC 9(9) COMP-5.
        10  MP-STATEMENTS       PIC 9(9) COMP-5.
        10  MP-SECTIONS         PIC 9(9) COMP-5.
        10  MP-PARAGRAPHS       PIC 9(9) COMP-5.
        10  MP-DATA-ITEMS       PIC 9(9) COMP-5.
        10  MP-COMPLEXITY       PIC 9(9) COMP-5.
        10  MP-NESTING          PIC 9(4) COMP-5.
        10  MP-GO-TOS           PIC 9(9) COMP-5.
        10  MP-PERFORMS         PIC 9(9) COMP-5.
        10  MP-CALLS            PIC 9(9) COMP-5.
        10  MP-UNIT-FIRST       PIC 9(9) COMP-5.
        10  MP-UNIT-COUNT       PIC 9(9) COMP-5.
    05  MU-COUNT                PIC 9(9) COMP-5.
    05  MU-ENTRY                OCCURS MU-MAX TIMES.
        *> The unit in the procedure graph (plbflow.cpy).
        10  MU-UNIT             PIC 9(9) COMP-5.
        10  MU-NAME             PIC X(31).
        *>   P paragraph   S section   D statements before the first
        10  MU-KIND             PIC X.
        10  MU-NAME-TOKEN       PIC 9(9) COMP-5.
        10  MU-LINE             PIC 9(9) COMP-5.
        10  MU-LINES            PIC 9(9) COMP-5.
        10  MU-STATEMENTS       PIC 9(9) COMP-5.
        10  MU-COMPLEXITY       PIC 9(9) COMP-5.
        10  MU-NESTING          PIC 9(4) COMP-5.
