+++
title = "World and Transform Actions"
description = "Replace, transform, teleport, and create objects with fixed or sampled values."
page_template = "docs/page.html"
weight = 20

[extra]
api_docs = true
kind = "api"
+++

## `replace`

**Shape:** `replace: { ReplacementRecordId: chance, ... }`

Attempts each replacement record with its chance and returns the first successful creation. A replacement action changes the current action target to the created object and disables the original source. It is not a weighted one-winner table: multiple entries may pass, and map iteration order determines which passing entry is encountered first.

```yaml
replace:
  dremora_special_fyr: 0.25
```

Each chance is a number from `0` to `1` in the schema. A failed creation is skipped by the handler. If no entry passes, the action is a no-op. See [execution order](execution-order.md) for replacement plus `delete` semantics.

## `transform`

**Shape:**

```yaml
transform:
  transform_type?: relative | absolute
  scale?: number | { min?: number, max: number }
  rotate?:
    x?: number | { min?: number, max: number }
    y?: number | { min?: number, max: number }
    z?: number | { min?: number, max: number }
  position?:
    x?: number | { min?: number, max: number }
    y?: number | { min?: number, max: number }
    z?: number | { min?: number, max: number }
```

The default `transform_type` is `relative`. Relative scale multiplies the current scale, rotation composes with the current rotation, and position adds to the current position. Absolute scale uses `1.0` as its reference, absolute rotation starts from the identity transform, and absolute position replaces the position. Numeric range tables are sampled and require `max`; see [random action ranges](random-ranges.md). Rotation values are degrees.

```yaml
transform:
  scale:
    min: 0.8
    max: 1.3
  rotate:
    z:
      min: 0
      max: 360
```

The action marks the target for a placement update when at least one transform field is present. It has no record-type restriction, but an invalid range can error.

## `teleport`

**Shape:**

```yaml
teleport:
  cell?: string | { x: integer, y: integer }
  position?:
    x?: number | { min?: number, max: number }
    y?: number | { min?: number, max: number }
    z?: number | { min?: number, max: number }
  rotation?:
    x?: number | { min?: number, max: number }
    y?: number | { min?: number, max: number }
    z?: number | { min?: number, max: number }
  onGround?: boolean
```

Every field is optional. A string resolves a cell by name; an `{ x, y }` table resolves an exterior grid cell. Without `cell`, the current cell remains. Missing position components retain their current coordinates. Rotation components are applied relative to the current rotation, in degrees. A position or rotation range is sampled and requires `max`. `onGround: true` requests ground placement.

```yaml
teleport:
  cell: "Balmora, South Wall Cornerclub"
  position:
    x: 771
    y: 754
    z: -250
```

A missing destination cell logs a warning and returns false. Other engine teleport failures are not converted into a portable success guarantee.

## `create`

**Shape:**

```yaml
create:
  <record-id>:
    count?: integer | { min?: integer, max: integer }
    chance?: number
    scale?: number | { min?: number, max: number }
    rotate?:
      x?: number | { min?: number, max: number }
      y?: number | { min?: number, max: number }
      z?: number | { min?: number, max: number }
    position?:
      x?: number | { min?: number, max: number }
      y?: number | { min?: number, max: number }
      z?: number | { min?: number, max: number }
    transform_type?: relative | absolute
```

The `<record-id>` value may also be a bare record ID string or an integer count.

Each record-ID pool is evaluated independently. A bare string creates one object; an integer creates that many; a pool can specify `count`, `chance`, and per-object position, rotation, scale, and `transform_type` overrides. Unlike `replace`, this is not a one-winner selection.

```yaml
create:
  mudcrab:
    count: 5
    position:
      x: { min: -300, max: 300 }
      y: { min: -300, max: 300 }
```

Pool counts default to `1`; count range tables require `max`, default `min` to `1`, and produce integer counts. Pool chance is a number from `0` to `1` in the YAML schema. Each pool chance is rolled once; transform overrides are sampled separately for each created object. Relative positioning/rotation/scale is the default, and absolute mode uses the trigger's cell with absolute override values. Invalid creation records or malformed action ranges can error.
