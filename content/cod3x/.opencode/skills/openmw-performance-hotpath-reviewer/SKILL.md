---
name: openmw-performance-hotpath-reviewer
description: "OpenMW Lua hot paths: onUpdate, render/update callbacks, event dispatch, metatable lookups, allocations, native API boundaries, storage reads, and LuaJIT/Luau-aware measurement."
---

# OpenMW Performance Hotpath Reviewer

Use this skill for code that runs per frame, per actor/object, in render/update callbacks, event fanout, metatable dispatch, large collection scans, or other high-frequency paths.

## Review Focus

- Establish call frequency and fanout before optimizing. A small cost multiplied by every frame/object can dominate; a scary-looking cold path may not matter.
- Watch table/closure/string allocation, temporary collections, concatenation, vararg churn, repeated scans, callback creation, and repeated path/key construction.
- Treat repeated OpenMW native-boundary/module/interface access as a measurement target rather than assuming ordinary Lua-table cost. Hoist stable references in proven hot paths when it reduces native lookups or improves generated code without harming correctness.
- Do not cargo-cult localization/hoisting for normal Lua tables or helpers; measure or justify by call frequency.
- Storage/settings/save-data reads in metatable or per-frame paths deserve suspicion. Prefer cached/derived runtime state only when invalidation is explicit and correct.
- Broad UI rebuilds and `ui.updateAll()` are high-value targets because layout work can be expensive.
- Require evidence before claiming a regression or improvement.

## Runtime Choice Matters

The optimization model differs between LuaJIT and Luau. Use the runtime actually shipped by the target OpenMW branch/build. Bytecode/JIT observations from one runtime do not automatically transfer to another.

## Evidence

Prefer, in descending usefulness:

- OpenMW/runtime profiler measurements and representative benchmarks.
- Allocation counters and call-frequency estimates.
- Targeted before/after traces.
- Runtime-appropriate bytecode/IR inspection.
- Static reasoning only when measurement is impractical, clearly labeled as a hypothesis.

Bytecode size or fewer globals alone is not proof of faster runtime behavior.

## Review Standard

- Remove work from the hot path before adding clever caches.
- Hoist stable constants/functions when the benefit is clear and ownership/context remain correct.
- Do not introduce invalidation complexity larger than the cost being avoided.
- Preserve determinism and context safety.
- State the suspected cost, why the path is hot, evidence, minimal fix, and validation needed.
