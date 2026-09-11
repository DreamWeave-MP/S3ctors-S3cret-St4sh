---
title: SSS Compatibility Translations from MOMW Patches
description: Source attribution and links for SSS compatibility modules translated from MOMW Patches.
weight: 10

extra:
  api_docs: true
  kind: compatibility
---

These modules translate object-level compatibility fixes published by the [MOMW Patches](https://gitlab.com/modding-openmw/momw-patches) project into Static Switching System YAML. Install a module only when its named source mods are present; these examples are not loaded automatically by SSS.

Original compatibility research, reference IDs, coordinates, and patch intent belong to the respective Modding-OpenMW contributors and original mod authors. DreamWeave is translating those published fixes into SSS modules, not claiming to have discovered the conflicts. MOMW Patches is [MIT-licensed](https://gitlab.com/modding-openmw/momw-patches/-/blob/master/LICENSE).

| SSS module | Original patch |
| --- | --- |
| `CuttingRoomFloor_BCOM_FarasChest.yaml` | [MOMW 06: Cutting Room Floor + BCoM](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/06%20Cutting%20Room%20Floor+BCOM%20Patch) |
| `BCOM_QCVL_Elayne.yaml` | [MOMW 22: BCoM + QCVL](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/22%20BCOM+Quests%20for%20Clans%20and%20Vampire%20Legends%20Patch) |
| `BitterCoastWaterway_CliffFix.yaml` | [MOMW 46: Bitter Coast Waterway Cliff Fix](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/46%20Bitter%20Coast%20Waterway%20Cliff%20Fix) |
| `RepopulatedMorrowind_WolverineHall.yaml` | [MOMW 66: Repopulated Morrowind × The Wolverine Hall](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/66%20RepopulatedMorrowindxTheWolverineHall%20patch) |
| `DungeonDetails_GrottoSeamFix.yaml` | [MOMW 73: Dungeon Details Grotto Fix](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/73%20Dungeon%20Details%20Grotto%20Fix) |
| `LittleLandscape_PathToPelagiad.yaml` | [MOMW 76: Little Landscape Path to Pelagiad Rock Fix](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/76%20Little%20Landscape%20Path%20to%20Pelagiad%20Rock%20Fix) |
| `LittleLandscape_FoyadaSharpTeeth.yaml` | [MOMW 78: Little Landscape Foyada of Sharp Teeth Rock Fix](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/78%20Little%20Landscape%20Foyada%20of%20Sharp%20Teeth%20Rock%20Fix) |
| `OdaiRiverUpper_StatueRemover.yaml` | [MOMW 81: Odai River Upper Overhaul Statue Remover](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/81%20Odai%20River%20Overhaul%20Statue%20Remover%20Patch) |
| `ImmersiveMournhold_CornerTowers.yaml` | [MOMW 82: Immersive Mournhold Corner Tower Remover](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/82%20Immersive%20Mournhold%20Corner%20Tower%20Remover%20Patch) |
| `BCOM_ImmersiveImperialSkirt.yaml` | [MOMW 89: BCoM × Immersive Imperial Skirt](https://gitlab.com/modding-openmw/momw-patches/-/tree/master/89%20BCOM%20x%20Immersive%20Imperial%20Skirt) |

The source plugin exports express rotations in radians; SSS transform fields use degrees, so exported rotations are converted in these modules. The target cells and provenance constraints remain explicit so a module does not silently alter an unrelated installation.
