local async = require 'openmw.async'
local core = require 'openmw.core'
local input = require 'openmw.input'
local storage = require 'openmw.storage'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

-- TODO: Fix default sizes/positions
-- Add presets
-- Find another compass?

---@class ColorUtil
local colorUtil = {}
function colorUtil.multiply(base, blend)
    local mix = base:asRgb():emul(blend:asRgb())

    return util.color.rgb(mix.x, mix.y, mix.z)
end

function colorUtil.screen(base, blend)
    local base_rgb = base:asRgb()
    local blend_rgb = blend:asRgb()
    local mix = util.vec3(
        1 - (1 - base_rgb.x) * (1 - blend_rgb.x),
        1 - (1 - base_rgb.y) * (1 - blend_rgb.y),
        1 - (1 - base_rgb.z) * (1 - blend_rgb.z)
    )
    return util.color.rgb(mix.x, mix.y, mix.z)
end

function colorUtil.overlay(base, blend)
    local base_rgb = base:asRgb()
    local blend_rgb = blend:asRgb()
    local mix = util.vec3(
        base_rgb.x < 0.5 and (2 * base_rgb.x * blend_rgb.x) or (1 - 2 * (1 - base_rgb.x) * (1 - blend_rgb.x)),
        base_rgb.y < 0.5 and (2 * base_rgb.y * blend_rgb.y) or (1 - 2 * (1 - base_rgb.y) * (1 - blend_rgb.y)),
        base_rgb.z < 0.5 and (2 * base_rgb.z * blend_rgb.z) or (1 - 2 * (1 - base_rgb.z) * (1 - blend_rgb.z))
    )
    return util.color.rgb(mix.x, mix.y, mix.z)
end

function colorUtil.additive(base, blend)
    local base_rgb = base:asRgb()
    local blend_rgb = blend:asRgb()
    local mix = util.vec3(
        math.min(base_rgb.x + blend_rgb.x, 1),
        math.min(base_rgb.y + blend_rgb.y, 1),
        math.min(base_rgb.z + blend_rgb.z, 1)
    )
    return util.color.rgb(mix.x, mix.y, mix.z)
end

function colorUtil.softlight(base, blend)
    local base_rgb = base:asRgb()
    local blend_rgb = blend:asRgb()
    local mix = util.vec3(
        blend_rgb.x < 0.5 and (2 * base_rgb.x * blend_rgb.x + base_rgb.x * base_rgb.x * (1 - 2 * blend_rgb.x)) or
        (2 * base_rgb.x * (1 - blend_rgb.x) + math.sqrt(base_rgb.x) * (2 * blend_rgb.x - 1)),
        blend_rgb.y < 0.5 and (2 * base_rgb.y * blend_rgb.y + base_rgb.y * base_rgb.y * (1 - 2 * blend_rgb.y)) or
        (2 * base_rgb.y * (1 - blend_rgb.y) + math.sqrt(base_rgb.y) * (2 * blend_rgb.y - 1)),
        blend_rgb.z < 0.5 and (2 * base_rgb.z * blend_rgb.z + base_rgb.z * base_rgb.z * (1 - 2 * blend_rgb.z)) or
        (2 * base_rgb.z * (1 - blend_rgb.z) + math.sqrt(base_rgb.z) * (2 * blend_rgb.z - 1))
    )
    return util.color.rgb(mix.x, mix.y, mix.z)
end

