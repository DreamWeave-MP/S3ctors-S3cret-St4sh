---
title: 'Design Genealogy: NullFunction to StateMachine'
description: How an empty callback can grow into explicit named states only when the system earns them.
weight: 40
extra:
  kind: guide
---

## The first trick

Sometimes a handler has nothing to do.

The smallest useful representation is an empty function:

```lua
local NullFunction = require 'scripts.s3.nullFunction'
local update = NullFunction

if workExists then update = doWork end
```

The caller does not need a branch every time the handler runs. No work means no work. H3's current [`nullFunction`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/h3lp_yours3lf/scripts/s3/nullFunction.lua) module is exactly that small.

The reported lineage begins in Modding-OpenMW's Pause Control and Friendly Autosave, where the same function-swapping idea was used before it became a named H3 helper. Those older repositories and commits still need primary-source recovery before Cod3x should state that ancestry as fact. The internal S3maphore and SSS lineage is verified.

## Reuse proves the trick

S3maphore used the idea for runtime update work. Its older core kept a current handler and assigned `NullFunction` when there was no active work. SSS still has the plain version in production: [`UpdateFunction = NullFunction`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/static_switching_system/Scripts/staticSwitcher/global.lua) lets the per-update callback return to doing nothing when its queues are empty.

This is good code when the state is small and the behavior is simple. Do not replace it merely because a state-machine module exists.

## Reality earns more structure

The representation changes when the system gains named phases and behavior at the boundaries:

{{ schematic(data_path="data/schematics/state-machine-genealogy.json") }}

S3maphore eventually had initialization, idle time, playlist-state updates, playback handling, delayed transitions, and error-sensitive sequencing. At that point a function pointer no longer told the reader which state the system was in or when a requested change would apply.

Commit [`d40f379c`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/d40f379ce7cae2fc3ba9a1f3f50a5c2431d6ca0b) replaced S3maphore's `NullFunction`/current-handler chain with H3's StateMachine. The code gained named states such as `init_player`, `update_playlist_state`, `handle_playback`, and `idle`, while the engine callback remained an explicit `onUpdate` that ticks the machine.

The current [StateMachine API](@/h3lp_yours3lf/docs/api/packages/state-machine.md) supplies the next layer of machinery: immediate versus queued transitions, enter/exit callbacks, validation, an optional error state, and re-entrant tick protection.

## Why both ends are good

`NullFunction` and `StateMachine` are not competing answers.

Use the empty callback when the only meaningful distinction is “work” versus “no work.” Use explicit states when names, transition timing, entry/exit behavior, or allowed transitions carry information the system must preserve.

The mistake is not choosing the smaller design. The mistake is refusing to change representation after the old one stops expressing the real state.

## What to steal

Start with the smallest representation of the state you actually have.

Generalize when repeated use and real requirements earn the abstraction. Do not build a state machine because “stateful code” sounds serious, and do not keep swapping anonymous functions after the system has acquired states that deserve names.

This is the same reduction described in [Reduce the Problem](@/cod3x/docs/good-designs/reduce-the-problem.md). [S3maphore's current core](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/core.lua) shows the promoted form; [SSS's global script](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/static_switching_system/Scripts/staticSwitcher/global.lua) shows why the primitive remains useful.

## When not to use this

If the only states are “run this function” and “do nothing,” `NullFunction` may already be the correct representation. Do not introduce named states until state identity, transition timing, entry/exit behavior, or validation carries information the system needs.
