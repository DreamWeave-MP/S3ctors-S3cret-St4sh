---
title: Event Architecture
description: Events are ownership boundaries, not free decoupling.
weight: 60
extra:
  kind: guide
---

Events are useful because they cross boundaries. That is also why they cost more reasoning than direct calls.

For same-context synchronous observation, use H3's [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) instead of paying for an engine event. Signal listeners run before `fire` returns; OpenMW events are the right tool when ownership or context really crosses a boundary.

## Use events when the boundary is real

Good reasons include:

- target-object ownership;
- global/local context crossing;
- engine-scheduled notification;
- fan-out where publisher and listeners intentionally do not share a direct dependency.

Bad reasons include:

- avoiding a function call because “events are decoupled”;
- hiding module dependencies;
- sending a message to yourself because the event bus is already available.

## Payloads are APIs

Name them, document them, and keep them small.

If an event can arrive stale, include the identity required to reject it.

If consumers need a stable object ID rather than a live handle, send the ID.

If a public event changes shape, treat that as an API evolution problem.

## Event handlers should make invalid state loud

Do not automatically wrap every handler in protected execution.

DreamScripts historically had a generic `safeCall` layer. That architecture made sense for a server framework executing third-party scripts, where one bad extension could cross a process boundary. It is not evidence that ordinary OpenMW mod internals should suppress their own handler errors.

Know whether you are writing a host or a mod.

## Batch work instead of broadcasting every frame

[S3maphore's combat integration](@/s3maphore/docs/api/events.md) spreads local actor checks across frames and uses events to address the actor scripts that own target observation. The [actor implementation](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/omw/music/actor.lua) shows the ownership boundary.

The system still performs work, but ownership and cadence are explicit.

See [Every Frame Is a Budget, Not an Invitation](@/cod3x/docs/anti-patterns/per-frame-everything.md).

H3 Pattern: [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) is deliberately synchronous and local. H3's [pooling example](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md) shows the only safe shape for reusing a payload: acquire, fire synchronously, then release.
