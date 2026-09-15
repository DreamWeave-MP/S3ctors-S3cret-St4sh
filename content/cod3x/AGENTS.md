# Cod3x Agent Contract

Cod3x is the OpenMW-Lua engineering field manual and LuaLS model. Treat documentation and annotations as engineering artifacts, not marketing copy.

## Hard rules

- Validate OpenMW API claims against the current Cod3x annotations and, when behavior matters, OpenMW source.
- Every OpenMW-facing Lua source file needs the narrowest correct `---@omw-context` contract.
- Never invent OpenMW APIs, fields, contexts, or object semantics because they sound plausible.
- Preserve the distinction between runtime objects, records, object IDs, and record IDs.
- Prefer explicit ownership, state transitions, and cache lifetimes over hidden magic.
- Required dependencies and broken invariants fail loudly. Do not silently downgrade them into optional behavior.
- **DO NOT USE PCALL OR YOU WILL BE UNPLUGGED.**
- A new `pcall`/`xpcall` requires a concrete documented recovery, cleanup/rethrow, host/plugin isolation, or introspection/probing requirement. “Defensive” is not a requirement.
- Do not introduce abstraction without repeated evidence that the contract is useful.
- Do not make performance claims without identifying the mechanism and measurement.
- Do not optimize engine-bound code as though it were pure Lua. Count the engine calls.
- Do not cache without defining key identity, semantic lifetime, invalidation, and cached-absence behavior.
- Do not persist transient caches or live runtime handles without an explicit persistence contract.
- Do not use global events as a generic same-context message bus.
- Do not put expensive work on `onFrame` merely because it is convenient.

## Style

- Use full-word variable names by default.
- Use semantic whitespace around control-flow and logical phases.
- Prefer guard clauses when they keep the main path visible.
- Avoid narration comments. Comments are for engine constraints, public contracts, benchmark caveats, and history that cannot be made obvious structurally.
- Keep examples minimal enough to teach one thing and complete enough to be correct.

## Research before changing weird code

Before simplifying an unusual implementation:

1. inspect current annotations/source;
2. search production call sites;
3. read file history and relevant `FIX:`, `PERF:`, `CHECK:`, and `REVERT:` commits;
4. determine whether the weirdness is obsolete or Paid For With Blood;
5. reproduce/benchmark if the reason remains uncertain.

## Documentation graph

Cod3x documentation is an index into the wider DreamWeave engineering corpus, not an isolated book.

- Every substantial page must look for a relevant reusable H3 pattern and link it inline when one exists.
- When a DreamWeave project has a useful production implementation, link its specific documentation page and source file rather than only its repository root.
- Every historical commit mentioned in public DreamWeave repositories must link to the full SHA on GitHub when the commit is available.
- For an important historical implementation, prefer a provenance chain: principle, reusable pattern, production source, commit-pinned source, and the current implementation.
- Use `H3 Pattern` for reusable H3 APIs, `From the St4sh` for production examples, and `Paid For With Blood` for historical failures and their surviving rules.
- Do not add a vague repository link when a page, file, commit, compare range, or line-level source is available.

## Evidence language

Classify significant guidance as one of:

- Contract — required by engine/API/runtime/data model;
- Measured — supported by representative evidence;
- Derived — follows from known implementation behavior;
- Preference — engineering/style choice.

Do not promote Preference to Contract or a microbenchmark to universal law.

## Documentation voice

Be technically exact. Be direct. Humor is allowed when it does not obscure the contract. PCallManager is to be referenced with completely straight-faced technical language. Do not explain the joke.

## Relevant manual pages

- `docs/mission.md`
- `docs/practice/evidence.md`
- `docs/practice/error-handling.md`
- `docs/practice/state.md`
- `docs/performance/_index.md`
- `docs/performance/benchmarking.md`
- `docs/paid-for-with-blood/_index.md`
- `docs/tooling/so-you-want-to-code-with-ai.md`
