"""Tests of plumbline lsp, the language server, through its pipes."""

import json
import os
import subprocess
import tempfile
import unittest

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
# make test names the program to run, which under make coverage is a
# wrapper that records the statements it executes.
PLUMBLINE = os.environ.get(
    "PLUMBLINE", os.path.join(ROOT, "build", "bin", "plumbline"))
SAMPLE = os.path.abspath(os.path.join(
    ROOT, "tests", "golden", "rules", "c001-unreachable.cob"))
URI = "file://" + SAMPLE


class Server:
    """A running plumbline lsp and a minimal client for it."""

    def __init__(self):
        self.process = subprocess.Popen(
            [PLUMBLINE, "lsp", "--no-config"], stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.next_id = 0

    def send(self, message):
        body = json.dumps(message).encode()
        self.process.stdin.write(
            b"Content-Length: %d\r\n\r\n" % len(body) + body)
        self.process.stdin.flush()

    def receive(self):
        length = None
        while True:
            line = self.process.stdout.readline()
            if not line:
                raise EOFError("server closed its output")
            line = line.strip()
            if not line:
                break
            name, _, value = line.partition(b":")
            if name.lower() == b"content-length":
                length = int(value)
        return json.loads(self.process.stdout.read(length))

    def request(self, method, params):
        self.next_id += 1
        self.send({"jsonrpc": "2.0", "id": self.next_id, "method": method,
                   "params": params})
        return self.receive()

    def notify(self, method, params):
        self.send({"jsonrpc": "2.0", "method": method, "params": params})

    def close(self):
        self.process.stdin.close()
        self.process.wait(timeout=10)
        self.process.stdout.close()
        self.process.stderr.close()


@unittest.skipUnless(os.path.exists(PLUMBLINE), "plumbline is not built")
class LanguageServerTest(unittest.TestCase):
    def setUp(self):
        self.server = Server()
        reply = self.server.request("initialize", {"capabilities": {}})
        self.capabilities = reply["result"]["capabilities"]
        self.server.notify("initialized", {})
        with open(SAMPLE) as f:
            self.text = f.read()
        self.server.notify("textDocument/didOpen", {"textDocument": {
            "uri": URI, "languageId": "cobol", "version": 1,
            "text": self.text}})
        self.diagnostics = self.server.receive()

    def tearDown(self):
        self.server.close()

    def position(self, needle, offset=0):
        """The 0-based line and character of NEEDLE in the sample."""
        for number, line in enumerate(self.text.splitlines()):
            if needle in line:
                return {"line": number,
                        "character": line.index(needle) + offset}
        raise AssertionError(needle)

    def test_capabilities(self):
        self.assertEqual(self.capabilities["textDocumentSync"]["change"], 1)
        self.assertTrue(self.capabilities["definitionProvider"])
        self.assertTrue(self.capabilities["hoverProvider"])
        self.assertTrue(self.capabilities["referencesProvider"])
        self.assertTrue(self.capabilities["documentHighlightProvider"])
        self.assertTrue(
            self.capabilities["renameProvider"]["prepareProvider"])
        self.assertTrue(self.capabilities["foldingRangeProvider"])
        self.assertIn("codeLensProvider", self.capabilities)
        self.assertIn("documentLinkProvider", self.capabilities)
        self.assertTrue(self.capabilities["inlayHintProvider"])
        self.assertIn("completionProvider", self.capabilities)
        self.assertTrue(self.capabilities["callHierarchyProvider"])
        self.assertIn("signatureHelpProvider", self.capabilities)
        legend = self.capabilities["semanticTokensProvider"]["legend"]
        self.assertIn("variable", legend["tokenTypes"])
        self.assertEqual(
            self.capabilities["codeActionProvider"]["codeActionKinds"],
            ["quickfix"])
        self.assertTrue(self.capabilities["documentSymbolProvider"])
        self.assertTrue(self.capabilities["workspaceSymbolProvider"])

    def test_diagnostics_on_open(self):
        self.assertEqual(self.diagnostics["method"],
                         "textDocument/publishDiagnostics")
        params = self.diagnostics["params"]
        self.assertEqual(params["uri"], URI)
        found = {(d["code"], d["range"]["start"]["line"])
                 for d in params["diagnostics"]}
        self.assertIn(("PLB-C001", self.position("AFTER-RANGE.")["line"]),
                      found)
        unreachable = [d for d in params["diagnostics"]
                       if d["code"] == "PLB-C001"]
        self.assertEqual(unreachable[0]["severity"], 2)
        # The range covers the paragraph name.
        start = unreachable[0]["range"]["start"]["character"]
        end = unreachable[0]["range"]["end"]["character"]
        self.assertEqual(end - start, len("AFTER-RANGE"))
        # The code links to the rule's section of the reference, and
        # code that never runs is tagged unnecessary.
        self.assertTrue(unreachable[0]["codeDescription"]["href"].endswith(
            "/docs/rules.md#plb-c001-unreachable-code"))
        self.assertEqual(unreachable[0]["tags"], [1])
        go_to = [d for d in params["diagnostics"] if d["code"] == "PLB-M001"]
        self.assertNotIn("tags", go_to[0])

    def test_diagnostics_follow_changes(self):
        changed = self.text.replace("GO TO ABEND", "PERFORM ABEND")
        self.server.notify("textDocument/didChange", {
            "textDocument": {"uri": URI, "version": 2},
            "contentChanges": [{"text": changed}]})
        codes = {d["code"]
                 for d in self.server.receive()["params"]["diagnostics"]}
        self.assertNotIn("PLB-M001", codes)

    def test_text_with_unicode_escapes(self):
        # JSON escapes non-ASCII as \\uXXXX, a character outside the
        # basic plane as a surrogate pair; the server reads them as UTF-8:
        # 2 bytes for e-acute, 3 for the euro sign, 4 for the face.
        changed = self.text.replace(
            "WORKING-STORAGE SECTION.\n",
            "WORKING-STORAGE SECTION.\n01  TINY PIC XX.\n").replace(
            "MAIN-LINE.\n",
            "MAIN-LINE.\n    MOVE \"\u00e9\u20ac\U0001f600\" TO TINY\n")
        self.server.notify("textDocument/didChange", {
            "textDocument": {"uri": URI, "version": 2},
            "contentChanges": [{"text": changed}]})
        messages = [d["message"]
                    for d in self.server.receive()["params"]["diagnostics"]
                    if d["code"] == "PLB-C008"]
        self.assertIn("MOVE truncates a 9-character literal to fit TINY "
                      "(2 characters)", messages)

    def test_document_symbols(self):
        reply = self.server.request("textDocument/documentSymbol",
                                    {"textDocument": {"uri": URI}})
        symbols = {(s["name"], s["kind"]) for s in reply["result"]}
        self.assertIn(("STEP-1", 6), symbols)
        self.assertIn(("ERRORS", 13), symbols)

    def test_workspace_symbols(self):
        with tempfile.TemporaryDirectory() as directory:
            other = os.path.join(directory, "other.cob")
            uri = "file://" + os.path.realpath(other)
            self.server.notify("textDocument/didOpen", {"textDocument": {
                "uri": uri, "languageId": "cobol", "version": 1,
                "text": "IDENTIFICATION DIVISION.\nPROGRAM-ID. OTHER.\n"
                        "PROCEDURE DIVISION.\nSTEP-ONE.\n    GOBACK.\n"}})
            self.server.receive()
            reply = self.server.request("workspace/symbol",
                                        {"query": "step"})
            found = {(s["name"], s["location"]["uri"])
                     for s in reply["result"]}
            self.assertIn(("STEP-1", URI), found)
            self.assertIn(("STEP-ONE", uri), found)
            self.assertTrue(all("STEP" in name for name, _ in found))
            everything = self.server.request("workspace/symbol",
                                             {"query": ""})["result"]
            self.assertIn("ERRORS", {s["name"] for s in everything})

    def test_definition_of_a_paragraph(self):
        reply = self.server.request("textDocument/definition", {
            "textDocument": {"uri": URI},
            "position": self.position("PERFORM STEP-1", len("PERFORM "))})
        location = reply["result"]
        self.assertEqual(location["uri"], URI)
        self.assertEqual(location["range"]["start"]["line"],
                         self.position("STEP-1.")["line"])

    def test_definition_of_a_data_item(self):
        reply = self.server.request("textDocument/definition", {
            "textDocument": {"uri": URI},
            "position": self.position("IF ERRORS", len("IF "))})
        self.assertEqual(reply["result"]["range"]["start"]["line"],
                         self.position("01  ERRORS")["line"])

    def lines(self, locations):
        return sorted(l["range"]["start"]["line"] for l in locations)

    def test_references_to_a_data_item(self):
        reply = self.server.request("textDocument/references", {
            "textDocument": {"uri": URI},
            "position": self.position("IF ERRORS", len("IF ")),
            "context": {"includeDeclaration": True}})
        self.assertEqual(self.lines(reply["result"]), [
            self.position("01  ERRORS")["line"],
            self.position("IF ERRORS")["line"],
            self.position("MOVE 0 TO ERRORS")["line"]])
        self.assertTrue(all(l["uri"] == URI for l in reply["result"]))

    def test_references_without_the_declaration(self):
        reply = self.server.request("textDocument/references", {
            "textDocument": {"uri": URI},
            "position": self.position("01  ERRORS", len("01  ")),
            "context": {"includeDeclaration": False}})
        self.assertEqual(self.lines(reply["result"]), [
            self.position("IF ERRORS")["line"],
            self.position("MOVE 0 TO ERRORS")["line"]])

    def test_references_to_a_paragraph(self):
        reply = self.server.request("textDocument/references", {
            "textDocument": {"uri": URI},
            "position": self.position("ABEND.", 0),
            "context": {"includeDeclaration": True}})
        self.assertEqual(self.lines(reply["result"]), [
            self.position("GO TO ABEND")["line"],
            self.position("ABEND.")["line"]])

    def test_references_to_nothing(self):
        reply = self.server.request("textDocument/references", {
            "textDocument": {"uri": URI},
            "position": {"line": 0, "character": 0},
            "context": {"includeDeclaration": True}})
        self.assertIsNone(reply["result"])

    def test_highlights_tell_reads_from_writes(self):
        reply = self.server.request("textDocument/documentHighlight", {
            "textDocument": {"uri": URI},
            "position": self.position("IF ERRORS", len("IF "))})
        kinds = {h["range"]["start"]["line"]: h["kind"]
                 for h in reply["result"]}
        self.assertEqual(kinds[self.position("IF ERRORS")["line"]], 2)
        self.assertEqual(kinds[self.position("MOVE 0 TO ERRORS")["line"]], 3)
        self.assertIn(self.position("01  ERRORS")["line"], kinds)

    def rename(self, needle, offset, new_name):
        return self.server.request("textDocument/rename", {
            "textDocument": {"uri": URI},
            "position": self.position(needle, offset),
            "newName": new_name})

    def apply(self, edits):
        lines = self.text.splitlines(keepends=True)
        for edit in sorted(edits, key=lambda e: (e["range"]["start"]["line"],
                                                 e["range"]["start"]["character"]),
                           reverse=True):
            start, end = edit["range"]["start"], edit["range"]["end"]
            self.assertEqual(start["line"], end["line"])
            line = lines[start["line"]]
            lines[start["line"]] = (line[:start["character"]] + edit["newText"]
                                    + line[end["character"]:])
        return "".join(lines)

    def test_rename_a_data_item(self):
        reply = self.rename("IF ERRORS", len("IF "), "Failures")
        edits = reply["result"]["changes"][URI]
        self.assertEqual(len(edits), 3)
        renamed = self.apply(edits)
        self.assertNotIn("ERRORS", renamed)
        self.assertIn("01  Failures", renamed)
        self.assertIn("MOVE 0 TO Failures.", renamed)

    def test_rename_a_paragraph(self):
        reply = self.rename("ABEND.", 0, "FAIL-EXIT")
        renamed = self.apply(reply["result"]["changes"][URI])
        self.assertIn("GO TO FAIL-EXIT", renamed)
        self.assertIn("FAIL-EXIT.", renamed)
        self.assertNotIn("ABEND", renamed)

    def test_rename_to_a_reserved_word(self):
        for name in ("MOVE", "-X", "X-", "123", "A B", ""):
            reply = self.rename("IF ERRORS", len("IF "), name)
            self.assertEqual(reply["error"]["code"], -32602, name)

    def test_rename_in_a_copybook(self):
        with tempfile.TemporaryDirectory() as directory:
            copybook = os.path.join(directory, "totals.cpy")
            with open(copybook, "w") as f:
                f.write("01  TOTAL-AMOUNT PIC 9(7).\n")
            program = os.path.join(directory, "report.cob")
            text = ("IDENTIFICATION DIVISION.\nPROGRAM-ID. REPORT1.\n"
                    "DATA DIVISION.\nWORKING-STORAGE SECTION.\n"
                    "COPY totals.\nPROCEDURE DIVISION.\n"
                    "    ADD 1 TO TOTAL-AMOUNT\n"
                    "    DISPLAY TOTAL-AMOUNT\n    GOBACK.\n")
            uri = "file://" + os.path.realpath(program)
            self.server.notify("textDocument/didOpen", {"textDocument": {
                "uri": uri, "languageId": "cobol", "version": 1,
                "text": text}})
            self.server.receive()
            reply = self.server.request("textDocument/rename", {
                "textDocument": {"uri": uri},
                "position": {"line": 6, "character": 15},
                "newName": "GRAND-TOTAL"})
            changes = reply["result"]["changes"]
            self.assertEqual(len(changes[uri]), 2)
            [declaration] = [edits for key, edits in changes.items()
                             if key.endswith("/totals.cpy")]
            self.assertEqual(declaration[0]["range"]["start"],
                             {"line": 0, "character": 4})

    def test_definition_of_a_copybook(self):
        with tempfile.TemporaryDirectory() as directory:
            with open(os.path.join(directory, "totals.cpy"), "w") as f:
                f.write("01  TOTAL-AMOUNT PIC 9(7).\n")
            program = os.path.join(directory, "report.cob")
            text = ("IDENTIFICATION DIVISION.\nPROGRAM-ID. REPORT1.\n"
                    "DATA DIVISION.\nWORKING-STORAGE SECTION.\n"
                    "    COPY totals.\nPROCEDURE DIVISION.\n"
                    "    DISPLAY TOTAL-AMOUNT\n    GOBACK.\n")
            uri = "file://" + os.path.realpath(program)
            self.server.notify("textDocument/didOpen", {"textDocument": {
                "uri": uri, "languageId": "cobol", "version": 1,
                "text": text}})
            self.server.receive()
            # On the name of the copybook, after COPY.
            reply = self.server.request("textDocument/definition", {
                "textDocument": {"uri": uri},
                "position": {"line": 4, "character": 10}})
            self.assertTrue(reply["result"]["uri"].endswith("/totals.cpy"))
            self.assertEqual(reply["result"]["range"]["start"],
                             {"line": 0, "character": 0})
            # Before the COPY statement, nothing.
            reply = self.server.request("textDocument/definition", {
                "textDocument": {"uri": uri},
                "position": {"line": 4, "character": 1}})
            self.assertIsNone(reply["result"])

    def test_definition_of_a_called_program(self):
        with tempfile.TemporaryDirectory() as directory:
            # A program file beside the caller, found by its name.
            with open(os.path.join(directory, "custlook.cbl"), "w") as f:
                f.write("       IDENTIFICATION DIVISION.\n"
                        "      * PROGRAM-ID. OLDNAME in a comment.\n"
                        "       PROGRAM-ID. CUSTLOOK.\n"
                        "       DATA DIVISION.\n"
                        "       LINKAGE SECTION.\n"
                        "       01  LK-ID     PIC X(8).\n"
                        "       01  LK-NAME   PIC X(30).\n"
                        "       PROCEDURE DIVISION USING LK-ID\n"
                        "               LK-NAME.     *> both\n"
                        "           GOBACK.\n")
            program = os.path.join(directory, "billing.cob")
            text = ("IDENTIFICATION DIVISION.\nPROGRAM-ID. BILLING.\n"
                    "PROCEDURE DIVISION.\n"
                    "    CALL \"CUSTLOOK\"\n"
                    "    CALL \"ARCHIVE\"\n"
                    "    CALL \"NOWHERE\"\n"
                    "    GOBACK.\n")
            uri = "file://" + os.path.realpath(program)
            self.server.notify("textDocument/didOpen", {"textDocument": {
                "uri": uri, "languageId": "cobol", "version": 1,
                "text": text}})
            self.server.receive()
            # Another open document that is the program called.
            archive = "file://" + os.path.realpath(
                os.path.join(directory, "elsewhere.cob"))
            self.server.notify("textDocument/didOpen", {"textDocument": {
                "uri": archive, "languageId": "cobol", "version": 1,
                "text": "IDENTIFICATION DIVISION.\n"
                        "PROGRAM-ID. \"archive\".\n"
                        "PROCEDURE DIVISION.\n    GOBACK.\n"}})
            self.server.receive()
            reply = self.server.request("textDocument/definition", {
                "textDocument": {"uri": uri},
                "position": {"line": 3, "character": 11}})
            # A file system may ignore case: either spelling is the file.
            self.assertTrue(
                reply["result"]["uri"].lower().endswith("/custlook.cbl"))
            self.assertEqual(reply["result"]["range"]["start"],
                             {"line": 2, "character": 19})
            reply = self.server.request("textDocument/definition", {
                "textDocument": {"uri": uri},
                "position": {"line": 4, "character": 11}})
            self.assertEqual(reply["result"]["uri"], archive)
            self.assertEqual(reply["result"]["range"]["start"],
                             {"line": 1, "character": 13})
            reply = self.server.request("textDocument/definition", {
                "textDocument": {"uri": uri},
                "position": {"line": 5, "character": 11}})
            self.assertIsNone(reply["result"])
            # Hover: where the program is and what it takes.
            reply = self.server.request("textDocument/hover", {
                "textDocument": {"uri": uri},
                "position": {"line": 3, "character": 11}})
            value = reply["result"]["contents"]["value"]
            self.assertIn("PROGRAM-ID. CUSTLOOK.\n"
                          "PROCEDURE DIVISION USING LK-ID LK-NAME.", value)
            self.assertIn(", line 3.", value)
            reply = self.server.request("textDocument/hover", {
                "textDocument": {"uri": uri},
                "position": {"line": 5, "character": 11}})
            self.assertIsNone(reply["result"])

    def test_signature_help_in_a_call(self):
        with tempfile.TemporaryDirectory() as directory:
            with open(os.path.join(directory, "custlook.cbl"), "w") as f:
                f.write("       IDENTIFICATION DIVISION.\n"
                        "       PROGRAM-ID. CUSTLOOK.\n"
                        "       DATA DIVISION.\n"
                        "       LINKAGE SECTION.\n"
                        "       01  LK-ID     PIC X(8).\n"
                        "       01  LK-NAME   PIC X(30).\n"
                        "       PROCEDURE DIVISION USING BY REFERENCE\n"
                        "               LK-ID LK-NAME.\n"
                        "           GOBACK.\n")
            program = os.path.join(directory, "billing.cob")
            lines = ["IDENTIFICATION DIVISION.", "PROGRAM-ID. BILLING.",
                     "DATA DIVISION.", "WORKING-STORAGE SECTION.",
                     "01  WS-REC.", "    05  WS-ID    PIC X(8).",
                     "01  WS-NAME  PIC X(30).",
                     "PROCEDURE DIVISION.",
                     "    CALL \"CUSTLOOK\" USING WS-ID OF WS-REC",
                     "        BY CONTENT WS-NAME",
                     "    DISPLAY WS-NAME",
                     "    GOBACK."]
            uri = "file://" + os.path.realpath(program)
            self.server.notify("textDocument/didOpen", {"textDocument": {
                "uri": uri, "languageId": "cobol", "version": 1,
                "text": "\n".join(lines) + "\n"}})
            self.server.receive()

            def help_at(line, character):
                return self.server.request("textDocument/signatureHelp", {
                    "textDocument": {"uri": uri},
                    "position": {"line": line, "character": character}}
                )["result"]

            result = help_at(8, lines[8].index("WS-ID") + 2)
            signature = result["signatures"][0]
            self.assertEqual(signature["label"],
                             "CUSTLOOK USING BY REFERENCE LK-ID LK-NAME")
            self.assertEqual([p["label"] for p in signature["parameters"]],
                             ["LK-ID", "LK-NAME"])
            self.assertEqual(result["activeParameter"], 0)
            # The qualifier is part of the first argument; past it, the
            # second begins.
            self.assertEqual(help_at(8, len(lines[8]))["activeParameter"], 0)
            self.assertEqual(
                help_at(8, len(lines[8]) + 1)["activeParameter"], 1)
            self.assertEqual(help_at(9, len(lines[9]))["activeParameter"], 1)
            # Outside a CALL: nothing.
            self.assertIsNone(help_at(10, 6))

    def test_hover_on_a_table(self):
        program = os.path.abspath(os.path.join(
            ROOT, "tests", "fixtures", "lineage", "acctsql.cob"))
        uri = "file://" + program
        with open(program) as f:
            text = f.read()
        self.server.notify("textDocument/didOpen", {"textDocument": {
            "uri": uri, "languageId": "cobol", "version": 1, "text": text}})
        self.server.receive()
        lines = text.split("\n")
        # On ACCOUNT in FROM ACCOUNT, and on its DECLARE TABLE.
        for line_no, line in enumerate(lines):
            if "FROM ACCOUNT WHERE" in line or "DECLARE ACCOUNT" in line:
                reply = self.server.request("textDocument/hover", {
                    "textDocument": {"uri": uri},
                    "position": {"line": line_no,
                                 "character": line.index("ACCOUNT") + 2}})
                value = reply["result"]["contents"]["value"]
                self.assertIn("Table `ACCOUNT`, 3 columns", value)
                self.assertIn("| BALANCE | DECIMAL(9,2) | not null |", value)
        # A word that is not a table: nothing.
        line_no = next(i for i, l in enumerate(lines) if "FROM ACCOUNT W" in l)
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": uri},
            "position": {"line": line_no,
                         "character": lines[line_no].index("FROM") + 1}})
        self.assertIsNone(reply["result"])

    def test_document_links_to_copybooks(self):
        with tempfile.TemporaryDirectory() as directory:
            with open(os.path.join(directory, "totals.cpy"), "w") as f:
                f.write("01  TOTAL-AMOUNT PIC 9(7).\n")
            program = os.path.join(directory, "report.cob")
            text = ("IDENTIFICATION DIVISION.\nPROGRAM-ID. REPORT1.\n"
                    "DATA DIVISION.\nWORKING-STORAGE SECTION.\n"
                    "    COPY totals.\nPROCEDURE DIVISION.\n"
                    "    DISPLAY TOTAL-AMOUNT\n    GOBACK.\n")
            uri = "file://" + os.path.realpath(program)
            self.server.notify("textDocument/didOpen", {"textDocument": {
                "uri": uri, "languageId": "cobol", "version": 1,
                "text": text}})
            self.server.receive()
            reply = self.server.request("textDocument/documentLink",
                                        {"textDocument": {"uri": uri}})
            [link] = reply["result"]
            self.assertEqual(link["range"],
                             {"start": {"line": 4, "character": 9},
                              "end": {"line": 4, "character": 15}})
            self.assertTrue(link["target"].endswith("/totals.cpy"))

    def test_inlay_hints_give_sizes_and_offsets(self):
        text = ("IDENTIFICATION DIVISION.\nPROGRAM-ID. HINTS.\n"
                "DATA DIVISION.\nWORKING-STORAGE SECTION.\n"
                "01  ORDER-REC.\n"
                "    05  ORDER-ID    PIC X(8).\n"
                "    05  ORDER-QTY   PIC 9(3).\n"
                "        88  NO-QTY  VALUE 0.\n"
                "PROCEDURE DIVISION.\n    DISPLAY ORDER-REC\n    GOBACK.\n")
        uri = "file:///tmp/plumbline-hints.cob"
        self.server.notify("textDocument/didOpen", {"textDocument": {
            "uri": uri, "languageId": "cobol", "version": 1,
            "text": text}})
        self.server.receive()
        reply = self.server.request("textDocument/inlayHint", {
            "textDocument": {"uri": uri},
            "range": {"start": {"line": 0, "character": 0},
                      "end": {"line": 11, "character": 0}}})
        hints = {(h["position"]["line"], h["position"]["character"]):
                 h["label"] for h in reply["result"]}
        self.assertEqual(hints[(4, 14)], "11 bytes at offset 0")
        self.assertEqual(hints[(6, 29)], "3 bytes at offset 8")
        # Condition names have none.
        self.assertFalse(any(line == 7 for line, _ in hints))

    def test_completion_offers_names_once(self):
        reply = self.server.request("textDocument/completion", {
            "textDocument": {"uri": URI},
            "position": self.position("PERFORM INIT", len("PERFORM "))})
        items = reply["result"]["items"]
        labels = [item["label"] for item in items]
        self.assertEqual(len(labels), len(set(labels)))
        kinds = {item["label"]: item["kind"] for item in items}
        self.assertEqual(kinds["ERRORS"], 6)
        self.assertEqual(kinds["STEP-EXIT"], 3)
        details = {item["label"]: item["detail"] for item in items}
        self.assertEqual(details["COUNTER"], "PIC 9(4), 4 bytes")
        self.assertEqual(details["NEVER-CALLED"], "paragraph")

    def code_actions(self, line):
        return self.server.request("textDocument/codeAction", {
            "textDocument": {"uri": URI},
            "range": {"start": {"line": line, "character": 0},
                      "end": {"line": line, "character": 0}},
            "context": {"diagnostics": []}})["result"]

    def test_quick_fix_suppresses_a_finding(self):
        line = self.position("AFTER-RANGE.")["line"]
        [action] = self.code_actions(line)
        self.assertEqual(action["kind"], "quickfix")
        self.assertIn("PLB-C001", action["title"])
        [edit] = action["edit"]["changes"][URI]
        self.assertEqual(edit["range"]["start"], {"line": line, "character": 0})
        self.assertTrue(edit["newText"].rstrip().endswith(
            "*> plumbline: ignore unreachable-code"))
        # With the edit made, the finding is gone.
        lines = self.text.splitlines(keepends=True)
        lines.insert(line, edit["newText"])
        self.server.notify("textDocument/didChange", {
            "textDocument": {"uri": URI, "version": 2},
            "contentChanges": [{"text": "".join(lines)}]})
        codes = {(d["code"], d["range"]["start"]["line"]) for d in
                 self.server.receive()["params"]["diagnostics"]}
        self.assertNotIn(("PLB-C001", line + 1), codes)

    def test_no_quick_fix_without_a_finding(self):
        self.assertEqual(self.code_actions(0), [])

    def hierarchy_item(self, needle, offset=0):
        reply = self.server.request("textDocument/prepareCallHierarchy", {
            "textDocument": {"uri": URI},
            "position": self.position(needle, offset)})
        return reply["result"]

    def test_prepare_call_hierarchy(self):
        [item] = self.hierarchy_item("PERFORM STEP-1", len("PERFORM "))
        self.assertEqual(item["name"], "STEP-1")
        self.assertEqual(item["detail"], "paragraph")
        self.assertEqual(item["uri"], URI)
        self.assertEqual(item["selectionRange"]["start"]["line"],
                         self.position("STEP-1.")["line"])
        self.assertIsNone(self.hierarchy_item("IF ERRORS", len("IF ")))

    def test_incoming_calls(self):
        [item] = self.hierarchy_item("ABEND.")
        reply = self.server.request("callHierarchy/incomingCalls",
                                    {"item": item})
        [call] = reply["result"]
        self.assertEqual(call["from"]["name"], "MAIN-LINE")
        self.assertEqual(call["fromRanges"][0]["start"]["line"],
                         self.position("GO TO ABEND")["line"])

    def test_outgoing_calls(self):
        [item] = self.hierarchy_item("MAIN-LINE.")
        reply = self.server.request("callHierarchy/outgoingCalls",
                                    {"item": item})
        names = {call["to"]["name"] for call in reply["result"]}
        self.assertEqual(names, {"INIT", "STEP-1", "ABEND"})

    def semantic_tokens(self):
        reply = self.server.request("textDocument/semanticTokens/full",
                                    {"textDocument": {"uri": URI}})
        legend = self.capabilities["semanticTokensProvider"]["legend"]
        data = reply["result"]["data"]
        lines = self.text.splitlines()
        tokens = {}
        line = character = 0
        for i in range(0, len(data), 5):
            delta_line, delta_char, length, kind, modifiers = data[i:i + 5]
            line += delta_line
            character = character + delta_char if delta_line == 0 \
                else delta_char
            text = lines[line][character:character + length]
            tokens[(line, text)] = (legend["tokenTypes"][kind], modifiers)
        return tokens

    def test_semantic_tokens(self):
        tokens = self.semantic_tokens()
        perform = self.position("PERFORM STEP-1")["line"]
        self.assertEqual(tokens[(perform, "PERFORM")], ("keyword", 0))
        self.assertEqual(tokens[(perform, "STEP-1")], ("function", 0))
        self.assertEqual(tokens[(self.position("STEP-1.")["line"],
                                 "STEP-1")], ("function", 1))
        self.assertEqual(tokens[(self.position("01  ERRORS")["line"],
                                 "ERRORS")], ("variable", 1))
        self.assertEqual(tokens[(self.position("IF ERRORS")["line"],
                                 "ERRORS")], ("variable", 0))
        self.assertEqual(tokens[(self.position("01  ERRORS")["line"],
                                 "9(4)")], ("type", 0))
        self.assertIn(("string", 0), tokens.values())
        self.assertIn(("number", 0), tokens.values())

    def test_code_lenses(self):
        reply = self.server.request("textDocument/codeLens",
                                    {"textDocument": {"uri": URI}})
        lenses = {lens["range"]["start"]["line"]: lens["command"]["title"]
                  for lens in reply["result"]}
        self.assertEqual(lenses[self.position("INIT.")["line"]],
                         "1 PERFORM")
        # PERFORM STEP-1 THRU STEP-EXIT counts for STEP-1.
        self.assertEqual(lenses[self.position("STEP-1.")["line"]],
                         "1 PERFORM")
        self.assertEqual(lenses[self.position("ABEND.")["line"]],
                         "1 GO TO")
        self.assertEqual(lenses[self.position("NEVER-CALLED.")["line"]],
                         "no PERFORM or GO TO")
        self.assertNotIn(self.position("MAIN-LINE.")["line"] - 1, lenses)
        # Records: ERRORS is read once and set once; ADD ... TO COUNTER
        # both reads it and gives it a value.
        self.assertEqual(lenses[self.position("01  ERRORS")["line"]],
                         "1 read, 1 write")
        self.assertEqual(lenses[self.position("01  COUNTER")["line"]],
                         "2 reads, 2 writes")

    def test_folding_ranges(self):
        reply = self.server.request("textDocument/foldingRange",
                                    {"textDocument": {"uri": URI}})
        ranges = {(r["startLine"], r["endLine"]) for r in reply["result"]}
        procedure = self.position("PROCEDURE DIVISION")["line"]
        last = len(self.text.rstrip("\n").splitlines()) - 1
        self.assertIn((procedure, last), ranges)
        # MAIN-LINE runs to STOP RUN; its IF to END-IF.
        self.assertIn((self.position("MAIN-LINE.")["line"],
                       self.position("STOP RUN.")["line"]), ranges)
        self.assertIn((self.position("IF ERRORS")["line"],
                       self.position("END-IF")["line"]), ranges)
        # One-line paragraphs do not fold.
        self.assertTrue(all(end > start for start, end in ranges))

    def test_prepare_rename(self):
        reply = self.server.request("textDocument/prepareRename", {
            "textDocument": {"uri": URI},
            "position": self.position("IF ERRORS", len("IF E"))})
        self.assertEqual(reply["result"]["start"]["character"], len("    IF "))
        self.assertEqual(reply["result"]["end"]["character"],
                         len("    IF ERRORS"))
        reply = self.server.request("textDocument/prepareRename", {
            "textDocument": {"uri": URI},
            "position": self.position("STOP RUN", 0)})
        self.assertIsNone(reply["result"])

    def test_hover_on_a_data_item(self):
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": URI},
            "position": self.position("IF ERRORS", len("IF "))})
        value = reply["result"]["contents"]["value"]
        self.assertIn("ERRORS", value)
        self.assertIn("PIC", value)
        self.assertIn("bytes", value)

    def test_hover_on_a_paragraph(self):
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": URI},
            "position": self.position("PERFORM INIT", len("PERFORM "))})
        value = reply["result"]["contents"]["value"]
        self.assertIn("paragraph INIT", value)
        self.assertIn("statements, complexity 1", value)
        self.assertIn("1 PERFORM, 0 GO TO.", value)
        self.assertNotIn("never runs", value)

    def test_hover_on_a_paragraph_that_never_runs(self):
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": URI},
            "position": self.position("NEVER-CALLED.")})
        value = reply["result"]["contents"]["value"]
        self.assertIn("0 PERFORM, 0 GO TO. It never runs.", value)

    def open_sql_sample(self):
        path = os.path.abspath(os.path.join(
            ROOT, "tests", "golden", "sql", "statements.cob"))
        with open(path) as f:
            text = f.read()
        uri = "file://" + path
        self.server.notify("textDocument/didOpen", {"textDocument": {
            "uri": uri, "languageId": "cobol", "version": 1,
            "text": text}})
        self.server.receive()
        return uri, text.splitlines()

    def hover_at(self, uri, lines, line_text, needle):
        number = next(i for i, line in enumerate(lines) if line_text in line)
        character = lines[number].index(needle)
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": uri},
            "position": {"line": number, "character": character}})
        return reply["result"]["contents"]["value"]

    def test_hover_on_a_host_variable_shows_its_column(self):
        uri, lines = self.open_sql_sample()
        value = self.hover_at(uri, lines, "INTO :WS-ID, :WS-NAME :WS-NAME-IND",
                              "WS-ID")
        self.assertIn("Column `ACCT_ID` DECIMAL(11), not null: "
                      "fetched into this item.", value)
        value = self.hover_at(uri, lines, "VALUES (:WS-ID, :WS-NAME",
                              "WS-BALANCE")
        self.assertIn("Column `BALANCE` DECIMAL(9,2): stored from this "
                      "item.", value)

    def test_hover_on_nothing(self):
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": URI},
            "position": {"line": 0, "character": 0}})
        self.assertIsNone(reply["result"])

    def selection_ranges(self, positions):
        reply = self.server.request("textDocument/selectionRange", {
            "textDocument": {"uri": URI}, "positions": positions})
        chains = []
        for selection in reply["result"]:
            chain = []
            while selection:
                chain.append(selection["range"])
                selection = selection.get("parent")
            chains.append(chain)
        return chains

    def text_of(self, range_):
        lines = self.text.splitlines()
        start, end = range_["start"], range_["end"]
        if start["line"] == end["line"]:
            return lines[start["line"]][start["character"]:end["character"]]
        return "\n".join(
            [lines[start["line"]][start["character"]:]] +
            lines[start["line"] + 1:end["line"]] +
            [lines[end["line"]][:end["character"]]])

    def test_selection_grows_from_a_name(self):
        [chain] = self.selection_ranges(
            [self.position("IF ERRORS", len("IF ") + 2)])
        texts = [self.text_of(r) for r in chain]
        self.assertEqual(texts[0], "ERRORS")
        # The condition, then the IF statement, then larger units.
        self.assertTrue(any(t.startswith("IF ERRORS") for t in texts))
        # Each range holds the one before, and none repeats.
        for inner, outer in zip(chain, chain[1:]):
            self.assertNotEqual(inner, outer)
            self.assertLessEqual(
                (outer["start"]["line"], outer["start"]["character"]),
                (inner["start"]["line"], inner["start"]["character"]))
            self.assertGreaterEqual(
                (outer["end"]["line"], outer["end"]["character"]),
                (inner["end"]["line"], inner["end"]["character"]))
        # The outermost is the whole program.
        self.assertEqual(chain[-1]["start"]["line"], 1)

    def test_selection_for_each_position(self):
        chains = self.selection_ranges([
            self.position("PERFORM INIT", len("PERFORM ")),
            {"line": 0, "character": 0}])
        self.assertEqual(len(chains), 2)
        self.assertEqual(self.text_of(chains[0][0]), "INIT")
        # Off any token: one empty range at the position.
        self.assertEqual(chains[1], [{"start": {"line": 0, "character": 0},
                                      "end": {"line": 0, "character": 1}}])

    def test_unknown_request(self):
        reply = self.server.request("textDocument/linkedEditingRange", {
            "textDocument": {"uri": URI},
            "position": {"line": 0, "character": 0}})
        self.assertEqual(reply["error"]["code"], -32601)

    def test_close_clears_diagnostics(self):
        self.server.notify("textDocument/didClose",
                           {"textDocument": {"uri": URI}})
        self.assertEqual(self.server.receive()["params"]["diagnostics"], [])

    def test_shutdown_and_exit(self):
        reply = self.server.request("shutdown", None)
        self.assertIsNone(reply["result"])
        self.server.notify("exit", None)
        self.assertEqual(self.server.process.wait(timeout=10), 0)


if __name__ == "__main__":
    unittest.main()
