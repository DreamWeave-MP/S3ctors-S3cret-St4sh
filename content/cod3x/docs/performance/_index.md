---
title: Performance
description: Profiling, hot paths, caches, engine boundaries, LuaJIT analysis, and benchmark design.
weight: 30
template: docs/section.html
page_template: docs/page.html
sort_by: weight
extra:
  kind: guide
---

“OpenMW Lua is slow” is not a diagnosis.

A useful performance investigation asks **where the time or memory goes**.

The cost may be:

- Lua execution;
- allocation;
- table/string churn;
- a repeated global/property lookup;
- an engine query;
- userdata construction/finalization;
- serialization;
- event dispatch;
- ray casting or physics;
- a C++ binding;
- a LuaJIT trace abort or side exit;
- GC behavior;
- work that never belonged on every frame in the first place.

Start with [Measure First](@/cod3x/docs/performance/measure-first.md). Use [Pr0f1l3r](@/cod3x/docs/performance/pr0f1l3r.md) for in-engine telemetry. [Events, Serialization, and Boundary Traffic](@/cod3x/docs/performance/event-and-serialization-costs.md) covers message-heavy systems. Move into [Bytecode](@/cod3x/docs/performance/luajit-bytecode.md), [Traces](@/cod3x/docs/performance/luajit-traces.md), and [Engine Boundaries](@/cod3x/docs/performance/engine-boundaries.md) only when the evidence points there.

Do not start with the cleverest optimization you know.
