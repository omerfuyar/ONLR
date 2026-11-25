#!/bin/sh
# Makes ONLR's archive for one platform (DESIGN.md, section 15.3): OpenECS's release, LÖVE 11.5, and ONLR's plugin, preset,
# packages and gallery, with a program that starts the editor. Nothing else is installed to run it.
#   .github/scripts/package.sh VERSION OPENECS_VERSION PLATFORM
# such as .github/scripts/package.sh 0.1.0 0.7.0 linux-x86_64. PLATFORM is linux-x86_64 or windows-x86_64.
# It writes dist/onlr-VERSION-PLATFORM.tar.gz on Linux and dist/onlr-VERSION-PLATFORM.zip on Windows. It runs on Linux for
# both, since it unpacks LÖVE's AppImage, and keeps what it downloads in build/release/, checked against each file's hash.
set -eu
cd "$(dirname "$0")/../.."

if [ $# -ne 3 ]; then
    echo "Usage: $0 VERSION OPENECS_VERSION PLATFORM" >&2
    exit 2
fi
version=$1
openecs=$2
platform=$3

case "$platform" in
linux-x86_64)
    love_file=love-11.5-x86_64.AppImage
    love_sum=65a673406431eff7167a15a032bf7a2e4ba50108e091eb7b176465831f9b5e00
    openecs_file=openecs-$openecs-linux-x86_64.tar.gz
    ;;
windows-x86_64)
    love_file=love-11.5-win64.zip
    love_sum=ba6e56be2685e53c817749c4a5007f51137136fe5a3ab64920508babc2e74369
    openecs_file=openecs-$openecs-windows-x86_64.zip
    ;;
*)
    echo "The platform is linux-x86_64 or windows-x86_64, not $platform." >&2
    exit 2
    ;;
esac

# The preset names ONLR's version: an archive of another version would show the wrong one.
if ! grep -q "version = \"$version\"" preset.lua; then
    echo "preset.lua does not name the version $version." >&2
    exit 1
fi

downloads=build/release/downloads
mkdir -p "$downloads"

# Downloads a file once, and checks it against its SHA-256 hash.
fetch() {
    url=$1 file=$2 sum=$3
    if [ ! -f "$downloads/$file" ]; then
        curl -sSfL -o "$downloads/$file.part" "$url"
        mv "$downloads/$file.part" "$downloads/$file"
    fi
    if ! echo "$sum  $downloads/$file" | sha256sum -c --quiet -; then
        rm -f "$downloads/$file"
        echo "$file does not match its hash, and is removed." >&2
        exit 1
    fi
}

# OpenECS's release, checked against the hashes of its own SHA256SUMS
base=https://github.com/omerfuyar/OpenECS/releases/download/v$openecs
if ! curl -sSfL -o "$downloads/openecs-$openecs-SHA256SUMS" "$base/SHA256SUMS" 2> /dev/null; then
    echo "OpenECS $openecs has no release to download from https://github.com/omerfuyar/OpenECS/releases/tag/v$openecs." >&2
    echo "The archive is made once OpenECS $openecs is released." >&2
    exit 1
fi
openecs_sum=$(grep " $openecs_file\$" "$downloads/openecs-$openecs-SHA256SUMS" | cut -d' ' -f1)
if [ -z "$openecs_sum" ]; then
    echo "OpenECS $openecs's SHA256SUMS does not name $openecs_file." >&2
    exit 1
fi
fetch "$base/$openecs_file" "$openecs_file" "$openecs_sum"
fetch "https://github.com/love2d/love/releases/download/11.5/$love_file" "$love_file" "$love_sum"

# The samples' packages, which the repository does not keep: the gallery takes its own
cc shuild.c -o shuild.ignore -Wno-format-truncation
./shuild.ignore > build/release/shuild.log 2>&1 || { cat build/release/shuild.log; exit 1; }

name=onlr-$version-$platform
work=build/release/$platform
out=$work/$name
rm -rf "$work"
mkdir -p "$out" dist

# OpenECS's release, unchanged, in OpenECS/
mkdir -p "$work/openecs"
case "$openecs_file" in
*.tar.gz) tar -xzf "$downloads/$openecs_file" -C "$work/openecs" ;;
*.zip) unzip -q "$downloads/$openecs_file" -d "$work/openecs" ;;
esac
mv "$work/openecs/"* "$out/OpenECS"

# LÖVE, unchanged, in love/: the AppImage's contents on Linux, so it runs without the system's AppImage support
case "$platform" in
linux-x86_64)
    cp "$downloads/$love_file" "$work/love.AppImage"
    chmod +x "$work/love.AppImage"
    (cd "$work" && ./love.AppImage --appimage-extract > /dev/null)
    mv "$work/squashfs-root" "$out/love"
    ;;
windows-x86_64)
    unzip -q "$downloads/$love_file" -d "$work"
    mv "$work/love-11.5-win64" "$out/love"
    ;;
esac

# ONLR's own files, laid out as the repository holds them, so the plugin finds the engine and the definitions where it
# looks for them (DESIGN.md, section 13.1)
cp -r plugins packages preset.lua LICENSE.md "$out/"
# The guide as it is at this release, with the documents that it links to (DESIGN.md, section 17)
cp GUIDE.md OVERVIEW.md DESIGN.md "$out/"
mkdir -p "$out/dependencies/love2d"
cp -r dependencies/love2d/library "$out/dependencies/love2d/"
cp dependencies/love2d/LICENSE* "$out/dependencies/love2d/" 2> /dev/null || true

# The gallery, as a project to open, without its test
cp -r samples/gallery "$out/gallery"
rm -f "$out/gallery/test.lua" "$out/gallery/packages/check.lua"
rm -rf "$out/gallery/.onlr"

# The program that starts the editor, and what to read first
case "$platform" in
linux-x86_64)
    cat > "$out/ONLR" << 'EOF'
#!/bin/sh
# Starts ONLR's editor. A project's folder named after it opens the project: ./ONLR gallery
here=$(cd "$(dirname "$0")" && pwd)
exec "$here/OpenECS/OpenECS" --preset "$here/preset.lua" "$@"
EOF
    chmod +x "$out/ONLR"
    start="./ONLR gallery"
    install="./ONLR --install"
    ;;
windows-x86_64)
    printf '@rem Starts ONLR'"'"'s editor. A project'"'"'s folder named after it opens the project: ONLR.cmd gallery\r\n@start "" "%%~dp0OpenECS\\OpenECS.exe" --preset "%%~dp0preset.lua" %%*\r\n' > "$out/ONLR.cmd"
    start="ONLR.cmd gallery"
    install="ONLR.cmd --install"
    ;;
esac

cat > "$out/README.md" << EOF
# ONLR $version

ONLR is an editor and an engine for 2D games that run on LÖVE. This archive holds all it needs: OpenECS $openecs, the editor's
base, in \`OpenECS/\`, and LÖVE 11.5 in \`love/\`, which runs your game. Nothing is installed.

- Start the editor with \`ONLR\`. To open the gallery, a project that shows what ONLR does: \`$start\`.
- \`$install\` adds ONLR to your system's list of programs; \`--uninstall\` removes it.
- Your projects can be anywhere. A new project gets the engine, \`packages/onlr/\`, from this folder.

More: https://github.com/omerfuyar/ONLR
EOF

case "$platform" in
linux-x86_64) tar -czf "dist/$name.tar.gz" -C "$work" "$name" ;;
windows-x86_64)
    rm -f "dist/$name.zip"
    (cd "$work" && zip -qr "../../../dist/$name.zip" "$name")
    ;;
esac
echo "dist/$name: done"
