---
title: SSS Compatibility Translations from alvazir's Various Patches
description: Source attribution and links for SSS compatibility modules translated from alvazir's Various Patches.
weight: 20

extra:
  api_docs: true
  kind: compatibility
---

These modules translate two object-level compatibility fixes published in [alvazir's Various Patches](https://www.nexusmods.com/morrowind/mods/48955) into Static Switching System YAML. Install a module only when its named source mods are present; these examples are not loaded automatically by SSS.

The original compatibility research, reference IDs, coordinates, and patch intent belong to alvazir and the original mod authors. DreamWeave is translating those published fixes into SSS modules, not claiming to have discovered the conflicts.

| SSS module | Published fix |
| --- | --- |
| `Examples/Compatibility/Alvazir/PopulatedVvardenfell_BalmoraWaterworks.yaml` | Moves NPC `1hlaalunpc35` to the published Balmora Waterworks coordinates for [Populated Vvardenfell](https://www.nexusmods.com/morrowind/mods/48955). |
| `Examples/Compatibility/Alvazir/ValitysBitterCoast_TwinLamps.yaml` | Disables refNum `361` from the published Vality's Bitter Coast addon in exterior cell `(-6, -7)`. |

See the [real-world compatibility patch guide](@/static_switching_system/docs/compatibility/real-world-patches.md) for the broader SSS translation list and targeting notes. The module headers retain the direct source link.
