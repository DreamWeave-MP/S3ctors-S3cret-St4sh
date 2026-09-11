+++
title = "Behavioral Edge Cases"
description = "The SSS behaviors most likely to surprise an otherwise valid module."
weight = 95

[extra]
kind = "concepts"
+++

SSS keeps the normal path small, but valid-looking modules can still hit boundary behavior. The rules below are authoring contracts where stated; otherwise test them with debug logging before relying on them.

## Dispatch and matching

- A file is either a static module or an instance module. The root markers cannot be combined.
- When an object becomes active, matching instance rules own that activation. If an instance action later misses its chance roll, SSS does not fall back to static replacement for the same activation.
- Conditions in one rule are ANDed. Array values are usually OR-lists, but `global_value` entries are all required.
- `record_id` uses Lua-pattern matching. Anchor exact matches with `^` and `$`, and escape Lua pattern characters when necessary.
- String matching is field-specific. `cell` is exact and case-sensitive; `cell_match` is case-insensitive substring matching; `nameMatch` is plain substring matching without case folding; static `replace_names` is case-insensitive substring matching.
- An unsupported target usually makes a specialized condition false or an action a no-op. An unknown `object_type` is different: it raises an invalid-type error.

## Ordering and selection

- Module priority controls execution order, not plugin load order. Same-tier modules use canonical module ID as the tie-breaker.
- Instance rules remain in their module order, but every matching rule can contribute. `once` skips only the rule or module scope it governs; it is not a general “stop all later modules” switch.
- Fields in one action table execute in SSS's fixed action order, not YAML mapping order. Use separate action entries when you need separate block chances or unconditional deletion.
- `replace` candidate maps are not weighted tables and do not provide YAML authoring order. The runtime uses the first passing candidate it encounters; only scalar `replace: self` recreates the matched object's base record. `key` and `trap` arrays are explicitly ordered first-passing selections.

## Target and timing behavior

- After a successful `replace`, later property, inventory, script, tag, sound, transform, teleport, and disable actions in the same action table target the replacement. `delete` still refers to the original source.
- Same-table `replace` plus `delete` deletes the source only after replacement succeeds. Put `delete: true` in a separate action entry for unconditional source deletion.
- SSS accumulates transform and teleport placement changes, then performs one engine placement operation after the action list finishes. A later transform continues from the intended teleported position and rotation and clears an earlier teleport's `onGround` request. Deletion is queued for later frames. `equip` and `unequip` queue OpenMW `UseItem` events rather than synchronously changing the final equipment table.
- `disable` applies to the final action target, but disabled objects may not generate a later `onObjectActive` event. SSS therefore cannot use disable as a reliable cross-cell toggle.
- `create` evaluates each record pool independently and creates every object in a successful pool. It is not a one-winner selection.

## Persistence and optional integrations

- `once: true` is saved by object handle, canonical module ID, and rule-data hash. Editing a rule can give it a new identity and allow it to apply again; changing YAML does not undo an already-saved world effect.
- Static replacement chains are historical. Priority changes affect future applications, not existing chain order. A chain allows at most 8 replacement steps and never applies the same module twice to one lineage.
- A FlexTag-dependent condition returns false without FlexTag. `add_tag` and `remove_tag` cannot perform their operation without the interface, but the current dispatcher still treats those selected fields as handled for once bookkeeping.
- Script attachment/removal, activation, tags, and sound playback affect engine state or other systems; they are not automatically reversed when a YAML module changes.

## Numeric and value traps

- Comparison ranges and action ranges are different. Conditions may omit either bound; sampled action ranges require `max`.
- Range defaults are action-specific: position and rotation normally start at `0`, while scale, count, lock, and `global_set` ranges normally start at `1` or `1.0`.
- Lua treats `0` as truthy. Zero lower bounds are therefore real values for scale and `global_set`, and zero-valued optional sound settings can be forwarded when supplied.
- `set_ownership.factionRank: 0` is a real rank value, not a clear-ownership operation; there is no documented ownership-clear form.
- `key: false` and `trap: false` clear those values. There is no equivalent documented clear form for ownership.
