*> plbfind.cpy: findings reported by analysis rules.
*>
*> Rule findings are kept apart from diagnostics (plbdiag.cpy):
*> diagnostics describe problems with Plumbline's input or limits,
*> findings describe problems in the program being analyzed.
78  FN-MAX                      VALUE 20000.
01  PLB-FINDINGS.
    05  FN-COUNT                PIC 9(9) COMP-5.
    05  FN-DROPPED              PIC 9(9) COMP-5.
    *> Variable length so that SORT only reorders real entries.
    05  FN-ENTRY                OCCURS 0 TO FN-MAX TIMES
                                DEPENDING ON FN-COUNT.
        *> Index of the rule in the catalog (plbrules.cpy).
        10  FN-RULE             PIC 9(4) COMP-5.
        *>   E error   W warning   N note
        10  FN-SEVERITY         PIC X.
        10  FN-FILE-ID          PIC 9(4) COMP-5.
        10  FN-LINE             PIC 9(9) COMP-5.
        10  FN-COLUMN           PIC 9(4) COMP-5.
        *> SS-LINE index of the reported line (0 if none); used to
        *> look for suppression comments.
        10  FN-SRC-LINE         PIC 9(9) COMP-5.
        10  FN-MESSAGE          PIC X(200).
        *> "Y" when a plumbline: ignore comment suppresses it.
        10  FN-SUPPRESSED       PIC X.
