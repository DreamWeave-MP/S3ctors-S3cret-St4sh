+++
title = "Validation and Debugging"
description = "Validate YAML before loading and use SSS's runtime diagnostics without relying on internals."
weight = 90

[extra]
kind = "concepts"
+++

Use the JSON Schema shipped at `Scripts/staticSwitcher/schema/replacerSchema.json` in your YAML editor. It describes the stable authoring API: root module shape, conditions, actions, enum values, and range forms. The schema rejects mixed static/instance modules, static modules using instance-only top-level `once`, stale condition names, invalid priority values, and random action ranges that omit `max`.

Runtime validation is lighter than the schema. SSS warns about unknown top-level keys, modules with neither `replace_meshes` nor `instances`, and mixed root shapes. Validate in the editor before installing a module.

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
