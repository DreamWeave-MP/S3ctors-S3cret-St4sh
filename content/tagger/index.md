---
title: Tagger
description: A community tagging standard for Morrowind records and cells. Tags dungeons, items, NPCs, ingredients, civic spaces, and more. Built as a dependency for mods like Static Switching System.
date: 2025-07-01

taxonomies:
  tags:
    - OpenMW-Lua
    - Frameworks
    - Dependencies

extra:
  install_info:
    data_directories:
      - .
    content_files:
      - Tagger.esp

  version: 1.0.0
---

Tagger is a lightweight, zero-overhead tagging framework for Morrowind on OpenMW. It lets mods ask questions like "is this cell a dungeon?" or "does this NPC belong to the Camonna Tong?" — without hardcoding IDs or guessing.

Nothing happens in-game just by installing Tagger. It's a dependency. Other mods use it.

## Built-In Tags

Tagger ships with six tag datasets covering the vanilla game and its DLCs:

<!-- more -->

| Module | Tags | What It Covers |
|---|---|---|
| `dungeon_tags.yaml` | 12 | 576 dungeon cells plus subcategories (mine, cave, daedric, dwemer, tomb, shipwreck, sewer, stronghold) |
| `item_tags.yaml` | 42 | Weapon and armor materials, clothing tiers, enchanted items, unique gear |
| `civic_tags.yaml` | 5 | Taverns, merchants, Tribunal Temples, Imperial Cult shrines |
| `npc_tags.yaml` | 22 | Bandits, Sixth House, vampires, necromancers, assassins, faction enemies — with vanilla-specific variants |
| `ingr_tags.yaml` | 9 | Edible vs. inedible ingredients, plants, fungi, minerals, animal parts, magical, quest |
| `item_origins.yaml` | 5 | Item origins: Morrowind, Skyrim, Cyrodiil, Orsinium, Elsweyr |

All tags use the record IDs from `Morrowind.esm`, `Tribunal.esm`, and `Bloodmoon.esm`. Case-insensitive.

## YAML Format

Tag data files live in a `ModTags/` directory under any `data=` path in `openmw.cfg`. The format is simple — each top-level key is a tag name, and its value is a list of record IDs:

```yaml
CellDungeon:
  - "addamasartus"
  - "ald daedroth, inner shrine"
  - "arkngthand, cells of hollow hand"

NPCBandit:
  - "adraria nilor"
  - "agrob gro-bolmog"
```

That's it. No wrapper keys, no `tags` list, no `applied_tags` map. Create as many files as you want. Tagger loads them all.

## API

Tagger exposes two interfaces: `I.TaggerG` (global scripts) and `I.TaggerL` (all other contexts). Both have the same functions. Every function that accepts an object also accepts a raw string record ID — case doesn't matter.

### Querying Tags

**`objectHasTag(object, tag)`** — returns `true` if the object has the tag. `tag` can be a single string or an array of strings (returns `true` on the first match).

```lua
if I.TaggerL.objectHasTag(self.cell, "CellDungeonDaedric") then
    -- do something in daedric ruins
end

if I.TaggerL.objectHasTag(self, {"NPCBandit", "NPCSixthHouse"}) then
    -- target is either a bandit or a Sixth House cultist
end
```

**`objectTags(object)`** — returns a table of all tags on an object (read-only).

```lua
local tags = I.TaggerL.objectTags(self)
if tags.NPCBandit then
    -- ...
end
```

**`getRecordsWithTag(tag)`** — returns an array of all record IDs that have a given tag.

```lua
local dungeons = I.TaggerG.getRecordsWithTag("CellDungeonMorrowind")
log(#dungeons .. " dungeon cells found")
```

**`tagList()`** — returns the set of all registered tag names.

**`appliedTags()`** — returns the full `{recordId: {tagName: true}}` map (read-only).

### Modifying Tags

**`addTag(object, tag)`** — adds one or more tags to an object. `tag` can be a single string or an array.

```lua
I.TaggerG.addTag(someNPC, "QuestActive")
I.TaggerG.addTag(someCell, {"CellExplored", "CellCleared"})
```

**`removeTag(object, tag)`** — removes one or more tags from an object.

```lua
I.TaggerG.removeTag(someNPC, "QuestActive")
```

Tags added or removed at runtime are visible immediately and persist for the session.

### Type Reference

| Type | Meaning |
|---|---|
| `Tagger.Taggable` | A string record ID, or any OpenMW game object (`GObject`, `LObject`, `SelfObject`), or a cell (`GCell`, `LCell`) |
| `Tagger.ObjectTag` | A tag name string |
| `Tagger.TagArg` | A single tag string or an array of tag strings |
| `Tagger.ObjectTagList` | A set of tag names (`{[tag] = true}`) |
| `Tagger.AppliedTags` | The full record-to-tag map (`{[recordId] = ObjectTagList}`) |

## For Mod Authors: Adding Tags

Drop a `.yaml` file into any `ModTags/` directory. Use the format above: top-level keys are tag names, values are arrays of record IDs. Tagger loads all files at startup, one key per frame, so even large files won't cause a hitch.

```yaml
# MyMod_tags.yaml
QuestActive:
  - "caldera_mine_slave_key"
  - "dwemer_boots_auriels"

CellCleared:
  - "addamasartus"
  - "gnisis, eggmine"
```

## Technical Notes

- Tags are loaded via a coroutine that yields between YAML keys — zero frame hitches.
- All storage writes are deferred until loading completes. Runtime tag mutations are atomic.
- The `TagList` catalogue prunes automatically when the last instance of a tag is removed.
- Storage lifetime is `Temporary` — nothing persists in your save file. Tags rebuild fresh each session.
