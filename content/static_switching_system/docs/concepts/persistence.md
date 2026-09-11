+++
title = "Persistence and Once Semantics"
description = "Understand what SSS stores and when instance rules are re-applied."
weight = 80

[extra]
kind = "concepts"
+++

## Instance rules

`once` has two scopes:

- `once: true` on a rule caches that rule's successful application for the object and preserves the cache across save/load. It prevents the rule from being rolled again for that object.
- Despite its name, `once: per_cell` tracks the application only during the current SSS activation batch. It is not keyed by a tracked cell identity, is not saved, and is cleared when a new activation batch begins.

With no rule-level `once`, an eligible rule can run whenever the object becomes active. This is useful for re-randomized decoration but is unsafe for effects that should not repeat. The top-level `once: true` is instance-module-only: once any rule in that module applies to an object, remaining rules from that module are skipped for that object. It has no static-module meaning and should not be placed on a static module.

Persistence records successful rule applications by remappable object handle, module ID, and rule data hash. Keep module paths and rule shapes stable when you want an existing save to recognize prior applications. Changing a rule can give it a new identity and cause it to apply again; the exact resulting world state is action-dependent.

A disabled object may not emit a later `onObjectActive` event. Do not use a repeating disable action as if it were a toggle. For a one-time disable, prefer `once: true`, as shown in the [Loot, locks, and traps recipe](@/static_switching_system/docs/recipes/loot-locks-traps.md).

## Static replacement chains

Static replacements create replacement objects and retain an ordered chain from the original object through later replacements. Each successful module application contributes one chain step, and a chain can contain at most **8 steps**. Once that limit is reached, SSS logs `chain max depth reached` and skips later static replacements for that lineage. A module that already appears in the chain is also skipped for that lineage.

The chain and generated override records are saved so a loaded save can continue to identify the objects it owns. Original sources are disabled during replacement; work that removes or disables objects is processed asynchronously.

SSS orders new chain applications by priority tier and canonical module ID. Historical chains are not rewritten when a module's priority changes; priority controls future replacement application.
