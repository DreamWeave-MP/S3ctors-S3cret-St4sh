local async = require 'openmw.async'
local core = require 'openmw.core'
local input = require 'openmw.input'
local storage = require 'openmw.storage'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

---@type H4NDConstants
local Constants = require 'scripts.s3.TTTH.constants'
local Attrs, Colors, Vectors = Constants.Attrs, Constants.Colors, Constants.Vectors

--- setting to disable compass entirely
--- notifier box
---
local Magic = require 'scripts.s3.spellUtil'

local HudCore,
Compass,
ThumbAtlas,
MiddleAtlas,
PinkyAtlas,
CompassAtlas,
CastableIndicator,
WeaponIndicator,
EffectBar,
TotalDelay,
CurrentDelay

---@alias H4NDCompassStyle
---| 'Moon and Star'
---| 'Redguard'
---| 'Redguard Mono'

local H4ndStorage = storage.playerSection('SettingsTalkToTheHandMain')
---@class H4ND: ProtectedTable
---@field UIFramerate integer
---@field H4NDWidth number
---@field H4NDPos util.vector2
---@field H4NDAnchor util.vector2
---@field ThumbStat string
---@field PinkyStat string
---@field MiddleStat string
---@field fatigueColor util.color
---@field magickaColor util.color
---@field healthColor util.color
---@field DurabilityColor util.color
---@field CastChanceColor util.color
---@field CompassColor util.color
---@field CompassSize integer
---@field CompassPos util.vector2
---@field CompassStyle H4NDCompassStyle
---@field UseFade boolean
---@field FadeTime number
---@field FadeStep number
---@field UIDebug boolean
---@field EffectsPerRow integer
local H4ND = I.S3ProtectedTable.new {
    storageSection = H4ndStorage,
    logPrefix = '[H4ND]:',
    subscribeHandler = false,
}
H4ND.state = {
    equippedWeapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight),
    equippedCastable = s3lf.getSelectedSpell() or s3lf.getSelectedEnchantedItem(),
    lastUpdateTime = core.getRealTime(),
    currentScreenSize = ui.screenSize(),
}

function H4ND.updateUIFramerate()
    TotalDelay = 1 / H4ND.UIFramerate
end

function H4ND.resize()
    H4ND.updateTime()
    local hudProps = HudCore.layout.props
    hudProps.relativeSize, hudProps.alpha = H4ND.getHandSize(), 1.
    HudCore:update()
end

function H4ND.getUIScalingFactor()
    local result = ui.screenSize():ediv(ui.layers[1].size)
    assert(result.x == result.y)
    return result.x
end

local HUD_RATIO = 1.125
function H4ND.getHandSize()
    local targetWidth, screenSize = H4ND.H4NDWidth, ui.screenSize()
    local xResolution = screenSize.x * targetWidth
    local yResolution = xResolution * HUD_RATIO
    local targetHeight = yResolution / screenSize.y

    return util.vector2(targetWidth, targetHeight)
end

---@param statName string
---@return ImageAtlas?
function H4ND.getStatAtlas(statName)
    return ({
        MiddleStat = MiddleAtlas,
        PinkyStat = PinkyAtlas,
        ThumbStat = ThumbAtlas
    })[statName]
end

---@alias DynamicStatName
---| 'fatigue'
---| 'health'
---| 'magicka'

---@param statName DynamicStatName
---@return ImageAtlas atlas, string atlasName
function H4ND.getAtlasByStatName(statName)
    for atlasStat, atlas in pairs {
        MiddleStat = { MiddleAtlas, 'Middle' },
        PinkyStat = { PinkyAtlas, 'Pinky' },
        ThumbStat = { ThumbAtlas, 'Thumb' },
    } do
        ---@diagnostic disable-next-line: redundant-return-value, return-type-mismatch
        if H4ND[atlasStat] == statName then return table.unpack(atlas) end
    end

    error('Invalid atlas name provided: ' .. statName)
end

---@param elementName string
---@return userdata|ImageAtlas|nil handElement
function H4ND.getElementByName(elementName)
    return ({
        Compass = Compass,
        Core = HudCore,
        Middle = MiddleAtlas,
        Pinky = PinkyAtlas,
        Thumb = ThumbAtlas,
        EffectBar = EffectBar,
        WeaponIndicator = WeaponIndicator,
        CastableIndicator = CastableIndicator,
    })[elementName]
