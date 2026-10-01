*> plbrules.cpy: the rule catalog.
*>
*> Rule ids are PLB-<category><number>. Categories:
*>   C correctness     M maintainability
*>   P portability     S security
*> A rule's default severity can be changed, and the rule disabled,
*> with command-line options. Rules that measure something against a
*> threshold keep it in RL-LIMIT, which configuration can change.
78  RL-MAX                      VALUE 64.
01  PLB-RULES.
    05  RL-COUNT                PIC 9(4) COMP-5.
    05  RL-ENTRY                OCCURS RL-MAX TIMES.
        10  RL-ID               PIC X(8).
        10  RL-NAME             PIC X(32).
        10  RL-SEVERITY         PIC X.
        10  RL-ENABLED          PIC X.
        10  RL-TITLE            PIC X(80).
        *> The threshold of a measuring rule (0 for other rules).
        10  RL-LIMIT            PIC 9(9) COMP-5.
