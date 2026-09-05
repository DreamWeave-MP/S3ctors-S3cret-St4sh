+++
title = "Journal and Services Rules"
description = "Rules for quest journal stages and nearby merchant services."
weight = 40

[extra]
api_docs = true
kind = "PlaylistRules"
+++

## `journal`

{{ api_signature(value="Playback.rules.journal(journalDataMap) -> boolean") }}

Returns `true` when any named quest has a journal stage inside its inclusive `min`/`max` range. A missing bound is unbounded.

```lua
local InformantStages = {
    A1_V_VivecInformants = { min = 50, max = 55 },
}

isValidCallback = function()
    return Playback.rules.journal(InformantStages)
end
```

Quest IDs are the engine quest identifiers. Keep the table outside the callback so the journal cache can reuse it.

## `localMerchantType`

{{ api_signature(value="Playback.rules.localMerchantType(services) -> boolean") }}

Returns `true` when a nearby actor offers every requested service with the requested boolean value. It does not match while the player is in combat.

Supported service keys include `Apparatus`, `Armor`, `Barter`, `Books`, `Clothing`, `Enchanting`, `Ingredients`, `Lights`, `Misc`, `MagicItems`, `Repair`, `RepairItem`, `Spellmaking`, `Spells`, `Training`, `Travel`, `Picks`, `Potions`, `Probes`, and `Weapon`.

```lua
local Armorer = {
    Armor = true,
    Repair = true,
}

isValidCallback = function()
    return Playback.rules.localMerchantType(Armorer)
end
```

The rule succeeds on the first nearby actor satisfying all entries. In a cell with several merchants, combine it with `cellNameExact` or `cellNameMatch` to avoid an overly broad match.