---@param r integer
---@param g integer
---@param b integer
---@return integer, integer, integer
function colorUtil.rgbToHsl(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max ~= min then
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l
end

---@param p integer
---@param q integer
---@param t integer
---@return integer p
function colorUtil.hueToRgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
end

---@param h integer
---@param s integer
---@param l integer
---@return integer, integer, integer
function colorUtil.hslToRgb(h, s, l)
    local r, g, b

    if s == 0 then
        r, g, b = l, l, l
    else
        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = colorUtil.hueToRgb(p, q, h + 1 / 3)
        g = colorUtil.hueToRgb(p, q, h)
        b = colorUtil.hueToRgb(p, q, h - 1 / 3)
    end

    return r, g, b
end

---@param color util.color
---@param degrees integer
function colorUtil.hueShift(color, degrees)
    local rgb = color:asRgb()
    local h, s, l = colorUtil.rgbToHsl(rgb.x, rgb.y, rgb.z)
    h = (h + degrees / 360) % 1.0
    local r, g, b = colorUtil.hslToRgb(h, s, l)
    return util.color.rgb(r, g, b)
end

---@param color util.color
---@param amount number @0-1, where 0 = no change, 1 = fully grayscale
---@return util.color
function colorUtil.desaturate(color, amount)
    local rgb = color:asRgb()
    local h, s, l = colorUtil.rgbToHsl(rgb.x, rgb.y, rgb.z)
    s = s * (1 - amount)
    local r, g, b = colorUtil.hslToRgb(h, s, l)
    return util.color.rgb(r, g, b)
end

local overAtlas = I.S3AtlasConstructor.constructAtlas {
    tileSize = util.vector2(213, 213),
    tilesPerRow = 10,
    totalTiles = 100,
    atlasPath = 'textures/s3/ttth/orb_over_atlas.dds'
}

local hubbleAtlas = I.S3AtlasConstructor.constructAtlas {
    tileSize = util.vector2(213, 213),
    tilesPerRow = 10,
    totalTiles = 100,
    atlasPath = 'textures/s3/ttth/hubble_over_atlas.dds'
}

local orbHeight = 1.
local orbSize = .2
local upOrDown = true

--- Functions for generating colors and layouts for diablo-style resource indicators
---@class OrbGen
local OrbGen = {
    colorCoeff = 2.,
    fillTexture = ui.texture {
        path = 'textures/s3/ttth/orb_fill.dds',
        size = util.vector2(213, 213),
    },
    nebulaAlpha = .25,
    noiseAlpha = .5,
    noiseTexture = ui.texture { path = 'textures/s3/ttth/perlin.dds', },
    veinAlpha = .25,
}

---@param vector util.vector3
---@return util.color
function OrbGen.vectorColor(vector)
    return util.color.rgb(vector.x, vector.y, vector.z)
end

---@class OrbColors
---@field base util.color
---@field noise util.color
---@field vein util.color
---@field nebula util.color

---@param inColor util.color
---@return OrbColors
function OrbGen:getColor(inColor)
    local mult = self.colorCoeff
    local current = inColor:asRgb() * mult
    local layers = { base = inColor }

    local order = {
        { name = "noise",  hue = nil },
        { name = "vein",   hue = nil },
        { name = "nebula", hue = 45 }
    }

    for _, layer in ipairs(order) do
        local color = self.vectorColor(current)

        if layer.hue then
            color = colorUtil.hueShift(color, layer.hue)
        end

        layers[layer.name] = color
        current = current:emul(color:asRgb()) * mult
    end

    return layers
end

---@class SubElementConstructor
---@field alpha number
---@field resource userdata
---@field color util.color,
---@field twoSided boolean
---@field rightSide boolean?
---@field name string

---@param elementInfo  SubElementConstructor
function OrbGen:subElement(elementInfo)
    local width, xPos = elementInfo.twoSided and 2. or 1., 0

    if elementInfo.twoSided and elementInfo.rightSide then
        xPos = -1
    end

    return {
        name = 'Orb' .. elementInfo.name,
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(width, 1),
            resource = elementInfo.resource,
            color = elementInfo.color,
            alpha = elementInfo.alpha,
            anchor = util.vector2(0, 1),
            relativePosition = util.vector2(xPos, 1),
        }
    }
end

