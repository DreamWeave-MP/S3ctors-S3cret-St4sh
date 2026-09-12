---
title: Small Utilities
description: Use tiny plain-Lua helpers for table clearing and no-op callbacks.
weight: 78
extra:
  kind: api
---

These helpers are deliberately minimal. They are useful at seams where a callback or table operation is optional, but they should not be mistaken for a framework or a performance strategy.

## clear

{{ api_signature(value="require 'scripts.s3.clear'(table) → nil") }}

`clear(t)` removes every key from `t` in place. It uses `table.clear` when the runtime provides it and otherwise falls back to iterating with `next`. The table identity is preserved; the function does not copy or return a replacement.

```lua
local clear = require 'scripts.s3.clear'
clear(workList)
```

The input must be a table. Clearing while another part of the program retains the same table is intentional; clearing does not release references held by other values.

## nullFunction

{{ api_signature(value="require 'scripts.s3.nullFunction' → function(...)") }}

`nullFunction` is a shared no-op callback. It accepts and ignores any arguments and returns no values.

```lua
local nullFunction = require 'scripts.s3.nullFunction'
local onDone = optionalCallback or nullFunction
onDone(result)
```

Both modules are plain Lua and have no OpenMW context or lifecycle requirements. `clear` is used by [S3maphore's playlist rules](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fs3maphore%2F00%20Core%2Fscripts%2Fs3%2Fmusic%2FplaylistRules.lua) and [music core](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fs3maphore%2F00%20Core%2Fscripts%2Fs3%2Fmusic%2Fcore.lua); `nullFunction` appears in [S3UI's player camera](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fs3ui%2Fscripts%2Fs3ui%2Fplayer_camera.lua), [S3UI inventory](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fs3ui%2Fscripts%2Fs3ui%2Finventory%2Fwindow.lua), and the [Static Switching System](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fstatic_switching_system%2FScripts%2FstaticSwitcher%2Fglobal.lua). Use ordinary local code instead when the helper does not make an optional boundary clearer.
