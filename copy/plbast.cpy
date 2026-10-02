*> plbast.cpy: the syntax tree.
*>
*> Nodes live in one table and are linked by index: parent, first and
*> last child, and next sibling (0 means none). Node 1 is the root of
*> each parse. Each node covers a range of tokens in the expanded
*> token table (ND-TOK-FIRST..ND-TOK-LAST).
*>
*> Node kinds:
*>   UNIT  root: one source file                  PARA  paragraph
*>   PROG  program (name: PROGRAM-ID)             SENT  sentence
*>   DIVN  division (detail: IDENTIFICATION, ...) STMT  statement (detail: verb)
*>   SECT  section (detail: section name)         BLCK  statements under a
*>   IDPA  identification paragraph                     phrase (detail: THEN,
*>   SELE  SELECT entry in FILE-CONTROL                 ELSE, WHEN, AT-END, ...)
*>   FD    file or sort description (detail FD/SD) COND  condition
*>   DATA  data description entry (num: level)    REF   data reference
*>   CLAU  clause of an entry (detail: PICTURE...) PROC  procedure name
*>   USNG  USING/RETURNING item of PROCEDURE DIV. LIT   literal operand
*>   ERR   tokens that could not be parsed        OTHR  other phrase
*>
*> The limit AS-MAX is in plbastc.cpy.
01  PLB-AST.
    05  AS-COUNT                PIC 9(9) COMP-5.
    05  AS-NODE                 OCCURS AS-MAX TIMES.
        10  ND-KIND             PIC X(4).
        10  ND-DETAIL           PIC X(20).
        10  ND-PARENT           PIC 9(9) COMP-5.
        10  ND-FIRST            PIC 9(9) COMP-5.
        10  ND-LAST             PIC 9(9) COMP-5.
        10  ND-NEXT             PIC 9(9) COMP-5.
        10  ND-TOK-FIRST        PIC 9(9) COMP-5.
        10  ND-TOK-LAST         PIC 9(9) COMP-5.
        *> Token that names the node (program, paragraph, data item,
        *> referenced identifier), or 0.
        10  ND-NAME             PIC 9(9) COMP-5.
        *> Numeric attribute: level number of a DATA node.
        10  ND-NUM              PIC S9(9) COMP-5.
