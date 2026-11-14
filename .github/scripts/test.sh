#!/bin/sh
# Runs the samples' tests with shuild's --test: every sample's, or those of the samples named after it, such as coinrun.
# The samples are ONLR's tests (DESIGN.md, section 16), and shuild.c says how each runs. LOVE names LÖVE's executable, love if it is not set.
# The editor's tests need OpenECS laid out as a release in OpenECS/, which git ignores. Without it, they are skipped.
# It prints the lines that a sample reports, such as the frame time of samples/speed, and the log's end of each test that fails.
set -u
cd "$(dirname "$0")/../.." || exit 2

mkdir -p build/tests
if ! gcc shuild.c -o shuild.ignore -Wno-format-truncation 2> build/tests/shuild.log; then
    cat build/tests/shuild.log
    exit 2
fi

./shuild.ignore --test "$@" > build/tests/tests.log 2>&1
status=$?
grep -v -E "^pass |all [0-9]+ tests passed" build/tests/tests.log
exit $status
