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
| Generate an independent random stream | [randomGen](@/h3lp_yours3lf/docs/api/modules/random-gen.md) |
| Produce a clock-based 0..1 waveform | [oscillator](@/h3lp_yours3lf/docs/api/modules/oscillator.md) |
| Pair integer coordinates | [szudzik](@/h3lp_yours3lf/docs/api/modules/szudzik.md) |
| Hash a table's contents | [tableHash](@/h3lp_yours3lf/docs/api/modules/table-hash.md) |
| Define small inherited Lua classes | [class](@/h3lp_yours3lf/docs/api/modules/class.md) |
| Project objects into the player's viewport | [CamHelper](@/h3lp_yours3lf/docs/api/modules/cam-helper.md) |
| Calculate spell, enchantment, and potion values | [spellUtil](@/h3lp_yours3lf/docs/api/modules/spell-util.md) |
| Test whether an actor meets the aggression threshold | [isHostile](@/h3lp_yours3lf/docs/api/modules/is-hostile.md) |
| Clear tables or provide no-op callbacks | [Small Utilities](@/h3lp_yours3lf/docs/api/modules/small-utilities.md) |

## Coverage and remaining references

This manual is being expanded; it is not yet an exhaustive reference for all H3 exports. UI components, rendering support, and a few implementation-only helpers still need classification or dedicated source-checked contracts. Do not infer their signatures from neighboring modules.

Files under `fixtures/` are opt-in diagnostic scripts, not ordinary helper modules to enable as part of a dependency installation. Internal provider files such as `lfG.lua` are not substitutes for an installed interface. Check [State and Context](@/h3lp_yours3lf/docs/concepts/state-and-context.md) before moving any helper between script types.
