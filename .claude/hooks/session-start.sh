#!/bin/sh
# Claude Code runs this when a session starts (.claude/settings.json). In a cloud session only, it installs what the checks and the tests need,
# as CI has them, so check.sh and test.sh work at once. Each step is skipped when it is done.
set -eu

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"

# EGL, with Mesa drawing in software, which LÖVE needs to draw with SDL's offscreen driver
if ! dpkg -s libegl1 libegl-mesa0 libgl1-mesa-dri > /dev/null 2>&1; then
    sudo apt-get update > /dev/null 2>&1
    sudo apt-get install -y libegl1 libegl-mesa0 libgl1-mesa-dri > /dev/null 2>&1
fi

# LÖVE 11.5, its AppImage unpacked, which needs no FUSE; test.sh runs love from the PATH
if [ "$(love --version 2> /dev/null)" != "LOVE 11.5 (Mysterious Mysteries)" ]; then
    sudo mkdir -p /opt/love
    sudo curl -sSL -o /opt/love/love.AppImage https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage
    sudo chmod +x /opt/love/love.AppImage
    (cd /opt/love && sudo ./love.AppImage --appimage-extract > /dev/null)
    sudo ln -sf /opt/love/squashfs-root/AppRun /usr/local/bin/love
fi

# the Lua language server of the check Lua (LuaLS), which check.sh runs on changed Lua files
luals=$(sed -n 's/.*LUALS_VERSION: *//p' .github/workflows/checks.yml | head -n 1)
if [ "$(lua-language-server --version 2> /dev/null)" != "$luals" ]; then
    sudo mkdir -p /opt/luals
    curl -sSL "https://github.com/LuaLS/lua-language-server/releases/download/$luals/lua-language-server-$luals-linux-x64.tar.gz" | sudo tar -xz -C /opt/luals
    sudo ln -sf /opt/luals/bin/lua-language-server /usr/local/bin/lua-language-server
fi

# LÖVE's definitions for LuaLS, which .luarc.json names, at the commit that the check Lua (LuaLS) takes
love2d=$(sed -n 's/.*LOVE2D_DEFINITIONS: *//p' .github/workflows/checks.yml | head -n 1)
if [ "$(git -C build/love2d rev-parse HEAD 2> /dev/null)" != "$love2d" ]; then
    rm -rf build/love2d
    git clone -q https://github.com/LuaCATS/love2d build/love2d
    git -C build/love2d checkout -q "$love2d"
fi

exit 0
