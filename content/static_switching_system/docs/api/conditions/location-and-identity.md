+++
title = "Location and Identity Conditions"
description = "Match cells, coordinates, content files, object types, records, and generated objects."
page_template = "docs/page.html"
weight = 10

[extra]
api_docs = true
kind = "api"
+++

These conditions inspect the target object's cell or identity. Sequence forms are OR-lists unless noted otherwise.

## `cell`

**Shape:** `cell: string | string[]`

Exact match against `object.cell.name` or `object.cell.id`. The comparison is not a substring match. Use the cell spelling exposed by the active content; the handler does not perform a case-insensitive comparison for this condition.

```yaml
cell: "Balmora, Caius Cosades' House"
```

## `cell_match`

**Shape:** `cell_match: string | string[]`

Case-insensitive plain substring match against the cell name or ID. Each listed substring is an alternative.

```yaml
cell_match: tomb
```

## `coords`

**Shape:** `coords: [{ x: integer, y: integer }, ...]`

Matches an exterior cell's exact grid coordinates. Interior and non-exterior objects do not match. The sequence is required because multiple coordinate tables are alternatives.

```yaml
coords:
  - x: -2
    y: -2
```

## `content_file`

**Shape:** `content_file: string | string[]`

Matches the object's originating content file. Values are normalized by the module loader and then compared as an exact content-file value. An object without a content file matches the special value `GENERATED`.

```yaml
content_file: Morrowind.esm
```

## `exterior`

**Shape:** `exterior: boolean`

Matches `true` for exterior cells and `false` for non-exterior cells.

```yaml
exterior: false
```

## `quasi_exterior`

**Shape:** `quasi_exterior: boolean`

Matches the cell's OpenMW `isQuasiExterior` flag. This is separate from `exterior`.

```yaml
quasi_exterior: true
```

## `region`

**Shape:** `region: string | string[]`

Case-insensitive exact match against the cell region. For an interior without a direct region, SSS may infer the region from the nearest teleport door leading to an exterior cell. If no region can be found, the condition fails.

```yaml
region: ashlands region
```

## `worldspace`

**Shape:** `worldspace: string | string[]`

Case-insensitive exact match against the object's cell worldspace ID. Objects without a worldspace ID do not match.

```yaml
worldspace: morrowind
```

## `object_type`

**Shape:** `object_type: string | string[]`

Matches an exact OpenMW type name through `types[...]`. Common values include `Container`, `Creature`, `LevelledCreature`, `Weapon`, `Armor`, `NPC`, `Static`, `Door`, and `Activator`. A listed type is an alternative. An unknown type is an error, not a non-match.

```yaml
object_type:
  - Door
  - Container
```

## `record_id`

**Shape:** `record_id: string | string[]`

Lua-pattern match against the object's record ID. An exact record ID naturally matches; `^` and `$` can anchor a pattern, for example `^bonewalker$`. Listed patterns are alternatives. Record IDs are normalized by the loader.

```yaml
record_id: "^in_tomb_all_lev%+0$"
```

Because this is Lua-pattern matching rather than plain substring matching, escape Lua pattern characters such as `+` with `%`.

## `content_file_target`

**Shape:** `content_file_target: { ContentFile: [referenceNumber, ...] }`

Matches only when both the object's content file and its local reference number match. Content-file keys are alternatives; reference numbers under a matching key are alternatives. This is the current reference-number condition; there is no standalone `ref_num` condition.

```yaml
content_file_target:
  Morrowind.esm:
    - 67647
```

## `generated_record`

**Shape:** `generated_record: boolean`

Matches whether the object's record was dynamically created rather than supplied by a plugin. It is distinct from `generated_object`.

```yaml
generated_record: true
```

## `generated_object`

**Shape:** `generated_object: boolean`

Matches whether the object instance has no originating content file. `true` means dynamically created; `false` means an original content placement.

```yaml
generated_object: false
```
