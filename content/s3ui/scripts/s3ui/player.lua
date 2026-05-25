---@omw-context player

local async = require 'openmw.async'
local camera = require 'openmw.camera'
local input = require 'openmw.input'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local v2 = util.vector2
local v3 = util.vector3

local WINDOW = I.UI.WINDOW.Inventory
local MODE = I.UI.MODE.Interface
local ROOT_LAYER = 'Windows'
local CAMERA_CONTROL_TAG = 's3ui_inventory'

local WINDOW_POSITION = v2(24, 80)
local WINDOW_SIZE = v2(500, 520)
local GRID_COLUMNS = 6
local GRID_ROWS = 5
local WHITE_TEXTURE = ui.texture { path = 'white' }
local CATEGORY_ICON_ATLAS = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/category_icons.dds'
local BACKGROUND_COLOR = util.color.rgb(0, 0, 0)
local ICON_RELATIVE_SIZE = v2(0.58, 0.58)
local COUNT_RELATIVE_SIZE = v2(0.28, 0.22)
local CATEGORY_ICON_COUNT_SIZE = v2(0.34, 0.24)
local CATEGORY_ICON_TOGGLE_SIZE = v2(0.24, 0.24)
local HINT_RELATIVE_SIZE = v2(1, 0.05)
local STATUS_RELATIVE_SIZE = v2(1, 0.05)
local MAX_VISIBLE_ITEMS = GRID_COLUMNS * GRID_ROWS
local STATIC_CAMERA_EXTRA_DISTANCE = 15
local TOOLBAR_RELATIVE_SIZE = v2(1, 0.12)
local MAIN_RELATIVE_SIZE = v2(1, 0)
local CATEGORY_RAIL_SIZE = v2(86, 0)
local CONTROL_BUTTON_SIZE = v2(48, 0)
local VIEW_BUTTON_SIZE = v2(44, 0)
local CATEGORY_HEADER_COLOR = util.color.rgb(0.18, 0.36, 0.68)
local CATEGORY_ACTIVE_COLOR = util.color.rgb(0.24, 0.47, 0.86)
local CATEGORY_COLLAPSED_COLOR = util.color.rgb(0.12, 0.18, 0.28)
local TOOLTIP_LAYER = 'S3UI_Tooltip'
local TOOLTIP_RELATIVE_WIDTH = 0.18
local TOOLTIP_HEADER_HEIGHT = 72
local TOOLTIP_FIELD_ROW_HEIGHT = 28
local TOOLTIP_FIELD_ROW_COUNT = 9
local TOOLTIP_VERTICAL_PADDING = 14
local TOOLTIP_DEFAULT_HEIGHT = TOOLTIP_HEADER_HEIGHT + TOOLTIP_FIELD_ROW_COUNT * TOOLTIP_FIELD_ROW_HEIGHT + TOOLTIP_VERTICAL_PADDING
local TOOLTIP_HEADER_SIZE = v2(1, TOOLTIP_HEADER_HEIGHT / TOOLTIP_DEFAULT_HEIGHT)
local TOOLTIP_FIELDS_SIZE = v2(1, TOOLTIP_FIELD_ROW_COUNT * TOOLTIP_FIELD_ROW_HEIGHT / TOOLTIP_DEFAULT_HEIGHT)
local TOOLTIP_MIN_MARGIN = v2(24, 24)
local TOOLTIP_ICON_SIZE = v2(48, 48)
local TOOLTIP_FIELD_ICON_SIZE = v2(28, 28)
local TOOLTIP_VALUE_TEXT_SIZE = 16
local EMPTY_FIELD = '—'

local TOOLTIP_ICONS = {
    typeGeneric = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_generic.dds' },
    typeWeapon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_weapon.dds' },
    typeArmor = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_armor.dds' },
    typeBook = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_book.dds' },
    value = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/value.dds' },
    weight = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weight.dds' },
    goldPerWeight = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/value.dds' },
    condition = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/durability.dds' },
    reach = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_reach.dds' },
    speed = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_speed.dds' },
    damage = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_damage.dds' },
    damageSpeed = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/weapon_damage_speed.dds' },
    armorRating = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/armor_rating.dds' },
}

local TOOLTIP_FIELD_NAMES = {
    's3ui_tooltip_type',
    's3ui_tooltip_value',
    's3ui_tooltip_weight',
    's3ui_tooltip_gold_per_weight',
    's3ui_tooltip_condition',
    's3ui_tooltip_reach',
    's3ui_tooltip_speed',
    's3ui_tooltip_damage',
    's3ui_tooltip_effectiveness',
}

local rootElement = nil
local tooltipElement = nil
local statusLayout = nil
local cameraSnapshot = nil
local hudVisibleSnapshot = nil
local registeredWindow = false
local selectedCategory = 'all'
local collapsedCategories = {}
local sortMode = 'value'
local sortAscending = {
    value = false,
    weight = false,
    effectiveness = false,
    condition = false,
}
local viewMode = 'grid'
local uiGeneration = 0
local pendingRebuildStatus = nil
local rebuildEventQueued = false
local rebuildInventoryRoot = nil
local scrollOffset = 0
local lastEntryCount = 0

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

