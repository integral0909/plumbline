*> plbfixs.cpy: the fixes of a run's findings, kept for the reports.
*>
*> PLB-FIX-KEEP adds the fix of a finding while its lines are loaded;
*> PLB-FIX-FOR finds it again by the finding's file, line, column, and
*> rule, which stay the same when the findings are sorted. The edits of
*> fix N are FK-EDIT(FK-FIRST-EDIT(N)) and the FK-EDITS(N) - 1 after
*> it, with the fields of FX-EDIT in plbfix.cpy.
78  FK-FIX-MAX                  VALUE 4096.
78  FK-EDIT-MAX                 VALUE 16384.
01  PLB-FIX-STORE.
    05  FK-FIX-COUNT            PIC 9(9) COMP-5.
    05  FK-EDIT-COUNT           PIC 9(9) COMP-5.
    05  FK-FIX                  OCCURS FK-FIX-MAX TIMES.
        10  FK-FILE-ID          PIC 9(4) COMP-5.
        10  FK-LINE             PIC 9(9) COMP-5.
        10  FK-COLUMN           PIC 9(4) COMP-5.
        10  FK-RULE             PIC 9(4) COMP-5.
        10  FK-TITLE            PIC X(80).
        10  FK-FIRST-EDIT       PIC 9(9) COMP-5.
        10  FK-EDITS            PIC 9(4) COMP-5.
    05  FK-EDIT                 OCCURS FK-EDIT-MAX TIMES.
        10  FK-EDIT-LINE        PIC 9(9) COMP-5.
        10  FK-EDIT-COLUMN      PIC 9(4) COMP-5.
        10  FK-EDIT-END-LINE    PIC 9(9) COMP-5.
        10  FK-EDIT-END-COLUMN  PIC 9(4) COMP-5.
        10  FK-EDIT-TEXT        PIC X(256).
        10  FK-EDIT-TEXT-LEN    PIC 9(9) COMP-5.
