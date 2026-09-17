---
title: Specialist Agents
description: The four Cod3x OpenCode subagents and when a task deserves delegation to each one.
weight: 20
extra:
  kind: guide
---

Cod3x ships four specialist OpenCode subagents. Each one owns a domain where generic code review tends to miss important OpenMW or TES3 constraints.

They are deliberately capability-named. The name should tell you what evidence the agent is expected to establish.

## `tes3-plugin-analyst`

**Use for:** `.esp`, `.esm`, `.omwaddon`, TES3 records, placed references, conflicts, load order, leveled records, ownership/provenance, and package implications of plugin changes.

This agent is for questions where the answer must come from actual plugin data rather than filenames or intuition. It distinguishes base records from placed references, tracks which content file introduces or overrides a record, and refuses to call a load-order winner when the supplied load order is incomplete.

It prefers read-only inspection and treats conversion output such as `tes3conv` JSON as a representation of plugin data rather than raw plugin bytes.

Typical requests:

```text
Use tes3-plugin-analyst to determine which plugin changes this NPC's
inventory and whether the result depends on load order.
```

```text
@tes3-plugin-analyst Compare these two plugins and identify the records
that matter for this compatibility patch.
```

Pair it with [VFS analysis](#openmw-vfs-specialist) when plugin records reference assets whose provider matters, and with `openmw-mod-release-packager` when the findings change shipped plugins or install instructions.

## `openmw-save-data-specialist`

**Use for:** `LUAL`/`LUAD`, `.omwscripts`, Lua init data, script state serialization, persisted schema changes, migrations, and save/load compatibility.

This agent separates several layers that are easy to conflate: raw record payloads, conversion-tool JSON, generated script configuration, initialization data, and runtime save state. When persistence changes, it maps the owner, schema/version, defaults, serialization contract, and migration path.

It is intentionally suspicious of live userdata, engine objects, callbacks, metatables, and other runtime-only values crossing a save boundary without explicit OpenMW support.

Typical requests:

```text
Use openmw-save-data-specialist to review this migration before I ship it
to users with existing saves.
```

```text
@openmw-save-data-specialist Explain whether this LUAD JSON field maps
cleanly to the raw record or is only a conversion-layer representation.
```

Natural companion skills are `openmw-persistence-storage-auditor`, `openmw-lifecycle-debugger`, and `openmw-runtime-ordering-auditor`.

## `openmw-ui-specialist`

**Use for:** `openmw.ui`, MWUI, Settings renderers, menu/player UI, localization, layout ownership, element lifecycle, callbacks, and runtime UI bugs.

This is the broad UI specialist. It reviews both declarative layout structure and the retained `Element` lifecycle around it: root creation, mutation, `update`, replacement, destruction, callbacks, layers, context boundaries, and version-sensitive API behavior.

It does not assume that stale Cod3x metadata outranks the engine. When Cod3x and the matching OpenMW source disagree, the correct outcome is to fix or qualify Cod3x.

Typical requests:

```text
Use openmw-ui-specialist to review this inventory overlay. Focus on root
ownership, update/destroy paths, callbacks, and menu/player context.
```

```text
@openmw-ui-specialist Trace why this settings renderer works in a new game
but fails after returning to the main menu.
```

The UI specialist composes especially well with `openmw-ui-layout-author`, `openmw-ui-runtime-debugger`, `openmw-ui-settings-l10n`, `openmw-lua-context-guard`, and `openmw-lifecycle-debugger`.

## `openmw-vfs-specialist`

**Use for:** VFS lookup, data directories, loose files versus archives, case mismatches, archive conflicts, winning/shadowed providers, BSA/BA2 inspection, and missing resources.

This agent starts from the VFS-relative path and works outward through the configured search environment. It is designed to answer questions such as “why does this texture resolve to that file?” rather than merely proving that a similarly named file exists somewhere on disk.

It treats path casing as significant for compatibility analysis and prefers OpenMW-aware VFS/config tooling when available.

Typical requests:

```text
Use openmw-vfs-specialist to determine why meshes/foo/bar.nif is missing
in-game even though I can see it in one of my mod directories.
```

```text
@openmw-vfs-specialist Identify the winning provider for this DDS and all
shadowed copies.
```

Pair it with `openmw-asset-pipeline-checker` for generated/source asset problems and `openmw-mod-release-packager` when the resolution failure comes from the shipped archive layout.

## When not to delegate

Do not summon a specialist because the filename happens to contain `ui` or `save`.

Keep ordinary implementation in the primary coding agent when the relevant contract is already clear. Delegate when the task benefits from an independent evidence-gathering pass, touches a format or runtime boundary with expensive mistakes, or is large enough that isolating the investigation prevents the main session from filling with plugin dumps, VFS listings, traces, or source archaeology.

A specialist should return evidence and a bounded conclusion. The primary agent still owns integration with the rest of the change.
