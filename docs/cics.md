# CICS resource definitions

A CICS region knows its transactions, programs, mapsets, and files from
its system definition file (the CSD), which is loaded by the utility
DFHCSDUP from commands such as:

```
 DEFINE TRANSACTION(CC00) GROUP(CARDDEMO)
        PROGRAM(COSGN00C) TWASIZE(0) PROFILE(DFHCICST)
 DEFINE FILE(ACCTDAT) GROUP(CARDDEMO)
        DSNAME(AWS.M2.CARDDEMO.ACCTDATA.VSAM.KSDS)
```

Plumbline reads that input so that the programs' `EXEC CICS` commands
can be checked against what the region defines.

## Reading definitions

`plumbline dump csd FILE...` shows each resource a file defines, with
its group, and for a transaction its program, for a file its data set:

```console
$ plumbline dump csd app/csd/CARDDEMO.CSD
app/csd/CARDDEMO.CSD:1: file ACCTDAT group CARDDEMO dsname AWS.M2.CARDDEMO.ACCTDATA.VSAM.KSDS
...
```

A command runs from its verb to the next verb, over as many lines as
it needs. Its keywords stand alone or take a value in parentheses,
which may hold spaces and parentheses of its own
(`DESCRIPTION(ORDER MENU (MAIN SCREEN))`). Lines starting with `*` are
comments. Only `DEFINE` commands are kept; `ADD`, `LIST`, `ALTER`, and
the others are read and passed over.

## Checking programs against the definitions

Give `check` the definitions (`*.csd`, in either case) with the
programs, and each `EXEC CICS` command that names a resource by a
constant is checked against them
([PLB-K001](rules.md#plb-k001-cics-resource-undefined)). `dump calls`
lists the resources each program's commands name.

```console
$ plumbline check app/cbl/*.cbl app/csd/*.csd
```
