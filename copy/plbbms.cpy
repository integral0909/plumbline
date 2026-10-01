*> plbbms.cpy: the mapsets, maps, and fields of CICS BMS sources.
*>
*> PLB-BMS-READ appends one BMS source at a time. A mapset (DFHMSD)
*> holds maps (DFHMDI), and a map holds fields (DFHMDF). Names are
*> kept in upper case. A field's place is its attribute byte: row and
*> column within the map, 1-based; its data follows that byte.
*>
*> The limits are in plbbmsc.cpy, which a program copies once.
01  PLB-BMS.
    05  BS-COUNT                PIC 9(9) COMP-5.
    05  BS-ENTRY                OCCURS BS-MAX TIMES.
        10  BS-NAME             PIC X(8).
        10  BS-FILE-ID          PIC 9(4) COMP-5.
        10  BS-LINE             PIC 9(9) COMP-5.
    05  BM-COUNT                PIC 9(9) COMP-5.
    05  BM-ENTRY                OCCURS BM-MAX TIMES.
        10  BM-NAME             PIC X(8).
        10  BM-MAPSET           PIC 9(9) COMP-5.
        10  BM-FILE-ID          PIC 9(4) COMP-5.
        10  BM-LINE             PIC 9(9) COMP-5.
        *> SIZE=(lines,columns); 0 when not given.
        10  BM-LINES            PIC 9(4) COMP-5.
        10  BM-COLUMNS          PIC 9(4) COMP-5.
        10  BM-FIELD-FIRST      PIC 9(9) COMP-5.
        10  BM-FIELD-COUNT      PIC 9(9) COMP-5.
    05  BF-COUNT                PIC 9(9) COMP-5.
    05  BF-ENTRY                OCCURS BF-MAX TIMES.
        10  BF-MAP              PIC 9(9) COMP-5.
        *> Spaces for a field without a name (a label on the screen).
        10  BF-NAME             PIC X(8).
        10  BF-FILE-ID          PIC 9(4) COMP-5.
        10  BF-LINE             PIC 9(9) COMP-5.
        *> POS=(row,column), or POS=offset turned into both; 0 when
        *> the field has no POS.
        10  BF-ROW              PIC 9(4) COMP-5.
        10  BF-COLUMN           PIC 9(4) COMP-5.
        10  BF-LENGTH           PIC 9(4) COMP-5.
        *> OCCURS=n: n fields of LENGTH one after the other.
        10  BF-OCCURS           PIC 9(4) COMP-5.
        *> "Y" for a field the terminal user cannot type in (ASKIP,
        *> PROT), and for one that takes digits only (NUM).
        10  BF-PROTECTED        PIC X.
        10  BF-NUMERIC          PIC X.
        10  BF-HAS-INITIAL      PIC X.
