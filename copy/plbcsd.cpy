*> plbcsd.cpy: CICS resources defined in DFHCSDUP input.
*>
*> One entry per DEFINE: the resource type as written (TRANSACTION,
*> PROGRAM, MAPSET, FILE, TDQUEUE, ...) and its name, upper-cased, with
*> its group. For a transaction, CR-TARGET is the program it runs; for
*> a file, its data set name.
*>
*> The limits are in plbcsdc.cpy, which a program copies once.
01  PLB-CSD.
    05  CR-COUNT                PIC 9(9) COMP-5.
    05  CR-ENTRY                OCCURS CR-MAX TIMES.
        10  CR-TYPE             PIC X(31).
        10  CR-NAME             PIC X(44).
        10  CR-GROUP            PIC X(8).
        10  CR-TARGET           PIC X(44).
        10  CR-FILE-ID          PIC 9(4) COMP-5.
        10  CR-LINE             PIC 9(9) COMP-5.
