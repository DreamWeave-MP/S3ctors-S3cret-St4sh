local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_track_order%.lua$' or '.'

package.path = table.concat({
  root .. '/content/h3lp_yours3lf/?.lua',
  root .. '/content/s3maphore/00 Core/?.lua',
  package.path,
}, ';')

local storageData = {}
local function makeStorageSection(name)
  local data = storageData[name] or {}
  storageData[name] = data
  return {
    asTable = function() return data end,
    get = function(_, key) return data[key] end,
    set = function(_, key, value) data[key] = value end,
    setLifeTime = function() end,
    subscribe = function() end,
  }
end

package.preload['openmw.async'] = function()
  return { callback = function(_, callback) return callback end }
end
package.preload['openmw.ambient'] = function()
  return { isMusicPlaying = function() return false end, stopMusic = function() end }
end
package.preload['openmw.core'] = function()
  return { getGameTime = function() return 0 end }
end
package.preload['openmw.self'] = function()
  return { sendEvent = function() end }
end
package.preload['openmw.storage'] = function()
  return {
    LIFE_TIME = { GameSession = 1 },
    playerSection = makeStorageSection,
  }
end
package.preload['openmw.vfs'] = function()
  return {
    fileExists = function() return true end,
    pathsWithPrefix = function()
      return function() end
    end,
  }
end
package.preload['openmw_aux.util'] = function()
  return { callEventHandlers = function() end }
end
package.preload['scripts.s3.isOpenMW'] = function() return true end
package.preload['scripts.s3.music.banner'] = function()
  return { layout = { props = {}, content = {} }, update = function() end }
end
package.preload['scripts.s3.music.musicMetadata'] = function()
  return { getPlaylistMetadata = function() end, getTrackMetadata = function() end }
end
package.preload['scripts.s3.music.musicSettings'] = function()
  return { BannerEnabled = false, FadeOutDuration = 0, MusicEnabled = true }
end
package.preload['scripts.s3.music.playlistState'] = function() return {} end
package.preload['scripts.s3.music.silenceManager'] = function() return { time = 0 } end
package.preload['scripts.s3.music.enum.interruptMode'] = function()
  return { Me = 0, Other = 1, Never = 2, Override = 3 }
end
package.preload['scripts.s3.music.enum.stateChangeReason'] = function()
  return { SpecialTrackPlaying = 1 }
end
package.preload['scripts.s3.music.enum.stateChangedFlags'] = function() return {} end
package.preload['scripts.s3.music.enum.timeMap'] = function() return {} end
package.preload['scripts.s3.music.defaultDeathTrack'] = function()
  return 'music/special/mw_death.mp3'
end

local musicUtil = require 'scripts.s3.music.util'
local originalInitTracksOrder = musicUtil.initTracksOrder
local initializationCount = 0
musicUtil.initTracksOrder = function(tracks, randomize)
  initializationCount = initializationCount + 1
  if initializationCount == 1 then return { 1, 2 } end
  return { 2, 1 }
end

local MusicManager = require 'scripts.s3.music.musicManager'
initializationCount = 0
local playlistId = 'test/order-invalidation'
local callback = function() return true end

MusicManager.registerPlaylist {
  id = playlistId,
  priority = 900,
  tracks = { 'music/one.mp3', 'music/two.mp3' },
  isValidCallback = callback,
}
assert(initializationCount == 1)
assert(MusicManager.playlistsTracksOrder[playlistId][1] == 1)

MusicManager.registerPlaylist {
  id = playlistId,
  priority = 900,
  tracks = { 'music/three.mp3', 'music/four.mp3' },
  isValidCallback = callback,
}
assert(initializationCount == 2, 'changed tracks with the same count reused the old order')
assert(MusicManager.playlistsTracksOrder[playlistId][1] == 2)
assert(storageData.S3MusicPlaylistsTrackOrder[playlistId][1] == 2)

musicUtil.initTracksOrder = originalInitTracksOrder
print 'S3maphore playlist track-order tests passed'
