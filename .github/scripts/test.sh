#!/bin/sh
# Runs the samples' tests: every sample's, or those of the samples named after it, such as coinrun. The samples are ONLR's tests (DESIGN.md, section 16).
# A sample's test of the engine is its test.lua: LÖVE runs the sample with --test and SDL's offscreen driver, and the sample checks itself and quits
# with a status. Before it runs, the sample gets the engine in packages/onlr/, as a project holds it, and the tests' helper in packages/check.lua;
# git ignores both copies. LOVE names LÖVE's executable, love if it is not set.
# It prints the log of each test that fails, and the lines that a sample reports with "report:", such as the frame time of samples/speed.
set -u
cd "$(dirname "$0")/../.." || exit 2

love="${LOVE:-love}"
if [ $# -eq 0 ]; then
    set -- $(ls samples 2> /dev/null)
fi

mkdir -p build/tests
failed=0

for name in "$@"; do
    sample="samples/${name%/}"
    name=$(basename "$sample")
    [ -f "$sample/test.lua" ] || continue

    rm -rf "$sample/packages/onlr"
    mkdir -p "$sample/packages"
    cp -r engine "$sample/packages/onlr"
    cp samples/check.lua "$sample/packages/check.lua"

    log="build/tests/$name.log"
    # the null driver of OpenAL Soft, LÖVE's sound, needs no sound device; a test that never ends stops after two minutes
    if SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null timeout 120 "$love" "$sample" --test > "$log" 2>&1; then
        grep "^report: " "$log" | sed "s/^report: /$name: /"
    else
        echo "FAIL $name (status $?):"
        grep -v -E "^\[ALSOFT\]" "$log" | tail -n 40
        failed=1
    fi
done

exit $failed
