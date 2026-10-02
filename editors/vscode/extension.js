// The Plumbline extension for Visual Studio Code: it starts
// `plumbline lsp` for COBOL files and lets the editor talk to it.
// Everything the user sees (findings, outline, navigation, rename,
// highlighting) comes from the language server; one command runs
// `plumbline doc` on the open file and shows the page it writes.
"use strict";

const { execFile } = require("child_process");
const vscode = require("vscode");
const { LanguageClient } = require("vscode-languageclient/node");

let client;

function serverOptions() {
  const settings = vscode.workspace.getConfiguration("plumbline");
  const command = settings.get("path", "plumbline");
  const args = ["lsp", ...settings.get("arguments", [])];
  // The server reads plumbline.conf in the directory it starts in.
  const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  return { command, args, options: folder ? { cwd: folder } : {} };
}

async function start(context) {
  client = new LanguageClient(
    "plumbline",
    "Plumbline",
    serverOptions(),
    { documentSelector: [{ scheme: "file", language: "cobol" }] }
  );
  await client.start();
}

// `plumbline doc` on the file of the active editor, with the same
// options as the language server, shown as a Markdown preview. The
// command exits with 1 when the file has errors; the page is still
// worth showing.
function documentProgram() {
  const editor = vscode.window.activeTextEditor;
  if (!editor || editor.document.uri.scheme !== "file") {
    vscode.window.showInformationMessage("Plumbline: open a COBOL file first.");
    return;
  }
  const settings = vscode.workspace.getConfiguration("plumbline");
  const command = settings.get("path", "plumbline");
  const args = ["doc", ...settings.get("arguments", []),
                editor.document.uri.fsPath];
  const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  execFile(command, args, folder ? { cwd: folder } : {},
    async (error, stdout, stderr) => {
      if (!stdout) {
        vscode.window.showErrorMessage(
          "Plumbline: doc failed: " + (stderr || String(error)));
        return;
      }
      // Blank lines are written as a single space.
      const content = stdout.replace(/^ $/gm, "");
      const page = await vscode.workspace.openTextDocument(
        { language: "markdown", content });
      await vscode.window.showTextDocument(page);
      await vscode.commands.executeCommand("markdown.showPreview", page.uri);
    });
}

async function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand("plumbline.document", documentProgram),
    vscode.commands.registerCommand("plumbline.restart", async () => {
      if (client) {
        await client.stop();
      }
      await start(context);
    }),
    vscode.workspace.onDidChangeConfiguration(async (event) => {
      if (event.affectsConfiguration("plumbline") && client) {
        await client.stop();
        await start(context);
      }
    })
  );
  await start(context);
}

async function deactivate() {
  if (client) {
    await client.stop();
  }
}

module.exports = { activate, deactivate };
