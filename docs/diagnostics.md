# Diagnostics

Diagnostics report problems with Plumbline's input: a file it cannot
read, text it cannot make sense of, or a limit it reached. They are
separate from findings, which report problems in the analyzed program
(see the [rule reference](rules.md)). Diagnostics are printed to
standard error as

```text
path:line:column: severity: message [CODE]
```

and make `plumbline check` exit with status 1 when one of them is an
error, whatever `--fail-on` says, because the analysis is then
incomplete. Plumbline carries on after an error where it can: a
statement it cannot parse is skipped, and the rest of the program is
still analyzed.

The code's letters name the stage that reports it.

## Reader (RD)

| Code | Severity | Meaning |
|------|----------|---------|
| RD001 | error | The file cannot be opened or read. |
| RD002 | warning | A line is longer than 1024 characters (after tab expansion); the rest of it is ignored. |
| RD003 | error | Column 7 of a fixed-format line holds a character that is not an indicator. This usually means the file is in free format; give `--format free`. |
| RD004 | warning | A `>>SOURCE` or `$SET` directive selects a format Plumbline cannot read, such as `VARIABLE`. |
| RD005 | error | Too many files, lines, or characters for one run; the rest of the input is not loaded. |

## Preprocessor (PP)

| Code | Severity | Meaning |
|------|----------|---------|
| PP001 | error | A copybook named by `COPY` is not found in the including file's directory or the `-I` directories. |
| PP002 | error | A copybook copies itself, directly or through others. |
| PP003 | error | A `COPY` statement is malformed. |
| PP004 | error | A copybook name is an absolute path or contains `..`. Copybooks are looked up only under the including file's directory and the `-I` directories. |
| PP005 | error | Copybooks are nested too deeply. |
| PP006 | error | A `REPLACE` statement is malformed. |
| PP007 | error | A preprocessor table is full: too many distinct copybooks or too many tokens after expansion. |
| PP008 | warning | A `REPLACING` rule of a `COPY` statement replaced nothing in the copybook: the pattern is misspelled, or the copybook no longer has what it names. |

## Lexer (LX)

| Code | Severity | Meaning |
|------|----------|---------|
| LX001 | error | An alphanumeric literal is not closed. |
| LX002 | error | A character that cannot start a token. |
| LX004 | warning | A hexadecimal literal (`X"..."`) has a character that is not a hexadecimal digit. |
| LX005 | error | The token table is full; the rest of the input is ignored. |
| LX006 | warning | A continuation line (`-` in column 7) follows no line it could continue. |
| LX007 | warning | A continuation line continues a literal but does not start with a quote. |
| LX008 | error | An internal table of the lexer is full. |
| LX009 | warning | A literal is longer than 8192 characters; the rest is ignored. |

## Parser (PS)

| Code | Severity | Meaning |
|------|----------|---------|
| PS001 | error | Text outside any division or paragraph. |
| PS002 | error | A scope terminator (`END-IF`, `END-PERFORM`, ...) with no open statement to end. |
| PS003 | error | `ELSE` without `IF`. |
| PS004 | error | `WHEN` outside `EVALUATE` or `SEARCH`. |
| PS005 | warning | The last sentence of a procedure division is not ended by a period: the program ends, or `END PROGRAM` follows, first. |
| PS006 | error | A conditional phrase (`AT END`, `ON SIZE ERROR`, ...) that no open statement accepts. |
| PS007 | error | Text where a statement was expected. |
| PS008 | error | A malformed data description entry. |
| PS009 | error | The syntax tree is full. |
| PS010 | error | `END PROGRAM` names a different program from the one it ends. |
| PS011 | warning | A nested program is not closed by `END PROGRAM`. |

## Symbols (SY)

| Code | Severity | Meaning |
|------|----------|---------|
| SY001 | warning | A `PICTURE` character-string is invalid. |
| SY002 | error | `REDEFINES` names no earlier item at the same level. |
| SY004 | error | The symbol table is full. |

## Procedure graph (FL)

| Code | Severity | Meaning |
|------|----------|---------|
| FL001 | error | `PERFORM` or `GO TO` names no paragraph or section of the program. |
| FL002 | warning | A paragraph name is used without qualification but is defined more than once: in more than one section, or twice outside sections. |
| FL003 | error | The procedure graph is full. |

## Baselines (BL)

| Code | Severity | Meaning |
|------|----------|---------|
| BL001 | error | The baseline file cannot be opened or written. |
| BL002 | error | The file given with `--baseline` is not a Plumbline baseline. |
| BL003 | error | The baseline has too many lines; the rest are ignored. |

## Diffs (DF)

| Code | Severity | Meaning |
|------|----------|---------|
| DF001 | error | The file given with `--diff` cannot be opened. |

## Findings (FN)

| Code | Severity | Meaning |
|------|----------|---------|
| FN001 | error | The run made more findings than it can keep (100,000); the report leaves the rest out. Check fewer files at a time, or disable the rules that report the most. |

## Limits

Plumbline keeps its data in tables of fixed size, and reaching a
limit is reported, never ignored. The limits are generous for a single
program; the ones that matter for large runs are:

| What | Limit |
|------|-------|
| Input files in one run | 10,000 |
| Files in one run, with copybooks | 20,000 |
| Lines of one input and its copybooks | 200,000 |
| Line length | 1024 characters |
| Findings in one run | 100,000 |

`plumbline check` holds the lines of one input and its copybooks at a
time, so the line limit applies to each input, not to the whole run.
