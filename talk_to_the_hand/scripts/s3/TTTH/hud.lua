local async = require 'openmw.async'
local core = require 'openmw.core'
local storage = require 'openmw.storage'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

---@type H4NDConstants
local Constants = require 'scripts.s3.TTTH.constants'
local Attrs, Colors, Vectors = Constants.Attrs, Constants.Colors, Constants.Vectors

local Magic = require 'scripts.s3.spellUtil'

local HudCore,
ThumbAtlas,
MiddleAtlas,
PinkyAtlas,
CastableIndicator,
TotalDelay,
CurrentDelay

local H4ndStorage = storage.playerSection('SettingsTalkToTheHandMain')
---@class H4ND: ProtectedTable
---@field UIFramerate integer
---@field HUDWidth number
---@field HUDPos util.vector2
---@field HUDAnchor util.vector2
---@field ThumbStat string
---@field PinkyStat string
---@field MiddleStat string
---@field fatigueColor util.color
---@field magickaColor util.color
---@field healthColor util.color
---@field DurabilityColor util.color
---@field CastChanceColor util.color
---@field size util.vector2 Absolute size of the hand HUD. This is part of the H4ND state table and not necessarily the original module
local H4ND = I.S3ProtectedTable.new {
    storageSection = H4ndStorage,
    logPrefix = '[H4ND]:',
    subscribeHandler = false,
}

function H4ND.getHandSize()
    return ui.screenSize():emul(
        util.vector2(
            H4ND.HUDWidth,
            H4ND.HUDWidth * 2
        )
    )
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

---@param elementName string
---@return userdata? handElement
function H4ND.getElementByName(elementName)
    return ({
        Middle = MiddleAtlas,
        Pinky = PinkyAtlas,
        Thumb = ThumbAtlas,
        EffectBar = HudCore.layout.content.EffectBar,
        WeaponIndicator = HudCore.layout.content.WeaponIndicator,
        CastableIndicator = CastableIndicator,
    })[elementName]
end

H4ND.state = {
    equippedWeapon = s3lf.getEquipment(s3lf.EQUIPMENT_SLOT.CarriedRight),
    equippedCastable = s3lf.getSelectedSpell() or s3lf.getSelectedEnchantedItem(),
}

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
local function getCastableWidth()
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

local function normalizedWeaponHealth()
    local weapon, mult = getWeapon(), 1.0

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
    local baseWidth = Attrs.ChanceBar(H4ND.getHandSize()).x
    local health = math.floor(normalizedWeaponHealth() * baseWidth)
    local width = HudCore.layout.content.WeaponIndicator.content.DurabilityBar.props.size.x

    width = math.floor(width)
    if width == health then return false end

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
    local baseWidth = Attrs.ChanceBar(H4ND.getHandSize()).x
    local targetWidth = math.floor(baseWidth * getCastableWidth())

    local castableIndicator = CastableIndicator.layout.content
    local chanceBarProps = castableIndicator.CastChanceContainer.content.CastChanceBar.props

    local currentWidth = math.floor(chanceBarProps.size.x)
    if currentWidth == targetWidth then return false end

    s3lf.gameObject:sendEvent('H4NDUpdateCastableBar')
    return true
end

local function updateDurabilityBarSize()
    local weaponIndicator = HudCore.layout.content.WeaponIndicator.content
    local xMult, barSize = normalizedWeaponHealth(), Attrs.ChanceBar(H4ND.getHandSize())
    weaponIndicator.DurabilityBar.props.size = util.vector2(barSize.x * xMult, barSize.y)
end