---@param color util.color
---@param twoSided boolean
---@param rightSide boolean?
---@return table<string, any> layout
function OrbGen:fill(color, twoSided, rightSide)
    return self:subElement {
        name = 'Fill',
        alpha = 1.,
        color = color,
        twoSided = twoSided,
        rightSide = rightSide,
        resource = self.fillTexture,
    }
end

---@param color util.color
---@param twoSided boolean
---@param rightSide boolean?
---@return table<string, any> layout
function OrbGen:noise(color, twoSided, rightSide)
    return self:subElement {
        name = 'Noise',
        type = ui.TYPE.Image,
        alpha = self.noiseAlpha,
        resource = self.noiseTexture,
        color = color,
        twoSided = twoSided,
        rightSide = rightSide,
    }
end

---@param atlas ImageAtlas
---@param color util.color
---@param twoSided boolean
---@param rightSide boolean?
---@return table<string, any> nebulaOverlay
function OrbGen:nebula(atlas, color, twoSided, rightSide)
    return self:subElement {
        name = 'Nebula',
        resource = atlas.textureArray[1],
        alpha = self.nebulaAlpha,
        color = color,
        twoSided = twoSided,
        rightSide = rightSide,
    }
end

---@param atlas ImageAtlas
---@param color util.color
---@param twoSided boolean
---@param rightSide boolean?
---@return table<string, any> veinOverlay
function OrbGen:vein(atlas, color, twoSided, rightSide)
    return self:subElement {
        name = 'Vein',
        resource = atlas.textureArray[1],
        alpha = self.veinAlpha,
        color = color,
        twoSided = twoSided,
        rightSide = rightSide,
    }
end

local ManaColors, FatigueColors =
    OrbGen:getColor(util.color.hex('00ff7f')), OrbGen:getColor(util.color.hex('a7fc00'))

local Orbs = ui.create {
    name = 'OrbLayoutTest',
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        resource = ui.texture {
            path = 'textures/s3/ttth/orb_background.dds',
            size = util.vector2(213, 213),
        },
        relativeSize = util.vector2(orbSize, orbSize),
        relativePosition = util.vector2(0., 1.),
        anchor = util.vector2(0, 1.),
    },
    content = ui.content {
        {
            name = 'OrbLeftFillContain',
            props = {
                relativePosition = util.vector2(.0, 1),
                relativeSize = util.vector2(.5, orbHeight),
                anchor = util.vector2(.0, 1.),
            },
            content = ui.content {
                OrbGen:fill(FatigueColors.base, true),
                OrbGen:noise(FatigueColors.noise, true),
                OrbGen:nebula(hubbleAtlas, FatigueColors.nebula, true),
                OrbGen:vein(overAtlas, FatigueColors.vein, true),
            }
        },
        {
            name = 'OrbRightFillContain',
            props = {
                relativePosition = util.vector2(.5, 1),
                relativeSize = util.vector2(.5, orbHeight),
                anchor = util.vector2(.0, 1.),
            },
            content = ui.content {
                OrbGen:fill(ManaColors.base, true, true),
                OrbGen:noise(ManaColors.noise, true, true),
                OrbGen:nebula(hubbleAtlas, ManaColors.nebula, true, true),
                OrbGen:vein(overAtlas, ManaColors.vein, true, true),
            }
        },
        {
            name = 'OrbCap',
            type = ui.TYPE.Image,
            props = {
                -- relativePosition = util.vector2(-.02, 0.),
                relativeSize = util.vector2(1.0, 1.015),
                resource = ui.texture { path = 'textures/s3/ttth/orb_cap.dds' },
            },
        },
    }
}

---@type H4NDConstants
local Constants = require 'scripts.s3.TTTH.constants'
local Attrs, Colors = Constants.Attrs, Constants.Colors

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
}
H4ND.state = {
    equippedWeapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight),
    equippedCastable = s3lf.getSelectedSpell() or s3lf.getSelectedEnchantedItem(),
    lastUpdateTime = core.getRealTime(),
    currentScreenSize = ui.screenSize(),
}

