# Running Plumbline in CI

`plumbline check` exits with status 1 when it reports findings at or
above the `--fail-on` level (`warning` by default), 2 when it is given
wrong options, and 0 otherwise, so a CI job can run it as a gate. The
reports turn the same findings into what each CI system shows.

| CI system | Report | Shown as |
|-----------|--------|----------|
| GitHub Actions | `--report sarif` | code scanning alerts, on the lines of a pull request |
| GitHub Actions | `--report md` | the job summary |
| GitLab | `--report codeclimate` | the merge request's code quality widget |
| GitLab, Jenkins, Azure DevOps | `--report junit` | test results |
| Jenkins (Warnings NG), reviewdog | `--report checkstyle` | warnings, review comments |

## Getting Plumbline into the job

Plumbline needs GnuCOBOL 3.2 to build. A job can build both, as this
repository's own CI does (`.github/workflows/ci.yml`), or build the
container image once and run that:

```sh
docker build -t plumbline .
docker run --rm -v "$PWD:/work" plumbline check -I copybooks src/*.cbl
```

The image holds Plumbline and the GnuCOBOL run-time library only, runs
as an unprivileged user, and reads the sources from `/work`.

## Only what a change adds

On an existing code base, a gate that fails on every old finding is
switched off within a week. Two ways keep it on:

- A **baseline** (`--write-baseline`, then `--baseline`) lists the
  findings of today; `check` then fails only on new ones, wherever they
  are. Commit the baseline with the code.
- A **diff** (`--diff`) holds a pull request to the rules on the lines
  it adds or changes, and nowhere else:

  ```sh
  git fetch origin main
  git diff -U0 origin/main...HEAD > changes.diff
  plumbline check --diff changes.diff -I copybooks src/*.cbl
  ```

The two can be used together. Findings they leave out do not count for
the exit status, and do not appear in any report.

## GitHub Actions

Code scanning reads SARIF. The upload needs the `security-events`
permission; run `check` with `--fail-on never` so that the upload
happens, and let code scanning decide what fails the pull request:

```yaml
permissions:
  contents: read
  security-events: write

steps:
  # ... check out the code and make plumbline available ...
  - run: plumbline check --report sarif --fail-on never -I copybooks src/*.cbl > plumbline.sarif
  - uses: github/codeql-action/upload-sarif@v3
    with:
      sarif_file: plumbline.sarif
  - run: plumbline check --report md --fail-on never -I copybooks src/*.cbl >> "$GITHUB_STEP_SUMMARY"
```

## GitLab

The code quality widget compares the report of a merge request with
that of its target branch, by each finding's fingerprint (see the
README), and shows what the change brings in or removes:

```yaml
plumbline:
  script:
    - plumbline check --report codeclimate --fail-on never -I copybooks src/*.cbl > gl-code-quality.json
    - plumbline check --report junit --fail-on never -I copybooks src/*.cbl > plumbline-junit.xml
  artifacts:
    reports:
      codequality: gl-code-quality.json
      junit: plumbline-junit.xml
```

## What a change reaches

`impact --changed` lists the programs a change reaches and the job
steps that run them, for a job that rebuilds or retests only those:

```sh
git fetch origin main
git diff --name-only origin/main...HEAD |
    plumbline impact --changed - --report json -I copybooks src/*.cbl jcl/*.jcl > impact.json
```

`impact.json` has the changed files of the run (`changed`) and the
others (`notInRun`), the programs (`programs`, each with its `name` and
`path`), and the job steps (`steps`, each with its `job` or `proc`,
`step`, `path`, `line`, and the program it `runs`, or `changed` for a
step of changed JCL).

## Settings

A `plumbline.conf` at the root of the repository holds the copybook
paths, the rules to enable or disable, and their severities, so that
the CI job, the command line, and the editor (`plumbline lsp`) apply
the same settings. See the README's configuration section.
