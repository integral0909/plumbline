*> plbcls.cpy: the classification of one physical source line.
*>
*> Columns are 1-based positions in the tab-expanded line. A column
*> or length of 0 means "none".
01  PLB-CLASSIFIED.
    *> What the line is.
    05  CL-KIND                 PIC X.
        88  CL-IS-CODE                VALUE "C".
        88  CL-IS-BLANK               VALUE "B".
        88  CL-IS-COMMENT             VALUE "*".
        88  CL-IS-PAGE                VALUE "/".
        88  CL-IS-DEBUG               VALUE "D".
        88  CL-IS-CONTINUATION        VALUE "-".
        88  CL-IS-DIRECTIVE           VALUE ">".
    *> Fixed format: the character in column 7. Free format: space.
    05  CL-INDICATOR            PIC X.
    *> The significant text: first to last non-space character,
    *> excluding any inline comment and, in fixed format, anything
    *> past column 72.
    05  CL-CONTENT-COL          PIC 9(4) COMP-5.
    05  CL-CONTENT-LEN          PIC 9(4) COMP-5.
    *> Where a comment starts ("*>" inline, or the indicator column
    *> of a fixed-format comment line).
    05  CL-COMMENT-COL          PIC 9(4) COMP-5.
    *> "Y" when the content starts in area A (fixed columns 8-11).
    05  CL-AREA-A               PIC X.
    *> The quote character of an alphanumeric literal still open at
    *> the end of the content, or space.
    05  CL-OPEN-QUOTE           PIC X.
    *> A problem found while classifying: space for none,
    *> "I" invalid indicator character in column 7.
    05  CL-PROBLEM              PIC X.
