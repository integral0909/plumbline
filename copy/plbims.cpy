*> plbims.cpy: IMS database and program specifications.
*>
*> PLB-IMS-READ appends one DBD or PSB source at a time. A DBD (DBD
*> ... DBDGEN) defines a database: its segments (SEGM), each with its
*> parent, and their fields (FIELD). A PSB (PCB ... PSBGEN) is what a
*> program may see: its PCBs, each for one database (DBDNAME) with the
*> processing options it allows (PROCOPT), and the segments the program
*> is sensitive to (SENSEG). Names are kept in upper case.
*>
*> The limits are in plbimsc.cpy, which a program copies once.
01  PLB-IMS.
    05  XD-COUNT                PIC 9(9) COMP-5.
    05  XD-ENTRY                OCCURS XD-MAX TIMES.
        10  XD-NAME             PIC X(8).
        *> ACCESS=(HIDAM,VSAM): the first, the access method.
        10  XD-ACCESS           PIC X(8).
        10  XD-FILE-ID          PIC 9(4) COMP-5.
        10  XD-LINE             PIC 9(9) COMP-5.
    05  XG-COUNT                PIC 9(9) COMP-5.
    05  XG-ENTRY                OCCURS XG-MAX TIMES.
        10  XG-DBD              PIC 9(9) COMP-5.
        10  XG-NAME             PIC X(8).
        *> Spaces for a root segment (PARENT=0).
        10  XG-PARENT           PIC X(8).
        10  XG-BYTES            PIC 9(9) COMP-5.
        10  XG-FILE-ID          PIC 9(4) COMP-5.
        10  XG-LINE             PIC 9(9) COMP-5.
    05  XF-COUNT                PIC 9(9) COMP-5.
    05  XF-ENTRY                OCCURS XF-MAX TIMES.
        10  XF-SEGMENT          PIC 9(9) COMP-5.
        10  XF-NAME             PIC X(8).
        *> "Y" for the sequence field (NAME=(name,SEQ,...)).
        10  XF-SEQUENCE         PIC X.
        10  XF-START            PIC 9(9) COMP-5.
        10  XF-BYTES            PIC 9(9) COMP-5.
        10  XF-LINE             PIC 9(9) COMP-5.
    05  XP-COUNT                PIC 9(9) COMP-5.
    05  XP-ENTRY                OCCURS XP-MAX TIMES.
        *> PSBGEN PSBNAME=, or the file's name when it has none.
        10  XP-NAME             PIC X(8).
        10  XP-FILE-ID          PIC 9(4) COMP-5.
        10  XP-LINE             PIC 9(9) COMP-5.
    05  XC-COUNT                PIC 9(9) COMP-5.
    05  XC-ENTRY                OCCURS XC-MAX TIMES.
        10  XC-PSB              PIC 9(9) COMP-5.
        *> The PCB's label, or spaces.
        10  XC-NAME             PIC X(8).
        *> TYPE=DB, TP, or GSAM.
        10  XC-TYPE             PIC X(4).
        10  XC-DBD              PIC X(8).
        10  XC-PROCOPT          PIC X(8).
        10  XC-FILE-ID          PIC 9(4) COMP-5.
        10  XC-LINE             PIC 9(9) COMP-5.
    05  XS-COUNT                PIC 9(9) COMP-5.
    05  XS-ENTRY                OCCURS XS-MAX TIMES.
        10  XS-PCB              PIC 9(9) COMP-5.
        10  XS-NAME             PIC X(8).
        10  XS-PARENT           PIC X(8).
        10  XS-FILE-ID          PIC 9(4) COMP-5.
        10  XS-LINE             PIC 9(9) COMP-5.
