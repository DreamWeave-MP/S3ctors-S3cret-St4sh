---
title: Your First OpenMW Lua Mod
description: Register one player script, press a key, and see OpenMW call your code.
weight: 40
extra:
  kind: guide
---

The first victory should happen quickly: one file, one registration, one key press, one message.

## Make the project tree

Create a data directory that OpenMW can see:

```text
MyFirstMod/
├── MyFirstMod registration file
└── scripts/
    └── MyFirstMod/
        └── player.lua
```

Add that directory as a data directory in `openmw.cfg`, or use the equivalent data-directory control in your launcher. A data directory is simply a layer of files OpenMW can see through its virtual filesystem.

## Register the player script

Put this in the `MyFirstMod` registration file. Its filename ends in `.omwscripts`:

```text
PLAYER: scripts/MyFirstMod/player.lua
```

The registration says: run this file as a player script. The path uses the VFS spelling and is case-sensitive on systems where the filesystem is case-sensitive.

## Write the script

Put this in `scripts/MyFirstMod/player.lua`:

```lua
---@omw-context player

local ui = require 'openmw.ui'

return {
    engineHandlers = {
        onKeyPress = function(key)
            if key.symbol == 'x' then
                ui.showMessage 'Hello from Lua.'
            end
        end,
    },
}
```

The context annotation tells Cod3x what environment this file expects. `openmw.ui` is available to player scripts. `onKeyPress` is a handler OpenMW calls when a key is pressed. The `key.symbol` value for the X key is the string `'x'`.

## Run it

1. Start OpenMW with the data directory active.
2. Load a game where the player script can run.
3. Press **X**.
4. Look for “Hello from Lua.”

If the message appears, congratulations: you have written an OpenMW Lua mod. Everything else in Cod3x is elaboration.

The repository also contains a checked-in copy of this example in [`content/cod3x/examples/zero-to-hero/`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/tree/main/content/cod3x/examples/zero-to-hero).

## If nothing happens

Check the smallest boundary first:

- Is the data directory active in `openmw.cfg`?
- Is the `MyFirstMod` registration file in that directory rather than only in your source editor?
- Does the registered path match the file's case exactly?
- Did OpenMW report a script or registration error in `openmw.log`?
- Did you press X while the game was running rather than in a menu?

The [VFS and Paths](@/cod3x/docs/getting-started/vfs-and-paths.md) page explains the file visibility model. [Debugging OpenMW Lua](@/cod3x/docs/getting-started/debugging.md) explains how to keep the first useful error.

Next, make your editor understand why this script works in [What the Hell Is a Language Server?](@/cod3x/docs/zero-to-hero/language-server.md).
