# Rule reference

`plumbline check` runs these rules. Each has an id (`PLB-C001`) and a
name (`unreachable-code`), and either can be given to `--enable` and
`--disable`.

| Id | Name | Default | Summary |
|----|------|---------|---------|
| [PLB-A001](#plb-a001-unused-program) | unused-program | note | Program is not called, run by a job, or started by a transaction |
| [PLB-A002](#plb-a002-record-length-conflict) | record-length-conflict | warning | Programs sharing a data set disagree on its record length |
| [PLB-B001](#plb-b001-map-fields-overlap) | map-fields-overlap | error | Two fields of a BMS map share screen positions |
| [PLB-B002](#plb-b002-field-outside-map) | field-outside-map | error | A BMS field ends past the end of its map |
| [PLB-B003](#plb-b003-map-not-in-mapset) | map-not-in-mapset | error | Program sends or receives a map its mapset does not define |
| [PLB-B004](#plb-b004-symbolic-map-stale) | symbolic-map-stale | error | Symbolic map copybook does not match its BMS map |
| [PLB-C001](#plb-c001-unreachable-code) | unreachable-code | warning | Paragraph or section can never be executed |
| [PLB-C002](#plb-c002-perform-and-fall-through) | perform-and-fall-through | warning | Paragraph is both performed and fallen into |
| [PLB-C003](#plb-c003-fall-off-end) | fall-off-end | warning | Control can run off the end of the procedure division |
| [PLB-C004](#plb-c004-next-sentence-in-scope) | next-sentence-in-scope | warning | NEXT SENTENCE inside a scope ended by an END- terminator |
| [PLB-C005](#plb-c005-perform-thru-backwards) | perform-thru-backwards | error | PERFORM THRU range ends before it starts |
| [PLB-C006](#plb-c006-recursive-perform) | recursive-perform | error | Paragraph performs a range that contains itself |
| [PLB-C007](#plb-c007-redefines-larger) | redefines-larger | error | REDEFINES item is larger than the item it redefines |
| [PLB-C008](#plb-c008-move-truncation) | move-truncation | warning | MOVE loses characters or high-order digits |
| [PLB-C009](#plb-c009-undefined-name) | undefined-name | error | Name is not declared |
| [PLB-C010](#plb-c010-ambiguous-name) | ambiguous-name | error | Name refers to more than one data item |
| [PLB-C011](#plb-c011-read-never-set) | read-never-set | warning | Data item is read but never given a value |
| [PLB-C012](#plb-c012-use-before-set) | use-before-set | warning | Data item is read before any path gives it a value |
| [PLB-C013](#plb-c013-call-argument-count) | call-argument-count | warning | CALL passes a different number of arguments than the program takes |
| [PLB-C014](#plb-c014-call-argument-mismatch) | call-argument-mismatch | warning | CALL argument is passed differently or is smaller than its parameter |
| [PLB-C015](#plb-c015-recursive-call) | recursive-call | error | Program that is not RECURSIVE can be called while it is running |
| [PLB-C016](#plb-c016-report-not-initiated) | report-not-initiated | warning | Report is generated or terminated but never initiated |
| [PLB-C017](#plb-c017-report-not-terminated) | report-not-terminated | warning | Report is initiated but never terminated |
| [PLB-C018](#plb-c018-sql-not-checked) | sql-not-checked | warning | Result of an SQL statement is not checked |
| [PLB-C019](#plb-c019-cics-response-not-checked) | cics-response-not-checked | warning | Response of a CICS command is not checked |
| [PLB-C020](#plb-c020-file-status-not-checked) | file-status-not-checked | warning | FILE STATUS is not tested after an I/O statement |
| [PLB-C021](#plb-c021-file-not-opened) | file-not-opened | warning | File is used but never opened |
| [PLB-C022](#plb-c022-open-mode-mismatch) | open-mode-mismatch | error | I/O statement needs an open mode the file is never opened in |
| [PLB-C023](#plb-c023-subscript-out-of-range) | subscript-out-of-range | error | Literal subscript is outside the table |
| [PLB-C024](#plb-c024-refmod-out-of-range) | refmod-out-of-range | error | Literal reference modification is outside the item |
| [PLB-C025](#plb-c025-stop-run-in-called-program) | stop-run-in-called-program | warning | STOP RUN in a program that is called |
| [PLB-C026](#plb-c026-varying-limit-unreachable) | varying-limit-unreachable | warning | PERFORM VARYING waits for a value its counter cannot hold |
| [PLB-C027](#plb-c027-divide-by-zero) | divide-by-zero | error | Divisor is a literal zero |
| [PLB-C028](#plb-c028-comparison-never-true) | comparison-never-true | warning | Data item is compared with a value it cannot hold |
| [PLB-C029](#plb-c029-go-to-leaves-perform) | go-to-leaves-perform | warning | GO TO leaves the range of a PERFORM, which then does not return |
| [PLB-C030](#plb-c030-value-never-used) | value-never-used | warning | Value is replaced before it is used |
| [PLB-C031](#plb-c031-string-overflow) | string-overflow | warning | STRING always sends more than its receiver holds |
| [PLB-C032](#plb-c032-duplicate-when) | duplicate-when | warning | EVALUATE has a WHEN that repeats an earlier one |
| [PLB-C033](#plb-c033-self-move) | self-move | warning | MOVE of an item to itself |
| [PLB-C034](#plb-c034-linkage-not-addressed) | linkage-not-addressed | error | LINKAGE record is used but nothing gives it an address |
| [PLB-C035](#plb-c035-duplicate-paragraph) | duplicate-paragraph | warning | Paragraph or section name defined twice in the same scope |
| [PLB-C036](#plb-c036-arithmetic-overflow) | arithmetic-overflow | warning | ADD, SUBTRACT, MULTIPLY, or COMPUTE into a receiver narrower than an operand |
| [PLB-C037](#plb-c037-search-index-not-set) | search-index-not-set | warning | Serial SEARCH whose index the paragraph does not set first |
| [PLB-C038](#plb-c038-condition-value-unfit) | condition-value-unfit | warning | Condition name with a value its item cannot hold |
| [PLB-C039](#plb-c039-decimal-to-alphanumeric) | decimal-to-alphanumeric | warning | MOVE of a number with decimal places to an alphanumeric item |
| [PLB-C040](#plb-c040-odo-object-too-small) | odo-object-too-small | warning | OCCURS DEPENDING ON object cannot hold the table's largest count |
| [PLB-C041](#plb-c041-write-from-truncation) | write-from-truncation | warning | WRITE or REWRITE FROM an item longer than the record |
| [PLB-C042](#plb-c042-inspect-count-not-reset) | inspect-count-not-reset | warning | INSPECT TALLYING adds to a count the paragraph does not reset |
| [PLB-C043](#plb-c043-pointer-not-reset) | pointer-not-reset | warning | STRING or UNSTRING POINTER that no statement sets |
| [PLB-C044](#plb-c044-varying-control-changed) | varying-control-changed | warning | Statement in a PERFORM VARYING loop changes the loop's control |
| [PLB-C045](#plb-c045-alnum-compared-to-number) | alnum-compared-to-number | warning | Alphanumeric or numeric-edited item compared with a number |
| [PLB-C046](#plb-c046-overlapping-move) | overlapping-move | warning | MOVE between items that share storage |
| [PLB-C047](#plb-c047-foreign-index) | foreign-index | warning | Index of one table subscripts a table with entries of another length |
| [PLB-C048](#plb-c048-sort-procedure-no-record) | sort-procedure-no-record | warning | SORT procedure never RELEASEs or RETURNs a record |
| [PLB-C049](#plb-c049-loop-condition-unchanged) | loop-condition-unchanged | warning | PERFORM UNTIL loop never changes what its condition reads |
| [PLB-C050](#plb-c050-record-read-at-end) | record-read-at-end | warning | AT END of a READ reads the file's record |
| [PLB-C051](#plb-c051-duplicate-if-condition) | duplicate-if-condition | warning | ELSE IF repeats a condition the chain already tested |
| [PLB-C052](#plb-c052-string-overlap) | string-overlap | warning | STRING or UNSTRING sends from storage it receives into |
| [PLB-C053](#plb-c053-exit-program-in-main) | exit-program-in-main | warning | EXIT PROGRAM in a program a job step runs does nothing |
| [PLB-C054](#plb-c054-go-to-into-perform-range) | go-to-into-perform-range | warning | GO TO from outside a PERFORM THRU range into its middle |
| [PLB-C055](#plb-c055-corresponding-no-match) | corresponding-no-match | warning | MOVE, ADD, or SUBTRACT CORRESPONDING finds no items to pair |
| [PLB-C056](#plb-c056-self-comparison) | self-comparison | warning | Data item is compared with itself |
| [PLB-C057](#plb-c057-misleading-indentation) | misleading-indentation | warning | Statement indented as if inside an IF a period has ended |
| [PLB-C058](#plb-c058-read-not-handled) | read-not-handled | warning | READ with no AT END, INVALID KEY, FILE STATUS, or declarative |
| [PLB-C059](#plb-c059-key-error-not-handled) | key-error-not-handled | warning | Keyed WRITE, REWRITE, DELETE, or START with no INVALID KEY |
| [PLB-C060](#plb-c060-spaces-into-numeric) | spaces-into-numeric | warning | Numeric item read after MOVE SPACES to its group |
| [PLB-C061](#plb-c061-unchecked-numeric-move) | unchecked-numeric-move | note, off | Alphanumeric item moved to a numeric one without a NUMERIC test |
| [PLB-C062](#plb-c062-varying-subscript-out-of-range) | varying-subscript-out-of-range | error | PERFORM VARYING counter used as a subscript goes outside the table |
| [PLB-C063](#plb-c063-varying-refmod-out-of-range) | varying-refmod-out-of-range | error | PERFORM VARYING counter in a reference modifier goes outside the item |
| [PLB-C064](#plb-c064-duplicate-condition-value) | duplicate-condition-value | warning | Two condition names of the same item have the same values |
| [PLB-C065](#plb-c065-open-in-loop) | open-in-loop | warning | OPEN runs on every pass of a loop that never closes the file |
| [PLB-C066](#plb-c066-identical-branches) | identical-branches | warning | IF does the same in its ELSE as in its THEN |
| [PLB-C067](#plb-c067-divisor-not-checked) | divisor-not-checked | warning, off | Division by a data item that nothing checks for zero |
| [PLB-C068](#plb-c068-odo-count-out-of-range) | odo-count-out-of-range | error | OCCURS DEPENDING ON count given a value outside the table |
| [PLB-C069](#plb-c069-search-index-used-unchecked) | search-index-used-unchecked | warning | Index used after a SEARCH that has no AT END |
| [PLB-C070](#plb-c070-mq-completion-not-checked) | mq-completion-not-checked | warning | Completion code of an MQ call is not tested |
| [PLB-C071](#plb-c071-contradictory-condition) | contradictory-condition | warning | Relations of one item joined so the condition is never or always true |
| [PLB-C072](#plb-c072-unreachable-statement) | unreachable-statement | warning | Statement after a GO TO, GOBACK, or STOP RUN never runs |
| [PLB-C073](#plb-c073-value-ignored) | value-ignored | warning | VALUE clause in the FILE or LINKAGE SECTION gives no value |
| [PLB-C074](#plb-c074-condition-range-reversed) | condition-range-reversed | warning | Condition name or WHEN has a THRU range whose start is above its end |
| [PLB-C075](#plb-c075-io-after-close) | io-after-close | warning | I/O statement on a file after its CLOSE, with no OPEN between |
| [PLB-C076](#plb-c076-open-while-open) | open-while-open | warning | OPEN of a file already opened, with no CLOSE between |
| [PLB-C077](#plb-c077-index-set-out-of-range) | index-set-out-of-range | warning | SET of an index to a number outside its table |
| [PLB-C078](#plb-c078-string-literal-cut) | string-literal-cut | warning | STRING literal holds its own delimiter and is sent cut short |
| [PLB-C079](#plb-c079-nonnumeric-literal-move) | nonnumeric-literal-move | warning | MOVE of an alphanumeric literal that is not a number to a numeric item |
| [PLB-C080](#plb-c080-initialize-loses-value) | initialize-loses-value | warning | INITIALIZE replaces the VALUE clauses of items it clears |
| [PLB-C081](#plb-c081-varying-wrong-direction) | varying-wrong-direction | warning | PERFORM VARYING steps away from its UNTIL condition |
| [PLB-C082](#plb-c082-pointer-below-one) | pointer-below-one | warning | STRING or UNSTRING POINTER set below 1 just before it |
| [PLB-C083](#plb-c083-close-in-loop) | close-in-loop | warning | CLOSE on every pass of a loop that never opens the file again |
| [PLB-C084](#plb-c084-file-status-unknown) | file-status-unknown | warning | FILE STATUS item compared with a code no I/O statement returns |
| [PLB-C085](#plb-c085-zeros-into-packed) | zeros-into-packed | warning | MOVE ZEROS to a group puts the character 0 in its packed items |
| [PLB-C086](#plb-c086-read-loop-end-only) | read-loop-end-only | warning | READ loop ends only at end of file, and loops for ever on errors |
| [PLB-C087](#plb-c087-when-covered) | when-covered | warning | WHEN of an EVALUATE whose values an earlier WHEN range takes |
| [PLB-C088](#plb-c088-accept-truncation) | accept-truncation | warning | ACCEPT of the date or time into a numeric item with too few digits |
| [PLB-C089](#plb-c089-loop-never-runs) | loop-never-runs | warning | PERFORM UNTIL, VARYING, or TIMES loop that runs no times |
| [PLB-C090](#plb-c090-condition-never-true) | condition-never-true | warning | Condition name tested whose item is never given one of its values |
| [PLB-C091](#plb-c091-varying-counter-repeated) | varying-counter-repeated | warning | AFTER phrase of PERFORM VARYING names a counter already stepped |
| [PLB-C092](#plb-c092-swap-lost) | swap-lost | warning | MOVE of an item to another and straight back, as a swap |
| [PLB-C093](#plb-c093-pointer-too-small) | pointer-too-small | warning | STRING or UNSTRING POINTER too small for the positions it counts |
| [PLB-C094](#plb-c094-open-after-lock) | open-after-lock | error | OPEN of a file closed WITH LOCK, which fails with status 38 |
| [PLB-C095](#plb-c095-rewrite-without-read) | rewrite-without-read | error | Sequential REWRITE or DELETE that does not follow a READ |
| [PLB-C096](#plb-c096-converting-repeated) | converting-repeated | warning | INSPECT CONVERTING string with a character twice, mapped apart |
| [PLB-C097](#plb-c097-sort-file-open) | sort-file-open | error | SORT or MERGE USING or GIVING a file the program has open |
| [PLB-C098](#plb-c098-group-value-into-packed) | group-value-into-packed | warning | Group VALUE puts characters in its packed-decimal or binary items |
| [PLB-C099](#plb-c099-value-overridden) | value-overridden | warning | VALUE of an item in a group that has a VALUE, which is ignored |
| [PLB-C100](#plb-c100-table-keys-unsorted) | table-keys-unsorted | warning | SEARCH ALL table whose VALUE keys are out of their KEY order |
| [PLB-C101](#plb-c101-string-numeric-sender) | string-numeric-sender | warning | STRING sends a number with decimal places or a sign as stored |
| [PLB-C102](#plb-c102-nested-if-decided) | nested-if-decided | warning | IF first in a THEN branch or PERFORM body whose test is already decided |
| [PLB-C103](#plb-c103-chain-exhausted) | chain-exhausted | warning | IF, ELSE, WHEN, or WHEN OTHER that the tests before it leave no value for |
| [PLB-C104](#plb-c104-count-too-small) | count-too-small | warning | INSPECT TALLYING or UNSTRING COUNT IN item too small for the count |
| [PLB-C105](#plb-c105-string-edited-leading-space) | string-edited-leading-space | warning | STRING DELIMITED BY SPACE sends an edited item that can start blank |
| [PLB-C106](#plb-c106-unstring-space-not-all) | unstring-space-not-all | warning | UNSTRING into several items DELIMITED BY SPACE without ALL |
| [PLB-C107](#plb-c107-times-count-changed) | times-count-changed | warning | Statement in a PERFORM TIMES loop changes its count, read only once |
| [PLB-C108](#plb-c108-number-compared-to-text) | number-compared-to-text | warning | Numeric item compared with digits in quotes of another length |
| [PLB-C109](#plb-c109-pointer-past-end) | pointer-past-end | warning | STRING or UNSTRING POINTER set past the end of its item just before |
| [PLB-C110](#plb-c110-file-dd-shared) | file-dd-shared | warning | Two files of a program, one of them written, assigned to one DD |
| [PLB-I001](#plb-i001-pcb-dbd-unknown) | pcb-dbd-unknown | error | PCB names a database no DBD of the run defines |
| [PLB-I002](#plb-i002-senseg-not-in-dbd) | senseg-not-in-dbd | error | Sensitive segment is not in its database as written |
| [PLB-I003](#plb-i003-segment-not-sensitive) | segment-not-sensitive | error | DL/I call names a segment the program's PSB is not sensitive to |
| [PLB-I004](#plb-i004-procopt-forbids-call) | procopt-forbids-call | error | DL/I call that no PCB of the segment allows |
| [PLB-I005](#plb-i005-dli-status-not-checked) | dli-status-not-checked | warning | Status code of a DL/I call is not tested |
| [PLB-J001](#plb-j001-dd-missing) | dd-missing | error | A file the step's programs open has no DD in the step |
| [PLB-J002](#plb-j002-dd-unused) | dd-unused | note | DD is not a file of the step's programs |
| [PLB-J003](#plb-j003-program-not-in-run) | program-not-in-run | note, off | Step runs a program that is not among those checked |
| [PLB-J004](#plb-j004-dd-cannot-be-read) | dd-cannot-be-read | error | A file the program only reads has a DD that gives it no data |
| [PLB-J005](#plb-j005-temp-not-created) | temp-not-created | error | Temporary data set read before any step creates it |
| [PLB-J006](#plb-j006-lrecl-mismatch) | lrecl-mismatch | error | DD record length differs from the program's records |
| [PLB-J007](#plb-j007-dataset-created-twice) | dataset-created-twice | error | Data set created and cataloged again without being deleted |
| [PLB-J008](#plb-j008-cond-step-unknown) | cond-step-unknown | warning | COND or IF tests a step that does not run before it |
| [PLB-J009](#plb-j009-referback-unresolved) | referback-unresolved | error | Backward reference names a step or DD not before it |
| [PLB-J010](#plb-j010-dsn-invalid) | dsn-invalid | error | DSN= names a data set name that z/OS does not accept |
| [PLB-J011](#plb-j011-dd-name-repeated) | dd-name-repeated | warning | Step has the same DD name twice; the second is never used |
| [PLB-J012](#plb-j012-read-after-delete) | read-after-delete | error | Step reads a data set that an earlier step deleted |
| [PLB-J013](#plb-j013-shr-for-output) | shr-for-output | warning | Step writes a sequential data set its DD shares with DISP=SHR |
| [PLB-J014](#plb-j014-output-deleted) | output-deleted | warning | Step writes a data set that its DD deletes when the step ends |
| [PLB-J015](#plb-j015-step-name-repeated) | step-name-repeated | warning | Two steps of a job or procedure have the same name |
| [PLB-J016](#plb-j016-utility-dd-missing) | utility-dd-missing | error | Step runs IEBGENER, IDCAMS, or IKJEFT01 without a DD it needs |
| [PLB-J017](#plb-j017-blksize-invalid) | blksize-invalid | error | DD BLKSIZE does not fit its RECFM and LRECL |
| [PLB-J018](#plb-j018-gdg-generation-not-created) | gdg-generation-not-created | error | Step reads generation (+1) that no earlier step of the job creates |
| [PLB-J019](#plb-j019-parm-too-long) | parm-too-long | error | EXEC PARM passes more than the 100 characters z/OS takes |
| [PLB-J020](#plb-j020-jcl-name-invalid) | jcl-name-invalid | error | JCL statement name is not 1 to 8 letters, digits, or $ # @ |
| [PLB-K001](#plb-k001-cics-resource-undefined) | cics-resource-undefined | error | EXEC CICS names a resource the CICS definitions do not define |
| [PLB-K002](#plb-k002-read-update-not-released) | read-update-not-released | warning | CICS READ UPDATE of a file the program never rewrites or unlocks |
| [PLB-K003](#plb-k003-commarea-without-length) | commarea-without-length | warning | DFHCOMMAREA is used but EIBCALEN is never tested |
| [PLB-K004](#plb-k004-commarea-length-too-long) | commarea-length-too-long | warning | CICS command passes more bytes than its COMMAREA item has |
| [PLB-K005](#plb-k005-batch-io-in-cics) | batch-io-in-cics | error | COBOL file statement or ACCEPT in a CICS program |
| [PLB-K006](#plb-k006-return-transid-without-commarea) | return-transid-without-commarea | warning | RETURN TRANSID passes no COMMAREA to a program that receives one |
| [PLB-K007](#plb-k007-commarea-too-short) | commarea-too-short | warning | XCTL or LINK passes less COMMAREA than the program's DFHCOMMAREA |
| [PLB-K008](#plb-k008-cics-name-too-long) | cics-name-too-long | error | EXEC CICS names a transaction, program, file, or map too long |
| [PLB-K009](#plb-k009-browse-not-active) | browse-not-active | error | CICS browse command with no browse of the file active, or two |
| [PLB-M001](#plb-m001-go-to) | go-to | note | GO TO statement |
| [PLB-M002](#plb-m002-alter) | alter | warning | ALTER statement (obsolete) |
| [PLB-M003](#plb-m003-unused-data-item) | unused-data-item | warning | Data item is never referenced |
| [PLB-M004](#plb-m004-alnum-narrowing) | alnum-narrowing | note, off | MOVE from a larger alphanumeric item to a smaller one |
| [PLB-M005](#plb-m005-set-never-read) | set-never-read | note | Data item is given values but never read |
| [PLB-M006](#plb-m006-dynamic-call) | dynamic-call | note, off | CALL of a program named by a data item |
| [PLB-M007](#plb-m007-detail-never-generated) | detail-never-generated | note | Report detail group is never generated |
| [PLB-M008](#plb-m008-file-not-closed) | file-not-closed | note | File is opened but never closed |
| [PLB-M009](#plb-m009-complex-paragraph) | complex-paragraph | note, off | Paragraph or section is more complex than the limit |
| [PLB-M010](#plb-m010-long-paragraph) | long-paragraph | note, off | Paragraph or section has more statements than the limit |
| [PLB-M011](#plb-m011-evaluate-without-other) | evaluate-without-other | note, off | EVALUATE has no WHEN OTHER |
| [PLB-M012](#plb-m012-deep-nesting) | deep-nesting | note, off | Statements are nested deeper than the limit |
| [PLB-M013](#plb-m013-unused-copybook) | unused-copybook | note | Copybook declares data the program never uses |
| [PLB-M014](#plb-m014-sql-select-star) | sql-select-star | note | Embedded SQL selects every column with SELECT * |
| [PLB-M015](#plb-m015-packed-even-digits) | packed-even-digits | note, off | Packed-decimal item has an even number of digits |
| [PLB-M016](#plb-m016-signed-to-alphanumeric) | signed-to-alphanumeric | note, off | MOVE of a signed integer to an alphanumeric item |
| [PLB-M017](#plb-m017-two-digit-year) | two-digit-year | note | ACCEPT FROM DATE or DAY gives a two-digit year |
| [PLB-M018](#plb-m018-signed-to-unsigned) | signed-to-unsigned | note, off | MOVE of a signed number to an unsigned one drops its sign |
| [PLB-M019](#plb-m019-commented-out-code) | commented-out-code | note, off | Comment lines that are COBOL statements |
| [PLB-M020](#plb-m020-constant-condition) | constant-condition | note | Condition compares two constants |
| [PLB-M021](#plb-m021-empty-branch-statement) | empty-branch-statement | note | IF or EVALUATE whose every branch is CONTINUE or empty |
| [PLB-M022](#plb-m022-mixed-and-or) | mixed-and-or | note | Condition joins with AND and OR without parentheses |
| [PLB-P001](#plb-p001-vendor-routine) | vendor-routine | note, off | CALL of a compiler library routine |
| [PLB-P002](#plb-p002-hard-coded-path) | hard-coded-path | warning | File is assigned to a path on one machine |
| [PLB-Q001](#plb-q001-sql-table-undeclared) | sql-table-undeclared | note | Embedded SQL uses a table the program does not declare |
| [PLB-Q002](#plb-q002-cursor-not-closed) | cursor-not-closed | warning | SQL cursor is opened but never closed |
| [PLB-Q003](#plb-q003-cursor-not-opened) | cursor-not-opened | error | SQL cursor is fetched or closed but never opened |
| [PLB-Q004](#plb-q004-sql-no-where) | sql-no-where | warning | SQL UPDATE or DELETE without WHERE changes every row |
| [PLB-Q005](#plb-q005-into-count-mismatch) | into-count-mismatch | warning | INTO list and select list have different numbers of items |
| [PLB-Q006](#plb-q006-host-variable-too-small) | host-variable-too-small | warning | FETCH or SELECT INTO a host variable too small for the column |
| [PLB-Q007](#plb-q007-host-variable-too-large) | host-variable-too-large | warning | INSERT or UPDATE from a host variable the column cannot hold |
| [PLB-Q008](#plb-q008-null-without-indicator) | null-without-indicator | warning | Column that can be NULL fetched without an indicator variable |
| [PLB-Q009](#plb-q009-update-of-read-only-cursor) | update-of-read-only-cursor | warning | UPDATE or DELETE WHERE CURRENT OF a cursor without FOR UPDATE |
| [PLB-Q010](#plb-q010-cursor-undeclared) | cursor-undeclared | error | SQL cursor is opened, fetched, or closed but never declared |
| [PLB-Q011](#plb-q011-cursor-opened-in-loop) | cursor-opened-in-loop | error | SQL cursor opened on every pass of a loop that never closes it |
| [PLB-Q012](#plb-q012-fetch-after-commit) | fetch-after-commit | error | Loop fetches from a cursor and commits, which closes the cursor |
| [PLB-Q013](#plb-q013-select-into-no-where) | select-into-no-where | warning | SELECT INTO without WHERE takes every row of the table |
| [PLB-Q015](#plb-q015-insert-count-mismatch) | insert-count-mismatch | error | INSERT names more or fewer columns than it gives values |
| [PLB-Q016](#plb-q016-cursor-open-twice) | cursor-open-twice | error | SQL cursor opened again with no CLOSE between |
| [PLB-Q017](#plb-q017-fetch-after-close) | fetch-after-close | error | FETCH or CLOSE of an SQL cursor after its CLOSE, with no OPEN |
| [PLB-Q018](#plb-q018-null-compared) | null-compared | error | SQL condition compares with NULL, which is never true |
| [PLB-Q019](#plb-q019-between-reversed) | between-reversed | warning | SQL BETWEEN whose first number is above its second |
| [PLB-Q014](#plb-q014-fetch-loop-end-only) | fetch-loop-end-only | warning | FETCH loop ends only on SQLCODE 100, and loops for ever on errors |
| [PLB-S001](#plb-s001-dynamic-sql) | dynamic-sql | note | SQL text is built at run time |
| [PLB-S002](#plb-s002-hard-coded-credential) | hard-coded-credential | warning | Credential is written into the program |
| [PLB-S003](#plb-s003-sensitive-data-displayed) | sensitive-data-displayed | warning | DISPLAY writes a credential or personal data |
| [PLB-S004](#plb-s004-shell-command) | shell-command | note | Shell command is taken from a data item |

Rules marked *off* run only when enabled with `--enable` (or `enable`
in `plumbline.conf`). Rules that measure something have a limit, which
`limit RULE N` in `plumbline.conf` changes.

Categories: **C** correctness, **M** maintainability, **P** portability,
**S** security.

## Suppressing findings

A comment containing `plumbline: ignore` suppresses findings on its own
line, or, when the comment is on a line by itself, on the line after it:

```cobol
    GO TO DONE.                   *> plumbline: ignore go-to
*> plumbline: ignore PLB-C001
OLD-ENTRY-POINT.
    DISPLAY "KEPT FOR REFERENCE".
```

After `ignore`, list rule ids or names separated by spaces or commas.
With none, every rule is suppressed for that line. A reason can follow
after `--`, and it is good practice to give one:

```cobol
*> plumbline: ignore move-truncation -- level numbers are at most 88
    MOVE ND-NUM TO SY-LEVEL
```

Case does not matter.
A suppression names the rules it silences, so the reason for it stays
reviewable.

## PLB-A001 unused-program

A program of the run that nothing in the run reaches:

```
program CBTRN01C is not called, run by a job step, or started by a transaction of the run
```

A program is reached when another program of the run calls it (`CALL`,
or `EXEC CICS XCTL`, `LINK`, or `LOAD` with a constant name), a JCL step
runs it (also as the program IMS's `DFSRRC00` or a DB2 `RUN PROGRAM`
starts), a CICS transaction definition names it as its program, or
another program names it in a literal, as menus do that keep the
programs they start in a table. The rule runs only when the run says
how programs start: with JCL or CICS resource definitions among its
inputs. Give the run all of the application's programs, jobs, and
definitions, or the programs started from the rest are reported.


## PLB-A002 record-length-conflict

Two programs whose files are the same data set, through the DDs of the
steps that run them, but whose records for it have different lengths:

```
//EXTRACT  EXEC PGM=ACCTEXT       FD ACCT-OUT: 01 record of 300 bytes
//EXTOUT   DD DSN=PROD.ACCT.EXTRACT,DISP=(NEW,CATLG,DELETE)
//REPORT   EXEC PGM=ACCTRPT       FD ACCT-IN: 01 record of 350 bytes
//EXTIN    DD DSN=PROD.ACCT.EXTRACT,DISP=SHR    <- reported
```

One of them was compiled with an old copy of the layout. The reader's
`OPEN` fails (file status 39), or, where the system does not check, it
reads each record shifted against its fields. The two programs can be
in different jobs: every job and program of the run counts.

The first use of a data set in the run, usually the step that creates
it, sets its length, and each use that differs is reported once, at its
DD. Data sets are compared by name without a generation
(`PAY.HISTORY(+1)` is `PAY.HISTORY`), temporary ones (`&&NAME`) only
within their job. Only files of fixed length count: not those whose
records differ in length, vary (`RECORD VARYING`, `OCCURS DEPENDING ON`),
or are read through a DD with `RECFM=V` or `U`, nor sort files.
## PLB-B001 map-fields-overlap

The B rules check CICS BMS maps, given to `check` as `*.bms` files (see
[BMS](bms.md)).

Two fields of a map that share screen positions:

```
ERRMSG  DFHMDF POS=(23,1),LENGTH=80
FKEYS   DFHMDF POS=(24,1),LENGTH=75
```

A field takes its attribute byte, at `POS`, and `LENGTH` bytes after
it, so `ERRMSG` takes 81 positions and its last byte is the attribute
byte of `FKEYS`. On the screen one field overwrites the other: text is
cut short, or an attribute (protection, color) changes in the middle of
a field. Two fields at the same `POS`, often a stopper field
(`LENGTH=0`) and a label, overlap too. A field with `OCCURS=n` takes its
positions `n` times. Each field is reported once, with the first field
before it in the source that it overlaps.

## PLB-B002 field-outside-map

A field that ends past the last position of its map, or starts in a
column the map does not have:

```
SMALL   DFHMDI SIZE=(5,40)
WIDE    DFHMDF POS=(5,10),LENGTH=40
```

A field may run on from one line into the next, but not past the end
of the map. Maps without `SIZE` take the terminal's size, which the
source does not give, and are not checked.

## PLB-B003 map-not-in-mapset

An `EXEC CICS SEND MAP` or `RECEIVE MAP` that names a map its mapset
does not define, when the mapset is among the BMS sources of the run:

```cobol
    EXEC CICS SEND MAP(HELP-MAP) MAPSET('SCRSET') END-EXEC
```

The command fails with `MAPFAIL` or `INVMPSZ` when it runs. The map and
mapset names are taken from literals, and from data items whose `VALUE`
is a literal and that no statement changes (the common
`LIT-THISMAP` constants). A command without `MAPSET` uses the mapset
of the map's own name. Names set at run time, and mapsets that are not
among the inputs, are not checked.

## PLB-B004 symbolic-map-stale

A program's symbolic map that does not match the BMS map of the run it
was generated from. For map `M`, BMS generates the record `MI` (and
`MO` redefining it), with four items for each named field `F`: `FL`,
the length typed in; `FF` and `FA`, flag and attribute; and `FI`, the
data. The rule reports:

- a field of the map with no `FI` item in the record;
- an `FI` item whose length is not the field's `LENGTH`;
- an `FI` item with an `FL` item beside it, for a field the map does
  not have.

```
CUSTNMI has 25 characters, but field CUSTNM of map SCRMAP has LENGTH=30
```

Each means the copybook was generated from another version of the map.
`RECEIVE MAP` and `SEND MAP` then move the program's data to other
places than the screen's fields: values are cut short, or land in the
next field. Assemble the map again and compile the programs that copy
it. The findings are in the copybook, once for each program that
copies it.

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
`CONTINUE`, which does nothing and lets control reach the terminator;
in an editor, the language server offers a quick fix that makes the
change (see [Editors](editors.md)).

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

## PLB-C008 move-truncation

A `MOVE` whose receiver cannot hold what is moved:

```cobol
01  SHORT-TEXT          PIC X(5).
01  SMALL-NUM           PIC 9(3).
01  BIG-NUM             PIC S9(7)V99.
    MOVE "TOO LONG FOR IT" TO SHORT-TEXT   *> 15 characters into 5
    MOVE 12345 TO SMALL-NUM                *> 5 integer digits into 3
    MOVE BIG-NUM TO SMALL-NUM              *> 7 integer digits into 3
```

A literal that is too long loses its rightmost characters. A number
with more integer digits than its receiver loses its high-order digits,
which silently changes the value: `MOVE 12345 TO SMALL-NUM` stores 345.
Leading zeros of a literal do not count. A numeric literal with more
decimal places than its receiver loses its low-order digits:
`MOVE 1.255 TO BIG-NUM` stores 1.25. Trailing zeros do not count, and
data items are not checked for decimal places, since dropping those of
a computed value is often what is meant. A numeric literal below zero
loses its sign in a receiver without one: `MOVE -5 TO SMALL-NUM`
stores 5 (a signed item moved to an unsigned one is the opt-in
[PLB-M018](#plb-m018-signed-to-unsigned)).

Sizes come from the symbol table. Reference-modified operands, `MOVE
CORRESPONDING`, `ALL` literals, figurative constants, function results,
and `ANY LENGTH` parameters are not checked, because their sizes are not
known statically. Moving a larger alphanumeric item into a smaller one is
the separate, opt-in rule [PLB-M004](#plb-m004-alnum-narrowing).

When a narrowing is safe because of something the program guarantees,
suppress it and say why.

## PLB-C009 undefined-name

A name in the procedure division that is not a data item of the program
(or a `GLOBAL` item of a program containing it), a paragraph or section,
or another declared name: a file, a mnemonic name from `SPECIAL-NAMES`,
an alphabet or class, or an index from `INDEXED BY`. Device names such
as `CONSOLE` and `SYSOUT` are accepted without declaration, as compilers
do.

A qualified reference that matches no item is reported with its
qualifiers, as in `KEY-FIELD OF NO-SUCH-GROUP is not declared`.

Undefined names usually mean a typing mistake or a missing copybook. If
a `COPY` failed (see the `PP001` diagnostic), fix that first. Until
then, in a file with a copybook that was not found, each undeclared name
is reported once, at its first reference, with the copybook that may
declare it, rather than at every reference:

```text
mqput.cbl:12:22: error: MQCC-OK is not declared; copybook CMQV, which was not found, may declare it [PLB-C009]
```

## PLB-C010 ambiguous-name

A name that matches more than one data item, where the reference does
not say which:

```cobol
01  A-REC.
    05  KEY-FIELD       PIC X(4).
01  B-REC.
    05  KEY-FIELD       PIC X(4).
    MOVE KEY-FIELD TO ...          *> reported
    MOVE KEY-FIELD OF B-REC TO ... *> fine
```

Compilers reject such references. Qualify the name with `IN` or `OF`.

## How data-flow rules see data

PLB-C011, PLB-C012, and PLB-M005 look at what each statement does with
the items it names. An operand is *read* (`MOVE A TO ...`, conditions,
`DISPLAY`), *set* (`MOVE ... TO B`, `ACCEPT`, `READ ... INTO`), or both
(`ADD 1 TO C`, `STRING ... POINTER P`). `plumbline dump refs` shows the
role of every reference. Plumbline does not claim to know what some
operands do, such as `CALL ... USING` items passed by reference, which
the called program may read or set. Such operands count as both. The
operand of `LENGTH OF` counts as neither, because only its size is used.

An access counts for every item whose storage it overlaps. Setting a
group sets its members, setting a member partly sets its group, and
reading a `REDEFINES` view reads the storage it redefines. A condition
name (level 88) stands for its conditional variable.

Only working-storage and local-storage items are checked. Items in the
linkage and file sections get their values from callers and files, and
`EXTERNAL`, `GLOBAL`, and `BASED` items get theirs from other programs
or addresses. A `VALUE` clause gives an initial value, and items named in
the environment division (such as `FILE STATUS` items) may be set by the
runtime.

## PLB-C011 read-never-set

An item that is read, while nothing in the program sets it or any
storage it shares, and it has no `VALUE`:

```cobol
01  TOTAL           PIC 9(5).
    DISPLAY TOTAL                  *> reported: nothing sets TOTAL
```

Its value is whatever the storage happens to hold, which depends on the
compiler and its options.

## PLB-C012 use-before-set

A read that no path through the program reaches with a value in the
item:

```cobol
01  TOTAL           PIC 9(5).
    ADD PRICE TO TOTAL             *> reported: TOTAL has no value yet
    ...
    MOVE 0 TO TOTAL
```

The analysis follows the procedure graph: fall-through, `PERFORM`
(including what the performed range may set), and `GO TO`. It reports a
read only when *every* path to it passes no statement that sets the item.
If any path sets the item first, the read is not reported. Within one
statement, reads come before sets, so `COMPUTE X = X + 1` reads `X`
first. The exception is `PERFORM VARYING`, which sets its variable before
it tests `UNTIL`.

A looping `PERFORM` (`UNTIL`, `VARYING`, `TIMES`, `FOREVER`) repeats its
body, so anything the loop sets counts as possibly set from its start.
This is what makes the usual "remember the previous record" loop
correct, but it also means a read before a set on a loop's first
iteration is not reported. Code after a `PERFORM` whose target
Plumbline cannot resolve, and declaratives, are assumed to have
everything set.

Items that PLB-C011 reports are not reported again here. Programs with
more than 4096 paragraphs and sections, and files with more than 512
items to check, are skipped.

Many compilers fill working storage with spaces or zeros by default, so
such code may happen to work. Give the item a `VALUE` or set it
explicitly, and the program no longer depends on compiler options.

## How call rules see programs

PLB-C013, PLB-C014, and PLB-C015 check each `CALL "NAME"` against the
program it calls. That program has to be in the same run: give
`plumbline check` the calling and the called programs together, in one
file or several. Calls of programs outside the run, such as runtime
library routines, are not checked. `plumbline dump calls` shows how
each call was resolved.

## PLB-C013 call-argument-count

A `CALL` that passes more or fewer arguments than the called program's
`PROCEDURE DIVISION USING` (or `ENTRY ... USING`) has parameters:

```cobol
    CALL "PRICING" USING ORDER-ID        *> reported
    ...
PROGRAM-ID. PRICING.
    PROCEDURE DIVISION USING ORDER-KEY ORDER-AMOUNT.
```

The parameters left without an argument have no storage behind them,
and using one is undefined. Pass `OMITTED` for an argument the program
is written to do without; it counts as an argument.

## PLB-C014 call-argument-mismatch

An argument that does not fit the parameter it is passed to:

- passed `BY VALUE` to a parameter the program takes by reference, or
  `BY REFERENCE` or `BY CONTENT` to one it takes `BY VALUE`;
- passed by reference or content while being smaller than its
  parameter.

```cobol
01  SHORT-ID        PIC X(4).
    CALL "PRICING" USING SHORT-ID ORDER-TOTAL   *> reported
    ...
PROGRAM-ID. PRICING.
    LINKAGE SECTION.
    01  ORDER-KEY       PIC X(8).
```

The called program reads and writes all 8 bytes of `ORDER-KEY`, and 4 of
them belong to whatever follows `SHORT-ID`. Literals count by their
length, so `CALL "PRICING" USING "A12" ...` is reported too. A larger
argument is not reported, because programs often pass a record to a
routine that uses only its start. Sizes Plumbline does not know, such
as `ANY LENGTH` parameters and reference-modified arguments, are not
compared.

## PLB-C015 recursive-call

A program that can be called while it is still running, through a chain
of calls that leads back to it, and that is not declared `RECURSIVE`:

```cobol
PROGRAM-ID. PRICING.
    CALL "DISCOUNT" USING ...
PROGRAM-ID. DISCOUNT.
    CALL "PRICING" USING ...    *> reported: PRICING -> DISCOUNT -> PRICING
```

COBOL programs are not reentrant unless they are declared `RECURSIVE`,
and calling an active program is undefined. Many runtimes stop with an
error at that point. The finding shows the chain and is reported at the
call that closes it. Declare the program `PROGRAM-ID. NAME IS RECURSIVE`
if the recursion is intended.

## How report rules see reports

A Report Writer report (an `RD` entry) is produced by `INITIATE`, then
`GENERATE` of its detail groups (or of the report itself, for summary
reporting), and ends with `TERMINATE`. PLB-C016, PLB-C017, and PLB-M007
look at which reports and groups these statements name anywhere in the
program. They do not follow the flow of control, so a report initiated
on one path and generated on another is not reported.

## PLB-C016 report-not-initiated

A `GENERATE` or `TERMINATE` of a report that no `INITIATE` in the
program starts:

```cobol
RD  MONTHLY-REPORT.
01  MONTH-LINE TYPE DETAIL ...
    GENERATE MONTH-LINE          *> reported: no INITIATE MONTHLY-REPORT
```

Generating or terminating a report that was not initiated is a run-time
error.

## PLB-C017 report-not-terminated

A report that is initiated but that no `TERMINATE` ends:

```cobol
RD  DAILY-REPORT.                *> reported
    INITIATE DAILY-REPORT
    GENERATE ITEM-LINE
    CLOSE PRINT-FILE
```

`TERMINATE` prints the final control footings and report footing, so
without it the last totals are missing from the report.

## How embedded SQL and CICS are read

Inside `EXEC SQL ... END-EXEC`, the host variables (`:NAME`, and
`:RECORD.FIELD` for a field of a record) are references to COBOL data.
`INTO` sets them, as in `SELECT ... INTO` and `FETCH ... INTO`, and so
does `SET :x = ...`. Everywhere else they are read. Inside `EXEC CICS`,
the arguments of options are references. Options that return data set
their argument (`INTO`, `SET`, `RESP`, `RESP2`), options that pass data
read it (`FROM`, `RIDFLD`), and `LENGTH` and `ITEM` do both. Every
option of `ASSIGN`, `INQUIRE`, and `FORMATTIME` returns a value.

`EXEC SQL INCLUDE member` includes the member like `COPY`. The SQLCA
fields (`SQLCODE`, `SQLSTATE`, ...) and the CICS EIB fields (`EIBCALEN`,
`EIBRESP`, ...) are known names. `EXEC CICS RETURN`, `XCTL`, and `ABEND`
end a paragraph like `GOBACK`. The procedures of `EXEC SQL WHENEVER ...
GO TO` and `PERFORM` count as jumped to or performed.

## PLB-C018 sql-not-checked

An SQL statement whose result nothing tests:

```cobol
    EXEC SQL SELECT NAME INTO :CUST-NAME FROM CUSTOMER
             WHERE ID = :CUST-ID END-EXEC          *> reported
    EXEC SQL UPDATE CUSTOMER SET SEEN = 'Y' ... END-EXEC
```

A statement counts as checked when a statement after it in the same
paragraph names `SQLCODE` or `SQLSTATE` before the next SQL statement,
or a paragraph performed from there does, or `WHENEVER SQLERROR` with an
action other than `CONTINUE` is in force. A check that is only reached
by falling into the next paragraph is not seen. `SELECT`, `INSERT`,
`UPDATE`, `DELETE`, `FETCH`, `OPEN`, `PREPARE`, `EXECUTE`, `CALL`,
`MERGE`, and `CONNECT` are checked. `CLOSE`, `COMMIT`, and `ROLLBACK`
are not.

An unchecked `FETCH` loops forever at the end of the data, and an
unchecked `UPDATE` fails silently.

## PLB-C019 cics-response-not-checked

A CICS command whose response is not tested:

```cobol
    EXEC CICS WRITE FILE('LOG') FROM(REC) RIDFLD(KEY)
         RESP(WS-RESP) END-EXEC                   *> reported if WS-RESP
    EXEC CICS RETURN END-EXEC                     *> is not tested first
    EXEC CICS DELETE FILE('TEMP') RIDFLD(KEY) NOHANDLE END-EXEC
                                                  *> reported
```

With `RESP(item)`, the item has to be tested (or `EIBRESP`, or a
paragraph performed in between has to test it) before the next CICS
command. `NOHANDLE` without `RESP` discards errors altogether. A command
with neither abends on an error, which is CICS's safe default, and is
not reported.

## How file rules see files

PLB-C020, PLB-C021, PLB-C022, and PLB-M008 look at each program's files
(`SELECT`), their records (`FD`), and the I/O statements that name them:
`OPEN` and `CLOSE`, `READ`, `START`, and `DELETE` of a file, and `WRITE`
and `REWRITE` of one of its records. A file's open modes are those of
every `OPEN` in the program that names it. The rules do not follow the
flow of control. An `EXTERNAL` file is shared with other programs, so
only PLB-C020 applies to it.

## PLB-C020 file-status-not-checked

An I/O statement on a file that has a `FILE STATUS` item, where nothing
tests the item afterwards:

```cobol
    OPEN OUTPUT REPORT-FILE                  *> reported
    WRITE REPORT-LINE FROM HEADING
```

A statement counts as checked when its own `AT END` or `INVALID KEY`
phrase handles errors, when a `USE AFTER ERROR PROCEDURE` declarative
covers the file (by name or by its open mode), or when the status item
or one of its condition names (level 88) is named after it. That can be
in the same paragraph before the next statement on the file, or in a
paragraph performed from there. `CLOSE` is not checked.

After a failed `OPEN`, every later statement on the file fails too, and
after a failed `WRITE` the record is simply not there.

## PLB-C021 file-not-opened

An I/O statement on a file that no `OPEN` in the program opens:

```cobol
    WRITE AUDIT-LINE FROM CUST-NAME          *> reported
```

The statement fails at run time with status 48 or 49 (or 47 for a
`READ`).

## PLB-C022 open-mode-mismatch

An I/O statement that none of the file's open modes allows:

```cobol
    OPEN INPUT CUST-FILE
    ...
    REWRITE CUST-REC                         *> reported: needs I-O
```

`READ` and `START` need `INPUT` or `I-O`, `WRITE` needs `OUTPUT`,
`EXTEND`, or `I-O`, and `REWRITE` and `DELETE` need `I-O`. A sequential
file opened `I-O` takes `REWRITE` but not `WRITE`: with GnuCOBOL 3.2 the
`WRITE` fails with file status 48, and only `OUTPUT` or `EXTEND` allows
it.

## PLB-C023 subscript-out-of-range

A subscript written as a number that is below 1 or past the table's
OCCURS:

```cobol
01  MONTH-TABLE.
    05  MONTH-NAME  PIC X(9) OCCURS 12 TIMES.
    ...
    MOVE "SMARCH" TO MONTH-NAME (13)                *> reported
    MOVE "NONE" TO MONTH-NAME (0)                   *> reported
    MOVE MONTH-NAME (I + 12) TO OUT-TEXT            *> not checked
```

At run time such a subscript reads or overwrites whatever follows the
table, unless the program was compiled with subscript checking. Each
dimension of a table inside a table is checked against its own OCCURS:
for `GRID-CELL (2, 5)` in a 3 by 4 grid, the 5 is reported. With
`OCCURS ... DEPENDING ON`, the subscript is checked against the maximum.
Only literal subscripts are checked, and only when there is one per
dimension.

## PLB-C024 refmod-out-of-range

A reference modification written with numbers that reaches outside the
item:

```cobol
01  CODE-TEXT  PIC X(8).
    ...
    MOVE CODE-TEXT (5:6) TO OUT-TEXT                *> ends at 10: reported
    MOVE CODE-TEXT (9:) TO OUT-TEXT                 *> starts past the end
    MOVE CODE-TEXT (0:2) TO OUT-TEXT                *> starts at 0
    MOVE CODE-TEXT (I:9) TO OUT-TEXT                *> 9 is too long anywhere
```

Positions count characters, from 1. Items whose characters are not
bytes (national, boolean), numeric items that are not `DISPLAY`, and
tables whose size depends on `OCCURS ... DEPENDING ON` are not checked.

## PLB-C025 stop-run-in-called-program

`STOP RUN` in a program that another program of the run calls, or in a
nested program:

```cobol
PROGRAM-ID. PAYSTEP.                    *> MAIN-RUN calls PAYSTEP
PROCEDURE DIVISION.
    ...
    STOP RUN.                           *> reported
```

`STOP RUN` ends the run unit: the program, its callers, and everything
else that is running. A called program usually means to return to its
caller, which `GOBACK` (or `EXIT PROGRAM`) does. A nested program only
runs when it is called, so it is always checked.

Whether a program is called is taken from the call graph, so the rule
needs the callers in the same run. That keeps it quiet on a main
program that has `PROCEDURE DIVISION USING` to receive a JCL `PARM`:
nothing calls it. Calls through a data item (`CALL WS-NAME`) do not
count.

## PLB-C026 varying-limit-unreachable

A `PERFORM VARYING` whose `UNTIL` condition waits for a value the
counter cannot hold:

```cobol
01  I  PIC 99.
    ...
    PERFORM VARYING I FROM 1 BY 1 UNTIL I > 99      *> reported
        MOVE "A" TO CELL (I)
    END-PERFORM
```

`I` goes from 99 to 00 when it is increased, so it is never greater
than 99, and the loop goes on until something else ends it: a `GO TO`
out of it, `EXIT PERFORM`, or an abend when `CELL (0)` is stored. Give
the counter one more digit, or stop at the last value it holds
(`UNTIL I = 99` with `TEST AFTER`).

The rule checks `UNTIL counter op literal`, with op one of `>`, `>=`,
`=`, `<`, `<=` or their words, on the counter that `VARYING` names:
`UNTIL I < 0` is reported for an unsigned counter too. Only integer
counters stored as decimal digits (`DISPLAY` or `PACKED-DECIMAL`) are
checked. A binary counter can hold more than its picture says when the
compiler does not truncate binary data (IBM `TRUNC(BIN)`, GnuCOBOL
`-fnotrunc`). Conditions with `AND` or `OR` are not checked.

## PLB-C027 divide-by-zero

A division whose divisor is a literal zero:

```cobol
    DIVIDE ZERO INTO TOTAL                  *> reported
    COMPUTE RESULT = TOTAL / 0.00           *> reported
    DIVIDE 0 BY TOTAL GIVING RESULT         *> not reported: 0 is divided
```

Dividing by zero raises the size error condition. Without an `ON SIZE
ERROR` phrase the receiving item is left unchanged, or the program
stops, depending on the compiler and its options, and nothing says
which happened. Such a division is usually a placeholder that was
never filled in, or a constant that was meant to be a data item.

The rule checks the first operand of `DIVIDE ... INTO`, the operand
after `BY` in `DIVIDE ... BY`, and the operand after `/` in any
expression (`COMPUTE`, conditions, subscripts). A divisor is zero when
it is `ZERO`, `ZEROS`, `ZEROES`, or a numeric literal with only zero
digits. A statement with `ON SIZE ERROR` handles the failure and is not
reported; test programs divide by zero this way on purpose. Divisors
that are data items, or constants declared with level 78 or
`CONSTANT`, are not checked.

## PLB-C028 comparison-never-true

A condition that compares a data item with a literal the item cannot
hold, so the comparison is never true:

```cobol
01  AGE      PIC 99.
01  BALANCE  PIC 9(5).
    ...
    IF AGE > 99                             *> reported
    IF BALANCE < 0                          *> reported: BALANCE has no sign
```

The code under such a condition never runs. Often the item was made
smaller, or lost its sign, after the condition was written, and the
check it was meant to make no longer happens.

The rule checks `item op literal` in the conditions of `IF`, `PERFORM
... UNTIL`, and `WHEN` in `EVALUATE` and `SEARCH`, with op one of `>`,
`>=`, `=`, `<`, `<=` or their words. Like
[PLB-C026](#plb-c026-varying-limit-unreachable), it checks integer items
stored as decimal digits (`DISPLAY` or `PACKED-DECIMAL`), and integer
literals. Table elements are checked through their subscripts. It does
not report:

- comparisons with `NOT`, and comparisons that are always true
  (`IF BALANCE >= 0`), which are usually harmless checks;
- an item that is an operand of arithmetic (`IF AGE + 1 > 99`);
- the counter of `PERFORM VARYING`, which PLB-C026 checks;
- a literal on the left (`IF 99 < AGE`), or an abbreviated condition
  without a subject (`IF AGE > 10 AND < 100` checks the first part).

A numeric item that holds invalid data (spaces, after a `MOVE` to its
group) still never compares greater than its picture allows.

An `EVALUATE` whose subject is such an item is checked the same way, for
each `WHEN` that is an integer, or a `THRU` range of integers, alone:

```cobol
    EVALUATE AGE
        WHEN 100                            *> reported
        WHEN 120 THRU 150                   *> reported
        WHEN 90 THRU 150                    *> not reported: 90 to 99
```

A range is reported when it lies wholly above or wholly below the
values the item holds; one whose start is above its end is
[PLB-C074](#plb-c074-condition-range-reversed)'s.

For an alphanumeric item (or alphabetic, or a group of fixed size), the
rule reports an equality with a literal that has more characters than
the item:

```cobol
01  STATE-CODE  PIC X(2).
    ...
    IF STATE-CODE = "TEX"                   *> reported
    EVALUATE STATE-CODE
        WHEN "TEX"                          *> reported
```

The shorter operand is compared as if padded with spaces, so the item
never holds the literal's last characters. Trailing spaces of the
literal do not count, and literals with a prefix (`X"..."`, `N"..."`)
are not checked. In an `EVALUATE`, a `WHEN` value that is one literal
is checked against its subject (each `ALSO` part on its own); a range
(`THRU`) is not.

## PLB-C029 go-to-leaves-perform

A `GO TO` inside a performed range whose target is outside it:

```cobol
    PERFORM COUNT-RECORD
    ...
COUNT-RECORD.
    ADD 1 TO COUNTER
    IF COUNTER > 100
        GO TO SUMMARY                       *> reported
    END-IF.
```

A `PERFORM` returns when control reaches the end of its range. After
this `GO TO` it never does: control runs on from `SUMMARY`, and the
statement after the `PERFORM` is skipped. When the range is performed
again later, its return point may still be set from the first time,
so some compilers then return to the wrong place.

The range is the performed paragraph or section, or `A THRU B`, and
the procedures of `SORT` and `MERGE` count as ranges too. A `GO TO` to
a paragraph inside the range (`GO TO READ-EXIT`) is fine. So is a
`GO TO` to code that ends the run, directly or by falling through
other paragraphs into `STOP RUN`, `GOBACK`, `EXIT PROGRAM`, or the end
of the program: that is how many programs leave on an error. A target
that itself ends with a `GO TO` is reported, even when that `GO TO`
leads to the end of the run. Each `GO TO` is reported once, for the
first `PERFORM` whose range it leaves.

## PLB-C030 value-never-used

A value given to a data item that a later statement of the same
paragraph replaces before anything reads it:

```cobol
    MOVE FUNCTION CURRENT-DATE TO WS-CURDATE-DATA     *> reported
    MOVE CCDA-TITLE01 TO TITLE01O
    MOVE FUNCTION CURRENT-DATE TO WS-CURDATE-DATA
```

The first value is never used. Often the statements were copied and
one of them should name another item; sometimes one is simply left
over.

The rule starts at a `MOVE` or `COMPUTE` and follows the statements
after it, across sentences, to the end of the paragraph. It stops,
keeping the value, at:

- a statement that reads the item, or any storage it shares: the
  groups it is in, its members, and items that redefine them;
- a statement that could read it out of sight or change where control
  goes: `PERFORM`, `CALL`, `GO TO`, I/O, `IF`, `EVALUATE`, and any
  statement with a phrase such as `ON SIZE ERROR`.

The value is reported when a `MOVE` or `COMPUTE` gives the whole item a
new value. `STRING`, `MOVE CORRESPONDING`, and stores to part of the
item do not replace it. Not followed at all:

- clearing an item before filling it: `MOVE SPACES`, `MOVE ZERO`,
  `MOVE LOW-VALUES`, `COMPUTE X = 0`, `INITIALIZE`;
- table elements, condition names, and items named by `DEPENDING ON`,
  which the table or item that depends on them reads;
- programs with `USE FOR DEBUGGING`, whose declaratives run on
  references that the statements do not show.

## PLB-C031 string-overflow

A `STRING` whose operands delimited by size are longer, together,
than the item they go into:

```cobol
05  WS-RETURN-MSG  PIC X(75).
    ...
    STRING 'Account:' WS-CARD-RID-ACCT-ID-X ' not found in'
           ' Cross ref file.  Resp:' ERROR-RESP ' Reas:' ERROR-RESP2
           DELIMITED BY SIZE
        INTO WS-RETURN-MSG                  *> 81 characters: reported
```

An operand `DELIMITED BY SIZE` is sent whole, so this statement always
overflows. `STRING` stops at the end of the receiver, and without `ON
OVERFLOW` nothing tells that the end of the text was lost (here, most
of the reason code).

The rule adds up the operands delimited by size: data items by their
size, literals by their length, figurative constants as one
character. Operands delimited by anything else may send any part of
themselves and are not counted; neither are operands whose size the
source does not show (reference modification, functions, literals
with a prefix such as `X` or `N`). The sum is the least the statement
sends. A `STRING` with `ON OVERFLOW` handles the case and is not
reported, nor is a receiver with reference modification, of variable
size, or of national usage.

## PLB-C032 duplicate-when

A `WHEN` of an `EVALUATE` that tests what an earlier `WHEN` of the same
`EVALUATE` already tests:

```cobol
    EVALUATE TRUE
        WHEN CCARD-AID-PFK07 AND CA-FIRST-PAGE
            ...
        WHEN CCARD-AID-PFK07 AND CA-FIRST-PAGE      *> reported
```

`EVALUATE` runs the first `WHEN` that matches, so the later one never
runs. Usually one of them was meant to test something else. `WHEN`s are
compared by their words and literals, `ALSO` parts included, whatever
the line breaks; a value inside an earlier `THRU` range is
[PLB-C087](#plb-c087-when-covered)'s.

## PLB-C033 self-move

A `MOVE` whose receiver is its sender:

```cobol
    MOVE WS-CICS-RESP2-CD TO WS-CICS-RESP2-CD       *> reported
```

The `MOVE` does nothing; usually another item was meant, here
`WS-CICS-RESP2-CD-D`. The rule compares names that stand alone: a
receiver with qualification, subscripts, or reference modification is
not compared, nor are names inside a receiver's subscripts.

## PLB-C034 linkage-not-addressed

A statement that uses a `LINKAGE SECTION` record (or an item in it) that
nothing gives an address:

```cobol
LINKAGE SECTION.
01  LOST-E.
    05  LOST-E-KEY     PIC X(4).
PROCEDURE DIVISION USING PARM-A.
    DISPLAY LOST-E-KEY                      *> reported
```

A linkage record has no storage of its own. The caller passes it
(`PROCEDURE DIVISION USING`, `ENTRY ... USING`), or the program sets its
address (`SET ADDRESS OF item TO pointer`, `EXEC CICS ... SET(ADDRESS OF
item)`, `ALLOCATE`). Without either, the program reads and writes
wherever the address happens to point, or ends abnormally. A `BASED`
record is in the same case until `ALLOCATE` or `SET ADDRESS OF` gives it
storage. Any other use of `ADDRESS OF item` (passing it to a program
that sets it, testing it against `NULL`) counts as the program handling
the address. Items that
redefine an addressed record share its address. In a program with `EXEC
CICS`, `DFHEIBLK` and `DFHCOMMAREA` count as passed, since CICS passes
them. Constants (level 78) need no address. Each record is reported
once, at its first use.

## PLB-C035 duplicate-paragraph

A paragraph with the name of an earlier paragraph of the same section,
or a section with the name of an earlier section of the program:

```cobol
0000-MAIN-EXIT.
    EXIT
    .
0000-MAIN-EXIT.                             *> reported
    EXIT
    .
```

A `PERFORM` or `GO TO` of the name cannot say which paragraph it means,
and qualifying it with the section does not help, so compilers reject
it: GnuCOBOL says the name "is ambiguous; needs qualification", and it
rejects a repeated section outright. A repeat that nothing names still
compiles, and is code that never runs. Paragraphs
outside any section count as one scope per program. The same paragraph
name in two sections is fine, as each section's paragraphs can use it
unqualified; a reference from elsewhere that does not say which
section it means is a diagnostic of its own (FL002). Names are compared
without regard to case. Each repeat is reported at its name, with the
line of the first.

## PLB-C036 arithmetic-overflow

An `ADD`, `SUBTRACT`, `MULTIPLY`, or `COMPUTE` without `ON SIZE ERROR`
whose receiver has fewer integer digits than one of its operands:

```cobol
01  PA-APPROVED-AUTH-AMT  PIC S9(09)V99 COMP-3.
01  WS-APPROVED-AMT       PIC S9(10)V99.
    ADD WS-APPROVED-AMT TO PA-APPROVED-AUTH-AMT     *> reported
```

When the result does not fit, its high-order digits are dropped and
the statement carries on, so a total silently wraps. `ON SIZE ERROR`
leaves the receiver unchanged and lets the program act; a wider
receiver avoids the question.

The operands are the items and numeric literals before `TO`, `FROM`,
or `BY`, and with `GIVING` the one after them too; for `COMPUTE`, those
of the expression after `=`, whose receivers are before it. Subscripts
do not count, nor does `LENGTH OF` an item, which is its length.
`DIVIDE`, and a `COMPUTE` with `/` or `**` (or a `FUNCTION`), are not
checked, because a quotient is commonly much smaller than its dividend,
nor are the `CORRESPONDING` forms, reference-modified items, or items
of unknown size. With GnuCOBOL 3.2, `COMPUTE WS-SMALL = WS-A + 1` with
`WS-A` 99999 and `WS-SMALL` `PIC 9(3)` stores 000. A `COMP-5` (or
`COMP-X`) receiver holds what its bytes hold, not what its picture
says (a `PIC 9(4) COMP-5` holds 12001, and wraps past 65535), and is
not read.

The rule reads declarations, not values. One case is known without
them: inside an inline `PERFORM VARYING IX ... UNTIL IX > 50` (or `>=`),
`IX` counts as two digits, however it is declared. Elsewhere, a `PIC
9(6)` counter added to a `PIC 9(3)` field is reported even when it
never goes past 50: declare it to fit, or suppress the finding and say
why.

## PLB-C037 search-index-not-set

A serial `SEARCH` whose index nothing sets on the way to it:

```cobol
FIND-FIRST.
    SET CODE-IX TO 1
    SEARCH CODE-ENTRY ...
FIND-AGAIN.
    SEARCH CODE-ENTRY                       *> reported
        AT END MOVE "N" TO FOUND-FLAG
        WHEN CODE-ENTRY(CODE-IX) = WANTED ...
```

A serial `SEARCH` starts at the current value of the table's first
index (or of the index named by `VARYING`, when it is one of the
table's own), not at the first entry. After an earlier search, that is
where the earlier search stopped, so the entries before it are never
compared. The standard leaves an index's first value undefined.
`SEARCH ALL` chooses its own starting point and is not checked.

The index counts as set when the `SEARCH`'s paragraph sets it before
the `SEARCH`, with `SET` or a `PERFORM` that names it (`PERFORM VARYING
CODE-IX ...`), or when a paragraph that leads into this one sets it
anywhere: one that falls into it, goes to it, or performs it. Longer
paths are not followed, so an index set two paragraphs away is
reported; move the `SET` next to the `SEARCH`, where a reader looks
for it.

## PLB-C038 condition-value-unfit

A condition name (level 88) with a value its item cannot hold:

```cobol
01  STATUS-CODE         PIC 9.
    88  DONE            VALUE 10.          *> reported: 2 digits into 1
01  REGION              PIC XX.
    88  NORTH           VALUE "NORTH".     *> reported: 5 characters into 2
01  AMOUNT              PIC 9(3)V9.
    88  CENTS           VALUE 1.25.        *> reported: 2 decimal places into 1
    88  BELOW-ZERO      VALUE -1.          *> reported: the item is unsigned
```

The item never holds the value, so a condition with that one value is
never true, and `SET DONE TO TRUE` stores something else (`0` for
`DONE`). When the condition has other values, only that value never
matches. Trailing spaces of an alphanumeric literal and trailing zeros
of decimal places do not count.

In `VALUE a THRU b` only `a` is checked, since a range that starts
among the item's values still has values it can hold. Figurative
constants and `ALL` literals are not checked.

GnuCOBOL warns about some of these where the condition is used
(`-Wconstant-expression`, `-Wtruncate`); this rule reports each value
at its declaration, used or not, including decimal places and signs.

## PLB-C039 decimal-to-alphanumeric

A `MOVE` of a numeric item with decimal places to an alphanumeric item:

```cobol
01  RATE                PIC 9V999.
01  TEXT-OUT            PIC X(10).
    MOVE RATE TO TEXT-OUT                   *> reported
```

The standard allows only integers to be moved to an alphanumeric item,
and GnuCOBOL rejects this `MOVE` ("invalid MOVE statement") unless the
dialect option `move-noninteger-to-alphanumeric` allows it. Where a
compiler accepts it, the decimal point is not written: `1.250` becomes
`1250`. Move the number to a numeric-edited item (`PIC 9.999`) and that
item to the text.

## PLB-C040 odo-object-too-small

A variable-length table whose count item cannot hold its largest count:

```cobol
01  SMALL-COUNT         PIC 99.
01  ORDERS.
    05  ORDER-LINE      PIC X(20) OCCURS 1 TO 500
                        DEPENDING ON SMALL-COUNT.    *> reported
```

`SMALL-COUNT` never goes past 99, so `ORDERS` never holds more than 99
lines, and moving a count of 150 to it stores 50: the table then looks
shorter than it is, and the lines after the 50th are lost when the
record is written. Declare the count with as many digits as the
table's largest count. The count is the numeric item of that name in
the same program; one with more than nine integer digits is not
checked.

## PLB-C041 write-from-truncation

A `WRITE` or `REWRITE` `FROM` an item longer than the record:

```cobol
FD  OUT-FILE.
01  OUT-REC             PIC X(80).
01  WS-LONG-LINE        PIC X(100).
    WRITE OUT-REC FROM WS-LONG-LINE         *> reported
```

`FROM` moves the item to the record first, as `MOVE` does, so the last
20 bytes never reach the file. The record is usually what is wrong: a
field added to the working-storage layout but not to the file's.

`READ ... INTO` a shorter item is not reported, because reading only
the start of a record, such as the first columns of a control card, is
common and meant. Items whose size changes at run time (`OCCURS
DEPENDING ON`) and reference-modified items are not checked.

## PLB-C042 inspect-count-not-reset

An `INSPECT ... TALLYING` whose count nothing sets before it:

```cobol
2250-EDIT-ARRAY.
    INSPECT WS-EDIT-SELECT-FLAGS
        TALLYING I FOR ALL 'S' ALL 'U'      *> reported
    IF I > +1 ...
```

`TALLYING` adds to its count; it does not start it at zero. A count
that is not set first carries whatever it held: the total of an
earlier `INSPECT`, or, as here, the last value of a loop index. Set it
to zero just before.

The count counts as set when the `INSPECT`'s paragraph stores into it,
or into a group around it, before the `INSPECT` (`MOVE ZERO TO`,
`INITIALIZE`), or when a paragraph that leads into this one (falls into
it, goes to it, or performs it) does so anywhere. `ADD 1 TO count` adds
as `INSPECT` does and does not count, and a `VALUE` clause sets the
count only for the first time the paragraph runs.

## PLB-C043 pointer-not-reset

A `STRING` or `UNSTRING` `WITH POINTER` whose pointer no statement
sets:

```cobol
01  WS-RESP-LENGTH      PIC S9(4) VALUE 1.
...
6000-MAKE-DECISION.
    STRING PA-RL-CARD-NUM ',' ... DELIMITED BY SIZE
        INTO W02-PUT-BUFFER
        WITH POINTER WS-RESP-LENGTH           *> reported
```

The statement starts at the pointer and leaves it past what it handled.
When the paragraph runs again, for the next message of a loop, it
starts where the last one stopped: the text lands after the earlier
reply, or does not fit at all. `VALUE 1` sets the pointer only for the
first run. Set it to 1 just before the statement.

Only a pointer that no statement of the program sets is reported: one
with just a `VALUE` clause, or nothing. A paragraph that appends to a
line through a pointer its callers set (`MOVE 1 TO PTR`, then `PERFORM
APPEND-FIELD` several times) is the usual way to build text, and is
fine.

## PLB-C044 varying-control-changed

A statement inside a `PERFORM VARYING` loop that changes the loop's
control item:

```cobol
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 20
        IF LINE-ENTRY(IX) = SPACES
            ADD 1 TO IX                     *> reported
        END-IF
        ...
    END-PERFORM
```

The loop steps from the changed value, so it skips or repeats entries,
and a change that keeps the control below the limit never ends it. The
control items are those after `VARYING` and `AFTER`; the loop's body is
its inline statements, or for `PERFORM procedure VARYING`, the
procedures it performs (not those they perform in turn). A store into a
group around the control counts.

Moving past items a loop has handled on purpose, as a scanner does when
it reads two tokens at once, is clearer written as `PERFORM UNTIL` with
its own `ADD`; where the `VARYING` form stays, suppress the finding and
say why.

## PLB-C045 alnum-compared-to-number

An alphanumeric item compared with a numeric literal that has fewer
digits than the item has characters:

```cobol
01  WS-IN-TYPE-CD           PIC X(02).
01  WS-IN-TYPE-CD-N REDEFINES WS-IN-TYPE-CD PIC 9(02).
    EVALUATE TRUE
        WHEN WS-IN-TYPE-CD = 0              *> reported
```

The comparison is of characters: the literal `0` stands for the
character "0", and the shorter side is padded with spaces, so the
condition is true only for "0 ", never for "00". Compare the numeric
view (`WS-IN-TYPE-CD-N = 0`), or `ZERO`, which fills the item. A
literal as long as the item (`TYPE-CODE = 12`) compares as written, and
an item with a binary usage (`PIC X COMP-X`) is a number.

A numeric-edited item is reported when compared with any number, or
with `ZERO`: it holds the characters its picture made, so with GnuCOBOL
3.2 a `PIC ZZ9` holding 0 is `"  0"`, and `IF WS-ED = 0` is false, as is
`IF WS-AMOUNT-OUT = 1234.5` for `" 1,234.50"`. Compare the number the
item was edited from, or a literal written as it shows. A picture of
`9` and inserted `0` alone (`PIC 0009999`) shows 0 as zeros and a number
as all its digits, so `ZERO`, or a literal with as many digits as the
item has characters, compares as meant and is not reported.

The same holds for the subject of an `EVALUATE` and the numbers, or
ranges of numbers (`WHEN 1 THRU 99`), of its `WHEN` phrases.

Two items are compared the same way: an alphanumeric item and an
unsigned whole number stored as digits, with `=`. The number compares
as its digits, and the shorter side is padded with spaces; when the
number has more digits than the alphanumeric item has characters, no
digit matches the padding, and with GnuCOBOL 3.2 a `PIC X(3)` holding
`"001"` is never equal to a `PIC 9(5)` holding 1. With fewer digits the
padding is on the number's side, and `"001  "` equals 1 in a `PIC
9(3)`; that is not reported.

## PLB-C046 overlapping-move

A `MOVE` from one item to another that occupies some of the same
storage, through `REDEFINES` or because one contains the other:

```cobol
01  CUSTOMER-REC.
    05  CUST-NAME       PIC X(20).
    05  CUST-CITY       PIC X(20).
01  SHIFTED REDEFINES CUSTOMER-REC.
    05  FILLER          PIC X(5).
    05  SHIFT-NAME      PIC X(20).
    MOVE CUST-NAME TO SHIFT-NAME            *> reported
```

The standard leaves the result of a move between overlapping items
undefined. A compiler may copy left to right, right to left, or through
a temporary, so the same statement can shift the data on one compiler
and smear its first characters across the receiver on another. Move
through a work item of its own. A move of an item to itself is PLB-C033;
subscripted items are not compared, since the subscripts decide whether
they overlap.

## PLB-C047 foreign-index

An index of one table (a name from its `INDEXED BY`) used as the
subscript of another table whose entries have a different length:

```cobol
01  RATE-TABLE.
    05  RATE            PIC 9(3)V99 OCCURS 12 INDEXED BY RATE-IX.
01  NAME-TABLE.
    05  MONTH-NAME      PIC X(9) OCCURS 12 INDEXED BY NAME-IX.
    DISPLAY MONTH-NAME(RATE-IX)             *> reported
```

IBM's compilers keep an index as the byte offset of its entry
(occurrence number minus one, times the entry length), so `RATE-IX` on
its third entry is 10, which in `MONTH-NAME` is the second byte of the
second name. The standard allows an index of another table only when
the entries have the same length. GnuCOBOL keeps the occurrence number,
so the program runs as meant there and not after the move to the
mainframe. Set the table's own index from the other
(`SET NAME-IX TO RATE-IX` converts it), or use a data item as the
subscript.

Each subscript is matched with the table of its dimension, outermost
first. A relative index (`RATE-IX + 1`) counts; subscripts that are
expressions or data items are not checked.

## PLB-C048 sort-procedure-no-record

The `INPUT PROCEDURE` of a `SORT` that never `RELEASE`s a record, or
the `OUTPUT PROCEDURE` of a `SORT` or `MERGE` that never `RETURN`s one:

```cobol
    SORT SORT-FILE ON ASCENDING KEY SORT-KEY
        USING IN-A
        OUTPUT PROCEDURE IS COUNT-ONLY      *> reported
COUNT-ONLY SECTION.
COUNT-START.
    DISPLAY "SORTED".
```

An input procedure that releases nothing gives the sort an empty file,
and the program goes on as if it had sorted its input; an output
procedure that returns nothing drops every sorted record. Either is
usually a procedure that was renamed, or a `RELEASE` or `RETURN` moved
into a paragraph the procedure no longer reaches.

The procedure is the range it names, with its `THRU` end, and every
paragraph and section that range performs or goes to, and so on. A
procedure that reaches a `GO TO` or `PERFORM` whose target could not be
resolved is not reported.

## PLB-C049 loop-condition-unchanged

A `PERFORM ... UNTIL` whose loop changes nothing its condition reads:

```cobol
    PERFORM STEP UNTIL ALL-DONE             *> reported
...
STEP.
    MOVE "Y" TO WS-OTHER.
```

Unless the condition holds when the loop starts, the loop runs until
the job is cancelled. It is usually a flag set under another name, or a
paragraph that used to set it and no longer does.

The loop is the inline body, or the range it performs, with every
paragraph and section reached from there by `PERFORM` or `GO TO`. The
condition's items are the data items it names; a condition name stands
for its item. An item changes when a statement of the loop stores into
it or into an item that shares its storage (its group, or an item that
redefines it).

The rule stays quiet when the loop can end, or change the condition,
in ways the data references do not show: a `GO TO`, `EXIT PERFORM`,
`STOP RUN`, `GOBACK`, `EXIT PROGRAM`, `CALL`, `ALTER`, `EXEC`, or I/O
statement in the loop; a `FUNCTION`, an index name, or an unresolved
name in the condition; a condition item in the `LINKAGE SECTION`; or a
procedure the analysis could not resolve. `VARYING` loops are left to
PLB-C026 and PLB-C044.

## PLB-C050 record-read-at-end

The `AT END` phrase of a `READ`, or of a `RETURN` from a sort file,
reads the file's record:

```cobol
    READ IN-FILE
        AT END
            DISPLAY "LAST " IN-KEY          *> reported
```

When a read finds the end of the file, the record area holds nothing
the standard defines: on some systems it still holds the last record,
on others whatever the buffer held, and after a read of an empty file
it was never filled. Code that works on one compiler shows a different
last key, or garbage, on another. Keep what the end needs in
`WORKING-STORAGE` as each record is read (`READ ... INTO` does that) and
read the copy.

Stores into the record are fine. Each item is reported once per phrase,
and condition names count as reads of their item. Statements the phrase
reaches through `PERFORM` are not followed.

## PLB-C051 duplicate-if-condition

An `IF` of an `ELSE IF` chain that tests what an earlier `IF` of the
chain tests:

```cobol
    IF WS-CODE = "A"
        DISPLAY "ADD"
    ELSE IF WS-CODE = "C"
        DISPLAY "CHANGE"
    ELSE IF WS-CODE = "A"                   *> reported
        DISPLAY "NEVER"
```

The chain reaches the later `IF` only when the earlier test failed, and
nothing runs in between, so the later branch is dead code. It is
usually a copied test whose value was not changed. This is PLB-C032 for
`IF` chains.

An `IF` belongs to the chain when it is the first statement of the
`ELSE` of the one before; an `IF` after other statements can see other
values and is not compared. Conditions are compared as text, as in
PLB-C032, and those that call a `FUNCTION` are left out.

A test that is one relation of a numeric item with a number (`=`, `>`,
`<`, `>=`, `<=`, their words, and `NOT` of all but `=`) is also read as
the values it accepts. A later `IF` on the same item, written the same
way with the same subscripts, whose values all lie among those of an
earlier one is reported too:

```cobol
    IF WS-AMOUNT > 10
        DISPLAY "OVER 10"
    ELSE IF WS-AMOUNT > 20                  *> reported
        DISPLAY "NEVER"
```

A test is compared with each earlier one alone: in `IF A > 5 ... ELSE
IF A < 8 ... ELSE IF A >= 3` the first two tests between them take
every value, but neither holds all of the third's, and it is not
reported. Items with reference modification are not compared.

## PLB-C052 string-overlap

A `STRING` or `UNSTRING` whose receiving item shares storage with an
item it sends from:

```cobol
    STRING WS-LINE DELIMITED BY SPACE ", DONE" DELIMITED BY SIZE
        INTO WS-LINE                        *> reported
```

The standard leaves the result undefined when a sending and a receiving
item of these statements overlap. Moving character by character, the
append above works; a compiler that clears the receiver first, or
builds the result elsewhere and copies it back, loses the text. Build
the result in another item and move it back, or append with `WITH
POINTER` into the item without sending it.

Senders are the items a `STRING` sends and its delimiters, or the item
an `UNSTRING` splits and its delimiters. Receivers are the `INTO` item
of a `STRING`, or the receivers of an `UNSTRING` with their `DELIMITER
IN` and `COUNT IN` items. `POINTER` and `TALLYING` items, and names in
subscripts, are not compared. Storage is shared through the same name,
a group and its items, or `REDEFINES`, as in PLB-C046.

## PLB-C053 exit-program-in-main

`EXIT PROGRAM` in a program that a job step runs (`EXEC PGM=name`) and
that no program of the run calls:

```cobol
MAIN-LINE.
    PERFORM PROCESS-FILE
    EXIT PROGRAM.                           *> reported
CLOSE-DOWN.
    ...
```

`EXIT PROGRAM` returns to a caller; in a main program, which has none,
it does nothing, and execution goes on with the next statement, into
the paragraphs that follow. `GOBACK` ends a main program and returns
from a called one, so it is right in both.

The rule needs the JCL that runs the program among the inputs. A
program a step runs through another (IMS's `DFSRRC00`, a DB2 `RUN
PROGRAM`) is called by it, and a nested program only runs when called;
neither is reported.

## PLB-C054 go-to-into-perform-range

A `GO TO` from outside a `PERFORM ... THRU` range to a paragraph inside
it, after its first:

```cobol
9200-WRITE.
    PERFORM 9300-CHECK THRU 9300-CHECK-EXIT
    ...
9200-WRITE-EXIT.
    EXIT.
9300-CHECK.
    IF WS-CHANGED = "Y"
        GO TO 9200-WRITE-EXIT               *> reported
    END-IF.
9300-CHECK-EXIT.
    EXIT.
```

Control that arrives by the `GO TO` reaches the end of the range as if
it had been performed. Here the `PERFORM` of `9300-CHECK` is left
unfinished, and the end of `9200-WRITE`'s range returns to its caller;
an unfinished `PERFORM` leaves its return point set, and control comes
back to it unexpectedly when its range end is reached later. Usually
the paragraph meant its own exit (`GO TO 9300-CHECK-EXIT`). This is the
other side of PLB-C029, a `GO TO` that leaves a range.

A `GO TO` that stays within some other `PERFORM` range, as when two
ranges share an exit paragraph, is not reported; each `GO TO` is
reported once.

## PLB-C055 corresponding-no-match

A `MOVE`, `ADD`, or `SUBTRACT CORRESPONDING` whose two groups have no
pair of items that correspond, so that it does nothing:

```cobol
01  IN-REC.
    05  CUST-ID         PIC X(8).
    05  CUST-NAME       PIC X(30).
01  OUT-REC.
    05  CUSTOMER-ID     PIC X(8).
    05  NAME            PIC X(30).
    ...
    MOVE CORRESPONDING IN-REC TO OUT-REC        *> reported
```

Two items correspond when they have the same name and the same
qualifiers up to the two groups. FILLER, condition names, `RENAMES`
and `USAGE INDEX` items do not count, nor do items that have, or are
in an item that has, `REDEFINES` or `OCCURS` below the group. For
`MOVE` one of the two must be elementary; for `ADD` and `SUBTRACT`
both must be elementary and numeric, so a numeric-edited item does
not pair. The compiler accepts such a statement without a word; a
renamed field, or a changed picture, on one side is the usual cause.

## PLB-C056 self-comparison

A relation condition whose two sides are the same data item, written
the same way:

```cobol
    IF WS-OLD-BALANCE NOT = WS-OLD-BALANCE           *> reported
        PERFORM 300-POST-CHANGE
    END-IF
```

The condition never changes: it is always true for `=`, `>=`, and
`<=`, and always false for `<`, `>`, and `NOT =`. A branch then never
runs, or always does, and a loop never ends or never starts. It is
most often a line copied from the one above with one name left as it
was.

The sides must be whole operands (`WS-COUNT + 1 > WS-COUNT` is not
reported) and the same tokens, subscripts and reference modifiers
included (`WS-ENTRY (WS-I) = WS-ENTRY (WS-J)` is not reported). The
`=` of `COMPUTE` stores a value and is not a condition.

## PLB-C057 misleading-indentation

A statement indented as if it were inside the `IF` before it, when a
period has already ended the `IF`:

```cobol
    IF WS-AMOUNT > WS-LIMIT
        MOVE "Y" TO WS-OVER-LIMIT.
        PERFORM 900-WRITE-EXCEPTION                *> reported
```

The period ends every open statement, so the `PERFORM` runs whatever
the condition, though it reads as part of the `IF`. Either the period
is a mistake, the classic one of COBOL before `END-IF`, or the
indentation is. The same holds after `EVALUATE`, `SEARCH`, an inline
`PERFORM`, or any statement with a body, and after an `ELSE`.

The statement reported starts the sentence after the one the `IF` ends,
in the same paragraph, on a later line and further right than the
`IF`. An `IF` without `ELSE` whose body ends with `GO TO`, `GOBACK`,
`STOP RUN`, or `EXIT` is left alone: the code after it runs only when
the condition is false, and indenting it as an "else" is a common style.
Copybook text is not checked.

## PLB-C058 read-not-handled

A `READ` that nothing prepares for the end of the file or a record
that is not there: it has no `AT END` or `INVALID KEY` phrase, the file
has no `FILE STATUS`, and no `USE` declarative covers it.

```cobol
    SELECT TRANS-FILE ASSIGN TO "TRANS".          *> no FILE STATUS
    ...
    READ TRANS-FILE                                *> reported
```

When the file ends, the run stops with an I/O error; GnuCOBOL says
`libcob: error: end of file (status = 10) for file TRANS-FILE`. A
program that reads exactly as many records as it knows the file has
does not reach that point, but the next change to the file may. Add an
`AT END` phrase, or a `FILE STATUS` that the program tests (see
PLB-C020).

## PLB-C059 key-error-not-handled

A `WRITE`, `REWRITE`, `DELETE`, or `START` of an indexed or relative
file with no `INVALID KEY` phrase, where the file has no `FILE STATUS`
and no `USE` declarative covers it:

```cobol
    SELECT CUST-FILE ASSIGN TO "CUSTOMER"
        ORGANIZATION IS INDEXED
        RECORD KEY IS CUST-KEY.
    ...
    WRITE CUST-REC                                 *> reported
```

A duplicate key, or a key that is not in the file, then stops the run
with an I/O error; GnuCOBOL says `libcob: error: record key already
exists (status = 22)`. `DELETE` in sequential access takes no
`INVALID KEY` phrase and is left alone.

## PLB-C060 spaces-into-numeric

`MOVE SPACES` to a group, and then a read of one of its numeric items
before anything gives it a value:

```cobol
01  WS-TOTALS.
    05  WS-COUNT        PIC S9(7) COMP-3.
    05  WS-NAME         PIC X(20).
    ...
    MOVE SPACES TO WS-TOTALS                       *> reported
    ADD 1 TO WS-COUNT
```

A group move copies the spaces byte for byte. In a packed-decimal or
zoned-decimal item they are not a valid number, and the first
arithmetic on it fails on z/OS with a data exception (S0C7); in a
binary item they are a meaningless number. The compiler rejects `MOVE
SPACES` to the numeric item itself, but not to its group. `INITIALIZE`
gives each item a value of its kind.

Clearing a record with spaces and then filling it, or reading into it,
is common and fine, so the statements after the `MOVE` are followed to
the end of the paragraph: one that gives the item (or a group around
it) a value ends the search for it, and a `READ`, `RETURN`, `PERFORM`,
or `CALL`, or a value given to a `RENAMES` item or one under a
`REDEFINES`, ends it for all. A read of a group around a packed or
binary item (`WRITE` of the record) counts too, since it copies the bad
bytes on; a `DISPLAY` item read only with its group, as in a print
line, shows blanks and is left alone. Branches are not told apart. A
group named after `FILE STATUS` in a `SELECT` is left alone: the I/O
statements give it its values.

## PLB-C061 unchecked-numeric-move

Off by default. A `MOVE` of an alphanumeric item, or of a reference
modification, to a numeric item, where nothing in the paragraph tests
the one or the other with the `NUMERIC` class condition:

```cobol
    ACCEPT IN-RECORD
    MOVE IN-AMOUNT-X TO WS-AMOUNT                  *> reported
    ADD WS-AMOUNT TO WS-TOTAL
```

The characters are copied as they are, so spaces or letters in the
input make a numeric item that holds no number: arithmetic on it fails
on z/OS with a data exception (S0C7), or gives a wrong result. Test
`IN-AMOUNT-X IS NUMERIC` before the move, or `WS-AMOUNT IS NUMERIC`
after it, anywhere in the paragraph.

Input checked in another paragraph, and data known to be digits (parts
of `FUNCTION CURRENT-DATE`, keys built from digits), are common, so the
rule is only run on request (`--enable unchecked-numeric-move`): on
CardDemo it notes 53 moves, many of fields checked by a validation
paragraph before.

## PLB-C062 varying-subscript-out-of-range

The counter of a `PERFORM VARYING` loop, used as a subscript in the
loop, takes a value outside the table:

```cobol
01  LINES-TABLE.
    05  LINE-ENTRY      PIC X(10) OCCURS 20.
    ...
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 25
        DISPLAY LINE-ENTRY(IX)                     *> reported
    END-PERFORM
```

`IX` reaches 25, past the 20 entries; `FROM 0` gives a subscript of 0
on the first pass. Without subscript checking (the default of most
compilers), the program reads or overwrites the storage after the table.

The rule works out the counter's values from a `VARYING` or `AFTER`
phrase written with integers: `FROM` a number, `BY` a positive number
(or no `BY`), and `UNTIL` the counter `>`, `>=`, or `=` a number (`=`
with `BY 1` only), with nothing else in the condition. It checks each
subscript in the loop that is the counter, or the counter plus or minus
a number, against the `OCCURS` of its dimension. The counter can be a
data item or an index. The loop is the inline body, or the paragraphs
from the procedure through its `THRU`.

A loop is left alone when it may not run as written: `WITH TEST AFTER`;
a statement in the loop changes the counter (PLB-C044 reports that);
or an `IF`, `EVALUATE`, `PERFORM`, or `SEARCH` in the loop tests the
counter, other than in a subscript or reference modifier, which may
guard the reference.

## PLB-C063 varying-refmod-out-of-range

The counter of a `PERFORM VARYING` loop, as the start or the length of
a reference modifier in the loop, takes a value outside the item:

```cobol
01  WS-NAME             PIC X(20).
    ...
    PERFORM VARYING IX FROM 1 BY 1 UNTIL IX > 30
        IF WS-NAME(IX:1) = SPACE                   *> reported
            ADD 1 TO BLANKS
        END-IF
    END-PERFORM
```

`IX` reaches 30, past the 20 characters of `WS-NAME`. The rule reports
a start below 1 or past the last character, a length below 1, and an
end (start plus length, less one) past the last character, each for
the values of the counter that PLB-C062 works out, from the same forms
of loop. One side of the modifier is the counter, or the counter plus
or minus a number; the other is a number or, for the length, left out.
Items whose size is not their number of characters (binary, packed,
national) and items whose size changes (`OCCURS DEPENDING ON`) are not
checked. Loops are left alone for the same reasons as in PLB-C062.

## PLB-C064 duplicate-condition-value

Two condition names (level 88) of the same item with the same values:

```cobol
01  WS-DELETE-FLAG          PIC X.
    88  DELETE-NOT-REQUESTED  VALUE LOW-VALUES.
    88  DELETE-REQUESTED      VALUE 'Y'.
    88  DELETE-SUCCEEDED      VALUE LOW-VALUES.   *> reported
```

Usually one was copied from the other and its value not changed. Each
is true whenever the other is, and `SET DELETE-SUCCEEDED TO TRUE`
stores what `SET DELETE-NOT-REQUESTED TO TRUE` does: here, a delete
that was never requested tests as one that succeeded.

The values are compared as a set, in any order: trailing spaces of an
alphanumeric literal, leading zeros and trailing decimal zeros of a
number, and the spelling of a figurative constant (`SPACE`, `SPACES`;
`ZERO` and `0` for a numeric item) do not count. A condition whose
values include another's and more, as a `VALID` condition that lists
the values of several others, is not reported, nor is the `WHEN SET TO
FALSE` phrase compared. A pair is reported only when the program's
procedures name one of the two: two condition names that nothing tests
or sets, as two messages with the same text, mislead no statement.

## PLB-C065 open-in-loop

An `OPEN` that runs on every pass of a loop, of a file the loop never
closes:

```cobol
    PERFORM WRITE-REPORT 3 TIMES
    ...
WRITE-REPORT.
    OPEN OUTPUT OUT-FILE                    *> reported
    WRITE OUT-REC.
```

The second pass opens a file that is already open. The `OPEN` fails
with file status 41; without a `FILE STATUS` check the program goes on
with the file as the first pass left it, or stops.

A loop is a `PERFORM` with `UNTIL`, `VARYING`, `FOREVER`, or `TIMES`
(but not `1 TIMES`). The `OPEN` is in its inline body, or in a
procedure of the range it performs, or in a procedure that a `PERFORM`
in its inline body performs on every pass. An `OPEN` under an `IF`,
`EVALUATE`, `SEARCH`, or a conditional phrase (`AT END`, `INVALID
KEY`, ...) inside the loop is not reported, since it may run only once.
Nor is one whose file the loop closes: a `CLOSE` of it among the loop's
statements, or in a procedure they perform, at any depth.

## PLB-C066 identical-branches

An `IF` whose `ELSE` does what its `THEN` does:

```cobol
    IF WS-ACCOUNT-TYPE = "S"
        MOVE SAVINGS-RATE TO WS-RATE
    ELSE
        MOVE SAVINGS-RATE TO WS-RATE          *> reported
    END-IF
```

The condition decides nothing. Usually one branch was copied from the
other and not changed. The branches are compared token by token, after
`COPY` and `REPLACE`: spacing, line breaks, comments, and the case of
words do not count.

## PLB-C067 divisor-not-checked

Off by default. A division by a data item that may be zero, with
nothing to catch it:

```cobol
    DIVIDE WS-TOTAL BY WS-COUNT GIVING WS-AVERAGE     *> reported when enabled
```

When the input was empty, `WS-COUNT` is 0: the statement raises a size
error, which without `ON SIZE ERROR` leaves `WS-AVERAGE` as it was, or
on z/OS can end the program with a decimal-divide exception (S0CB).

The divisor is the item after `INTO` or `BY` of a `DIVIDE`, or after
`/` in a `COMPUTE`. A division is left alone when the statement has `ON
SIZE ERROR`; when no statement gives the divisor a value (a constant
with a `VALUE`); when the paragraph, or one that falls into it, tests
the divisor before the division in an `IF`, `EVALUATE`, `PERFORM
UNTIL`, or `SEARCH`, or moves a nonzero literal to it; and when the
paragraph is performed from a statement that such a test encloses (`IF
WS-COUNT > 0 PERFORM REPORT-AVERAGE`).

A divisor is often known not to be zero for reasons the program does
not show, as a count of a file that is never empty, so the rule only
runs on request (`--enable divisor-not-checked`).

## PLB-C068 odo-count-out-of-range

The count of a table with `OCCURS ... DEPENDING ON` given a value the
table cannot have:

```cobol
01  ORDER-COUNT         PIC 999.
01  ORDER-TABLE.
    05  ORDER-LINE      PIC X(40)
                        OCCURS 1 TO 50 DEPENDING ON ORDER-COUNT.
    ...
    MOVE 60 TO ORDER-COUNT                  *> reported
```

A count above the maximum makes the table, and the record it is in,
reach past the storage they were given; one below the minimum is not
allowed either. Zero is not reported: `VALUE 0` and `MOVE 0` are the
usual count of a table not filled yet, whatever its minimum. GnuCOBOL with run-time checks stops the program there
(`EC-BOUND-ODO`); without them, the program reads and writes storage
that is not the table's. The rule checks the values written as numbers:
a `MOVE` of a numeric literal to the count, a `COMPUTE` whose
expression is one, and the count's `VALUE` clause. The value is the
one the count stores: a count without a sign keeps a negative number's
absolute value (`MOVE -3` stores 3), and one stored as decimal digits
loses the digits its picture has no room for (`MOVE 1005` to a `PIC
999` stores 5), as GnuCOBOL 3.2 does; [PLB-C008](#plb-c008-move-truncation)
reports such moves. As for [PLB-C040](#plb-c040-odo-object-too-small),
the count is the item of that name in the same program.

## PLB-C069 search-index-used-unchecked

A `SEARCH` without `AT END`, after which the paragraph uses the
table's index as if the search had found an entry:

```cobol
    SEARCH RATE-ENTRY
        WHEN RATE-CODE (RATE-IX) = WS-CODE
            CONTINUE
    END-SEARCH
    MOVE RATE-VALUE (RATE-IX) TO WS-RATE            *> reported
```

When no entry matches, the index is left past the last entry (or where
`SEARCH ALL` stopped), and the `MOVE` reads the storage after the
table, or a wrong entry. The index is the first `INDEXED BY` name of
the table searched, or the item after `VARYING`. Its uses are looked
for after the `SEARCH`, to the end of the paragraph, as subscripts in
statements directly in the paragraph. A `SET` of the index or another
`SEARCH` ends the look, and a use under an `IF` or `EVALUATE`, which
may test whether the search found anything, is not reported.

## PLB-C070 mq-completion-not-checked

A call of the IBM MQ interface (`MQGET`, `MQPUT`, `MQOPEN`, ...) whose
completion code and reason, its last two arguments, nothing tests
before the next MQ call:

```cobol
    CALL 'MQGET' USING HCONN HOBJ MQMD MQGMO BUFLEN BUFFER DATALEN
                       MQ-CC MQ-RC                  *> reported
    MOVE BUFFER TO REQUEST-RECORD
```

A failed `MQGET` (no message, or a buffer too short) leaves the buffer
as it was; a failed `MQPUT` loses the message. The test is looked for
as for [PLB-C018](#plb-c018-sql-not-checked): after the call in its
paragraph, before the next MQ call that can run after it, or in a
paragraph performed from there, up to the first MQ call in it. Passing
the codes to a later MQ call does not count: that call sets them anew.

## PLB-C071 contradictory-condition

A condition that joins equalities of one item with `AND`, or
inequalities with `OR`, so that it cannot be true, or cannot be false:

```cobol
    IF WS-STATUS = "00" AND "23"            *> reported: never true
    IF WS-CODE NOT = 100 OR 200             *> reported: always true
```

`AND` was meant to be `OR`, or the other way round. The rule reads
conditions of `IF` and `PERFORM ... UNTIL` that are a chain of
relations `item [IS] [NOT] operator literal`, with the abbreviated
forms that leave out the item, or the item and the operator, joined
all by `AND` or all by `OR`. A condition with parentheses that group,
or both `AND` and `OR`, is not read. The item is compared as written,
with its subscripts; literals by value, so that trailing spaces and
leading zeros do not count.

The operators are `=` (`EQUAL [TO]`), and `>`, `<`, `>=`, `<=` and
their words (`GREATER [THAN]`, `LESS [THAN]`, `GREATER [THAN] OR EQUAL
[TO]`, `LESS [THAN] OR EQUAL [TO]`); `NOT` before one of the four turns
it round, so `NOT > 4` is `<= 4`. Two relations of a numeric item with
numbers are also read as ranges:

```cobol
    IF WS-AMOUNT > 5 AND WS-AMOUNT < 3      *> reported: never true
    IF WS-AMOUNT < 5 OR >= 5                *> reported: always true
    IF WS-AMOUNT >= 5 AND <= 5              *> not reported: true for 5
    IF WS-AMOUNT < 5 OR > 5                 *> not reported: false for 5
```

Under `AND`, ranges that have no number in common are reported; under
`OR`, ranges that hold every number between them. Only items of a
numeric picture are read this way: an alphanumeric item is compared
with a number character by character, where `"10"` comes before `"9"`,
so `WS-TEXT > 10 AND WS-TEXT < 9` is true when `WS-TEXT` is `"5"`, and
a reference modification (`WS-NUMBER(1:2)`) is alphanumeric too.

An item without decimal places holds whole numbers only, and the
ranges are read as the whole numbers they hold:

```cobol
01  WS-CODE  PIC 9(3).
    IF WS-CODE > 3 AND WS-CODE < 4          *> reported: never true
    IF WS-CODE <= 3.5 OR >= 3.6             *> reported: always true
    IF WS-CODE <= 3 OR >= 5                 *> not reported: false for 4
```

The message then says so (`as it holds whole numbers only`). The
largest and smallest value the picture allows are not used: two ranges
that meet only outside them have one that no value meets on its own,
which [PLB-C028](#plb-c028-comparison-never-true) reports for an item
stored as decimal digits and a whole-number literal. A picture
with `P` (`9PP`, multiples of 100) is read as whole numbers, not as
its multiples.

In an editor, the language server offers a quick fix that changes the
condition's `AND`s to `OR`, or its `OR`s to `AND` (see
[Editors](editors.md)), and `plumbline fix` makes it. A condition with
`>` or `<` has no fix: changing `AND` to `OR` in
`WS-AMOUNT >= 5 AND WS-AMOUNT < 5` gives one that is always true, and
which was meant is not plain from the code.

## PLB-C072 unreachable-statement

A statement after one that never lets control go on: `GO TO`,
`GOBACK`, or `STOP RUN`, in the same list of statements (a branch of an
`IF`, a phrase such as `AT END`, a sentence), or in a later sentence of
the same paragraph:

```cobol
    IF WS-EOF = "Y"
        GO TO 900-FINISH
        CLOSE IN-FILE                 *> reported: never runs
    END-IF
```

Control cannot enter a paragraph between its sentences, so nothing
reaches the statement. Usually the statements are in the wrong order,
or the `GO TO` was added to code that was meant to run first. Where
PLB-C001 reports whole paragraphs that nothing reaches, this rule
reports the statements inside a paragraph.

The first statement of each dead stretch is reported. `GO TO ...
DEPENDING ON` does not count, since it goes on to the next statement
when the value is out of range. A statement that is itself `GO TO`,
`GOBACK`, `STOP RUN`, `EXIT`, or `CONTINUE` is not reported (a second
way out, written for safety, does no harm), nor is an `ENTRY`, where a
caller comes in, or GnuCOBOL's `ENTRY FOR GO TO`.

## PLB-C073 value-ignored

A `VALUE` clause on an item of the `FILE SECTION` or the `LINKAGE
SECTION`:

```cobol
FD  OUT-FILE.
01  OUT-REC.
    05  OUT-TYPE        PIC X VALUE "H".     *> reported
```

Storage there is not the program's own. A record holds what was last
read or moved into it, and a linkage item is the caller's storage, so
the clause gives the item nothing. GnuCOBOL 3.2 accepts such a clause
without a warning: in the program above, `WRITE OUT-REC` with nothing
moved to it writes binary zeros, not `H`. Move the value in before the
record is used, or move the layout to working storage if that is where
it belongs.

Condition names (88) and constants (78) are not reported; their values
mean something. Each record is reported once, at its first `VALUE`.
Clauses that a copybook brings in are not reported, since one copybook
is often a working-storage record of one program and a linkage record
of another. Nor is a record that `ALLOCATE ... INITIALIZED` or
`INITIALIZE ... TO VALUE` names, or an item of it: those statements
give it its `VALUE` clauses at run time.

## PLB-C074 condition-range-reversed

A condition name with a range `a THRU b` whose start is above its end:

```cobol
01  WS-MONTH            PIC 99.
    88  MONTH-VALID     VALUE 12 THRU 1.     *> reported
```

The range holds no value, so that part of the condition is never true;
GnuCOBOL 3.2 accepts it without a warning, and `MONTH-VALID` is false
for every month. The ends were written the wrong way round.

A `WHEN` of an `EVALUATE` with such a range is reported too:

```cobol
    EVALUATE WS-AGE
        WHEN 65 THRU 18                     *> reported
```

GnuCOBOL 3.2 matches no value with it, and every value with `WHEN NOT
65 THRU 18`. Only ranges whose ends stand alone are read: each end
starts or ends the `WHEN`, or is next to `ALSO` (or `NOT`, before the
start), and is not part of an expression.

Numbers are compared by value, with their signs and decimal places.
Alphanumeric literals are compared only where ASCII and EBCDIC agree:
at the first character that differs, the shorter literal padded with
spaces, both characters are digits, both upper-case letters, or both
lower-case letters, or one is a space. `"a" THRU "Z"` is a range in
EBCDIC and none in ASCII, and is not reported. Literals with a prefix
(`X"..."`, `N"..."`), figurative constants, and numbers written with a
decimal comma or an exponent are not compared.

In an editor, the language server offers a quick fix that swaps the
two ends of the range, as written (see [Editors](editors.md)).

## PLB-C075 io-after-close

An operation on a file after a `CLOSE` of it, with no `OPEN` between:

```cobol
    CLOSE IN-FILE
    READ IN-FILE                  *> reported: file status 47
```

The file is closed, so the operation fails. With GnuCOBOL 3.2, `READ`
and `START` return file status 47, `WRITE` 48, `REWRITE` and `DELETE`
49, and a second `CLOSE` 42; without a `FILE STATUS` check, the
program goes on as if the operation had worked, or stops.

The operation must come later in the same list of statements as the
`CLOSE` (the same branch of an `IF`, for example), or, for a `CLOSE`
directly in a sentence, anywhere later in its paragraph. The first
operation on the file after the `CLOSE` decides: an `OPEN` there means
no finding. A `PERFORM` of a procedure, `GO TO`, `CALL`, `EXEC`,
`GOBACK`, `STOP`, or `EXIT` between the two also means none, since it
may open the file again or leave. `EXTERNAL` files are not checked.

## PLB-C076 open-while-open

An `OPEN` of a file that an earlier `OPEN` left open, with no `CLOSE`
between:

```cobol
    OPEN INPUT IN-FILE
    READ IN-FILE
    OPEN INPUT IN-FILE            *> reported: file status 41
```

The second `OPEN` fails with file status 41 (GnuCOBOL 3.2), and the
file stays as the first `OPEN` left it, in that `OPEN`'s mode. The two
are found as for PLB-C075: the second in the first's list of
statements, or later in its paragraph, with no `PERFORM` of a
procedure, `GO TO`, `CALL`, `EXEC`, `GOBACK`, `STOP`, or `EXIT`
between. Other operations on the file between them do not matter.

When the file's `FILE STATUS` item is named between the two, the
program looks at whether the first `OPEN` worked (a file that is
missing, opened again in another mode), and nothing is reported.
`OPEN` statements on every pass of a loop are PLB-C065.

## PLB-C077 index-set-out-of-range

`SET` of an index to a number outside its table:

```cobol
01  WS-RATES.
    05  WS-RATE-ENTRY   OCCURS 10 TIMES INDEXED BY RATE-IX.
    ...
    SET RATE-IX TO 11                          *> reported
```

A reference through the index then reads or writes past the table, as
a subscript of 11 would (PLB-C023). The index is a name after `INDEXED
BY` in the table's `OCCURS` clause, in the same program; the number is
the literal after `TO`, checked for each index the `SET` names. Zero is
not reported: an index set to 0 and stepped with `SET ... UP BY 1`
before it is used is common. Negative numbers are.

## PLB-C078 string-literal-cut

A literal that `STRING` sends with a delimiter the literal holds:

```cobol
    STRING "DEAR MR " WS-NAME DELIMITED BY SPACE      *> reported
        INTO WS-LINE
```

Each operand is sent up to the first occurrence of its delimiter, so
`"DEAR MR "` sends only `DEAR`, and with GnuCOBOL 3.2 `WS-LINE` reads
`DEARSMITH`. A literal that starts with its delimiter sends nothing. A
literal says what is to be sent, so one cut short by its own delimiter
is a mistake: `DELIMITED BY SIZE` was meant for it, usually with a
second `DELIMITED BY` phrase for the data items.

The delimiters read are `SPACE`, `ZERO`, and `QUOTE`, with or without
`ALL`, and alphanumeric literals without a prefix. Delimiters that are
data items, literals with a prefix (`X"..."`), and literals inside
parentheses, such as a function's arguments, are not checked.

When every operand the `DELIMITED` phrase covers is a literal, the
language server's quick fix and `plumbline fix` make it `DELIMITED BY
SIZE`.

## PLB-C079 nonnumeric-literal-move

`MOVE` of an alphanumeric literal that is not a number, with a
character other than a digit, to a numeric item:

```cobol
01  WS-COUNT            PIC 9(3).
01  WS-AMOUNT           PIC S9(5)V99 COMP-3.
    MOVE "1.5" TO WS-COUNT                      *> reported
    MOVE "1.50" TO WS-AMOUNT                    *> reported
```

An alphanumeric literal is moved as if it were an unsigned integer of
its characters, so the item does not get the value written. With
GnuCOBOL 3.2, `WS-COUNT` holds the characters `1.5`, fails a `NUMERIC`
test, and `ADD 1` to it gives 246; `WS-AMOUNT` becomes 850.00.
GnuCOBOL warns only with `-Wall` (`-Wtyping`). Write the number without
quotes.

A literal of digits only is a valid move and is not reported, nor are
literals with a prefix (`X"F1F2"`) and edited receivers. When the
literal is a number in quotes, such as `"1.50"`, the language server's
quick fix and `plumbline fix` take the quotes off.

## PLB-C080 initialize-loses-value

`INITIALIZE` of a group with items whose `VALUE` clause it replaces,
and that nothing gives back:

```cobol
01  HEADING-LINE.
    05  HL-TITLE        PIC X(12) VALUE "SALES REPORT".
    05  FILLER          PIC X(3)  VALUE " - ".
    05  HL-PAGE         PIC ZZ9.
    ...
    INITIALIZE HEADING-LINE                     *> reported
```

`INITIALIZE` gives alphanumeric items spaces and numeric items zero,
whatever their `VALUE` clause says. With GnuCOBOL 3.2, `HL-TITLE` is
blank afterwards while the `FILLER` keeps ` - `, as `INITIALIZE`
leaves `FILLER` alone; cobc gives no warning, even with `-Wall`.
Initialize only the items to clear, or give the values back.

Reported are named elementary items under the item initialized whose
`VALUE` is not what `INITIALIZE` gives back (not `SPACE` for an
alphanumeric item, not zero for a numeric or numeric-edited one), that
are read, directly or as part of a group, and that no statement other
than an `INITIALIZE` gives a value: not by itself, not through a group
it is in or an item that redefines one of those, and not by `SET` of
one of its condition names. An item set again after the `INITIALIZE`
uses its `VALUE` clause as a first value only. Items under a
`REDEFINES` are left alone, as `INITIALIZE` leaves them, and so is a
statement with a `VALUE` phrase (`INITIALIZE ... ALL TO VALUE`), which
gives the items their `VALUE` clauses.

## PLB-C081 varying-wrong-direction

A `PERFORM VARYING` whose steps never make its `UNTIL` condition true:

```cobol
    PERFORM VARYING WS-I FROM 10 BY 1 UNTIL WS-I < 1      *> reported
    PERFORM VARYING WS-I FROM 1 BY 2 UNTIL WS-I = 10      *> reported
```

The condition is false at the start, and each step moves the counter
away from it, or, for `=`, past the limit without reaching it. The loop
ends only if the counter wraps around at the end of its picture, or
something else leaves it. With GnuCOBOL 3.2 and a `PIC S9(4)` counter,
the first loop above runs 9,990 times, until the counter goes from 9999
to 0; with `BY -1 UNTIL WS-I > 10` it does not end. The sign of `BY`
or the comparison is usually what is wrong.

Checked are loops whose `FROM`, `BY`, and `UNTIL` limit are literal
numbers and whose condition is the counter compared with that limit
alone, as for PLB-C026. A loop whose condition is true at the start
does not run its body; [PLB-C089](#plb-c089-loop-never-runs) reports
it.

## PLB-C082 pointer-below-one

`STRING` or `UNSTRING` `WITH POINTER` an item that was just given a
value below 1:

```cobol
    MOVE 0 TO WS-PTR
    STRING WS-FIRST DELIMITED BY SPACE INTO WS-LINE
        WITH POINTER WS-PTR                     *> reported
```

The pointer counts characters from 1. Below 1, the statement overflows
at once: with GnuCOBOL 3.2, `STRING` and `UNSTRING` move nothing, run
their `ON OVERFLOW` phrase, and leave the pointer at 0. `MOVE 1` was
meant.

The value is the one the last statement before, in the same paragraph,
gives the pointer: `MOVE` of a number or `ZERO`, `COMPUTE pointer =
number`, or `INITIALIZE` (zero). That statement must be in a list of
statements that holds the `STRING`, or directly in a sentence of the
paragraph, and nothing between may change the pointer: no `ADD` to it,
`PERFORM` of a procedure, `GO TO`, `CALL`, or `EXEC`. A value set in
another paragraph, one that falls into the `STRING`'s, is not followed.
When it was set by `MOVE`, the quick fix and `plumbline fix` make the
number 1.

## PLB-C083 close-in-loop

A `CLOSE` that runs on every pass of a loop that never opens the file
again:

```cobol
    PERFORM UNTIL WS-EOF = "Y"
        READ IN-FILE AT END MOVE "Y" TO WS-EOF END-READ
        CLOSE IN-FILE                           *> reported
    END-PERFORM
```

The first pass closes the file, and the second works on a closed file:
with GnuCOBOL 3.2 its `READ` fails with file status 47, a `WRITE` with
48, and the `CLOSE` itself with 42 (see PLB-C075). The `CLOSE` was
meant after the loop.

The loops and the places of the `CLOSE` are those of PLB-C065: the
loop's inline body, a procedure of the range it performs, or a
procedure performed on every pass from its inline body; not under an
`IF`, `EVALUATE`, or conditional phrase. A loop that opens the file
somewhere among its statements, or in a procedure they perform, is
not reported.

## PLB-C084 file-status-unknown

A `FILE STATUS` item compared with a code no I/O statement returns:

```cobol
    SELECT IN-FILE ASSIGN TO "in.dat" FILE STATUS IS WS-FS.
    ...
    IF WS-FS = "01"                             *> reported
```

No I/O statement sets the status to that code, so the test does not
catch what it was written for. Usually two digits were swapped (`"01"`
for `"10"`), or a one-character code was written for a two-character
status. The codes known are those of GnuCOBOL 3.2 (`libcob/common.h`),
which include the standard's: 00, 02, 04 to 07, 09, 10, 14, 21 to 24,
30, 31, 34, 35, 37 to 39, 41 to 49, 51 to 54, 57, 61, and 71; and any
code starting with 9, which each implementation defines for itself.

Checked are the alphanumeric literals the item is compared with by `=`
(or `EQUAL TO`, `NOT =`), with the abbreviated `OR` and `AND` forms
after them; the `WHEN` phrases of an `EVALUATE` of the item that are
one literal; and the values of its condition names. A literal the
program moves into the item itself, such as a marker for "not set
yet", is a value the item can hold and is not reported.

## PLB-C085 zeros-into-packed

`MOVE ZEROS` to a group, and then a read of one of its packed-decimal
or binary items before anything gives it a value:

```cobol
01  WS-TOTALS.
    05  WS-COUNT        PIC S9(7) COMP-3.
    05  WS-PAGE         PIC 9(3).
    ...
    MOVE ZEROS TO WS-TOTALS                        *> reported
    ADD 1 TO WS-COUNT
```

A group move puts the character `0` in every byte. That is a valid
`DISPLAY` number, and `WS-PAGE` is fine; but it is no packed or binary
zero. With GnuCOBOL 3.2, `WS-COUNT` then fails a `NUMERIC` test and
`ADD 1` makes it 30304, and a `COMP` item reads as 2336. `INITIALIZE`
gives each item a zero of its own kind.

`ZERO`, `ZEROS`, `ZEROES`, and a literal of zeros (`"000"`) count. The
statements after the `MOVE` are followed as for PLB-C060, which is the
same check for `MOVE SPACES`, and a `FILE STATUS` group is left alone.

## PLB-C086 read-loop-end-only

A loop that reads a file and ends only when its file status is `"10"`,
the end of the file:

```cobol
    PERFORM UNTIL WS-FS = "10"                 *> reported
        READ IN-FILE
        ADD 1 TO WS-COUNT
    END-PERFORM
```

When a `READ` fails with any other status, the loop goes round again,
and the next `READ` fails the same way. With GnuCOBOL 3.2, a file that
did not open returns status 47 on every pass, and the loop never ends.
Test for errors in the loop, or end it on any status but `"00"`.

Checked are `PERFORM ... UNTIL` loops whose whole condition is the file
status item `= "10"`, or a condition name of it whose only value is
`"10"`, and whose statements, inline or in procedures they perform,
`READ` (or `RETURN`). The loop is left alone when those statements name
the status item otherwise, or can leave the loop: `GOBACK`, `STOP`, `GO
TO`, `EXIT PERFORM`, `EXIT PROGRAM`, or a `CALL` (an abend routine).

## PLB-C087 when-covered

A `WHEN` of an `EVALUATE` whose values an earlier `WHEN`'s range
already takes:

```cobol
    EVALUATE WS-CODE
        WHEN 1 THRU 10
            ...
        WHEN 5                                  *> reported
```

`EVALUATE` runs the first `WHEN` that matches, so the later one never
runs: with GnuCOBOL 3.2, `WS-CODE` 5 takes the `1 THRU 10` branch.
Usually the ranges overlap by mistake, or the specific case was meant
to come first.

Read are `EVALUATE` statements of one subject (not `TRUE` or `FALSE`,
no `ALSO`), and `WHEN` phrases that are a number or a range of numbers;
a `WHEN` inside one earlier range is reported. A `WHEN` the same as an
earlier one is [PLB-C032](#plb-c032-duplicate-when)'s, and ranges of
alphanumeric values, which depend on the collating sequence, are not
read.

`EVALUATE TRUE` is read too, for `WHEN` phrases that are one relation
of a numeric item with a number:

```cobol
    EVALUATE TRUE
        WHEN WS-AMOUNT > 10
            ...
        WHEN WS-AMOUNT > 20                 *> reported: never chosen
```

Each relation stands for the values it holds (`> 10`, `= 15`, `NOT >
9`), and a `WHEN` whose values an earlier `WHEN` on the same item, as
written with its subscripts, takes all of is reported. With GnuCOBOL
3.2, over the values -5 to 30 the second `WHEN` above is never chosen,
while `WHEN WS-AMOUNT >= 10` after the first is, for 10.

## PLB-C088 accept-truncation

`ACCEPT` of the date or the time into a numeric item with fewer digits
than it gives:

```cobol
01  WS-TIME  PIC 9(6).
01  WS-DATE  PIC 9(6).
    ACCEPT WS-TIME FROM TIME                *> reported: HH is lost
    ACCEPT WS-DATE FROM DATE YYYYMMDD       *> reported: YY is lost
```

`ACCEPT ... FROM` moves an unsigned whole number to the item, as `MOVE`
does: `DATE` gives 6 digits (YYMMDD), `DATE YYYYMMDD` 8, `DAY` 5
(YYDDD), `DAY YYYYDDD` 7, and `TIME` 8 (HHMMSShh). A numeric item keeps
the digits on the right, so what is lost is the hours or the start of
the year: with GnuCOBOL 3.2, `WS-TIME` above holds minutes, seconds and
hundredths, and `WS-DATE` a two-digit year. The message names the
digits kept and lost. Usually `TIME` was taken for `HHMMSS`, or the
item was not widened when the date became `YYYYMMDD`.

Read are numeric items stored as decimal digits (`DISPLAY` or
`PACKED-DECIMAL`), with the digits before the decimal point counted. A
binary item does not keep the last digits (with GnuCOBOL, a `COMP-5`
item wraps round its bytes), and a picture with `P` (`9(4)PP`) loses
the low-order digits too; neither is read. An alphanumeric item keeps
the characters on the left (`HHMMSS` of the time in a `PIC X(6)`),
which is usually meant, and is not reported.

## PLB-C089 loop-never-runs

A `PERFORM ... UNTIL` whose condition is already true when the loop
starts, or a `PERFORM ... TIMES` whose count is zero, so that it runs no
times:

```cobol
    MOVE "N" TO WS-EOF
    PERFORM READ-NEXT UNTIL WS-EOF = "N"          *> reported
    SET END-OF-FILE TO TRUE
    PERFORM UNTIL END-OF-FILE                     *> reported
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 0   *> reported
```

`PERFORM` tests the condition before each pass, the first one too
(unless `WITH TEST AFTER`), so the body never runs: usually the value
moved or tested is the wrong one, or `>` was meant for `<`.

For `PERFORM ... UNTIL`, read are the statements before it that
`MOVE` a literal to items or `SET` condition names `TO TRUE` or
`FALSE`, across the ends of sentences but not out of the paragraph or
the branch the `PERFORM` is in. The walk back goes on over statements
whose data references show all they change: `DISPLAY`, `CONTINUE`,
`MOVE` and `SET` of other values, arithmetic, `INITIALIZE`, `STRING`,
`UNSTRING` and `INSPECT`, without phrases such as `ON SIZE ERROR`;
what they store into is no longer known. It stops at any other
statement (a `PERFORM` or `CALL` may change anything). The condition is read when it is relations `item [IS] [NOT] op
literal` (`=`, `>`, `<`, `>=`, `<=`, and their words) and condition
names, joined all by `AND` or all by `OR`, without parentheses or
abbreviations; it is true when every relation joined by `AND` is, or
one joined by `OR`. Items are named without subscripts. A value is
known only when the item holds the literal as written: an
alphanumeric literal no longer than the item (then compared with `=`
alone, as the collating sequence decides the order), or a number an
item stored as decimal digits holds, signs and decimal places too. A
`MOVE` to a group or other item that shares storage with an item,
nearer the loop, makes its earlier value unknown. So
`MOVE "YES" TO WS-FLAG` into a `PIC X` is not read, nor a value moved
before a `PERFORM` that comes before the loop.

`PERFORM ... n TIMES` runs no times when `n` is the literal 0, or an
item that a `MOVE` of 0 or `ZERO` before it leaves at 0, read as for
`UNTIL`.

For `PERFORM VARYING`, read are loops as for
[PLB-C081](#plb-c081-varying-wrong-direction): a `FROM` literal the
counter holds, and an `UNTIL` that compares the counter with a literal
alone, the counter an integer stored as decimal digits.

## PLB-C090 condition-never-true

A condition name that a statement tests, when nothing gives its item
one of the condition's values:

```cobol
01  WS-EOF          PIC X VALUE "N".
    88  END-OF-FILE VALUE "Y".
    ...
    MOVE "E" TO WS-EOF
    PERFORM PROCESS-RECORD UNTIL END-OF-FILE      *> reported
```

The condition is never true, so the loop never ends, or the branch it
guards never runs. Usually the value moved is mistyped, the `SET` of
the condition was left out, or the condition's `VALUE` is wrong. The
message lists every value the item can hold.

The values are read from every way the item gets one: its `VALUE`
clause (or, with none, the spaces or zero GnuCOBOL starts it with, or
`SPACE` or `ZERO` in the `VALUE` of a group it is in), `MOVE` of a
literal to it (cut to the item's size), `SET` of one of its condition
names `TO TRUE` (the first value) or `TO FALSE` (the `WHEN SET TO
FALSE` value), `INITIALIZE` of it or a group it is in, and `MOVE` of
`SPACE` or `ZERO` to such a group. A number counts only when the
item's picture holds it as written. Any other store into the item or
storage it shares makes its values unknown and the condition is not
read: `MOVE` of another item, arithmetic, `READ ... INTO`, `ACCEPT`,
`CALL ... BY REFERENCE`, embedded SQL or CICS `INTO`, a `REDEFINES`.

Only items that at least one statement stores into are read. An item
that keeps its `VALUE` is often a switch set by editing the program
(`88 DEBUG-ON VALUE "Y"` of an item with `VALUE "N"`), and one that
has no `VALUE` either is reported by
[PLB-C011](#plb-c011-read-never-set). Left out too are items of the
LINKAGE, FILE, and REPORT sections, items longer than 64 bytes,
FILE STATUS items (I/O statements set them without naming them), the
`SQLCA` and items named `SQL...`, `EXTERNAL`, `BASED` and `JUSTIFIED`
items, programs with a SCREEN SECTION (its `ACCEPT` stores into items
no statement names), and conditions with literals with a prefix
(`X"..."`) or ranges of characters.

## PLB-C091 varying-counter-repeated

A `PERFORM VARYING` whose `AFTER` phrase names the counter of the
`VARYING` phrase, or of an `AFTER` phrase before it:

```cobol
    PERFORM FILL-CELL VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3
                        AFTER WS-I FROM 1 BY 1 UNTIL WS-I > 3   *> reported
```

When the inner phrase's condition comes true, the outer phrase steps
its counter and the inner one sets its counter to its `FROM` value
again; with one counter for both, the outer condition is then tested
on that `FROM` value. Unless that value meets it, the loop never ends:
with GnuCOBOL 3.2, the one above does not. Usually an `AFTER` phrase
was copied and its counter not changed (`WS-J` was meant). Counters
are compared by the data item they name, without subscripts.

## PLB-C092 swap-lost

Two `MOVE` statements in a row that move an item to another and
straight back:

```cobol
    MOVE WS-A TO WS-B
    MOVE WS-B TO WS-A                       *> reported
```

Meant as a swap, the pair loses the value of `WS-B`, and the second
`MOVE` gives `WS-A` the value it already has: with GnuCOBOL 3.2 both
items end up `"AAAAA"`. A swap needs a third item (`MOVE WS-A TO
WS-TEMP`, `MOVE WS-B TO WS-A`, `MOVE WS-TEMP TO WS-B`).

Reported only when the middle item holds every value of the first as
it is: both alphanumeric (or alphabetic) and the middle one no
shorter, or both numeric with as many digits before and after the
decimal point, and a sign if the first has one. Moving through a
smaller item and back cuts a value (its decimal places, or the end of a
text), which is a way to round down or truncate, and is not reported.
The statements are read across the end of a sentence; as for
[PLB-C033](#plb-c033-self-move), the names must stand alone, without
qualification, subscripts, or reference modification.

## PLB-C093 pointer-too-small

A `STRING` or `UNSTRING` `POINTER` item that cannot hold one past the
last position it counts:

```cobol
01  WS-OUT  PIC X(20).
01  WS-P    PIC 9.
    STRING WS-PART DELIMITED BY SIZE INTO WS-OUT
        WITH POINTER WS-P                   *> reported
```

The pointer counts the positions of the receiver (`STRING`) or of the
sending item (`UNSTRING`), and after the last one it is one past it:
`WS-P` above must reach 21. A pointer whose picture cannot hold that
loses its high-order digits as it grows: with GnuCOBOL 3.2, after 12
characters `WS-P` holds 3, so the next `STRING` writes over the third
character, and an `UNSTRING` that should go on from position 11 starts
over at 1.

Read are pointers stored as decimal digits (`DISPLAY` or
`PACKED-DECIMAL`), whose picture decides the largest number they hold;
what a binary pointer holds depends on the compiler's options. The
receiver or sending item must have a fixed size and no reference
modification.

## PLB-C094 open-after-lock

An `OPEN` of a file that a `CLOSE ... WITH LOCK` before it closed:

```cobol
    CLOSE OUT-FILE WITH LOCK
    OPEN INPUT OUT-FILE                     *> reported
```

A file closed with lock cannot be opened again while the program runs:
with GnuCOBOL 3.2 the `OPEN` fails with file status 38
(`COB_STATUS_38_CLOSED_WITH_LOCK`). Usually `WITH LOCK` was copied from
the program's last `CLOSE` to one that is not the last. The lock
applies to the file it follows: `CLOSE F1 WITH LOCK F2` locks `F1`
alone, and `F2` opens again.

Read as for [PLB-C075](#plb-c075-io-after-close): the `OPEN` must come
later in the same list of statements as the `CLOSE` (or, for a `CLOSE`
directly in a sentence, later in its paragraph), with no `GO TO`,
`CALL`, `EXEC`, `GOBACK`, `STOP`, or `EXIT` between, which may leave.
A `PERFORM` between does not end the search: nothing it does can undo
the lock.

## PLB-C095 rewrite-without-read

A `REWRITE` or `DELETE` of a file with sequential access whose last
operation on the file before it is not a `READ`:

```cobol
    READ SEQ-FILE
    REWRITE SEQ-REC
    REWRITE SEQ-REC                         *> reported
```

With sequential access, `REWRITE` and `DELETE` act on the record the
last `READ` returned, and must follow it: with GnuCOBOL 3.2 a
`REWRITE` after the `OPEN`, or after another `REWRITE`, fails with
file status 43 (`COB_STATUS_43_READ_NOT_DONE`). Files with random or
dynamic access, which rewrite and delete by key, are not read.

The operation before must be in the same list of statements (or, for
statements directly in sentences, in the same paragraph) and be an
`OPEN`, `WRITE`, `REWRITE`, `DELETE`, or `START`. A `PERFORM` of a
procedure, `GO TO`, `CALL`, `EXEC`, `GOBACK`, `STOP`, or `EXIT`
between them, which may read, ends the search, as does an operation
before it in another list; a `REWRITE` in the `NOT AT END` of its
`READ` follows it.

## PLB-C096 converting-repeated

An `INSPECT ... CONVERTING` whose first string has a character twice,
with different characters for it in the second:

```cobol
    INSPECT WS-TEXT CONVERTING "ABA" TO "XYZ"   *> reported
```

Only the first occurrence counts: with GnuCOBOL 3.2 each `A` becomes
`X`, and the `Z` is never used. Usually a character of a translation
table was typed twice and another left out (`"aeiouAEIOe"` for
`"aeiouAEIOU"`). Read are both strings written as literals without a
prefix; a character repeated with the same character for it changes
nothing and is not reported.

## PLB-C097 sort-file-open

A `SORT` or `MERGE` whose `USING` or `GIVING` file an `OPEN` before it
left open:

```cobol
    OPEN INPUT IN-FILE
    SORT SORT-FILE ON ASCENDING KEY SORT-REC
        USING IN-FILE GIVING OUT-FILE        *> reported
```

`SORT` and `MERGE` open and close their `USING` and `GIVING` files
themselves, and the files must be closed when they start: with GnuCOBOL
3.2 the `SORT` above, or one whose `GIVING` file is open, ends with
`SORT-RETURN` 16 and writes nothing.

Read as for [PLB-C076](#plb-c076-open-while-open): the file's last
operation before the statement is an `OPEN` in the same list of
statements (or, for statements directly in sentences, the same
paragraph), with no `PERFORM` of a procedure, `GO TO`, `CALL`, `EXEC`,
`GOBACK`, `STOP`, or `EXIT` between, nor another `SORT` or `MERGE` of
the file, which closes it.

## PLB-C098 group-value-into-packed

A group whose `VALUE` puts characters in its packed-decimal or binary
items:

```cobol
01  WS-TOTALS VALUE SPACES.                     *> reported
    05  WS-COUNT        PIC S9(7) COMP-3.
    05  WS-NAME         PIC X(20).
```

A group's `VALUE` gives the whole group its start value byte for byte,
as an alphanumeric item. Spaces, or the character 0 of `ZERO`, are no
valid packed-decimal number: with GnuCOBOL 3.2, `ADD 1 TO WS-COUNT`
gives +2020203, and with run-time checks (`-fec=all`) the run stops
with "WS-COUNT (Type: PACKED-DECIMAL) not numeric"; on z/OS the first
arithmetic fails with a data exception. In a binary item they are a
meaningless number. `LOW-VALUES` gives a binary item the number 0, and
is not reported for binary items. Give the items values of their own
with `INITIALIZE`, or move the group's `VALUE` to its alphanumeric
items. One finding is made for each group, naming its first such item.
Items of the WORKING-STORAGE and LOCAL-STORAGE SECTIONs are read.

## PLB-C099 value-overridden

A `VALUE` clause on an item in a group that has a `VALUE` of its own:

```cobol
01  WS-LIMITS VALUE SPACES.
    05  WS-LIMIT        PIC X(3) VALUE "MAX".     *> reported
```

The group's `VALUE` decides the start value of everything in it. With
GnuCOBOL 3.2 the item's `VALUE` is ignored without a message, and
`WS-LIMIT` above starts as spaces. Take one of the two clauses out.

## PLB-C100 table-keys-unsorted

A table that `SEARCH ALL` looks in, filled by `VALUE` clauses, whose
keys are not in the order its `KEY` phrase gives:

```cobol
01  WS-STATES-V.
    05  FILLER  PIC X(7) VALUE "01ALPHA".
    05  FILLER  PIC X(7) VALUE "05BETA ".
    05  FILLER  PIC X(7) VALUE "03GAMMA".
01  WS-STATES REDEFINES WS-STATES-V.
    05  WS-STATE OCCURS 3 ASCENDING KEY WS-STATE-CODE   *> reported
                 INDEXED BY WS-SX.
        10  WS-STATE-CODE  PIC X(2).
        10  WS-STATE-NAME  PIC X(5).
```

`SEARCH ALL` is a binary search: it trusts the order of the keys, and
in a table out of order it misses entries that are there. With GnuCOBOL
3.2, a search of the table above for `05` ends `AT END`.

The table's start value is rebuilt from the `VALUE` clauses of the item
it redefines: literals of alphanumeric items, and unsigned whole
numbers of `DISPLAY` items. The entries are compared on the first key
the `KEY` phrase names, as characters, and a pair is reported only when
it is out of order both in ASCII and in EBCDIC, whose orders of
letters, digits, and signs differ (`AA` before `11` is in order on
z/OS, not on a PC); a key with a character outside the letters, digits,
space, and common signs is not compared. Tables with `OCCURS DEPENDING
ON`, tables filled by statements, and keys that no `VALUE` covers are
not read.

## PLB-C101 string-numeric-sender

A `STRING` that sends a numeric item with decimal places, or with a
sign kept in its last digit:

```cobol
01  WS-AMOUNT  PIC S9(5)V99.
    STRING "TOTAL " WS-AMOUNT DELIMITED BY SIZE   *> reported
        INTO WS-LINE
```

`STRING` sends the item's characters as they are stored, not the number
they stand for. The decimal point is not stored, so 1.5 in a `9(3)V99`
is sent as `00150`; the sign of a `DISPLAY` item is kept in its last
digit, so with GnuCOBOL 3.2, -123 in an `S9(3)` is sent as `12s`. A
`MOVE` of the same items to an alphanumeric item is rejected
([PLB-C039](#plb-c039-decimal-to-alphanumeric)) or drops the sign, but
GnuCOBOL takes them in `STRING` without a message. Move the item to a
numeric-edited item first (`PIC -(5)9.99`), and send that.

An item with a separate sign (`SIGN LEADING SEPARATE`) sends a real `-`
or `+`, and is reported only for its decimal places. A delimiter
(`DELIMITED BY item`) is not a sent item; packed and binary items in
`STRING` are compile errors.

## PLB-C102 nested-if-decided

An `IF` that is the first statement of the `THEN` branch of another
`IF`, whose test the outer test already decides:

```cobol
    IF WS-AMOUNT > 100
        IF WS-AMOUNT > 50                   *> reported: always true
            ...
    IF WS-COUNT = 325
        IF WS-COUNT = 750                   *> reported: never true
            ...
```

The inner test runs only when the outer one was true, and nothing runs
in between, so its item still holds a value the outer test took. When
every such value passes the inner test, the inner `ELSE` never runs;
when none does, the inner branch never runs. Without a period or
`END-IF`, an `IF` whose own statements were commented out takes the
next `IF` as its branch, which is how the second case above happens.

Both tests must be one relation of the same numeric item with a number,
read as PLB-C051 reads them, with the item written the same way and
the same subscripts. An `IF` in the `ELSE` branch is PLB-C051's.

An `IF` that is the first statement of an inline `PERFORM ... UNTIL` is
read the same way: the body runs only while the `UNTIL` test is false.

```cobol
    PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 10
        IF WS-I > 20                        *> reported: never true
            ...
```

The `UNTIL` test must have one end (`>`, `<`, `>=`, `<=`, not `=`),
so that the values it leaves are one range. A `PERFORM WITH TEST
AFTER` runs its body once before it tests, and `VARYING ... AFTER`
tests several items, and neither is read.

## PLB-C103 chain-exhausted

An `IF` of an `ELSE IF` chain, or the chain's last `ELSE`, that no value
reaches, because the tests before it take every value of their item
between them:

```cobol
    IF WS-AMOUNT > 5
        ...
    ELSE IF WS-AMOUNT < 8
        ...
    ELSE IF WS-AMOUNT >= 3                  *> reported
        ...

    IF WS-COUNT >= 100
        ...
    ELSE IF WS-COUNT < 100
        ...
    ELSE                                    *> reported
        ...
```

Neither earlier test of the first chain holds all the values of
`WS-AMOUNT >= 3`, so PLB-C051 does not report it, but every value
passes one of them. GnuCOBOL 3.2 runs neither the third branch nor an
`ELSE` after it, for any value from -999.9 to 999.9. Such an `ELSE` is
often a check for a case that cannot happen; when it is meant that way,
it can go.

The tests are read as PLB-C051 reads them: one relation of a numeric
item with a number. The item is that of the chain's first such test; a
test of anything else leaves the values it has left as they are. What
is left is followed while it is one range: `IF A = 50` leaves the
values on both sides of 50, and the chain is not followed further. An
`IF` that one earlier test alone covers is PLB-C051's, and only the
first `IF` or `ELSE` that nothing reaches is reported.

The `WHEN` phrases of an `EVALUATE TRUE` are read the same way, in
order; a `WHEN` that one earlier `WHEN` covers is
[PLB-C087](#plb-c087-when-covered)'s:

```cobol
    EVALUATE TRUE
        WHEN WS-AMOUNT >= 0
            ...
        WHEN WS-AMOUNT < 0
            ...
        WHEN OTHER                          *> reported
```

## PLB-C104 count-too-small

A count that `INSPECT` or `UNSTRING` stores in an item with too few
digits to hold it:

```cobol
01  WS-TEXT     PIC X(50).
01  WS-COUNT    PIC 9.
    ...
    INSPECT WS-TEXT TALLYING WS-COUNT FOR ALL "A"      *> reported
    UNSTRING WS-TEXT DELIMITED BY "," INTO WS-PART
        COUNT IN WS-COUNT                              *> reported
```

The count is stored like the result of an `ADD` without `ON SIZE
ERROR`: its high-order digits are lost. With GnuCOBOL 3.2, 50 `A`s
counted into a `PIC 9` item leave 0, in `DISPLAY`, `COMP-3`, and
`COMP` alike, and 25 pairs `AB` leave 5.

The largest count is the length of the item inspected divided by the
length of the shortest string counted for that item (`CHARACTERS`
counts one character at a time), or, for `COUNT IN`, the length of the
item unstrung. A string that is neither a literal, a figurative
constant, nor an item of fixed size, an item inspected with reference
modification or of variable size, and a count of native binary usage
(`COMP-5`) are not read. A count that `INSPECT` adds to without
setting it first can grow larger still; that is
[PLB-C042](#plb-c042-inspect-count-not-reset).

## PLB-C105 string-edited-leading-space

A `STRING` that sends a numeric-edited item `DELIMITED BY SPACE`, when
the item's picture starts with a symbol that leaves a space for some
values:

```cobol
01  WS-COUNT    PIC ZZZ9.
    ...
    STRING "COUNT " WS-COUNT DELIMITED BY SPACE      *> reported
        INTO WS-LINE
```

`STRING` stops sending an item at its first space. For 5, `WS-COUNT`
holds `"   5"`, so nothing of it is sent, and the line says `COUNT` with
no number. With GnuCOBOL 3.2, 5 moved to `PIC ZZZ9`, `PIC +(3)9`, `PIC
$$$9`, `PIC B99`, and `PIC -9` gives `"   5"`, `"  +5"`, `"  $5"`, `"
05"`, and `" 5"`, and `STRING ... DELIMITED BY SPACE` sends none of
them; `PIC ***9`, `PIC +9`, and `PIC $999` are sent.

The symbols read are `Z` and `B` at the start, a leading `-` (a space
for a value that is not negative), and a floating `+` or `$` (`++9`,
`$(3)9`). Send the item `DELIMITED BY SIZE`, or take its spaces off
first, for example with `FUNCTION TRIM`.

## PLB-C106 unstring-space-not-all

An `UNSTRING` into more than one item `DELIMITED BY SPACE`, without
`ALL`:

```cobol
    UNSTRING WS-NAME DELIMITED BY SPACE              *> reported
        INTO WS-FIRST WS-MIDDLE WS-LAST
```

Each space ends a field, so two spaces in a row give an empty field
between them, and the words after it go one field on. With GnuCOBOL
3.2, `"JOHN  SMITH JR"` gives `JOHN`, spaces, and `SMITH`, and `JR` is
lost; `DELIMITED BY ALL SPACE` gives `JOHN`, `SMITH`, and `JR`.

`SPACE`, `SPACES`, and `" "` are read, alone or among other delimiters
joined by `OR`. A delimiter of more than one character, and an
`UNSTRING` into one item, are not reported.

## PLB-C107 times-count-changed

A statement of a `PERFORM ... TIMES` loop that changes the loop's count:

```cobol
    PERFORM WS-ROWS TIMES
        ...
        MOVE 10 TO WS-ROWS                  *> reported
    END-PERFORM
```

The count is read once, when the loop starts: the standard says a
change to it in the loop has no effect on how many times it runs, and
NIST's `NC102A` tests just that. With GnuCOBOL 3.2, the loop above runs
3 times for a `WS-ROWS` of 3, though the count is 10 after the first.
A loop meant to run while a count lasts is written `PERFORM ... UNTIL`.

The loop is the inline body, or the paragraphs from the procedure
performed through its `THRU`, as for
[PLB-C044](#plb-c044-varying-control-changed); a statement counts when
it stores into the count or into a group that holds it. `PERFORM
LENGTH OF item TIMES` counts the item's length, and is not read.

## PLB-C108 number-compared-to-text

An unsigned integer item of decimal digits compared for equality with
digits in quotes, when there are fewer or more of them than the item
has:

```cobol
01  WS-COUNT    PIC 99.
    ...
    IF WS-COUNT = "5"                       *> reported
```

The literal is alphanumeric, so the comparison is of characters: the
item's `"05"` against `"5"` padded with a space, never equal, even
when `WS-COUNT` holds 5. With GnuCOBOL 3.2, `IF WS-COUNT = "5"` and
`EVALUATE WS-COUNT WHEN "5"` are false for 5, and `WS-COUNT = "05"` is
true. Compare with the number, `IF WS-COUNT = 5`.

`=` and the `WHEN` of an `EVALUATE` of the item are read; trailing
spaces in the literal count as the padding they are. Signed items,
items with decimal places or of other usages, and text that is not all
digits are not reported.

## PLB-C109 pointer-past-end

`STRING` or `UNSTRING` `WITH POINTER` an item that was just given a
value past the end of the item it counts in:

```cobol
01  WS-LINE     PIC X(20).
    ...
    MOVE 21 TO WS-PTR
    STRING "ABC" DELIMITED BY SIZE INTO WS-LINE
        WITH POINTER WS-PTR                          *> reported
```

The pointer counts positions in the receiver of `STRING`, or in the
item `UNSTRING` splits. Past its last position, the statement
overflows at once, as below 1
([PLB-C082](#plb-c082-pointer-below-one)): with GnuCOBOL 3.2 it moves
nothing and runs its `ON OVERFLOW` phrase, and 20 for the `PIC X(20)`
above is still fine. GnuCOBOL's own test of `STRING ... WITH POINTER`
expects this overflow for a pointer of 4 into a `PIC X(03)`.

The value is read as for PLB-C082: the last statement before, in the
same paragraph, that gives the pointer a number, with nothing between
that may change it. An item with reference modification or of variable
size is not read.

## PLB-C110 file-dd-shared

Two files of a program assigned to the same DD name and opened by one
`OPEN`, at least one of them for writing:

```cobol
    SELECT OLD-MASTER ASSIGN TO MASTER.
    SELECT NEW-MASTER ASSIGN TO UT-S-MASTER.    *> reported
    ...
    OPEN INPUT OLD-MASTER OUTPUT NEW-MASTER
```

On z/OS `UT-S-MASTER` is DD `MASTER`, so both files are the one data
set it names, and each works on it as if the other were not there.
With GnuCOBOL 3.2 and both files assigned to `MASTER`, `OPEN OUTPUT`
of the new file empties the data set the old one reads, whose first
`READ` is then at end of file; and two files opened `OUTPUT` on one DD
both write from its start, so the records of the first are lost. A new
file needs a DD of its own.

The DD name is the one the JCL rules use: the assignment, or its last
part after a hyphen. Only files opened by the same `OPEN` statement are
compared, which shows they are open together; a file written, closed,
and read back through another `FD` on its DD, as NIST's `RL111A` does,
is common and fine. Two `OPEN` statements that leave both files open
are not followed. Files assigned to a data item, a path, or a device
are not compared.

## PLB-I001 pcb-dbd-unknown

The I rules check IMS definitions, given to `check` as `*.dbd` and
`*.psb` files, and the DL/I calls of the programs against them (see
[IMS](ims.md)).

A `PCB` of a PSB that names a database (`DBDNAME`) that no DBD of the run
defines, when the run has DBDs:

```
BADPCB   PCB   TYPE=DB,DBDNAME=NOSUCHDB,PROCOPT=G
```

The PSB generation (PSBGEN) fails, or the PSB was generated against a
DBD that is no longer among the sources.

## PLB-I002 senseg-not-in-dbd

A sensitive segment (`SENSEG`) that its PCB's database does not have, or
that has another parent in it:

```
         SENSEG NAME=ORDNOTE,PARENT=ORDLINE
```

when `ORDNOTE` is a child of `ORDER` in the DBD. The PSB no longer
matches the database it was written for.

## PLB-I003 segment-not-sensitive

An `EXEC DLI` call that names a segment (`SEGMENT(name)`) that none of
the program's PSBs is sensitive to:

```cobol
    EXEC DLI GNP USING PCB(1) SEGMENT(ORDNOTE) INTO(NOTE-AREA) END-EXEC
```

IMS rejects the call (status code `AK` or `GE`). A program's PSB is the
one it schedules (`EXEC DLI SCHD PSB(name)`, or `PSB((item))` with an
item whose `VALUE` names it) or the one the JCL step that runs it gives
(`EXEC PGM=DFSRRC00,PARM='BMP,program,psb'`). Calls through `CALL
'CBLTDLI'` are not checked.

## PLB-I004 procopt-forbids-call

An `EXEC DLI` call that no PCB of the program's PSBs allows for the
segment: `ISRT` needs `PROCOPT` with `I`, `REPL` with `R`, `DLET` with `D`,
and the get calls with `G`; `A` allows all of them.

```cobol
    EXEC DLI REPL USING PCB(1) SEGMENT(ORDER) FROM(ORDER-AREA) END-EXEC
```

when the PCB has `PROCOPT=G`. IMS rejects the call (status code `AM`).

## PLB-I005 dli-status-not-checked

A DL/I call whose status code nothing tests before the next call:

```cobol
    CALL 'CBLTDLI' USING FUNC-GU ACCTPCB ACCT-SEGMENT   *> reported
    MOVE ACCT-SEGMENT(1:11) TO WS-ACCT-ID
```

When the segment is not found (`GE`) or the call fails, the I/O area
holds what it held before, and the program goes on with it. For `CALL
'CBLTDLI'` the status is in the PCB mask passed (the second argument):
the mask, or any item of it, named after the call counts as the test.
For `EXEC DLI` it is `DIBSTAT`. The test is looked for as for
[PLB-C018](#plb-c018-sql-not-checked): after the call in its paragraph,
before the next DL/I call that can run after it (one in another branch
of the same `IF` or `EVALUATE` cannot), or in a paragraph performed
from there. `EXEC DLI TERM` is left alone.

## PLB-J001 dd-missing

The J rules check programs against the JCL that runs them, when a run
has both: JCL files are those named `*.jcl` or `*.prc` (see
[JCL](jcl.md)).

A step that runs a program of the run, where the program, or a program
it calls by literal name, opens a file whose DD the step does not have:

```
//RERUN    EXEC PGM=PAYUPD
//PAYMAST  DD DSN=PAY.MASTER,DISP=SHR
//PAYRPT   DD SYSOUT=*
```

Here PAYUPD calls PAYLOG, which opens `LOG-FILE ASSIGN TO PAYLOG`, and
the step has no `PAYLOG` DD. The `OPEN` fails when the step runs (file status 35 for input, or an
abend). The DD name is that of the file's `ASSIGN TO`, or its last part
for an IBM assignment name such as `UT-S-PAYLOG`. Files that are
`OPTIONAL`, sort files (`SD`), files no `OPEN` names, and files assigned
to a data item or a path are not checked. A step in a procedure also
has the DDs that job steps running the procedure add as `STEP.DDNAME`;
with no such job step in the run, the procedure's own DDs must do.

## PLB-J002 dd-unused

A DD of a step that no file of the step's programs is assigned to:

```
//RERUN    EXEC PGM=PAYUPD
//OLDFILE  DD DSN=PAY.OLD,DISP=SHR
```

when neither PAYUPD nor the programs it calls assign a file to
`OLDFILE`.

Such a DD is often left over from an earlier version of the program,
and allocating it can hold a data set for nothing; or the program was
meant to read it under that name. DDs the system and the runtime read
count as used: `STEPLIB`, `JOBLIB`, names starting with `SYS`, `CEE`,
or `SORT`, and the path of an alternate index (the file's DD name with a
digit at its end, `PAYMAST1` for `PAYMAST`). A step whose programs
assign a file to a name known only at run time is not checked.

## PLB-J003 program-not-in-run

*Off by default.* A step that runs a program the run does not have.
Most jobs also run utilities (`IDCAMS`, `SORT`, `IEBGENER`), so the rule
is for runs meant to hold every program of the jobs, to find a step
whose program is missing or misspelled. Steps running programs that
start others (`IKJEFT01` for DB2, `DFSRRC00` for IMS) are not
followed, since the program they run is named in their input.

## PLB-J004 dd-cannot-be-read

A file that the step's programs only open for input, whose DD gives it
nothing to read:

```
//NEWRATE  EXEC PGM=PAYUPD
//RATES    DD DSN=PAY.RATES,DISP=(NEW,CATLG)
```

`DISP=NEW` creates the data set in the step, so it is empty when the
program reads it: the first `READ` is at end. A `SYSOUT` DD is output
for the spool and cannot be read at all. `DD DUMMY`, which reads as an
empty file, is left alone: it is how a job leaves out an input on
purpose. Files that a program also opens for output, `I-O`, or `EXTEND`
are not checked.

## PLB-J005 temp-not-created

A step that reads a temporary data set that no earlier step of its job
creates:

```jcl
//COPY     EXEC PGM=IEBGENER
//SYSUT1   DD DSN=&&SORTED,DISP=(OLD,DELETE)
//         DD DSN=&&LOST,DISP=(OLD,DELETE)       <- reported
```

A temporary data set (`DSN=&&NAME`) exists from the step that creates
it to the end of the job. A `DD` that reads it (`DISP=OLD` or `SHR`)
before then ends the job with a JCL error. A step creates it with
`DISP=NEW`, `DISP=MOD`, or no `DISP`. In a procedure, the earlier steps
are those of the procedure.

A job that runs a procedure before the step is not checked, since the
procedure's steps may create the data set, nor is a `DD` that a job adds
to a step of a procedure (`PSTEP.DDNAME`). Every data set of a
concatenation is checked.

## PLB-J006 lrecl-mismatch

A DD whose record length is not that of the records of the file the
step's program assigns to it:

```jcl
//UPDATE   EXEC PGM=PAYUPD
//RATES    DD DSN=PAY.RATES,DISP=SHR,DCB=(RECFM=FB,LRECL=81)   <- reported
```

when `PAYUPD`'s `FD` for the file `RATES` has 80-byte records. On z/OS
the `OPEN` then fails with file status 39, a conflict between the data
set's attributes and the program's. The record length is
the largest `01` record under the file's `FD`. With a fixed format
(`RECFM=F`, `FB`), `LRECL` must equal it; with a variable one (`V`,
`VB`), `LRECL` must be at least that and 4 bytes for the record
descriptor. With ASA control characters (`FBA`, `VBA`), one more byte
for the character is right too, as a program writing with `ADVANCING`
needs it under the `ADV` compiler option.

`LRECL` and `RECFM` are read as keywords of the DD or from `DCB=( )`.
A DD without `RECFM`, with `RECFM=U`, or with a symbol for `LRECL` is
not checked, nor is a sort file.


## PLB-J007 dataset-created-twice

A DD that creates and catalogs a data set (`DISP=(NEW,CATLG)` or
`DISP=(,CATLG)`) that an earlier DD of the same job or procedure
already created and cataloged, with no DD in between that deletes or
uncatalogs it:

```
//EXTRACT  EXEC PGM=IEBGENER
//SYSUT2   DD DSN=PROD.ACCT.EXTRACT,DISP=(NEW,CATLG,DELETE)
//RESORT   EXEC PGM=SORT
//SORTOUT  DD DSN=PROD.ACCT.EXTRACT,DISP=(NEW,CATLG,DELETE)
```

The data set already exists when the later step asks for a new one, so
that step fails with a duplicate name, or makes the data set and
cannot catalog it (`NOT CATLGD 2`), leaving a copy the next job will
not find. Jobs that rebuild a data set delete it first, usually in an
`IEFBR14` step with `DISP=(MOD,DELETE)`.

Temporary data sets, generations of a GDG (`NAME(+1)`), and names with
symbols (`&HLQ..NAME`), which another call of a procedure may give
another value, are not compared. `IF` and `COND` are not followed: a
step that runs only when another does not is still counted.

## PLB-J008 cond-step-unknown

A `COND` test on an `EXEC` statement, or an `IF` statement, that names
a step which is not an earlier step of the same job:

```jcl
//EXTRACT  EXEC PGM=ACCTEXT
//LOAD     EXEC PGM=ACCTLOAD,COND=(4,LT,EXTRCT)          reported
//BACKUP   EXEC PGM=ACCTBKUP,COND=(0,NE,REPORT)          reported
//REPORT   EXEC PGM=ACCTRPT
//CHECK    IF (EXTRACT.RC > 4 OR REPORT.RC > 4) THEN     reported
```

The step named has no return code to compare when the test is made:
there is no such step, or it runs later. The test then does not do
what was meant, and the step may run (or be skipped) when it should
not. This is what a step renamed, removed, or moved leaves behind.

In a procedure, the step must be an earlier step of the procedure. In
`COND=(code,op,STEP.PROCSTEP)` the job step is checked. Tests without
a step name, `EVEN` and `ONLY`, and names with symbols (`&STEP`) are
left alone. In an `IF`, each `STEP.RC`, `STEP.ABEND`, `STEP.ABENDCC`,
and `STEP.RUN` is checked against the steps before the `IF`; `RC` and
`ABEND` alone name no step.

## PLB-J009 referback-unresolved

A backward reference of a DD statement, in `DSN=`, `DCB=`, `VOL=REF=`,
or `REFDD=`, that names a step which does not run before it, or a DD
the step does not have:

```jcl
//EXTRACT  EXEC PGM=ACCTEXT
//OUT      DD DSN=&&EXTRACT,DISP=(NEW,PASS)
//SORT     EXEC PGM=SORT
//SORTIN   DD DSN=*.EXTRCT.OUT,DISP=(OLD,DELETE)       reported
```

The system cannot resolve the reference, and the job fails with a JCL
error before any step runs. `*.DD` must name a DD before it in the same
step, `*.STEP.DD` a DD of an earlier step of the same job (or
procedure). Through a procedure step (`*.STEP.PROCSTEP.DD`) only the
step is checked, since procedures are not expanded.

A `DSN=` reference that resolves takes the data set name of the DD it
names, so the other JCL rules, `dump jcl`, and the data set graphs see
the data set itself rather than `*.STEP.DD`.

## PLB-J010 dsn-invalid

A `DSN=` name that z/OS does not accept as a data set name:

```jcl
//MASTER   DD DSN=PROD.CUSTOMER.2024JAN,DISP=SHR          reported
//HISTORY  DD DSN=PROD.CUSTOMERS.HISTORY,DISP=SHR         reported
```

A data set name is at most 44 characters, in qualifiers of 1 to 8
characters joined by periods. Each qualifier starts with a letter or a
national character (`#`, `@`, `$`) and goes on with letters, digits,
national characters, and hyphens. `2024JAN` starts with a digit and
`CUSTOMERS` has nine characters: the job fails with a JCL error before
any step runs. The rule reports the first problem of each name.

A member or generation in parentheses (`LIB(PAYROLL)`, `TOTALS(+1)`) is
not part of the name. Names the system resolves or substitutes are not
checked: temporary data sets (`&&WORK`), symbols (`&HLQ..MASTER`, and
the `%%` variables of job schedulers), backward references (`*.DD`),
quoted names, and `NULLFILE`.
## PLB-J011 dd-name-repeated

A DD name that a step has twice, not as a concatenation:

```jcl
//POST     EXEC PGM=CBTRN02C
//TRANFILE DD DSN=PROD.TRANSACT.DAILY,DISP=SHR
//XREFFILE DD DSN=PROD.CARDXREF,DISP=SHR
//TRANFILE DD DSN=PROD.TRANSACT.BACKUP,DISP=SHR          reported
```

The system allocates both DD statements and disposes of both as their
`DISP` says, but directs every reference to the first: the program
reads or writes the first one's data set, and the second's, often the
one meant, is never used (a `NEW` one is created empty). A DD with no
name of its own after one with the name is a concatenation, and is not
reported; nor are overrides of different procedure steps
(`STEP.DDNAME`).

## PLB-J012 read-after-delete

A DD that reads a data set (`DISP=OLD` or `SHR`) that an earlier DD of
the same job, or procedure, deleted or uncataloged, with no DD in
between that creates it again:

```jcl
//CLEANUP  EXEC PGM=IEFBR14
//OLDEXT   DD DSN=PROD.ACCT.EXTRACT,DISP=(OLD,DELETE)
//REPORT   EXEC PGM=ACCTRPT
//INPUT    DD DSN=PROD.ACCT.EXTRACT,DISP=SHR              reported
```

When the step comes, the data set is gone, and the job ends with a JCL
error at that step. A DD creates a data set when its `DISP` is `NEW`
or `MOD`, or left out. Temporary data sets
([PLB-J005](#plb-j005-temp-not-created) checks those), generations, and
names with symbols are not compared, as for
[PLB-J007](#plb-j007-dataset-created-twice). Steps that may not run
(`COND`, `IF`) are counted as running.


## PLB-J013 shr-for-output

A sequential file that a step's program opens `OUTPUT` or `EXTEND`,
through a DD with `DISP=SHR`:

```
//UPDATE   EXEC PGM=PAYUPD
//PAYRPT   DD DSN=PAY.REPORT,DISP=SHR           <- reported
```

`SHR` lets other jobs read, or write, the data set while the step
writes it, so a reader may see it half written. `DISP=OLD` (or `MOD`
to add to it) keeps it to the step. Indexed and relative files, which
VSAM shares by its own options and CICS may hold open, are left alone,
and so are files opened `I-O`.

## PLB-J014 output-deleted

A data set that a step's program writes (`OUTPUT`, `EXTEND`, or
`I-O`), whose DD deletes it when the step ends:

```
//REPORT   EXEC PGM=PAYUPD
//PAYRPT   DD DSN=PAY.REPORT,DISP=(NEW,DELETE,DELETE)   <- reported
```

The second `DISP` subparameter is what happens when the step ends
well: `DELETE` throws away what the program wrote. `CATLG` or `KEEP`
was meant, or `PASS` for a later step. Temporary data sets (`&&NAME`),
which go at the end of the job anyway, are left alone.
## PLB-J015 step-name-repeated

Two steps of one job, or of one procedure, with the same name:

```
//EXTRACT  EXEC PGM=ACCTEXT
//SORT     EXEC PGM=SORT
//EXTRACT  EXEC PGM=ACCTRPT                    reported
```

`COND` and `IF` tests, backward references (`*.EXTRACT.OUT`), restarts
(`RESTART=EXTRACT`), and the job's messages name a step by its name,
and cannot tell two steps of one name apart. Usually a step was copied
and not renamed. Steps without a name are not compared; a procedure's
steps are compared among themselves, not with those of the job that
runs it, and steps of different jobs are not compared.

## PLB-J016 utility-dd-missing

A job step that runs an IBM utility without a DD statement the utility
reads or writes by name:

```
//COPY     EXEC PGM=IEBGENER                    reported: no SYSIN,
//SYSUT1   DD DSN=PAY.INPUT,DISP=SHR             no SYSPRINT
//SYSUT2   DD DSN=PAY.COPY,DISP=(NEW,CATLG)
```

`IEBGENER` copies `SYSUT1` to `SYSUT2`, takes its control statements
from `SYSIN` (`DD DUMMY` when there are none), and writes its messages
to `SYSPRINT`. `IDCAMS` takes its commands from `SYSIN`, and the TSO
batch program `IKJEFT01` (and `IKJEFT1A`, `IKJEFT1B`), which runs DB2
programs, its commands from `SYSTSIN`. A step without them fails.

Read are steps of a job that run the program themselves. A procedure's
steps can get their DD statements from the job that runs the procedure
(`//GEN.SYSUT2 DD ...`), and are not read.

## PLB-J017 blksize-invalid

A DD whose `BLKSIZE` does not fit its `RECFM` and `LRECL`:

```
//OUT      DD DSN=PAY.COPY,DISP=(NEW,CATLG),       reported
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27900)
```

A block of fixed blocked records (`FB`) holds whole records, so its
size must be a multiple of `LRECL`; for fixed unblocked records (`F`)
it equals `LRECL`; for variable records (`V`, `VB`, not spanned) it is
at least `LRECL` + 4, the 4 bytes of the block descriptor word. With
another, the data set cannot be opened; for fixed records the `OPEN`
abends with 013-34. Read are DDs that give `RECFM`, `LRECL`, and a
`BLKSIZE` other than 0, which lets the system choose one (the best
choice, unless a block size is needed for a reason).

## PLB-J018 gdg-generation-not-created

A DD that reads a new generation of a generation data group
(`NAME(+1)`, with `DISP=OLD` or `SHR`) that no earlier step of its job,
or procedure, creates:

```
//REPORT   EXEC PGM=PAYRPT
//IN       DD DSN=PAY.HISTORY(+1),DISP=SHR         reported
```

Relative generation numbers are fixed when the job starts: `(+1)` is
the generation a step of this job creates, and `(0)` the newest one
cataloged before the job. Read before any step creates it, `(+1)` does
not exist, and the step fails (data set not found); usually `(0)` was
meant. Read as [PLB-J005](#plb-j005-temp-not-created) reads temporary
data sets: a step that runs a procedure before the DD may create the
generation, and the DD is not read; nor are names with symbols
(`&HLQ..HISTORY(+1)`), or a DD a job adds to a procedure's step.

## PLB-J019 parm-too-long

A step whose `PARM` passes the program more than 100 characters:

```jcl
//REPORT   EXEC PGM=PAYRPT,PARM='...101 characters...'   reported
```

z/OS takes at most 100 characters in the `PARM` of an `EXEC` statement
([Character limits for the JCL PARM
parameter](https://www.ibm.com/docs/en/wdfrhcw/1.4.0?topic=builds-parm-parameter-character-limits)),
so the job ends with a JCL error before the step runs. Since z/OS 2.1,
`PARMDD` names a DD whose data set passes up to 32760.

The count is taken after continuation lines are joined, and leaves out
the apostrophes or parentheses that enclose the `PARM`, the
apostrophes around each part of `PARM=('A','B')`, and counts a doubled
apostrophe once, so it is never more than what the program would be
passed. A `PARM` with a symbol (`&`) is not counted, nor one on a step
that runs a procedure. `plumbline dump jcl` shows the count of each
step as `parm N`.

## PLB-J020 jcl-name-invalid

A JCL statement whose name z/OS does not accept:

```jcl
//EXTRACTSTEP EXEC PGM=PAYEXT       reported: 11 characters
//1COPY    EXEC PGM=IEFBR14          reported: starts with a digit
//PAY-IN   DD DSN=PAY.INPUT,DISP=SHR reported: a hyphen
```

The name in the name field, of a `JOB`, `EXEC`, `DD`, `PROC`, or any
other statement, is 1 through 8 alphanumeric or national (`$`, `#`,
`@`) characters, and the first is alphabetic or national (z/OS MVS JCL
Reference, "Name field"). In a `STEP.DDNAME` override, each part is
such a name. A name that breaks this ends the job with a JCL error
before any step runs. Names with a symbol (`&`) are not checked.

The program of `EXEC PGM=` and the procedure of `EXEC PROC=` (or `EXEC
name`) are checked the same way, as member names, without a dot:

```jcl
//EXTRACT  EXEC PGM=PAYEXTRACT1       reported: 11 characters
```

`PGM=*.STEP.DD`, a backward reference to a DD that names the program,
is not checked.

## PLB-K001 cics-resource-undefined

An `EXEC CICS` command that names a file, transaction, program, mapset,
or transient data queue that the CICS resource definitions of the run
do not define:

```cobol
    EXEC CICS RETURN TRANSID('ORD9') END-EXEC
```

The command fails when it runs (`FILENOTFOUND`, `PGMIDERR`, `INVREQ`,
`QIDERR`), often only on the path that is tested least. The rule needs
the definitions: DFHCSDUP input among the inputs, as `*.csd` files (see
[CICS](cics.md)). It checks `FILE` and `DATASET`, `TRANSID`, `PROGRAM`
of `XCTL`, `LINK`, and `LOAD`, `MAPSET`, and the `QUEUE` of `WRITEQ TD`
and `READQ TD`, when the name is a literal or a data item whose `VALUE`
is a literal and that no statement changes. A program of the run counts
as defined, since CICS may install it by autoinstall. Resources that
CICS supplies are left out: queues whose names start with `C` (`CSSL`,
`CSMT`) and programs whose names start with `DFH` or `CEE`.

## PLB-K002 read-update-not-released

An `EXEC CICS READ ... UPDATE` of a file that the program never
rewrites, deletes, or unlocks:

```cobol
    EXEC CICS READ DATASET(WS-TRANSACT-FILE)    *> reported
         INTO(TRAN-RECORD) RIDFLD(TRAN-ID) UPDATE
         RESP(WS-RESP-CD)
    END-EXEC
```

`UPDATE` takes an exclusive lock on the record, which CICS holds until
`REWRITE`, `DELETE`, or `UNLOCK` of the file, or to the end of the task
or the next `SYNCPOINT`. Other tasks that read the record for update
wait meanwhile. A program that reads a record only to show it needs no
`UPDATE`.

The file is the operand of `FILE( )` or `DATASET( )`, compared as
written, and the statements are paired within a program in any order:
a `REWRITE FILE(WS-ACCT-FILE)` anywhere releases a `READ
FILE(WS-ACCT-FILE) UPDATE`. A program that names the same file in two
ways (a literal and a variable holding it) is reported.


## PLB-K003 commarea-without-length

A transaction program that uses `DFHCOMMAREA` but never looks at
`EIBCALEN`:

```cobol
LINKAGE SECTION.
01  DFHCOMMAREA.
    05  CA-ACCOUNT-ID       PIC X(11).
PROCEDURE DIVISION.
    MOVE CA-ACCOUNT-ID TO WS-ACCOUNT-ID     *> reported
    ...
    EXEC CICS RETURN TRANSID('AVIW') COMMAREA(WS-STATE) END-EXEC.
```

The first time a user starts the transaction there is no COMMAREA:
`EIBCALEN` is 0 and `DFHCOMMAREA` has no storage, so the first
reference abends the task or reads whatever is at that address. Test
`EIBCALEN = 0` first and set the state up instead.

Transaction programs are those that return with `EXEC CICS RETURN
TRANSID`, the pseudo-conversational return that has the terminal start
them again; a program only `LINK`ed or `XCTL`ed to with a COMMAREA
always has one, and is not checked. Any mention of `EIBCALEN` in the
program counts as the test, and the program's first use of the
COMMAREA or an item in it is reported. The text of nested programs is
their own.

## PLB-K004 commarea-length-too-long

An `EXEC CICS RETURN`, `XCTL`, `LINK`, or `START` whose `LENGTH` is more
than its `COMMAREA` (or `FROM`) item:

```cobol
    EXEC CICS XCTL PROGRAM('ACCTUPD')
        COMMAREA(WS-COMMAREA)               *> reported
        LENGTH(LENGTH OF WS-OLD-COMMAREA)
    END-EXEC
```

CICS copies `LENGTH` bytes from the item's address, so the bytes after
it, whatever items they belong to, become the end of the next
program's COMMAREA; past the end of working storage, the task can
abend. It usually happens when the COMMAREA layout shrinks and a
`LENGTH OF` still names the old item. Leaving `LENGTH` out lets CICS
take the item's own length.

A `LENGTH` that is a literal or `LENGTH OF` an item is checked; one in
a data item, items of variable size, and reference modification are
not.

## PLB-K005 batch-io-in-cics

A COBOL file statement (`OPEN`, `CLOSE`, `READ`, `WRITE`, `REWRITE`,
`DELETE`, `START`), or an `ACCEPT` of input, in a program with
`EXEC CICS` commands:

```cobol
    OPEN EXTEND AUDIT-FILE                  *> reported
    WRITE AUDIT-REC                         *> reported
    EXEC CICS RETURN END-EXEC.
```

CICS does not open COBOL files for its tasks, and a task has no SYSIN or
console to accept from: the statement fails or abends the task. A CICS
program reads and writes files with `EXEC CICS READ`, `WRITE`, and the
like, writes to a transient data queue instead of a log file, and takes
its input from the terminal or the COMMAREA. It is usually code moved
from a batch program. `ACCEPT ... FROM DATE`, `DAY`, `DAY-OF-WEEK`, and
`TIME` only read the clock, and are fine.

A program counts as a CICS program when its own text has an `EXEC
CICS` command; programs nested in it are checked on their own.
## PLB-K006 return-transid-without-commarea

A pseudo-conversational `RETURN` that names the next transaction but
passes no `COMMAREA`, in a program that receives one:

```cobol
LINKAGE SECTION.
01  DFHCOMMAREA          PIC X(100).
    ...
    EXEC CICS RETURN TRANSID('ACCT') END-EXEC     *> reported
```

The next task of the conversation starts with `EIBCALEN` 0, as on a
first entry from the terminal: the program sets its state up again,
and the user's place in the conversation is lost. A program receives a
`COMMAREA` when it declares `DFHCOMMAREA` in its `LINKAGE SECTION`; a
`RETURN` without `TRANSID`, which ends the conversation, is not
reported, nor is one in a program nested in it without `DFHCOMMAREA`.

## PLB-K007 commarea-too-short

An `EXEC CICS XCTL` or `LINK` that passes a COMMAREA shorter than the
`DFHCOMMAREA` of the program it names:

```cobol
    EXEC CICS XCTL PROGRAM('ACCTUPD') COMMAREA(WS-KEY) END-EXEC   *> reported
    ...
PROGRAM-ID. ACCTUPD.
LINKAGE SECTION.
01  DFHCOMMAREA         PIC X(200).
```

The program reads its `DFHCOMMAREA` past the bytes it was given, into
storage that belongs to something else. The bytes passed are the
`LENGTH` when it is a number or `LENGTH OF` an item, else the size of
the `COMMAREA` item. The program must be named by a literal or a
constant item, and be a program of the run whose `DFHCOMMAREA` has a
fixed size: one declared `OCCURS ... DEPENDING ON EIBCALEN`, which
takes the length passed, is not checked.

## PLB-K008 cics-name-too-long

An `EXEC CICS` command that names a resource with a literal longer than
names of its kind are:

```cobol
    EXEC CICS RETURN TRANSID('ACCTU') END-EXEC     *> reported: 5
```

A transaction is named with 1 to 4 characters; a program, and a file
(`FILE` or `DATASET`), with 1 to 8; a BMS map and mapset with 1 to 7.
No resource has a longer name, so the command finds none, and CICS
raises a condition (`INVREQ`, `PGMIDERR`, `FILENOTFOUND`, `MAPFAIL`)
that abends the task unless the program handles it. Usually a name was
typed with a character too many, or a test system's name was left in.
Read are literals without a prefix; their trailing spaces do not count.

## PLB-K009 browse-not-active

A CICS browse command for a file whose browse is not active, or a
second `STARTBR` while one is:

```cobol
    EXEC CICS ENDBR FILE('ACCTDAT') END-EXEC
    EXEC CICS READNEXT FILE('ACCTDAT') INTO(WS-REC)
        RIDFLD(WS-KEY) END-EXEC                    *> reported
```

After `ENDBR`, a `READNEXT`, `READPREV`, `RESETBR`, or `ENDBR` of the
file before a `STARTBR` of it has no browse to act on; after
`STARTBR`, another `STARTBR` of the file before its `ENDBR` starts one
that is already active. CICS rejects the command with `INVREQ`, which
abends the task unless the program handles it.

The statements after the `ENDBR` or `STARTBR` are read in their list
(for a statement directly in a sentence, on through the paragraph's
later sentences). A `STARTBR` or `ENDBR` of the file ends the search,
as do a `PERFORM` of a procedure, `GO TO`, `CALL`, `GOBACK`, `STOP`,
`EXIT`, and a statement holding other CICS commands. Files are compared
by what `FILE` or `DATASET` names, as written; commands with a
`REQID`, which runs several browses of one file at once, are not read.

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

## PLB-M004 alnum-narrowing

*Off by default; enable with `--enable alnum-narrowing`.*

A `MOVE` from an alphanumeric, edited, or group item into a smaller
alphanumeric or group item. The rightmost characters are lost. This is
often intended, for example when moving a field out of a large input
buffer, so the rule reports notes and does not run unless asked. Turn it
on when reviewing record layouts or when a truncation bug is suspected.

## PLB-M005 set-never-read

An item that the program gives values to but never reads, nor reads any
storage it shares:

```cobol
01  WORK-TOTAL      PIC 9(7).
    MOVE AMOUNT TO WORK-TOTAL      *> reported: nothing reads WORK-TOTAL
```

Usually the item is left over from earlier code, or the read that should
use it is reading something else. The rule is a note by default.

## PLB-M006 dynamic-call

A `CALL` of the program named in a data item:

```cobol
    CALL ROUTINE-NAME USING ORDER-ID       *> reported when enabled
```

Plumbline cannot tell which program such a call reaches, so the call
rules do not check it. Enable this rule to list the calls that are left
unchecked.

## PLB-M007 detail-never-generated

A detail group (`TYPE DETAIL`) with a name that no `GENERATE` names, in
a report that is never generated as a whole:

```cobol
01  ERROR-LINE TYPE DE LINE PLUS 1.   *> reported
```

The group is either left over or meant to be generated somewhere it is
not. Groups without names cannot be generated on their own and are not
reported.

## PLB-M008 file-not-closed

A file that the program opens but never closes:

```cobol
    SELECT LOG-FILE ASSIGN TO "LOG"          *> reported
    ...
    OPEN EXTEND LOG-FILE
```

Most runtimes close files when the run ends, but the last records of an
unclosed output file can be lost when a program is called rather than
run, and the file stays locked for others.

## PLB-M009 complex-paragraph

A paragraph or section whose complexity, as `plumbline metrics` reports
it, is above the limit (15 by default):

```
paragraph CHECK-CLAIM has complexity 23 (limit 15)
```

Complexity counts the paths through the code. The more there are, the
harder the paragraph is to test and change. Splitting it into
paragraphs that each make one decision usually helps. The rule is off
by default. A paragraph that dispatches through one long `EVALUATE` is
complex by this count but easy to read, so where the limit lies is a
choice each team makes.

## PLB-M010 long-paragraph

A paragraph or section with more statements than the limit (50 by
default):

```
paragraph PRINT-SUMMARY has 87 statements (limit 50)
```

Off by default, like PLB-M009.

## PLB-M011 evaluate-without-other

*Off by default.* An `EVALUATE` without `WHEN OTHER`:

```cobol
    EVALUATE STATUS-CODE                *> noted
        WHEN 1 DISPLAY "OPEN"
        WHEN 2 DISPLAY "CLOSED"
    END-EVALUATE
```

A value that no `WHEN` matches does nothing, silently. Often that is
what was meant, so the rule is for teams whose convention is that
every `EVALUATE` says what happens to the other values, if only
`WHEN OTHER CONTINUE`.

## PLB-M012 deep-nesting

*Off by default.* A statement whose body nests statements deeper than
the limit (5 by default):

```
IF nests statements 6 levels deep (limit 5)
```

A statement inside an `IF` inside another `IF` is at level 2. Every
statement with a body counts: `IF`, `EVALUATE`, `SEARCH`, inline
`PERFORM`, and the phrases of `READ ... AT END` or `ADD ... ON SIZE
ERROR`. The finding is at the outermost statement of the paragraph,
once, however many statements inside it go too deep. Moving the inner
levels into a paragraph of their own, or testing the exceptional cases
first and leaving, usually flattens the code. Like the size limits,
where the limit lies is a team's choice: `limit deep-nesting N` in
`plumbline.conf` changes it.

## PLB-M013 unused-copybook

A `COPY` in working-storage or local-storage whose copybook declares
data items, none of which the program uses:

```
none of the items copybook cvcus01y.cpy declares is used
```

The finding is at the `COPY` statement, so it can be suppressed there
for one program while the copybook stays in use elsewhere. Items count
as used as for [PLB-M003](#plb-m003-unused-data-item): by name in the
procedure division or the environment division, through a member, a
group, a condition name, or a `REDEFINES`. A constant (level 78) also
counts as used when the data division sizes an item with it (`OCCURS
ADDRESS-LINES`, `PIC X(NAME-LEN)`).

A copybook that only copies other copybooks is judged by them. One
that holds anything else is not reported: file or linkage entries,
`GLOBAL` or `EXTERNAL` items, or code.

## PLB-M014 sql-select-star

`SELECT *` in embedded SQL, in a statement, in a `DECLARE CURSOR` (also
one in working-storage), or in `INSERT ... SELECT`:

```cobol
    EXEC SQL DECLARE ALL-EMP CURSOR FOR
        SELECT * FROM EMPLOYEE              *> noted
    END-EXEC.
```

The host variables of `INTO` or `FETCH` must match the table's columns
one for one, in order. With `SELECT *` they do so only until a column
is added, and nothing in the program says which columns it reads.
Name the columns. `COUNT(*)` is not reported.

## PLB-M015 packed-even-digits

*Off by default.* A packed-decimal item (`COMP-3`, `PACKED-DECIMAL`)
with an even number of digits:

```
TOTAL is packed with 4 digits; 5 take the same bytes
```

Packed decimal stores two digits a byte, with the sign in the last half
byte, so `PIC S9(4) COMP-3` takes the same 3 bytes as `PIC S9(5)`, and
its first half byte is unused. IBM compilers generate extra code to
keep that half byte zero, and data written by another program can
hide a digit there that the picture does not show. Many shops' coding
standards ask for odd digit counts; the rule is for them.

## PLB-M016 signed-to-alphanumeric

A `MOVE` of a signed integer to an alphanumeric item:

```cobol
01  BALANCE             PIC S9(7).
01  TEXT-OUT            PIC X(10).
    MOVE BALANCE TO TEXT-OUT                *> reported, when enabled
```

Only the digits are moved: `-500` and `500` both give `0000500`. When
the value can be negative, move it to a numeric-edited item with a sign
(`PIC -(6)9`) first. Most signed items moved to text (record counts,
CICS response codes) are never negative, which is why the rule is off
by default; enable it with `--enable signed-to-alphanumeric`.

## PLB-M017 two-digit-year

`ACCEPT ... FROM DATE` and `ACCEPT ... FROM DAY` without the four-digit
forms:

```cobol
    ACCEPT CURRENT-DATE     FROM DATE       *> reported: YYMMDD
    ACCEPT CURRENT-YYDDD    FROM DAY        *> reported: YYDDD
    ACCEPT TODAY            FROM DATE YYYYMMDD
```

The year comes in two digits, so dates kept that way order and
subtract wrongly across a century, and a Julian date (YYDDD) subtracts
wrongly across any new year: 26001 minus 25365 is 636, not one day.
`FROM DATE YYYYMMDD` and `FROM DAY YYYYDDD` give four digits;
`FUNCTION INTEGER-OF-DATE` turns a date into a day number to subtract.
A program that only shows the date can leave it, which is why the rule
is a note.


## PLB-M018 signed-to-unsigned

Off by default; turn it on with `--enable signed-to-unsigned` or in
`plumbline.conf`. A `MOVE` of a signed number to an unsigned numeric
item:

```cobol
01  WS-ADJUSTMENT      PIC S9(5)V99.
01  WS-REPORT-AMOUNT   PIC 9(5)V99.
    MOVE WS-ADJUSTMENT TO WS-REPORT-AMOUNT     *> reported
```

The receiver keeps the absolute value: an adjustment of -12.50 becomes
12.50, a refund a charge. Give the receiver a sign, or an edited
picture with one (`-ZZZZ9.99`), or test the sign before the move.

Most signed items moved this way are identifiers and codes that are
never negative but were declared signed out of habit, which is why the
rule is off unless asked for: on the corpora it reports 91 moves in the
NIST suite, 8 in GnuCOBOL's tests, and 107 in CardDemo (packed account
ids, MQ completion codes). Turned on for a program that handles money,
it finds the moves to look at.

## PLB-M019 commented-out-code

Off by default. Comment lines that are COBOL statements rather than
prose:

```cobol
      *    MOVE WS-OLD-RATE TO WS-RATE
      *    PERFORM 300-APPLY-DISCOUNT.
```

Code kept in comments is never compiled and soon wrong: the names it
uses are renamed and the logic around it changes, and each reader has
to make out whether it still matters. Version control keeps old code.

A comment line counts when its text starts with a statement's verb, has
no lower-case letters, has a hyphenated name or a period at its end,
and has at most one plain word (one that is not a reserved word of the
statement, a hyphenated name, a number, or in a literal), so that
`MOVE OLD VALUES TO NON-DISPLAY FIELDS` reads as prose. A run of such
lines, with up to two blank or other comment lines between them, is
reported once at its first line. Only the program's own lines are read,
not its copybooks'. Enabled, it notes 69 runs in CardDemo; NIST's
programs keep many variants of their tests in comments (1,579 runs).

## PLB-M020 constant-condition

A relation condition between two constants, literals or figurative
constants:

```cobol
    IF 1 = 1                                        *> reported
        PERFORM 900-TRACE
    END-IF
```

Its result is fixed when the program is written, so the branch always
runs or never does. It is usually left from testing, or a way to
switch code off that reads as if it were a decision. When both sides
are numbers, both alphanumeric literals (compared as COBOL compares
them, the shorter padded with spaces), or the same figurative
constant, the message says whether the condition is always true or
always false. A side that is part of an arithmetic expression is not a
constant.

## PLB-M021 empty-branch-statement

An `IF` without `ELSE`, or an `EVALUATE`, whose every branch is
`CONTINUE` or empty:

```cobol
    IF WS-CODE = "A"                        *> reported
        CONTINUE
    END-IF
```

The statement does nothing, as a condition changes no data. It is
usually what is left after code was taken out, or the branch that was
to act is missing. An `IF` with `CONTINUE` in one branch and statements
in the other is the usual way to write a negated test, and is not
reported, nor is `NEXT SENTENCE`, which goes somewhere. An `IF` whose
`ELSE` is `CONTINUE` too is reported by
[PLB-C066](#plb-c066-identical-branches). A condition, subject, or
`WHEN` that calls a `FUNCTION` may act (`FUNCTION RANDOM` moves its
seed), and the statement is not reported.

## PLB-M022 mixed-and-or

A condition that joins relations with both `AND` and `OR` at one level
of parentheses:

```cobol
    IF WS-TYPE = "A" OR WS-TYPE = "B" AND WS-AMOUNT > 0   *> reported
```

`AND` is evaluated before `OR`, so this is `WS-TYPE = "A" OR (WS-TYPE =
"B" AND WS-AMOUNT > 0)`: an `"A"` passes with any amount. Readers take
such a condition either way, and so do the people who change it;
parentheses say which is meant, as C compilers ask with
`-Wparentheses`. Each level of parentheses is read on its own, and one
condition is reported once. The `OR` of `GREATER OR EQUAL` and `LESS
OR EQUAL` is no join, and `ALSO` (in `EVALUATE`) and the `UNTIL`,
`AFTER`, and `VARYING` phrases of a `PERFORM` start another condition.
## PLB-P001 vendor-routine

*Off by default.* A CALL of a library routine that comes with some
compilers and not others:

```cobol
    CALL "CBL_DELETE_FILE" USING ITEM-PATH          *> noted
    CALL "C$SLEEP" USING 1                          *> noted
```

Routines named `CBL_...` come from Micro Focus COBOL, `C$...` from
ACUCOBOL; GnuCOBOL provides many of both, IBM Enterprise COBOL few.
`SYSTEM` is noted too. Programs built with one compiler call its library
on purpose, so the rule only runs on request, for code meant to move.
Where such calls are needed, keep them in a few small programs that a
port can replace.

## PLB-P002 hard-coded-path

A file assigned to a path, written into the SELECT or into the VALUE of
the item it is assigned to:

```cobol
    SELECT IN-FILE ASSIGN TO "/var/data/in.dat".    *> reported
    SELECT OUT-FILE ASSIGN TO "C:\DATA\OUT.DAT".      *> reported
    SELECT WORK-FILE ASSIGN TO DYNAMIC WORK-PATH.   *> reported when
01  WORK-PATH  PIC X(40) VALUE "../tmp/work.dat".   *> the VALUE is a path
    SELECT DD-FILE ASSIGN TO "INFILE".              *> fine
```

A path names a place on one machine, in its operating system's syntax.
A bare name is resolved when the program runs, by a DD statement on
z/OS or an environment variable (`DD_INFILE`, `dd_INFILE`, `INFILE`)
with GnuCOBOL, so the same program reads a different file in test and
in production. Text with a `/` or `\`, or that starts with a drive letter
(`C:`), is a path. A path the program builds at run time is not seen.

## PLB-Q001 sql-table-undeclared

A table that a program uses in embedded SQL without declaring it:

```
table PAY.HISTORY is not declared in TABLES (EXEC SQL DECLARE ... TABLE, or its DCLGEN INCLUDE)
```

`EXEC SQL DECLARE name TABLE (...)`, which DCLGEN writes for each table
and programs bring in with `EXEC SQL INCLUDE`, lets the DB2
precompiler check each statement's columns against the table. Without
it a misspelled column, or a column dropped from the table since, is
found only when the program is bound or the statement runs. The rule
finds tables after `FROM` and `JOIN` (every table of a `FROM` list),
`INSERT INTO`, `UPDATE`, `DELETE FROM`, and `MERGE INTO`, and reports each
table once per program, at its first use. The catalog tables of DB2
(`SYSIBM.*`) are left out. `dump calls` and `inventory` list the
tables each program uses.

## PLB-Q002 cursor-not-closed

A cursor the program opens but never closes:

```cobol
    EXEC SQL OPEN C-LEFT-OPEN END-EXEC      *> reported
    EXEC SQL FETCH NEXT FROM C-LEFT-OPEN INTO :WS-ORDER-ID END-EXEC
```

The cursor keeps its position, and in DB2 its locks, until the unit of
work ends; a cursor declared `WITH HOLD` survives a `COMMIT` too. The
next `OPEN` of it fails with SQLCODE -502 (cursor already open), which
a program run again in the same unit of work, such as a CICS
transaction calling it twice, meets. A `COMMIT` or `ROLLBACK` closes a
cursor without `WITH HOLD`, so a program that relies on that can
suppress the finding and say so.

## PLB-Q003 cursor-not-opened

A cursor the program fetches or closes but never opens:

```cobol
    EXEC SQL FETCH FIRST FROM C-NEVER-OPENED INTO :WS-ORDER-ID
    END-EXEC                                *> reported
```

The `FETCH` fails with SQLCODE -501 (cursor not open). Cursors are
those declared in the file (`EXEC SQL DECLARE name ... CURSOR`, in any
division), and their `OPEN`, `FETCH`, and `CLOSE` statements are found
anywhere in the file, in the order of the source or not.

## PLB-Q004 sql-no-where

An embedded `UPDATE` or `DELETE` without `WHERE`:

```cobol
    EXEC SQL UPDATE ORDERS SET STATUS = 'C' END-EXEC     *> reported
```

It changes every row of the table. That is sometimes meant, a reset
of a work table, and then suppressing the finding says so; more often
the `WHERE` was lost in an edit. A `WHERE` inside parentheses, in a
subquery, does not count: `UPDATE ORDERS SET STATUS = (SELECT ...
WHERE ...)` still changes every row. `WHERE CURRENT OF cursor` counts.


## PLB-Q005 into-count-mismatch

A `FETCH`, or a `SELECT ... INTO`, whose `INTO` list has another number
of host variables than the select list has columns:

```cobol
    EXEC SQL DECLARE ACCT-CUR CURSOR FOR
        SELECT ACCT_ID, ACCT_NAME, COALESCE(BALANCE, 0)
          FROM ACCOUNT
    END-EXEC.
    EXEC SQL FETCH ACCT-CUR INTO :WS-ID, :WS-NAME END-EXEC  *> reported
```

With fewer host variables than columns, DB2 sets `SQLWARN3` and the
statement otherwise succeeds: a program that tests only `SQLCODE` goes
on without the columns it dropped, usually ones added to the query
later. With more, the statement is in error.

Commas are separators to COBOL, so the lists are counted from the
source text between their tokens, by the commas outside parentheses. A
host variable with its indicator (`:HV :IND`, `:HV INDICATOR :IND`) is
one, and so is a `VARCHAR` host variable (a group of level-49 items).
A cursor is matched by name with its `DECLARE` anywhere in the file.
Select lists with `*` at their top level, cursors for prepared
statements, and host structures (another group item, which stands for
its fields) are not counted.

## PLB-Q006 host-variable-too-small

A `FETCH`, or a `SELECT ... INTO`, that puts a column into a host
variable too small for the column's values, by the column's type in
the `DECLARE TABLE` of the file (a DCLGEN copybook, usually):

```cobol
    EXEC SQL DECLARE BANK.ACCOUNT TABLE
    ( ACCT_ID          DECIMAL(11, 0) NOT NULL,
      ACCT_NAME        VARCHAR(40) NOT NULL ...
01  WS-SHORT-ID        PIC S9(7) COMP-3.
    EXEC SQL SELECT ACCT_ID INTO :WS-SHORT-ID ...   *> reported
```

A character value longer than the host variable is cut, with only
`SQLWARN1` to say so; a number with more integer digits than the host
variable has makes the statement fail (`SQLCODE -304`); decimal places
the host variable lacks are cut. It usually follows a change to the
table that the program's own copy of the layout missed.

Compared are `CHAR` and `VARCHAR` columns with alphanumeric host
variables, or VARCHAR structures (two items of level 49, the length
and the text); `DECIMAL` columns with numeric ones, by integer digits
and decimal places; and `SMALLINT`, `INTEGER`, and `BIGINT` with
numeric ones, which need 4, 9, and 18 digits when binary and 5, 10,
and 19 otherwise. A column is looked for in the statement's tables,
then in all declared tables, where its name must be unique. Select
items that are expressions, and other types, are not compared.

## PLB-Q007 host-variable-too-large

An `INSERT` or `UPDATE` that gives a column a host variable holding
values the column cannot take: more characters than a `CHAR` or
`VARCHAR` column (`SQLCODE -404` when a value is that long), more
integer digits than a `DECIMAL` column (`SQLCODE -302`), or more
decimal places, which are cut.

```cobol
01  WS-LONG-CITY       PIC X(25).
    EXEC SQL INSERT INTO BANK.ACCOUNT (CITY)
        VALUES (:WS-LONG-CITY) END-EXEC          *> CITY is CHAR(20)
```

An `INSERT` pairs its column list with its `VALUES`, an `UPDATE` each
`SET column = :host`; values that are not a host variable alone are
not compared. As for PLB-Q006, the types come from `DECLARE TABLE`.

## PLB-Q008 null-without-indicator

A `FETCH`, or a `SELECT ... INTO`, that puts a column declared without
`NOT NULL` into a host variable without an indicator variable:

```cobol
    EXEC SQL DECLARE BANK.CUSTOMER TABLE
    ( CUST_ID          INTEGER NOT NULL,
      PHONE            CHAR(15) ...
    EXEC SQL SELECT PHONE INTO :WS-PHONE ...     *> reported
```

A host variable cannot hold NULL; DB2 says a value is NULL through the
indicator (`:WS-PHONE :WS-PHONE-IND`, or `INDICATOR :WS-PHONE-IND`),
and without one the statement fails (`SQLCODE -305`) on the first row
where the column is NULL, which may be long after the program went
live. The column's nullability comes from the `DECLARE TABLE` of the
file, as for PLB-Q006; select items that are expressions are not
checked.

## PLB-Q009 update-of-read-only-cursor

An `UPDATE` or `DELETE ... WHERE CURRENT OF` a cursor whose declaration
has no `FOR UPDATE` clause:

```cobol
    EXEC SQL DECLARE READ-CUR CURSOR FOR
        SELECT ACCT_ID, BALANCE FROM ACCOUNT ORDER BY ACCT_ID
    END-EXEC.
    EXEC SQL UPDATE ACCOUNT SET BALANCE = :WS-BALANCE
        WHERE CURRENT OF READ-CUR END-EXEC          *> reported
```

Without `FOR UPDATE`, DB2 makes the cursor read-only when its query
orders, joins, or groups, and may when the plan is bound so; the
positioned statement then fails (`SQLCODE -510`). `FOR UPDATE OF` the
columns changed also takes update locks while fetching, so that
another task does not change the row between the `FETCH` and the
`UPDATE`. Cursors are matched by name with their `DECLARE` in the
file.

## PLB-Q010 cursor-undeclared

An `OPEN`, `FETCH`, or `CLOSE` of a cursor that no `DECLARE ... CURSOR`
in the file declares:

```cobol
    EXEC SQL DECLARE ORDER-CUR CURSOR FOR
        SELECT ORDER_ID FROM ORDERS
    END-EXEC.
    ...
    EXEC SQL OPEN ORDER-CUR END-EXEC
    EXEC SQL FETCH NEXT FROM ORDER-CURS                  *> reported
        INTO :WS-ORDER-ID END-EXEC
```

The precompiler rejects the program (`SQLCODE -504`), so this is most
often a misspelled name. The cursor of a `FETCH` is the word after
`FROM`, or else the first word that is not part of the fetch
orientation (`NEXT`, `ABSOLUTE :N`, ...). A cursor that
`ALLOCATE name CURSOR FOR RESULT SET` allocates is declared, and open,
from there.
## PLB-Q011 cursor-opened-in-loop

An `EXEC SQL OPEN` that runs on every pass of a loop, of a cursor the
loop never closes:

```cobol
    PERFORM UNTIL WS-DONE = "Y"
        EXEC SQL OPEN ACCT-CUR END-EXEC              *> reported
        EXEC SQL FETCH ACCT-CUR INTO :WS-ID END-EXEC
        ...
    END-PERFORM
    EXEC SQL CLOSE ACCT-CUR END-EXEC
```

The second `OPEN` of a cursor that is still open fails with SQLCODE
-502, and the loop goes on with the rows of the first. The loops and
the `OPEN` statements counted are those of
[PLB-C065](#plb-c065-open-in-loop), and an `EXEC SQL CLOSE` of the
cursor among the loop's statements, or in a procedure they perform,
closes it.

## PLB-Q012 fetch-after-commit

A loop that fetches from a cursor and commits, when the cursor is not
declared `WITH HOLD`:

```cobol
    EXEC SQL DECLARE ACCT-CUR CURSOR FOR SELECT ... END-EXEC
    ...
    PERFORM UNTIL WS-DONE = "Y"
        EXEC SQL FETCH ACCT-CUR INTO :WS-ID END-EXEC    *> reported
        ...
        IF WS-COUNT = 100
            EXEC SQL COMMIT END-EXEC
        END-IF
    END-PERFORM
```

`COMMIT` and `ROLLBACK`, and `EXEC CICS SYNCPOINT`, close every
cursor not declared `WITH HOLD`: the first `FETCH` after them fails
with SQLCODE -501, and the loop ends early or goes on with no rows. The
loop and its statements are found as for
[PLB-C065](#plb-c065-open-in-loop), from the `FETCH`. A loop that opens
the cursor again among its statements is not reported.


## PLB-Q013 select-into-no-where

An embedded `SELECT ... INTO` with no `WHERE`:

```cobol
    EXEC SQL SELECT NAME INTO :WS-NAME FROM CUSTOMER END-EXEC   *> reported
```

`SELECT INTO` takes one row. Without `WHERE` it reads the whole table,
and once the table has more than one row the statement fails rather
than return one of them. A `GROUP BY` returns a row for each group and
is reported too. Usually the `WHERE` was lost in an edit, or a cursor
was meant.

Left alone: a select list of aggregate functions only (`COUNT`, `SUM`,
`MIN`, `MAX`, `AVG`) without `GROUP BY`, which returns one row; `FETCH
FIRST ... ROW ONLY`; and the one-row tables `SYSIBM.SYSDUMMY1` (and the
other `SYSDUMMY` tables) and `DUAL`. A `WHERE` only inside parentheses,
in a subquery, does not count.

## PLB-Q014 fetch-loop-end-only

The same for embedded SQL: a loop that fetches from a cursor and ends
only when `SQLCODE` is 100:

```cobol
    PERFORM UNTIL SQLCODE = 100                *> reported
        EXEC SQL FETCH C1 INTO :WS-NAME END-EXEC
        DISPLAY WS-NAME
    END-PERFORM
```

A `FETCH` that fails gives a negative `SQLCODE`, and the loop goes on
fetching. Left alone are loops whose statements name `SQLCODE`,
`SQLSTATE`, or `SQLCA` otherwise, or can leave the loop, as for
PLB-C086.
## PLB-Q015 insert-count-mismatch

An `INSERT` whose column list and `VALUES` list have different numbers
of items:

```cobol
    EXEC SQL INSERT INTO ACCOUNT (ACCT_ID, BALANCE, STATUS)
        VALUES (:WS-ACCT-ID, :WS-BALANCE)          *> reported
    END-EXEC
```

DB2 rejects the statement with SQLCODE -117 (the number of values is
not the number of columns), so the row is never written. Usually a
column was added to one list and not the other.

Read are `INSERT` statements with a column list and one `VALUES` row.
Commas are not tokens, so the items are counted from the source text,
as for [PLB-Q005](#plb-q005-into-count-mismatch): commas outside inner
parentheses, so that a function's arguments are not counted. A host
variable with an indicator (`:HV :IND`) is one value, and so is a
`VARCHAR` host variable (a group of level-49 items). A `VALUES` list
with a host structure (another group item, which stands for its
fields), an `INSERT` without a column list (its columns come from the
table), and `INSERT ... SELECT` are not read.

## PLB-Q016 cursor-open-twice

An `OPEN` of an SQL cursor, then, later in the same list of
statements, another `OPEN` of it with no `CLOSE` between:

```cobol
    EXEC SQL OPEN ACCT-CUR END-EXEC
    MOVE 0 TO WS-COUNT
    EXEC SQL OPEN ACCT-CUR END-EXEC          *> reported
```

DB2 rejects the second `OPEN` with SQLCODE -502 (the cursor is already
open), and a program that tests only for 100 goes on fetching from
where the first left off.

The statements after the `OPEN` are read in its list (for a statement
directly in a sentence, on through the paragraph's later sentences).
A `CLOSE` of the cursor ends the search, as do a `PERFORM` of a
procedure, `GO TO`, `CALL`, `GOBACK`, `STOP`, `EXIT`, and a statement
holding other SQL. A test of `SQLCODE` or `SQLSTATE` between them,
which may find that the first `OPEN` failed and try again, ends it too.

## PLB-Q017 fetch-after-close

A `FETCH` or `CLOSE` of an SQL cursor after a `CLOSE` of it, with no
`OPEN` between:

```cobol
    EXEC SQL CLOSE ACCT-CUR END-EXEC
    EXEC SQL FETCH ACCT-CUR INTO :WS-ID END-EXEC   *> reported
```

The cursor is closed, and DB2 rejects the statement with SQLCODE -501
(the cursor is not open). Read as for
[PLB-Q016](#plb-q016-cursor-open-twice), from the `CLOSE`: an `OPEN`
of the cursor ends the search, and so do the statements that end
Q016's.

## PLB-Q018 null-compared

A condition of embedded SQL that compares a value with `NULL`:

```cobol
    EXEC SQL
        DELETE FROM ACCOUNT
         WHERE CLOSED_DATE = NULL           *> reported
    END-EXEC
```

In SQL a comparison with the null value is unknown, never true, for
every row, with `<>` as much as with `=`: the `DELETE` above deletes
nothing, and `CLOSED_DATE <> NULL` selects nothing either. SQLite 3
selects no row with either, and a `CASE WHEN OWNER = NULL` never takes
the row whose `OWNER` is null. The test meant is `IS NULL` or `IS NOT
NULL`.

Conditions are read after `WHERE`, `HAVING`, `ON`, and `WHEN`, in
statements and in `DECLARE CURSOR`, with `NULL` on either side of `=`,
`<>`, `<`, `>`, `<=`, or `>=`. `SET CLOSED_DATE = NULL` in an `UPDATE`
gives the column the null value, and is not reported.

## PLB-Q019 between-reversed

An SQL `BETWEEN` whose first number is above its second:

```cobol
    EXEC SQL
        SELECT COUNT(*) INTO :WS-COUNT FROM ACCOUNT
         WHERE AGE BETWEEN 65 AND 18        *> reported
    END-EXEC
```

`x BETWEEN a AND b` means `x >= a AND x <= b`, so with `a` above `b` no
value satisfies it, and `NOT BETWEEN` is true for every value that is
not null; SQLite 3 selects no row with `BETWEEN 10 AND 5`, and every
row with `NOT BETWEEN 10 AND 5`. This is
[PLB-C074](#plb-c074-condition-range-reversed) for SQL.

Both ends must be numbers, with a sign or decimal places or not; an end
that is a host variable or part of an expression (`BETWEEN 30 AND 20 +
:WS-LOW`) is not read.

## PLB-S001 dynamic-sql

SQL text that the program builds at run time and hands to the database:

```cobol
    EXEC SQL PREPARE STMT FROM :SQL-TEXT END-EXEC       *> noted
    EXEC SQL EXECUTE IMMEDIATE :SQL-TEXT END-EXEC       *> noted
```

If outside input (a screen, a file, a message) reaches the text without
being checked, it can change what the statement does: SQL injection.
Static SQL with host variables keeps data and statement apart. Use it
where possible, and check the text where not.

## Names that mark sensitive data

PLB-S002 and PLB-S003 cannot see what an item holds, so they go by its
name. A name is split at its hyphens, and whole parts are compared:

- **credentials**: PASSWORD, PASSWD, PWD, PASSPHRASE, PASSCODE, SECRET,
  APIKEY, CREDENTIAL, CREDENTIALS;
- **personal data**: PIN, SSN, CVV, CVC, CVV2, TAXID.

`CUSTOMER-PIN` is personal data. `SPINDLE-ID` and `PINNED-FLAG` are
not: PIN is only part of a part. A name with a part that describes the
data rather than holding it (LEN, LENGTH, SIZE, COUNT, CNT, CTR, RETRY,
RETRIES, TRIES, ATTEMPTS, FLAG, SW, SWITCH, IND, STATUS, DATE, EXPIRY,
EXPIRES, MIN, MAX, RULES, POLICY, PROMPT, MSG, MESSAGE, LABEL, TEXT,
FIELD, COL, ROW, POS) is not sensitive, so `PASSWORD-LENGTH` and
`PIN-RETRY-COUNT` are left alone. Condition names (level 88) never are.

## PLB-S002 hard-coded-credential

A credential given its value by the program itself, in a VALUE clause
or a MOVE of a literal:

```cobol
01  DB-PASSWORD         PIC X(16) VALUE "tiger".   *> reported
    MOVE "s3cr3t" TO API-SECRET                    *> reported
    MOVE SPACES TO DB-PASSWORD                     *> fine: clears it
```

Anyone who can read the source, the load module, or a listing can read
the credential, and changing it means a new build. Read it at run time
from a protected file, a vault, or the job's environment. Blank values
(SPACES, `""`, `" "`) are not reported: they clear an item rather than
set a secret.

## PLB-S003 sensitive-data-displayed

DISPLAY of an item whose name marks it as a credential or as personal
data:

```cobol
    DISPLAY "LOGIN " USER-NAME " " DB-PASSWORD     *> reported
    DISPLAY CUSTOMER-PIN                           *> reported
```

DISPLAY output usually ends up in a job log or a console log, which is
kept, copied, and read by far more people than the data was meant for.
Leave the item out, or show a masked form.

## PLB-S004 shell-command

A command run through the operating system that comes from a data item
rather than a literal:

```cobol
    CALL "SYSTEM" USING "ls -l"                    *> fine: a literal
    CALL "SYSTEM" USING BY CONTENT SHELL-LINE      *> noted
```

The routines checked are SYSTEM, C$SYSTEM, C$RUN, CBL_OS_COMMAND, and
CBL_EXEC_RUN_UNIT. When outside input goes into the command text
unchecked, it can add commands of its own: command injection. Build the
command from known parts, and check or quote anything that comes from
outside. The rule cannot tell whether that happened, so it only notes
the call.
