*> plbinput.cpy: the input files named for one run, from the command
*> line and from list files (--files-from).
*>
*> Inputs and the copybooks they include share the source set's
*> SS-MAX-FILES ids.
78  IP-MAX                      VALUE 10000.
78  IP-PATH-SIZE                VALUE 512.
01  PLB-INPUTS.
    05  IP-COUNT                PIC 9(4) COMP-5.
    05  IP-PATH                 PIC X(IP-PATH-SIZE)
                                OCCURS IP-MAX TIMES.
