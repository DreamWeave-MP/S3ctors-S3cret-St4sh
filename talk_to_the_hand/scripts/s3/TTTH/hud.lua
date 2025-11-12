local async = require 'openmw.async'
local core = require 'openmw.core'
local storage = require 'openmw.storage'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local HudCore,
WeaponIndicator,
ThumbAtlas,
MiddleAtlas,
PinkyAtlas,
TotalDelay,
CurrentDelay

local H4ndStorage = storage.playerSection('SettingsTalkToTheHandMain')
---@class H4ND: ProtectedTable
---@field UIFramerate integer
---@field HUDWidth number
---@field HUDPos util.vector2
---@field ThumbStat string
---@field PinkyStat string
---@field MiddleStat string
---@field fatigueColor util.color
---@field magickaColor util.color
---@field healthColor util.color
---@field DurabilityColor util.color
---@field CastChanceColor util.color
local H4ND = I.S3ProtectedTable.new {
    storageSection = H4ndStorage,
    logPrefix = '[H4ND]:',
    subscribeHandler = false,
}

local function getSelectedWeaponIcon()
    local weapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
    if not weapon then
        return core.stats.Skill.records.handtohand.icon
    end

    return weapon.type.records[weapon.recordId].icon
end

---@param statName string name of a dynamic stat
local function getStatFrame(statName)
    local stat = I.s3lf[statName]
    local normalized = util.clamp(stat.current / stat.base, 0.0, 1.0)
    local difference = 1.0 - normalized
    return math.max(1, math.floor(difference * 100))
end

---@param atlasName string
local function getAtlasTargetTile(atlasName)
    local statName = H4ND[atlasName .. 'Stat']
    return getStatFrame(statName)
end

---@param elementName string
local function getColorForElement(elementName)
    local settingName = elementName .. 'Stat'
    local stat = H4ND[settingName]

    return H4ND[stat .. 'Color']
end

---@param atlasName string
---@param atlas ImageAtlas
local function updateAtlas(atlasName, atlas)
    local targetTile = getAtlasTargetTile(atlasName)
    if atlas.currentTile == targetTile then return end

    atlas:cycleFrame(atlas.currentTile < targetTile)
end

local screenSize = ui.screenSize()

local Vectors = {
    BottomLeft = util.vector2(0, 1),
    Center = util.vector2(.5, .5),
    LeftCenter = util.vector2(0, .5),
    RelativeHandSize = util.vector2(H4ND.HUDWidth, H4ND.HUDWidth * 2),
    Zero = util.vector2(0, 0),
    Tiles = {
        Pinky = util.vector2(128, 256),
        Middle = util.vector2(256, 512),
        Thumb = util.vector2(278, 271),
    },
    TopRight = util.vector2(1, 0),
}

local handSize = screenSize:emul(Vectors.RelativeHandSize)

--- Table mapping X pixel length to Y pixel length
local Ratio = {
    UL = 1.3475177305,
    UR = 1.37795275591,
    Pinky = 2.0,
    Middle = 1.37,
    Thumb = 0.974820143885,
}

local Width = {
    UL = 1 / 6,
    Pinky = function()
        return handSize.x * .275
    end,
    Middle = function()
        return handSize.x * .55
    end,
    Thumb = function()
        return handSize.x * .625
    end,
}

local Attrs = {
    ChanceBar = function()
        return util.vector2(handSize.x * .2, handSize.x * 0.02)
    end,
    EffectBar = function()
        return util.vector2(handSize.x, handSize.y * 0.1)
    end,
    Middle = function()
        local width = Width.Middle()
        return util.vector2(width, width * Ratio.Middle), util.vector2(handSize.x * .255, handSize.y * 0.015)
    end,
    Pinky = function()
        local width = Width.Pinky()
        return util.vector2(width, width * Ratio.Pinky), util.vector2(handSize.x * .64, handSize.y * .235)
    end,
    SubIcon = function()
        return util.vector2(handSize.x * .2, handSize.x * .2)
    end,
    Thumb = function()
        local width = Width.Thumb()
        return util.vector2(width, width * Ratio.Thumb), util.vector2(handSize.x * .075, handSize.y * .35)
    end,
    Weapon = function()
        return util.vector2(handSize.x * .025, handSize.y * .15)
    end,
}

