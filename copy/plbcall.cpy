*> plbcall.cpy: the call graph of one run.
*>
*> Unlike the other analysis tables, which hold one file at a time,
*> the call graph collects the programs and CALL statements of every
*> file in the run, so that calls between files can be checked.
*>
*> Programs (CP) include ENTRY points; each has a list of parameters
*> (CA), its PROCEDURE DIVISION USING or ENTRY ... USING items. Calls
*> (CC) each have a list of arguments (CG). The files of each program
*> (PF) say which DD name the job step must provide, and the maps of
*> each program (PM) which BMS maps it sends and receives, the CICS
*> resources (PU) its commands name, the short literals (PL) that
*> may name programs, the SQL tables (PQ) it uses or declares, and its
*> IMS DL/I calls (PD).
*>
*> Names are compared without regard to case: CP-NAME and CC-TARGET
*> are upper-cased.
*> The limits are in plbcallc.cpy, which a program copies once.
01  PLB-CALL-GRAPH.
    05  CP-COUNT                PIC 9(9) COMP-5.
    05  CP-ENTRY                OCCURS CP-MAX TIMES.
        10  CP-NAME             PIC X(31).
        *> The name as written, case kept: GnuCOBOL keeps PROG and
        *> prog apart.
        10  CP-SPELLING         PIC X(31).
        *>   P program   E ENTRY point of program CP-OWNER
        10  CP-KIND             PIC X.
        *> The program itself, or for an ENTRY, the program it is in.
        10  CP-OWNER            PIC 9(9) COMP-5.
        *> The program containing CP-OWNER (0: an outermost program).
        10  CP-PARENT           PIC 9(9) COMP-5.
        *> Where the name is: file, line, column, SS-LINE index.
        10  CP-FILE-ID          PIC 9(4) COMP-5.
        10  CP-LINE             PIC 9(9) COMP-5.
        10  CP-COLUMN           PIC 9(4) COMP-5.
        10  CP-SRC-LINE         PIC 9(9) COMP-5.
        *> "Y" for IS COMMON and IS RECURSIVE programs.
        10  CP-COMMON           PIC X.
        10  CP-RECURSIVE        PIC X.
        *> "Y" when the program has EXEC CICS commands.
        10  CP-CICS             PIC X.
        10  CP-PARAM-FIRST      PIC 9(9) COMP-5.
        10  CP-PARAM-COUNT      PIC 9(4) COMP-5.
        *> Where the program's first STOP RUN is (CP-STOP-LINE 0:
        *> it has none). A STOP RUN of a nested program is that
        *> program's own.
        10  CP-STOP-FILE-ID     PIC 9(4) COMP-5.
        10  CP-STOP-LINE        PIC 9(9) COMP-5.
        10  CP-STOP-COLUMN      PIC 9(4) COMP-5.
        10  CP-STOP-SRC-LINE    PIC 9(9) COMP-5.
    05  CA-COUNT                PIC 9(9) COMP-5.
    05  CA-ENTRY                OCCURS CA-MAX TIMES.
        10  CA-NAME             PIC X(31).
        *>   R BY REFERENCE   V BY VALUE
        10  CA-MODE             PIC X.
        *> Bytes, or 0 when unknown (ANY LENGTH, unresolved).
        10  CA-SIZE             PIC 9(9) COMP-5.
    05  CC-COUNT                PIC 9(9) COMP-5.
    05  CC-ENTRY                OCCURS CC-MAX TIMES.
        *> The calling program.
        10  CC-FROM             PIC 9(9) COMP-5.
        *> Where the target is named: file, line, column, SS-LINE.
        10  CC-FILE-ID          PIC 9(4) COMP-5.
        10  CC-LINE             PIC 9(9) COMP-5.
        10  CC-COLUMN           PIC 9(4) COMP-5.
        10  CC-SRC-LINE         PIC 9(9) COMP-5.
        *> The literal program name, or for a dynamic call the name of
        *> the data item holding it.
        10  CC-TARGET           PIC X(31).
        10  CC-SPELLING         PIC X(31).
        10  CC-DYNAMIC          PIC X.
        *> Set by PLB-CALL-RESOLVE: the program called (0: not found
        *> in this run, or ambiguous), and how many programs of the
        *> run the name matched.
        10  CC-TO               PIC 9(9) COMP-5.
        10  CC-MATCHES          PIC 9(4) COMP-5.
        10  CC-ARG-FIRST        PIC 9(9) COMP-5.
        10  CC-ARG-COUNT        PIC 9(4) COMP-5.
    05  CG-COUNT                PIC 9(9) COMP-5.
    05  CG-ENTRY                OCCURS CG-MAX TIMES.
        *> The data item's name or the literal, for messages.
        10  CG-TEXT             PIC X(31).
        *>   D data item   L literal   O OMITTED
        *>   X something else (ADDRESS OF, LENGTH OF, a function)
        10  CG-KIND             PIC X.
        *>   R BY REFERENCE   C BY CONTENT   V BY VALUE
        10  CG-MODE             PIC X.
        *> Bytes, or 0 when unknown.
        10  CG-SIZE             PIC 9(9) COMP-5.
    *> Programs, calls, or arguments that did not fit.
    05  CP-DROPPED              PIC 9(9) COMP-5.
    05  PF-COUNT                PIC 9(9) COMP-5.
    05  PF-ENTRY                OCCURS PF-MAX TIMES.
        10  PF-PROGRAM          PIC 9(9) COMP-5.
        10  PF-NAME             PIC X(31).
        *> The DD name of SELECT ... ASSIGN TO: the name, or its last
        *> part after a hyphen (UT-S-INFILE is DD INFILE). Spaces when
        *> the file is assigned to a data item, a path, or a device.
        10  PF-DDNAME           PIC X(8).
        *> "Y" for SELECT OPTIONAL, and for a sort or merge file (SD).
        10  PF-OPTIONAL         PIC X.
        10  PF-SORT             PIC X.
        *> ALTERNATE RECORD KEY clauses: each has a path DD of its own.
        10  PF-ALTERNATES       PIC 9(4) COMP-5.
        *> Open modes of the OPEN statements that name the file.
        10  PF-INPUT            PIC X.
        10  PF-OUTPUT           PIC X.
        10  PF-I-O              PIC X.
        10  PF-EXTEND           PIC X.
        *> Where the file is named in its SELECT.
        10  PF-FILE-ID          PIC 9(4) COMP-5.
        10  PF-LINE             PIC 9(9) COMP-5.
        10  PF-COLUMN           PIC 9(4) COMP-5.
        10  PF-SRC-LINE         PIC 9(9) COMP-5.
    05  PM-COUNT                PIC 9(9) COMP-5.
    05  PM-ENTRY                OCCURS PM-MAX TIMES.
        10  PM-PROGRAM          PIC 9(9) COMP-5.
        *> EXEC CICS SEND MAP (S) or RECEIVE MAP (R), with the map and
        *> mapset it names: a literal, or a data item whose VALUE is
        *> one and that no statement changes. MAPSET left out is the
        *> map's own name.
        10  PM-COMMAND          PIC X.
        10  PM-MAP              PIC X(8).
        10  PM-MAPSET           PIC X(8).
        10  PM-FILE-ID          PIC 9(4) COMP-5.
        10  PM-LINE             PIC 9(9) COMP-5.
        10  PM-COLUMN           PIC 9(4) COMP-5.
        10  PM-SRC-LINE         PIC 9(9) COMP-5.
    05  PU-COUNT                PIC 9(9) COMP-5.
    05  PU-ENTRY                OCCURS PU-MAX TIMES.
        10  PU-PROGRAM          PIC 9(9) COMP-5.
        *> The kind of resource: F file (FILE or DATASET), T
        *> transaction (TRANSID), P program (XCTL, LINK, LOAD), M
        *> mapset, Q transient data queue (WRITEQ TD, READQ TD).
        10  PU-KIND             PIC X.
        10  PU-NAME             PIC X(8).
        *> The command: READ, XCTL, RETURN, ...
        10  PU-COMMAND          PIC X(12).
        10  PU-FILE-ID          PIC 9(4) COMP-5.
        10  PU-LINE             PIC 9(9) COMP-5.
        10  PU-COLUMN           PIC 9(4) COMP-5.
    *> Literals of 1 to 8 letters and digits, which a program may use
    *> to name another one (menu tables, XCTL through a data item).
    05  PL-COUNT                PIC 9(9) COMP-5.
    05  PL-ENTRY                OCCURS PL-MAX TIMES.
        10  PL-PROGRAM          PIC 9(9) COMP-5.
        10  PL-NAME             PIC X(8).
    05  PQ-COUNT                PIC 9(9) COMP-5.
    05  PQ-ENTRY                OCCURS PQ-MAX TIMES.
        10  PQ-PROGRAM          PIC 9(9) COMP-5.
        *> The table as written: NAME or QUALIFIER.NAME, upper-cased.
        10  PQ-TABLE            PIC X(64).
        *>   S selected (FROM, JOIN)   I inserted into   U updated
        *>   D deleted from   M merged into   T declared (DECLARE TABLE)
        10  PQ-KIND             PIC X.
        10  PQ-FILE-ID          PIC 9(4) COMP-5.
        10  PQ-LINE             PIC 9(9) COMP-5.
        10  PQ-COLUMN           PIC 9(4) COMP-5.
        10  PQ-SRC-LINE         PIC 9(9) COMP-5.
    05  PD-COUNT                PIC 9(9) COMP-5.
    05  PD-ENTRY                OCCURS PD-MAX TIMES.
        10  PD-PROGRAM          PIC 9(9) COMP-5.
        *> EXEC DLI function: GU, GN, GNP, ISRT, REPL, DLET, SCHD, ...
        10  PD-FUNCTION         PIC X(8).
        *>   S a segment the call names (SEGMENT)
        *>   P a PSB it schedules (SCHD PSB)
        10  PD-KIND             PIC X.
        10  PD-NAME             PIC X(8).
        10  PD-FILE-ID          PIC 9(4) COMP-5.
        10  PD-LINE             PIC 9(9) COMP-5.
        10  PD-COLUMN           PIC 9(4) COMP-5.
        10  PD-SRC-LINE         PIC 9(9) COMP-5.
