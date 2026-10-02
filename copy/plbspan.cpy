*> plbspan.cpy: the storage each data item occupies.
*>
*> Two items share storage when they have the same root and their
*> byte ranges [SP-LOW, SP-HIGH) intersect. The root is the record
*> (01 or 77) the item belongs to, or for a record that redefines
*> another record, the root of that record. Items in a table span the
*> whole table: with no subscripts known, any occurrence may be meant.
*> Built by PLB-SPAN-BUILD; indexed like PLB-SYMBOLS.
01  PLB-SPANS.
    05  SP-ENTRY                OCCURS 100000 TIMES.
        10  SP-ROOT             PIC 9(9) COMP-5.
        10  SP-LOW              PIC 9(9) COMP-5.
        10  SP-HIGH             PIC 9(9) COMP-5.
