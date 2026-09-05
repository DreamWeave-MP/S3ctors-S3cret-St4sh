+++
title = "Loading, Registration, and Persistence"
description = "How S3maphore loads playlists, resolves them, and preserves player choices."
weight = 90

[extra]
api_docs = true
kind = "advanced"
+++

S3maphore has two separate phases: it loads and registers the available content, then it resolves the registered playlists against the live player state. Keeping those phases separate is important when writing integrations.

## Loading

S3maphore scans the VFS `Playlists/` directory for:

- `.lua` playlist files
- `.yaml` and `.yml` metadata files

Lua files run in the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md) and must return an array of playlist tables. Metadata files merge into the [playlist metadata registry](@/s3maphore/docs/api/metadata.md). Loading is coroutine-based, so large music collections are processed across update steps instead of blocking one frame.

Playback waits until playlist loading is complete and the initial cell-presence state is available. Do not assume that every playlist has been registered immediately when another script first initializes.

## Registration

When a playlist is registered, S3maphore:

1. Initializes omitted playlist fields with their defaults.
2. Discovers tracks from the playlist ID when `tracks` is not supplied.
3. Applies exclusions and fallback track data.
4. Assigns registration order for equal-priority tie breaking.
5. Restores the playlist's saved activation state when one exists.

The playlist must have a stable `id` and a `priority`. Treat playlist IDs as persistent identifiers. Renaming a playlist breaks its association with previously saved activation state. See [Playlist Specification](@/s3maphore/docs/playlist-authoring/specification.md) and [Priority and Interruption](@/s3maphore/docs/playlist-authoring/priority.md).

Playlists with no discovered tracks are not eligible for normal selection. This is why a playlist can appear in the editor but remain unavailable until its VFS music files are installed.

Scripts may also register a playlist through [I.S3maphore](@/s3maphore/docs/api/interface.md) after the player interface is ready. That registration is immediate, but it still follows the same field initialization, track discovery, priority, and activation rules.

## Resolution

S3maphore reevaluates active playlists when relevant state changes, such as cell transitions, combat, weather, time, movement, spell selection, stance, or playlist activation. It considers playlists in priority order and may stop after selecting a winner.

An `isValidCallback()` is a query, not a loop. It may run more or fewer times than expected, and it may not run once per frame. Use the [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md)'s `Playback.state` and `Playback.rules`; keep lookup tables stable and avoid side effects.

## Existing saves and persistence

Playlist activation state is kept in a game-session storage section and is also copied into the player script's save payload. A playlist disabled by the player or by `setPlaylistActive` is restored when that save is loaded; the playlist ID is the key that connects the saved choice to the newly loaded definition.

The configured death-track path is included in the player save payload. Track order is session-only state used by playlist selection and is not part of that save payload. The cell-presence scan is runtime synchronization data, not a general-purpose save-data interface.

When a mod adds or updates playlists, preserve existing IDs and provide sensible defaults for new definitions. Do not depend on the order in which files finish loading; use priority and explicit IDs to make selection deterministic.

For current playback state, use `I.S3maphore.state`, `getState()`, `getCurrentPlaylist()`, and `getCurrentTrack()`. For accepted changes, use [S3maphore events](@/s3maphore/docs/api/events.md).
