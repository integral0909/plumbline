*> plbstat.cpy: the FILE STATUS items the SELECT statements name.
*>
*> PLB-STATUS-ITEMS fills it from the syntax tree: for each SELECT
*> with a FILE STATUS clause, the name of the item (upper case) and the
*> PROG node of the program the SELECT is in. PLB-STATUS-ITEM-OF tells
*> whether a data item is one of them.
78  SI-MAX                      VALUE 512.
01  PLB-STATUS-ITEMS.
    05  SI-COUNT                PIC 9(9) COMP-5.
    05  SI-ITEM                 OCCURS SI-MAX TIMES.
        10  SI-NAME             PIC X(31).
        10  SI-PROGRAM          PIC 9(9) COMP-5.
