---@omw-context player

local self = require 'openmw.self'
local types = require 'openmw.types'

local EMPTY_FIELD = '—'

---@class S3UI.InventoryCategory
---@field key string
---@field label string

---@class S3UI.InventoryItemData
---@field item any
---@field record table|nil
---@field name string
---@field icon string|nil
---@field count integer
---@field categoryKey string
---@field categoryLabel string
---@field value number
---@field weight number
---@field effectiveness number
---@field condition number|nil
---@field equipped boolean
---@field enchanted boolean
---@field broken boolean

---@class S3UI.InventoryCategoryEntry
---@field kind 'categoryHeader'
---@field categoryKey string
---@field label string
---@field count integer
---@field collapsed boolean

---@class S3UI.InventoryItemEntry
---@field kind 'item'
---@field data S3UI.InventoryItemData

---@alias S3UI.InventoryDisplayEntry S3UI.InventoryCategoryEntry|S3UI.InventoryItemEntry

---@class S3UI.WeaponDamageField
---@field key string
---@field text string
---@field compactText string

---@type S3UI.InventoryCategory[]
local CATEGORY_ORDER = {
    { key = 'all', label = 'All' },
    { key = 'weapons', label = 'Weapons' },
    { key = 'armor', label = 'Armor' },
    { key = 'apparel', label = 'Apparel' },
    { key = 'alchemy', label = 'Alchemy' },
    { key = 'books', label = 'Books' },
    { key = 'tools', label = 'Tools' },
    { key = 'misc', label = 'Misc' },
}

local CATEGORY_BY_KEY = {}
for _, category in ipairs(CATEGORY_ORDER) do
    CATEGORY_BY_KEY[category.key] = category
end

local TYPE_NAMES = {
    [types.Apparatus] = 'Apparatus',
    [types.Armor] = 'Armor',
    [types.Book] = 'Book',
    [types.Clothing] = 'Clothing',
    [types.Ingredient] = 'Ingredient',
    [types.Light] = 'Light',
    [types.Lockpick] = 'Lockpick',
    [types.Miscellaneous] = 'Miscellaneous',
    [types.Potion] = 'Potion',
    [types.Probe] = 'Probe',
    [types.Repair] = 'Repair',
    [types.Weapon] = 'Weapon',
}

local ARMOR_TYPE_NAMES = {
    [types.Armor.TYPE.Boots] = 'Boots',
    [types.Armor.TYPE.Cuirass] = 'Cuirass',
    [types.Armor.TYPE.Greaves] = 'Greaves',
    [types.Armor.TYPE.Helmet] = 'Helmet',
    [types.Armor.TYPE.LBracer] = 'Left Bracer',
    [types.Armor.TYPE.LGauntlet] = 'Left Gauntlet',
    [types.Armor.TYPE.LPauldron] = 'Left Pauldron',
    [types.Armor.TYPE.RBracer] = 'Right Bracer',
    [types.Armor.TYPE.RGauntlet] = 'Right Gauntlet',
    [types.Armor.TYPE.RPauldron] = 'Right Pauldron',
    [types.Armor.TYPE.Shield] = 'Shield',
}

local CLOTHING_TYPE_NAMES = {
    [types.Clothing.TYPE.Amulet] = 'Amulet',
    [types.Clothing.TYPE.Belt] = 'Belt',
    [types.Clothing.TYPE.LGlove] = 'Left Glove',
    [types.Clothing.TYPE.Pants] = 'Pants',
    [types.Clothing.TYPE.RGlove] = 'Right Glove',
    [types.Clothing.TYPE.Ring] = 'Ring',
    [types.Clothing.TYPE.Robe] = 'Robe',
    [types.Clothing.TYPE.Shirt] = 'Shirt',
    [types.Clothing.TYPE.Shoes] = 'Shoes',
    [types.Clothing.TYPE.Skirt] = 'Skirt',
}

local WEAPON_TYPE_NAMES = {
    [types.Weapon.TYPE.Arrow] = 'Arrow',
    [types.Weapon.TYPE.AxeOneHand] = 'One Handed Axe',
    [types.Weapon.TYPE.AxeTwoHand] = 'Two Handed Axe',
    [types.Weapon.TYPE.BluntOneHand] = 'One Handed Blunt',
    [types.Weapon.TYPE.BluntTwoClose] = 'Close Two Handed Blunt',
    [types.Weapon.TYPE.BluntTwoWide] = 'Wide Two Handed Blunt',
    [types.Weapon.TYPE.Bolt] = 'Bolt',
    [types.Weapon.TYPE.LongBladeOneHand] = 'One Handed Long Blade',
    [types.Weapon.TYPE.LongBladeTwoHand] = 'Two Handed Long Blade',
    [types.Weapon.TYPE.MarksmanBow] = 'Bow',
    [types.Weapon.TYPE.MarksmanCrossbow] = 'Crossbow',
    [types.Weapon.TYPE.MarksmanThrown] = 'Thrown',
    [types.Weapon.TYPE.ShortBladeOneHand] = 'Short Blade',
    [types.Weapon.TYPE.SpearTwoWide] = 'Spear',
}

