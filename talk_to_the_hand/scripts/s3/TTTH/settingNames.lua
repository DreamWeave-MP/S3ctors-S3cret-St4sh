local async = require 'openmw.async'
local core = require 'openmw.core'
local self = require 'openmw.self'
local util = require 'openmw.util'

---@type H4ND
local H4ND,
H4ndStorage,
CastableIndicator,
Compass,
Core,
EffectBar,
Middle,
Pinky,
Thumb,
WeaponIndicator

local statSettingNames = {
    MiddleStat = true,
    PinkyStat = true,
    ThumbStat = true,
}

---@param atlasName string
---@param atlas ImageAtlas
---@param settingName string
---@param settingValue string
local function updateAtlas(atlasName, atlas, settingName, settingValue)
    atlas.element.layout.props.color = H4ND.getColorForElement(atlasName)
    atlas.element:update()

    if not statSettingNames[settingName] then return end

    local statToUpdate, usedAttributes = nil, {
        magicka = true,
        health = true,
        fatigue = true,
    }

    local thisAtlas = H4ND.getStatAtlas(settingName)

    for elementName, statName in pairs {
        Pinky = H4ND.PinkyStat,
        Thumb = H4ND.ThumbStat,
        Middle = H4ND.MiddleStat,
    } do
        usedAttributes[statName] = nil

        if statName == settingValue and H4ND.getElementByName(elementName) ~= thisAtlas then
            atlasName = elementName
        end
    end

    statToUpdate = next(usedAttributes)

    if not statToUpdate then return end

    self:sendEvent('H4NDCorrectSecondAttribute', {
        stat = statToUpdate,
        atlasName = atlasName,
    })
end

local function colorUpdater(key, value)
    local statName, atlas, atlasName = key:gsub('Color$', '')

    atlas, atlasName = H4ND.getAtlasByStatName(statName)
    assert(atlas and atlasName)

    updateAtlas(atlasName, atlas, key, value)
end

local function fadeUpdater(key, _)
    if Core.layout.props.alpha ~= 1.0 then Core.layout.props.alpha = 1.0 end
    Core:update()
    H4ND.state.lastUpdateTime = core.getRealTime()
end

---@class H4NDSettingNames
local SettingNames = {
    CompassSize = function(_, value)
        Compass.layout.props.size = util.vector2(value, value)
        Compass:update()
    end,
    CompassPos = function(_, value)
        Compass.layout.props.relativePosition = value
        Compass:update()
    end,
    CompassColor = function(_, value)
        Compass.layout.props.color = value
        Compass:update()
    end,
    CompassStyle = function(_, _)
        self:sendEvent('H4NDUpdateCompassStyle')
    end,
    H4NDAnchor = function(_, value)
        Core.layout.props.anchor = value
        Core:update()
    end,
    H4NDPos = function(_, value)
        Core.layout.props.relativePosition = value
        Core:update()
    end,
    H4NDWidth = function(_, _)
        H4ND.resize()
        Core:update()
    end,
    fatigueColor = colorUpdater,
    healthColor = colorUpdater,
    magickaColor = colorUpdater,
    EffectBarAnchor = function(_, value)
        EffectBar.layout.props.anchor = value
        EffectBar:update()
    end,
    EffectBarSize = function(_, value)
        EffectBar.layout.props.relativeSize = value
        EffectBar:update()
    end,
    EffectBarPos = function(_, value)
        EffectBar.layout.props.relativePosition = value
        EffectBar:update()
    end,
    FadeStep = fadeUpdater,
    FadeTime = fadeUpdater,
    UseFade = fadeUpdater,
    WeaponIndicatorAnchor = function(_, value)
        WeaponIndicator.layout.props.anchor = value
        WeaponIndicator:update()
    end,
    WeaponIndicatorSize = function(_, value)
        WeaponIndicator.layout.props.relativeSize = util.vector2(value, value)
        WeaponIndicator:update()
    end,
    WeaponIndicatorPos = function(_, value)
        WeaponIndicator.layout.props.relativePosition = value
        WeaponIndicator:update()
    end,
    CastableIndicatorAnchor = function(_, value)
        CastableIndicator.layout.props.anchor = value
        CastableIndicator:update()
    end,
    CastableIndicatorSize = function(_, value)
        CastableIndicator.layout.props.relativeSize = util.vector2(value, value)
        CastableIndicator:update()
    end,
    CastableIndicatorPos = function(_, value)
        CastableIndicator.layout.props.relativePosition = value
        CastableIndicator:update()
    end,
    MiddleStat = function(key, value)
        updateAtlas('Middle', Middle, key, value)
    end,
    PinkyStat = function(key, value)
        updateAtlas('Pinky', Pinky, key, value)
    end,
    ThumbStat = function(key, value)
        updateAtlas('Thumb', Thumb, key, value)
    end,
    UIDebug = function(_, value)
        Core.layout.content.DebugContent.props.visible = value
        Core:update()

        EffectBar.layout.content.DebugContent.props.visible = value
        EffectBar:update()

        WeaponIndicator.layout.content.DebugContent.props.visible = value
        WeaponIndicator:update()

        CastableIndicator.layout.content.DebugContent.props.visible = value
        CastableIndicator:update()

        Compass.layout.content.DebugContent.props.visible = value
        Compass:update()
    end,
    UIFramerate = function(_, _)
        H4ND.updateUIFramerate()
    end,
}

local function h4ndSubscriber(_, key)
    local value = H4ndStorage:get(key)

    local settingHandler = SettingNames[key]
    if not settingHandler then return end

    settingHandler(key, value)
end

---@param h4nd H4ND
---@param h4ndStorage userdata
return function(h4nd, h4ndStorage)
    assert(h4nd)
    H4ND = h4nd
    CastableIndicator = H4ND.getElementByName('CastableIndicator')
    Compass = H4ND.getElementByName('Compass')
    Core = H4ND.getElementByName('Core')
    EffectBar = H4ND.getElementByName('EffectBar')
    Middle = H4ND.getElementByName('Middle')
    Pinky = H4ND.getElementByName('Pinky')
    Thumb = H4ND.getElementByName('Thumb')
    WeaponIndicator = H4ND.getElementByName('WeaponIndicator')
    H4ndStorage = h4ndStorage

    H4ndStorage:subscribe(async:callback(h4ndSubscriber))
    H4ND.updateUIFramerate()
end
