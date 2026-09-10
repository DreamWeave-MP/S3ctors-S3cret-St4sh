---@omw-context player

local coCreate, coResume, coStatus, coYield, error, next, print, type, ToString =
  coroutine.create,
  coroutine.resume,
  coroutine.status,
  coroutine.yield,
  error,
  next,
  print,
  type,
  tostring

local StrFormat, StrMatch = string.format, string.match

local Quit = require('openmw.core').quit
local util = require 'openmw.util'
local vfs = require 'openmw.vfs'

local musicUtil = require 'scripts.s3.music.util'

local Catalog = require 'scripts.s3.music.playlistCatalog'
local MusicManager = require 'scripts.s3.music.musicManager'

local FAILED_TO_LOAD_PLAYLIST = 'Failed to load playlist file: %s\nErr: %s'

--- Takes any number of paramaters and deep prints them, if debug logging is enabled
local function printOverride(...) musicUtil.debugLog(musicUtil.deepToString({ ... }, 3)) end

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
    rules = require('scripts.s3.music.playlistRules').rules,
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

local currentFile = 'Playlists/ discovery'

local function playlistCoroutineLoader()
  local files = musicUtil.getAllPlaylistFiles()

  for fileIndex = 1, #files do
    local file = files[fileIndex]
    currentFile = file

    if StrMatch(file, '%.ya?ml$') then
      MusicManager.playlistMetadata.loadYamlFile(file)
    elseif StrMatch(file, '%.lua$') then
      musicUtil.debugLog('reading playlist file: %s', file)

      local fileHandle, openError = vfs.open(file)
      if not fileHandle then
        error(StrFormat(FAILED_TO_LOAD_PLAYLIST, file, ToString(openError)))
      end

      local codeString, readError = fileHandle:read '*a'
      local closed, closeError = fileHandle:close()

      if codeString == nil then
        error(StrFormat(FAILED_TO_LOAD_PLAYLIST, file, ToString(readError)))
      end

      if not closed then error(StrFormat(FAILED_TO_LOAD_PLAYLIST, file, ToString(closeError))) end

      local playlistChunk = util.loadCode(codeString, PlaylistEnvironment)
      if type(playlistChunk) ~= 'function' then
        error(StrFormat(FAILED_TO_LOAD_PLAYLIST, file, 'chunk did not compile to a function'))
      end

      local result = playlistChunk()
      if type(result) ~= 'table' then
        error(StrFormat(FAILED_TO_LOAD_PLAYLIST, file, 'chunk must return a playlist table'))
      end

      local playlistCount = #result
      for key in next, result do
        if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 or key > playlistCount then
          error(
            StrFormat(
              FAILED_TO_LOAD_PLAYLIST,
              file,
              StrFormat(
                'playlist return value must be a contiguous array; invalid key %s',
                ToString(key)
              )
            )
          )
        end
      end

      for playlistIndex = 1, playlistCount do
        local playlist = result[playlistIndex]
        if type(playlist) ~= 'table' then
          error(
            StrFormat(
              FAILED_TO_LOAD_PLAYLIST,
              file,
              StrFormat('playlist %d must be a table, got %s', playlistIndex, type(playlist))
            )
          )
        end
        Catalog.registerSource(playlist, string.lower(file:gsub('\\', '/')))
        coYield(playlist)
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

  local ok, failure = coResume(playlistLoaderCo)

  if not ok then
    local message = StrFormat(
      'S3maphore playlist initialization failed while processing %s:\n%s',
      ToString(currentFile),
      ToString(failure)
    )
    print(StrFormat('[ S3MAPHORE ]: Fatal initialization error: %s', message))
    Quit()
    error(message, 0)
  end

  if failure then
    musicUtil.debugLog('Registered playlist: %s', failure.id)
    playlistCount = playlistCount + 1
  elseif coStatus(playlistLoaderCo) == 'dead' then
    Catalog.finishLoading()
    print(StrFormat('[ S3MAPHORE ]: %d playlists loaded. Ready to play music!', playlistCount))

    return PlaylistEnvironment
  end
end
