---
title: spellUtil
description: Reuse OpenMW-derived spell, enchantment, potion, and casting calculations from Lua.
weight: 77
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.spellUtil' → MagicHelper") }}

`spellUtil` collects calculations that otherwise get duplicated in HUDs, gameplay helpers, and magic-aware systems. It is available in local and player scripts and requires H3's installed S3lf interface to read the current actor's skills and fatigue.

```lua
local Magic = require 'scripts.s3.spellUtil'

local castable = Magic.getCastable(actor)
local icon = castable and Magic.getCastableIcon(actor)
local chance = Magic.getSpellCastChance(spell, actor, true, true)
```

## Public functions

| Function | Behavior |
| --- | --- |
| `getCastable(actor)` | Return the selected enchanted item, selected spell, or `nil`. |
| `getEffectCost(effect, baseEffect?, method)` | Calculate one effect's cost using `CostMethod`. |
| `getEffectListCost(effects, method?)` | Sum effect costs; target-range effects receive the OpenMW multiplier. |
| `getSpellCost(spell)` | Return authored cost or calculate an autocalculated spell cost. |
| `getBaseCastChance(spell)` | Return base chance and the lowest effective magic school for the current S3lf actor. |
| `getSpellCastChance(spell, actor, checkMagicka?, cap?)` | Return effective cast chance, optionally checking magicka and clamping to `0..100`. |
| `getSpellSchool(spell)` / `getSpellIdSchool(id)` | Return the effective school identifier, or `nil` when an ID is unknown. |
| `spellIncreasesSkill(spell)` / `spellIdIncreasesSkill(id)` | Test whether a normal, non-always-succeed spell trains skill. |
| `getFatigueTerm()` | Calculate the current actor's fatigue multiplier. |
| `getEnchantmentCharge(enchantment)` | Return authored or autocalculated total enchantment capacity. |
| `getCastableIcon(actor)` | Return the selected castable's icon VFS path, or `nil`. |
| `getEnchantmentBaseCost(cost, actor)` | Apply the actor's Enchant skill adjustment, with a minimum result of `1`. |
| `getEffectiveEnchantCost(enchantment, actor)` | Calculate an enchantment's effective cast cost. |
| `getPotionValue(potion)` | Return authored or autocalculated potion value. |
| `rollIngredientEffect(caster, ingredient, index)` | Roll one of the four ingredient effects and return effect parameters, or `nil` when the roll fails. |

`CostMethod` contains `GameSpell`, `PlayerSpell`, `Enchantment`, and `Potion`. Autocalculation reads OpenMW game settings and magic-effect records. Invalid spell, enchantment, effect, actor, or ingredient inputs raise rather than becoming silently empty results. The helper performs ordinary temporary work for effect lists and ingredient rolls; it is intended for calculations, not per-frame polling without a caller-owned budget.

## Relationship to OpenMW

The formulas follow the engine's mechanics implementation, but the Lua boundary is not a promise that every detail is identical. In particular, `rollIngredientEffect` uses Lua's `math.random`, while current OpenMW uses its world PRNG. Read the [OpenMW spell utility implementation](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwmechanics/spellutil.cpp), especially [cost and charge calculations](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwmechanics/spellutil.cpp#L42-L160), [ingredient rolls](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwmechanics/spellutil.cpp#L162-L218), and [casting chance](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwmechanics/spellutil.cpp#L220-L303), when engine-version details matter.

Current consumers include [H4ND's HUD](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Ftalk_to_the_hand%2Fscripts%2Fs3%2FTTTH%2Fhud.lua) and [S3maphore's music core](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fs3maphore%2F00%20Core%2Fscripts%2Fs3%2Fmusic%2Fcore.lua).
