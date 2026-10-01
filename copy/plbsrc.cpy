*> plbsrc.cpy: source files loaded into memory.
*>
*> Every physical line of every loaded file has one SS-LINE entry,
*> in load order. The tab-expanded text of the line is kept in the
*> shared SS-HEAP; SL-TEXT-OFF is the heap position of column 1.
*> Content and comment columns are relative to the line (column 1 is
*> the first character of the line), so
*>     SS-HEAP(SL-TEXT-OFF + SL-CONTENT-COL - 1 : SL-CONTENT-LEN)
*> is the line's significant text.
*>
*> A file can be added (given an id) before it is read, and its lines
*> can be released again when they are no longer needed, so that a run
*> over many files holds the lines of a few at a time. Lines are always
*> appended, so releasing everything read since a mark (SS-LINE-COUNT
*> and SS-HEAP-USED at some moment) is a rewind.
*>
*> The limits below are hard: exceeding one is reported as an error
*> diagnostic and the rest of the input is not loaded.
78  SS-MAX-FILES                VALUE 256.
78  SS-MAX-LINES                VALUE 200000.
78  SS-HEAP-SIZE                VALUE 16000000.
78  SS-MAX-WIDTH                VALUE 1024.
78  SS-PATH-SIZE                VALUE 512.
01  PLB-SOURCE-SET.
    05  SS-FILE-COUNT           PIC 9(4) COMP-5.
    05  SS-LINE-COUNT           PIC 9(9) COMP-5.
    05  SS-HEAP-USED            PIC 9(9) COMP-5.
    05  SS-FILE                 OCCURS SS-MAX-FILES TIMES.
        10  SF-PATH             PIC X(SS-PATH-SIZE).
        *> Format in effect at the top of the file.
        10  SF-FORMAT           PIC X.
            88  SF-IS-FIXED           VALUE "X".
            88  SF-IS-FREE            VALUE "F".
        *> "Y" when the format was detected rather than given.
        10  SF-DETECTED         PIC X.
        *> Format asked for when the file was added: "X", "F", or
        *> "A" (detect). A file read again is read the same way.
        10  SF-MODE             PIC X.
        *> Times the file was read: 0 when it was only added. Problems
        *> are reported the first time only.
        10  SF-READS            PIC 9(4) COMP-5.
        *> "Y" while the file's lines are in SS-LINE; PLB-SRC-RELEASE
        *> takes them out again, and then SF-FIRST-LINE is 0.
        10  SF-LOADED           PIC X.
        10  SF-FIRST-LINE       PIC 9(9) COMP-5.
        *> Lines of the file, kept when its lines are released.
        10  SF-LINE-COUNT       PIC 9(9) COMP-5.
    05  SS-LINE                 OCCURS SS-MAX-LINES TIMES.
        10  SL-FILE-ID          PIC 9(4) COMP-5.
        10  SL-LINE-NO          PIC 9(9) COMP-5.
        10  SL-TEXT-OFF         PIC 9(9) COMP-5.
        10  SL-TEXT-LEN         PIC 9(4) COMP-5.
        *> Format this line was read in ("X" fixed, "F" free).
        10  SL-FORMAT           PIC X.
        *> Same codes and meanings as CL-KIND in plbcls.cpy.
        10  SL-KIND             PIC X.
            88  SL-IS-CODE            VALUE "C".
            88  SL-IS-BLANK           VALUE "B".
            88  SL-IS-COMMENT         VALUE "*".
            88  SL-IS-PAGE            VALUE "/".
            88  SL-IS-DEBUG           VALUE "D".
            88  SL-IS-CONTINUATION    VALUE "-".
            88  SL-IS-DIRECTIVE       VALUE ">".
        10  SL-INDICATOR        PIC X.
        10  SL-CONTENT-COL      PIC 9(4) COMP-5.
        10  SL-CONTENT-LEN      PIC 9(4) COMP-5.
        10  SL-COMMENT-COL      PIC 9(4) COMP-5.
        10  SL-AREA-A           PIC X.
        10  SL-OPEN-QUOTE       PIC X.
    05  SS-HEAP                 PIC X(SS-HEAP-SIZE).
