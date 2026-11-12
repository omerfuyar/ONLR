#!/bin/sh
# Formats the tool's C files with clang-format and checks them with clang-tidy (.clang-format, .clang-tidy), and checks the Lua files with
# the Lua language server when it is installed, for agents before they commit.
# With no files named, it takes the C files of plugins/ and the Lua files that differ from dev, committed or not.
# It prints only the problems, and fails when clang-tidy or the Lua language server finds one.
# OPENECS names the folder of OpenECS's release, whose include/ holds the plugin interface, as shuild.c's -o does; OpenECS/ if it is not set.
set -u
cd "$(dirname "$0")/../.." || exit 2

if [ $# -eq 0 ]; then
    base=$(git merge-base HEAD origin/dev 2> /dev/null || echo HEAD)
    # shellcheck disable=SC2046
    set -- $({
        git diff --name-only "$base"
        git ls-files --others --exclude-standard
    } | grep -E '(^plugins/.*\.[ch]$|^.*\.lua$)' | sort -u)
fi

files=
lua=
for file in "$@"; do
    case "$file" in
    *.lua) [ -f "$file" ] && lua="$lua $file" ;;
    *) [ -f "$file" ] && files="$files $file" ;;
    esac
done

failed=0

# LuaLS checks one file only as part of its folder, so it checks the whole folder, as the check Lua (LuaLS) does, and the problems of the files named here are printed;
# its lines name a problem's file first, such as plugins/ui/init.lua:2:11 [Warning] ..., and the two lines after show where
if [ -n "$lua" ] && command -v lua-language-server > /dev/null; then
    lua-language-server --check="$PWD" --checklevel=Warning --check_format=pretty --logpath=luals.ignore > luals.ignore.log 2>&1
    if tr '\r' '\n' < luals.ignore.log | sed 's/\x1b\[[0-9;]*m//g' | awk -v files="$lua" '
        BEGIN { split(files, list, " "); for (i in list) named[list[i]] = 1 }
        /:[0-9]+:[0-9]+ \[/ { split($0, parts, ":"); show = parts[1] in named; if (show) { found = 1; print }; next }
        /^ +[^ ]/ && show { print; next }
        { show = 0 }
        END { exit !found }'; then
        failed=1
    fi
    rm -rf luals.ignore.log luals.ignore
fi

[ -z "$files" ] && exit $failed

# shellcheck disable=SC2086
clang-format -i $files || exit 2

include="${OPENECS:-OpenECS}/include"
if [ ! -f "$include/OpenECS.h" ]; then
    echo "clang-tidy needs OpenECS's release: OPENECS names its folder, as shuild.c's -o does"
    exit 2
fi

for file in $files; do
    case "$file" in
    *.c) ;;
    *) continue ;;
    esac

    # the flags of shuild.c: C23 and the plugin interface
    if ! clang-tidy --quiet "$file" -- -std=c23 -isystem "$include" > tidy.ignore.log 2>&1; then
        grep -E "(warning|error):" -A3 tidy.ignore.log | grep -v -E "^[0-9]+ warnings? generated"
        failed=1
    fi
done

rm -f tidy.ignore.log
exit $failed
