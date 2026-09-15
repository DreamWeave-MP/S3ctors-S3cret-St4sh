---
title: LuaJIT Traces, Aborts, and Side Exits
description: Understand what got compiled, where it bailed out, and whether that matters to the workload.
weight: 60
extra:
  kind: guide
---

LuaJIT performance is not binary “JIT on / JIT off.”

Hot execution forms traces. Those traces contain guards. Compilation can abort. Runtime can leave a trace through side exits. C/engine calls can limit what the recorder can see or optimize.

A useful investigation asks **what happened to this path?**

## Trace vocabulary

**Trace** — a compiled hot execution path.

**Root trace** — the initial trace for a hot loop/path.

**Side trace** — a trace compiled from a frequently taken exit from another trace.

**Guard** — a runtime assumption compiled into the trace. If it fails, execution exits.

**Trace abort** — the recorder could not compile the attempted path.

**Side exit** — execution left compiled trace code at a guard/snapshot.

An exit is not automatically bad. Branches exist. The question is frequency and cost.

## Capture in the real workload

Pr0f1l3r can attach LuaJIT trace callbacks and capture trace/IR/snapshot information from inside OpenMW's runtime.

That matters because a standalone script may trace differently once it interacts with:

- OpenMW userdata;
- binding calls;
- engine callbacks;
- sandbox restrictions;
- real data shape;
- the actual event/frame lifecycle.

Use outside-game reproductions to isolate mechanisms and in-game capture to establish relevance.

## Trace aborts are clues

An abort tells you why the recorder stopped.

Do not respond by blindly rewriting until the abort disappears.

Ask:

- Is this path hot enough to care?
- Does the abort happen once during warmup or continuously?
- Is the operation inherently unsupported/NYI?
- Does the loop spend most of its time in engine calls anyway?
- Would restructuring improve architecture even if the JIT did not exist?

A trace-perfect version of bad architecture is still bad architecture.

## Side exits need frequency

One rare guard failure is noise.

A side exit taken thousands of times in the steady-state workload may indicate unstable types/data shape or a branch that deserves a side trace/architectural change.

Pr0f1l3r aggregates side-exit information because raw dump volume can become overwhelming.

The profiler itself caps/aggregates trace telemetry to avoid turning observability into the performance problem.

## Stable data shapes help more than incantations

LuaJIT likes predictable hot code.

Useful practices often already align with good architecture:

- normalize data at ingress;
- avoid changing a hot field among unrelated types;
- keep dense sequences dense;
- avoid repeatedly constructing different-shaped tables on the same path;
- separate slow exceptional handling from the common path.

Do not distort public APIs solely to appease the JIT without measurement.

## C calls are not necessarily trace death, but they are boundaries

LuaJIT can record around many C calls depending on the function and runtime integration. It cannot see arbitrary engine internals as Lua IR.

The right question is not “does this C call break the trace?” in isolation.

The right question is:

**How much does this boundary cost, what result does it allocate/return, and how often do I cross it?**

## Flushes change the experiment

Pr0f1l3r performs best-effort trace flushing for some capture workflows so the run can observe trace formation rather than only preexisting compiled state.

That means a capture run may not represent steady-state throughput.

Use the profiler's measurement notes. Do not compare incompatible modes as if they answer the same question.

## Read IR only after you know why

IR dumps are powerful and easy to fetishize.

Inspect IR when you have a concrete hypothesis about:

- allocation sinking;
- guard generation;
- value specialization;
- load/store elimination;
- call behavior;
- snapshot/side-exit state.

If the user-visible problem is a 3 ms physics query, an hour staring at `SLOAD` and `HREFK` is performance cosplay.
