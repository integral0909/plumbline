*> plbpst.cpy: state shared by the parser's programs.
01  PLB-PARSE-STATE.
    *> Current token, and the end-of-file token that stops parsing.
    05  PS-POS                  PIC 9(9) COMP-5.
    05  PS-END                  PIC 9(9) COMP-5.
    *> Tree nodes the next constructs attach to.
    05  PS-UNIT                 PIC 9(9) COMP-5.
    05  PS-PROGRAM              PIC 9(9) COMP-5.
    05  PS-DIVISION             PIC 9(9) COMP-5.
    *> "Y" once the tree is full; parsing then stops.
    05  PS-FULL                 PIC X.
