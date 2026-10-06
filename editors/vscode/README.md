# Plumbline for Visual Studio Code

This extension runs the Plumbline language server (`plumbline lsp`) for
COBOL files: findings as you type, outline, completion, go to
definition (also from `COPY` to the copybook), hover, references,
highlights, rename, folding, code lenses, inlay hints with record
offsets, links to copybooks, call hierarchy, semantic highlighting, and
quick fixes that suppress a finding. See [Using Plumbline in an
editor](../../docs/editors.md) for what each does.

## Installing

Build and install `plumbline` first, so that it is on the `PATH` or at
a path you can give the extension. Then, from this directory:

```console
$ npm install
$ npx @vscode/vsce package
$ code --install-extension plumbline-0.1.0.vsix
```

## Settings

| Setting | Default | |
|---|---|---|
| `plumbline.path` | `plumbline` | The program, on the `PATH` or as a full path |
| `plumbline.arguments` | `[]` | Options for `plumbline lsp`, such as `["-I", "copybooks"]` |

The server starts in the first folder of the workspace and reads its
`plumbline.conf`. `Plumbline: Restart the language server` restarts it,
which a change of the settings also does.

`Plumbline: Document this program` runs `plumbline doc` on the open
file, with the same `plumbline.arguments`, and shows the page in the
Markdown preview: how the program starts, what it uses, its paragraphs,
and its records.

`Plumbline: Show what the name under the cursor reaches` runs
`plumbline impact` on the word under the cursor (a copybook, program,
data item, or data set name), or on the file's own name when the cursor
is on none, over the `.cbl`, `.cob`, and `.jcl` files of the workspace,
with the same `plumbline.arguments`. The answer goes to the "Plumbline
impact" output: the files that include a copybook, the programs that
call a program and the job steps that run them, where a data item is
read and set, or which steps read and write a data set.
