---
title: Reusable Skills
description: The twelve Cod3x OpenCode skills for context, lifecycle, persistence, UI, performance, assets, releases, and public API work.
weight: 30
extra:
  kind: guide
---

Skills are narrower than agents. They are reusable engineering contracts that OpenCode can advertise to the current model and load only when the task needs them.

The Cod3x pack currently ships twelve.

## Runtime correctness

### `openmw-lua-context-guard`

**Use when:** importing `openmw.*`, moving code between script types, sharing modules across contexts, or reviewing Cod3x context diagnostics.

The skill enforces the narrowest correct context, checks API availability against the target OpenMW revision, and treats a multi-context module as a shared contract rather than permission to hide context-specific imports behind a broad annotation.

Use it early. A context error discovered after a subsystem has been designed around the wrong owner is much more expensive than one discovered at the import boundary.

### `openmw-lifecycle-debugger`

**Use when:** behavior differs between new games, existing saves, mod updates, reloads, `onInit`, `onLoad`, top-level module execution, or delayed script activation.

It forces fresh-game and old-save paths to be treated as different execution histories. The skill inventories top-level work, storage access, subscriptions, migrations, and cross-context readiness rather than assuming every dependency exists because one handler fired.

### `openmw-runtime-ordering-auditor`

**Use when:** correctness depends on event delivery, delayed actions, timers, inventory/equipment mutation, UI redraw timing, save/load ordering, or object lifetime across an asynchronous boundary.

The critical rule is simple: runtime ordering is version- and scenario-sensitive. The skill prefers explicit request/acknowledgement and stable IDs over “this event probably finishes before the next line matters,” and asks for source or a narrow trace when sequencing is not guaranteed.

It also defines Cod3x's compact `OMWTRACE` convention for proving disputed order without turning logging into a second application.

### `openmw-persistence-storage-auditor`

**Use when:** changing `openmw.storage`, settings-backed state, save data, persistent schemas, defaults, migrations, or cached data that may accidentally cross a save boundary.

It classifies state by owner and lifetime, treats every persisted key/shape/identifier as a compatibility contract, requires non-destructive defaults and idempotent migrations, and separates rebuildable runtime caches from durable state.

This is the skill to invoke before “it's only one field” becomes a permanent save-format decision.

## UI

### `openmw-ui-layout-author`

**Use when:** building or reviewing `openmw.ui` layout tables, `Content`, named children, layers, `Element:update`, dynamic regions, or root ownership.

The skill keeps one explicit owner for a logical surface, prefers direct named-child access over routine recursive search, distinguishes the construction table from the live `Element.layout`, and demands deliberate update/destroy behavior.

Use it for structure. Use the runtime debugger below when the structure looks correct but the game disagrees.

### `openmw-ui-runtime-debugger`

**Use when:** redraws disappear, callbacks become stale, roots are destroyed unexpectedly, menu/inventory state changes race UI work, timers fire against old generations, or static inspection cannot establish the failure.

The workflow is runtime-first: instrument the smallest path, reproduce the target scenario, prove request/mutation/defer/redraw/destroy order, inspect snapshots when needed, and remove the temporary instrumentation after the claim is established.

### `openmw-ui-settings-l10n`

**Use when:** changing OpenMW Settings definitions, renderers, setting IDs, menu/player settings UI, localization keys/files, or user-facing settings documentation.

It keeps IDs and localization keys aligned across data, Lua, and docs; checks renderer contracts against the target OpenMW revision; preserves persisted setting compatibility; and prevents menu UI from casually assuming gameplay state is already available.

## Performance and API surface

### `openmw-performance-hotpath-reviewer`

**Use when:** code runs per frame, per actor/object, in render/update callbacks, through large event fanout, across native API boundaries, or in other high-frequency paths.

The skill begins with call frequency and fanout, not folklore. It looks for allocation churn, repeated scans, expensive UI rebuilds, engine-bound lookups, storage reads, and work that should leave the hot path entirely. It also keeps LuaJIT and Luau analysis separate: observations about one runtime do not automatically transfer to the other.

Pair it with [Measure First](@/cod3x/docs/performance/measure-first.md) and [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md) when the task reaches actual performance claims.

### `cod3x-luals-stub-maintainer`

**Use when:** changing Cod3x's `openmw/*.lua` annotations, classes, fields, overloads, context tags, hover documentation, or context-diagnostic behavior.

This skill treats stubs as editor/documentation contracts rather than runtime code. Matching OpenMW source is authoritative; the goal is to make Cod3x model the engine accurately, including uncertainty, rather than force the engine into a cleaner type shape than it guarantees.

This skill is primarily for Cod3x maintainers, but it is useful to downstream contributors who find a real stub bug while working on a mod.

### `lua-public-api-curator`

**Use when:** publishing or changing stable Lua `require` paths, exported tables/functions, runtime helpers, LuaLS docs, examples, changelogs, or semver-like compatibility promises.

It asks you to distinguish a plain module from a runtime helper with lifecycle/context/state dependencies, keep public paths small and intentional, document ownership and allocation behavior where callers can misuse them, and update examples/docs in the same change as the contract.

Use it for libraries and mod APIs that other code is expected to depend on, not every private module rename.

## Assets and releases

### `openmw-asset-pipeline-checker`

**Use when:** changing `.nif`, `.dds`, icons, sounds, atlases, generated assets, generator scripts, or VFS paths consumed by plugins/Lua/packages.

The skill maps **source → generator → output → VFS path → consumer**, checks casing and portability, searches references before renames, and refuses to treat a binary diff as proof of visual correctness. It also distinguishes generated output from the source of truth so an automated fix does not edit the wrong side of the pipeline.

### `openmw-mod-release-packager`

**Use when:** assembling release archives, changing manifests, `.omwscripts`, shipped plugins/assets, install instructions, release notes, or site/download metadata.

It checks that the staged file list, manifest, documentation, paths, casing, and release notes all describe the same artifact. It prefers dry-run/staging validation and explicitly does not grant permission to commit, tag, publish, or overwrite source assets just because packaging was requested.

## Choosing the smallest useful skill set

Do not load six skills merely because six could theoretically comment on a diff.

Start with the contract most likely to be violated:

| Problem | Start with |
| --- | --- |
| illegal or suspicious OpenMW import | `openmw-lua-context-guard` |
| works on new game, fails on old save | `openmw-lifecycle-debugger` |
| persisted shape/default/migration changed | `openmw-persistence-storage-auditor` |
| event/timer/redraw race | `openmw-runtime-ordering-auditor` |
| building a UI surface | `openmw-ui-layout-author` |
| UI is structurally correct but fails in-game | `openmw-ui-runtime-debugger` |
| settings/localization change | `openmw-ui-settings-l10n` |
| suspicious high-frequency path | `openmw-performance-hotpath-reviewer` |
| Cod3x annotation change | `cod3x-luals-stub-maintainer` |
| public Lua API change | `lua-public-api-curator` |
| asset generation/path change | `openmw-asset-pipeline-checker` |
| release archive/docs mismatch | `openmw-mod-release-packager` |

Add a second skill when the boundary genuinely crosses domains. Persistence plus lifecycle is common. UI plus context is common. Assets plus packaging is common. Loading everything all the time is not expertise; it is prompt sediment.
