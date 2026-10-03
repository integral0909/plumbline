*> plbsqlm.cpy: the embedded SQL of one file (src/lib/plbsqlu.cob).
*>
*> The tables its DECLARE TABLE statements describe (from DCLGEN
*> copybooks, usually) with their columns, the cursors it declares,
*> and the statements that move values between columns and host
*> variables, each with its pairs of a column and a host variable:
*>
*>   SELECT ... INTO   select item i and INTO host variable i
*>   FETCH             item i of its cursor's select list and INTO
*>                     host variable i
*>   INSERT            column i of the column list and VALUES item i
*>   UPDATE            each SET column = :host-variable
*>
*> A pair whose select item is an expression has no column; one whose
*> value is not a host variable alone is not kept. Names are in upper
*> case; a qualified table name keeps its qualifier (CARDDEMO.T).
78  QT-MAX                      VALUE 500.
78  QL-MAX                      VALUE 10000.
78  QS-MAX                      VALUE 5000.
78  QP-MAX                      VALUE 20000.
01  PLB-SQL-MODEL.
    05  QT-COUNT                PIC 9(9) COMP-5.
    05  QT-ENTRY                OCCURS QT-MAX TIMES.
        10  QT-NAME             PIC X(64).
        *> The name without its qualifier.
        10  QT-SHORT            PIC X(64).
        10  QT-TOKEN            PIC 9(9) COMP-5.
        10  QT-COL-FIRST        PIC 9(9) COMP-5.
        10  QT-COL-COUNT        PIC 9(9) COMP-5.
    05  QL-COUNT                PIC 9(9) COMP-5.
    05  QL-ENTRY                OCCURS QL-MAX TIMES.
        10  QL-TABLE            PIC 9(9) COMP-5.
        10  QL-NAME             PIC X(31).
        *> CHAR, VARCHAR, GRAPHIC, VARGRAPHIC, DECIMAL, INTEGER,
        *> SMALLINT, BIGINT, FLOAT, DATE, TIME, TIMESTAMP, or the type
        *> as written; CHARACTER and DEC, NUMERIC, and INT are given
        *> their usual names.
        10  QL-TYPE             PIC X(12).
        *> Length (CHAR, VARCHAR) or precision (DECIMAL), and scale;
        *> 0 when not given (CHAR is then 1, DECIMAL 5,0).
        10  QL-LENGTH           PIC 9(9) COMP-5.
        10  QL-SCALE            PIC 9(9) COMP-5.
        *> "N" for NOT NULL.
        10  QL-NULLS            PIC X.
        10  QL-TOKEN            PIC 9(9) COMP-5.
    05  QS-COUNT                PIC 9(9) COMP-5.
    05  QS-ENTRY                OCCURS QS-MAX TIMES.
        *>   S SELECT INTO   F FETCH   I INSERT   U UPDATE
        *>   C a cursor's declaration (its pairs have no host variable)
        *>   D DELETE (no pairs)
        10  QS-KIND             PIC X.
        *> The cursor of C and F.
        10  QS-CURSOR           PIC X(31).
        *> The EXEC token, and END-EXEC.
        10  QS-TOKEN            PIC 9(9) COMP-5.
        10  QS-END              PIC 9(9) COMP-5.
        *> The tables it names (FROM, INTO, UPDATE): up to four.
        10  QS-TABLE-COUNT      PIC 9(4) COMP-5.
        10  QS-TABLE            PIC X(64) OCCURS 4 TIMES.
        10  QS-PAIR-FIRST       PIC 9(9) COMP-5.
        10  QS-PAIR-COUNT       PIC 9(9) COMP-5.
    05  QP-COUNT                PIC 9(9) COMP-5.
    05  QP-ENTRY                OCCURS QP-MAX TIMES.
        *> The column, and the token naming it (0 for an expression).
        10  QP-COLUMN           PIC X(31).
        10  QP-COLUMN-TOKEN     PIC 9(9) COMP-5.
        *> The host variable's name token after its colon (0: none),
        *> and its indicator variable's (:HV :IND, :HV INDICATOR :IND;
        *> 0: none).
        10  QP-HOST-TOKEN       PIC 9(9) COMP-5.
        10  QP-INDICATOR-TOKEN  PIC 9(9) COMP-5.
    *> Entries that did not fit.
    05  QS-DROPPED              PIC 9(9) COMP-5.
