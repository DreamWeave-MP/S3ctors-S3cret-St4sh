---
title: Objects, Records, Types, and Cells
description: The conceptual map behind GameObject handles and content records.
weight: 30
extra:
  kind: guide
---

One of the most persistent sources of OpenMW-Lua confusion is that several APIs answer different versions of “what is this thing?”

Keep instance identity, record identity, concrete type, and location separate.

S3lf is a production example of centralizing that interpretation instead of making every consumer rebuild it. See the [I.s3.lf Design Genealogy](@/cod3x/docs/good-designs/s3lf-semantic-boundary.md) after this mental model.

{{ schematic(data_path="data/schematics/object-record-model.json") }}

## Objects are runtime instances

Cod3x models the common object hierarchy as:

- `openmw.Object` — shared object surface;
- `openmw.LObject` — read-only nearby/local handle;
- `openmw.GObject` — mutable global handle;
- `openmw.SelfObject` — the object a local/player script is attached to.

An object has two identities you should not confuse:

```lua
local instanceId = object.id
local recordId = object.recordId
```

`instanceId` identifies this runtime instance.

`recordId` identifies the content record it was created from.

If three iron swords exist in the world, they may share one `recordId` and have three different object IDs.

### Which ID belongs in a cache?

Use the identity of the thing you are caching.

- Cache per-instance combat state by `object.id`.
- Cache immutable-ish metadata derived from a base record by `recordId`.
- Do not key instance state by `recordId` merely because it is shorter or familiar.

S3maphore's combat tracking, for example, uses actor object IDs because it is tracking individual live actors, not NPC record definitions.

## Records are content definitions

Type modules expose record lists and record lookup helpers.

For example, a type API may provide:

```lua
local types = require 'openmw.types'

local record = types.Weapon.record(object)
```

The record describes the weapon definition. It is not the world object.

Records can also exist with no currently loaded object instance.

This is why “find the record” and “find the object” are separate tasks.

## `types` is the bridge between generic handles and game meaning

The `openmw.types` module contains concrete type APIs such as Actor, NPC, Weapon, Door, Container, Static, and many others.

A typical decision is:

```lua
local types = require 'openmw.types'

if types.Actor.objectIsInstance(object) then
  local health = types.Actor.stats.dynamic.health(object)
end
```

Do not infer type from record naming conventions or the existence of a convenient field when OpenMW exposes an explicit type predicate.

## Local and global handles are different capabilities

A nearby object in a player/local script is not equivalent to a `GObject` held by a global script.

The global handle exposes world mutation APIs such as adding scripts, moving objects, setting scale, and other authority that local handles do not have.

This is not merely a type-checker inconvenience. It expresses ownership.

If local code needs a global mutation, design the communication boundary rather than pretending the local object is writable.

## Objects can become invalid

Long-lived object handles require care.

`object:isValid()` exists because an object you cached earlier may no longer be available. Cell transitions, unloads, removal, and lifecycle changes can invalidate assumptions.

Do not turn every single access into a defensive `isValid()` ritual. Instead, ask whether the lifetime of the handle actually crosses an engine boundary where validity can change.

If it does, revalidate at that boundary.

## `cell` can be nil

An object in a container or inventory can have no world cell. Loading can also expose transitional states.

Cod3x annotations mark `object.cell` as optional for a reason.

Do not write:

```lua
local cellId = object.cell.id
```

unless the surrounding contract proves the object is in a cell.

Prefer a real invariant:

```lua
local cell = object.cell
if not cell then return end

local cellId = cell.id
```

or assert if absence is genuinely impossible for the operation:

```lua
local cell = assert(object.cell, 'expected an object placed in a cell')
```

The right choice depends on whether absence is valid input or broken state.

## Engine data is messier than the happy path

A good example is Cod3x [commit `f834f17e`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/f834f17e9bd18837d68faf60b80678bad23aa384): the annotation had assumed cells necessarily had pathgrids. Real content proved otherwise, so the type had to become optional.

This is a recurring OpenMW lesson:

**semantic expectation is not a runtime guarantee.**

Content can omit optional records, data can vary by plugin, and engine wrappers may use userdata even when the conceptual value looks like a number or table.

The type annotations should describe reality, not the most common content.

## Finding things

### Find objects by record ID globally

Global scripts have world-level lookup APIs such as `world.getObjectsByRecordId`.

Use these when you need instances matching a content record.

### Inspect nearby things locally

Local/player scripts use `openmw.nearby` and the attached object/nearby collections.

The result is a local handle surface, not global authority.

### Get a record from a known object

Use the relevant `types.*.record` function when the type is known.

### Iterate all records of a type

Use the type's record collection where exposed. This is content data, not an object scan.

These operations have different costs and semantics. Do not substitute one for another because they eventually produce a matching string ID.

## Cells are part of identity and lifetime

A cell is not merely a label attached to an object. Cell transitions are engine lifecycle boundaries.

They affect:

- which local objects exist;
- which nearby collections are meaningful;
- when caches should be invalidated;
- when deferred work becomes stale;
- when object handles may change validity.

S3maphore's presence system learned this the expensive way. See [Generations for Deferred Work](@/cod3x/docs/paid-for-with-blood/generation-counters.md).

## The question to ask

When you are stuck between `world`, `nearby`, `types`, and a record list, ask:

**Am I trying to find an instance, inspect an instance, identify its concrete type, or read its content definition?**

That usually tells you which API family you actually need.
