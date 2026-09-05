+++
title = "Playlist"
description = "The data structure registered with S3maphore."
weight = 10

[extra]
api_docs = true
kind = "api"
+++

## `S3maphorePlaylist`

{{ api_signature(value="S3maphorePlaylist -> table") }}

A playlist is a table containing an `id`, a `priority`, and an `isValidCallback`. A playlist file returns an array of these tables. See the complete [Playlist Specification](@/s3maphore/docs/playlist-authoring/specification.md) for every supported field.

### Required fields

`id` is the playlist's stable identifier. It is also used as a folder name when `tracks` is not provided.

`priority` is the playlist's place in resolution. Use the exported `PlaylistPriority` values instead of scattering magic numbers through a music pack.

### Validation

`isValidCallback` is required and returns `true` when the playlist applies. Playlist files use the `Playback` binding from the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md); programmatically registered playlists can use the callback argument. The callback should not mutate game state or act as a timer. See [Playback](@/s3maphore/docs/api/playback.md) for its state and rules.
