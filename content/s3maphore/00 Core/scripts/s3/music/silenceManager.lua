--- This is a little wacky as we violate normal import order rules here but it's
--- more convenient to import things which will work across engines and then pull in other things
--- in an API-specific manner
local musicUtil = require 'scripts.s3.music.util'
local INTERRUPT = require 'scripts.s3.music.enum.interruptMode'

---@class SilenceData: UpdatingSettingTable
---@field GlobalSilenceToggle boolean whether or not silence "tracks" are used
---@field GlobalSilenceChance number player-configured chance for a silence track to play between each track
---@field ExploreSilenceMin integer minimum duration of silence tracks for explore playlists
---@field ExploreSilenceMax integer maximum duration of silence tracks for explore playlists
---@field BattleSilenceMin integer minimum duration of silence tracks for battle playlists
---@field BattleSilenceMax integer maximum duration of silence tracks for battle playlists
---@field time number current remaining duration for silence
local SilenceData = musicUtil.getUpdatingSettingsTable('SettingsS3MusicSilenceConfig', nil, { time = 0 })

--- Given the currently-running playlist and settings,
--- determine whether there should be a silence played
--- according to, in order:
--- 1. Whether silence between tracks is enabled at all
--- 2. What silence range the playlist defines
--- 3. What silence range/chance the player's settings define
---@param newPlaylist S3maphorePlaylist
function SilenceData.updateSilenceParams(newPlaylist)
    local silenceParams = newPlaylist.silenceBetweenTracks

    if not SilenceData.GlobalSilenceToggle then
        SilenceData.time = 0
    elseif silenceParams and math.random() <= (silenceParams.chance or 1) then
        if type(silenceParams) == 'table' then
            SilenceData.time = math.random(silenceParams.min or 0, silenceParams.max or 30)
        else
            error(
                ('Invalid silence parameters on playlist %s, given silence parameter %s'):format(newPlaylist.id,
                    silenceParams)
            )
        end
    elseif math.random() <= (SilenceData.GlobalSilenceChance or 1) then
        local playlistArchetype = newPlaylist.interruptMode

        if playlistArchetype == INTERRUPT.Me then
            SilenceData.time = math.random(
                SilenceData.ExploreSilenceMin,
                SilenceData.ExploreSilenceMax
            )
        elseif playlistArchetype == INTERRUPT.Other then
            SilenceData.time = math.random(
                SilenceData.BattleSilenceMin,
                SilenceData.BattleSilenceMax
            )
        else
            -- Special playlists must always define their own silence parameters
            SilenceData.time = 0
        end

        musicUtil.debugLog('archetypal silence time is...', SilenceData.time)
    else
        SilenceData.time = 0
    end
end

return SilenceData
