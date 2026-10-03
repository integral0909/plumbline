#!/bin/sh
# Run plumbline over the programs of GnuCOBOL's run-time test suite and
# summarize what it reports.
#
# Every program there compiles and runs with GnuCOBOL, so each input
# error Plumbline reports, and each undefined or ambiguous name it
# finds (PLB-C009, PLB-C010), points at something Plumbline does not
# understand yet, or at a GnuCOBOL extension it does not know.
#
# The suite is part of GnuCOBOL (GPL-3.0-or-later). It is downloaded
# from ftp.gnu.org, checked against a known SHA-256 (the same release
# CI builds the compiler from), and kept under WORK-DIR; nothing of it
# is added to this repository.
#
# Usage: tools/corpus/run-gnucobol.sh path/to/plumbline [WORK-DIR]
set -eu
bin=${1:?usage: run-gnucobol.sh path/to/plumbline [WORK-DIR]}
work=${2:-build/corpus/gnucobol}
version=3.2
url=https://ftp.gnu.org/gnu/gnucobol/gnucobol-$version.tar.xz
sha=3bb48af46ced4779facf41fdc2ee60e4ccb86eaa99d010b36685315df39c2ee2
here=$(cd "$(dirname "$0")" && pwd)
bin=$(cd "$(dirname "$bin")" && pwd)/$(basename "$bin")

mkdir -p "$work"
archive=$work/gnucobol-$version.tar.xz
if [ ! -f "$archive" ]; then
    echo "run-gnucobol: downloading GnuCOBOL $version" >&2
    curl -fsSL -o "$archive.part" "$url"
    mv "$archive.part" "$archive"
fi
if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$archive" | cut -d' ' -f1)
else
    actual=$(shasum -a 256 "$archive" | cut -d' ' -f1)
fi
if [ "$actual" != "$sha" ]; then
    echo "run-gnucobol: $archive does not have the expected SHA-256" >&2
    exit 1
fi

rm -rf "$work/src" "$work/out" "$work/gnucobol-$version"
mkdir -p "$work/out"
# The test programs, and the copybooks GnuCOBOL installs for them
# (the EXTFH and screen I/O definitions).
tar -xJf "$archive" -C "$work" "gnucobol-$version/tests/testsuite.src" \
    "gnucobol-$version/copy"
copy_dir=$(cd "$work/gnucobol-$version/copy" && pwd)
python3 "$here/split_gnucobol.py" \
    "$work/gnucobol-$version/tests/testsuite.src" "$work/src" >/dev/null

start=$(date +%s)
programs=0
skipped=0
tab=$(printf '\t')
while IFS="$tab" read -r dir program format dialect title; do
    case $format in
        fixed|free|variable|xopen|terminal|cobolx) ;;
        *) skipped=$((skipped + 1)); continue ;;
    esac
    programs=$((programs + 1))
    name=$dir--$program
    (cd "$work/src/$dir" &&
        "$bin" check --no-config --format "$format" -I . -I "$copy_dir" \
            --fail-on never \
            "$program" > "../../out/$name.out" 2> "../../out/$name.err") || true
done < "$work/src/MANIFEST"
end=$(date +%s)
cd "$work/out"

with_errors=$(grep -l ': error: ' *.err 2>/dev/null | wc -l | tr -d ' ')
with_names=$(grep -l -E '\[PLB-C0(09|10)\]$' *.out 2>/dev/null | wc -l | tr -d ' ')
echo "programs:            $programs ($skipped in formats Plumbline does not read)"
echo "seconds:             $((end - start))"
echo "with input errors:   $with_errors"
echo "with unknown names:  $with_names (PLB-C009 or PLB-C010)"
echo
echo "input diagnostics:"
cat *.err | sed -n 's/.*\[\([A-Z][A-Z]*[0-9][0-9]*\)\]$/\1/p' | sort | uniq -c | sort -rn
echo
echo "names reported as undefined or ambiguous:"
cat *.out | sed -n -E 's/^[^ ]* (error|warning|note): (.*) (is not declared|names more than one).*\[PLB-C0(09|10)\]$/\2/p' \
    | sort | uniq -c | sort -rn | head -40
