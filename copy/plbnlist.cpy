*> plbnlist.cpy: a short list of names to look for (PLB-NAMED-AFTER).
01  PLB-NAME-LIST.
    05  NL-COUNT                PIC 9(4) COMP-5.
    05  NL-NAME                 PIC X(31) OCCURS 32 TIMES.
    *> When not spaces: a CALL of a program whose literal name starts
    *> with this ends the search where it is met, its own words
    *> included: the call sets the status anew, and what follows tests
    *> that call, not the one the search is for.
    05  NL-SKIP-PREFIX          PIC X(8) VALUE SPACES.
