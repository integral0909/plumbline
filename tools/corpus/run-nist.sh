#!/bin/sh
# Run plumbline over the NIST COBOL-85 test suite and summarize what it
# reports: how many programs it reads without input errors, which input
# diagnostics remain, the findings by rule, and how long it took.
#
# The suite is a US government work, in the public domain. It is
# downloaded from the GnuCOBOL project's mirror, checked against a known
# SHA-256, and kept under WORK-DIR; nothing of it is added to this
# repository.
#
# Usage: tools/corpus/run-nist.sh path/to/plumbline [WORK-DIR]
set -eu
bin=${1:?usage: run-nist.sh path/to/plumbline [WORK-DIR]}
work=${2:-build/corpus/nist}
url=https://sourceforge.net/projects/gnucobol/files/nist/newcob.val.tar.gz/download
sha=e4513f26a9b38911f7bf882fe3d3339a80b45cabc2caf85eb3055b0f5ce87ee0
here=$(cd "$(dirname "$0")" && pwd)
bin=$(cd "$(dirname "$bin")" && pwd)/$(basename "$bin")

mkdir -p "$work"
archive=$work/newcob.val.tar.gz
if [ ! -f "$archive" ]; then
    echo "run-nist: downloading the suite" >&2
    curl -fsSL -o "$archive.part" "$url"
    mv "$archive.part" "$archive"
fi
if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$archive" | cut -d' ' -f1)
else
    actual=$(shasum -a 256 "$archive" | cut -d' ' -f1)
fi
if [ "$actual" != "$sha" ]; then
    echo "run-nist: $archive does not have the expected SHA-256" >&2
    exit 1
fi

rm -rf "$work/src" "$work/out"
mkdir -p "$work/out"
tar -xzf "$archive" -C "$work"
python3 "$here/split_nist.py" "$work/newcob.val" "$work/src" >/dev/null

start=$(date +%s)
cd "$work/src"
for f in *.cob; do
    name=${f%.cob}
    "$bin" check --no-config -I copy --fail-on never "$f" \
        > "../out/$name.out" 2> "../out/$name.err" || true
done
end=$(date +%s)
# All programs in one run, as a project would check its whole source
# tree. Its findings must be those of the runs above, put together.
one_start=$(date +%s)
"$bin" check --no-config -I copy --fail-on never *.cob \
    > ../out/all-in-one.txt 2> ../out/all-in-one.log || true
one_end=$(date +%s)
cd ../out

programs=$(ls ../src/*.cob | wc -l | tr -d ' ')
lines=$(cat ../src/*.cob ../src/copy/*.cpy | wc -l | tr -d ' ')
with_errors=$(grep -l ': error: ' *.err 2>/dev/null | wc -l | tr -d ' ')
echo "programs:            $programs ($lines lines with copybooks)"
echo "seconds:             $((end - start)) (one run per program)"
echo "seconds, one run:    $((one_end - one_start))"
cat *.out | sort > per-program.sorted
if sort all-in-one.txt | cmp -s - per-program.sorted; then
    echo "one run agrees:      yes"
else
    echo "one run agrees:      NO (compare all-in-one.txt with the .out files)"
fi
rm -f per-program.sorted
echo "with input errors:   $with_errors"
echo
echo "input diagnostics:"
cat *.err | sed -n 's/.*\[\([A-Z][A-Z]*[0-9][0-9]*\)\]$/\1/p' | sort | uniq -c | sort -rn
echo
echo "findings by rule:"
cat *.out | sed -n 's/.*\[\(PLB-[A-Z0-9]*\)\]$/\1/p' | sort | uniq -c | sort -rn
