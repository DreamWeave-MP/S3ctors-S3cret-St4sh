---
title: Every Frame Is a Budget, Not an Invitation
description: Poll only what must be fresh, batch what can be late, and move observations to their natural owner.
weight: 20
extra:
  kind: guide
---

`onFrame` is easy to reach and therefore easy to abuse.

A feature that runs once per frame at 144 FPS runs 144 times per second whether the relevant state changed or not.

Multiply that by nearby actors, ray casts, bounding boxes, string normalization, UI rebuilds, or storage queries and the architecture becomes the performance bug.

## Historical shape

Early Starwind systems centralized many managers under a player controller and repeatedly performed camera/lock-on work from the frame loop. That design was understandable: one controller gives obvious ordering and one place to update everything.

The later St4sh lock-on work moved toward fewer raycasts, fewer runtime operations, explicit lock-loss rules, hysteresis, and more carefully bounded geometry checks.

The lesson is not “never use `onFrame`.” Camera smoothing genuinely is frame-driven.

The lesson is to classify work.

## Four useful cadences

**Event-driven** — run when the engine tells you the relevant state changed.

**Demand-driven** — compute only when a consumer asks.

**Batched/polled** — state can tolerate bounded latency, so distribute work across frames.

**Per-frame** — the result genuinely needs frame-rate freshness.

Do not promote everything into the fourth category.

## A ray cast is not a boolean lookup

Camera and targeting code repeatedly teaches this lesson.

If a frame loop raycasts to every candidate, then optimizes a table lookup beside it, the wrong layer is being optimized.

Reduce candidate count, reuse stable geometry, lower cadence where acceptable, or perform the observation from the actor/object that naturally owns it.

## Batch with a latency target

Modern S3maphore combat polling computes a bounded batch size based on nearby actor count and a target update latency.

That makes the tradeoff explicit:

{{ schematic(data_path="data/schematics/bounded-batch.json") }}

An arbitrary “check five actors per frame” constant can work too, but documenting the intended latency makes tuning more defensible.

## UI is subject to the same rule

Do not rebuild or globally update UI every frame because layout state is easy to regenerate.

Update on state changes. Narrow the invalidation to the element you own.
