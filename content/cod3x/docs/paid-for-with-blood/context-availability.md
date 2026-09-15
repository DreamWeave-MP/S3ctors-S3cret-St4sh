---
title: Paid For With Blood — Context Availability Is a Contract
description: An API that exists elsewhere in OpenMW does not exist in every sandbox.
weight: 35
extra:
  kind: guide
---

## Paid For With Blood

Cod3x once claimed `openmw.types` was available in menu scripts.

It was not.

Commit [`8f3e075d`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8f3e075d98c1fbd31a7a2eecce09cbece7686ff1) changed the context matrix from “all contexts” to the contexts the module actually supports: global, local, and player.

One line in a tooling table was enough to make the editor confidently teach the wrong architecture.

## What went wrong

It is easy to treat familiar modules such as `core`, `types`, `ui`, and `world` as one coherent namespace that should exist everywhere.

OpenMW does not expose one universal Lua environment.

A script context is part of the API contract.

Availability determines what the script is allowed to know and do.

## The rule

Do not infer module availability from:

- the module name;
- another script context;
- a similar API;
- the fact that a type is conceptually relevant;
- LuaLS accepting the symbol in an unscoped file.

Verify it against the actual engine/context contract.

Cod3x exists partly so this mistake is caught before runtime.

## Tooling has to be at least as honest as the engine

A false-positive annotation is not harmless convenience.

It can cause developers and coding agents to design around an API that cannot exist where they need it.

Static tooling that lies confidently is worse than incomplete tooling.

See [Script Contexts](@/cod3x/docs/getting-started/contexts.md) and [Module Context Matrix](@/cod3x/docs/reference/module-contexts.md).
