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
    "runtime.plugin": "C:/Modding/Tools/Cod3x/omw_context_plugin.lua"
}
```

This file is meant for your mod workspace, not your OpenMW install directory.
