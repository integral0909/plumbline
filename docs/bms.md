# CICS BMS maps

Online CICS programs talk to the terminal through maps: screens
defined with the BMS macros `DFHMSD` (a mapset), `DFHMDI` (a map), and
`DFHMDF` (a field), assembled into a physical map that CICS uses and a
symbolic map, the copybook a program uses to fill and read the screen.
Plumbline reads BMS sources so that maps can be checked.

## Reading BMS

`plumbline dump bms FILE...` shows what Plumbline reads: each mapset,
its maps with their size, and their fields with position, length, and
attributes.

```console
$ plumbline dump bms app/bms/COSGN00.bms
app/bms/COSGN00.bms:19: mapset COSGN00
app/bms/COSGN00.bms:26:   map COSGN0A size 24x80
app/bms/COSGN00.bms:29:     field - at 1,1 length 6 protected initial
app/bms/COSGN00.bms:34:     field TRNNAME at 1,8 length 4 protected
...
app/bms/COSGN00.bms:156:     field USERID at 19,43 length 8 input
```

A BMS source is assembler:

- A statement has an optional name starting in column 1, the macro,
  and operands separated by commas, up to the first blank outside
  quotes. The rest of the line is a comment.
- A character in column 72 continues the statement on the next line,
  from column 16; a quoted string that runs to column 71 goes on there
  too.
- Lines starting with `*` or `.*` are comments, and `END` ends the
  source.

A field's `POS` is the place of its attribute byte, as `(row,column)`
or as an offset from the start of the map; the field's data follows
that byte. A field without `ATTRB` is `ASKIP` (protected); one with an
`ATTRB` that names neither `ASKIP` nor `PROT` takes input.

## Checking maps

Give `check` the BMS sources (`*.bms`, in either case) with the
programs, and each map is checked: fields that overlap
([PLB-B001](rules.md#plb-b001-map-fields-overlap)), and fields past the
end of the map ([PLB-B002](rules.md#plb-b002-field-outside-map)). The
programs' `SEND MAP` and `RECEIVE MAP` commands are checked against the
maps ([PLB-B003](rules.md#plb-b003-map-not-in-mapset)); `dump calls`
lists the maps each program uses.

```console
$ plumbline check app/bms/*.bms
app/bms/COCRDSL.bms:148:1: error: field FKEYS overlaps field ERRMSG of map CCRDSLA [PLB-B001]
```
