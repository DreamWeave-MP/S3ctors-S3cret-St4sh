---
title: Physics and Rendering Raycasts Answer Different Questions
description: Starwind cursor selection produced false positives because a physics query was being used for a visual-selection problem.
weight: 82
extra:
  kind: guide
---

## Paid For With Blood

Starwind's cursor selection originally tried both a physics raycast and a rendering raycast when asking what the user was pointing at.

That sounds robust: ask both systems and accept the first useful hit.

It was wrong.

Commit [`ae7561d`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/ae7561d0b5aa16170059193c21054913cadb6f62) removed the physics raycast from cursor selection because collision geometry could produce hits that did not correspond to the visual object the cursor was actually over.

The same fix also corrected activation range to measure from the player rather than the camera-offset ray origin.

## What went wrong

Two APIs that both return "ray hits" were treated as interchangeable implementations of one conceptual operation.

They are not.

A physics/collision ray asks about collision geometry.

A rendering ray asks about visual scene intersection.

Cursor picking is fundamentally a rendering-space question.

## The rule

**Choose the engine query whose semantics match the user-visible question.**

Do not combine similar-looking engine APIs merely because more data feels safer.

Before adding a fallback query, ask:

- Does it observe the same world representation?
- Does it include/exclude the same classes of object?
- Is the coordinate origin equivalent?
- Is it legal in the same script callbacks?
- If both return answers, which one is authoritative?

Extra engine work can make an answer slower *and* less correct.

Source: Starwind Builder [commit `ae7561d`](https://github.com/DreamWeave-MP/Starwind-Builder/commit/ae7561d0b5aa16170059193c21054913cadb6f62).

Implementation at that revision: [cursorController.lua](https://github.com/DreamWeave-MP/Starwind-Builder/blob/ae7561d0b5aa16170059193c21054913cadb6f62/src/Community%20Patch%20Project/Scripts/SW4/player/cursorController.lua).

### From the St4sh

The [T4rg3t5 documentation](@/t4rg3t5/docs/_index.md) describes the current targeting contract. Read the [target manager source](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/t4rg3t5/scripts/s3/target/lockOnManager.lua) when you need to see how semantic target selection is kept separate from camera and marker presentation.

See [Engine Boundaries](@/cod3x/docs/performance/engine-boundaries.md) and [Every Frame Is a Budget, Not an Invitation](@/cod3x/docs/anti-patterns/per-frame-everything.md).
