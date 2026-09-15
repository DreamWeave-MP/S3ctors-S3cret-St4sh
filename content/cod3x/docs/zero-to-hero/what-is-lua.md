---
title: What Is Lua?
description: The small embeddable language underneath OpenMW's scripting API.
weight: 10
extra:
  kind: guide
---

Lua is a small programming language. It is designed to be embedded inside another program, which means a host application can give Lua a carefully chosen set of functions and data.

OpenMW is the host. OpenMW starts Lua scripts, decides when they run, and provides engine modules such as `openmw.core`, `openmw.world`, and `openmw.ui`.

That distinction matters. Lua itself does not know what a cell, actor, record, or Morrowind save is. OpenMW teaches the script those things through its API.

## The pieces you need first

Lua stores values in local variables:

```lua
local greeting = 'Hello from Lua.'
local visits = 3
local enabled = true
```

It groups related values in tables:

```lua
local player = {
    name = 'Nerevarine',
    visits = 3,
}

print(player.name)
```

Functions take values and may return values:

```lua
local function greetingFor(name)
    return 'Hello, ' .. name .. '.'
end

print(greetingFor('Nerevarine'))
```

Control flow chooses what happens:

```lua
if player.visits > 0 then
    print('Welcome back.')
else
    print('First visit.')
end
```

The `..` operator joins strings. `nil` means “there is no value.” A missing table field usually produces `nil`, which is why this is common:

```lua
local cell = player.currentCell
if cell then
    print(cell.name)
end
```

## Lua in one sentence

Lua is a language for describing data and behavior. OpenMW is the program that gives that behavior access to a game world.

Do not try to learn every corner of Lua before writing a script. Continue to [Learn Enough Lua to Be Dangerous](@/cod3x/docs/zero-to-hero/lua-to-be-dangerous.md), then return to Lua's authoritative references when a syntax question appears.

## Learn more

- [Programming in Lua](https://www.lua.org/pil/) is the Lua project's recommended starting book. The freely available first edition describes Lua 5.0, so use it for language concepts and check the version notes below.
- The [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/manual.html) is the relevant language reference for OpenMW's Lua baseline.
- [OpenMW Lua Mental Model](@/cod3x/docs/getting-started/mental-model.md) explains what OpenMW adds around the language.