local CATEGORY_ICON_TEXTURES = {
    all = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(25, 29), size = v2(206, 204) },
    weapons = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(284, 3), size = v2(224, 225) },
    armor = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(555, 0), size = v2(169, 256) },
    apparel = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(17, 536), size = v2(222, 226) },
    alchemy = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(802, 25), size = v2(194, 212) },
    books = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(4, 260), size = v2(247, 241) },
    tools = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(1061, 529), size = v2(182, 217) },
    misc = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(1074, 29), size = v2(153, 207) },
}

local CATEGORY_ICON_RELATIVE_SIZES = {
    all = v2(0.62, 0.58),
    weapons = v2(0.7, 0.6),
    armor = v2(0.48, 0.66),
    apparel = v2(0.58, 0.58),
    alchemy = v2(0.6, 0.62),
    books = v2(0.66, 0.6),
    tools = v2(0.52, 0.62),
    misc = v2(0.46, 0.58),
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

local function safeRecord(item)
    if not item or not item.type or not item.recordId then return nil end
    local records = item.type.records
    if not records then return nil end
    return records[item.recordId]
end

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

local function collectInventoryItems()
    local inventory = types.Actor.inventory(self.object or self)
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
                condition = itemCondition(itemData),
            }
        end
    end

    table.sort(result, function(left, right)
        return left.name:lower() < right.name:lower()
    end)

    return result
end

local function setStatus(text)
    if not rootElement or not rootElement.layout or not statusLayout then return end
    statusLayout.props.text = text
    rootElement:update()
end

local function textLine(text, template, props)
    props = props or {}
    local name = props.name
    props.name = nil
    props.text = text
    return {
        name = name,
        template = template or I.MWUI.templates.textNormal,
        props = props,
    }
end

local function formatNumber(value, decimals)
    if type(value) ~= 'number' then return EMPTY_FIELD end
    if decimals then return string.format('%.' .. tostring(decimals) .. 'f', value) end
    return tostring(value)
end

local function formatDamage(minDamage, maxDamage)
    if type(minDamage) ~= 'number' or type(maxDamage) ~= 'number' then return EMPTY_FIELD end
    return tostring(minDamage) .. '–' .. tostring(maxDamage)
end

local function formatCondition(condition)
    if type(condition) ~= 'number' or condition < 0 then return EMPTY_FIELD end
    return formatNumber(condition, 0)
end

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

local function typeText(data)
    if not data then return EMPTY_FIELD end
    local recordType = TYPE_NAMES[data.item and data.item.type] or 'Item'
    local subtype = subtypeName(data.item and data.item.type, data.record)
    if subtype == EMPTY_FIELD then return recordType end
    return subtype
end

local function typeIcon(data)
    local itemType = data and data.item and data.item.type
    if itemType == types.Weapon then return TOOLTIP_ICONS.typeWeapon end
    if itemType == types.Armor or itemType == types.Clothing then return TOOLTIP_ICONS.typeArmor end
    if itemType == types.Book then return TOOLTIP_ICONS.typeBook end
    return TOOLTIP_ICONS.typeGeneric
end

local function goldPerWeight(record)
    if not record or type(record.weight) ~= 'number' or record.weight <= 0 or type(record.value) ~= 'number' then
        return EMPTY_FIELD
    end
    return formatNumber(record.value / record.weight, 2)
end

local function backgroundAlpha()
    return ui._getMenuTransparency()
end

local function ensureTooltipLayer()
    if ui.layers.indexOf(TOOLTIP_LAYER) == nil then
        ui.layers.insertAfter(ROOT_LAYER, TOOLTIP_LAYER, { interactive = false })
    end
end

local function tooltipPixelHeight(rowCount)
    if type(rowCount) ~= 'number' or rowCount < 1 then rowCount = 1 end
    return TOOLTIP_HEADER_HEIGHT + rowCount * TOOLTIP_FIELD_ROW_HEIGHT + TOOLTIP_VERTICAL_PADDING
end

local function tooltipRelativeSize(rowCount, screen)
    screen = screen or ui.screenSize()
    return v2(TOOLTIP_RELATIVE_WIDTH, tooltipPixelHeight(rowCount) / screen.y)
end

local function tooltipPosition(relativeSize)
    local screen = ui.screenSize()
    relativeSize = relativeSize or tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT, screen)
    local size = v2(screen.x * relativeSize.x, screen.y * relativeSize.y)
    local preferred = v2(WINDOW_POSITION.x + WINDOW_SIZE.x, WINDOW_POSITION.y)
    if preferred.x + size.x > screen.x - TOOLTIP_MIN_MARGIN.x then preferred.x = screen.x - size.x - TOOLTIP_MIN_MARGIN.x end
    if preferred.y + size.y > screen.y - TOOLTIP_MIN_MARGIN.y then preferred.y = screen.y - size.y - TOOLTIP_MIN_MARGIN.y end
    if preferred.x < TOOLTIP_MIN_MARGIN.x then preferred.x = TOOLTIP_MIN_MARGIN.x end
    if preferred.y < TOOLTIP_MIN_MARGIN.y then preferred.y = TOOLTIP_MIN_MARGIN.y end
    return preferred
end

local function itemSortValue(data)
    if sortMode == 'value' then return data.value or 0 end
    if sortMode == 'weight' then return data.weight or 0 end
    if sortMode == 'effectiveness' then return data.effectiveness or 0 end
    if sortMode == 'condition' then return data.condition or 0 end
    return 0
