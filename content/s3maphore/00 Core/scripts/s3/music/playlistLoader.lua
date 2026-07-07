---@omw-context player

local coCreate, coResume, coStatus, coYield, pcall, print, type =
  coroutine.create, coroutine.resume, coroutine.status, coroutine.yield, pcall, print, type

local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local musicUtil = require 'scripts.s3.music.util'

local MusicManager = require 'scripts.s3.music.musicManager'
local Strings = require 'scripts.s3.music.staticStrings'

--- Takes any number of paramaters and deep prints them, if debug logging is enabled
local function printOverride(...) musicUtil.debugLog(musicUtil.deepToString({ ... }, 3)) end

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
  Playback = {
    rules = require 'scripts.s3.music.playlistRules',
    state = require 'scripts.s3.music.playlistState',
  },
  --- Don't interfaces HAVE to be tables?
  ---@type table <string, any>
  I = require 'openmw.interfaces',
  math = math,
  require = require,
  string = string,
  table = table,
  ipairs = ipairs,
  pairs = pairs,
  print = printOverride,
}

local function playlistCoroutineLoader()
  local files = musicUtil.getAllPlaylistFiles()
  local result, codeString

  for fileIndex = 1, #files do
    local file = files[fileIndex]

    if file:match '%.ya?ml$' then
      local ok, err = pcall(MusicManager.playlistMetadata.loadYamlFile, file)
      if not ok then print(Strings.FailedToLoadTrackMetadata:format(file, err)) end
    elseif file:match '%.lua$' then
      musicUtil.debugLog('reading playlist file', file)

      local ok, fileHandle = pcall(vfs.open, file)
      if not ok then
        print(Strings.FailedToLoadPlaylist:format(file, fileHandle))
      else
        codeString = fileHandle:read '*a'
        fileHandle:close()

        ok, result = pcall(util.loadCode, codeString, PlaylistEnvironment)

        if not ok or type(result) ~= 'function' then
          print(Strings.FailedToLoadPlaylist:format(file, result))
        else
          ok, result = pcall(result)

          if type(result) ~= 'table' then
            print(Strings.FailedToLoadPlaylist:format(file, result))
          else
            for playlistIndex = 1, #result do
              local playlist = result[playlistIndex]
              MusicManager.registerPlaylist(playlist)
              coYield(playlist)
            end
          end
        end
      end
    end
  end
end

-- Create the coroutine
local playlistLoaderCo = coCreate(playlistCoroutineLoader)
local playlistCount = 0

---@return S3maphorePlaylistEnv? PlaylistEnvironment once non-nil, loading has finished and playback can start
return function()
  local status = coStatus(playlistLoaderCo)
  if status == 'dead' then return end

  local ok, playlist = coResume(playlistLoaderCo)

  if ok and playlist then
    musicUtil.debugLog('Registered playlist:', playlist.id)
    playlistCount = playlistCount + 1
  elseif coStatus(playlistLoaderCo) == 'dead' then
    print(Strings.InitializationFinished:format(playlistCount))

    return PlaylistEnvironment
  end
end
