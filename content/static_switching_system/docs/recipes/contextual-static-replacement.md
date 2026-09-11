+++
title = "Contextual Static Replacement"
description = "Limit a static mesh replacement to named cells, regions, or exterior coordinates."
weight = 20

[extra]
api_docs = true
kind = "recipe"
+++

## Goal

Apply a mesh replacement only in selected places while leaving the same source mesh alone elsewhere.

## Smallest YAML excerpt

```yaml
replace_names:
  - "dagoth ur"

replace_meshes:
  r/CliffRacer.NIF: my_mod/creatures/cliff_racer_replacer.NIF
```

The shipped pattern is in `Examples/StaticModule.yaml`. Use `replace_regions` for exact, case-insensitive region IDs/names or `exterior_cells` for exterior grid coordinates:

```yaml
replace_regions:
  - "ashlands region"

exterior_cells:
  - x: 0
    y: -1
```

## Why it works

`replace_names` performs a case-insensitive substring match against a cell name or ID. `replace_regions` matches a cell's region, and `exterior_cells` matches an exterior grid coordinate. These location filters are ORed: an object in any selected location is eligible. Omitting all three makes the replacement global.

## Persistence

The matching decision is made when objects become active, but each successful static swap is stored in the same replacement chain as a global swap. Existing chain data remains historical if you edit the filters or priority.

## Caveats

- A region or cell filter does not combine with the others as an AND expression. Split the design into separate modules when you need distinct precedence or narrower logic.
- `ignore_records` can exclude record IDs from this module after its location matches. It is useful when several records share one mesh.
- Exterior coordinates are integer grid coordinates and do not apply to interiors.
- The replacement asset is still resolved through the VFS; a valid location filter cannot make a missing mesh work.
