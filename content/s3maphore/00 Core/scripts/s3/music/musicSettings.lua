local musicUtil = require 'scripts.s3.music.util'

---@class S3maphoreCoreSettings: UpdatingSettingTable
---@field BannerEnabled boolean
---@field BattleEnabled boolean
---@field DebugEnable boolean
---@field ForceFinishTrack boolean
---@field ForcePlaylistChangeOnFriendlyExteriorTransition boolean
---@field ForcePlaylistChangeOnHostileExteriorTransition boolean
---@field ForcePlaylistChangeOnOverworldTransition boolean
---@field FadeOutDuration number
---@field MusicEnabled boolean
local MusicSettings = musicUtil.getUpdatingSettingsTable('SettingsS3Music')

return MusicSettings