local APPARATUS_TYPE_NAMES = {
    [types.Apparatus.TYPE.Alembic] = 'Alembic',
    [types.Apparatus.TYPE.Calcinator] = 'Calcinator',
    [types.Apparatus.TYPE.MortarPestle] = 'Mortar & Pestle',
    [types.Apparatus.TYPE.Retort] = 'Retort',
}

local WEAPON_DAMAGE_ATTACKS = {
    { key = 'chopDamage', label = 'Chop', compactLabel = 'C', minField = 'chopMinDamage', maxField = 'chopMaxDamage' },
    { key = 'slashDamage', label = 'Slash', compactLabel = 'S', minField = 'slashMinDamage', maxField = 'slashMaxDamage' },
    { key = 'thrustDamage', label = 'Thrust', compactLabel = 'T', minField = 'thrustMinDamage', maxField = 'thrustMaxDamage' },
}

local function safeRecord(item)
    if not item or not item.type or not item.recordId then return nil end
    local records = item.type.records
    if not records then return nil end
    return records[item.recordId]
end

---@param item any
---@param record table|nil
---@return string
local function itemName(item, record)
    return (record and record.name) or item.recordId or 'Unknown item'
end

local function itemCount(inventory, item)
    if not item or not item.recordId then return 1 end
    local ok, count = pcall(function() return inventory:countOf(item.recordId) end)
    if ok and count and count > 0 then return count end
    return 1
end

local function safeItemData(item)
    local ok, itemData = pcall(function() return types.Item.itemData(item) end)
    if ok then return itemData end
    return nil
end

local function currentActor()
    return self.object or self
end

local function equippedRecordIds(actor)
    local result = {}
    local ok, equipment = pcall(function() return types.Actor.getEquipment(actor) end)
    if not ok or type(equipment) ~= 'table' then return result end
    for _, item in pairs(equipment) do
        if item and item.recordId then result[item.recordId] = true end
    end
    return result
end

local function itemEquipped(actor, equippedIds, item)
    if item and item.recordId and equippedIds[item.recordId] then return true end
    local ok, equipped = pcall(function() return types.Actor.hasEquipped(actor, item) end)
    return ok and equipped == true
end

local function itemEnchanted(record)
    return record and record.enchant ~= nil and record.enchant ~= ''
end

local function itemBroken(condition)
    return type(condition) == 'number' and condition <= 0
end

local function categoryForItem(itemType)
    if itemType == types.Weapon then return CATEGORY_BY_KEY.weapons end
    if itemType == types.Armor then return CATEGORY_BY_KEY.armor end
    if itemType == types.Clothing then return CATEGORY_BY_KEY.apparel end
    if itemType == types.Ingredient or itemType == types.Potion or itemType == types.Apparatus then return CATEGORY_BY_KEY.alchemy end
    if itemType == types.Book then return CATEGORY_BY_KEY.books end
    if itemType == types.Lockpick or itemType == types.Probe or itemType == types.Repair or itemType == types.Light then return CATEGORY_BY_KEY.tools end
    return CATEGORY_BY_KEY.misc
end

local function weaponEffectiveness(record)
    if not record then return 0 end
    local best = 0
    if type(record.thrustMaxDamage) == 'number' and record.thrustMaxDamage > best then best = record.thrustMaxDamage end
    if type(record.chopMaxDamage) == 'number' and record.chopMaxDamage > best then best = record.chopMaxDamage end
    if type(record.slashMaxDamage) == 'number' and record.slashMaxDamage > best then best = record.slashMaxDamage end
    if type(record.speed) == 'number' then best = best * record.speed end
    return best
end

local function itemEffectiveness(itemType, record)
    if not record then return 0 end
    if itemType == types.Weapon then return weaponEffectiveness(record) end
    if itemType == types.Armor and type(record.baseArmor) == 'number' then return record.baseArmor end
    if (itemType == types.Apparatus or itemType == types.Lockpick or itemType == types.Probe or itemType == types.Repair)
        and type(record.quality) == 'number' then
        return record.quality
    end
    return 0
end

local function itemCondition(itemData)
    if itemData and type(itemData.condition) == 'number' then return itemData.condition end
    return nil
end

