*> plbcall.cpy: the call graph of one run.
*>
*> Unlike the other analysis tables, which hold one file at a time,
*> the call graph collects the programs and CALL statements of every
*> file in the run, so that calls between files can be checked.
*>
*> Programs (CP) include ENTRY points; each has a list of parameters
*> (CA), its PROCEDURE DIVISION USING or ENTRY ... USING items. Calls
*> (CC) each have a list of arguments (CG).
*>
*> Names are compared without regard to case: CP-NAME and CC-TARGET
*> are upper-cased.
*> The limits are in plbcallc.cpy, which a program copies once.
01  PLB-CALL-GRAPH.
    05  CP-COUNT                PIC 9(9) COMP-5.
    05  CP-ENTRY                OCCURS CP-MAX TIMES.
        10  CP-NAME             PIC X(31).
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
        10  CP-PARAM-FIRST      PIC 9(9) COMP-5.
        10  CP-PARAM-COUNT      PIC 9(4) COMP-5.
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
