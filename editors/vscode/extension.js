// The Plumbline extension for Visual Studio Code: it starts
// `plumbline lsp` for COBOL files and lets the editor talk to it.
// Everything the user sees (findings, outline, navigation, rename,
// highlighting) comes from the language server.
"use strict";

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

async function activate(context) {
  context.subscriptions.push(
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