local targetLayer = H4ND.UIDebug and 'Windows' or 'HUD'

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

local StatMap

---@param statName string
---@return ImageAtlas?
function H4ND.getStatAtlas(statName)
    if not StatMap then
        assert(MiddleAtlas and PinkyAtlas and ThumbAtlas,
            'GetStatAtlas should never be called prior to the atlasses actually being constructed!')
        StatMap = {
            MiddleStat = MiddleAtlas,
            PinkyStat = PinkyAtlas,
            ThumbStat = ThumbAtlas
        }
    end

    local result = StatMap[statName]
    assert(result)

    return result
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

    local content = ui.content(allRows)

    if EffectBar then
        EffectBar.layout.content[1].content = content
        EffectBar:update()
    else
        EffectBar = ui.create {
            name = 'EffectBar',
            layer = targetLayer,
            props = {
                relativeSize = H4ND.EffectBarSize,
                anchor = H4ND.EffectBarAnchor,
                relativePosition = H4ND.EffectBarPos,
            },
            events = H4ND.dragEvents('EffectBar'),
            content = ui.content {
                {
                    type = ui.TYPE.Flex,
                    name = 'EffectContainer',
                    props = {
                        autoSize = false,
                        relativeSize = Constants.Vectors.BottomRight,
                    },
                    content = content,
                },
                {
                    name = 'DebugContent',
                    props = {
                        visible = H4ND.UIDebug,
                        relativeSize = Constants.Vectors.BottomRight,
                    },
                    content = ui.content {
                        {
                            type = ui.TYPE.Image,
                            props = {
                                relativeSize = Constants.Vectors.BottomRight,
                                alpha = .5,
                                resource = ui.texture { path = 'white', },
                                color = util.color.hex('ffaa0b'),
                            },
                        },
                        {
                            template = I.MWUI.templates.textHeader,
                            props = {
                                anchor = Constants.Vectors.Center,
                                relativePosition = Constants.Vectors.Center,
                                text = 'Effect Bar',
                            },
                        }
                    }
                },
            }
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
        .WeaponIndicator
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
        .CastableIndicator
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
    .WeaponIndicator
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
    elseif (fadeIn or hudVisible) and HudProps.alpha ~= 1. then
        step = math.min(1., HudProps.alpha + H4ND.FadeStep)

        if step == 1. then
            H4ND.updateTime()
        end
    else
        return
    end

    for _, element in ipairs { HudCore, EffectBar, CastableIndicator, WeaponIndicator, } do
        element.layout.props.alpha = step
        element:update()
    end
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
    layer = targetLayer,
    name = 'H4ND',
    props = {
        relativeSize = H4ND.getHandSize(),
        anchor = H4ND.H4NDAnchor,
        relativePosition = H4ND.H4NDPos,
        alpha = 1.0,
    },
    events = H4ND.dragEvents('Core'),
    userdata = {},
    content = ui.content {
        ThumbAtlas.element,
        MiddleAtlas.element,
        PinkyAtlas.element,
        {
            name = 'DebugContent',
            props = {
                visible = H4ND.UIDebug,
                relativeSize = Constants.Vectors.BottomRight,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        relativeSize = Constants.Vectors.BottomRight,
                        alpha = .5,
                        resource = ui.texture { path = 'white', },
                        color = util.color.hex('ff0000'),
                    },
                },
                { template = I.MWUI.templates.textHeader, props = { text = 'H4ND', }, }
            }
        },
    },
}

Compass = ui.create {
    layer = targetLayer,
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
    content = ui.content {
        {
            name = 'DebugContent',
            props = {
                visible = H4ND.UIDebug,
                relativeSize = Constants.Vectors.BottomRight,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        relativeSize = Constants.Vectors.BottomRight,
                        alpha = .5,
                        resource = ui.texture { path = 'white', },
                        color = util.color.hex('00ff00'),
                    },
                },
                {
                    template = I.MWUI.templates.textHeader,
                    props = {
                        anchor = Constants.Vectors.Center,
                        relativePosition = Constants.Vectors.Center,
                        text = 'Compass',
                    },
                }
            }
        },
    }
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

