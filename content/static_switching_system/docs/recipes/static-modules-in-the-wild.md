+++
title = "Static Modules in the Wild"
description = "Released Morrowind mods that use SSS static replacement modules."
weight = 5

[extra]
api_docs = true
kind = "recipe"
+++

The static pipeline is not a theoretical feature. These released mods use it to ship mesh replacements and compatibility patches without editing every affected reference in a plugin. Every module listed here is a **static module**; none is an instance-module example.

The linked mod pages remain authoritative for installation, versions, dependencies, and asset permissions. The examples below describe what their SSS modules demonstrate.

## Existing modules

| Mod | What its static module demonstrates |
| --- | --- |
| [White Suran 2 - MD Edition](https://www.nexusmods.com/morrowind/mods/44153) | A large Hlaalu mesh remap scoped by Suran names and exterior grid cells. It also covers assets from other content packages. |
| [Unique Velothi Interiors](https://www.nexusmods.com/morrowind/mods/57515) | A broad ancestral-tomb retexture spanning base-game, Tamriel Rebuilt, and OAAB mesh paths. The SSS component is optional and applies to the tombs. |
| [Suran O Suran - Compatibility Patches](https://www.nexusmods.com/morrowind/mods/59893) | A focused compatibility module that remaps the added Suran meshes from OAAB, Tamriel Rebuilt, and related content only in the affected exterior cell. |
| [Red Vos](https://www.nexusmods.com/morrowind/mods/44729) | A location-scoped village overhaul: one exterior grid cell, one cell-name filter, and a static mesh map covering the interior and exterior kit. |
| [On the Rocks Tamriel Rebuilt Compatibility Patch](https://www.nexusmods.com/morrowind/mods/58238) | Many small coordinate-scoped modules that restore original rocks only where the On the Rocks meshes conflict with Tamriel Rebuilt. More than 70 rock placements are covered. |
| [Landscape - Aendemika of Solstheim - The Breath of All-Maker](https://www.nexusmods.com/morrowind/mods/59755) | An optional Tomb of the Snow Prince barrow replacer covering 270 unique exterior coordinates and one interior cell with a large replacement map. |
| [G.A.S. - Green Azura Shrines - Aestetika of Vvardenfell](https://www.nexusmods.com/morrowind/mods/59752) | Three installer-selected scopes for the same Daedric replacement kit, from Azura's shrines to barren-coast shrines across Vvardenfell and Tamriel Rebuilt. |
| [Caverns Revamp - Cleaned-up and Compatible](https://www.nexusmods.com/morrowind/mods/57911) | A compatibility patch scoped to named Old Mournhold cells, replacing only the cavern meshes that cause visible seams. |
| [Anthony's Minor Mods and Patches](https://www.nexusmods.com/morrowind/mods/57811) | A static SSS component for the Shabby Balmora Labor Town buildings, allowing the resource mod to be used without its original ESP. |

## Patterns worth copying

### Use the narrowest location selector that expresses the intent

Use `replace_names` for a logical group of cells, `exterior_cells` for exact exterior coordinates, and both when the module needs both kinds of coverage:

```yaml
replace_names:
  - "suran"

exterior_cells:
  - x: 6
    y: -7
```

Location filters are ORed. They are not a hidden AND expression. Split separate intents into separate modules instead of making one file carry an ambiguous scope.

### Small compatibility patches can be better than one large file

The On the Rocks patch uses one small static module per rock mesh and coordinate set. That makes each exception visible, independently maintainable, and easy to extend when another conflicting placement is found. A compatibility patch does not need to pretend it is a grand overhaul.

### Preserve the asset provider's VFS paths

The source and replacement paths in these modules point into the packages that provide the meshes. Install the required resource mod first, keep the paths case-correct, and expose both packages through the OpenMW VFS. A valid YAML map cannot make a missing mesh appear.

### Treat installer variants as mutually exclusive choices

G.A.S. ships different scopes as alternatives with the same module identity. Install the scope you want, not every variant. The same approach is useful when a replacement has optional coverage for another content package or compatibility patch.

### Keep static and instance intent separate

These mods use the static pipeline because their intent is “when this mesh is encountered in these places, use that mesh.” Use an instance module when the rule must inspect active-object state, player state, world state, or apply a non-mesh action. Do not combine `instances` with static replacement fields merely because both forms are available.

See [Contextual Static Replacement](@/static_switching_system/docs/recipes/contextual-static-replacement.md) for the authoring pattern, [Pipelines and Module Boundaries](@/static_switching_system/docs/concepts/pipelines.md) for the boundary, and [VFS and Package Boundaries](@/static_switching_system/docs/compatibility/vfs-package-boundaries.md) for installation details.
