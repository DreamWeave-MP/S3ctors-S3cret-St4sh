+++
title = "Comparison and Random Ranges"
description = "Use min and max correctly in SSS conditions and sampled actions."
weight = 70

[extra]
kind = "concepts"
+++

SSS uses two similar-looking but different range forms.

## Comparison ranges

Conditions use a number as an at-least comparison in most numeric gates, or a table whose `min` and `max` bounds are independently optional:

```yaml
- conditions:
    - player_level:
        min: 10
        max: 20
```

These are valid condition shapes:

```yaml
player_level: 10
player_level: { min: 10 }
player_level: { max: 20 }
player_level: { min: 10, max: 20 }
```

A number normally means “value is at least this number.” A supplied `min` is inclusive, as is `max`. This applies to level, attributes, skills, health, magicka, fatigue, disposition, lock level, faction rank, and similar condition gates. `scale` is different: a bare number requires exact equality; use a table for inclusive bounds. `time_of_day` is another exception worth remembering: when both bounds are present and `min` is greater than `max`, the range wraps across midnight, for example `min: 20`, `max: 8`.

## Random action ranges

Sampled action values use a fixed number or a table with a required `max`:

```yaml
position:
  x:
    min: -32
    max: 32
```

A table with only `min` is not a valid random action range. The default lower bound depends on the action:

| Action value | Table-form default `min` | Sampled as |
| --- | ---: | --- |
| Position and rotation | `0` | A numeric coordinate or degree value |
| Scale | `1` | A multiplier in relative mode, or an absolute scale in absolute mode |
| Item/create count | `1` | An integer count |
| `lock_level` | `1` | An integer lock level |
| `global_set` | `1` | An integer global value |

For a scalar fixed value, `transform.scale: 1.5` means 1.5 times the reference scale in relative mode. With `transform_type: absolute`, the reference is 1.0 and the result is an absolute scale. Relative position adds an offset; absolute position replaces the position. Relative rotation applies a rotation to the current orientation.

Create pools sample each object's overrides independently, so a position range can scatter objects. A pool's `chance` decides whether that pool activates; pools in one `create` map are evaluated independently. `count` ranges are sampled as integers.

The [schema reference](@/static_switching_system/docs/api/schema.md) is the authoring-time source of truth for these forms. Do not use the condition `numericRange` shape in an action that requires a sampled upper bound.
