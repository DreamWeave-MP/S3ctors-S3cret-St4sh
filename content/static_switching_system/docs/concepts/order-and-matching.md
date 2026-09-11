+++
title = "Matching, Priority, and Action Order"
description = "Deterministic SSS module order, condition matching, chance rolls, and action sequencing."
weight = 60

[extra]
kind = "concepts"
+++

## Module discovery and IDs

SSS scans `scripts/staticSwitcher/data/` for `.yaml` and `.yml` files, normalizes their VFS paths, and uses the normalized path as the canonical module ID. Files are initially collected in sorted path order. Preserve filenames and relative paths when updating a module if you want saved state to continue resolving it. An unambiguous legacy basename can be resolved for compatibility, but canonical IDs are safer.

## Priority tiers

`priority` is SSS module execution order, not plugin load order. Earlier tiers run first:

| Tier | Intended use |
| --- | --- |
| `cleanup` | Early cleanup work |
| `foundation` | Structural setup |
| `remodel` | Mesh/model changes |
| `balance` | Stats and difficulty |
| `standard` | Default |
| `polish` | Cosmetic finishing |
| `finisher` | Last-pass changes |

The labels are authoring conventions plus order; SSS does not enforce a special action vocabulary for a tier. Omitted priority means `standard`. Within a tier, the canonical module ID is the deterministic tie-breaker. The same order applies to instance rule evaluation and static replacement precedence and chain order. Unknown values fail module loading, while the schema rejects them before runtime.

Changing priority does not retroactively reorder replacement-chain steps already stored in a save. It affects future matching and application.

## Conditions

A rule's `conditions` list is ANDed: every condition entry must pass. A condition value written as an array is normally an OR-list, so this matches either record:

```yaml
- conditions:
    - record_id: [guar, nix-hound]
```

`global_value` is the exception: its array contains gates and every entry must pass. `not` inverts one inner condition; use multiple `not` entries for multiple exclusions. `record_id` accepts Lua pattern syntax, which is why the examples use anchors such as `^skeleton$`.

String matching is condition-specific. Cell names and IDs may use case-insensitive matching or substring matching where documented; `cell` is an exact cell name/ID comparison, `cell_match` is a case-insensitive substring search, and static `replace_names` is a case-insensitive name/ID substring filter. Read the [condition reference](@/static_switching_system/docs/api/module-format.md#conditions) before assuming that two string fields have the same semantics.

## Rules, chance, and actions

Instance rules remain in the order written in `instances`; matching rules are collected in module priority order. Within each rule, action fields execute in the fixed SSS order:

1. `replace`
2. `transform`
3. `teleport`
4. `set_ownership`
5. `add_tag`, `remove_tag`
6. `add`, `remove`, `equip`, `unequip`
7. `lock_level`, `key`, `trap`
8. `create`
9. `global_set`
10. `playsound`
11. `add_lua_script`, `activate_by_player`, `remove_lua_script`
12. `disable`
13. `delete`

An action block's `chance` is rolled before the fields in that block. Some fields have a second chance: item entries, sound data, key/trap candidates, replacement candidates, pools, and conditional disable. These rolls are independent.

`replace` is a map of candidate record IDs to chances. The chances are not normalized weights. The runtime tests candidates and uses the first successful candidate it encounters; YAML map iteration is not an authoring-order contract, so do not describe this as a weighted ordered list. Key and trap actions are different: their array of one-key tables is explicitly ordered and the first passing entry wins.

A same-table `replace` plus `delete` queues deletion only when replacement succeeds. Put `delete: true` in a separate action entry when source deletion must be unconditional. Replacement and transform placement updates are applied through the runtime's deferred processing; see [Lifecycle](@/static_switching_system/docs/api/lifecycle.md).
