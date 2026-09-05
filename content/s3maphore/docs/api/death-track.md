+++
title = "Death Track"
description = "Every supported way to select, reset, persist, and play the death track."
weight = 60

[extra]
api_docs = true
kind = "interface"
+++

S3maphore treats the death track as a separate configured path. When the player dies, it plays that path once as a special track and then returns to normal resolution. Changing the death track does not change the registered playlists.

## Default

The default VFS path is:

```text
music/special/mw_death.mp3
```

The default is supplied by `scripts.s3.music.defaultDeathTrack`. A VFS override of that module changes the default used by S3maphore, but the supported runtime integration is the `I.S3maphore` interface below.

## Interface methods

| Member | Signature | Behavior |
| --- | --- | --- |
| `getDeathTrack` | `fun() → string` | Returns the currently configured VFS path. |
| `setDeathTrack` | `fun(path: string)` | Sets the path if the file exists in the VFS. Invalid paths are logged and ignored. |
| `resetDeathTrack` | `fun()` | Restores the configured default path. |

```lua
local S3maphore = require('openmw.interfaces').S3maphore

S3maphore.setDeathTrack('music/my-mod/death.mp3')
print(S3maphore.getDeathTrack())

S3maphore.resetDeathTrack()
```

The path is a VFS path, not an operating-system filesystem path. Package the audio file in an active data directory or archive and use its OpenMW-visible path.

The implementation also exposes `require 'scripts.s3.music.musicManager'.setDeathTrack(path)` inside the player context. That is an internal module path, not a compatibility promise; use `I.S3maphore.setDeathTrack` for integrations.

## Equivalent player events

The same operations are available as player-scoped events:

```lua
local self = require 'openmw.self'

self.sendEvent(self, 'S3maphoreSetDeathTrack', 'music/my-mod/death.mp3')
self.sendEvent(self, 'S3maphoreResetDeathTrack')
```

Use the interface when you already have it. Events are useful when an existing event-driven integration is the better fit.

## Death playback

On the `Died` event, S3maphore reads the current configured path and sends itself:

```lua
{
    trackPath = S3maphore.getDeathTrack(),
    reason = S3maphore.const.STATE.Died,
}
```

That is a `S3maphoreSpecialTrack` playback request. It is not a playlist activation and it does not permanently change the configured path.

`playSpecialTrack(path, reason)` can play another one-shot track, but it does not mutate the death-track setting. If the desired behavior is “play this track on death from now on,” call `setDeathTrack`; if it is “play this track once right now,” call `playSpecialTrack`.

## Save and load

S3maphore stores the current death-track path in its player script state under `deathTrack`. Loading a save restores it through the same existence-checked setter. A missing path is rejected, leaving the already initialized default or current valid path active.

This is separate from `PlaylistState.killCounts`. Kill counts describe actors that have died; they do not choose the death audio.

## Example: a custom death track with a manual test

```lua
local I = require 'openmw.interfaces'
local self = require 'openmw.self'

local CustomDeathTrack = 'music/my-mod/death.mp3'

I.S3maphore.setDeathTrack(CustomDeathTrack)

if I.S3maphore.getDeathTrack() == CustomDeathTrack then
    print('Custom death track is active')
end

-- Test the audio without changing the configured death track.
I.S3maphore.playSpecialTrack(CustomDeathTrack, I.S3maphore.const.STATE.SpecialTrackPlaying)

-- Restore the default later.
I.S3maphore.resetDeathTrack()
```
