*> plbdiag.cpy: diagnostics collected while reading and analyzing source.
*>
*> Diagnostics are problems with Plumbline's input or its own limits
*> (unreadable file, overlong line, table full). Findings reported by
*> analysis rules are kept separately.
*>
*> The table holds DG-MAX entries. Further diagnostics still update the
*> error and warning counts but are counted in DG-DROPPED instead of
*> being stored, so a flood of problems can never overrun memory.
78  DG-MAX                      VALUE 4096.
78  DG-MESSAGE-SIZE             VALUE 200.
01  PLB-DIAGNOSTICS.
    05  DG-COUNT                PIC 9(9) COMP-5.
    05  DG-ERRORS               PIC 9(9) COMP-5.
    05  DG-WARNINGS             PIC 9(9) COMP-5.
    05  DG-DROPPED              PIC 9(9) COMP-5.
    05  DG-ENTRY                OCCURS DG-MAX TIMES.
        10  DG-SEVERITY         PIC X.
            88  DG-IS-ERROR           VALUE "E".
            88  DG-IS-WARNING         VALUE "W".
            88  DG-IS-NOTE            VALUE "N".
        10  DG-CODE             PIC X(8).
        10  DG-FILE-ID          PIC 9(4) COMP-5.
        10  DG-LINE             PIC 9(9) COMP-5.
        10  DG-COLUMN           PIC 9(4) COMP-5.
        10  DG-MESSAGE          PIC X(DG-MESSAGE-SIZE).
