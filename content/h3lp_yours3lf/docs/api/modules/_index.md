---
title: Modules
page_template: docs/page.html
sort_by: weight
weight: 10

extra:
  kind: api
---

Browse by the problem you are solving. These categories describe public semantics, not the source directory layout.

## OpenMW helpers

- [S3lf](@/h3lp_yours3lf/docs/api/modules/s3lf.md): access the attached object through an installed interface.
- [ProtectedTable](@/h3lp_yours3lf/docs/api/modules/protected-table.md): bind settings and runtime state to a manager.
- [ScriptContext](@/h3lp_yours3lf/docs/api/modules/script-context.md): identify the current script context.
- [LogMessage](@/h3lp_yours3lf/docs/api/modules/log-message.md): print diagnostics from supported contexts.

## State and coordination

- [Signal](@/h3lp_yours3lf/docs/api/modules/signal.md): notify synchronous listeners.
- [StateMachine](@/h3lp_yours3lf/docs/api/modules/state-machine.md): represent named runtime states and transitions.
- [memoize](@/h3lp_yours3lf/docs/api/modules/memoize.md): retain results with optional expiry or entry limits.
- [Pool](@/h3lp_yours3lf/docs/api/modules/pool.md): reuse short-lived objects when measured allocation pressure warrants it.

## Timing and basic utilities

- [isOpenMW](@/h3lp_yours3lf/docs/api/modules/is-openmw.md): detect whether the OpenMW Lua runtime is available.
- [Timing Helpers](@/h3lp_yours3lf/docs/api/modules/timing.md): poll intervals, cooldowns, one-shot delays, and elapsed time.
- [Debounce](@/h3lp_yours3lf/docs/api/modules/debounce.md): wait for changes to settle.
- [Budget](@/h3lp_yours3lf/docs/api/modules/budget.md): spread work across frames.
- [lazy](@/h3lp_yours3lf/docs/api/modules/lazy.md): compute one value on demand.
- [Result](@/h3lp_yours3lf/docs/api/modules/result.md): represent success and failure explicitly.
- [normalizePath](@/h3lp_yours3lf/docs/api/modules/normalize-path.md): normalize VFS-style path spelling.

## UI and diagnostics

- [ImageAtlas](@/h3lp_yours3lf/docs/api/modules/image-atlas.md): cycle tile-based image frames in a player UI.
- [uiSnapshot](@/h3lp_yours3lf/docs/api/modules/ui-snapshot.md): capture bounded, deterministic layout evidence.
