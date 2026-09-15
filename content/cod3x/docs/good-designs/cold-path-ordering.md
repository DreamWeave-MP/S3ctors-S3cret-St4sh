---
title: 'Design Study: Move Stable Work to the Cold Path'
description: How sorting once during playlist loading removed repeated work from resolution.
weight: 110
extra:
  kind: guide
---

## The problem

S3maphore resolves playlists in priority order. If that order is stable between registrations, sorting the same decks during every resolution is work that does not change the answer.

It is easy to miss because sorting is not a dramatic operation. It is simply in the wrong place.

## The reduction

Ask when the ordering becomes known:

> If the input is stable, why are we re-establishing its order in the hot path?

Commit [`5b1537b5`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/5b1537b504e2861755d1bb4f63ac5c5d1362dbd) moved playlist sorting to the initialization boundary. The current [music core](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/core.lua) sorts each deck after loading completes, while the [playlist catalog](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/playlistCatalog.lua) re-sorts when a ready catalog changes. Normal selection walks already ordered decks.

This is not a LuaJIT trick. It is a placement decision: establish stable facts at the boundary where the data enters, then make the runtime path consume them.

## Why this works

Moving stable work cold does three things:

- removes repeated work from a path that may run often;
- makes the hot path's assumptions visible;
- gives registration and loading code ownership of order changes.

The optimization is safe only because the ordering contract is explicit. When a playlist is registered, removed, or its priority changes, the catalog must restore the ordering before resolution uses it. The [priority rules](@/s3maphore/docs/playlist-authoring/priority.md) document the semantic ordering; the catalog owns maintaining the data structure.

## What to steal

Look for work whose answer depends only on stable input: sorting, parsing, path normalization, lookup-table construction, and validation are common examples.

Do it once when the data enters the system. Keep the invalidation path responsible for rebuilding it when the input actually changes.

This is the approachable beginning of the performance path. [Measure First](@/cod3x/docs/performance/measure-first.md) tells you how to establish whether repeated work matters before moving it.

## When not to use this

Do not move work out of the runtime path if its inputs can change there or if rebuilding it is cheaper than maintaining invalidation. A stale “cold-path” result is worse than a small repeated calculation.
