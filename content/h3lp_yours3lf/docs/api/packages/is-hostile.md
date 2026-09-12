---
title: isHostile
description: Test whether an actor meets the engine's aggression threshold for a target.
weight: 76
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.isHostile'(actor, target) → boolean") }}

Use `isHostile` when a global script needs the same broad aggression calculation used by OpenMW's combat logic, without starting combat or mutating either actor.

```lua
local isHostile = require 'scripts.s3.isHostile'

if isHostile(actor, player) then
    includeInCombatMusic(actor)
end
```

The helper returns `false` for missing, depleted, invalid, or identical objects; actors that cannot move; and actors currently suppressed by the appropriate Calm Humanoid or Calm Creature effect. Otherwise it combines AI Fight, disposition, distance, and the werewolf modifier, returning `true` when the resulting fight term is at least `100`.

This is a predicate, not a combat-state query. It does not make the actor attack, and it does not include OpenMW's separate shortcut for an actor already in combat. The Lua helper also uses the objects' full position distance, so it should be treated as a practical compatibility helper rather than a promise of bit-for-bit identity with every combat path.

The calculation is based on OpenMW's [`getFightTerm` and `isAggressive`](https://github.com/OpenMW/openmw/blob/master/apps/openmw/mwmechanics/combat.cpp#L555-L646). The H3 implementation is [here](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content%2Fh3lp_yours3lf%2Fscripts%2Fs3%2FisHostile.lua).
