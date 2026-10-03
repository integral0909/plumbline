*> plbdupt.cpy: the paragraphs of a run, by a hash of their bodies
*> (plumbline duplicates, src/lib/plbdup.cob). Paragraphs beyond DP-MAX
*> are counted in DP-DROPPED.
78  DP-MAX                      VALUE 50000.
01  PLB-DUPLICATES.
    05  DP-COUNT                PIC 9(9) COMP-5.
    05  DP-DROPPED              PIC 9(9) COMP-5.
    05  DP-ENTRY                OCCURS DP-MAX TIMES.
        10  DP-HASH-1           PIC S9(18) COMP-5.
        10  DP-HASH-2           PIC S9(18) COMP-5.
        *> Tokens of the body, and the statements in it.
        10  DP-TOKENS           PIC 9(9) COMP-5.
        10  DP-STATEMENTS       PIC 9(9) COMP-5.
        10  DP-NAME             PIC X(31).
        10  DP-PROGRAM          PIC X(31).
        *> Where the paragraph's name is.
        10  DP-FILE-ID          PIC 9(4) COMP-5.
        10  DP-LINE             PIC 9(9) COMP-5.
