---
name: lua-public-api-curator
description: "Public Lua modules, stable require paths, exported tables/functions, LuaLS docs, examples, semver-like compatibility, and runtime-vs-plain module contracts."
---

# Lua Public API Curator

Use this skill when changing or reviewing a Lua library or mod's public modules, exported helpers, documented `require` paths, examples, or release notes.

## Goals

- Stabilize public import paths and exported shapes before implementation details.
- Keep public APIs small and semver-like: prefer additive changes and call out deliberate breaks.
- Do not expose joke, experimental, temporary, generated, or implementation-detail names as public contracts.
- Distinguish plain modules from runtime helpers. Runtime helpers may depend on OpenMW lifecycle, mutable engine objects, timers, events, contexts, or persistent state; plain modules should avoid hidden runtime registration or side effects.

## Documentation Standards

Document public behavior that callers can otherwise misuse:

- Parameters, returns, callback signatures, fields, nil/error behavior.
- Allocation behavior when meaningful: new tables, closures, coroutines, pooled/reused objects, caches.
- Ownership/lifetime: who owns returned values, when handles remain valid, required cleanup/release.
- Mutation: whether inputs are modified, outputs are reused, or returned tables are read-only/shared.
- Scheduling/runtime behavior: callback timing, repetition, cancellation, reload/save implications.
- Context restrictions for OpenMW APIs or interfaces.

Use project-local naming in examples, but never leak private/internal paths merely because implementation files are nearby.

## Review Checklist

- Public examples import only documented public paths and match current exports.
- Internal implementation files are not referenced by docs or copy-paste examples unless intentionally public.
- Runtime helpers clearly state lifecycle/context/state dependencies.
- Plain modules remain importable without hidden registration or engine-state side effects.
- LuaLS docs are sufficient for useful editor completion without pretending to stronger types than runtime guarantees.
- API additions are minimal, consistently named, and compatible unless a break is deliberate.
- Docs indexes, examples, changelogs, and release notes are updated in the same change when user-visible contracts move.

## Validation

Run the repository's Lua syntax/type/docs checks when available. For public API changes, search the repository for old import paths and names before declaring the change complete.
