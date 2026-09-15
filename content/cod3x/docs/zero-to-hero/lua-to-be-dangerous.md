---
title: Learn Enough Lua to Be Dangerous
description: The Lua syntax you need to read and write OpenMW scripts without pretending to write a Lua textbook.
weight: 20
extra:
  kind: guide
---

You do not need to memorize all of Lua. You need enough to read Cod3x examples, change them safely, and recognize when a problem is language syntax rather than OpenMW behavior.

For the full language, use [Programming in Lua](https://www.lua.org/pil/) and the [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/manual.html). This page is the field kit.

## Scope with `local`

Use `local` for values owned by this file or block:

```lua
local count = 0

local function increment()
    count = count + 1
end
```

Without `local`, Lua may create or modify a global variable. Accidental globals make unrelated scripts interfere with one another. Make ownership visible.

## Tables are the everyday container

Tables can act like records, lists, or maps:

```lua
local settings = {
    enabled = true,
    names = { 'Ash', 'Balmora' },
}

settings.enabled = false
settings.names[1] = 'Ald-ruhn'
```

Use `ipairs` for a sequence and `pairs` for a general table:

```lua
for index, name in ipairs(settings.names) do
    print(index, name)
end

for key, value in pairs(settings) do
    print(key, value)
end
```

## Functions and multiple returns

Functions are values. They can be stored in tables and passed to other functions:

```lua
local function divide(total, parts)
    return total / parts, total % parts
end

local quotient, remainder = divide(7, 3)
```

That is why OpenMW handler tables work: a handler name points to a function that OpenMW calls later.

## `:` versus `.`

The colon is shorthand for passing the table as the first argument:

```lua
function player:greet()
    return self.name
end

player:greet()
```

is equivalent to:

```lua
player.greet(player)
```

Use the form the API expects. A method documented as `object:sendEvent(...)` needs the colon call. A function documented as `types.Actor.objectIsInstance(object)` needs the explicit object argument.

## `require` loads a module

`require` asks Lua for a module and gives you the value that module returns:

```lua
local core = require 'openmw.core'
print(core.getGameTime())
```

Your own modules work the same way:

```lua
local mathHelpers = require 'scripts.myMod.mathHelpers'
```

In OpenMW, the module path is resolved through the virtual filesystem, not by guessing a relative path from the current file. Read [VFS and Paths](@/cod3x/docs/getting-started/vfs-and-paths.md) when your module cannot be found.

## Closures are functions carrying local state

This function remembers `count` because the returned function closes over it:

```lua
local function makeCounter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end
```

Closures are useful for handlers and private state. They are also allocations, so do not manufacture them in a per-frame loop without a reason.

## What can wait

Metatables, coroutines, iterators, and environments matter later. You will meet them when an OpenMW problem actually needs them. Do not start by building a language course inside your mod.

Next, see [What Is OpenMW Lua?](@/cod3x/docs/zero-to-hero/what-is-openmw-lua.md).
