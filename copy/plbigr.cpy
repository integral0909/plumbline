*> plbigr.cpy: the include graph of a run. One edge per pair of
*> files where the first includes the second (COPY or EXEC SQL
*> INCLUDE), by file id in the source set. Main files are the ids up to
*> GI-MAIN-FILES; copybooks come after them. The limit is in
*> plbigrc.cpy.
01  PLB-INCLUDE-GRAPH.
    05  GI-MAIN-FILES           PIC 9(4) COMP-5.
    05  GI-COUNT                PIC 9(9) COMP-5.
    05  GI-EDGE                 OCCURS GI-MAX TIMES.
        10  GI-FROM             PIC 9(4) COMP-5.
        10  GI-TO               PIC 9(4) COMP-5.
