+++
title = "Overview"
description = "The mental model behind S3maphore playlists."
weight = 10

[extra]
api_docs = true
kind = "guide"
+++

S3maphore treats music as a collection of contextual playlists. A playlist describes tracks and playback behavior; its `isValidCallback` describes when it is eligible; its priority decides what happens when several playlists are eligible at once.

When selection is reevaluated, S3maphore considers eligible playlists in priority order and may stop after finding a valid choice. Callback frequency is not a timing contract. Write callbacks as cheap queries of the current playback state, not as update loops.

## The three pieces

1. **Playlist** — the tracks and playback policy.
2. **Priority** — the ordering used to resolve eligible playlists.
3. **Validity callback** — a function that returns whether the playlist applies to the current state.

The built-in rules handle common cases such as cells, regions, combat, weather, and journal values. Custom Lua logic is available when your mod needs something more specific.
