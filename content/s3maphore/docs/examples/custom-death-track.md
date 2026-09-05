+++
title = "Custom Death Track"
description = "Install, test, persist, and restore a custom death-track selection."
weight = 60

[extra]
api_docs = true
kind = "example"
+++

The configured death track is separate from ordinary playlists. Set it once, and S3maphore uses it the next time the player dies, including after a save/load cycle.

```lua
local S3maphore = require('openmw.interfaces').S3maphore

local DeathTrack = 'music/my-mod/death.mp3'

S3maphore.setDeathTrack(DeathTrack)

if S3maphore.getDeathTrack() == DeathTrack then
    print('Custom death track accepted')
end

-- Play it immediately without changing the configured value.
S3maphore.playSpecialTrack(
    DeathTrack,
    S3maphore.const.STATE.SpecialTrackPlaying
)

-- Restore music/special/mw_death.mp3 when the event is over.
S3maphore.resetDeathTrack()
```

The file must exist at the OpenMW VFS path. An invalid path is logged and ignored. For the event equivalents, save behavior, and the distinction between death playback and `killCounts`, see [Death Track](@/s3maphore/docs/api/death-track.md).
