#!/bin/sh
# Runs the samples' tests: every sample's, or those of the samples named after it, such as coinrun. The samples are ONLR's tests (DESIGN.md, section 16).
# A sample's test of the engine is its test.lua: LÖVE runs the sample with --test and SDL's offscreen driver, and the sample checks itself and quits
# with a status. Before it runs, the sample gets the engine in packages/onlr/, as a project holds it, and the tests' helper in packages/check.lua;
# git ignores both copies. LOVE names LÖVE's executable, love if it is not set.
# A sample's test of the editor is its editortest.lua, an OpenECS test: a Debug build of OpenECS runs it on a copy of the sample in
# build/tests/work/, since the test writes the sample's files. OPENECS names OpenECS's executable, OpenECS/OpenECS if it is not set:
# OpenECS laid out as a release has it, in the folder OpenECS/ of this repository, which git ignores. Without it, these tests are skipped.
# It prints the log of each test that fails, and the lines that a sample reports with "report:", such as the frame time of samples/speed.
set -u
cd "$(dirname "$0")/../.." || exit 2

love="${LOVE:-love}"
openecs="${OPENECS:-$PWD/OpenECS/OpenECS}"
skipped=0
if [ $# -eq 0 ]; then
    set -- $(ls samples 2> /dev/null)
fi

mkdir -p build/tests
failed=0

# every sample gets the engine and the helper first, since the link's test starts players on other samples
for sample in samples/*/; do
    rm -rf "${sample}packages/onlr"
    mkdir -p "${sample}packages"
    cp -r engine "${sample}packages/onlr"
    cp samples/check.lua "${sample}packages/check.lua"
done

for name in "$@"; do
    sample="samples/${name%/}"
    name=$(basename "$sample")
    if [ -f "$sample/editortest.lua" ]; then
        if [ -x "$openecs" ]; then
            work="build/tests/work/$name"
            rm -rf "$work"
            mkdir -p build/tests/work
            cp -r "$sample" "$work"
            log="$PWD/build/tests/$name.editor.log"
            # the play player, which the editor starts, opens LÖVE's window: the offscreen driver gives it one that no screen shows
            if ! (cd "$work" && LOVE="$love" SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null timeout "${TEST_TIMEOUT:-120}" "$openecs" --test editortest.lua > "$log" 2>&1); then
                echo "FAIL $name, the editor's test:"
                tail -n 40 "$log"
                failed=1
            fi
        else
            skipped=1
        fi
    fi

    [ -f "$sample/test.lua" ] || continue

    log="build/tests/$name.log"
    # the null driver of OpenAL Soft, LÖVE's sound, needs no sound device; a test that never ends stops after TEST_TIMEOUT seconds, 120 if it is not set
    if LOVE="$love" SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null timeout "${TEST_TIMEOUT:-120}" "$love" "$sample" --test > "$log" 2>&1; then
        grep "^report: " "$log" | sed "s/^report: /$name: /"
    else
        echo "FAIL $name (status $?):"
        grep -v -E "^\[ALSOFT\]" "$log" | tail -n 40
        failed=1
    fi
done

if [ $skipped -eq 1 ]; then
    echo "The editor's tests are skipped: no OpenECS at $openecs"
fi

exit $failed
