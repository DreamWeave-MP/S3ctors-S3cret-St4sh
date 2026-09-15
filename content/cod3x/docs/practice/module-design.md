---
title: Module and API Design
description: Small contracts, explicit ownership, and abstractions that have earned their existence.
weight: 50
extra:
  kind: guide
---

Lua makes abstraction cheap to create and expensive to delete.

A table can become a class, proxy, service locator, event bus, lazy loader, and dependency container before lunch. Resist the temptation to confuse flexibility with architecture.

## Extract contracts, not vibes

A reusable abstraction should solve a repeated problem with a stable shape.

H3 exists because the same utilities, UI components, signals, object access patterns, and integration problems appeared across many shipped mods.

That is evidence.

Do not build “the reusable version” of a helper that exists in one call site and may never exist in a second.

## Keep public surfaces smaller than internals

An interface should publish what consumers need, not every helper the implementation happens to use.

Small surfaces are easier to:

- document;
- type;
- test;
- version;
- optimize internally;
- keep compatible.

## Avoid magical multiplexing

Starwind Builder's historical `protectedTable` combined:

- storage access;
- local shadow caching;
- subscription behavior;
- logging;
- UI notification;
- arbitrary writable state;
- injected methods;
- custom `__index`, `__newindex`, `__pairs`, and `__tostring` behavior.

It was inventive and useful at the time. It also made a single indexed value potentially come from several different systems.

The modern preference is to split those responsibilities unless consumers genuinely benefit from one contract.

See [Clever Proxies and Magic Tables](@/cod3x/docs/anti-patterns/clever-proxies.md).

## Initialize required dependencies explicitly

DreamScripts evolved toward explicit interface contracts rather than repeated optional checks for tables that should always exist after initialization.

If a dependency is required, initialize it and assert it.

Do not write hundreds of defensive `if dependency then` branches that silently downgrade required architecture into optional behavior.

## Cache the product you promise

DreamScripts [commit `28062542`](https://github.com/DreamWeave-MP/DreamScripts/commit/28062542ca4e8f0eecc65237264aa2b13c44e8d1) corrected a script-loader cache that stored an intermediate compiled chunk rather than the script's returned module value.

That distinction mattered for hot reload and module semantics.

General rule:

**cache the abstraction consumers asked for, not an incidental intermediate representation.**

See [Cache the Result, Not the Machinery](@/cod3x/docs/paid-for-with-blood/cache-the-result.md).

## Lifecycle cleanup belongs at the lifecycle boundary

DreamScripts [commit `046694b6`](https://github.com/DreamWeave-MP/DreamScripts/commit/046694b61cb870994d89ac786131d7a1af3a13a3) removed duplicated event-flushing logic and centralized stale registration cleanup when a script was loaded/reloaded.

If a lifecycle transition invalidates registrations, perform cleanup at that transition rather than teaching every downstream subsystem to notice stale data independently.

This is the same principle as cache invalidation: put invalidation next to the event that makes the old state invalid.
