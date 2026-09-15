+++
title = "Pipelines and Module Boundaries"
description = "How SSS dispatches static replacement and instance rule modules."
weight = 50

[extra]
kind = "concepts"
+++

A YAML file is one of two module types:

1. A **static replacement module**, identified by `replace_meshes`, with optional cell filters and record exclusions.
2. An **instance module**, identified by `instances`, containing ordered rules with conditions and actions.

SSS's small runtime primitives and its promotion of repeated utilities into H3 are part of Cod3x's [earned shared infrastructure genealogy](@/cod3x/docs/good-designs/earned-shared-infrastructure.md).

Pick one. Do not put `instances` beside `replace_meshes`, `replace_names`, `exterior_cells`, `replace_regions`, or `ignore_records`. There is no precedence rule that runs both systems for one object.

## Dispatch

When an object becomes active, SSS first asks the instance pipeline whether any instance rules match. If one or more rules are eligible by their conditions and once state, the instance pipeline owns that activation. Otherwise SSS tries the static replacement pipeline. An instance action's chance can still miss after dispatch has been selected; that miss does not make the object a static fallback candidate.

Static modules operate on record meshes and can create a replacement object while preserving the original object's placement. Instance modules operate on the active object and can replace or transform it, change inventory or ownership, alter lock/key/trap state, create objects, teleport, set globals, play sounds, attach scripts, or disable/delete objects.

A module can therefore use the same record or mesh vocabulary as another module without becoming composable. Split independent intent into separate files, and use priority and explicit conditions rather than relying on a cross-pipeline ordering assumption.

## Choosing a pipeline

| Need | Pipeline |
| --- | --- |
| Replace a mesh everywhere or in selected cells | Static module |
| Exclude record variants from a mesh replacement | Static module |
| Select by player state, quest stage, weather, object state, or tags | Instance module |
| Change inventory, equipment, locks, traps, ownership, scripts, or globals | Instance module |
| Spawn a replacement or scatter created objects | Instance module |

Use [Module Format](@/static_switching_system/docs/api/module-format.md) for YAML. `StaticSwitcher_G` is read-only inspection for scripts; it does not merge the pipelines. See the [interface reference](@/static_switching_system/docs/api/interface.md) and the [released static-module examples](@/static_switching_system/docs/recipes/static-modules-in-the-wild.md).
