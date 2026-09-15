---
title: 'Design Study: CamHelper'
description: How application code earned extraction into a reusable OpenMW camera interface.
weight: 50
extra:
  kind: guide
---

## The problem

A target marker needs to answer a deceptively ordinary question: where is this world object on the player's screen, and should it be shown at all?

That means dealing with camera position and yaw, viewport projection, screen bounds, view distance, NPC height, bounding boxes, and the distinction between “visible to the camera” and “not occluded by geometry.”

## The first implementation

CamHelper did not begin as a guessed universal camera library. It lived inside T4rg3t5 as application code for lock-on and target presentation.

That is the right place to discover the contract. A real consumer reveals which questions recur and which details are accidental. Commit [`3b1f8a75`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/3b1f8a75cb84edb65588aaa8b024a5571b4de756) then migrated the camera helper into H3 and removed the T4-specific copy.

The result is an installed interface with a small vocabulary: `isPositionBehindCamera`, `targetPosition`, and `objectIsOnscreen`. The [H3 CamHelper reference](@/h3lp_yours3lf/docs/api/interfaces/cam-helper.md) documents the boundary; the [T4rg3t5 interface](@/t4rg3t5/docs/api/interface.md) shows the production consumer.

## The reduction

The reusable question is not “give every mod a camera framework.” It is:

> Given this object, where should its marker go, or should it be absent?

That contract hides the repeated camera interpretation while keeping important semantics visible. `objectIsOnscreen` returns a normalized viewport position or `nil`; it does not pretend to perform occlusion testing. NPC height adjustment can use a previously captured offset when animation-driven bounds would cause jitter.

The provider is [`camHelper.lua`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/h3lp_yours3lf/scripts/s3/camHelper.lua). It is player-scoped because the camera and viewport are player concerns.

## Extraction is not the end

Once the common boundary existed, real use continued to improve it:

- [`8d8f2025`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8d8f20252f7b9a535c64c98e37299334a3e25bae) rewrote the helper around its actual hot path;
- [`334d7493`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/334d749313dba2a15ff74a93fcac81cc1bbb0907) corrected a semantic inconsistency in onscreen checks;
- [`70c895cc`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/70c895ccd7cf99399709635d90cc157a79c78928) removed an unnecessary allocation;
- [`02a00845`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/02a00845e213467106756a9f641a67eb1698c559) stopped repeatedly querying NPC bounding boxes by stabilizing the target offset.

That sequence matters. Application-specific implementation became a reusable interface, then measured hot-path work exposed both performance costs and semantic assumptions worth correcting.

## What to steal

Do not start by guessing what will be reusable. Build one useful thing. Reuse it. Extract the part that proved stable.

Then keep optimizing behind the semantic boundary. A consumer should not have to know whether the answer came from a camera binding, a bounding-box query, a cached offset, or a Rubic0n-assisted math operation.

Read [Engine Boundaries](@/cod3x/docs/performance/engine-boundaries.md) before optimizing a wrapper, and [Measure First](@/cod3x/docs/performance/measure-first.md) before declaring the wrapper expensive.

## When not to use this

If one caller performs a small, one-off projection and does not share the camera semantics with anything else, it may not have an extraction boundary yet. Do not build a camera interface merely to avoid four lines of direct OpenMW code.