end

local function sortItems(items)
    table.sort(items, function(left, right)
        local leftValue = itemSortValue(left)
        local rightValue = itemSortValue(right)
        if leftValue ~= rightValue then
            if sortAscending[sortMode] then return leftValue < rightValue end
            return leftValue > rightValue
        end
        local leftName = left.name:lower()
        local rightName = right.name:lower()
        if leftName ~= rightName then return leftName < rightName end
        return (left.item and left.item.recordId or '') < (right.item and right.item.recordId or '')
    end)
end

local function itemsByCategory(items)
    local grouped = {}
    for _, category in ipairs(CATEGORY_ORDER) do
        grouped[category.key] = {}
    end

    for _, item in ipairs(items) do
        grouped[item.categoryKey][#grouped[item.categoryKey] + 1] = item
    end

    for key in pairs(grouped) do
        sortItems(grouped[key])
    end

    return grouped
end

local function categoryEntry(category, count)
    return {
        kind = 'categoryHeader',
        categoryKey = category.key,
        label = category.label,
        count = count,
        collapsed = collapsedCategories[category.key] == true,
    }
end

local function itemEntry(item)
    return {
        kind = 'item',
        data = item,
    }
end

local function buildDisplayEntries(items)
    local grouped = itemsByCategory(items)
    local entries = {}

    for _, category in ipairs(CATEGORY_ORDER) do
        if category.key ~= 'all' and (selectedCategory == 'all' or selectedCategory == category.key) then
            local categoryItems = grouped[category.key]
            if #categoryItems > 0 then
                entries[#entries + 1] = categoryEntry(category, #categoryItems)
                if not collapsedCategories[category.key] then
                    for _, item in ipairs(categoryItems) do
                        entries[#entries + 1] = itemEntry(item)
                    end
                end
            end
        end
    end

    return entries
end

local function maxScrollOffset(entryCount)
    local extraRows = math.ceil(entryCount / GRID_COLUMNS) - GRID_ROWS
    if extraRows <= 0 then return 0 end
    return extraRows * GRID_COLUMNS
end

local function clampScrollOffset(entryCount)
    local maxOffset = maxScrollOffset(entryCount)
    if scrollOffset < 0 then scrollOffset = 0 end
    if scrollOffset > maxOffset then scrollOffset = maxOffset end
    scrollOffset = math.floor(scrollOffset / GRID_COLUMNS) * GRID_COLUMNS
    return maxOffset
end

local function resetScrollOffset()
    scrollOffset = 0
end

local function tooltipText(name, text, props, template, external)
    props = props or {}
    props.text = text
    return {
        name = name,
        template = template or I.MWUI.templates.textNormal,
        external = external,
        props = props,
    }
end

local function tooltipField(name, icon)
    return {
        name = name .. '_row',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = false,
            relativeSize = v2(1, 1 / TOOLTIP_FIELD_ROW_COUNT),
        },
        content = ui.content {
            {
                name = name .. '_icon_box',
                type = ui.TYPE.Widget,
                props = {
                    relativeSize = v2(0.16, 1),
                    autoSize = false,
                },
                content = ui.content {
                    {
                        name = name .. '_icon',
                        type = ui.TYPE.Image,
                        props = {
                            resource = icon,
                            anchor = v2(0.5, 0.5),
                            relativePosition = v2(0.5, 0.5),
                            size = TOOLTIP_FIELD_ICON_SIZE,
                        },
                    },
                },
            },
            tooltipText(name .. '_value', EMPTY_FIELD, {
                relativeSize = v2(0.84, 1),
                textSize = TOOLTIP_VALUE_TEXT_SIZE,
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                multiline = true,
                wordWrap = true,
                autoSize = false,
            }),
        },
    }
end

local function tooltipFieldValue(fieldsLayout, name)
    return fieldsLayout.content[name .. '_row'].content[name .. '_value']
end

local function tooltipFieldIcon(fieldsLayout, name)
    return fieldsLayout.content[name .. '_row'].content[name .. '_icon_box'].content[name .. '_icon']
end

local function setTooltipField(fieldsLayout, name, value)
    tooltipFieldValue(fieldsLayout, name).props.text = value or EMPTY_FIELD
end

local function setTooltipFieldIcon(fieldsLayout, name, icon)
    tooltipFieldIcon(fieldsLayout, name).props.resource = icon
end

local function setTooltipVisibleFields(fieldsLayout, visibleNames)
    local visible = {}
    for _, name in ipairs(visibleNames) do
        visible[name] = true
    end

    local visibleCount = #visibleNames
    if visibleCount < 1 then visibleCount = 1 end

    for _, name in ipairs(TOOLTIP_FIELD_NAMES) do
        local row = fieldsLayout.content[name .. '_row']
        local isVisible = visible[name] == true
        row.props.visible = isVisible
        row.props.relativeSize = isVisible and v2(1, 1 / visibleCount) or v2(1, 0)
    end

    return visibleCount
end

local function addTooltipField(visibleNames, name, value)
    if value == nil or value == '' or value == EMPTY_FIELD then return end
    visibleNames[#visibleNames + 1] = name
end

local function makeTooltipLayout()
    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        layer = TOOLTIP_LAYER,
        props = {
            position = tooltipPosition(),
            relativeSize = tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT),
            visible = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEXTURE,
                    color = BACKGROUND_COLOR,
                    alpha = backgroundAlpha(),
                    relativeSize = v2(1, 1),
                },
            },
            {
                name = 's3ui_tooltip_body',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    relativeSize = v2(1, 1),
                    autoSize = false,
                },
                content = ui.content {
                    {
                        name = 's3ui_tooltip_header',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            relativeSize = TOOLTIP_HEADER_SIZE,
                            autoSize = false,
                        },
                        content = ui.content {
                            {
                                name = 's3ui_tooltip_icon_box',
                                type = ui.TYPE.Widget,
                                props = {
                                    relativeSize = v2(0.18, 1),
                                    autoSize = false,
                                },
                                content = ui.content {
                                    {
                                        name = 's3ui_tooltip_icon',
                                        type = ui.TYPE.Image,
                                        props = {
                                            size = TOOLTIP_ICON_SIZE,
                                            anchor = v2(0.5, 0.5),
                                            relativePosition = v2(0.5, 0.5),
                                        },
                                    },
                                },
                            },
                            tooltipText('s3ui_tooltip_name', EMPTY_FIELD, {
                                relativeSize = v2(0.68, 1),
                                textSize = 21,
                                textAlignH = ui.ALIGNMENT.Start,
                                textAlignV = ui.ALIGNMENT.Center,
                                multiline = true,
                                wordWrap = true,
                                autoSize = false,
                            }, I.MWUI.templates.textHeader),
                            tooltipText('s3ui_tooltip_count', '', {
                                relativeSize = v2(0.14, 1),
                                textSize = 18,
                                textAlignH = ui.ALIGNMENT.Center,
                                textAlignV = ui.ALIGNMENT.Center,
                                autoSize = false,
                            }),
                        },
                    },
                    {
                        name = 's3ui_tooltip_fields',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            relativeSize = TOOLTIP_FIELDS_SIZE,
                            autoSize = false,
                        },
                        content = ui.content {
                            tooltipField('s3ui_tooltip_type', TOOLTIP_ICONS.typeGeneric),
                            tooltipField('s3ui_tooltip_value', TOOLTIP_ICONS.value),
                            tooltipField('s3ui_tooltip_weight', TOOLTIP_ICONS.weight),
                            tooltipField('s3ui_tooltip_gold_per_weight', TOOLTIP_ICONS.goldPerWeight),
                            tooltipField('s3ui_tooltip_condition', TOOLTIP_ICONS.condition),
                            tooltipField('s3ui_tooltip_reach', TOOLTIP_ICONS.reach),
                            tooltipField('s3ui_tooltip_speed', TOOLTIP_ICONS.speed),
                            tooltipField('s3ui_tooltip_damage', TOOLTIP_ICONS.damage),
                            tooltipField('s3ui_tooltip_effectiveness', TOOLTIP_ICONS.damageSpeed),
                        },
                    },
                },
            },
        },
    }
