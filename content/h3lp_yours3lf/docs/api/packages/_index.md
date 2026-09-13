---
title: Packages
description: Individual modules loaded directly with require.
template: docs/section.html
page_template: docs/page.html
sort_by: title
weight: 10

extra:
  kind: api
  sidebar_groups:
    - title: Core Lua and coordination
      pages: [class, lazy, memoize, pool, result, signal, state-machine]
    - title: Timing and work
      pages: [budget, debounce, oscillator]
    - title: Data and utility
      pages: [normalize-path, random-gen, szudzik, table-hash]
    - title: OpenMW context and gameplay
      pages: [is-hostile, is-openmw, log-message, script-context, spell-util]
    - title: UI and interaction
      pages: [drag-events, ui-snapshot]
---

These packages return a module value when required. Some use OpenMW clocks or context APIs after loading, but they are still consumed as ordinary module dependencies.

## Choose by job

| Need | Packages |
| --- | --- |
| Model state or coordinate plain-Lua work | [class](@/h3lp_yours3lf/docs/api/packages/class.md), [lazy](@/h3lp_yours3lf/docs/api/packages/lazy.md), [memoize](@/h3lp_yours3lf/docs/api/packages/memoize.md), [pool](@/h3lp_yours3lf/docs/api/packages/pool.md), [result](@/h3lp_yours3lf/docs/api/packages/result.md), [signal](@/h3lp_yours3lf/docs/api/packages/signal.md), [StateMachine](@/h3lp_yours3lf/docs/api/packages/state-machine.md) |
| Poll time or spread work across updates | [Budget](@/h3lp_yours3lf/docs/api/packages/budget.md), [Debounce](@/h3lp_yours3lf/docs/api/packages/debounce.md), [oscillator](@/h3lp_yours3lf/docs/api/packages/oscillator.md), [Timing Helpers](@/h3lp_yours3lf/docs/api/timing.md) |
| Normalize, hash, pair, or randomize data | [normalizePath](@/h3lp_yours3lf/docs/api/packages/normalize-path.md), [randomGen](@/h3lp_yours3lf/docs/api/packages/random-gen.md), [szudzik](@/h3lp_yours3lf/docs/api/packages/szudzik.md), [tableHash](@/h3lp_yours3lf/docs/api/packages/table-hash.md) |
| Inspect context, log, or evaluate gameplay state | [isHostile](@/h3lp_yours3lf/docs/api/packages/is-hostile.md), [isOpenMW](@/h3lp_yours3lf/docs/api/packages/is-openmw.md), [LogMessage](@/h3lp_yours3lf/docs/api/packages/log-message.md), [ScriptContext](@/h3lp_yours3lf/docs/api/packages/script-context.md), [spellUtil](@/h3lp_yours3lf/docs/api/packages/spell-util.md) |
| Build or inspect UI interaction | [DragEvents](@/h3lp_yours3lf/docs/api/packages/drag-events.md), [uiSnapshot](@/h3lp_yours3lf/docs/api/packages/ui-snapshot.md), [UI Components](@/h3lp_yours3lf/docs/api/components/_index.md) |

Constructor-style modules use capitalized exports such as `Signal`, `Pool`, and `StateMachine`; function and value modules generally use camelCase exports such as `memoize`, `randomGen`, and `normalizePath`. The public `scripts.s3` module paths remain the stable entry points.
