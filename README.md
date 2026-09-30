# Plumbline

Plumbline is a static analyzer for COBOL, written in COBOL.

It reads COBOL source (fixed or free format, with COPY expansion), builds
control-flow and data-flow models of each program, and reports defects such as
unreachable paragraphs, PERFORM fall-through, truncating MOVEs, and
uninitialized fields. Findings can be emitted as text, JSON, or SARIF.

> Status: early development. Nothing here is stable yet.

## License

Apache License 2.0. See [LICENSE](LICENSE).
