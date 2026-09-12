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
| Notify synchronous listeners | [Signal](@/h3lp_yours3lf/docs/api/modules/signal.md) |
| Reuse short-lived objects | [Pool](@/h3lp_yours3lf/docs/api/modules/pool.md) |
| Act after input stops changing | [Debounce](@/h3lp_yours3lf/docs/api/modules/debounce.md) |
| Periodic checks, rate limits, delays, elapsed time | [Timing Helpers](@/h3lp_yours3lf/docs/api/modules/timing.md) |
| Normalize VFS-style path spelling | [normalizePath](@/h3lp_yours3lf/docs/api/modules/normalize-path.md) |

## Coverage and remaining references

This manual is being expanded; it is not yet an exhaustive reference for all H3 exports. ProtectedTable, ScriptContext, and uiSnapshot still need dedicated source-checked contracts here, along with functional/caching helpers, state machines, math/random helpers, and UI/rendering utilities. Do not infer their signatures from neighboring modules.

Files under `fixtures/` are opt-in diagnostic scripts, not ordinary helper modules to enable as part of a dependency installation. Internal provider files such as `lfG.lua` are not substitutes for an installed interface. Check [State and Context](@/h3lp_yours3lf/docs/concepts/state-and-context.md) before moving any helper between script types.