PinkyAtlas = I.S3AtlasConstructor.constructAtlas {
    tileSize = Vectors.Tiles.Pinky,
    tilesPerRow = 10,
    totalTiles = 100,
    atlasPath = 'textures/s3/chim/tribunalpinky.dds'
}

MiddleAtlas = I.S3AtlasConstructor.constructAtlas {
    tileSize = Vectors.Tiles.Middle,
    tilesPerRow = 10,
    totalTiles = 100,
    atlasPath = 'textures/s3/chim/tribunalmiddle.dds'
}

ThumbAtlas = I.S3AtlasConstructor.constructAtlas {
    tileSize = Vectors.Tiles.Thumb,
    tilesPerRow = 10,
    totalTiles = 100,
    atlasPath = 'textures/s3/chim/tribunalthumb.dds'
}

local ThumbSize, ThumbPos = Attrs.Thumb()
ThumbAtlas:spawn {
    color = getColorForElement('Thumb'),
    name = 'Thumb',
    size = ThumbSize,
    position = ThumbPos,
}

local middleSize, middlePos = Attrs.Middle()
MiddleAtlas:spawn {
    color = getColorForElement('Middle'),
    name = 'Middle',
    size = middleSize,
    position = middlePos,
}

local pinkySize, pinkyPos = Attrs.Pinky()
PinkyAtlas:spawn {
    color = getColorForElement('Pinky'),
    name = 'Pinky',
    size = pinkySize,
    position = pinkyPos,
}

HudCore = ui.create {
    layer = 'HUD',
    name = 'H4ND',
    props = {
        size = handSize,
        anchor = Vectors.BottomLeft,
        relativePosition = H4ND.HUDPos,
    },
    content = ui.content {
        ThumbAtlas.element,
        MiddleAtlas.element,
        PinkyAtlas.element,
        {
            type = ui.TYPE.Flex,
            name = 'WeaponIndicator',
            props = {
                position = Attrs.Weapon(),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    name = 'WeaponIcon',
                    props = {
                        resource = ui.texture { path = getSelectedWeaponIcon() },
                        size = Attrs.SubIcon(),
                    }
                },
                {
                    type = ui.TYPE.Image,
                    name = 'DurabilityBar',
                    props = {
                        resource = ui.texture { path = 'white' },
                        size = Attrs.ChanceBar(),
                        color = H4ND.DurabilityColor,
                    },
                },
            }
        },
        {
            type = ui.TYPE.Image,
            name = 'EffectBar',
            props = {
                resource = ui.texture { path = 'white', },
                size = Attrs.EffectBar(),
                color = util.color.hex('ff0abb'),
                anchor = Vectors.BottomLeft,
                relativePosition = Vectors.BottomLeft,
            }
        },
        {
            type = ui.TYPE.Flex,
            name = 'CastableIndicator',
            props = {
                anchor = Vectors.TopRight,
                relativePosition = Vectors.TopRight + util.vector2(-.02, .03),
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    name = 'CastableIcon',
                    props = {
                        resource = ui.texture { path = getSelectedWeaponIcon() },
                        size = Attrs.SubIcon(),
                    }
                },
                {
                    type = ui.TYPE.Image,
                    name = 'CastChanceBar',
                    props = {
                        resource = ui.texture { path = 'white' },
                        size = Attrs.ChanceBar(),
                        color = H4ND.CastChanceColor,
                    },
                },
            }
        }
    }
}

local function updateStatFrames()
    if not HudCore then return end

    for elementName, atlas in pairs {
        Thumb = ThumbAtlas,
        Middle = MiddleAtlas,
        Pinky = PinkyAtlas,
    } do
        updateAtlas(elementName, atlas)
    end
end

local namesToAtlases, statsToAtlases = {
    Middle = MiddleAtlas,
    Pinky = PinkyAtlas,
    Thumb = ThumbAtlas,
    EffectBar = HudCore.layout.content.EffectBar,
    WeaponIndicator = HudCore.layout.content.WeaponIndicator,
    CastableIndicator = HudCore.layout.content.CastableIndicator,
}, {
    MiddleStat = MiddleAtlas,
    PinkyStat = PinkyAtlas,
    ThumbStat = ThumbAtlas
}

