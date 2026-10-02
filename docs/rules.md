# Rule reference

`plumbline check` runs these rules. Each has an id (`PLB-C001`) and a
name (`unreachable-code`), and either can be given to `--enable` and
`--disable`.

| Id | Name | Default | Summary |
|----|------|---------|---------|
| [PLB-C001](#plb-c001-unreachable-code) | unreachable-code | warning | Paragraph or section can never be executed |
| [PLB-C002](#plb-c002-perform-and-fall-through) | perform-and-fall-through | warning | Paragraph is both performed and fallen into |
| [PLB-C003](#plb-c003-fall-off-end) | fall-off-end | warning | Control can run off the end of the procedure division |
| [PLB-C004](#plb-c004-next-sentence-in-scope) | next-sentence-in-scope | warning | NEXT SENTENCE inside a scope ended by an END- terminator |
| [PLB-C005](#plb-c005-perform-thru-backwards) | perform-thru-backwards | error | PERFORM THRU range ends before it starts |
| [PLB-C006](#plb-c006-recursive-perform) | recursive-perform | error | Paragraph performs a range that contains itself |
| [PLB-C007](#plb-c007-redefines-larger) | redefines-larger | error | REDEFINES item is larger than the item it redefines |
| [PLB-M001](#plb-m001-go-to) | go-to | note | GO TO statement |
| [PLB-M002](#plb-m002-alter) | alter | warning | ALTER statement (obsolete) |
| [PLB-M003](#plb-m003-unused-data-item) | unused-data-item | warning | Data item is never referenced |

Categories: **C** correctness, **M** maintainability, **P** portability,
**S** security.

## PLB-C001 unreachable-code

A paragraph or section that nothing can execute: it is not the program's
entry point, nothing falls into it, and no `PERFORM` or `GO TO` names it.

The analysis follows COBOL's execution model. A `PERFORM` runs its whole
range and then returns, so a paragraph placed after the end of a
performed range is unreachable unless something else falls into it or
jumps to it:

```cobol
MAIN-LINE.
    PERFORM STEP-1 THRU STEP-EXIT
    STOP RUN.
STEP-1.
    ADD 1 TO COUNTER.
STEP-EXIT.
    EXIT.
AFTER-RANGE.                      *> reported: nothing reaches it
    DISPLAY "NEVER".
```

When a whole section is unreachable, only the section is reported, not
each of its paragraphs.

**Why it matters.** Dead code misleads readers and reviewers, hides
logic that was meant to run, and is often left behind by an incomplete
change to a `PERFORM THRU` range or a `GO TO`.

**What to do.** Delete the code if it is obsolete. If it should run, add
the missing `PERFORM`, or check whether a `THRU` range ends too early.

## PLB-C002 perform-and-fall-through

A paragraph that is the target of a `PERFORM` and is also entered by
falling out of the paragraph before it.

```cobol
MAIN-LINE.
    PERFORM CALC
    DISPLAY "CALCULATED".         *> no STOP RUN: falls into CALC
CALC.                             *> reported
    ADD 1 TO TOTAL.
```

When `CALC` is performed it returns at its end. When it is fallen into,
control continues into whatever follows it. Code is rarely right for
both, and the second entry is usually a missing `STOP RUN`, `GOBACK`, or
`EXIT PROGRAM` in the paragraph before.

## PLB-C003 fall-off-end

Control can reach the end of a program's procedure division without
`STOP RUN`, `GOBACK`, or `EXIT PROGRAM`. The compiler then ends the
program implicitly, which readers easily miss. The finding points at the
last statement before the end.

End the main line explicitly.

## PLB-C004 next-sentence-in-scope

`NEXT SENTENCE` continues after the next *period*, not after the
`END-IF` (or other terminator) of the statement it is in:

```cobol
IF A = 1
    NEXT SENTENCE                 *> reported
ELSE
    MOVE 2 TO B
END-IF
DISPLAY "SKIPPED WHEN A = 1"      *> skipped too, up to the period
```

In code that uses scope terminators this is almost never intended. Use
`CONTINUE`, which does nothing and lets control reach the terminator.

## PLB-C005 perform-thru-backwards

`PERFORM A THRU B` where `B` comes before `A` in the source. The range
never reaches `B`, so control runs past the paragraphs the author meant
and returns only if some later `PERFORM` range happens to end where this
one's return point is. Swap the names, or fix the order of the
paragraphs.

## PLB-C006 recursive-perform

A `PERFORM` whose range includes the paragraph or section containing
the `PERFORM`, for example a paragraph that performs itself, or a
paragraph that performs its own section. COBOL `PERFORM` is not
recursive. The standard leaves the behavior undefined, and real
implementations overwrite the return point, so the program loops or
returns to the wrong place.

## PLB-C007 redefines-larger

An item below level 01 that is larger than the item it redefines:

```cobol
05  CODE-NUM        PIC 9(4).
05  CODE-TEXT REDEFINES CODE-NUM PIC X(6).     *> reported: 6 > 4
```

The extra bytes overlay whatever follows the redefined item, so writing
to `CODE-TEXT` silently changes the next field. The standard forbids it;
some compilers accept it with a warning. Sizes come from the symbol
table, so usages and `OCCURS` are taken into account. Level-01 records
may be redefined by larger records and are not reported.

## PLB-M001 go-to

Every `GO TO` statement, reported as a note. `GO TO` makes the flow of
control hard to follow, and structured statements (`PERFORM`, `EVALUATE`,
inline `PERFORM ... END-PERFORM`) usually say the same thing more
clearly. Notes do not fail a run unless `--fail-on note` is given.
Disable the rule with `--disable go-to` in code bases that use `GO TO`
by convention (for example `GO TO xxx-EXIT`).

## PLB-M002 alter

`ALTER` changes the target of a `GO TO` while the program runs, so the
source no longer says where control goes. It was declared obsolete and
then removed from the standard in 2002. Replace the altered `GO TO` with
a flag and an `EVALUATE` or `IF`.

## PLB-M003 unused-data-item

A working-storage or local-storage item that the program never refers
to. Unused items are clutter at best. At worst they are a sign that code
meant to use them was lost.

An item counts as used when:

- its name, or the name of one of its condition names (level 88), appears
  in the procedure division;
- it is the object of an `OCCURS ... DEPENDING ON`;
- one of its members is used (for a group), or the group it belongs to is
  used by name (for a member);
- an item that `REDEFINES` it is used. This is the common idiom of a table
  of `VALUE` clauses read through a redefinition.

Only the outermost unused item is reported: an unused group is one
finding, not one per member. Items declared in copybooks are not
reported, because programs commonly use part of a shared layout. Neither
are `GLOBAL` or `EXTERNAL` items, which other programs may use, nor
linkage items, constants (level 78), and `RENAMES` (level 66).

References are matched by name within the program, so an item is treated
as used if any item of the same name is referenced.
