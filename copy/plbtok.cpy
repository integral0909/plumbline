*> plbtok.cpy: tokens produced by the lexer.
*>
*> Tokens of all files are kept in one table, in source order. Each
*> file's tokens end with an end-of-file token (kind "E").
*>
*> TK-TEXT holds normalized token text:
*>   words, pictures     upper-cased as written
*>   numeric literals    as written, sign included
*>   alphanumeric lits   the value: no quotes or prefix, doubled
*>                       quotes collapsed, continuations joined
*>   operators, others   the characters of the token
*> TK-SRC-LINE is the SS-LINE index of the token's first character;
*> TK-COLUMN its column there. TK-SPAN is the token's length in the
*> logical stream (a token continued onto another line spans both).
*>
*> The table limits are in plbtokc.cpy, which a program copies once
*> even when it copies this record several times under other names
*> (COPY "plbtok.cpy" REPLACING ==PLB-TOKENS== BY ==OTHER-TOKENS==).
01  PLB-TOKENS.
    05  TK-COUNT                PIC 9(9) COMP-5.
    05  TK-TEXT-USED            PIC 9(9) COMP-5.
    05  TK-ENTRY                OCCURS TK-MAX TIMES.
        10  TK-KIND             PIC X.
            88  TK-IS-WORD            VALUE "W".
            88  TK-IS-NUMBER          VALUE "N".
            88  TK-IS-ALNUM           VALUE "A".
            88  TK-IS-PICTURE         VALUE "P".
            88  TK-IS-PERIOD          VALUE ".".
            88  TK-IS-LPAREN          VALUE "(".
            88  TK-IS-RPAREN          VALUE ")".
            88  TK-IS-COLON           VALUE ":".
            88  TK-IS-OPERATOR        VALUE "O".
            88  TK-IS-PSEUDO          VALUE "=".
            88  TK-IS-EOF             VALUE "E".
        *> Alphanumeric literal prefix: spaces, or X, Z, N, NX, G, B,
        *> BX, U (as in X"FF", N"text").
        10  TK-PREFIX           PIC XX.
        *> For a word, its reserved-word kind (see plbkwtab.cpy) or
        *> space; looked up once, when the token is made.
        10  TK-KEYWORD          PIC X.
        10  TK-FILE-ID          PIC 9(4) COMP-5.
        *> Inclusion the token came through (see plbincl.cpy); 0 for
        *> tokens of the main file and for unexpanded token streams.
        10  TK-INCL             PIC 9(4) COMP-5.
        10  TK-SRC-LINE         PIC 9(9) COMP-5.
        10  TK-COLUMN           PIC 9(4) COMP-5.
        10  TK-SPAN             PIC 9(9) COMP-5.
        10  TK-TEXT-OFF         PIC 9(9) COMP-5.
        10  TK-TEXT-LEN         PIC 9(9) COMP-5.
    05  TK-TEXT                 PIC X(TK-TEXT-SIZE).
