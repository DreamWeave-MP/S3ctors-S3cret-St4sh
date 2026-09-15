---
title: 'Design Study: Local Handlers Instead of Engine Events'
description: Why a synchronous local observer boundary can be better than another engine event.
weight: 75
extra:
  kind: guide
---

## The problem

S3maphore needs to notify several pieces of its own player-side code when a track changes. The notification is synchronous and belongs to one provider. Nothing needs a new OpenMW context, a global broadcast, or a delayed message.

## The tempting design

OpenMW already has events, so it is tempting to turn every internal notification into one:

```lua
self:sendEvent('S3maphoreTrackChanged', data)
```

That can work. It also makes a local relationship look like an engine-facing contract. Consumers now depend on event names, payload serialization and delivery rules even though they are all listeners owned by the same Lua module.

## The reduction

Ask what kind of communication this actually is:

> Several local functions need the same synchronous notification.

That is a local handler list. S3maphore's [`musicManager.lua`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/musicManager.lua) owns the list, exposes `addTrackChangedHandler`, and calls those handlers when playback accepts a change. Commit [`e485c601`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/e485c6012da36017499d6819bdbc84d8e80b11ec) moved this relationship from direct track-change events to the explicit handler pattern used by the OpenMW API.

The public `I.S3maphore.addTrackChangedHandler` contract is now about one thing: subscribe a local function to accepted track changes. The engine event remains appropriate where the engine or another script context actually needs to hear about the change.

## Why this boundary works

The local handler gives the provider ownership of:

- listener storage;
- synchronous call order;
- the event payload's lifetime;
- error behavior during dispatch;
- the distinction between an accepted track change and an internal intermediate step.

It also keeps the communication vocabulary honest. An engine event is a cross-boundary message. A local handler is a local observer.

[H3 Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) is a reusable general-purpose local observer primitive with explicit listener cleanup and dispatch behavior. It is a useful parallel pattern, not proof that every provider should replace its own deliberately narrow handler list with a generic signal.

## What to steal

Choose the boundary that matches the communication:

- local, synchronous observers → a local handler list or Signal;
- another script context → an OpenMW event or interface;
- a public capability → an installed interface;
- delayed work → an explicit queued lifecycle.

Do not use a global event as a generic same-context message bus. Cod3x's [Events and Interfaces](@/cod3x/docs/practice/events.md) and [event performance guidance](@/cod3x/docs/performance/event-and-serialization-costs.md) explain the larger boundary costs.

## When not to use this

Do not hide a cross-context or externally consumable contract inside a private local handler list. If another script needs to subscribe without owning the provider, publish a documented interface or event instead. Local handlers are smaller because their ownership is smaller.
