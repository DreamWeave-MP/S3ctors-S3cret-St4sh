---
title: 'Design Study: The Actor Scheduler'
description: How S3maphore made combat polling a bounded contract with the frame.
weight: 90
extra:
  kind: guide
---

## The problem

S3maphore needs to know which nearby actors are fighting the player. OpenMW exposes nearby actors, but checking every actor on every update makes the cost grow with the world around the player.

The answer also does not need to be exact every fraction of a frame. Combat state can tolerate a bounded amount of sampling latency if the work remains predictable.

## The first reduction

Do not ask “how do I scan every actor immediately?” Ask:

> How much actor work can this frame afford, and when will every actor be revisited?

Commit [`57eb4b69`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/57eb4b69c0d5568bf82d4b476632cd2ada055a48) moved combat scanning to a bounded queue. The scheduler walks a slice of nearby actors and asks each one to report its combat targets instead of doing every actor's work in one update.

The current [`combatState.lua`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/combatState.lua) makes the contract concrete: maintain a cursor, calculate a bounded batch, send local checks, and wrap back to the beginning.

## Performance is an experiment, not a vibe

The history then tried several answers to batch sizing:

1. [`8cad4c1f`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/8cad4c1fc3590a21afd3b91cfee0b15bf080ed26) tried shrinking the batch dynamically from frame time;
2. [`17cfca78`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/17cfca786c6579d68246ccd21e5beab393ec3362) reverted that direction because a fixed bound was preferable;
3. [`c967a3d2`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/c967a3d20c5fa51b801dab53369e579f9fd08994) landed on a capped 4–16 scheduler targeting roughly one full actor pass every third of a second.

That sequence is the lesson. “Dynamic” is not synonymous with “better.” A scheduler is a contract with the frame: bounded work now, bounded freshness later. The useful numbers are part of that contract and should be measured against the actual workload.

## Why the boundary works

The actor scheduler does not pretend to solve all combat state in one place. It separates:

- scheduling when an actor is checked;
- local actor reporting through `S3maphoreCheckCombat`;
- player-side aggregation of combat targets;
- playlist resolution when the aggregate state changes.

That lets the hot path remain bounded while the playlist callback stays a simple eligibility query. [H3 Budget](@/h3lp_yours3lf/docs/api/packages/budget.md) provides a reusable budget primitive, but the scheduler's actual latency and batch contract still belong to S3maphore.

## What to steal

When a scan is too large for one frame, define both sides of the compromise: the maximum work per update and the acceptable revisit delay.

Then keep the scheduler responsible for work distribution, not for every semantic decision the scanned actors produce. Read [Measure First](@/cod3x/docs/performance/measure-first.md) before changing the batch formula.

## When not to use this

Do not batch a small collection merely because batching sounds sophisticated. If the full scan is cheap, a direct loop is clearer. Do not use a bounded sampler when correctness requires an immediate answer; make the latency part of the design before choosing this shape.
