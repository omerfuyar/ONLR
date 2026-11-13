#!/bin/sh
# Checks ONLR's Lua files with the Lua language server when it is installed, for agents before they commit.
# With no files named, it takes the Lua files that differ from dev, committed or not.
# It prints only the problems, and fails when the Lua language server finds one.
set -u
cd "$(dirname "$0")/../.." || exit 2

if [ $# -eq 0 ]; then
    base=$(git merge-base HEAD origin/dev 2> /dev/null || echo HEAD)
    # shellcheck disable=SC2046
    set -- $({
        git diff --name-only "$base"
        git ls-files --others --exclude-standard
    } | grep -E '\.lua$' | sort -u)
fi

lua=
for file in "$@"; do
    [ -f "$file" ] && lua="$lua $file"
done

[ -z "$lua" ] && exit 0
if ! command -v lua-language-server > /dev/null; then
    echo "The Lua language server is not installed: the Lua files are not checked."
    exit 0
fi

# LuaLS checks one file only as part of its folder, so it checks the whole folder, as the check Lua (LuaLS) does, and the problems of the files
# named here are printed; its lines name a problem's file first, such as engine/node.lua:2:11 [Warning] ..., and the two lines after show where
mkdir -p build
lua-language-server --check="$PWD" --checklevel=Warning --check_format=pretty --logpath=build/luals > build/luals.log 2>&1
if tr '\r' '\n' < build/luals.log | sed 's/\x1b\[[0-9;]*m//g' | awk -v files="$lua" '
    BEGIN { split(files, list, " "); for (i in list) named[list[i]] = 1 }
    /:[0-9]+:[0-9]+ \[/ { split($0, parts, ":"); show = parts[1] in named; if (show) { found = 1; print }; next }
    /^ +[^ ]/ && show { print; next }
    { show = 0 }
    END { exit !found }'; then
    exit 1
fi

exit 0
