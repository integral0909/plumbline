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
*>
*> Halstead's measures count the tokens of the program's PROCEDURE
*> DIVISION: operators are the reserved words other than figurative
*> constants and special registers, the arithmetic and relational
*> symbols, and opening parentheses; operands are the user-defined
*> words, literals, figurative constants, and special registers.
*> Volume is N log2 n (N tokens, n distinct ones), difficulty
*> (n1 / 2) (N2 / n2), and effort their product, each rounded. The
*> maintainability index is Oman and Hagemeister's, on a scale of 0 to
*> 100, with the program's paragraphs and sections as its modules:
*> (171 - 5.2 ln(V / m) - 0.23 C - 16.2 ln(L / m)) * 100 / 171, where m
*> is the number of paragraphs and sections (1 when there are none),
*> V the volume, C the average complexity of a paragraph or section,
*> and L the code lines; 0 when that is below 0. Over a whole program
*> the formula sinks to 0 past a few hundred lines; the original
*> averages over the modules of a system for that reason.
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
        *> N1, N2, n1, and n2; volume, difficulty, effort; the index.
        10  MP-OPERATORS        PIC 9(9) COMP-5.
        10  MP-OPERANDS         PIC 9(9) COMP-5.
        10  MP-DISTINCT-OPERATORS PIC 9(9) COMP-5.
        10  MP-DISTINCT-OPERANDS  PIC 9(9) COMP-5.
        10  MP-VOLUME           PIC 9(12) COMP-5.
        10  MP-DIFFICULTY       PIC 9(9) COMP-5.
        10  MP-EFFORT           PIC 9(15) COMP-5.
        10  MP-MAINTAINABILITY  PIC 9(4) COMP-5.
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
