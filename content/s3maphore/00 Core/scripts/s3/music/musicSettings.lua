---@omw-context player

local musicUtil = require 'scripts.s3.music.util'

local MusicSettings = musicUtil.getUpdatingSettingsTable 'SettingsS3Music'

return MusicSettings
