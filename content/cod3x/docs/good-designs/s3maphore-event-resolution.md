---
title: 'Design Genealogy: Event-Driven S3maphore Resolution'
description: How S3maphore stopped polling everything, and what the resulting invalidation bugs taught us.
weight: 70
extra:
  kind: guide
---

## The old shape

Playlist truth can change when the hour changes, the player changes cell, combat changes, a target dies, a quest changes, or a relevant setting changes.

The blunt solution is to inspect everything from `onUpdate`. It is easy to understand, but it asks the resolver to keep checking facts that have not changed and makes the update loop responsible for discovering every kind of change.

## The reduction

Ask a narrower question:

> Which events can change the inputs to playlist eligibility?

Commit [`dcf5bf21`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/dcf5bf214c979272d5938d063b9859dbc1cd7914) moved S3maphore toward event-driven resolution. Relevant state changes request resolution; ordinary updates handle the work that genuinely needs time, such as movement-state sampling and playback sequencing.

The current [`core.lua`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/blob/main/content/s3maphore/00%20Core/scripts/s3/music/core.lua) makes the split visible. `realResolvePlaylist` asks the generic selection mechanism for the best eligible playlist. Event handlers mark or request the work when their inputs change. The [playlist state](@/s3maphore/docs/api/playlist-state.md) and [event reference](@/s3maphore/docs/api/events.md) describe the public side.

{{ schematic(data_path="data/schematics/event-driven-resolution.json") }}

This is not “events are always faster.” It is “do not perform a query on every update when you can identify the boundaries at which its answer may change.”

## The scars

Event-driven systems move responsibility from repeated polling into invalidation. Missing one invalidation is now a correctness bug.

S3maphore paid for that twice:

- [`bfe28c01`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/bfe28c012a7c42a8e0349a9b06b5c0962e796c70) fixed journal updates that changed source data without dirtying derived resolver state;
- [`fbe9f127`](https://github.com/DreamWeave-MP/S3ctors-S3cret-St4sh/commit/fbe9f127c46161528b9156f9f952ca536c588f6e) restored silence-chance handling that ordinary playback still needed after the event-driven overhaul.

Those are not arguments for returning to `onUpdate` polling. They are the price of having explicit ownership of truth changes. The [resolver invalidation scar](@/cod3x/docs/paid-for-with-blood/resolver-invalidation.md) and [side-effect regression](@/cod3x/docs/paid-for-with-blood/side-effect-regression.md) show the failure modes in detail.

## What to steal

First identify the state that can change and the events that announce those changes. Then make invalidation explicit and test each input boundary.

Do not migrate to event-driven work merely to avoid an `onUpdate` callback. If you cannot name the invalidation events, you are not ready to remove the polling yet.

This study pairs with [S3maphore Playlist Eligibility](@/cod3x/docs/good-designs/s3maphore-playlist-eligibility.md): the predicate keeps the resolver generic, while invalidation tells it when asking the predicate is necessary.

## When not to use this

If the truth changes continuously and there is no trustworthy event or coarse invalidation boundary, event-driven work can become a fragile imitation of polling. Keep a bounded sampler when sampling is the actual contract, and measure before replacing it.