end

local function hideTooltip()
    if not tooltipElement or not tooltipElement.layout then return end
    tooltipElement.layout.props.visible = false
    tooltipElement:update()
end

local function updateTooltip(data)
    if not tooltipElement or not tooltipElement.layout or not data then return end

    local bodyContent = tooltipElement.layout.content.s3ui_tooltip_body.content
    local header = bodyContent.s3ui_tooltip_header.content
    local fields = bodyContent.s3ui_tooltip_fields
    local record = data.record

    local headerIcon = header.s3ui_tooltip_icon_box.content.s3ui_tooltip_icon
    if data.icon then
        headerIcon.props.resource = ui.texture { path = data.icon }
    else
        headerIcon.props.resource = WHITE_TEXTURE
    end

    header.s3ui_tooltip_name.props.text = data.name or itemName(data.item, record)
    header.s3ui_tooltip_count.props.text = data.count and data.count > 1 and ('x' .. tostring(data.count)) or ''

    setTooltipFieldIcon(fields, 's3ui_tooltip_type', typeIcon(data))
    setTooltipFieldIcon(fields, 's3ui_tooltip_reach', TOOLTIP_ICONS.reach)
    setTooltipFieldIcon(fields, 's3ui_tooltip_speed', TOOLTIP_ICONS.speed)
    setTooltipFieldIcon(fields, 's3ui_tooltip_damage', TOOLTIP_ICONS.damage)
    setTooltipFieldIcon(fields, 's3ui_tooltip_effectiveness', TOOLTIP_ICONS.damageSpeed)

    local itemType = data.item and data.item.type
    local valueText = record and type(record.value) == 'number' and tostring(record.value) or EMPTY_FIELD
    local weightText = formatNumber(record and record.weight, 2)
    local goldPerWeightText = goldPerWeight(record)
    local conditionText = formatCondition(data.condition)
    local visibleFields = { 's3ui_tooltip_type' }

    setTooltipField(fields, 's3ui_tooltip_type', typeText(data))
    setTooltipField(fields, 's3ui_tooltip_value', valueText)
    setTooltipField(fields, 's3ui_tooltip_weight', weightText)
    setTooltipField(fields, 's3ui_tooltip_gold_per_weight', goldPerWeightText)
    setTooltipField(fields, 's3ui_tooltip_condition', conditionText)

    addTooltipField(visibleFields, 's3ui_tooltip_value', valueText)
    addTooltipField(visibleFields, 's3ui_tooltip_weight', weightText)
    addTooltipField(visibleFields, 's3ui_tooltip_gold_per_weight', goldPerWeightText)
    addTooltipField(visibleFields, 's3ui_tooltip_condition', conditionText)

    if itemType == types.Weapon then
        local reachText = formatNumber(record and record.reach, 2)
        local speedText = formatNumber(record and record.speed, 2)
        local damageText = bestWeaponDamage(record)
        local effectivenessText = formatNumber(data.effectiveness, 2)
        setTooltipField(fields, 's3ui_tooltip_reach', reachText)
        setTooltipField(fields, 's3ui_tooltip_speed', speedText)
        setTooltipField(fields, 's3ui_tooltip_damage', damageText)
        setTooltipField(fields, 's3ui_tooltip_effectiveness', effectivenessText)
        addTooltipField(visibleFields, 's3ui_tooltip_reach', reachText)
        addTooltipField(visibleFields, 's3ui_tooltip_speed', speedText)
        addTooltipField(visibleFields, 's3ui_tooltip_damage', damageText)
        addTooltipField(visibleFields, 's3ui_tooltip_effectiveness', effectivenessText)
    elseif itemType == types.Armor then
        local armorText = formatNumber(record and record.baseArmor, 0)
        setTooltipFieldIcon(fields, 's3ui_tooltip_reach', TOOLTIP_ICONS.armorRating)
        setTooltipField(fields, 's3ui_tooltip_reach', armorText)
        setTooltipField(fields, 's3ui_tooltip_speed', '')
        setTooltipField(fields, 's3ui_tooltip_damage', '')
        setTooltipField(fields, 's3ui_tooltip_effectiveness', '')
        addTooltipField(visibleFields, 's3ui_tooltip_reach', armorText)
    else
        setTooltipField(fields, 's3ui_tooltip_reach', '')
        setTooltipField(fields, 's3ui_tooltip_speed', '')
        setTooltipField(fields, 's3ui_tooltip_damage', '')
        setTooltipField(fields, 's3ui_tooltip_effectiveness', '')
    end

    local visibleCount = setTooltipVisibleFields(fields, visibleFields)
    local relativeSize = tooltipRelativeSize(visibleCount)
    local height = tooltipPixelHeight(visibleCount)
    tooltipElement.layout.props.relativeSize = relativeSize
    tooltipElement.layout.props.position = tooltipPosition(relativeSize)
    bodyContent.s3ui_tooltip_header.props.relativeSize = v2(1, TOOLTIP_HEADER_HEIGHT / height)
    fields.props.relativeSize = v2(1, visibleCount * TOOLTIP_FIELD_ROW_HEIGHT / height)

    tooltipElement.layout.props.visible = true
    tooltipElement:update()