---@return S3UI.InventoryItemData[]
local function collectItems()
    local actor = currentActor()
    local inventory = types.Actor.inventory(actor)
    local equippedIds = equippedRecordIds(actor)
    local seen = {}
    local result = {}

    for _, item in ipairs(inventory:getAll()) do
        local recordId = item.recordId
        if recordId and not seen[recordId] then
            seen[recordId] = true
            local record = safeRecord(item)
            local itemType = item.type
            local category = categoryForItem(itemType)
            local itemData = safeItemData(item)
            local condition = itemCondition(itemData)
            result[#result + 1] = {
                item = item,
                record = record,
                name = itemName(item, record),
                icon = record and record.icon,
                count = itemCount(inventory, item),
                categoryKey = category.key,
                categoryLabel = category.label,
                value = (record and type(record.value) == 'number') and record.value or 0,
                weight = (record and type(record.weight) == 'number') and record.weight or 0,
                effectiveness = itemEffectiveness(itemType, record),
                condition = condition,
                equipped = itemEquipped(actor, equippedIds, item),
                enchanted = itemEnchanted(record),
                broken = itemBroken(condition),
            }
        end
    end

    table.sort(result, function(left, right)
        return left.name:lower() < right.name:lower()
    end)

    return result
end

---@param value number|nil
---@param decimals integer|nil
---@return string
local function formatNumber(value, decimals)
    if type(value) ~= 'number' then return EMPTY_FIELD end
    if decimals then return string.format('%.' .. tostring(decimals) .. 'f', value) end
    return tostring(value)
end

local function formatDamage(minDamage, maxDamage)
    if type(minDamage) ~= 'number' or type(maxDamage) ~= 'number' then return EMPTY_FIELD end
    return tostring(minDamage) .. '–' .. tostring(maxDamage)
end

---@param condition number|nil
---@return string
local function formatCondition(condition)
    if type(condition) ~= 'number' or condition < 0 then return EMPTY_FIELD end
    return formatNumber(condition, 0)
end

---@param record table|nil
---@return string
local function bestWeaponDamage(record)
    if not record then return EMPTY_FIELD end
    local bestMin = nil
    local bestMax = -math.huge
    local damagePairs = {
        { record.thrustMinDamage, record.thrustMaxDamage },
        { record.chopMinDamage, record.chopMaxDamage },
        { record.slashMinDamage, record.slashMaxDamage },
    }
    for _, damage in ipairs(damagePairs) do
        local minDamage = damage[1]
        local maxDamage = damage[2]
        if type(minDamage) == 'number' and type(maxDamage) == 'number' and maxDamage > bestMax then
            bestMin = minDamage
            bestMax = maxDamage
        end
    end
    return formatDamage(bestMin, bestMax)
end

---@param record table|nil
---@return S3UI.WeaponDamageField[]
local function weaponDamageFields(record)
    local result = {}
    if not record then return result end

    for _, attack in ipairs(WEAPON_DAMAGE_ATTACKS) do
        local damage = formatDamage(record[attack.minField], record[attack.maxField])
        if damage ~= EMPTY_FIELD then
            result[#result + 1] = {
                key = attack.key,
                text = attack.label .. ' ' .. damage,
                compactText = attack.compactLabel .. ' ' .. damage,
            }
        end
    end

    return result
end

local function subtypeName(recordType, record)
    if not record then return EMPTY_FIELD end
    if recordType == types.Armor then return ARMOR_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Clothing then return CLOTHING_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Weapon then return WEAPON_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Apparatus then return APPARATUS_TYPE_NAMES[record.type] or EMPTY_FIELD end
    if recordType == types.Book and record.isScroll then return 'Scroll' end
    if recordType == types.Miscellaneous and record.isKey then return 'Key' end
    return EMPTY_FIELD
end

---@param data S3UI.InventoryItemData|nil
---@return string
local function typeText(data)
    if not data then return EMPTY_FIELD end
    local recordType = TYPE_NAMES[data.item and data.item.type] or 'Item'
    local subtype = subtypeName(data.item and data.item.type, data.record)
    if subtype == EMPTY_FIELD then return recordType end
    return subtype
end

---@param record table|nil
---@return string
local function goldPerWeight(record)
    if not record or type(record.weight) ~= 'number' or record.weight <= 0 or type(record.value) ~= 'number' then
        return EMPTY_FIELD
    end
    return formatNumber(record.value / record.weight, 2)
end

return {
    EMPTY_FIELD = EMPTY_FIELD,
    CATEGORY_ORDER = CATEGORY_ORDER,
    collectItems = collectItems,
    itemName = itemName,
    formatNumber = formatNumber,
    formatCondition = formatCondition,
    bestWeaponDamage = bestWeaponDamage,
    weaponDamageFields = weaponDamageFields,
    typeText = typeText,
    goldPerWeight = goldPerWeight,
}
