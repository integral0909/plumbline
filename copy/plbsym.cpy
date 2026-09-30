*> plbsym.cpy: the data items of the analyzed programs.
*>
*> One entry per data description entry, in source order, so a group
*> always comes before its members. Built from the syntax tree by
*> PLB-SYM-BUILD.
78  SY-MAX                      VALUE 100000.
01  PLB-SYMBOLS.
    05  SY-COUNT                PIC 9(9) COMP-5.
    05  SY-ENTRY                OCCURS SY-MAX TIMES.
        *> The DATA node, and the PROG node of the owning program.
        10  SY-NODE             PIC 9(9) COMP-5.
        10  SY-PROGRAM          PIC 9(9) COMP-5.
        *> Token of the name (0 for FILLER or an unnamed item).
        10  SY-NAME-TOKEN       PIC 9(9) COMP-5.
        10  SY-NAME             PIC X(31).
        *> Where the item is declared:
        *>   W working-storage  L local-storage  K linkage
        *>   F file             R report         S screen   ? other
        10  SY-SECTION          PIC X.
        10  SY-LEVEL            PIC 9(4) COMP-5.
        *> Entry of the group this item belongs to (0 for a record).
        10  SY-PARENT           PIC 9(9) COMP-5.
        *> Category: the picture category (A X 9 E D N M 1, see
        *> plbpic.cpy), or G group, C condition name (88), R renames
        *> (66), K constant (78), U a usage without a picture (INDEX,
        *> POINTER, COMP-1), ? an invalid or missing picture.
        10  SY-CATEGORY         PIC X.
        10  SY-USAGE            PIC X(20).
        10  SY-DIGITS           PIC 9(4) COMP-5.
        10  SY-SCALE            PIC S9(4) COMP-5.
        10  SY-SIGNED           PIC X.
        *> Bytes of one occurrence, and the offset of the first
        *> occurrence from the start of the record.
        10  SY-SIZE             PIC 9(9) COMP-5.
        10  SY-OFFSET           PIC 9(9) COMP-5.
        *> Maximum OCCURS (0 when the item is not a table), and the
        *> token naming the DEPENDING ON object.
        10  SY-OCCURS           PIC 9(9) COMP-5.
        10  SY-ODO-TOKEN        PIC 9(9) COMP-5.
        *> Entry this item redefines (0 if none).
        10  SY-REDEFINES        PIC 9(9) COMP-5.
        10  SY-HAS-VALUE        PIC X.
