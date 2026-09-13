---
title: randomGen
description: Generate fast, independent pseudo-random values without consuming OpenMW's protected random stream.
weight: 70
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.randomGen' → Rand") }}

Use `randomGen` when a mod needs randomness that should not consume or reseed OpenMW's engine-managed random stream. H3 keeps a private module-level xorshift state, seeded from real time when the module loads. This makes it a useful escape hatch for independent gameplay rolls, cosmetic variation, and randomized selection without asking OpenMW to hand over its protected seed.

{% usage_note(title="Independent stream · Not cryptographic") %}
This is a fast gameplay PRNG, not a security primitive and not a reproducible save-data source. It does not expose a reseed operation. Its sequence belongs to the Lua environment that loaded the module; do not persist the internal state or use it for authoritative randomness that must replay exactly.
{% end %}

## Example

```lua
local random = require 'scripts.s3.randomGen'

local chance = random.float()
if chance <= 0.25 then playRareEffect() end

local index = random.range(1, #entries, true)
local pitch = random.range(-2, 2)
```

## Values and ranges

| Function | Behavior |
| --- | --- |
| `int()` | Advance the private xorshift stream and return its 32-bit integer value. |
| `float()` | Return a floating-point value in `[0, 1)`. |
| `range(max)` | Return a continuous value in `[1, max)`. |
| `range(max, true)` | Return a uniform integer in `[1, max]`. |
| `range(min, max)` | Return a continuous value in `[min, max)`. |
| `range(min, max, true)` | Return a uniform integer spanning the requested endpoints. |

The direct numeric overloads deliberately avoid an options table and its allocation. Pass `true` as the second argument for the one-bound integer form, or as the third argument for the two-bound form. Bounds are not validated; invalid types raise, while reversed or otherwise nonsensical numeric bounds produce whatever the arithmetic implies. The [H3 implementation](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fh3lp_yours3lf%2Fscripts%2Fs3%2FrandomGen.lua) keeps the hot path small: direct arguments, cached math/bit operations, and no result table.

The H4ND legacy call site passes a table-shaped range argument, while the current H3 implementation accepts direct numeric arguments. Use the forms above when writing new code; that call site should be audited separately.
