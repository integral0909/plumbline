# Plumbline for Visual Studio Code

This extension runs the Plumbline language server (`plumbline lsp`) for
COBOL files: findings as you type, outline, go to definition, hover,
references, highlights, rename, folding, code lenses, call hierarchy, semantic
highlighting, and quick fixes that suppress a finding. See [Using
Plumbline in an editor](../../docs/editors.md) for what each does.

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