end

function H4ND:getCompassPath()
    return ('textures/s3/TTTH/compass/%s.dds'):format(self.CompassStyle)
end

---@class EffectManager
local EffectBarManager = {
    effectIndices = {},
    schoolIndices = {
        alteration = 1,
        conjuration = 2,
        destruction = 3,
        illusion = 4,
        mysticism = 5,
        restoration = 6,
    },
}

do
    local totalEffectIndex = 1
    for _, effect in pairs(core.magic.effects.records) do
        EffectBarManager.effectIndices[effect.id] = totalEffectIndex
        totalEffectIndex = totalEffectIndex + 1
    end
end

--- Used to sort arrays of magic effect ids
---@param effectA MagicEffectWithParams
---@param effectB MagicEffectWithParams
---@return boolean
function EffectBarManager.effectSort(effectA, effectB)
    local magicEffects = core.magic.effects.records
    local schoolA, schoolB = magicEffects[effectA.id].school, magicEffects[effectB.id].school
    local schools, effects = EffectBarManager.schoolIndices, EffectBarManager.effectIndices

    if schoolA ~= schoolB then
        return schools[schoolA] < schools[schoolB]
    else
        return effects[effectA.id] < effects[effectB.id]
    end
end

---@return table<string, MagicEffectWithParams>
function EffectBarManager:getActiveEffectIds()
    local activeEffects, foundEffects = {}, {}

    for _, spell in pairs(s3lf.activeSpells()) do
        ---@cast spell Spell
        for _, effect in ipairs(spell.effects) do
            local storedEffect = foundEffects[effect.id]

            if not storedEffect or (storedEffect.durationLeft or math.huge) < (effect.durationLeft or math.huge) then
                foundEffects[effect.id] = effect
            end
        end
    end

    local effectIndex = 1
    for _, effect in pairs(foundEffects) do
        activeEffects[effectIndex] = effect
        effectIndex = effectIndex + 1
    end

    table.sort(activeEffects, self.effectSort)

    return activeEffects
end

---@param effectName string
---@param effectIcon string
function EffectBarManager.getEffectImage(effectName, effectIcon, alpha)
    return {
        type = ui.TYPE.Image,
        name = effectName,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = util.vector2(1 / H4ND.EffectsPerRow, 1),
            anchor = Constants.Vectors.BottomRight,
            resource = ui.texture { path = effectIcon },
            alpha = alpha,
        },
    }
end

---@param rowNum number of currently-constructed row
---@param totalRows number total number of rows, for calculating size
function EffectBarManager.effectRow(rowNum, totalRows)
    return {
        type = ui.TYPE.Flex,
        name = 'EffectRow' .. tostring(rowNum),
        props = {
            horizontal = true,
            align = ui.ALIGNMENT[H4ND.EffectAlign],
            relativeSize = util.vector2(1, 1 / totalRows),
            autoSize = false,
        },
        external = {
            grow = 1,
        },
        content = {},
    }
end

