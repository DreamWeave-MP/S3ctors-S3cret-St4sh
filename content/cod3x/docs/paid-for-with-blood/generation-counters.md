---
title: Paid For With Blood — Generations for Deferred Work
description: CellPresence work was valid when sent and stale when it returned.
weight: 20
extra:
  kind: guide
---

## The wound

S3maphore's CellPresence/update pipeline crossed script contexts and cell transitions. Deferred work could complete after a newer transition had already made the result irrelevant.

A cell ID check alone was not a sufficiently strong identity for every in-flight operation.

## What changed

Commit [`b148ee31`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/b148ee31cb8fd023436e8b00d984d1098299b0a2) added:

- a presence generation;
- a playback epoch;
- generation data on presence messages;
- epoch/cell data on track-change messages;
- rejection of results that no longer matched the current generation.

The important operation is not incrementing an integer. It is attaching **authority** to the work.

## The rule

**Delayed work must be able to prove that it still belongs to the state that requested it.**

Use generations/epochs/tokens when:

- a newer request supersedes an older one;
- cell transitions can invalidate replies;
- playback/UI state can change while work is queued;
- events or callbacks cross enough time that current state may differ.

Do not solve stale work only by checking one coincidental field. Give the request an identity.

Source: S3ctors S3cret St4sh [commit `b148ee31`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/b148ee31cb8fd023436e8b00d984d1098299b0a2).

Implementation at that revision: [playlistState.lua](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/b148ee31cb8fd023436e8b00d984d1098299b0a2/content/s3maphore/00%20Core/scripts/s3/music/playlistState.lua). Current production source: [playlistState.lua on main](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/playlistState.lua).
