#!/bin/sh
# Run plumbline over AWS's CardDemo, a sample mainframe application
# (CICS, VSAM, batch, and in its extensions DB2, IMS, and MQ), and
# summarize what it reports.
#
# CardDemo is published by Amazon Web Services under the Apache License
# 2.0. A fixed commit is downloaded from GitHub, checked against a known
# SHA-256, and kept under WORK-DIR; nothing of it is added to this
# repository.
#
# Usage: tools/corpus/run-carddemo.sh path/to/plumbline [WORK-DIR]
set -eu
bin=${1:?usage: run-carddemo.sh path/to/plumbline [WORK-DIR]}
work=${2:-build/corpus/carddemo}
commit=59cc6c2fd7ebd7ef7925cad552a01a4b8b6e4d5e
url=https://github.com/aws-samples/aws-mainframe-modernization-carddemo/archive/$commit.tar.gz
sha=a22c114ba79df73f86578495fbceb4062ae53e0cb335f5d2950598caf011684f
bin=$(cd "$(dirname "$bin")" && pwd)/$(basename "$bin")

mkdir -p "$work"
archive=$work/carddemo-$commit.tar.gz
if [ ! -f "$archive" ]; then
    echo "run-carddemo: downloading CardDemo $commit" >&2
    curl -fsSL -o "$archive.part" "$url"
    mv "$archive.part" "$archive"
fi
if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$archive" | cut -d' ' -f1)
else
    actual=$(shasum -a 256 "$archive" | cut -d' ' -f1)
fi
if [ "$actual" != "$sha" ]; then
    echo "run-carddemo: $archive does not have the expected SHA-256" >&2
    exit 1
fi

rm -rf "$work/src" "$work/out"
mkdir -p "$work/src" "$work/out"
tar -xzf "$archive" -C "$work/src" --strip-components 1
cd "$work/src"

# Every directory of copybooks (cpy, cpy-bms) and DB2 declarations
# (dcl); the CICS and MQ copybooks that come with those products are
# not part of CardDemo.
includes=$(find app \( -iname '*.cpy' -o -iname '*.dcl' \) | sed 's|/[^/]*$||' \
    | sort -u | sed 's/^/-I /' | tr '\n' ' ')
find app \( -iname '*.cbl' -o -iname '*.cob' \) | sort > ../programs.list
programs=$(wc -l < ../programs.list | tr -d ' ')
lines=$(cat $(cat ../programs.list) | wc -l | tr -d ' ')
# The jobs and procedures that run the programs, and the BMS maps of
# the online programs.
find app \( -iname '*.jcl' -o -iname '*.prc' \) | sort > ../jcl.list
jobs=$(wc -l < ../jcl.list | tr -d ' ')
find app -iname '*.bms' | sort > ../bms.list
maps=$(wc -l < ../bms.list | tr -d ' ')
cat ../programs.list ../jcl.list ../bms.list > ../inputs.list

# The few sources with tabs were written with stops every 4 columns.
start=$(date +%s)
# shellcheck disable=SC2086
"$bin" check --no-config $includes --tab-width 4 --fail-on never \
    --files-from ../inputs.list > ../out/findings.txt 2> ../out/diagnostics.txt || true
end=$(date +%s)
cd ../out

echo "programs:            $programs ($lines lines, without copybooks)"
echo "JCL members:         $jobs"
echo "BMS sources:         $maps"
echo "seconds, one run:    $((end - start))"
echo "with input errors:   $(grep ': error: ' diagnostics.txt | cut -d: -f1 | sort -u | wc -l | tr -d ' ')"
echo
echo "input diagnostics:"
sed -n -E 's/.*: (error|warning): (.*)$/\2/p' diagnostics.txt | sort | uniq -c | sort -rn
echo
echo "findings by rule:"
sed -n 's/.*\[\(PLB-[A-Z0-9]*\)\]$/\1/p' findings.txt | sort | uniq -c | sort -rn
