"""Tests of plumbline lsp, the language server, through its pipes."""

import json
import os
import subprocess
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
        self.assertTrue(self.capabilities["documentSymbolProvider"])

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

    def test_diagnostics_follow_changes(self):
        changed = self.text.replace("GO TO ABEND", "PERFORM ABEND")
        self.server.notify("textDocument/didChange", {
            "textDocument": {"uri": URI, "version": 2},
            "contentChanges": [{"text": changed}]})
        codes = {d["code"]
                 for d in self.server.receive()["params"]["diagnostics"]}
        self.assertNotIn("PLB-M001", codes)

    def test_document_symbols(self):
        reply = self.server.request("textDocument/documentSymbol",
                                    {"textDocument": {"uri": URI}})
        symbols = {(s["name"], s["kind"]) for s in reply["result"]}
        self.assertIn(("STEP-1", 6), symbols)
        self.assertIn(("ERRORS", 13), symbols)

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

    def test_hover_on_a_data_item(self):
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": URI},
            "position": self.position("IF ERRORS", len("IF "))})
        value = reply["result"]["contents"]["value"]
        self.assertIn("ERRORS", value)
        self.assertIn("PIC", value)
        self.assertIn("bytes", value)

    def test_hover_on_nothing(self):
        reply = self.server.request("textDocument/hover", {
            "textDocument": {"uri": URI},
            "position": {"line": 0, "character": 0}})
        self.assertIsNone(reply["result"])

    def test_unknown_request(self):
        reply = self.server.request("workspace/symbol", {"query": "X"})
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
