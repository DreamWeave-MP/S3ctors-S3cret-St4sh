--- This is a little wacky as we violate normal import order rules here but it's
--- more convenient to import things which will work across engines and then pull in other things
--- in an API-specific manner
local musicUtil = require 'scripts.s3.music.util'
local INTERRUPT = require 'scripts.s3.music.enum.interruptMode'

local SilenceData
local frameDuration, isMusicPlaying

if require 'scripts.s3.isOpenMW' then
    frameDuration = require 'openmw.core'.getRealFrameDuration
    isMusicPlaying = require 'openmw.ambient'.isMusicPlaying
else
end

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
    elseif silenceParams and math.random() <= (silenceParams.chance or 1) then
        if type(silenceParams) == 'table' then
            self.time = math.random(silenceParams.min or 0, silenceParams.max or 30)
        else
            error(
                ('Invalid silence parameters on playlist %s, given silence parameter %s'):format(newPlaylist.id,
                    silenceParams)
            )
        end
    elseif math.random() <= (self.GlobalSilenceChance or 1) then
        local playlistArchetype = newPlaylist.interruptMode

        if playlistArchetype == INTERRUPT.Me then
            self.time = math.random(
                self.ExploreSilenceMin,
                self.ExploreSilenceMax
            )
        elseif playlistArchetype == INTERRUPT.Other then
            self.time = math.random(
                self.BattleSilenceMin,
                self.BattleSilenceMax
            )
        else
            -- Special playlists must always define their own silence parameters
            self.time = 0
        end

        musicUtil.debugLog('archetypal silence time is...', self.time)
    else
        self.time = 0
    end
end

---@return boolean beQuiet whether or not a silence track is presently active
local function silenceActive(self)
    local silenceTrackRunning = not isMusicPlaying() and self.time > 0

    if silenceTrackRunning then
        self.time = self.time - frameDuration(); print(self.time)
    end

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
---@field silenceActive fun(): boolean Whether or not a silence track is currently running
---@field updateSilenceParams fun(self, newPlaylist: S3maphorePlaylist)
SilenceData = musicUtil.getUpdatingSettingsTable(
    'SettingsS3MusicSilenceConfig',
    'S3maphore.s3.mcm',
    {
        silenceActive = silenceActive,
        updateSilenceParams = updateSilenceParams,
        time = 0,
    }
)

return SilenceData
