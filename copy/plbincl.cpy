*> plbincl.cpy: where each expanded copybook was included from.
*>
*> Every COPY statement the preprocessor expands creates one entry.
*> A token's TK-INCL names the entry its text came through, so a
*> finding inside a copybook can be reported with its include chain:
*> follow IN-PARENT until it is 0 (the main file).
78  IN-MAX                      VALUE 4096.
78  IM-MAX                      VALUE 256.
01  PLB-INCLUSIONS.
    05  IN-COUNT                PIC 9(4) COMP-5.
    05  IN-ENTRY                OCCURS IN-MAX TIMES.
        *> The copybook's file id in the source set.
        10  IN-FILE-ID          PIC 9(4) COMP-5.
        *> The inclusion that contains the COPY statement (0: main).
        10  IN-PARENT           PIC 9(4) COMP-5.
        *> Location of the word COPY that included it.
        10  IN-FROM-FILE-ID     PIC 9(4) COMP-5.
        10  IN-FROM-LINE        PIC 9(9) COMP-5.
        10  IN-FROM-COLUMN      PIC 9(4) COMP-5.
    *> The copybooks COPY statements name that were not found, each
    *> once: what they declare is missing from the program.
    05  IM-COUNT                PIC 9(4) COMP-5.
    05  IM-NAME                 PIC X(31) OCCURS IM-MAX TIMES.