end

local function queueInventoryRebuild(statusText)
    hideTooltip()
    pendingRebuildStatus = statusText or ''
    if rebuildEventQueued then return end
    rebuildEventQueued = true
    self:sendEvent('S3UI_RebuildInventory')
end

local function controlBackground(active)
    return {
        type = ui.TYPE.Image,
        props = {
            resource = WHITE_TEXTURE,
            color = active and CATEGORY_ACTIVE_COLOR or CATEGORY_COLLAPSED_COLOR,
            alpha = active and 0.55 or 0.25,
            relativeSize = v2(1, 1),
        },
    }
end

local function controlText(name, text, textSize)
    return tooltipText(name, text, {
        relativeSize = v2(1, 1),
        textSize = textSize or 14,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        multiline = true,
        wordWrap = true,
        autoSize = false,
    })
end

local function makeControlButton(name, label, active, props, external, onClick)
    local generation = uiGeneration
    return {
        name = name,
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = props,
        external = external,
        events = {
            focusGain = async:callback(function()
                hideTooltip()
            end),
            mouseClick = async:callback(function()
                if generation ~= uiGeneration then return end
                hideTooltip()
                if onClick then onClick() end
            end),
        },
        content = ui.content {
            controlBackground(active),
            controlText(name .. '_text', label),
        },
    }
end

local function makeSortButton(mode, label)
    local active = sortMode == mode
    local directionLabel = sortAscending[mode] and ' ^' or ' v'
    local buttonLabel = active and (label .. directionLabel) or label
    return makeControlButton('s3ui_sort_' .. mode, buttonLabel, active, {
        size = CONTROL_BUTTON_SIZE,
    }, { stretch = 1 }, function()
        if sortMode == mode then
            sortAscending[mode] = not sortAscending[mode]
        end
        sortMode = mode
        resetScrollOffset()
        queueInventoryRebuild('Sorted by ' .. label .. (sortAscending[mode] and ' ascending' or ' descending'))
    end)
end

local function inventoryWindowActive()
    return rootElement and rootElement.layout and I.UI.isWindowVisible(WINDOW)
end

local function scrollInventoryRows(deltaRows)
    if not inventoryWindowActive() then return end
    local oldOffset = scrollOffset
    scrollOffset = scrollOffset + deltaRows * GRID_COLUMNS
    clampScrollOffset(lastEntryCount)
    if scrollOffset == oldOffset then return end
    queueInventoryRebuild()
end

