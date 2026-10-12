*> plbrange.cpy: the values a relation of a numeric item with a number
*> holds, as PLB-COND-RANGE reads it (item > 10, item = 5, item NOT <
*> 3): the item as written, with its subscripts, and the interval from
*> RG-LOW to RG-HIGH. An end that is missing has no limit; an open end
*> is not itself in the interval. RG-OK is "N" for a condition that is
*> not such a relation. The fields only, for 01 PLB-RANGE, or under
*> a table entry with REPLACING LEADING ==RG-== BY another prefix.
    05  RG-OK                   PIC X.
    05  RG-SUBJECT              PIC X(64).
    05  RG-LOW                  PIC S9(18)V9(9) COMP-3.
    05  RG-HIGH                 PIC S9(18)V9(9) COMP-3.
    05  RG-NO-LOW               PIC X.
    05  RG-NO-HIGH              PIC X.
    05  RG-OPEN-LOW             PIC X.
    05  RG-OPEN-HIGH            PIC X.
