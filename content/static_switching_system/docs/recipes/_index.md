+++
title = "Static Switching System Recipes"
description = "Copyable YAML patterns for static replacement and instance rules."
template = "docs/section.html"
page_template = "docs/page.html"
sort_by = "weight"
weight = 10

[extra]
api_docs = true
kind = "guide"
+++

These recipes turn the shipped SSS examples into focused patterns. Put each module in an active data directory under `scripts/staticSwitcher/data/`. Use either static replacement fields or `instances`, never both. If SSS is not installed, start with [Getting Started](@/static_switching_system/docs/getting-started/_index.md) and its [five-minute test](@/static_switching_system/index.md#start-here-a-five-minute-test).

## Choose a recipe

- [Static modules in the wild](@/static_switching_system/docs/recipes/static-modules-in-the-wild.md) — study released SSS replacers and compatibility modules.
- [Basic static replacement](@/static_switching_system/docs/recipes/basic-static-replacement.md) — swap a mesh everywhere.
- [Contextual static replacement](@/static_switching_system/docs/recipes/contextual-static-replacement.md) — restrict a mesh swap by cell, region, or exterior grid.
- [Wildlife randomization](@/static_switching_system/docs/recipes/wildlife-randomization.md) — give creature instances a persistent or per-load random scale.
- [Quest-state world patching](@/static_switching_system/docs/recipes/quest-state-world-patching.md) — gate a world replacement on a journal stage.
- [Randomized object creation](@/static_switching_system/docs/recipes/randomized-object-creation.md) — scatter created objects around an active trigger.
- [Loot, locks, and traps](@/static_switching_system/docs/recipes/loot-locks-traps.md) — modify containers and doors with level and chance gates.
- [Actor scaling and equipment](@/static_switching_system/docs/recipes/actor-scaling-equipment.md) — target one actor, equip items, and set scale.
- [Dungeon creature repopulation](@/static_switching_system/docs/recipes/dungeon-creature-repopulation.md) — recreate dead, respawning-marked creatures in tagged dungeon cells.
- [Scheduled teleportation](@/static_switching_system/docs/recipes/scheduled-teleportation.md) — move an actor when activation-time conditions match.

For range semantics, use [Comparison and Random Ranges](@/static_switching_system/docs/concepts/ranges.md). Comparison ranges test values; random ranges sample them. They use different syntax.
