+++
title = "Basic Static Replacement"
description = "Replace one mesh everywhere with a static module."
weight = 10

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Replace every matching instance of one mesh with another mesh, without writing a Lua object-processing script.

## Smallest YAML excerpt

```yaml
replace_meshes:
  r/CliffRacer.NIF: my_mod/creatures/cliff_racer_replacer.NIF
```

This is the core pattern from `Examples/StaticModule_Advanced.yaml`. Save it as a YAML module below `scripts/staticSwitcher/data/` in an active data directory and change both paths to assets that are actually present in your VFS.

## Why it works

A module with `replace_meshes` and no `replace_names`, `exterior_cells`, or `replace_regions` filters is unconditional. SSS normalizes mesh paths and creates a replacement record from the original record with the requested model, then places the replacement at the source object's position and scale.

## Persistence

Static replacements are recorded as replacement-chain steps and generated override records in SSS save data. The original object is disabled while the replacement is active. Existing chain data is historical; changing a module or its priority does not rewrite prior steps.

## Caveats

- The replacement mesh must be available through the OpenMW VFS. A missing asset is logged and that object is skipped.
- A static module is mutually exclusive with `instances`; do not add instance rules to this file.
- The mesh path is a resource path, not a record ID. Keep the path spelling and package layout consistent with the installed asset.
- If another static module also replaces the resulting mesh, `priority` controls which replacement module is considered first. It is not plugin load order.

See the [contextual replacement recipe](@/static_switching_system/docs/recipes/contextual-static-replacement.md) when a global swap is too broad.
