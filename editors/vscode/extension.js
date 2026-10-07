// The Plumbline extension for Visual Studio Code: it starts
// `plumbline lsp` for COBOL files and lets the editor talk to it.
// Everything the user sees (findings, outline, navigation, rename,
// highlighting) comes from the language server; one command runs
// `plumbline doc` on the open file and shows the page it writes, and
// another `plumbline impact` on the name under the cursor.
"use strict";

const { execFile } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");
const vscode = require("vscode");
const { LanguageClient } = require("vscode-languageclient/node");

let client;
let impactOutput;

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
      const page = await vscode.workspace.openTextDocument(
        { language: "markdown", content: stdout });
      await vscode.window.showTextDocument(page);
      await vscode.commands.executeCommand("markdown.showPreview", page.uri);
    });
}

// The name to look up: the COBOL word under the cursor (a copybook,
// program, data item, or data set name), else the file's own name
// without its extension.
function impactName(editor) {
  const document = editor.document;
  const range = document.getWordRangeAtPosition(
    editor.selection.active, /[A-Za-z0-9#@$][A-Za-z0-9#@$.-]*/);
  if (range) {
    return document.getText(range).replace(/[.]+$/, "");
  }
  return path.basename(document.uri.fsPath).replace(/\.[^.]*$/, "");
}

// `plumbline impact NAME` over the COBOL and JCL files of the workspace,
// listed in a file for --files-from, with the same options as the
// language server; the answer goes to an output channel.
async function showImpact() {
  const editor = vscode.window.activeTextEditor;
  if (!editor || editor.document.uri.scheme !== "file") {
    vscode.window.showInformationMessage("Plumbline: open a file first.");
    return;
  }
  const name = impactName(editor);
  const files = await vscode.workspace.findFiles(
    "**/*.{cbl,cob,CBL,COB,jcl,JCL}", "**/node_modules/**");
  if (files.length === 0) {
    vscode.window.showInformationMessage(
      "Plumbline: no COBOL or JCL files in the workspace.");
    return;
  }
  const list = path.join(os.tmpdir(), "plumbline-impact-" + process.pid + ".txt");
  fs.writeFileSync(list, files.map((file) => file.fsPath).join("\n") + "\n");
  const settings = vscode.workspace.getConfiguration("plumbline");
  const command = settings.get("path", "plumbline");
  const args = ["impact", name, ...settings.get("arguments", []),
                "--files-from", list];
  const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!impactOutput) {
    impactOutput = vscode.window.createOutputChannel("Plumbline impact");
  }
  execFile(command, args,
    { ...(folder ? { cwd: folder } : {}), maxBuffer: 64 * 1024 * 1024 },
    (error, stdout, stderr) => {
      fs.rm(list, () => {});
      impactOutput.clear();
      impactOutput.append(stdout || stderr || String(error));
      impactOutput.show(true);
    });
}

async function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand("plumbline.document", documentProgram),
    vscode.commands.registerCommand("plumbline.impact", showImpact),
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
