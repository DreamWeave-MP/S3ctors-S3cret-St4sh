---
title: The OpenMW Lua Mental Model
description: Engine, script, object, record, context, interface, event, and storage in one model.
weight: 10
extra:
  kind: guide
---

OpenMW Lua is not a free-standing Lua application with a game library attached.

It is embedded code running inside an engine that deliberately exposes different capabilities to different script contexts. The fastest way to become confused is to treat every module as globally available and every object as the same kind of handle.

Keep five layers separate in your head.

## 1. The engine owns the world

OpenMW owns game state, object lifetime, content records, simulation, rendering, input, UI, save state, and the scheduler that invokes scripts.

Lua receives handles and APIs into that state. Crossing from Lua into those APIs is not the same thing as indexing another ordinary Lua table. Some accesses are cheap. Some create temporary values or userdata. Some perform queries. Some dispatch through bindings into significant C++ work.

This distinction becomes critical in [Performance](@/cod3x/docs/performance/_index.md).

## 2. A script runs in a context

The major concrete contexts are:

- `global` — world-level authority;
- `local` — attached to an in-world object;
- `player` — a local script attached to the player with additional player-only APIs;
- `menu` — main-menu/UI environment without the in-world object surface;
- `load` — content-loading environment.

The context determines what the script can see and mutate.

A module being documented somewhere does **not** imply your script can require it.

Cod3x makes this explicit with `---@omw-context` annotations and the context plugin. See [Script Contexts](@/cod3x/docs/getting-started/contexts.md).

## 3. Records are not objects

A record describes content data: the weapon definition, NPC definition, static definition, race definition, and so on.

An object is an instance that exists somewhere in game state.

Many objects can share one record. One object can move, be disabled, enter a container, change count, become invalid, or acquire instance state without changing the base content record.

A record ID therefore answers a different question from an object ID.

- `object.recordId` identifies the underlying record.
- `object.id` identifies that particular runtime object.

Do not build caches, event routing, or persistence without being clear which identity you need.

See [Objects, Records, Types, and Cells](@/cod3x/docs/getting-started/objects-records-types.md).

## 4. `types` describes concrete game categories

`openmw.types` is where OpenMW groups type-specific behavior and record access.

A generic object tells you that something exists in the world. A type API tells you what that thing means as an Actor, Weapon, Door, NPC, Container, and so on.

The important questions are usually:

1. What object handle do I have?
2. What concrete type is it?
3. Do I need instance state or record data?
4. Is this operation legal in my context?

Cod3x should make those answers easier than guessing which module sounds right.

## 5. Scripts communicate through explicit boundaries

There are several communication mechanisms, and they are not interchangeable:

- direct Lua function/module calls inside one compatible environment;
- OpenMW interfaces for stable cross-script contracts;
- local events sent to an object;
- global events sent through the engine;
- storage for persistent/shared state and subscriptions.

An event is not a substitute for dependency design. An interface is not a global variable with a nicer name. Storage is not a message bus.

Choose based on ownership and lifetime first, convenience second.

See [Events and Interfaces](@/cod3x/docs/getting-started/events-and-interfaces.md) and [Storage, Save State, and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md).

## The minimum useful questions

Before writing a feature, answer these:

- Which script owns the state?
- Which context should own the behavior?
- What engine data must be queried?
- Which values can become invalid?
- Which values are records and which are instances?
- Does work need to happen every frame, on an event, or in a bounded batch?
- Does anything cross a script-context boundary?
- Does anything need to survive a save/load cycle?

If those answers are vague, adding code usually makes the architecture worse.

## A useful rule of thumb

Put authority where the engine naturally exposes it.

If a thing can only be done globally, do not simulate global authority from five player-side events. If a player script already owns a UI concern, do not bounce through a global event because events feel decoupled. If a local actor script can observe its own combat state cheaply, do not poll every actor from one giant player loop unless the measurement proves that architecture is better.

OpenMW's contexts are constraints, but they are also architecture hints.

Use them.
