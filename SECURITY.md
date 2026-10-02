# Security Policy

## Supported versions

Plumbline has not had a release yet. Until 1.0, only the latest commit on
`main` receives security fixes.

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report vulnerabilities through GitHub's private vulnerability reporting:
open the repository's **Security** tab and choose **Report a
vulnerability**. Include:

- a description of the issue and its impact,
- the input (COBOL source, copybooks, configuration) that triggers it,
- the Plumbline version or commit, and your platform.

You can expect an acknowledgement within seven days. We will keep you
informed while we work on a fix and credit you in the release notes unless
you prefer otherwise.

## Threat model

Plumbline reads source code that may come from untrusted places, such as a
pull request under review. Treat these as security bugs:

- crashes, hangs, or unbounded memory use caused by crafted COBOL source,
  copybooks, or configuration files;
- reading or writing files outside the paths the user asked Plumbline to
  analyze, including through `COPY` resolution;
- executing any part of the analyzed program. Plumbline must never run the
  code it analyzes.
