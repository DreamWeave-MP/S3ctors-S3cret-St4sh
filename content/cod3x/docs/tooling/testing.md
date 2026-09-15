---
title: Testing OpenMW Lua
description: Separate pure logic tests, engine-contract checks, in-game integration tests, and performance harnesses.
weight: 40
extra:
  kind: guide
---

OpenMW Lua testing works best when different kinds of claims are tested at the layer that owns them.

Do not make one giant in-game manual test responsible for everything.

## Pure Lua logic

Functions that do not need the engine should be testable without the engine.

Good candidates include:

- parsers;
- rule evaluation;
- canonicalization;
- hash/index calculations;
- state-machine transitions expressed over plain data;
- selection algorithms;
- batching math.

The St4sh contains focused Lua tests for systems such as playlist rules, registration, reconciliation, presence collection, and UI/runtime helpers.

Pure tests are fast enough to run constantly.

## Engine-contract tests

Some behavior is specifically about OpenMW's scripting model:

- context availability;
- interface visibility;
- annotations;
- object/list semantics.

Cod3x itself has tests that load representative global/local/player/menu/union context cases through LuaLS.

Tooling that models the engine should be tested against representative context boundaries, not only syntax.

## In-game integration tests

Use OpenMW for claims that actually require OpenMW:

- engine lifecycle/order;
- object validity;
- UI behavior;
- raycasts;
- save/load;
- input;
- engine-bound performance.

A standalone Lua test cannot prove those semantics.

## Performance harnesses

A benchmark is not a correctness test.

Keep the two purposes distinct.

Rubic0n's `bench/openmw_userdata` harness isolates OpenMW-like Sol/vector userdata behavior without pretending to reproduce the complete engine frame/GC loop. That limitation is documented because a good harness states what it does *not* model.

## Regression tests should encode the wound

When a bug has a small reproducible shape, add a regression test near the fix.

Especially valuable targets include:

- nil/optional engine data;
- old/new transition generation ordering;
- cache invalidation;
- parser edge cases;
- context restrictions;
- save migration.

A Paid For With Blood lesson is even better when the repository can mechanically prevent reopening the wound.

## Test invariants, not implementation trivia

Prefer assertions like:

> stale generation results are rejected

rather than:

> helper function X was called exactly twice

unless the exact call count is the contract/performance property being tested.

Tests should permit safe refactoring while protecting the behavior that mattered.
