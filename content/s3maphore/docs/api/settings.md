+++
title = "Settings"
description = "S3maphore's music, combat, transition, and silence settings."
weight = 80

[extra]
api_docs = true
kind = "settings"
+++

S3maphore settings live in the OpenMW **Music** settings page. The main group is permanent player storage under `SettingsS3Music`; silence settings are stored under `SettingsS3MusicSilenceConfig`.

## Playback settings

| Key | Default | Effect |
| --- | ---: | --- |
| `DebugEnable` | `false` | Enables verbose `[ S3MAPHORE ]` diagnostics in `openmw.log`. |
| `MusicEnabled` | `true` | Enables S3maphore playback. Disabling it stops the current track. |
| `BattleEnabled` | `true` | Allows combat playlists to become active. |
| `ExploreEnabled` | `true` | Allows exploration playlists to become active. |
| `BannerEnabled` | `false` | Shows current playlist and track titles in the music banner. |
| `ForceFinishTrack` | `true` | Prevents playlists with the same interrupt mode from replacing the current track before it finishes. |
| `FadeOutDuration` | `1.0` | Global fade-out duration in seconds, from `0.0` to `30.0`. A playlist-level `fadeOut` overrides it. |

## Transition settings

These settings decide whether a newly resolved contextual playlist may force a track change during an exterior transition:

| Key | Default | Effect |
| --- | ---: | --- |
| `ForcePlaylistChangeOnFriendlyExteriorTransition` | `false` | Allows a new playlist to interrupt during a friendly exterior transition. |
| `ForcePlaylistChangeOnHostileExteriorTransition` | `true` | Allows a new playlist to interrupt during a hostile exterior transition. |
| `ForcePlaylistChangeOnOverworldTransition` | `false` | Allows a higher-priority new playlist to interrupt during an overworld transition. |

Cell and state changes still trigger resolution. These controls affect whether the resolved playlist can force an interruption during the transition; they do not change playlist priority or callback rules.

## Combat settings

| Key | Default | Effect |
| --- | ---: | --- |
| `PlayerTargetedCombatOnly` | `true` | Counts an actor for combat music only when that actor is targeting the player. |
| `CombatHealthThreshold` | `0.0` | When greater than zero, combat music can be filtered by the target's remaining health ratio. `0.0` disables this filter. |
| `CombatLevelGap` | `0` | When greater than zero, ignores targets that are more than this many levels below the player. `0` disables this filter. |

Combat filtering happens after actor target polling and before `PlaylistState.isInCombat` is recomputed. The [batched combat event architecture](@/s3maphore/docs/api/events.md#s3maphorecheckcombat) keeps that polling bounded.

## Silence settings

| Key | Default | Effect |
| --- | ---: | --- |
| `GlobalSilenceToggle` | `true` | Enables the chance of silence between tracks. |
| `GlobalSilenceChance` | `0.15` | Chance of a silence interval when global silence is enabled. |
| `ExploreSilenceMin` | `0` | Minimum exploration silence duration in seconds. |
| `ExploreSilenceMax` | `120` | Maximum exploration silence duration in seconds. |
| `BattleSilenceMin` | `0` | Minimum battle silence duration in seconds. |
| `BattleSilenceMax` | `120` | Maximum battle silence duration in seconds. |

A playlist can provide `silenceBetweenTracks` to define its own silence parameters. If its chance roll fails, S3maphore falls through to the global silence chance for Explore and Battle playlists. Special playlists must define their own silence parameters. See [Playlist Specification](@/s3maphore/docs/playlist-authoring/specification.md) for the playlist-level field.

## Settings and reevaluation

Changing a setting does not mean every callback is immediately run in isolation. S3maphore updates its state machine and reevaluates selection when the relevant state or setting changes. Callbacks should remain pure, cheap queries of `Playback.state` and `Playback.rules`; do not use them to watch settings or perform side effects.

For programmatic playback control, use [I.S3maphore](@/s3maphore/docs/api/interface.md). For the available playlist-side bindings, see [PlaylistEnvironment](@/s3maphore/docs/api/playlist-environment.md).