function EffectBarManager:constructEffectImages()
    local effects = self:getActiveEffectIds()

    local currentRowNum, totalRows = 1, math.max(1, math.floor(#effects / H4ND.EffectsPerRow + .5))

    local allRows, currentRow, rowEffects = {}, self.effectRow(currentRowNum, totalRows), 0

    for _, magicEffect in ipairs(effects) do
        if rowEffects == H4ND.EffectsPerRow then
            currentRow.content = ui.content(currentRow.content)

            allRows[#allRows + 1] = currentRow

            currentRowNum, rowEffects = currentRowNum + 1, 0
            currentRow = self.effectRow(currentRowNum, totalRows)
        end

        local effectIcon = core.magic.effects.records[magicEffect.id].icon
        local alpha = util.clamp((magicEffect.durationLeft or 1) / (magicEffect.duration or 1), .0, 1.)

        rowEffects = rowEffects + 1
        currentRow.content[rowEffects] = self.getEffectImage(magicEffect.id, effectIcon, alpha)
    end

    if currentRow ~= {} then
        currentRow.content = ui.content(currentRow.content)
        allRows[#allRows + 1] = currentRow
    end

    if H4ND.UIDebug and EffectBar then
        allRows[#allRows + 1] = {
            type = ui.TYPE.Image,
            name = 'DebugContent',
            props = {
                relativeSize = Constants.Vectors.BottomRight,
                color = util.color.hex('ffaa0b'),
                resource = ui.texture { path = 'white' },
            },
        }
    end
    local content = ui.content(allRows)

    if EffectBar then
        EffectBar.layout.content = content
        EffectBar:update()
    else
        EffectBar = ui.create {
            type = ui.TYPE.Flex,
            name = 'EffectBar',
            layer = 'Windows',
            props = {
                autoSize = false,
                relativeSize = H4ND.EffectBarSize,
                anchor = H4ND.EffectBarAnchor,
                relativePosition = H4ND.EffectBarPos,
            },
            content = content,
            events = H4ND.dragEvents('EffectBar')
        }
    end
end

---@param item GameObject
local function getItemIcon(item)
    return item.type.records[item.recordId].icon
end

local function getSelectedWeaponIcon()
    local weapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
    if not weapon then
        return core.stats.Skill.records.handtohand.icon
    end

    return getItemIcon(weapon)
end

---@return string? path to icon for the currently-selected castable
local function getCastableIcon()
    local enchantedItem = s3lf.getSelectedEnchantedItem()
    if enchantedItem then return getItemIcon(enchantedItem) end

    local selectedSpell = s3lf.getSelectedSpell()
    if not selectedSpell then return end

    return selectedSpell.effects[1].effect.icon
end

---@return number relative width of the castable item
function H4ND.getCastableWidth()
    local enchantedItem = s3lf.getSelectedEnchantedItem()
    if enchantedItem then
        local enchantId = enchantedItem.type.records[enchantedItem.recordId].enchant
        local enchantRecord = core.magic.enchantments.records[enchantId]

        local totalCharge = Magic.getEnchantmentCharge(enchantRecord)
        local currentCharge = enchantedItem.type.itemData(enchantedItem).enchantmentCharge

        return currentCharge / totalCharge
    end

    local selectedSpell = s3lf.getSelectedSpell()
    if not selectedSpell then return 0.0 end

    local chance, _ = Magic:getSpellCastChance(selectedSpell, s3lf.gameObject, true, true)

    return chance / 100
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
function H4ND.getColorForElement(elementName)
    local settingName = elementName .. 'Stat'
    local stat = H4ND[settingName]

    return H4ND[stat .. 'Color']
end

function H4ND.updateTime()
    H4ND.state.lastUpdateTime = core.getRealTime()
end

---@param atlasName string
---@param atlas ImageAtlas
local function updateAtlas(atlasName, atlas)
    local targetTile = getAtlasTargetTile(atlasName)
    if atlas.currentTile == targetTile then return end

    atlas:cycleFrame(atlas.currentTile < targetTile)
    H4ND.updateTime()
end

---@return GameObject? weapon
local function getWeapon()
    return s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
end

---@param weapon GameObject?
---@return boolean
local function weaponIsEnchanted(weapon)
    if not weapon then return false end
    return weapon.type.records[weapon.recordId].enchant ~= nil
end

function H4ND.normalizedWeaponHealth()
    local weapon, mult = getWeapon(), 0.0

    if weapon then
        mult = weapon.type.itemData(weapon).condition / weapon.type.records[weapon.recordId].health
    end

    return mult
end

---@return boolean
local function updateWeaponIcon()
    local currentWeapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight)
    if H4ND.state.equippedWeapon == currentWeapon then return false end
    H4ND.state.equippedWeapon = currentWeapon
    s3lf.gameObject:sendEvent('H4NDUpdateWeapon')
    return true
end

---@return boolean
local function updateWeaponDurability()
    local baseWidth = math.floor(H4ND.normalizedWeaponHealth() * 100)
    local currentWidth = math.floor(WeaponIndicator
        .layout
        .content
        .DurabilityBarContainer
        .content
        .DurabilityBar
        .props
        .relativeSize
        .x) * 100

    if baseWidth == currentWidth then return false end

    s3lf.gameObject:sendEvent('H4NDUpdateDurability')
    return true
end

---@return boolean
local function updateCastableIcon()
    local currentCastable = Magic.getCastable(s3lf.gameObject)

    local checkCastable = currentCastable and currentCastable.id or nil
    local lastCastable = H4ND.state.equippedCastable and H4ND.state.equippedCastable.id or nil
    if checkCastable == lastCastable then return false end

    H4ND.state.equippedCastable = currentCastable
    s3lf.gameObject:sendEvent('H4NDUpdateCastable')
    return true
end

---@return boolean
local function updateCastableBar()
    local targetWidth = math.floor(100 * H4ND.getCastableWidth())

    local currentWidth = math.floor(CastableIndicator
        .layout
        .content
        .CastChanceContainer
        .content
        .CastChanceBar
        .props
        .relativeSize
        .x) * 100

    if currentWidth == targetWidth then return false end

    s3lf.gameObject:sendEvent('H4NDUpdateCastableBar')
    return true
end

local function updateDurabilityBarSize()
    WeaponIndicator
    .layout
    .content
    .DurabilityBarContainer
    .content
    .DurabilityBar
    .props
    .relativeSize =
        util.vector2(H4ND.normalizedWeaponHealth(), 1)
end

local function handleFade()
    local HudProps, CompassProps = HudCore.layout.props, Compass.layout.props
    local hudVisible = I.UI.isHudVisible()
    local hudIsStale = core.getRealTime() - H4ND.state.lastUpdateTime >= H4ND.FadeTime
    local fadeIn = HudProps.alpha ~= 1. and not hudIsStale

    local step

    if not hudVisible and CompassProps.alpha > 0. then
        CompassProps.alpha = math.max(CompassProps.alpha - H4ND.FadeStep, .0)
        Compass:update()
    elseif hudVisible and CompassProps.alpha ~= 1. then
        CompassProps.alpha = math.min(CompassProps.alpha + H4ND.FadeStep, 1.)
        Compass:update()
    end

    if ((hudIsStale and H4ND.UseFade) or not hudVisible) and HudProps.alpha > .0 then
        step = math.max(HudProps.alpha - H4ND.FadeStep, .0)

        HudProps.alpha = step
    elseif (fadeIn or hudVisible) and HudProps.alpha ~= 1. then
        step = math.min(1., HudProps.alpha + H4ND.FadeStep)
        HudProps.alpha = step

        if HudProps.alpha == 1. then
            H4ND.updateTime()
        end
    else
        return
    end

    HudCore:update()
end

local function adjustedYaw()
    local yaw = math.deg(s3lf.rotation:getYaw())

    if yaw < 0 then yaw = util.remap(yaw, -180, 0, 181, 360) end

    return util.clamp(util.round(yaw), 1, 360)
end

local function updateCompass()
    local currentTile = adjustedYaw()
    if currentTile == CompassAtlas.currentTile then return end

    CompassAtlas.currentTile = currentTile
    Compass.layout.props.resource = CompassAtlas.textureArray[currentTile]
    Compass:update()
end

---@return ImageAtlas
local function respawnCompassAtlas()
    return I.S3AtlasConstructor.constructAtlas {
        tileSize = Constants.Vectors.Tiles.Compass,
        tilesPerRow = 30,
        totalTiles = 360,
        atlasPath = H4ND:getCompassPath(),
    }
end

local function getCompassAnchor()
    local anchor = Constants.Vectors.Center

    if H4ND.CompassStyle == 'Moon and Star' then
        anchor = anchor + Constants.Vectors.Tiles.MoonAndStarAdjust
    end

    return anchor
end

---@class UITil
local Uitil = {}

--- Given a mouseEvent.offset and the clicked layout, figure out the relative position based on the offset
function Uitil.relativeClickPos(offsetPos, layout)
    local props = layout.props
    local elementTotalSize = props.size or props.relativeSize:emul(ui.screenSize())
    return offsetPos:ediv(elementTotalSize)
end

--- Used for resizing elements. Resizing without making positions go
--- all fucked off and cattywompus necessitates mirroring the anchor into the opposite position
--- for convenience's sake, we also return the relativeClickPos here since it's needed
function Uitil.getOppositeAnchor(offsetPos, layout)
    local relativeClickPos = Uitil.relativeClickPos(offsetPos, layout)
    return Constants.Vectors.BottomRight - relativeClickPos, relativeClickPos
end

--- Determines if a click occurred on the edge of an element or not.
--- Feed the params of a mousePress/Click event directly into `Uiti.relativeClickPos`, then into this.
--- Usage: Uitil.didClickEdge(Uitil.relativeClickPos(mouseEvent.offset, layout))
---@param relativeClickPos util.vector2
---@return boolean
function Uitil.didClickEdge(relativeClickPos)
    local edgeThreshold = 0.025
    local isLeftEdge = relativeClickPos.x < edgeThreshold
    local isRightEdge = relativeClickPos.x > (1 - edgeThreshold)
    local isTopEdge = relativeClickPos.y < edgeThreshold
    local isBottomEdge = relativeClickPos.y > (1 - edgeThreshold)

    return isLeftEdge or isRightEdge or isTopEdge or isBottomEdge
end

local AlignmentCycle = {
    Center = 'End',
    End = 'Start',
    Start = 'Center'
}

function H4ND.dragEvents(elementName)
    return {
        mousePress = async:callback(function(mouseEvent, layout)
            if not layout.userdata then layout.userdata = {} end
            local element = H4ND.getElementByName(elementName)
            assert(element)

            layout.userdata.doDrag = true
            layout.userdata.lastPos = mouseEvent.position

            local newAnchor, relativeClickPos = Uitil.getOppositeAnchor(mouseEvent.offset, layout)
            local relativeSize = layout.props.relativeSize or layout.props.size:ediv(ui.screenSize())

            if not Uitil.didClickEdge(relativeClickPos) and not input.isShiftPressed() then return end

            layout.userdata.scaleDrag = true
            if element == Compass then return end

            local anchorDiff = newAnchor - layout.props.anchor
            local name = layout.name

            H4ND[name .. 'Anchor'] = newAnchor
            H4ND[name .. 'Pos'] = layout.props.relativePosition + anchorDiff:emul(relativeSize)
        end),
        mouseMove = async:callback(function(mouseEvent, layout)
            if not layout.userdata or not layout.userdata.doDrag then return end

            local element, screenSize = H4ND.getElementByName(elementName), ui.screenSize()

            local delta = layout.userdata.lastPos - mouseEvent.position
            local relativeDelta = delta:ediv(screenSize)

            local scalar
            if layout.userdata.scaleDrag then
                scalar = layout.props.relativeSize or layout.props.size

                --- Mouse movements in either direction may not necessarily cause scaling to go in the direction we want,
                --- if the anchor's in some weird place
                --- So we have to invert the movement diretion depending on the orientation of the anchor
                local goLeft = layout.props.anchor.x <= .5
                local goDown = layout.props.anchor.y <= .5
                local width = goLeft and -relativeDelta.x or relativeDelta.x
                local height = goDown and -relativeDelta.y or relativeDelta.y

                relativeDelta = util.vector2(width, height)
            else
                scalar = layout.props.relativePosition
                relativeDelta = relativeDelta * -1
            end

            local newX, newY =
                util.clamp(scalar.x + relativeDelta.x, .0, 1.),
                util.clamp(scalar.y + relativeDelta.y, .0, 1.)

            local newValue = util.vector2(newX, newY)

            if layout.userdata.scaleDrag then
                local handler = H4ND.state.resizeHandlers[element]

                assert(
                    handler,
                    ('Failed to find matching resize handler for element: %s %s'):format(elementName, element)
                )

                ---@type ResizeHandler
                handler {
                    layout = layout,
                    absoluteDelta = delta,
                    resolvedDelta = newValue,
                }
            else
                local elementTotalSize = layout.props.size or layout.props.relativeSize:emul(screenSize)
                local anchorPos = layout.props.relativePosition:emul(screenSize)
                local topLeft = (anchorPos - (layout.props.anchor:emul(elementTotalSize))) + delta

                local leftEdge = topLeft.x <= 0.
                local rightEdge = (topLeft.x + elementTotalSize.x) > screenSize.x
                local topEdge = topLeft.y <= 0.
                local bottomEdge = (topLeft.y + elementTotalSize.y) > screenSize.y

                local currentPos, epsilon = layout.props.relativePosition, 0.001
                if leftEdge then
                    newValue = util.vector2(currentPos.x + epsilon, currentPos.y)
                elseif rightEdge then
                    newValue = util.vector2(currentPos.x - epsilon, currentPos.y)
                end

                if topEdge then
                    newValue = util.vector2(currentPos.x, currentPos.y + epsilon)
                elseif bottomEdge then
                    newValue = util.vector2(currentPos.x, currentPos.y - epsilon)
                end

                H4ND[layout.name .. 'Pos'] = newValue
            end

            layout.userdata.lastPos = mouseEvent.position
        end),
        mouseRelease = async:callback(function(mouseEvent, layout)
            if not layout.userdata or not layout.userdata.doDrag then return end
            layout.userdata.doDrag = false
            layout.userdata.scaleDrag = false
            layout.userdata.lastPos = mouseEvent.position
        end),
        focusLoss = async:callback(function(_, layout)
            if not layout.userdata or not layout.userdata.doDrag then return end
            layout.userdata.doDrag = false
            layout.userdata.scaleDrag = false
        end),
        mouseDoubleClick = async:callback(function(_, layout)
            local element = H4ND.getElementByName(elementName)
            if element ~= EffectBar then return end

            local currentSetting = H4ND.EffectAlign
            local newValue = AlignmentCycle[currentSetting]

            H4ND.EffectAlign = newValue
        end),
    }
end

CompassAtlas, ThumbAtlas, MiddleAtlas, PinkyAtlas = respawnCompassAtlas(), require 'scripts.s3.TTTH.atlasses' (
    Constants,
    H4ND.getColorForElement
)

local atlasMap = {
    Thumb = ThumbAtlas,
    Middle = MiddleAtlas,
    Pinky = PinkyAtlas,
}
local function updateStatFrames()
    if not HudCore then return end

    for elementName, atlas in pairs(atlasMap) do
        updateAtlas(elementName, atlas)
    end
end

local BarSize, castableIcon = Attrs.ChanceBar(), getCastableIcon()

CastableIndicator = require 'scripts.s3.TTTH.components.castableIndicator' {
    barColor = H4ND.CastChanceColor,
    castableIcon = castableIcon,
    castableWidth = H4ND.getCastableWidth(),
    Constants = Constants,
    dragEvents = H4ND.dragEvents('CastableIndicator'),
    useDebug = H4ND.UIDebug,
    H4ND = H4ND,
}

WeaponIndicator = require 'scripts.s3.TTTH.components.weaponIndicator' {
    barSize = BarSize,
    weaponHealth = H4ND.normalizedWeaponHealth(),
    durabilityColor = H4ND.DurabilityColor,
    enchantFrameVisible = weaponIsEnchanted(getWeapon()),
    weaponIcon = getSelectedWeaponIcon(),
    Constants = Constants,
    dragEvents = H4ND.dragEvents('WeaponIndicator'),
    useDebug = H4ND.UIDebug,
    H4ND = H4ND,
}

EffectBarManager:constructEffectImages()

HudCore = ui.create {
    layer = 'Windows',
    name = 'H4ND',
    props = {
        relativeSize = H4ND.getHandSize(),
        anchor = H4ND.H4NDAnchor,
        relativePosition = H4ND.H4NDPos,
        alpha = 1.0,
    },
    userdata = {},
    content = ui.content {
        {
            type = ui.TYPE.Image,
            name = 'DebugContent',
            props = {
                resource = ui.texture { path = 'white' },
                relativeSize = Constants.Vectors.BottomRight,
                color = util.color.hex('ff0000'),
                visible = H4ND.UIDebug,
            }
        },
        ThumbAtlas.element,
        MiddleAtlas.element,
        PinkyAtlas.element,
    },
    events = H4ND.dragEvents('Core')
}

Compass = ui.create {
    layer = 'Windows',
    name = 'Compass',
    type = ui.TYPE.Image,
    props = {
        relativePosition = H4ND.CompassPos,
        size = util.vector2(H4ND.CompassSize, H4ND.CompassSize),
        color = H4ND.CompassColor,
        resource = CompassAtlas.textureArray[adjustedYaw()],
        anchor = getCompassAnchor(),
        alpha = 1.,
    },
    events = H4ND.dragEvents('Compass'),
}

require 'scripts.s3.ttth.settingNames' (H4ND, H4ndStorage)

---@class ResizeInfo
---@field layout table<string, any>
---@field absoluteDelta util.vector2
---@field resolvedDelta util.vector2

---@alias ResizeHandler fun(resizeInfo: ResizeInfo)
---@alias ui.Element userdata

---@type table<ui.Element, ResizeHandler>
H4ND.state.resizeHandlers = {
    [CastableIndicator] = function(resizeInfo)
        H4ND.CastableIndicatorSize = resizeInfo.resolvedDelta.x
    end,
    [Compass] = function(resizeInfo)
        local layout, absoluteDelta = resizeInfo.layout, resizeInfo.absoluteDelta
        H4ND.CompassSize = (layout.props.size + -(absoluteDelta.xx)).x
    end,
    [EffectBar] = function(resizeInfo)
        H4ND.EffectBarSize = resizeInfo.resolvedDelta
    end,
    [HudCore] = function(resizeInfo)
        H4ND.H4NDWidth = resizeInfo.resolvedDelta.x
    end,
    [WeaponIndicator] = function(resizeInfo)
        H4ND.WeaponIndicatorSize = resizeInfo.resolvedDelta.x
    end,
}

CurrentDelay = 0
return {
    interfaceName = 'H4nd',
    interface = {
        getElementByName = H4ND.getElementByName,
    },
    eventHandlers = {
        H4NDCorrectSecondAttribute = function(atlasData)
            local stat, atlasName = atlasData.stat, atlasData.atlasName
            H4ND[atlasName .. 'Stat'] = stat
            ---@diagnostic disable-next-line: undefined-field
            H4ND.getElementByName(atlasName).element:update()
            H4ND.updateTime()
        end,
        H4NDUpdateCastable = function()
            local icon = getCastableIcon()
            local castableIndicator = CastableIndicator.layout.content
            local castIconProps = castableIndicator.CastableIcon.props
            local chanceBarProps = castableIndicator.CastChanceContainer.content.CastChanceBar.props

            if not icon then
                icon = 'white'
                castIconProps.alpha = .5
                castIconProps.color = Colors.Black
            else
                castIconProps.alpha = 1.
                castIconProps.color = nil
            end

            chanceBarProps.relativeSize = util.vector2(H4ND.getCastableWidth(), 1)
            chanceBarProps.visible = icon ~= nil
            castIconProps.resource = ui.texture { path = icon }

            CastableIndicator:update()
            H4ND.updateTime()
        end,
        H4NDUpdateCastableBar = function()
            CastableIndicator
            .layout
            .content
            .CastChanceContainer
            .content
            .CastChanceBar
            .props
            .relativeSize =
                util.vector2(H4ND.getCastableWidth(), 1)

            CastableIndicator:update()
            H4ND.updateTime()
        end,
        H4NDUpdateCompassStyle = function()
            CompassAtlas = respawnCompassAtlas()

            local compassProps = Compass.layout.props
            compassProps.resource = CompassAtlas.textureArray[adjustedYaw()]
            compassProps.anchor = getCompassAnchor()

            Compass:update()
        end,
        H4NDUpdateDurability = function()
            updateDurabilityBarSize()
            WeaponIndicator:update()
            H4ND.updateTime()
        end,
        H4NDUpdateWeapon = function()
            local weaponIndicator = WeaponIndicator.layout.content.WeaponIconBox.content

            weaponIndicator.WeaponIcon.props.resource = ui.texture { path = getSelectedWeaponIcon() }
            weaponIndicator.EnchantFrame.props.visible = weaponIsEnchanted(getWeapon())
            updateDurabilityBarSize()

            WeaponIndicator:update()
            H4ND.updateTime()
        end,
    },
    engineHandlers = {
        onFrame = function()
            if CurrentDelay < TotalDelay then
                CurrentDelay = CurrentDelay + core.getRealFrameDuration()
                return
            else
                CurrentDelay = 0
            end

            if not updateWeaponIcon() then updateWeaponDurability() end
            if not updateCastableIcon() then updateCastableBar() end

            updateStatFrames()
            updateCompass()
            EffectBarManager:constructEffectImages()
            handleFade()
        end,
    }
}