local handSize = H4ND.getHandSize()
ThumbAtlas, MiddleAtlas, PinkyAtlas = require 'scripts.s3.TTTH.atlasses' (
    Constants,
    handSize,
    getColorForElement
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

local BarSize, castableIcon = Attrs.ChanceBar(handSize), getCastableIcon()

CastableIndicator = require 'scripts.s3.TTTH.components.castableIndicator' {
    barSize = BarSize,
    barColor = H4ND.CastChanceColor,
    castableIcon = castableIcon,
    castableWidth = getCastableWidth(),
    handSize = handSize,
    Constants = Constants,
}

local WeaponIndicator = require 'scripts.s3.TTTH.components.weaponIndicator' {
    barSize = BarSize,
    handSize = handSize,
    weaponHealth = normalizedWeaponHealth(),
    durabilityColor = H4ND.DurabilityColor,
    enchantFrameVisible = weaponIsEnchanted(getWeapon()),
    weaponIcon = getSelectedWeaponIcon(),
    Constants = Constants,
}

HudCore = ui.create {
    layer = 'HUD',
    name = 'H4ND',
    props = {
        size = handSize,
        anchor = H4ND.HUDAnchor,
        relativePosition = H4ND.HUDPos,
    },
    content = ui.content {
        ThumbAtlas.element,
        MiddleAtlas.element,
        PinkyAtlas.element,
        WeaponIndicator,
        {
            type = ui.TYPE.Image,
            name = 'EffectBar',
            props = {
                resource = ui.texture { path = 'white', },
                size = Attrs.EffectBar(handSize),
                color = util.color.hex('ff0abb'),
                anchor = Vectors.BottomLeft,
                relativePosition = Vectors.BottomLeft,
            }
        },
        CastableIndicator,
    }
}

H4ndStorage:subscribe(
    async:callback(
        function(_, key)
            local value, atlasName, atlas = H4ndStorage:get(key)

            if key == 'ThumbColor' or key == 'ThumbStat' then
                atlasName, atlas = 'Thumb', ThumbAtlas
            elseif key == 'MiddleColor' or key == 'MiddleStat' then
                atlasName, atlas = 'Middle', MiddleAtlas
            elseif key == 'PinkyColor' or key == 'PinkyStat' then
                atlasName, atlas = 'Pinky', PinkyAtlas
            elseif key == 'HUDPos' or key == 'HUDWidth' or key == 'HUDAnchor' then
                if key == 'HUDWidth' then
                    handSize = H4ND.getHandSize()
                    HudCore.layout.props.size = handSize

                    for attrFunc, resizeAtlas in pairs {
                        [Attrs.Thumb] = ThumbAtlas,
                        [Attrs.Middle] = MiddleAtlas,
                        [Attrs.Pinky] = PinkyAtlas,
                    } do
                        local props = resizeAtlas.element.layout.props
                        props.size, props.position = attrFunc(handSize)
                        resizeAtlas.element:update()
                    end

                    ---@diagnostic disable-next-line: undefined-field
                    H4ND.getElementByName('EffectBar').props.size = Attrs.EffectBar(handSize)

                    local castable = H4ND.getElementByName('CastableIndicator')
                    assert(castable)

                    ---@diagnostic disable-next-line: undefined-field
                    castable.layout.props.position = Attrs.Castable(handSize)

                    ---@diagnostic disable-next-line: undefined-field
                    local castableContent = castable.layout.content

                    castableContent.CastableIcon.props.size = Attrs.SubIcon(handSize)

                    local container, barSize = castableContent.CastChanceContainer.content, Attrs.ChanceBar(handSize)
                    container.CastChanceBackground.props.size = barSize
                    container.CastChanceBar.props.size = util.vector2(barSize.x * getCastableWidth(), barSize.y)

                    ---@diagnostic disable-next-line: undefined-field
                    castable:update()

                    ---@diagnostic disable-next-line: undefined-field
                    local weapon = H4ND.getElementByName('WeaponIndicator').content
                    local iconBoxProps = weapon.WeaponIconBox.props
                    iconBoxProps.position, iconBoxProps.size = Attrs.Weapon(handSize), Attrs.SubIcon(handSize)

                    local durabilityBarSize = Attrs.ChanceBar(handSize)

                    weapon.DurabilityBar.props.size = util.vector2(
                        durabilityBarSize.x * normalizedWeaponHealth(), durabilityBarSize.y)
                elseif key == 'HUDPos' then
                    HudCore.layout.props.relativePosition = value
                elseif key == 'HUDAnchor' then
                    HudCore.layout.props.anchor = value
                end

                HudCore:update()
            elseif key == 'UIFramerate' then
                TotalDelay = 1 / value
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

                    local thisAtlas = H4ND.getStatAtlas(key)

                    for elementName, statName in pairs {
                        Pinky = H4ND.PinkyStat,
                        Thumb = H4ND.ThumbStat,
                        Middle = H4ND.MiddleStat,
                    } do
                        usedAttributes[statName] = nil

                        if statName == value and H4ND.getElementByName(elementName) ~= thisAtlas then
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
local updateFunctions = {
    updateWeaponIcon,
    updateWeaponDurability,
    updateCastableIcon,
    updateCastableBar,
}
return {
    interfaceName = 'H4nd',
    interface = {
        HUD = function()
            return HudCore
        end,
        getCastChance = function(spell, actor)
            return Magic:getSpellCastChance(spell, actor or s3lf.gameObject)
        end,
        getSpellCost = function(spell)
            return Magic:getSpellCost(spell)
        end,
    },
    eventHandlers = {
        H4NDCorrectSecondAttribute = function(atlasData)
            local stat, atlasName = atlasData.stat, atlasData.atlasName
            H4ND[atlasName .. 'Stat'] = stat
            ---@diagnostic disable-next-line: undefined-field
            H4ND.getElementByName(atlasName).element:update()
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

            local barSize = Attrs.ChanceBar(H4ND.getHandSize())
            chanceBarProps.size = util.vector2(barSize.x * getCastableWidth(), barSize.y)
            chanceBarProps.visible = icon ~= nil
            castIconProps.resource = ui.texture { path = icon }

            CastableIndicator:update()
        end,
        H4NDUpdateCastableBar = function()
            local castableIndicator = CastableIndicator.layout.content

            local chanceBarProps = castableIndicator.CastChanceContainer.content.CastChanceBar.props
            local barSize = Attrs.ChanceBar(H4ND.getHandSize())
            chanceBarProps.size = util.vector2(barSize.x * getCastableWidth(), barSize.y)

            CastableIndicator:update()
        end,
        H4NDUpdateDurability = function()
            updateDurabilityBarSize()
            HudCore:update()
        end,
        H4NDUpdateWeapon = function()
            local weaponIndicator = HudCore.layout.content.WeaponIndicator.content[1].content

            weaponIndicator.WeaponIcon.props.resource = ui.texture { path = getSelectedWeaponIcon() }
            weaponIndicator.EnchantFrame.props.visible = weaponIsEnchanted(getWeapon())
            updateDurabilityBarSize()

            HudCore:update()
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

            for i, updater in ipairs(updateFunctions) do
                if updater() then
                    print('bailing on updater ' .. i)
                    break
                end
            end

            updateStatFrames()
        end,
    }
}
