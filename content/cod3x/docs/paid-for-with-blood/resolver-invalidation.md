---
title: Paid For With Blood — Invalidate the Resolver Too
description: Clearing source data did not make S3maphore's derived playlist state dirty.
weight: 10
extra:
  kind: guide
---

## The wound

A S3maphore quest update could require **two** journal updates before the active playlist changed.

The event handler cleared the journal cache and called playlist resolution, which sounded correct.

It was not enough.

## What was wrong

The playlist system was staged through a state machine with its own resolver dirtiness and update flow.

Clearing the source cache did not correctly integrate the change with the state machine's derived-state lifecycle. The immediate resolve did not make every downstream path observe the new state at the correct point.

## The fix

Commit [`bfe28c01`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bfe28c012a7c42a8e0349a9b06b5c0962e796c70) introduced explicit `journalDirty` state. `onQuestUpdate` marks the journal dirty and transitions the state machine. The update state consumes the dirty flag and resolves in the expected stage.

## The rule

**Invalidating source data is not the same thing as invalidating every derived value that depends on it.**

Draw the dependency chain.

If `A -> B -> C`, mutating A must make it impossible for stale B or C to masquerade as current truth.

Do not rely on “we called the resolver once” when the architecture has a staged lifecycle.

Source: S3ctors S3cret St4sh [commit `bfe28c01`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bfe28c012a7c42a8e0349a9b06b5c0962e796c70).
