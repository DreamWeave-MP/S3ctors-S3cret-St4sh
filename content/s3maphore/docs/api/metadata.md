+++
title = "Playlist and Track Metadata"
description = "Add display metadata to playlists and tracks with YAML files."
weight = 60

[extra]
api_docs = true
kind = "api"
+++

Metadata is separate from playlist behavior. A Lua playlist file defines what can play; a YAML metadata file gives S3maphore the names and descriptive information to show when it plays.

Put a `.yaml` or `.yml` file under the same VFS `Playlists/` directory as the Lua playlist files. S3maphore loads both formats automatically.

## Metadata file format

Metadata is divided into `playlists` and `tracks`:

```yaml
playlists:
  my-mod/explore:
    title: My Mod Explore Music
    artist: Example Artist
    album: The Example Collection
    year: 2026
    genre: Ambient
    description: Exploration music for the example region.
    source: Example Mod
    composer: Example Composer
    license: CC BY-SA 4.0

tracks:
  music/my-mod/explore/first-song.mp3:
    title: Across the Bitter Coast
    artist: Example Artist
    album: The Example Collection
    year: 2026
    genre: Ambient
    description: A quiet walk along the coast.
    source: Example Mod
    composer: Example Composer
    license: CC BY-SA 4.0
```

The playlist key is the playlist's `id`. The track key is the track's full VFS path. Both keys are normalized before lookup, so use the same paths and IDs you use in the playlist definition.

String values are shorthand for a title-only metadata table:

```yaml
playlists:
  my-mod/explore: My Mod Explore Music
tracks:
  music/my-mod/explore/first-song.mp3: Across the Bitter Coast
```

Table values must contain a string `title`. The supported fields are:

| Field | Type | Meaning |
| --- | --- | --- |
| `title` | `string` | Display name. Required for table values. |
| `artist` | `string?` | Performing artist. |
| `album` | `string?` | Album or collection name. |
| `year` | `integer?` | Release year. |
| `genre` | `string?` | Genre label. |
| `description` | `string?` | Longer description. |
| `source` | `string?` | Mod, collection, or source attribution. |
| `composer` | `string?` | Composer name. |
| `license` | `string?` | License or usage terms. |

## Adding metadata to an existing playlist

Do not put metadata fields inside the playlist table. Add a YAML entry keyed by the existing playlist ID or track VFS path:

```lua
return {
    {
        id = 'my-mod/explore',
        priority = PlaylistPriority.Explore,
        tracks = {
            'music/my-mod/explore/first-song.mp3',
        },
        isValidCallback = function()
            return not Playback.state.isInCombat
        end,
    },
}
```

```yaml
playlists:
  my-mod/explore: My Mod Explore Music
tracks:
  music/my-mod/explore/first-song.mp3: Across the Bitter Coast
```

This works the same way when tracks are discovered from the playlist ID's folder. Metadata names the resulting playlist and track; it does not add tracks, register playlists, or change selection rules.

## Normalization and collisions

Playlist IDs and track paths are normalized to lowercase, forward-slash paths with redundant separators removed. Metadata lookups therefore behave consistently even when the Lua definition uses different capitalization.

If multiple YAML files define the same normalized playlist ID or track path, the later-loaded entry replaces the earlier one and S3maphore logs an override message. Keep one metadata owner per key unless an intentional override is part of the mod's design.

Malformed YAML or invalid metadata tables are reported while the rest of the playlist load continues. A metadata table without a string `title` is invalid.

## Reading metadata from Lua

The public registry is available as `I.S3maphore.playlistMetadata`:

```lua
local S3maphore = require('openmw.interfaces').S3maphore
local registry = S3maphore.playlistMetadata

local playlist = registry.getPlaylistMetadata('my-mod/explore')
local track = registry.getTrackMetadata('music/my-mod/explore/first-song.mp3')
local displayName = registry.getPlaylistDisplayName('my-mod/explore')
```

The returned metadata tables are read-only. Unknown playlist IDs and track paths return `nil`; `getPlaylistDisplayName` falls back to the supplied playlist ID when no title is registered.

The registry also provides iterators for tooling and UI:

| Method | Result |
| --- | --- |
| `getPlaylistDisplayName(id)` | Metadata title, or the original ID when no metadata exists. |
| `getPlaylistMetadata(id)` | Playlist metadata table, or `nil`. |
| `getTrackMetadata(path)` | Track metadata table, or `nil`. |
| `iterPlaylists()` | Iterator over normalized playlist IDs and metadata. |
| `iterTracks()` | Iterator over normalized VFS paths and metadata. |
| `loadYamlFile(path)` | Loads or reloads one metadata file. Advanced, loader-facing operation; ordinary integrations should let S3maphore discover metadata automatically. |

`I.S3maphore.getCurrentTrackInfo()` returns the metadata for the current playlist and track as two values. The track banner appears only when both metadata entries are available and track information is enabled; it does not fall back to the playlist ID or track path. See [I.S3maphore](@/s3maphore/docs/api/interface.md) for the interface method and [Events](@/s3maphore/docs/api/events.md) for track-change notifications.

Metadata is not a localization file. The registry stores the values supplied by YAML and does not choose translations for them. If a music pack needs localized display text, it must provide that behavior separately rather than assuming metadata keys are passed through OpenMW's l10n system.
