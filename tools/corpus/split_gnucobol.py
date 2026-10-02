#!/usr/bin/env python3
"""Extract the COBOL programs of GnuCOBOL's run-time test suite.

GnuCOBOL's tests are Autotest files (tests/testsuite.src/run_*.at).
Each test case runs from AT_SETUP to AT_CLEANUP; it writes its files
with AT_DATA([name], [content]) and compiles them with
AT_CHECK([$COMPILE ... name], [status], ...). The run_* files hold the
tests whose programs compile and run, so every program in them is
valid for GnuCOBOL.

For each test case that compiles a COBOL file and expects that to
succeed, this script writes the files of the test case into a
directory of its own, NNNN-slug/, and adds a line to MANIFEST:

    directory<TAB>program<TAB>format<TAB>dialect<TAB>title

format is the reference format the test compiles with: "fixed"
unless -free or -fformat=NAME says otherwise; dialect is the -std=
option, or "default".

Usage: split_gnucobol.py TESTSUITE-DIR OUT-DIR
"""

import os
import re
import sys

# Autotest quadrigraphs and what they stand for.
QUADRIGRAPHS = [("@<:@", "["), ("@:>@", "]"), ("@S|@", "$"),
                ("@%:@", "#"), ("@{:@", "("), ("@:}@", ")"),
                ("@&t@", "")]

COBOL_SUFFIXES = (".cob", ".cbl", ".cpy", ".CPY", ".CBL", ".COB")


def unquote(text):
    for quad, char in QUADRIGRAPHS:
        text = text.replace(quad, char)
    return text


def quoted_argument(text, start):
    """The m4-quoted argument starting at text[start] == '[': its text
    and the index after its closing bracket."""
    assert text[start] == "["
    depth = 0
    i = start
    while i < len(text):
        if text[i] == "[":
            depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0:
                return text[start + 1:i], i + 1
        i += 1
    raise ValueError("unbalanced quotes at %d" % start)


def macro_arguments(text, start):
    """The quoted arguments of the macro call whose '(' is at
    text[start], and the index after its ')'."""
    args = []
    i = start + 1
    while i < len(text):
        while i < len(text) and text[i] in " \t\n,":
            i += 1
        if i >= len(text):
            break
        if text[i] == ")":
            return args, i + 1
        if text[i] == "[":
            arg, i = quoted_argument(text, i)
            args.append(arg)
        else:
            # An unquoted argument runs to the next comma or ')'.
            j = i
            while j < len(text) and text[j] not in ",)":
                j += 1
            args.append(text[i:j].strip())
            i = j
    raise ValueError("unterminated macro call at %d" % start)


def test_cases(text):
    """(title, body) for each AT_SETUP ... AT_CLEANUP in text."""
    for match in re.finditer(r"AT_SETUP\(\[(.*?)\]\)(.*?)AT_CLEANUP",
                             text, re.S):
        yield match.group(1), match.group(2)


def files_and_compiles(body):
    """The files a test case writes, and its COBOL compiles as
    (options, program, expected status)."""
    files = {}
    compiles = []
    for match in re.finditer(r"\b(AT_DATA|AT_CHECK)\(", body):
        try:
            args, _ = macro_arguments(body, match.end() - 1)
        except ValueError:
            continue
        if match.group(1) == "AT_DATA" and len(args) >= 2:
            files[args[0]] = unquote(args[1])
        elif match.group(1) == "AT_CHECK" and args:
            command = args[0]
            found = re.match(r"\$COMPILE(?:_ONLY|_MODULE)?\s+(.*)$",
                             command, re.S)
            if not found:
                continue
            words = found.group(1).split()
            programs = [w for w in words if w.endswith(COBOL_SUFFIXES)]
            options = [w for w in words if w.startswith("-")]
            status = args[1].strip() if len(args) > 1 else "0"
            for program in programs:
                compiles.append((options, program, status or "0"))
    return files, compiles


def slug(title):
    return re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:40]


def main(argv):
    if len(argv) != 3:
        sys.stderr.write(__doc__)
        return 2
    suite, out = argv[1], argv[2]
    os.makedirs(out, exist_ok=True)
    manifest = []
    number = 0
    for name in sorted(os.listdir(suite)):
        if not (name.startswith("run_") and name.endswith(".at")):
            continue
        with open(os.path.join(suite, name), encoding="latin-1") as at:
            text = at.read()
        for title, body in test_cases(text):
            files, compiles = files_and_compiles(body)
            programs = [(options, program) for options, program, status
                        in compiles if status == "0" and program in files]
            if not programs:
                continue
            number += 1
            directory = "%04d-%s" % (number, slug(title))
            path = os.path.join(out, directory)
            os.makedirs(path, exist_ok=True)
            for file_name, content in files.items():
                if "/" in file_name or file_name.startswith("."):
                    continue
                with open(os.path.join(path, file_name), "w",
                          encoding="latin-1") as data:
                    data.write(content.lstrip("\n"))
            for options, program in programs:
                source_format = "fixed"
                for option in options:
                    if option in ("-free", "-F"):
                        source_format = "free"
                    elif option.startswith("-fformat="):
                        source_format = option[len("-fformat="):].lower()
                dialect = next((o[len("-std="):] for o in options
                                if o.startswith("-std=")), "default")
                manifest.append("\t".join([
                    directory, program, source_format,
                    dialect, "%s: %s" % (name, title)]))
    with open(os.path.join(out, "MANIFEST"), "w", encoding="utf-8") as m:
        m.write("\n".join(manifest) + "\n")
    print("%d test cases, %d programs" % (number, len(manifest)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
