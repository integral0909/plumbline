# IMS databases and PSBs

IMS programs reach their databases through a PSB, the program's view:
a PCB for each database it uses, with the processing options it is
allowed (`PROCOPT`), and the segments it is sensitive to (`SENSEG`).
Each database is described by a DBD: its segments, their parents, and
their fields. Both are written as assembler macros:

```
         DBD     NAME=DBPAUTP0,ACCESS=(HIDAM,VSAM)
         SEGM    NAME=PAUTSUM0,PARENT=0,BYTES=100
         FIELD   NAME=(ACCNTID,SEQ,U),START=1,BYTES=6,TYPE=P
...
PAUTBPCB PCB     TYPE=DB,DBDNAME=DBPAUTP0,PROCOPT=AP,KEYLEN=14
         SENSEG  NAME=PAUTSUM0,PARENT=0
         PSBGEN  LANG=COBOL,PSBNAME=PSBPAUTB
```

## Reading DBDs and PSBs

`plumbline dump ims FILE...` shows what Plumbline reads from DBD and PSB
sources: each database with its access method, segments, and fields,
and each PSB with its PCBs and their sensitive segments.

```console
$ plumbline dump ims ims/DBPAUTP0.dbd ims/PSBPAUTB.psb
ims/DBPAUTP0.dbd:18: dbd DBPAUTP0 access HIDAM
ims/DBPAUTP0.dbd:28:   segment PAUTSUM0 bytes 100
ims/DBPAUTP0.dbd:30:     field ACCNTID start 1 bytes 6 sequence
...
ims/PSBPAUTB.psb:17: psb PSBPAUTB
ims/PSBPAUTB.psb:17:   pcb PAUTBPCB type DB dbd DBPAUTP0 procopt AP
ims/PSBPAUTB.psb:18:     senseg PAUTSUM0
```

Statements are read as assembler, like BMS maps: an optional name in
column 1, the macro, and operands, continued by a character in column
72 from column 16. A `SEGM`'s parent may be written `PARENT=name` or
`PARENT=((name,SNGL))`; `PARENT=0` marks a root. `SENSEG` operands may
be positional (`SENSEG name,parent`), and the database of a `PCB` may be
positional after `TYPE=DB`. A PSB that `PSBGEN` does not name takes the
name of its file.