H4ndStorage:subscribe(
    async:callback(
        function(_, key)
            local atlasName, atlas
            if key == 'ThumbColor' or key == 'ThumbStat' then
                atlasName, atlas = 'Thumb', ThumbAtlas
            elseif key == 'MiddleColor' or key == 'MiddleStat' then
                atlasName, atlas = 'Middle', MiddleAtlas
            elseif key == 'PinkyColor' or key == 'PinkyStat' then
                atlasName, atlas = 'Pinky', PinkyAtlas
            elseif key == 'HUDPos' or key == 'HUDWidth' then
                if key == 'HUDWidth' then
                    local width = H4ndStorage:get('HUDWidth')
                    local relativeSize = util.vector2(width, width * 2)

                    handSize = ui.screenSize():emul(relativeSize)
                    HudCore.layout.props.size = handSize

                    for attrFunc, resizeAtlas in pairs {
                        [Attrs.Thumb] = ThumbAtlas,
                        [Attrs.Middle] = MiddleAtlas,
                        [Attrs.Pinky] = PinkyAtlas,
                    } do
                        local props = resizeAtlas.element.layout.props
                        props.size, props.position = attrFunc()
                        resizeAtlas.element:update()
                    end

                    namesToAtlases.EffectBar.props.size = Attrs.EffectBar()

                    local castable = namesToAtlases.CastableIndicator.content
                    castable.CastableIcon.props.size = Attrs.SubIcon()
                    castable.CastChanceBar.props.size = Attrs.ChanceBar()

                    local weapon = namesToAtlases.WeaponIndicator
                    weapon.props.position = Attrs.Weapon()
                    weapon.content.WeaponIcon.props.size = Attrs.SubIcon()
                    weapon.content.DurabilityBar.props.size = Attrs.ChanceBar()
                elseif key == 'HUDPos' then
                    HudCore.layout.props.relativePosition = H4ndStorage:get('HUDPos')
                end

                HudCore:update()
            elseif key == 'UIFramerate' then
                TotalDelay = 1 / H4ndStorage:get('UIFramerate')
            end

            if atlasName and atlas then
                atlas.element.layout.props.color = getColorForElement(atlasName)
                atlas.element:update()

                if key == 'PinkyStat' or key == 'MiddleStat' or key == 'ThumbStat' then
                    local statToUpdate, usedAttributes = nil, {
                        magicka = true,
                        health = true,
                        fatigue = true,
                    }

                    local thisAtlas = statsToAtlases[key]

                    local invalidStat = H4ndStorage:get(key)

                    for elementName, statName in pairs {
                        Pinky = H4ND.PinkyStat,
                        Thumb = H4ND.ThumbStat,
                        Middle = H4ND.MiddleStat,
                    } do
                        usedAttributes[statName] = nil

                        if statName == invalidStat and namesToAtlases[elementName] ~= thisAtlas then
                            atlasName = elementName
                        end
                    end

                    statToUpdate = next(usedAttributes)

                    if not statToUpdate then return end

                    s3lf.gameObject:sendEvent('H4NDCorrectSecondAttribute', {
                        stat = statToUpdate,
                        atlasName = atlasName,
                    })
                end
            end
        end
    )
)

CurrentDelay, TotalDelay = 0, 1 / H4ND.UIFramerate
return {
    interfaceName = 'H4nd',
    interface = {
        HUD = function()
            return HudCore
        end,
    },
    eventHandlers = {
        H4NDCorrectSecondAttribute = function(atlasData)
            local stat, atlasName = atlasData.stat, atlasData.atlasName
            H4ND[atlasName .. 'Stat'] = stat
            namesToAtlases[atlasName].element:update()
        end,
    },
    engineHandlers = {
        onFrame = function(dt)
            if CurrentDelay < TotalDelay then
                CurrentDelay = CurrentDelay + dt
                return
            else
                CurrentDelay = 0
            end

            updateStatFrames()
        end,
    }
}
