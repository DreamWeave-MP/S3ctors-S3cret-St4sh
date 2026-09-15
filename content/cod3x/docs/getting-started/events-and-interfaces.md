---
title: Events and Interfaces
description: Choose communication by ownership, direction, and lifetime rather than convenience.
weight: 40
extra:
  kind: guide
---

OpenMW gives scripts several ways to communicate. The existence of multiple mechanisms is not an invitation to choose whichever requires the least typing.

Choose based on ownership.

## Direct calls first, when they are actually direct

Inside one compatible Lua environment, an ordinary module call is the simplest possible contract:

```lua
local Resolver = require 'scripts.myMod.resolver'

local result = Resolver.resolve(input)
```

If two pieces of code already share context and lifetime, inserting an engine event between them usually adds indirection, serialization constraints, and debugging cost for no benefit.

## Interfaces are stable contracts between scripts

OpenMW interfaces expose named functionality between participating scripts.

Think of an interface as a published capability:

- a stable name;
- a set of fields/functions;
- an owner;
- consumers that depend on the contract rather than implementation files.

H3 and S3maphore make heavy use of this pattern because reusable infrastructure needs a public surface that is narrower and more stable than its internal module graph.

H3 Pattern: use [S3lf](@/h3lp_yours3lf/docs/api/interfaces/s3lf.md) or another installed interface when the provider owns the capability. Use [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) only for synchronous listeners inside one Lua environment; it is not an OpenMW event substitute.

Do not expose every internal helper merely because an interface table can hold it.

## Local events address an object

`object:sendEvent` routes an event to the target object's local scripts.

That is appropriate when the receiver naturally owns the behavior.

S3maphore's actor/player split uses this to ask local actor scripts for combat-state work and to notify the player script of actor-owned changes.

The target object is meaningful. That is a good sign that a local event is the correct boundary.

## Global events cross the world-level boundary

`core.sendGlobalEvent` can be appropriate for communication that genuinely targets global script infrastructure or crosses a context boundary that has no direct interface path.

Do not use global events as a generic internal message bus.

If code in the same context could call an interface or module directly, bouncing through the engine because “events are decoupled” often makes the system slower and harder to reason about.

## Events have payload contracts

Event data crosses an engine-managed boundary. Treat the payload as an API.

That means:

- use stable field names;
- know whether values are serializable/allowed;
- distinguish object handles from IDs;
- version or evolve public payloads deliberately;
- do not smuggle arbitrary implementation state through an event just because a table accepts it.

If the receiver needs one ID and a generation counter, send one ID and a generation counter.

## Events are not guaranteed to mean “still relevant”

A delayed event may be valid when sent and stale when handled.

S3maphore's cell-presence pipeline had exactly this problem. The fix attached transition generations and playback epochs so the receiver could prove that deferred work still belonged to the current state.

See [Generations for Deferred Work](@/cod3x/docs/paid-for-with-blood/generation-counters.md).

## Interfaces do not remove lifecycle questions

An interface can disappear, change version, or become available only after another script initializes.

Reusable code should decide explicitly whether a missing dependency is:

- optional capability;
- expected initialization ordering;
- fatal configuration error.

Do not turn every missing interface into `if interface then ... end`. That silently converts required dependencies into optional behavior.

## A practical selection table

| Need | Prefer |
| --- | --- |
| Call code in the same module graph/context | direct module/function call |
| Publish a reusable stable capability | interface |
| Tell one object's local scripts something | local event |
| Cross to world/global infrastructure | global event when appropriate |
| Persist/share state over time | storage, with explicit ownership |
| Notify many listeners inside one Lua module graph | a local signal/callback abstraction |

## Design from the receiver backward

Before sending anything, ask:

1. Who owns the state that changes?
2. Which context owns that state?
3. Does the receiver need a command, a notification, or a queryable capability?
4. Can the message become stale?
5. What is the smallest stable payload?

If those questions are answered first, the API choice is usually obvious.