local function makeViewButton(mode, label)
    return makeControlButton('s3ui_view_' .. mode, label, viewMode == mode, {
        size = VIEW_BUTTON_SIZE,
    }, { stretch = 1 }, function()
        if mode == 'grid' then
            viewMode = 'grid'
            queueInventoryRebuild('Grid view')
        else
            setStatus('List view is not implemented yet')
        end
    end)
end

local function makeCategoryRailButton(category)
    return makeControlButton('s3ui_category_' .. category.key, category.label, selectedCategory == category.key, {
        relativeSize = v2(1, 1 / #CATEGORY_ORDER),
    }, nil, function()
        selectedCategory = category.key
        resetScrollOffset()
        queueInventoryRebuild(category.label .. ' selected')
    end)
end

local function makeCategoryRail()
    local buttons = ui.content {}
    for _, category in ipairs(CATEGORY_ORDER) do
        buttons:add(makeCategoryRailButton(category))
    end

    return {
        name = 's3ui_category_rail',
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = CATEGORY_RAIL_SIZE,
            autoSize = false,
        },
        external = { stretch = 1 },
        content = buttons,
    }
end

local function makeToolbar()
    return {
        name = 's3ui_toolbar',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            relativeSize = TOOLBAR_RELATIVE_SIZE,
            autoSize = false,
        },
        content = ui.content {
            tooltipText('s3ui_title', 'Inventory', {
                size = v2(120, 0),
                textSize = 22,
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                autoSize = false,
            }, I.MWUI.templates.textHeader, { stretch = 1 }),
            makeViewButton('grid', 'Grid'),
            makeViewButton('list', 'List'),
            { external = { grow = 1 } },
            makeSortButton('value', 'Gold'),
            makeSortButton('weight', 'Wt'),
            makeSortButton('effectiveness', 'Eff'),
            makeSortButton('condition', 'Cond'),
        },
    }
end

local function makeCategoryHeaderSlot(entry, index)
    local collapsed = entry.collapsed
    local generation = uiGeneration
    local icon = CATEGORY_ICON_TEXTURES[entry.categoryKey]
    local iconSize = CATEGORY_ICON_RELATIVE_SIZES[entry.categoryKey] or v2(0.58, 0.58)
    local content = ui.content {
        {
            type = ui.TYPE.Image,
            props = {
                resource = WHITE_TEXTURE,
                color = collapsed and CATEGORY_COLLAPSED_COLOR or CATEGORY_HEADER_COLOR,
                alpha = 0.72,
                relativeSize = v2(1, 1),
            },
        },
    }

    if icon then
        content:add {
            name = 'slot_' .. tostring(index) .. '_category_icon',
            type = ui.TYPE.Image,
            props = {
                resource = icon,
                anchor = v2(0.5, 0.5),
                relativePosition = v2(0.5, 0.48),
                relativeSize = iconSize,
                alpha = collapsed and 0.62 or 0.95,
            },
        }
    else
        content:add(controlText('slot_' .. tostring(index) .. '_category_text', entry.label, 13))
    end

    content:add(textLine(collapsed and '+' or '-', I.MWUI.templates.textHeader, {
        name = 'slot_' .. tostring(index) .. '_category_toggle',
        anchor = v2(0, 0),
        relativePosition = v2(0.08, 0.06),
        relativeSize = CATEGORY_ICON_TOGGLE_SIZE,
        textSize = 16,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        autoSize = false,
    }))

    content:add(textLine(tostring(entry.count), I.MWUI.templates.textNormal, {
        name = 'slot_' .. tostring(index) .. '_category_count',
        anchor = v2(1, 1),
        relativePosition = v2(0.92, 0.92),
        relativeSize = CATEGORY_ICON_COUNT_SIZE,
        textSize = 14,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
        autoSize = false,
    }))

    return {
        name = 'slot_' .. tostring(index),
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = v2(1 / GRID_COLUMNS, 1),
        },
        userData = entry,
        events = {
            focusGain = async:callback(function()
                hideTooltip()
            end),
            mouseClick = async:callback(function(_, layout)
                if generation ~= uiGeneration then return end
                local clicked = layout and layout.userData
                if not clicked then return end
                collapsedCategories[clicked.categoryKey] = not collapsedCategories[clicked.categoryKey]
                resetScrollOffset()
                queueInventoryRebuild(clicked.label .. (collapsedCategories[clicked.categoryKey] and ' collapsed' or ' expanded'))
            end),
        },
        content = content,
    }
end

local function makeSlot(entry, index)
    if entry and entry.kind == 'categoryHeader' then return makeCategoryHeaderSlot(entry, index) end

    local data = entry and entry.data
    local generation = uiGeneration
    local content = ui.content {}

    if data then
        local iconProps = {
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.45),
            relativeSize = ICON_RELATIVE_SIZE,
        }
        if data.icon then
            iconProps.resource = ui.texture { path = data.icon }
        end

        content:add {
            type = ui.TYPE.Image,
            props = iconProps,
        }

        if data.count > 1 then
            content:add(textLine(tostring(data.count), I.MWUI.templates.textNormal, {
                anchor = v2(1, 1),
                relativePosition = v2(0.88, 0.88),
                relativeSize = COUNT_RELATIVE_SIZE,
                textSize = 13,
            }))
        end
    else
        content:add {
            type = ui.TYPE.Widget,
            props = { relativeSize = v2(1, 1) },
        }
    end

    return {
        name = 'slot_' .. tostring(index),
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = v2(1 / GRID_COLUMNS, 1),
        },
        userData = data,
        events = data and {
            focusGain = async:callback(function(mouseEvent, layout)
                if generation ~= uiGeneration then return end
                updateTooltip(layout and layout.userData, mouseEvent)
            end),
            focusLoss = async:callback(function()
                if generation ~= uiGeneration then return end
                hideTooltip()
            end),
            mouseClick = async:callback(function(_, layout)
                if generation ~= uiGeneration then return end
                local clicked = layout and layout.userData
                if clicked then
                    setStatus(clicked.name .. '  x' .. tostring(clicked.count))
                end
            end),
        } or nil,
        content = content,
    }
