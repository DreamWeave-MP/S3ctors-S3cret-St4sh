---
title: Validation and Testing
description: Make correctness cheap to prove and regressions expensive to hide.
weight: 70
extra:
  kind: guide
---

OpenMW-Lua code should be validated at the cheapest layer that can prove the relevant contract.

## Static/tooling checks

Use LuaLS/Cod3x to catch:

- missing fields;
- wrong optionality;
- context violations;
- bad interface signatures;
- obvious type mismatches.

Static tooling cannot prove runtime ownership, event ordering, or engine data quality. Do not mistake green annotations for a complete test suite.

## Pure-Lua tests

Extract calculations and state transitions away from engine calls where practical. Pure logic is easier to fuzz, table-test, and benchmark.

Do not distort architecture solely to make everything unit-testable. Use extraction where there is a real pure contract.

## Fixture scripts

H3 ships opt-in fixture probes for global, player, menu, and custom/local lifecycle behavior. This is a useful pattern for infrastructure whose contract depends on real OpenMW scheduling and context availability.

For UI behavior, H3's [uiSnapshot](@/h3lp_yours3lf/docs/api/packages/ui-snapshot.md) and [UI recipes](@/h3lp_yours3lf/docs/examples/ui-recipes.md) provide a reusable inspection/composition layer, but they do not replace an in-game check of OpenMW layout ownership and update timing.

Test the engine boundary in the engine.

## Regression tests should name the wound

When a bug requires a non-obvious fix, encode the scenario if feasible.

A good regression test answers:

> What exact assumption are we preventing from returning?

This matters especially for:

- stale generations;
- save/load lifecycle;
- optional content;
- context availability;
- event ordering;
- cache invalidation.

## Performance tests need controls

A benchmark belongs beside correctness tests when the optimization itself is part of the contract.

Rubic0n is exemplary here: runtime changes come with focused harnesses, self-tests, workload groups, and explicit caveats.

## Fail tests loudly

Do not wrap test code in generic recovery that lets the suite continue with corrupted state and reports a dozen secondary failures.

The first violated invariant is usually the most valuable one.
