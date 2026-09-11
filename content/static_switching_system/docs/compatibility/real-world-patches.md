+++
title = "Real-World Compatibility Patches"
description = "Published Morrowind compatibility fixes translated into SSS modules."
weight = 20

[extra]
api_docs = true
kind = "compatibility"
+++

These are not hypothetical examples. They are SSS translations of object-level compatibility fixes published by [MOMW Patches](https://gitlab.com/modding-openmw/momw-patches), plus two fixes from [alvazir's various patches](https://www.nexusmods.com/morrowind/mods/48955). The original projects discovered the conflicts and published the reference IDs, coordinates, and intended changes. DreamWeave is translating that work into SSS YAML.

The ready-to-copy modules are in `Examples/Compatibility/MOMW/` and `Examples/Compatibility/Alvazir/`. They are optional examples, not automatic compatibility behavior. Install a module only when the named source mods are installed.

## From MOMW Patches

The [MOMW Patches repository](https://gitlab.com/modding-openmw/momw-patches) is [MIT-licensed](https://gitlab.com/modding-openmw/momw-patches/-/blob/master/LICENSE). We preserve attribution here: Modding-OpenMW contributors supplied the compatibility research and patch data; SSS supplies the translation.

| Original patch | SSS translation | Result |
| --- | --- | --- |
| [06 Cutting Room Floor + BCoM](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/06%20Cutting%20Room%20Floor+BCOM%20Patch) | `Examples/Compatibility/MOMW/CuttingRoomFloor_BCOM_FarasChest.yaml` | Replaces a one-shot `PositionCell` MWScript with one declarative teleport rule. |
| [22 BCoM + QCVL](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/22%20BCOM+Quests%20for%20Clans%20and%20Vampire%20Legends%20Patch) | `Examples/Compatibility/MOMW/BCOM_QCVL_Elayne.yaml` | Moves the scripted QCVL NPC out of a wall. |
| [46 Bitter Coast Waterway](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/46%20Bitter%20Coast%20Waterway%20Cliff%20Fix) | `Examples/Compatibility/MOMW/BitterCoastWaterway_CliffFix.yaml` | Moves three exact rocks and disables one tree. |
| [66 Repopulated Morrowind × The Wolverine Hall](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/66%20RepopulatedMorrowindxTheWolverineHall%20patch) | `Examples/Compatibility/MOMW/RepopulatedMorrowind_WolverineHall.yaml` | Disables one reference and relocates two NPCs. |
| [73 Dungeon Details Grotto Fix](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/73%20Dungeon%20Details%20Grotto%20Fix) | `Examples/Compatibility/MOMW/DungeonDetails_GrottoSeamFix.yaml` | Relocates five exact cave-cliff references. |
| [76 Little Landscape Path to Pelagiad](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/76%20Little%20Landscape%20Path%20to%20Pelagiad%20Rock%20Fix) | `Examples/Compatibility/MOMW/LittleLandscape_PathToPelagiad.yaml` | Moves one cliff across an exterior-cell boundary. |
| [78 Little Landscape Foyada of Sharp Teeth](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/78%20Little%20Landscape%20Foyada%20of%20Sharp%20Teeth%20Rock%20Fix) | `Examples/Compatibility/MOMW/LittleLandscape_FoyadaSharpTeeth.yaml` | Moves vanilla and plugin references and disables one vanilla tree. |
| [81 Odai River Upper Overhaul](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/81%20Odai%20River%20Overhaul%20Statue%20Remover%20Patch) | `Examples/Compatibility/MOMW/OdaiRiverUpper_StatueRemover.yaml` | Disables two exact statues. |
| [82 Immersive Mournhold](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/82%20Immersive%20Mournhold%20Corner%20Tower%20Remover%20Patch) | `Examples/Compatibility/MOMW/ImmersiveMournhold_CornerTowers.yaml` | Collapses a 422-line exported patch into three exact-reference rules. |
| [89 BCoM × Immersive Imperial Skirt](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/89%20BCOM%20x%20Immersive%20Imperial%20Skirt) | `Examples/Compatibility/MOMW/BCOM_ImmersiveImperialSkirt.yaml` | Moves the skirt vendor NPC from the void. |

## Other published examples

The [alvazir source collection](https://www.nexusmods.com/morrowind/mods/48955) documents these two translations:

- `Examples/Compatibility/Alvazir/PopulatedVvardenfell_BalmoraWaterworks.yaml` moves NPC `1hlaalunpc35` to the published Balmora Waterworks coordinates.
- `Examples/Compatibility/Alvazir/ValitysBitterCoast_TwinLamps.yaml` disables refNum `361` from the published Vality's Bitter Coast addon in exterior cell `(-6, -7)`.

SSS `content_file_target` is intentionally close to the source patch vocabulary: it combines the originating content file with that file's local reference number. TES3 `ObjIdx` and the OpenMW local reference number are the same targeting idea here; this is why the tree and statue removals do not need a fragile record-ID guess.

## Attribution

The [MOMW translation index](@/static_switching_system/docs/compatibility/MOMW/index.md) and [alvazir translation index](@/static_switching_system/docs/compatibility/Alvazir/index.md) contain the source attribution and module tables. SSS does not claim the original compatibility research.

## Reading moved references in MOMW exports

In a MOMW export, `Cell.grid` identifies the source cell where the original reference must be found. `moved_cell` identifies the destination cell. SSS conditions target the source cell; `teleport.cell` targets the destination.
