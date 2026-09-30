*> plbptok.cpy: one token as the parser sees it (PLB-PX-TOKEN).
01  PLB-PX-VIEW.
    *> Token kind (TK-KIND codes).
    05  PX-KIND                 PIC X.
    *> First 31 characters of the token text.
    05  PX-TEXT                 PIC X(31).
    *> Reserved-word kind (V T F S R) of a word, else space.
    05  PX-KW                   PIC X.
