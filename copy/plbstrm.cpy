*> plbstrm.cpy: the logical character stream of one source file.
*>
*> The lexer does not scan physical lines. It scans one stream per
*> file in which:
*>   - comment, blank, page, and directive lines are left out, and so
*>     are debugging lines unless debugging mode is on;
*>   - each remaining line contributes its significant text;
*>   - lines are separated by a newline character (X"0A"), except
*>     that a fixed-format continuation line is joined directly to
*>     the line it continues. A continued literal is padded to column
*>     72 and resumes after the opening quote of the continuation.
*>
*> ST-SEGMENT maps stream positions back to source: stream position
*> SG-START(n) + k is column SG-COL(n) + k of source line SG-LINE(n)
*> (an index into SS-LINE), for 0 <= k < SG-LEN(n). Newlines belong
*> to no segment.
78  ST-SIZE                     VALUE 16000000.
78  ST-MAX-SEGMENTS             VALUE 200000.
01  PLB-STREAM.
    05  ST-FILE-ID              PIC 9(4) COMP-5.
    05  ST-LEN                  PIC 9(9) COMP-5.
    05  ST-SEG-COUNT            PIC 9(9) COMP-5.
    05  ST-SEGMENT              OCCURS ST-MAX-SEGMENTS TIMES.
        10  SG-START            PIC 9(9) COMP-5.
        10  SG-LINE             PIC 9(9) COMP-5.
        10  SG-COL              PIC 9(4) COMP-5.
        10  SG-LEN              PIC 9(4) COMP-5.
    05  ST-TEXT                 PIC X(ST-SIZE).
