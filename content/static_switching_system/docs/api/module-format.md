+++
title = "Module Format"
description = "The stable YAML authoring contract for static replacement and instance rule modules."
weight = 110

[extra]
api_docs = true
kind = "format"
+++

An SSS module is a YAML mapping with common metadata and exactly one pipeline. Use the shipped [schema](@/static_switching_system/docs/api/schema.md) in your editor; the shipped examples are reference material. For released static-module patterns, see [Static Modules in the Wild](@/static_switching_system/docs/recipes/static-modules-in-the-wild.md).

## Common fields

| Field | Type | Meaning |
| --- | --- | --- |
| `log_name` | string | Optional name used in SSS logging for the module. |
| `priority` | string | Execution tier: `cleanup`, `foundation`, `remodel`, `balance`, `standard`, `polish`, or `finisher`. Defaults to `standard`. |

`once` is not a common field in effect: the top-level field is allowed only on an instance module. Static modules must not use it. Rule-level `once` is described under [Instance modules](#instance-modules).

## Static modules

A static module contains `replace_meshes` and may contain these filters:

| Field | Type | Behavior |
| --- | --- | --- |
| `replace_meshes` | map of mesh path to mesh path | Maps the source record mesh to a replacement mesh. Paths are normalized for lookup; a missing replacement mesh is skipped and logged. |
| `replace_names` | string array | Matches cell name or ID case-insensitively, including substring matches. |
| `exterior_cells` | array of `{x, y}` | Matches listed exterior grid coordinates. |
| `replace_regions` | string array | Exact, case-insensitive cell region ID/name matches. |
| `ignore_records` | string array | Record IDs excluded before the mesh replacement is attempted. |

If `replace_names`, `exterior_cells`, and `replace_regions` are all omitted, the mesh map is eligible in every cell. If filters are present, a matching cell in any supplied filter is sufficient; the filter categories are ORed. `exterior_cells` only matches exterior cells.

This excerpt is copied from the shipped `StaticModule.yaml` example:

```yaml
log_name: "an example file"
replace_names:
  - "dagoth ur"
replace_regions:
  - "ashlands region"
exterior_cells:
  - x: 0
    y: 0
  - x: 0
    y: -1
replace_meshes:
  "totallyFake1.nif": "some_real/file1.nif"
  "totallyFake2.nif": "some_real/file2.nif"
```

The example intentionally uses illustrative paths. Use installed meshes in a real module. See [Pipelines and Module Boundaries](@/static_switching_system/docs/concepts/pipelines.md) and [Persistence and Once Semantics](@/static_switching_system/docs/concepts/persistence.md).

## Instance modules

An instance module contains an ordered `instances` array. Each rule has:

| Field | Type | Meaning |
| --- | --- | --- |
| `conditions` | array, optional | All condition entries must pass. Omit it for an unconditional rule. |
| `actions` | array, required | Action entries applied in the fixed action order below. |
| `once` | `true` or `per_cell`, optional | Cache successful application across saves, or only for the current activation batch. Despite its name, `per_cell` is not keyed by a tracked cell identity. |

Top-level `once: true` stops all later rules from that module for an object after any rule applies. It is not valid for static modules. A rule can combine multiple action fields, but each action entry must contain at least one supported action.

### Conditions

The supported condition keys are:

- **Location and provenance:** `cell`, `cell_match`, `coords`, `content_file`, `content_file_target`, `exterior`, `quasi_exterior`, `region`, `worldspace`.
- **Object identity and record data:** `record_id`, `object_type`, `mesh`, `generated_record`, `generated_object`, `nameMatch`, `has_name`, `scale`.
- **Scripts, tags, and equipment:** `has_lua_script`, `has_mwscript`, `has_tag`, `cell_tag`, `player_equipped`.
- **Actor and inventory state:** `carrying`, `is_dead`, `creature_type`, `race`, `target_class`, `target_disposition`, `target_level`, `target_attribute`, `target_skill`, `target_spell`.
- **Locks and ownership:** `locked`, `has_key`, `has_trap`, `owner_id`, `faction_owner_id`, `faction_owner_rank`, `target_faction`, `player_faction`.
- **Player and world state:** `player_level`, `player_attribute`, `player_skill`, `player_health`, `player_magicka`, `player_fatigue`, `player_spell`, `global_value`, `has_journal`, `time_of_day`, `current_weather`.
- **Logic:** `not` for one inverted inner condition.

Condition keys that refer to actors, NPCs, inventories, locks, tags, or other specialized state return false or no-op when the target does not support that state. `record_id` uses Lua pattern matching; anchor it when exact matching is required, for example `^rat$`. `content_file_target` scopes local reference numbers to a named content file:

```yaml
content_file_target:
  Morrowind.esm:
    - 67647
```

Arrays are normally OR-lists for one condition; `global_value` uses an array of gates that are all ANDed. See [Matching and Action Order](@/static_switching_system/docs/concepts/order-and-matching.md) for the distinction.

### Actions

The stable actions are:

| Action | Shape and behavior |
| --- | --- |
| `replace` | Map of replacement record ID to chance. Creates a replacement object when a candidate succeeds. Candidates are not normalized weights. |
| `transform` | `scale`, `rotate`, and/or `position`, with `transform_type: relative` (default) or `absolute`. |
| `teleport` | Optional cell name/ID or exterior `{x, y}`, position, relative rotation, and `onGround`. |
| `set_ownership` | Optional `owner`, `faction`, and `factionRank`. |
| `add_tag`, `remove_tag` | Add or remove a FlexTag tag when FlexTag is available. |
| `add`, `remove` | Add to or remove from Actor/Container inventories. Array removal uses the available quantity as its effective count. |
| `equip`, `unequip` | Force OpenMW item use on Actor targets. `equip` may create a missing item; `unequip` requires the requested count already equipped. |
| `lock_level` | Positive values lock; zero or negative values unlock. Non-lockable objects no-op. |
| `key`, `trap` | Set a selected key/trap from an ordered chance table, or use `false` to remove it. |
| `create` | Spawn one or more record pools at the trigger position, optionally with chance and per-object position/rotation/scale overrides. |
| `global_set` | Set an MWScript global to a fixed value or a sampled range. |
| `playsound` | Play a record sound or VFS sound file at the target, with optional chance, volume, pitch, loop, and time offset. |
| `add_lua_script`, `remove_lua_script` | Attach or remove a Lua script by VFS path. |
| `activate_by_player` | Activate the target as if the player used it. |
| `disable` | Disable the final action target, optionally with a chance. A replacement is the final target when replacement succeeds. |
| `delete` | Queue removal of the original source. With same-entry `replace`, removal occurs only after successful replacement. |

Item actions accept a record ID, an array of IDs, or a map of IDs to counts/details. Details may include `count` and `chance`; count ranges require `max`. Create entries accept a bare record ID, integer count, or pool object. See [Ranges](@/static_switching_system/docs/concepts/ranges.md) for default bounds and [Lifecycle](@/static_switching_system/docs/api/lifecycle.md) for deferred processing.

### Action order

When fields are combined in one action entry, SSS executes them in this order. YAML key order does not get a vote:

```text
replace → transform → teleport → set_ownership → add_tag → remove_tag
→ add → remove → equip → unequip → lock_level → key → trap → create
→ global_set → playsound → add_lua_script → activate_by_player
→ remove_lua_script → disable → delete
```

The `actions` array still determines the rule's action entries, but entries are normalized into this action-type order at module load. Use separate entries when you need separate `chance` rolls or unconditional deletion semantics.