end

local function makeGrid(items, firstIndex)
    local rows = ui.content {}
    local index = firstIndex or 1
    local slotIndex = 1

    for _ = 1, GRID_ROWS do
        local row = ui.content {}
        for _ = 1, GRID_COLUMNS do
            row:add(makeSlot(items[index], slotIndex))
            index = index + 1
            slotIndex = slotIndex + 1
        end
        rows:add {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                relativeSize = v2(1, 1 / GRID_ROWS),
                autoSize = false,
            },
            content = row,
        }
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = v2(0, 0),
            autoSize = false,
        },
        external = { grow = 1, stretch = 1 },
        content = rows,
    }
end

local function makeInventoryLayout(items)
    local entries = buildDisplayEntries(items)
    lastEntryCount = #entries
    local maxOffset = clampScrollOffset(#entries)
    local firstIndex = scrollOffset + 1
    local lastIndex = math.min(#entries, scrollOffset + MAX_VISIBLE_ITEMS)
    local summary
    if #entries == 0 then
        summary = '0 entries'
    else
        summary = 'Entries ' .. tostring(firstIndex) .. '–' .. tostring(lastIndex) .. ' of ' .. tostring(#entries)
        if maxOffset > 0 then summary = summary .. '  |  Wheel/PageUp/PageDown scroll by row' end
    end

    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        layer = ROOT_LAYER,
        props = {
            position = WINDOW_POSITION,
            size = WINDOW_SIZE,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEXTURE,
                    color = BACKGROUND_COLOR,
                    alpha = backgroundAlpha(),
                    relativeSize = v2(1, 1),
                },
            },
            {
                name = 's3ui_body',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    relativeSize = v2(1, 1),
                    autoSize = false,
                },
                content = ui.content {
                    makeToolbar(),
                    textLine('Click an item header to collapse a category. Press I to close.', I.MWUI.templates.textNormal, { relativeSize = HINT_RELATIVE_SIZE, textSize = 15 }),
                    {
                        name = 's3ui_main',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            relativeSize = MAIN_RELATIVE_SIZE,
                            autoSize = false,
                        },
                        external = { grow = 1 },
                        content = ui.content {
                            makeCategoryRail(),
                            makeGrid(entries, firstIndex),
                        },
                    },
                    textLine(summary, I.MWUI.templates.textNormal, { name = 's3ui_status', relativeSize = STATUS_RELATIVE_SIZE, textSize = 15 }),
                },
            },
        },
    }
end

local function saveCamera()
    if cameraSnapshot then return end
    cameraSnapshot = {
        mode = camera.getMode(),
        yaw = camera.getYaw(),
        pitch = camera.getPitch(),
        focalOffset = camera.getFocalPreferredOffset(),
        staticPosition = camera.getPosition(),
    }
end

local function disableInventoryCameraControls()
    if not I.Camera then return end
    if I.Camera.disableModeControl then I.Camera.disableModeControl(CAMERA_CONTROL_TAG) end
    if I.Camera.disableZoom then I.Camera.disableZoom(CAMERA_CONTROL_TAG) end
    if I.Camera.disableThirdPersonOffsetControl then I.Camera.disableThirdPersonOffsetControl(CAMERA_CONTROL_TAG) end
end

local function enableInventoryCameraControls()
    if not I.Camera then return end
    if I.Camera.enableThirdPersonOffsetControl then I.Camera.enableThirdPersonOffsetControl(CAMERA_CONTROL_TAG) end
    if I.Camera.enableZoom then I.Camera.enableZoom(CAMERA_CONTROL_TAG) end
    if I.Camera.enableModeControl then I.Camera.enableModeControl(CAMERA_CONTROL_TAG) end
end

local function restoreCamera()
    if not cameraSnapshot then return end
    enableInventoryCameraControls()

    camera.setFocalPreferredOffset(cameraSnapshot.focalOffset)
    camera.setYaw(cameraSnapshot.yaw)
    camera.setPitch(cameraSnapshot.pitch)
    camera.setMode(cameraSnapshot.mode, true)

    if cameraSnapshot.mode == camera.MODE.Static then
        camera.setStaticPosition(cameraSnapshot.staticPosition)
    end

    camera.instantTransition()
    cameraSnapshot = nil
end