if H4ND.UIDebug then
    s3lf.gameObject:sendEvent('SetUiMode', { mode = 'Interface', windows = {}, })
end

local fatigueOrbFrame, magickaOrbFrame = 1
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
            local castableIndicator = CastableIndicator.layout.content.CastableIndicator.content
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
            .CastableIndicator
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
            local weaponIndicator = WeaponIndicator.layout.content.WeaponIndicator.content.WeaponIconBox.content

            weaponIndicator.WeaponIcon.props.resource = ui.texture { path = getSelectedWeaponIcon() }
            weaponIndicator.EnchantFrame.props.visible = weaponIsEnchanted(getWeapon())
            updateDurabilityBarSize()

            WeaponIndicator:update()
            H4ND.updateTime()
        end,
        UiModeChanged = function(modeInfo)
            if H4ND.UIDebug and (not modeInfo.newMode or modeInfo.newMode ~= 'Interface') then
                H4ND.UIDebug = false
            end
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

            if not H4ND.UIDebug then
                handleFade()
            end

            if fatigueOrbFrame == 100 then
                fatigueOrbFrame = upOrDown and 1 or 99
                magickaOrbFrame = upOrDown and 99 or 1
            elseif fatigueOrbFrame == 1 then
                fatigueOrbFrame = upOrDown and 2 or 100
                magickaOrbFrame = upOrDown and 100 or 2
            else
                fatigueOrbFrame = fatigueOrbFrame + (upOrDown and 1 or -1)
                magickaOrbFrame = magickaOrbFrame + (upOrDown and -1 or 1)
            end

            local orbContent = Orbs
                .layout
                .content
                .OrbLeftFillContain.content

            orbContent
            .OrbVein
            .props
            .resource = overAtlas.textureArray[fatigueOrbFrame]

            orbContent
            .OrbNebula
            .props
            .resource = hubbleAtlas.textureArray[fatigueOrbFrame]

            orbHeight = util.clamp(s3lf.fatigue.current / s3lf.fatigue.base, .0, 1.)
            Orbs.layout.content.OrbLeftFillContain.props.relativeSize = util.vector2(.5, orbHeight)

            orbContent
            .OrbVein
            .props
            .relativeSize = util.vector2(2., 1 / orbHeight)

            orbContent
            .OrbNebula
            .props
            .relativeSize = util.vector2(2., 1 / orbHeight)

            orbContent
            .OrbFill
            .props
            .relativeSize = util.vector2(2., 1 / orbHeight)

            orbContent
            .OrbNoise
            .props
            .relativeSize = util.vector2(2., 1 / orbHeight)

            orbContent = Orbs
                .layout
                .content
                .OrbRightFillContain.content

            orbContent
            .OrbVein
            .props
            .resource = overAtlas.textureArray[fatigueOrbFrame]

            orbContent
            .OrbNebula
            .props
            .resource = hubbleAtlas.textureArray[fatigueOrbFrame]

            orbHeight = util.clamp(s3lf.magicka.current / s3lf.magicka.base, .0, 1.)
            Orbs.layout.content.OrbRightFillContain.props.relativeSize = util.vector2(.5, orbHeight)

            orbContent
            .OrbVein
            .props
            .relativeSize = util.vector2(2, 1 / orbHeight)

            orbContent
            .OrbNebula
            .props
            .relativeSize = util.vector2(2, 1 / orbHeight)

            orbContent
            .OrbFill
            .props
            .relativeSize = util.vector2(2, 1 / orbHeight)

            orbContent
            .OrbNoise
            .props
            .relativeSize = util.vector2(2, 1 / orbHeight)

            Orbs:update()
        end,
    }
}
