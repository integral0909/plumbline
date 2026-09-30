*> plbppopt.cpy: options for the preprocessor.
78  PO-MAX-PATHS                VALUE 32.
01  PLB-PP-OPTIONS.
    *> Directories searched for copybooks, in order, after the
    *> directory of the file that contains the COPY statement.
    05  PO-PATH-COUNT           PIC 9(4) COMP-5.
    05  PO-PATH                 PIC X(512) OCCURS PO-MAX-PATHS TIMES.
    *> "Y" to treat debugging lines as code (WITH DEBUGGING MODE).
    05  PO-DEBUG                PIC X.
    *> Reference format of copybooks: "X" fixed, "F" free, "A" detect.
    05  PO-FORMAT               PIC X.
