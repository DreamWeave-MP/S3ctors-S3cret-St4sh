---
title: Object Lifetime and Stable Identity
description: Live engine-backed objects are not interchangeable with IDs, records, or persisted data.
weight: 35
extra:
  kind: guide
---

OpenMW objects are not ordinary Lua-owned tables.

They are handles into engine-managed state.

That difference should shape caching, event payloads, deferred work, and persistence.

## An object can stop being useful

A handle may exist while the underlying object is no longer loaded or valid for the operation you planned.

OpenMW exposes `object:isValid()` for this reason. APIs such as `nearby.getObjectByFormId` and `world.getObjectByFormId` can return an object handle even when the referenced object is not currently valid/loaded.

Do not interpret "I still have a Lua value" as "the engine object is still available."

## Object ID, form ID, and record ID answer different questions

Use the identity that matches the lifetime you need.

**Runtime object ID** identifies one specific instance.

**Form ID / engine identity** can be used to look an object up again where the API supports it.

**Record ID** identifies the content definition shared by potentially many instances.

A cache keyed by record ID answers a different question from one keyed by object ID.

An event that means "this exact actor" should not silently carry only the actor's record ID.

## Persist stable data, not live handles

Do not save a live object/userdata value merely because serialization accepts some representation of it.

Persist the minimum stable identity/state needed to rebuild the relationship later.

Typical persisted forms include:

- object/form ID when re-resolution is valid;
- record ID when instance identity does not matter;
- explicit DTO/state fields;
- generation/version information needed for migration.

Then validate again after load.

## Deferred work needs revalidation

A callback scheduled under one cell, target, or state generation may execute after that context changed.

Two useful strategies are:

1. resolve the stable ID again at execution time;
2. attach a generation/epoch token and reject work from older state.

S3maphore's CellPresence transition work eventually required generation counters precisely because "this request was valid when created" was not enough.

See [Generation Counters](@/cod3x/docs/paid-for-with-blood/generation-counters.md).

H3 Pattern: [Pool](@/h3lp_yours3lf/docs/api/packages/pool.md) makes a different lifetime explicit for short-lived plain-Lua values: the object is borrowed until `release`, not owned forever. [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) can consume such a payload only while dispatch is synchronous.

## A loaded cell is part of the lifetime contract

Properties such as `object.cell` can be absent in states where the object is not presently associated with a usable loaded cell.

Do not make cell-dependent calculations before establishing that the cell exists.

Prefer:

```lua
if not object:isValid() then return end

local cell = object.cell
if not cell then return end

processInCell(object, cell)
```

## Caches can accidentally pin stale world assumptions

Caching a record is usually much safer than caching a live object because record data is content-level rather than instance-level state.

Caching object-derived results requires a semantic lifetime:

- one frame;
- one cell transition;
- until equipment changes;
- until object invalidation/death;
- until an explicit event clears it.

"Until Lua GC gets around to it" is not a semantic lifetime.

## Send the right thing across boundaries

When sending events/interfaces:

- send a live object when the receiver is guaranteed to act immediately in a compatible lifetime/context and the API supports it;
- send a stable ID when work may be deferred or reconstructed;
- send record ID when the message is about the content definition rather than one instance;
- send a small DTO when the receiver needs a snapshot, not ownership of the live object.

The payload is part of the architecture.

See [Event Architecture](@/cod3x/docs/practice/events.md) and [Storage, Save State, and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md).
