*> plbduse.cpy: the declarations and uses of a data item name over a
*> run, for plumbline impact NAME.
78  DU-MAX                      VALUE 50000.
01  PLB-DATA-USES.
    05  DU-COUNT                PIC 9(9) COMP-5.
    05  DU-DROPPED              PIC 9(9) COMP-5.
    05  DU-ENTRY                OCCURS DU-MAX TIMES.
        *>   T declared   U read   D given a value   B read and given
        *>   one   X used, may read or set (CALL BY REFERENCE, ...)
        10  DU-ROLE             PIC X.
        10  DU-PROGRAM          PIC X(31).
        *> The statement's verb (MOVE, IF, ...), or the item's level
        *> for a declaration.
        10  DU-VERB             PIC X(20).
        10  DU-FILE-ID          PIC 9(4) COMP-5.
        10  DU-LINE             PIC 9(9) COMP-5.
        10  DU-COLUMN           PIC 9(4) COMP-5.
