*> plbpic.cpy: what a PICTURE character-string describes.
01  PLB-PIC-INFO.
    *> Category:
    *>   A  alphabetic               X  alphanumeric
    *>   9  numeric                  E  numeric-edited
    *>   D  alphanumeric-edited      N  national
    *>   M  national-edited          1  boolean
    *>   ?  not a valid picture (PI-ERROR says why)
    05  PI-CATEGORY             PIC X.
        88  PI-IS-ALPHABETIC          VALUE "A".
        88  PI-IS-ALPHANUMERIC        VALUE "X".
        88  PI-IS-NUMERIC             VALUE "9".
        88  PI-IS-NUMERIC-EDITED      VALUE "E".
        88  PI-IS-ALNUM-EDITED        VALUE "D".
        88  PI-IS-NATIONAL            VALUE "N".
        88  PI-IS-NATIONAL-EDITED     VALUE "M".
        88  PI-IS-BOOLEAN             VALUE "1".
        88  PI-IS-INVALID             VALUE "?".
    *> Character positions the item occupies when displayed (USAGE
    *> DISPLAY or NATIONAL); S, V, and P take none.
    05  PI-SIZE                 PIC 9(9) COMP-5.
    *> Digit positions (9, and Z * + - $ that stand for digits), plus
    *> scaling positions P.
    05  PI-DIGITS               PIC 9(4) COMP-5.
    *> Digits to the right of the decimal point (V or an edited
    *> period). Negative when P scales to the left: 99PPP has -3.
    05  PI-SCALE                PIC S9(4) COMP-5.
    *> "Y" when the value can be negative (S, or a sign in editing).
    05  PI-SIGNED               PIC X.
    *> "Y" when a repetition count is a constant name, as in
    *> X(MAX-LEN); it counts as 1 here. Callers that know the
    *> constants substitute their values before analysis.
    05  PI-SYMBOLIC             PIC X.
    05  PI-ERROR                PIC X(60).
