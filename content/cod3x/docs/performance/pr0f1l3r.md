---
title: Pr0f1l3r
description: In-engine timing, allocation attribution, throughput windows, and LuaJIT trace telemetry.
weight: 70
extra:
  kind: guide
---

Pr0f1l3r exists because OpenMW-Lua optimization needs measurements **inside OpenMW**, not only synthetic Lua microbenchmarks.

The current profiler can collect several different kinds of evidence. They are not interchangeable.

## Call counts

Call-count profiling answers “what is being invoked how often?”

This is useful for discovering architectural mistakes:

- a supposedly rare resolver running every frame;
- a callback registered twice;
- a helper called once per object when it could run once per batch;
- a UI rebuild happening far more often than expected.

Frequency often explains performance before duration does.

## Timing

Timing profiles help find where wall time accumulates.

Treat very small timings carefully: hook and clock overhead can become a significant fraction of the observed value.

For large engine-bound calls, timing is often enough to tell you where to investigate next.

## Allocation attribution

Pr0f1l3r has an allocation-attribution mode based on debug hooks and memory deltas.

The profiler explicitly marks that mode as useful for **allocation attribution**, not clean throughput measurement.

Use it to answer:

- which call sites correlate with allocation growth;
- whether a supposedly allocation-free path churns memory;
- whether a refactor moves allocation rather than removes it.

Then reproduce the suspicious path with a narrower benchmark if the mechanism matters.

## Throughput windows

A throughput window times a bounded workload without mixing in the heavier debug-hook modes.

Use this to compare representative end-to-end work when you can trigger the same behavior repeatedly.

Do not compare a throughput window against a debug-hook allocation run and call the difference an optimization.

## LuaJIT trace capture

Pr0f1l3r can attach trace telemetry, collect trace events, inspect trace info/IR/snapshots where available, aggregate aborts and side exits, and read runtime dump output.

This is intentionally noisy tooling. The implementation limits raw event/detail counts and aggregates overflow so the profiler does not produce an unbounded log storm while diagnosing one.

## Why Pr0f1l3r breaks the sandbox

The profiler accesses privileged LuaJIT/debug/IO facilities through the runtime's sandbox-bypass mechanism.

That is **tooling infrastructure**, not a mod architecture recommendation.

Ordinary mods should not copy the bypass because they want filesystem access, `debug`, or JIT internals.

The profiler's job is to observe the runtime. Observation requires capabilities intentionally denied to normal sandboxed scripts.

## Protected calls inside Pr0f1l3r

Pr0f1l3r contains many `pcall` operations.

That is not hypocrisy. It is a good example of the rule.

The profiler asks introspection APIs questions that may legitimately fail:

- a trace may no longer exist;
- a PC may not map to function info;
- a debug hook may be inaccessible/in an unexpected state;
- a runtime dumper may already be stopped;
- optional modules may not be present.

Failure is part of the observation contract.

The profiler also uses `xpcall` around a measured function so it can finish timing/cleanup and then preserve the failure.

The protected boundary exists because the profiler must not corrupt its own state when the code being measured throws.

## A recommended investigation loop

1. Reproduce the user-visible problem reliably.
2. Count calls before assuming each call is individually expensive.
3. Time the suspicious path.
4. Use allocation attribution if memory churn is implicated.
5. Capture JIT behavior only when Lua execution remains a meaningful part of the cost.
6. Reduce the suspicious mechanism into a standalone benchmark if possible.
7. Make one change.
8. Re-run the same representative workload.

## Structured logs are part of the tool

Pr0f1l3r emits structured fields because profiler output should be machine-filterable and comparable.

When adding new telemetry, preserve:

- stable field names;
- run/mode context;
- truncation indicators;
- explicit limitations;
- aggregation counts.

A profiler that produces ten megabytes of human-only text has created a second debugging problem.
