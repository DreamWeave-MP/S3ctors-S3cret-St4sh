+++
title = "example config"
date = 2026-07-01

[taxonomies]
tags = [ "Different", "Tag", "Names"]

[extra]
hide_download_bar = true
version = 1.0
+++

# Cod3x LuaLS example config

Copy `.luarc.json` from this directory into the root folder of your OpenMW-Lua
mod project, then replace `/absolute/path/to/Cod3x` with the folder where you
extracted Cod3x.

Use forward slashes in paths, even on Windows:

```json
{
    "runtime.version": "LuaJIT",
    "workspace.library": [
        "C:/Modding/Tools/Cod3x"
    ],
    "runtime.plugin": "C:/Modding/Tools/Cod3x/omw_context_plugin.lua",
    "language.fixIndent": false,
    "typeFormat.config": {
        "format_line": "false"
    }
}
```

`language.fixIndent` and `typeFormat.config.format_line` are LuaLS settings used
to disable VSCode/VSCodium on-type formatting while keeping Cod3x's virtual
LuaLS transforms enabled.  The current LuaLS docs list them at
<https://luals.github.io/wiki/settings/#languagefixindent> and
<https://luals.github.io/wiki/settings/#typeformatconfig>.

This file is meant for your mod workspace, not your OpenMW install directory.

Cod3x validates OpenMW API availability and interface surfaces in the current
file. It cannot reliably validate whether an arbitrary user module's
`---@omw-context` is compatible with every importer because LuaLS may process
an importer before the imported module and does not provide a reliable
post-resolution diagnostic hook.
