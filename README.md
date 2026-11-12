# OpenECS template

Template of a tool made with [OpenECS](https://github.com/omerfuyar/OpenECS): a preset, a plugin in Lua and a plugin in C, a test, and a guide that goes through each part. Press "Use this template" on GitHub to make your own repository from it.

The tool is a board of notes beside a small panel in C. Unpack an [OpenECS release](https://github.com/omerfuyar/OpenECS/releases) into `OpenECS/`, then:

``` shell
git submodule update --init
cc shuild.c -o shuild && ./shuild
OpenECS/OpenECS --fresh --preset preset.lua
```

[GUIDE.md](GUIDE.md) explains the preset, plugins, panels, etc. and how to ship your tool.
