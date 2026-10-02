*> plbconf.cpy: the settings of a configuration file.
*>
*> One entry per setting line, in file order. A setting line is a
*> key and an optional value separated by spaces; blank lines and
*> lines starting with # are left out.
78  CF-MAX                      VALUE 200.
01  PLB-CONFIG.
    05  CF-COUNT                PIC 9(4) COMP-5.
    *> "Y" when the file had more than CF-MAX settings.
    05  CF-OVERFLOW             PIC X.
    05  CF-ENTRY                OCCURS CF-MAX TIMES.
        10  CF-LINE-NO          PIC 9(9) COMP-5.
        10  CF-KEY              PIC X(31).
        10  CF-VALUE            PIC X(512).
