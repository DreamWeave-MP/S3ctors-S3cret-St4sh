+++
title = "Loading, Processing, and Persistence"
description = "How SSS discovers modules, processes active objects, and restores saved state."
weight = 150

[extra]
api_docs = true
kind = "lifecycle"
+++

SSS discovers modules at startup, then processes objects as they become active with bounded, deferred work.

## Startup and discovery

At startup, SSS scans the VFS prefix `scripts/staticSwitcher/data/` for `.yaml` and `.yml` files. The normalized VFS path is the canonical module ID.

Modules are then available to the two dispatch pipelines. Instance and static module IDs are each sorted by priority and canonical ID for execution.

A module load does not mean every object has already been processed. SSS waits for `onObjectActive` notifications as objects enter the active scene.

## Activation and deferred work

For each active object, SSS checks instance rules first and uses static replacement only when no instance rule owns the activation. Active objects are processed in bounded batches during `onUpdate`, rather than all at once. Instance transforms are accumulated and placement updates are applied after the relevant actions. Replacement, disable, and delete work can be queued for later frames so that object validity and chain bookkeeping remain coherent.

Static replacement chains have a maximum depth of **8 replacement steps**. Each successful static module application adds one step to the chain. When a chain already has eight steps, SSS logs `chain max depth reached` and does not apply another static replacement to that lineage. A module is also applied at most once to a chain lineage, even before the depth limit is reached.

Missing meshes, invalid cells, unsupported object types, failed condition checks, and chance misses are normal reasons for an action to have no effect; inspect debug output when distinguishing them matters.

Disabled objects are a special lifecycle case: OpenMW may not report them as active on later cell loads. Do not expect an SSS rule that disables an object to re-enable or re-roll it automatically on re-entry.

## Save and load

SSS saves generated replacement records, pending deletion work, instance `once: true` state, and static replacement chains. It restores that state when the save loads.

`once: per_cell` data is runtime-only and is not saved.

Static replacement chains are historical save data. Changing a module's priority does not reorder old chain steps. Priority controls future matching/application only.
