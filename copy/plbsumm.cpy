*> plbsumm.cpy: one row per program of a run, for check --report
*> summary (src/lib/plbsumm.cob): where it is, its size, complexity,
*> and maintainability index from the metrics, and the findings in
*> its lines by severity, counted when the report is written.
78  SM-MAX                      VALUE 20000.
01  PLB-SUMMARY.
    05  SM-COUNT                PIC 9(9) COMP-5.
    05  SM-DROPPED              PIC 9(9) COMP-5.
    05  SM-ENTRY                OCCURS SM-MAX TIMES.
        10  SM-NAME             PIC X(31).
        10  SM-FILE-ID          PIC 9(4) COMP-5.
        *> The program's first and last lines in its file.
        10  SM-FIRST-LINE       PIC 9(9) COMP-5.
        10  SM-LAST-LINE        PIC 9(9) COMP-5.
        10  SM-LINES            PIC 9(9) COMP-5.
        10  SM-COMPLEXITY       PIC 9(9) COMP-5.
        10  SM-MAINTAINABILITY  PIC 9(4) COMP-5.
        10  SM-ERRORS           PIC 9(9) COMP-5.
        10  SM-WARNINGS         PIC 9(9) COMP-5.
        10  SM-NOTES            PIC 9(9) COMP-5.
