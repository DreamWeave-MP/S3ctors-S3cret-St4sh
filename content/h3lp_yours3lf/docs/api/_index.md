---
title: API Reference
page_template: docs/page.html
sort_by: weight
weight: 30

extra:
  kind: api
---

Choose an entry by the problem it solves. References describe the repository's current implementation, including ownership and failure behavior; the existence of a source file is not by itself a stability promise for its internals.

| Task | Reference |
| --- | --- |
| Access the attached object's fields and stats | [S3lf](@/h3lp_yours3lf/docs/api/modules/s3lf.md) |
| Bind settings and runtime state to a protected manager | [ProtectedTable](@/h3lp_yours3lf/docs/api/modules/protected-table.md) |
| Notify synchronous listeners | [Signal](@/h3lp_yours3lf/docs/api/modules/signal.md) |
| Represent named runtime states | [StateMachine](@/h3lp_yours3lf/docs/api/modules/state-machine.md) |
| Cache expensive calls | [memoize](@/h3lp_yours3lf/docs/api/modules/memoize.md) |
| Represent success or failure explicitly | [Result](@/h3lp_yours3lf/docs/api/modules/result.md) |
| Compute one value lazily | [lazy](@/h3lp_yours3lf/docs/api/modules/lazy.md) |
| Reuse short-lived objects | [Pool](@/h3lp_yours3lf/docs/api/modules/pool.md) |
| Act after input stops changing | [Debounce](@/h3lp_yours3lf/docs/api/modules/debounce.md) |
| Periodic checks, rate limits, delays, elapsed time | [Timing Helpers](@/h3lp_yours3lf/docs/api/modules/timing.md) |
| Spread work across frames | [Budget](@/h3lp_yours3lf/docs/api/modules/budget.md) |
| Normalize VFS-style path spelling | [normalizePath](@/h3lp_yours3lf/docs/api/modules/normalize-path.md) |
| Identify the current script context | [ScriptContext](@/h3lp_yours3lf/docs/api/modules/script-context.md) |
| Print diagnostics from supported contexts | [LogMessage](@/h3lp_yours3lf/docs/api/modules/log-message.md) |
| Detect the OpenMW Lua runtime | [isOpenMW](@/h3lp_yours3lf/docs/api/modules/is-openmw.md) |
| Capture a deterministic UI layout snapshot | [uiSnapshot](@/h3lp_yours3lf/docs/api/modules/ui-snapshot.md) |
| Display and cycle atlas texture frames | [ImageAtlas](@/h3lp_yours3lf/docs/api/modules/image-atlas.md) |

## Coverage and remaining references

This manual is being expanded; it is not yet an exhaustive reference for all H3 exports. Functional helpers, math/random helpers, and UI/rendering utilities still need dedicated source-checked contracts. Do not infer their signatures from neighboring modules.

Files under `fixtures/` are opt-in diagnostic scripts, not ordinary helper modules to enable as part of a dependency installation. Internal provider files such as `lfG.lua` are not substitutes for an installed interface. Check [State and Context](@/h3lp_yours3lf/docs/concepts/state-and-context.md) before moving any helper between script types.
