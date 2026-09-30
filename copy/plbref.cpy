*> plbref.cpy: data references in the procedure division.
*>
*> One entry per identifier: a user-defined word in a procedure
*> division that is not a procedure name, with its qualifiers
*> (IN/OF), subscripts, and reference modifier. Identifiers inside
*> subscripts get entries of their own.
78  RF-MAX                      VALUE 200000.
01  PLB-REFS.
    05  RF-COUNT                PIC 9(9) COMP-5.
    05  RF-ENTRY                OCCURS RF-MAX TIMES.
        *> First token (the name) and last token (the closing
        *> parenthesis of a subscript or reference modifier, or the
        *> last qualifier).
        10  RF-TOKEN            PIC 9(9) COMP-5.
        10  RF-LAST             PIC 9(9) COMP-5.
        *> The innermost statement containing the reference.
        10  RF-STMT             PIC 9(9) COMP-5.
        *> What the name resolved to:
        *>   D  a data item (RF-SYMBOL is its entry)
        *>   P  a paragraph or section
        *>   O  another kind of name: a file, mnemonic, index, ...
        *>   A  ambiguous: several data items match (RF-SYMBOL is the
        *>      first)
        *>   U  nothing: an undefined name
        10  RF-KIND             PIC X.
        10  RF-SYMBOL           PIC 9(9) COMP-5.
        10  RF-SUBSCRIPTED      PIC X.
        10  RF-REFMOD           PIC X.
        *> What the statement does with the item (set by
        *> PLB-REF-ROLES):
        *>   U  reads it               D  gives it a value
        *>   B  reads it, then gives it a value (ADD 1 TO X)
        *>   X  unknown: may read or set it (CALL ... BY REFERENCE)
        *>   -  not a data item, so no role
        10  RF-ROLE             PIC X.
