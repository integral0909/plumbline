*> plbacc.cpy: every access to data storage in one analyzed file.
*>
*> An access is a data reference with its role (U D B X, see
*> plbref.cpy), a VALUE clause (V), or a mention in an environment
*> division (X: FILE STATUS and similar items are set by the runtime).
*> Accesses are sorted by storage root (plbspan.cpy), and
*> AX-ROOT-FIRST/AX-ROOT-LAST give each root's run. Built by
*> PLB-ACCESS-BUILD, which also builds the spans.
78  AX-MAX                      VALUE 300000.
01  PLB-ACCESSES.
    05  AX-COUNT                PIC 9(9) COMP-5.
    05  AX-ENTRY                OCCURS 0 TO AX-MAX TIMES
                                DEPENDING ON AX-COUNT.
        10  AX-ROOT             PIC 9(9) COMP-5.
        10  AX-SYMBOL           PIC 9(9) COMP-5.
        10  AX-ROLE             PIC X.
*> Kept apart from the variable-length table above.
01  PLB-ACCESS-INDEX.
    05  AX-ROOT-FIRST           PIC 9(9) COMP-5 OCCURS 100000 TIMES.
    05  AX-ROOT-LAST            PIC 9(9) COMP-5 OCCURS 100000 TIMES.
    *> "Y" for items whose values Plumbline can reason about: working-
    *> and local-storage items that are not EXTERNAL, GLOBAL, BASED,
    *> constants (78), or RENAMES (66).
    05  AX-CHECKED              PIC X OCCURS 100000 TIMES.
