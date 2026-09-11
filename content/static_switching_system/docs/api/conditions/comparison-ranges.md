+++
title = "Comparison Ranges"
description = "The min, max, and threshold semantics used by instance conditions."
page_template = "docs/page.html"
weight = 5

[extra]
api_docs = true
kind = "api"
+++

Condition range tables are comparisons, not random samplers. Bounds are inclusive and independently optional.

```yaml
player_level:
  min: 10
  max: 20
```

| Form | Meaning |
| --- | --- |
| `value: 10` | Usually value is at least `10`. |
| `value: { min: 10 }` | Value is at least `10`. |
| `value: { max: 20 }` | Value is at most `20`. |
| `value: { min: 10, max: 20 }` | Value is between both inclusive bounds. |

The consuming condition supplies the defaults for a missing bound. Most numeric conditions use a bare number as an at-least threshold. `time_of_day` additionally treats `min > max` as a range crossing midnight. Attribute and skill maps apply every named entry as an AND condition. `global_value` uses an ordered array of one-key maps, and every entry must pass.

This is distinct from action values: action range tables are sampled and require `max`. See [random action ranges](@/static_switching_system/docs/api/actions/random-ranges.md).

The JSON Schema requires at least one bound for range objects and rejects invalid bound types. Runtime handlers may be more permissive for values supplied outside schema validation; do not rely on that for YAML modules.
