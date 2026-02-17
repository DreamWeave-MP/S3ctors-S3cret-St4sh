local PlaylistFileNames = {}
for fileName in lfs.walkdir("Data Files/playlists/") do
    if (fileName:find("%.lua$")) then
        table.insert(PlaylistFileNames, fileName)
    end
end

local playlistIds =
{
    {label = "Explore", value = "Explore"},
    {label = "Battle", value = "Battle"}
}
for _, file in ipairs(PlaylistFileNames) do
    local ok, playlists = pcall(require, file:gsub("%.lua$", ""))
    if ok and type(playlists) == "table" then
        for _, playlist in ipairs(playlists) do
            playlistIds[#playlistIds + 1] = {label = playlist.id, value = playlist.id}
        end
    end
end

-- local function getMaxLength(arr)
--     local max = 0
--     for _, str in ipairs(arr) do
--         if #str > max then max = #str end
--     end
--     return max + 8
-- end

-- local function padStrings(arr)
--     local maxLen = getMaxLength(arr)
--     local padded = {}
--     for i, kvp in ipairs(arr) do
--         local totalPad = maxLen - #kvp.label
--         local leftPad = math.floor(totalPad / 2)
--         local rightPad = totalPad - leftPad
--         local str = string.rep(" ", leftPad) .. kvp.label .. string.rep(" ", rightPad)
--         padded[i] = {label = str, value = str}
--     end
--     return padded
-- end

-- local function stripWhitespace(str)
--     return str:match("^%s*(.-)%s*$")
-- end

-- local playlistIds = padStrings(playlistIds)

local i18n = mwse.loadTranslations("S3maphore")
local musicSettings = mwse.loadConfig("S3maphore", {
    SettingsS3Music =
    {
        DebugEnable = false,
        MusicEnabled = true,
        BattleEnabled = true,
        BannerEnabled = false,
        ForceFinishTrack = true,
        ForcePlaylistChangeOnFriendlyExteriorTransition = false,
        ForcePlaylistChangeOnHostileExteriorTransition = true,
        ForcePlaylistChangeOnOverworldTransition = false,
        FadeOutDuration = 1.0
    },
    SettingsS3MusicPlaylistSelection =
    {
        PlaylistActiveCurrentSelection = playlistIds[1]
    },
    SettingsS3MusicPlaylistActivity =
    {
        PlaylistActiveState = true
    },
    SettingsS3MusicSilenceConfig =
    {
        GlobalSilenceToggle = true,
        GlobalSilenceChance = 0.15,
        ExploreSilenceMin = 0,
        ExploreSilenceMax = 120,
        BattleSilenceMin = 0,
        BattleSilenceMax = 120
    },
    S3maphoreActivePlaylistSettings = {}
})

local playlistSettings = musicSettings["SettingsS3MusicPlaylistSelection"]
local activePlaylistSettings = musicSettings["SettingsS3MusicPlaylistActivity"]
local activePlaylistState = musicSettings["S3maphoreActivePlaylistSettings"]

table.subscribe(playlistSettings,
    function(_, key)
        local targetPlaylist = playlistSettings["PlaylistActiveCurrentSelection"]

        if (not targetPlaylist) then return end

        local currentState = activePlaylistState[targetPlaylist.label .. "Active"]
        local noTracks = currentState == -1

        activePlaylistSettings["PlaylistActiveState"] = noTracks and false or currentState
    end
)

table.subscribe(activePlaylistSettings,
    function(_, key)
        if (not key) then return end
        local targetPlaylist = playlistSettings["PlaylistActiveCurrentSelection"]
        local state = activePlaylistSettings["PlaylistActiveState"]
        activePlaylistState[targetPlaylist.label .. "Active"] = state
    end
)

--- @param e modConfigReadyEventData
local function modConfigReadyCallback(e)
    local template = mwse.mcm.createTemplate{name = i18n("Music")}
    template:saveOnClose("S3maphore", musicSettings)

    local page = template:createSideBarPage{label = i18n("musicSettings"), config = musicSettings["SettingsS3Music"]}
    page:createInfo{text = i18n("settingsPageDescription")}
    page:createOnOffButton{
        label = i18n("DebugEnabled"),
        description = i18n("DebugEnabledDescription"),
        leftSide = false,
        configKey = "DebugEnable"
    }
    page:createOnOffButton{
        label = i18n("MusicEnabled"),
        description = i18n("MusicEnabledDescription"),
        leftSide = false,
        configKey = "MusicEnabled"
    }
    page:createOnOffButton{
        label = i18n("BattleEnabled"),
        description = i18n("BattleEnabledDescription"),
        leftSide = false,
        configKey = "BattleEnabled"
    }
    page:createOnOffButton{
        label = i18n("BannerEnabled"),
        description = i18n("BannerEnabledDescription"),
        leftSide = false,
        configKey = "BannerEnabled"
    }
    page:createOnOffButton{
        label = i18n("NoInterrupt"),
        description = i18n("NoInterruptDescription"),
        leftSide = false,
        configKey = "ForceFinishTrack"
    }
    page:createOnOffButton{
        label = i18n("ForcePlaylistChangeOnFriendlyExteriorTransition"),
        description = i18n("ForcePlaylistChangeOnFriendlyExteriorTransitionDescription"),
        leftSide = false,
        configKey = "ForcePlaylistChangeOnFriendlyExteriorTransition"
    }
    page:createOnOffButton{
        label = i18n("ForcePlaylistChangeOnHostileExteriorTransition"),
        description = i18n("ForcePlaylistChangeOnHostileExteriorTransitionDescription"),
        leftSide = false,
        configKey = "ForcePlaylistChangeOnHostileExteriorTransition"
    }
    page:createOnOffButton{
        label = i18n("ForcePlaylistChangeOnOverworldTransition"),
        description = i18n("ForcePlaylistChangeOnOverworldTransitionDescription"),
        leftSide = false,
        configKey = "ForcePlaylistChangeOnOverworldTransition"
    }
    local block = page:createSideBySideBlock{
        description = i18n("FadeOutDurationDescription")
    }
    block:createInfo{
        text = i18n("FadeOutDuration"),
        description = i18n("FadeOutDurationDescription")
    }
    block:createSlider{
        label = i18n("FadeOutDuration"),
        description = i18n("FadeOutDurationDescription"),
        min = 0.0,
        max = 30.0,
        step = 0.1,
        jump = 1.0,
        decimalPlaces = 2,
        configKey = "FadeOutDuration",
        -- postCreate = function(self)
        --     self.elements.labelBlock.visible = false
        --     sliderLabel.elements.label.text = self.elements.label.text
        --     sliderLabel:update()
        -- end
    }

    page = template:createSideBarPage{label = i18n("PlaylistSelection"), config = musicSettings["SettingsS3MusicPlaylistSelection"]}
    page:createInfo{text = i18n("settingsPageDescription")}
    block = page:createSideBySideBlock()
    block:createInfo{
        text = i18n("CurrentPlaylistSelection"),
        description = i18n("CurrentPlaylistSelectionDescription")
    }
    block:createDropdown{
        description = i18n("CurrentPlaylistSelectionDescription"),
        leftSide = false,
        options = playlistIds,
        configKey = "PlaylistActiveCurrentSelection"
    }
    page:createButton{
        label = i18n("ResetAllPlaylists"),
        description = i18n("ResetAllPlaylistsDescription"),
        leftSide = false,
        buttonText = i18n("ResetButtonLabel"),
        callback = function()
            for _, file in ipairs(PlaylistFileNames) do
                local ok, playlists = pcall(require, file:gsub("%.lua$", ""))

                if (ok and type(playlists) == "table") then
                    for _, playlist in ipairs(playlists) do
                        activePlaylistState[playlist.id .. "Active"] = playlist.active or true
                        activePlaylistSettings["PlaylistActiveState"] = playlist.active or true
                    end
                end
            end
        end
    }

    page:createOnOffButton{
        label = i18n("PlaylistActiveState"),
        description = i18n("PlaylistActiveStateDescription"),
        leftSide = false,
        configKey = "PlaylistActiveState"
    }
    
    page = template:createSideBarPage{label = i18n("SilenceConfiguration"), config = musicSettings["SettingsS3MusicSilenceConfig"]}
    page:createInfo{text = i18n("settingsPageDescription")}
    page:createOnOffButton{
        label = i18n("GlobalSilenceToggle"),
        description = i18n("GlobalSilenceToggleDesc"),
        leftSide = false,
        configKey = "GlobalSilenceToggle"
    }
    block = page:createSideBySideBlock{description = i18n("GlobalSilenceChanceDesc")}
    block:createInfo{
        text = i18n("GlobalSilenceChanceName"),
        description = i18n("GlobalSilenceChanceDesc")
    }
    block:createTextField{
        description = i18n("GlobalSilenceChanceDesc"),
        buttonText = "Set",
        numbersOnly = true,
        configKey = "GlobalSilenceChance",
        press = function(self)
            local t
            local s
            if (musicSettings.GlobalSilenceToggle) then
                t = tostring(math.round(math.max(0.0, math.min(1.0, tonumber(self.elements.inputField.text))), 2))
                s = nil
            else
                t = tostring(self.variable.value)
                s = "Silence Tracks are turned off."
            end
            self.elements.inputField.text = t
            self.sNewValue = s
            self:update()
        end
    }
    block = page:createSideBySideBlock{description = i18n("ExploreSilenceMinDesc")}
    block:createInfo{
        text = i18n("ExploreSilenceMinDuration"),
        description = i18n("ExploreSilenceMinDesc")
    }
    block:createTextField{
        description = i18n("ExploreSilenceMinDesc"),
        buttonText = "Set",
        numbersOnly = true,
        configKey = "ExploreSilenceMin",
        press = function(self)
            local t
            local s
            if (musicSettings.GlobalSilenceToggle) then
                t = tostring(math.round(math.max(0, math.min(musicSettings.ExploreSilenceMax - 1, tonumber(self.elements.inputField.text))), 0))
                s = nil
            else
                t = tostring(self.variable.value)
                s = "Silence Tracks are turned off."
            end
            self.elements.inputField.text = t
            self.sNewValue = s
            self:update()
        end
    }
    block = page:createSideBySideBlock{description = i18n("ExploreSilenceMaxDesc")}
    block:createInfo{
        text = i18n("ExploreSilenceMaxDuration"),
        description = i18n("ExploreSilenceMaxDesc")
    }
    block:createTextField{
        description = i18n("ExploreSilenceMaxDesc"),
        buttonText = "Set",
        numbersOnly = true,
        configKey = "ExploreSilenceMax",
        press = function(self)
            local t
            local s
            if (musicSettings.GlobalSilenceToggle) then
                t = tostring(math.round(math.max(musicSettings.ExploreSilenceMin + 1, math.min(math.huge, tonumber(self.elements.inputField.text))), 0))
                s = nil
            else
                t = tostring(self.variable.value)
                s = "Silence Tracks are turned off."
            end
            self.elements.inputField.text = t
            self.sNewValue = s
            self:update()
        end
    }
    block = page:createSideBySideBlock{description = i18n("BattleSilenceMinDesc")}
    block:createInfo{
        text = i18n("BattleSilenceMinDuration"),
        description = i18n("BattleSilenceMinDesc")
    }
    block:createTextField{
        description = i18n("BattleSilenceMinDesc"),
        buttonText = "Set",
        numbersOnly = true,
        configKey = "BattleSilenceMin",
        press = function(self)
            local t
            local s
            if (musicSettings.GlobalSilenceToggle) then
                t = tostring(math.round(math.max(0, math.min(musicSettings.BattleSilenceMax - 1, tonumber(self.elements.inputField.text))), 0))
                s = nil
            else
                t = tostring(self.variable.value)
                s = "Silence Tracks are turned off."
            end
            self.elements.inputField.text = t
            self.sNewValue = s
            self:update()
        end
    }
    block = page:createSideBySideBlock{description = i18n("BattleSilenceMaxDesc")}
    block:createInfo{
        text = i18n("BattleSilenceMaxDuration"),
        description = i18n("BattleSilenceMaxDesc")
    }
    block:createTextField{
        description = i18n("BattleSilenceMaxDesc"),
        buttonText = "Set",
        numbersOnly = true,
        configKey = "BattleSilenceMax",
        press = function(self)
            local t
            local s
            if (musicSettings.GlobalSilenceToggle) then
                t = tostring(math.round(math.max(musicSettings.BattleSilenceMin + 1, math.min(math.huge, tonumber(self.elements.inputField.text))), 0))
                s = nil
            else
                t = tostring(self.variable.value)
                s = "Silence Tracks are turned off."
            end
            self.elements.inputField.text = t
            self.sNewValue = s
            self:update()
        end
    }
    mwse.mcm.register(template)
end
event.register(tes3.event.modConfigReady, modConfigReadyCallback)

return
{
    get = function(key)
        return musicSettings[key]
    end
}