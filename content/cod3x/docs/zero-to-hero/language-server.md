---
title: What the Hell Is a Language Server?
description: The editor, LuaLS, Cod3x, and the conversation that produces completion and diagnostics.
weight: 50
extra:
  kind: guide
---

Your editor does not inherently know what `openmw.world` is.

OpenMW knows. Cod3x knows. Your editor needs somebody to tell it.

{{ schematic(data_path="data/schematics/language-server.json") }}

The [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) is a standard conversation between an editor and a separate analysis program. The editor asks questions such as “what does this name mean?” or “is this call valid?” The language server answers.

LuaLS is the analysis program in this picture. Your editor or editor extension is the client that displays its answers.

## What each piece does

| Piece | Job |
| --- | --- |
| LuaLS | Understands Lua syntax, scopes, types, and common mistakes. |
| Cod3x annotations | Teach LuaLS about OpenMW modules, objects, records, handlers, and APIs. |
| Cod3x context plugin | Adds OpenMW-specific context rules that ordinary Lua analysis cannot infer. |
| Editor LSP client | Displays completion, hover text, warnings, and errors. |

Cod3x does not change what OpenMW runs. LuaLS does not run your script. A green editor does not prove that the game behavior is correct.

## What it can and cannot prove

LuaLS can catch a misspelled field, a wrong argument shape, an unavailable module for the declared context, or a type mismatch.

It cannot prove that your `.omwscripts` file is installed, that a save has the state you expected, that an object is still valid after a cell transition, or that your code is fast enough. Those require the engine, logs, tests, or measurement.

That distinction is useful rather than disappointing. Use the editor to catch cheap static mistakes before launching OpenMW, then use OpenMW to answer runtime questions.

Continue to [Set Up Cod3x](@/cod3x/docs/zero-to-hero/setup-cod3x.md).
