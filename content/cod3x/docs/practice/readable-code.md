---
title: Readability Is a Performance Feature for Humans
description: Full-word names, semantic whitespace, narrow scopes, and almost no narration comments.
weight: 20
extra:
  kind: guide
---

OpenMW mods accumulate state, engine boundaries, lifecycle assumptions, and context-specific behavior quickly. Dense code makes those costs harder to see.

The preferred style is intentionally boring.

## Name the thing

Use full-word variable names unless the abbreviated form is a conventional local alias whose meaning is obvious in a tiny scope.

Prefer:

```lua
local currentPlaylist = MusicManager.currentPlaylist
local combatTargets = {}
local transitionGeneration = 0
```

over:

```lua
local cp = MusicManager.currentPlaylist
local ct = {}
local gen = 0
```

Hot-path localizations are an exception only when the alias remains readable. `local GetTargets = AI.getTargets` is comprehensible. Turning an entire module into two-letter aliases to save keystrokes is not an optimization strategy.

## Use whitespace to expose control flow

Separate setup, guard clauses, state mutation, and downstream effects.

```lua
local cell = object.cell
if not cell then return end

local record = types.Static.record(object)
if not record then return end

applyStaticRule(object, record, cell)
```

The blank lines are semantic. They tell the reader that one decision is complete before the next begins.

Do not compress unrelated work merely because Lua permits one-line statements.

## Prefer guard clauses

Deep nesting hides the path that actually matters.

Prefer:

```lua
if not MusicSettings.MusicEnabled then return end
if waitingOnPresence then return end
if not desiredPlaylist then return end

play(desiredPlaylist)
```

when the alternative is three levels of nested `if` blocks.

This is not a universal command to early-return every branch. It is a preference for keeping the main path visible.

## Comments are for information the structure cannot carry

Do not narrate obvious code:

```lua
-- Increment the generation
transitionGeneration = transitionGeneration + 1
```

The assignment already says that.

A useful comment explains a non-obvious contract:

```lua
-- Generation travels with deferred presence work so a cell transition can reject stale responses.
transitionGeneration = transitionGeneration + 1
```

Better still, encode the rule in names and structure so the comment becomes unnecessary.

Comments should be maximum-signal:

- engine behavior that cannot be inferred locally;
- public contract information;
- benchmark caveats;
- historical reason for a counterintuitive choice;
- downstream integration requirements.

## Narrow scope reduces reasoning cost

Declare variables as close as practical to the code that owns them.

Module-level state is appropriate when the module owns long-lived state. Do not hoist everything to module scope because local lookup can be faster. Lifetime and ownership come first.

## Performance code must remain reviewable

A fast module that nobody can safely modify is unfinished work.

S3maphore has aggressively localized engine and library calls in truly hot code, but the better examples still preserve recognizable names and explicit state transitions.

When a micro-optimization makes the control flow opaque, require evidence that the gain is worth the maintenance cost.

See [Hot Paths, Hoisting, and Precomputation](@/cod3x/docs/performance/hot-paths.md).
