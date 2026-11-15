+++
title = "Validation and Debugging"
description = "Validate YAML before loading and use SSS's runtime diagnostics without relying on internals."
weight = 90

[extra]
kind = "concepts"
+++

Use the JSON Schema shipped at `Scripts/staticSwitcher/schema/replacerSchema.json` in your YAML editor. It describes the stable authoring API: root module shape, conditions, actions, enum values, and range forms. The schema rejects mixed static/instance modules, static modules using instance-only top-level `once`, stale condition names, invalid priority values, and random action ranges that omit `max`.

Runtime validation is lighter than the schema. SSS warns about unknown top-level keys, modules with neither `replace_meshes` nor `instances`, and mixed root shapes. Validate in the editor before installing a module.

Two runtime checks fail closed, and both log regardless of the debug setting:

- An instance rule is skipped whole, with a `[WARN] Skipped rule N in <module>` line naming the problem, when it has an unknown condition, action, or trigger name; a trigger listed twice; a condition or action its trigger cannot support; an `object_type` that is not an OpenMW type; a malformed `record_id` or `used_item` Lua pattern; a missing `actions` list; a sampled range that the action could not use (a position, rotation, count, chance, lock level, or global value range without `max`, a count, lock level, or scale with `min` above `max`); a scale range without `max`, which would otherwise be sampled with `min` as its upper bound; a `transform_type` other than `relative` or `absolute`, which would otherwise be read silently as `absolute`; or an action missing a required field (`set_weather` without a weather, `global_set` without a name, `call_interface` without an interface and function, an event without a name, a script action without a path). The module's other rules still load.
- A module that cannot be read or parsed is skipped with an `[ERROR] Skipped module <path>` line. Other modules still load.

Some failures cannot be known until the game is running, because they depend on the load order: a record, sound, script, or global the engine does not have, or another mod's interface refusing a call. When the engine or another mod refuses an action for a reason like that, the action is skipped and reported once with `[WARN] Action <name> failed and was skipped`. It counts as not applied. The rest of the rule still runs, placement is still committed, and `once` is recorded only if something else in the rule applied, so a rule that fails part-way does not repeat its earlier actions, and a rule in which nothing applied is tried again next time.

Replacing, transforming, and teleporting take effect when placement is committed, once, at the end. If the engine refuses it, `[WARN] Action placement failed and was skipped` is logged and those actions count as not applied. Whether the rule is then recorded follows [where its effects live](@/static_switching_system/docs/concepts/persistence.md#instance-rules): a rule that only replaced, transformed, or changed the replacement it made is not recorded and will try again, while a rule that sent an event or changed the original object stays recorded. A refused placement cancels everything that depends on the commit, `disable` and `delete` included: the object is not disabled, not deleted, and keeps its scale.

Placement is the one part of a commit the engine can refuse outright, because the destination cell does not exist or the object is already being moved. Once it is accepted, the move itself is carried out by OpenMW at the end of the frame and cannot be called off. If a pass fails after that point, which only an error inside SSS can cause, the pass is abandoned and put right afterwards: a replacement that was on its way is removed once it has landed, an object that was moved is put back once it has arrived, and the original's enabled state is restored to what it was before the pass, which is not necessarily enabled. If the object moved was the player, neither turning up at the destination nor being put back counts as a `cell_enter`. Rules that depended on the commit are not recorded.

Anything SSS created and then could not use is removed again: a replacement that was not placed, a created object that could not be placed, an item an inventory refused. These corrections, and the ones for an abandoned pass, are worked off four per frame however many are waiting. One that the engine refuses is logged as `[WARN] A stray <record> could not be removed and will be retried` (or `put back where it was`), tried again on later frames, and given up after eight tries with `[WARN] Gave up: a stray <record> was never removed`. Corrections still waiting when the game is saved are saved with it and carried out after loading.

A delayed deletion that the engine refuses when its turn comes is logged as `[WARN] A queued removal was refused and dropped` and taken off the queue, so it cannot hold up the deletions behind it. A deletion whose target is being moved when its turn comes waits a few frames for the target to land instead.

Anything else that goes wrong while a rule runs, such as an error in a condition, is not treated as a skipped step. It stops work on that object with `[ERROR] Skipped <object id> (<record id>)`, rolls back a replacement that had been started, and SSS moves on to the next object. An `[ERROR]` line of this kind is worth reporting: it means SSS met something it does not handle. A `replace` or `create` action naming a record that cannot be instantiated logs one `[WARN]` per record ID.

## Debug logging

Enable `StaticSwitcherEnableDebug` in the OpenMW settings menu. It defaults to `false`. SSS then emits verbose `[ SSS ]` debug and information messages. The setting is operational; module behavior still comes from YAML. These messages can show:

- module discovery and load counts;
- object activation and batch progress;
- condition failures and OR-list results;
- instance rule matches, once skips, and chance misses;
- static module skips, mesh matches, missing meshes, and chain limits;
- delayed deletion progress.

Warnings and errors ignore the debug checkbox. Look for the `SSS` prefix in `openmw.log` or the OpenMW console.

## A practical diagnosis order

1. Confirm the YAML is below the discovered VFS prefix and has a supported extension.
2. Confirm the module is one pipeline, not a mixed root.
3. Validate record IDs, cell names, coordinates, content-file reference numbers, and case-sensitive VFS paths.
4. For a static module, check that the source mesh matches the object's record mesh and that the replacement mesh exists.
5. For an instance module, temporarily remove `once`, narrow conditions, and inspect the action order and chance values.
6. Check whether the target is a supported object type. Inventory actions require an Actor or Container; lock/key/trap actions require a lockable object; actor-only conditions return false for other types.
7. If a disabled object is expected to change on re-entry, redesign the rule: disabled objects do not reliably become active again for SSS.

For runtime timing and save/load behavior, use [Lifecycle](@/static_switching_system/docs/api/lifecycle.md). For the exact field contract, use [Module Format](@/static_switching_system/docs/api/module-format.md) and [Schema](@/static_switching_system/docs/api/schema.md).
