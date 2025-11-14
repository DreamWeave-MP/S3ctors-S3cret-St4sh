local core = require 'openmw.core'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

local ModName = 'TalkToTheHand'

local statNames = { 'fatigue', 'magicka', 'health' }

---@param key string
---@param renderer DefaultSettingRenderer
---@param argument SettingRendererOptions
---@param name string
---@param description string
---@param default string|number|boolean
local function setting(key, renderer, argument, name, description, default)
    return {
        key = key,
        renderer = renderer,
        argument = argument,
        name = name,
        description = description,
        default = default,
    }
end

local function colorFromGMST(gmst)
    local colorString = core.getGMST(gmst)
    local numberTable = {}
    for numberString in colorString:gmatch("([^,]+)") do
        if #numberTable == 3 then break end
        local number = tonumber(numberString:match("^%s*(.-)%s*$"))
        if number then
            table.insert(numberTable, number / 255)
        end
    end

    if #numberTable < 3 then error('Invalid color GMST name: ' .. gmst) end

    return util.color.rgb(table.unpack(numberTable))
end

I.Settings.registerPage {
    key = ModName,
    l10n = ModName,
    name = 'HandPageName',
    description = 'HandPageDesc',
}

I.Settings.registerGroup {
    key = 'Settings' .. ModName .. 'Main',
    page = ModName,
    order = 0,
    l10n = ModName,
    name = 'MainGroupName',
    description = 'MainGroupDesc',
    permanentStorage = true,
    settings = {
        setting(
            'UIFramerate',
            'number',
            { integer = true, min = 1, max = 144 },
            'UIFramerateName',
            'UIFramerateDesc',
            60
        ),
        setting(
            'HUDWidth',
            'number',
            { integer = false, min = 0.01, max = 0.5 },
            'HUDWidthName',
            'HUDWidthDesc',
            0.15
        ),
        setting(
            'HUDAnchor',
            ---@diagnostic disable-next-line: param-type-mismatch
            'ScreenPosition',
            {},
            'HUDAnchorName',
            'HUDAnchorDesc',
            util.vector2(0, 1)
        ),
        setting(
            'HUDPos',
            ---@diagnostic disable-next-line: param-type-mismatch
            'ScreenPosition',
            {},
            'HUDPosName',
            'HUDPosDesc',
            util.vector2(0, 1)
        ),
        setting(
            'CompassPos',
            ---@diagnostic disable-next-line: param-type-mismatch
            'ScreenPosition',
            {},
            'CompassPosName',
            'CompassPosDesc',
            util.vector2(.5, .5)
        ),
        setting(
            'CompassColor',
            'color',
            {},
            'CompassColorName',
            'CompassColorDesc',
            util.color.hex('ffffff')
        ),
        setting(
            'CompassSize',
            'number',
            { integer = true, min = 16, max = 128 },
            'CompassSizeName',
            'CompassSizeDesc',
            48
        ),
        setting(
            'CompassStyle',
            'select',
            { items = { 'Moon and Star', 'Redguard', 'Redguard Mono', }, l10n = ModName },
            'CompassStyleName',
            'CompassStyleDesc',
            'Redguard'
        ),
        setting(
            'ThumbStat',
            'select',
            { l10n = ModName, items = statNames },
            'ThumbStatName',
            'ThumbStatDesc',
            'fatigue'
        ),
        setting(
            'MiddleStat',
            'select',
            { l10n = ModName, items = statNames },
            'MiddleStatName',
            'MiddleStatDesc',
            'health'
        ),
        setting(
            'PinkyStat',
            'select',
            { l10n = ModName, items = statNames },
            'PinkyStatName',
            'PinkyStatDesc',
            'magicka'
        ),
        setting(
            'magickaColor',
            'color',
            {},
            'MagickaColorName',
            'MagickaColorDesc',
            colorFromGMST('FontColor_color_magic')
        ),
        setting(
            'healthColor',
            'color',
            {},
            'HealthColorName',
            'HealthColorDesc',
            colorFromGMST('FontColor_color_health')
        ),
        setting(
            'fatigueColor',
            'color',
            {},
            'FatigueColorName',
            'FatigueColorDesc',
            colorFromGMST('FontColor_color_fatigue')
        ),
        setting(
            'DurabilityColor',
            'color',
            {},
            'DurabilityColorName',
            'DurabilityColorDesc',
            colorFromGMST('FontColor_color_weapon_fill')
        ),
        setting(
            'CastChanceColor',
            'color',
            {},
            'CastChanceColorName',
            'CastChanceColorDesc',
            colorFromGMST('FontColor_color_magic_fill')
        ),
    }
}
