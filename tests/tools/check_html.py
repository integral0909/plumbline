#!/usr/bin/env python3
"""Check that standard input is a well-formed Plumbline HTML report.

Usage: check_html.py EXPECTED-FINDINGS

Exits non-zero with a message when the tags do not nest, when the page
has no title, or when the number of findings is not the one expected.
"""

import html.parser
import sys

VOID = {"meta", "br", "hr", "img", "link", "input"}


class Checker(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = []
        self.findings = 0
        self.title = False

    def handle_starttag(self, tag, attrs):
        if tag == "article":
            self.findings += 1
        if tag == "title":
            self.title = True
        if tag not in VOID:
            self.stack.append(tag)

    def handle_endtag(self, tag):
        if not self.stack or self.stack[-1] != tag:
            raise ValueError(f"</{tag}> does not close <{self.stack[-1:]}>")
        self.stack.pop()


def main(argv):
    if len(argv) != 2:
        sys.stderr.write(__doc__)
        return 2
    checker = Checker()
    try:
        checker.feed(sys.stdin.read())
        checker.close()
    except ValueError as error:
        print(f"check_html: {error}")
        return 1
    if checker.stack:
        print(f"check_html: unclosed tags: {checker.stack}")
        return 1
    if not checker.title:
        print("check_html: no title")
        return 1
    if checker.findings != int(argv[1]):
        print(f"check_html: expected {argv[1]} findings, found "
              f"{checker.findings}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
