*> Colon-delimited tags are part of the word they appear in;
*> reference modification colons are not tags.
01  :PFX:-RECORD.
    05  WS-:TAG:-FIELD PIC X.
    05  :A:-:B: PIC X.
    DISPLAY NAME(1:LEN) VALUES(I:2)
    COPY T REPLACING ==:PFX:== BY ==WS==.
