local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local musicUtil = require 'scripts.s3.music.util'

local Strings = require 'scripts.s3.music.staticStrings'

--- Takes any number of paramaters and deep prints them, if debug logging is enabled
local function printOverride(...)
  musicUtil.debugLog(
    musicUtil.deepToString({ ... }, 3)
  )
end

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
  print = printOverride,
}

local function playlistCoroutineLoader()
  local result, codeString

  for _, file in ipairs(musicUtil.getPlaylistFilePaths()) do
    musicUtil.debugLog('reading playlist file', file)

    --- open the file
    local ok, fileHandle = pcall(vfs.open, file)
    if not ok then goto fail end

    --- read all lines
    codeString = fileHandle:read('*a')

    --- util.loadCode it
    ok, result = pcall(util.loadCode, codeString, PlaylistEnvironment)
    if not ok or type(result) ~= 'function' then goto fail end

    --- call the resulting function to get the inner playlist array
    ok, result = pcall(result)

    if type(result) ~= 'table' then goto fail end
    musicUtil.debugLog(musicUtil.deepToString(result, 3))

    for _, playlist in ipairs(result) do
      MusicManager.registerPlaylist(playlist)
      coroutine.yield(playlist)
    end

    ::fail::
    if not ok then
      print(
        Strings.FailedToLoadPlaylist:format(file, result)
      )
    else
      fileHandle:close()
    end
  end
end

-- Create the coroutine
local playlistLoaderCo = coroutine.create(playlistCoroutineLoader)
local playlistCount = 0

---@return boolean? canPlayback if true, loading has finished and playback can start
return function()
  local status = coroutine.status(playlistLoaderCo)
  if status == 'dead' then return true end

  local ok, playlist = coroutine.resume(playlistLoaderCo)

  if ok and playlist then
    musicUtil.debugLog("Registered playlist:", playlist.id)
    playlistCount = playlistCount + 1
  elseif coroutine.status(playlistLoaderCo) == "dead" then
    print(
      Strings.InitializationFinished:format(playlistCount)
    )
    return true
  end
end
