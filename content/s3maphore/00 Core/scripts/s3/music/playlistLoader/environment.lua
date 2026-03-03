local util = require 'scripts.s3.music.util'

---@class S3maphorePlaylistEnv
local PlaylistEnvironment = {
  playSpecialTrack = MusicManager.playSpecialTrack,
  skipTrack = MusicManager.skipTrack,
  setPlaylistActive = MusicManager.setPlaylistActive,
  timeOfDay = MusicManager.playlistTimeOfDay,
  INTERRUPT = MusicManager.INTERRUPT,
  ---@type PlaylistPriority
  PlaylistPriority = require 'doc.playlistPriority',
  Tilesets = require 'doc.tilesets',
  Playback = Playback,
  --- Don't interfaces HAVE to be tables?
  ---@type table <string, any>
  I = require 'openmw.interfaces',
  math = math,
  string = string,
  ipairs = ipairs,
  pairs = pairs,
  --- Takes any number of paramaters and deep prints them, if debug logging is enabled
  ---@param ... any
  print = function(...)
    util.debugLog(
      util.deepToString({ ... }, 3)
    )
  end,
}

return PlaylistEnvironment
