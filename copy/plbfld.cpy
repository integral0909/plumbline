*> plbfld.cpy: the data items of the copybooks of a run, and how many
*> programs name each (PLB-FIELDS-COLLECT, for plumbline fields).
*>
*> An item is named by a program when a statement of the program names
*> it, one of its subordinate items, or one of its condition names, or
*> when it is the key or status item of a file or the object of OCCURS
*> DEPENDING ON. An item that is only moved, read, or written as part
*> of its record is not.
*> The limits are in plbfldc.cpy, which a program copies once.
01  PLB-FIELDS.
    05  FI-COUNT                PIC 9(9) COMP-5.
    *> Items that did not fit.
    05  FI-DROPPED              PIC 9(9) COMP-5.
    *> The first entry of each copybook, by file id; entries of one
    *> copybook are chained by FI-NEXT in the order they were added.
    05  FI-HEAD                 PIC 9(9) COMP-5 OCCURS FI-FILES-MAX TIMES.
    05  FI-ENTRY                OCCURS FI-MAX TIMES.
        *> The copybook (an input of the source set) and the line of
        *> the item's name in it.
        10  FI-FILE-ID          PIC 9(4) COMP-5.
        10  FI-LINE             PIC 9(9) COMP-5.
        10  FI-LEVEL            PIC 9(4) COMP-5.
        10  FI-NAME             PIC X(31).
        *> Programs (main files) that copy it, and that name it.
        10  FI-COPIED           PIC 9(9) COMP-5.
        10  FI-NAMED            PIC 9(9) COMP-5.
        *> The main file that last counted it, so that a file counts
        *> once.
        10  FI-LAST-COPY        PIC 9(4) COMP-5.
        10  FI-LAST-NAME        PIC 9(4) COMP-5.
        10  FI-NEXT             PIC 9(9) COMP-5.
