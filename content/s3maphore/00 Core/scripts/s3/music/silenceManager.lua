---@omw-context player

--- This is a little wacky as we violate normal import order rules here but it's
--- more convenient to import things which will work across engines and then pull in other things
--- in an API-specific manner
local INTERRUPT = require 'scripts.s3.music.enum.interruptMode'
local musicUtil = require 'scripts.s3.music.util'

---@type Rand
local randomGen = require 'scripts.s3.randomGen'

local SilenceData
local getRealTime, isMusicPlaying

if require 'scripts.s3.isOpenMW' then
  getRealTime = require('openmw.core').getRealTime
  isMusicPlaying = require('openmw.ambient').isMusicPlaying
else
end

local Float, Max, type = randomGen.float, math.max, type

--- Given the currently-running playlist and settings,
--- determine whether there should be a silence played
--- according to, in order:
--- 1. Whether silence between tracks is enabled at all
--- 2. What silence range the playlist defines
--- 3. What silence range/chance the player's settings define
---@param self SilenceData
---@param newPlaylist S3maphorePlaylist
local function updateSilenceParams(self, newPlaylist)
  local silenceParams = newPlaylist.silenceBetweenTracks

  if not self.GlobalSilenceToggle then
    self.time = 0
  elseif silenceParams and Float() <= (silenceParams.chance or 1) then
    if type(silenceParams) == 'table' then
      self.time = randomGen.range(silenceParams.min or 0, silenceParams.max or 30, true)
    else
      error(
        ('Invalid silence parameters on playlist %s, given silence parameter %s'):format(
          newPlaylist.id,
          silenceParams
        )
      )
    end
  elseif Float() <= (self.GlobalSilenceChance or 1) then
    local playlistArchetype = newPlaylist.interruptMode

    if playlistArchetype == INTERRUPT.Me then
      self.time = randomGen.range(self.ExploreSilenceMin, self.ExploreSilenceMax, true)
    elseif playlistArchetype == INTERRUPT.Other then
      self.time = randomGen.range(self.BattleSilenceMin, self.BattleSilenceMax, true)
    else
      -- Special playlists must always define their own silence parameters
      self.time = 0
    end

    musicUtil.debugLog('archetypal silence time is... %s', self.time)
  else
    self.time = 0
  end
end

---@return boolean beQuiet whether or not a silence track is presently active
local function silenceActive(self)
  local now = getRealTime()
  local elapsed = now - (self.lastTime or now)
  self.lastTime = now

  local silenceTrackRunning = not isMusicPlaying() and self.time > 0

  if silenceTrackRunning then self.time = Max(0, self.time - elapsed) end

  return silenceTrackRunning
end

---@class SilenceData: UpdatingSettingTable
---@field GlobalSilenceToggle boolean whether or not silence "tracks" are used
---@field GlobalSilenceChance number player-configured chance for a silence track to play between each track
---@field ExploreSilenceMin integer minimum duration of silence tracks for explore playlists
---@field ExploreSilenceMax integer maximum duration of silence tracks for explore playlists
---@field BattleSilenceMin integer minimum duration of silence tracks for battle playlists
---@field BattleSilenceMax integer maximum duration of silence tracks for battle playlists
---@field time number current remaining duration for silence
---@field lastTime number timestamp of the last silenceActive call, for wall-clock elapsed computation
---@field silenceActive fun(): boolean Whether or not a silence track is currently running
---@field updateSilenceParams fun(self, newPlaylist: S3maphorePlaylist)
SilenceData =
  musicUtil.getUpdatingSettingsTable('SettingsS3MusicSilenceConfig', 'S3maphore.s3.mcm', {
    silenceActive = silenceActive,
    updateSilenceParams = updateSilenceParams,
    time = 0,
  })

return SilenceData
