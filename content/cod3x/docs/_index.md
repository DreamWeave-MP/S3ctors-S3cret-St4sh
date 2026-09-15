---
title: Cod3x
description: API mental models, engineering practice, performance work, failure archaeology, and tooling for OpenMW Lua.
template: docs/section.html
page_template: docs/page.html
sort_by: weight

extra:
  api_docs: true
  docs_root: true
  docs_project_name: Cod3x
  docs_short_title: Cod3x
  docs_project_path: '@/cod3x/index.md'
  docs_repository_url: https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/tree/main/content/cod3x
  docs_sidebar_label: Field Manual
  kind: guide
---

Cod3x is the OpenMW-Lua engineering field manual.

It is an API companion, handbook, cookbook, performance guide, historical record, and tooling reference. The goal is not merely to tell you which function exists. The goal is to make the engine legible enough that you can reason about what your script is doing, why it is doing it, where the cost lives, and which mistakes have already been paid for.

## Start here

Read [Why Cod3x Exists](@/cod3x/docs/mission.md), then choose [Zero to Hero](@/cod3x/docs/zero-to-hero/_index.md) if OpenMW Lua is new to you. After that, build the mental model in [Getting Started](@/cod3x/docs/getting-started/_index.md). If you already ship OpenMW Lua, [Good Designs](@/cod3x/docs/good-designs/_index.md), [Engineering Practice](@/cod3x/docs/practice/_index.md), and [Performance](@/cod3x/docs/performance/_index.md) are the useful parts immediately.

If something looks clever, inspect [Anti-Patterns](@/cod3x/docs/anti-patterns/_index.md). If a design looks simpler than the problem it solves, inspect [Good Designs](@/cod3x/docs/good-designs/_index.md). If a rule sounds suspiciously specific, there is a fair chance the explanation is in [Paid For With Blood](@/cod3x/docs/paid-for-with-blood/_index.md). If a machine is helping you work, read [So You Want To Code With AI?](@/cod3x/docs/tooling/so-you-want-to-code-with-ai.md) before giving it the keys.

## Follow the evidence graph

Cod3x pages are meant to give you three ways out of an idea: the doctrine, a reusable implementation, and the history that tested it.

| If you are thinking about... | Reusable H3 pattern | Production or historical trail |
| --- | --- | --- |
| explicit state transitions | [StateMachine](@/h3lp_yours3lf/docs/api/packages/state-machine.md) | [S3maphore state and lifecycle](@/s3maphore/docs/api/playlist-state.md) · [generation counters](@/cod3x/docs/paid-for-with-blood/generation-counters.md) |
| synchronous local observation | [Signal](@/h3lp_yours3lf/docs/api/packages/signal.md) | [Events and Interfaces](@/cod3x/docs/practice/events.md) · [pooling example](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md) |
| bounded temporary ownership | [Pool](@/h3lp_yours3lf/docs/api/packages/pool.md) | [Pooling and Signals](@/h3lp_yours3lf/docs/examples/pooling-and-signals.md) |
| caching and invalidation | [memoize](@/h3lp_yours3lf/docs/api/packages/memoize.md) | [Caching Without Creating New Bugs](@/cod3x/docs/performance/caching.md) · [resolver invalidation](@/cod3x/docs/paid-for-with-blood/resolver-invalidation.md) |
| path and VFS hygiene | [normalizePath](@/h3lp_yours3lf/docs/api/packages/normalize-path.md) | [VFS and Paths](@/cod3x/docs/getting-started/vfs-and-paths.md) |
| bounded update work | [Budget](@/h3lp_yours3lf/docs/api/packages/budget.md) and [Timing Helpers](@/h3lp_yours3lf/docs/api/timing.md) | [S3maphore documentation](@/s3maphore/docs/_index.md) · [Every Frame Is a Budget](@/cod3x/docs/anti-patterns/per-frame-everything.md) |
| settings plus transient state | [ProtectedTable](@/h3lp_yours3lf/docs/api/interfaces/protected-table.md) | [Storage and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md) |
| Morrowind UI composition | [H3UI](@/h3lp_yours3lf/docs/concepts/h3ui.md) and [UI Recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md) | [UI: From Nothing to Something](@/cod3x/docs/getting-started/ui.md) |
| investigation and proof | [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md) | [Source-Diving Workflow](@/cod3x/docs/tooling/source-diving.md) · [Historical Evidence Index](@/cod3x/docs/reference/history-index.md) |

Other useful pairings are [Result](@/h3lp_yours3lf/docs/api/packages/result.md) for explicit error values, [ScriptContext](@/h3lp_yours3lf/docs/api/packages/script-context.md) for narrow shared-module introspection, [randomGen](@/h3lp_yours3lf/docs/api/packages/random-gen.md) for allocation-conscious random calls, and [uiSnapshot](@/h3lp_yours3lf/docs/api/packages/ui-snapshot.md) for structural UI inspection. For settled-input work, see [Debounce](@/h3lp_yours3lf/docs/api/packages/debounce.md); for one-shot or rate-limited polling, see [Once](@/h3lp_yours3lf/docs/api/timing.md) and [Cooldown](@/h3lp_yours3lf/docs/api/timing.md).

The useful path is usually **principle → H3 pattern → production implementation → receipt**. Use the links at the point where the idea becomes actionable; the history is not decoration.

## What this manual is built from

Cod3x is not written from generic Lua advice. Its initial corpus is the complete available history of the St4sh, DreamScripts, Starwind Builder, and Rubic0n repositories, plus the current Cod3x annotations and OpenMW-facing production code in the St4sh.

That corpus contains thousands of fixes, experiments, reversions, performance passes, cache designs, event systems, sandbox boundaries, profiler work, and runtime changes. The history is useful precisely because the current code did not spring into existence fully formed.

See [Provenance and Research Corpus](@/cod3x/docs/provenance.md) for how evidence is classified and how historical code is used.

## Read by problem

- New to OpenMW Lua: [The OpenMW Lua Mental Model](@/cod3x/docs/getting-started/mental-model.md)
- Unsure where an API exists: [Script Contexts](@/cod3x/docs/getting-started/contexts.md)
- Confused by objects, records, and `types`: [Objects, Records, Types, and Cells](@/cod3x/docs/getting-started/objects-records-types.md)
- Choosing between events and interfaces: [Events and Interfaces](@/cod3x/docs/getting-started/events-and-interfaces.md)
- Writing stateful code: [Storage, Save State, and Lifecycle](@/cod3x/docs/getting-started/storage-and-lifecycle.md)
- Trying to put literally anything on screen: [UI: From Nothing to Something](@/cod3x/docs/getting-started/ui.md)
- Deciding whether advice is a fact or an opinion: [Contracts, Measurements, Derivations, and Preferences](@/cod3x/docs/practice/evidence.md)
- Thinking about `pcall`: [Error Handling](@/cod3x/docs/practice/error-handling.md)
- Chasing performance: [Measure First](@/cod3x/docs/performance/measure-first.md)
- Profiling in game: [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md)
- Reading LuaJIT output: [Bytecode](@/cod3x/docs/performance/luajit-bytecode.md) and [Traces](@/cod3x/docs/performance/luajit-traces.md)
- Trying to optimize the engine boundary: [Engine Boundaries](@/cod3x/docs/performance/engine-boundaries.md)
- Wondering why Rubic0n exists: [When Lua-Side Optimization Stops Being Enough](@/cod3x/docs/performance/rubic0n.md)
