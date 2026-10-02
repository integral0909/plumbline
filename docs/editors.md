# Using Plumbline in an editor

`plumbline lsp` is a language server: an editor starts it, talks to it
over standard input and output with the Language Server Protocol, and
shows what it reports as you work.

| Feature | What you see |
|---------|--------------|
| Diagnostics | Findings and input problems, underlined where they are, updated on every change |
| Outline | Programs, sections, paragraphs, and data items of the file |
| Workspace symbols | The same names in every open file, found by part of the name |
| Go to definition | From a data name to its declaration (also in a copybook), from a paragraph or section name to the paragraph or section, and from a `COPY` statement to its copybook |
| Hover | A data item's level, picture, usage, size, offset, and record; a paragraph's or section's lines, statements, complexity, the `PERFORM` and `GO TO` statements naming it, and whether it ever runs |
| Find references | Every reference to a data item (also in copybooks), or every `PERFORM`, `GO TO`, `ALTER`, and `SORT` procedure naming a paragraph or section of the same program |
| Highlight | The same references in the open file, with reads and writes of a data item told apart |
| Quick fix | For a finding, a comment on the line before that suppresses its rule there (`*> plumbline: ignore unreachable-code`) |
| Semantic highlighting | Reserved words, data names, paragraph and section names, literals, operators, and pictures, from the analysis; names where they are declared are marked as declarations |
| Call hierarchy | For a paragraph or section, the paragraphs that PERFORM it or jump to it, and those it performs or jumps to |
| Folding | Programs, divisions, sections, paragraphs, and statements with a body (`IF`, `EVALUATE`, inline `PERFORM`, ...) |
| Code lens | Above each section and paragraph, how many `PERFORM` and `GO TO` statements name it, or "no PERFORM or GO TO" |
| Rename | A data item, paragraph, or section, at its declaration and every reference, in the open file and its copybooks. The new name must be a user-defined word. A name written in a `COPY ... REPLACING` phrase is not changed. |

The server reads `plumbline.conf` in the directory the editor starts it
in, usually the project's root, so `include`, `enable`, `disable`,
`severity`, and `limit` settings apply as they do for `plumbline check`.
The directory of each open file is searched for copybooks too. Options
can also be given on the command line, as in `plumbline lsp -I
copybooks`.

Every change is analyzed from a copy of the editor's text in the
temporary directory (`$TMPDIR`, else `/tmp`). The copy is deleted when
the file is closed and when the server stops.

## Visual Studio Code

`editors/vscode` holds an extension that starts `plumbline lsp` for
COBOL files; its README says how to build and install it, and its
settings name the program and its options.

## Neovim

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cobol",
  callback = function()
    vim.lsp.start({
      name = "plumbline",
      cmd = { "plumbline", "lsp" },
      root_dir = vim.fs.root(0, { "plumbline.conf", ".git" }),
    })
  end,
})
```

## Emacs (eglot)

```elisp
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(cobol-mode "plumbline" "lsp")))
```

## Other editors

Any editor or extension that can start a language server for a file
type can run `plumbline lsp`.

## Limits

- The whole text is sent on each change (full document sync).
- Positions are in characters of the line as Plumbline reads it, with
  tabs expanded to tab stops of 8. A line with tabs before a finding is
  underlined a few columns off.
- Rules about calls between programs need the other programs, so they
  are not run on a single open file.