local function playerFrame(box, screenRight)
    local top = box.center.z + box.halfSize.z
    local bottom = box.center.z - box.halfSize.z
    local rightEdge = box.halfSize.x
    local leftEdge = -box.halfSize.x

    if box.vertices then
        top = -math.huge
        bottom = math.huge
        rightEdge = -math.huge
        leftEdge = math.huge

        for _, vertex in ipairs(box.vertices) do
            if vertex.z > top then top = vertex.z end
            if vertex.z < bottom then bottom = vertex.z end

            local offset = vertex - box.center
            local projectedRight = offset * screenRight
            if projectedRight > rightEdge then rightEdge = projectedRight end
            if projectedRight < leftEdge then leftEdge = projectedRight end
        end
    end

    return {
        target = v3(box.center.x, box.center.y, (top + bottom) * 0.5),
        halfHeight = (top - bottom) * 0.5,
        rightEdge = rightEdge,
        width = rightEdge - leftEdge,
    }
end

local function saveHudVisibility()
    if hudVisibleSnapshot ~= nil then return end
    hudVisibleSnapshot = I.UI.isHudVisible()
    I.UI.setHudVisibility(false)
end

local function restoreHudVisibility()
    if hudVisibleSnapshot == nil then return end
    I.UI.setHudVisibility(hudVisibleSnapshot)
    hudVisibleSnapshot = nil
end

local function showStaticInventoryCamera()
    saveCamera()
    disableInventoryCameraControls()

    local actorYaw = self.object.rotation:getYaw()
    local front = util.transform.rotateZ(actorYaw) * v3(0, 1, 0)
    local screenRight = util.transform.rotateZ(actorYaw) * v3(-1, 0, 0)
    local bodyBounds = self.object:getBoundingBox()
    local frame = playerFrame(bodyBounds, screenRight)
    local screen = ui.screenSize()
    local aspect = screen.x / screen.y
    local verticalTan = math.tan(camera.getFieldOfView() * 0.5)
    local distance = frame.halfHeight / verticalTan + STATIC_CAMERA_EXTRA_DISTANCE
    local halfViewWidth = distance * verticalTan * aspect
    local lateralOffset = halfViewWidth - frame.rightEdge - frame.width
    local pos = frame.target + front * distance - screenRight * lateralOffset

    camera.setMode(camera.MODE.Static, true)
    camera.setStaticPosition(pos)
    camera.setYaw(actorYaw + math.pi)
    camera.setPitch(0)
    camera.instantTransition()
end

local function toggleInventoryWindow()
    if I.UI.isWindowVisible(WINDOW) then
        I.UI.removeMode(MODE)
    else
        I.UI.setMode(MODE, { windows = { WINDOW } })
    end
end

local function destroyInventoryWindow()
    uiGeneration = uiGeneration + 1
    pendingRebuildStatus = nil
    rebuildEventQueued = false
    statusLayout = nil
    if tooltipElement and tooltipElement.layout then
        tooltipElement:destroy()
    end
    tooltipElement = nil
    if rootElement and rootElement.layout then
        rootElement:destroy()
    end
    rootElement = nil
end

rebuildInventoryRoot = function(statusText)
    uiGeneration = uiGeneration + 1
    hideTooltip()
    statusLayout = nil
    if rootElement and rootElement.layout then
        rootElement:destroy()
    end
    rootElement = ui.create(makeInventoryLayout(collectInventoryItems()))
    statusLayout = rootElement.layout.content.s3ui_body.content.s3ui_status
    if statusText then setStatus(statusText) end
end

local function processPendingRebuild()
    rebuildEventQueued = false
    if pendingRebuildStatus == nil then return end
    local statusText = pendingRebuildStatus
    pendingRebuildStatus = nil
    if not rootElement or not rootElement.layout or not I.UI.isWindowVisible(WINDOW) then return end
    rebuildInventoryRoot(statusText ~= '' and statusText or nil)
end

local function showInventoryWindow()
    destroyInventoryWindow()
    saveHudVisibility()
    showStaticInventoryCamera()
    rebuildInventoryRoot()
    ensureTooltipLayer()
    tooltipElement = ui.create(makeTooltipLayout())
end

local function hideInventoryWindow()
    destroyInventoryWindow()
    restoreCamera()
    restoreHudVisibility()
end

local function registerInventoryWindow()
    if registeredWindow then return end
    I.UI.registerWindow(WINDOW, showInventoryWindow, hideInventoryWindow)
    registeredWindow = true
end

registerInventoryWindow()

return {
    engineHandlers = {
        onKeyPress = function(key)
            if key.code == input.KEY.I then
                toggleInventoryWindow()
            elseif key.code == input.KEY.PageUp or key.code == input.KEY.UpArrow then
                scrollInventoryRows(-1)
            elseif key.code == input.KEY.PageDown or key.code == input.KEY.DownArrow then
                scrollInventoryRows(1)
            elseif key.code == input.KEY.Home then
                if not inventoryWindowActive() then return end
                if scrollOffset ~= 0 then
                    scrollOffset = 0
                    queueInventoryRebuild()
                end
            elseif key.code == input.KEY.End then
                if not inventoryWindowActive() then return end
                local oldOffset = scrollOffset
                scrollOffset = maxScrollOffset(lastEntryCount)
                if scrollOffset ~= oldOffset then queueInventoryRebuild() end
            end
        end,
        onMouseWheel = function(vertical, _horizontal)
            if type(vertical) ~= 'number' then return end
            if vertical > 0 then
                scrollInventoryRows(-1)
            elseif vertical < 0 then
                scrollInventoryRows(1)
            end
        end,
    },
    eventHandlers = {
        S3UI_RebuildInventory = processPendingRebuild,
    },
}
