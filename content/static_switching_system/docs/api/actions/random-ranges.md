+++
title = "Random Action Ranges"
description = "Sampled values for transforms, spawning, locks, teleporting, and globals."
page_template = "docs/page.html"
weight = 5

[extra]
api_docs = true
kind = "api"
+++

Action range tables are random samplers. Unlike [condition comparison ranges](@/static_switching_system/docs/api/conditions/comparison-ranges.md), a table-form action range requires `max`.

```yaml
transform:
  position:
    x:
      min: -32
      max: 32
```

| Form | Meaning |
| --- | --- |
| `value: 10` | Use the fixed value `10`. |
| `value: { min: 10, max: 20 }` | Sample between both bounds. |
| `value: { max: 20 }` | Sample from the consumer's default lower bound through `20`. |
| `value: { min: 10 }` | Invalid for sampled action values; runtime consumers assert that `max` exists. |

Defaults depend on the action. Position and rotation components default their missing lower bound to `0`; scale defaults its lower bound to `1.0`; lock and count ranges default their lower bound to `1`; `global_set` defaults its range lower bound to `1`. Count and lock ranges are sampled as integers. Transform, teleport, and scale ranges use numeric sampling.

Random values are sampled when the action executes. With `once: true`, the successful result is retained through the once cache; with `once: per_cell`, it is rerolled for a later activation batch. Without a once mode, the action can reroll whenever the object is activated.

The JSON Schema separates comparison and random-range definitions. Keep `max` explicit even where a runtime default may appear convenient. Lua treats `0` as a real value, so zero lower bounds and zero-valued optional settings are preserved when the schema permits them.
