---@omw-context player

local async = require 'openmw.async'
local camera = require 'openmw.camera'
local omwDebug = require 'openmw.debug'
local input = require 'openmw.input'
local I = require 'openmw.interfaces'
local self = require 'openmw.self'
local storage = require 'openmw.storage'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local inventoryData = require 'scripts.s3ui.inventory.data'
local inventoryLayout = require 'scripts.s3ui.inventory.layout'

local v2 = util.vector2
local v3 = util.vector3

local WINDOW = I.UI.WINDOW.Inventory
local MODE = I.UI.MODE.Interface
local ROOT_LAYER = 'Windows'
local CAMERA_CONTROL_TAG = 's3ui_inventory'
local DEV_RELOAD_SECTION = 'S3UI_DevReload'
local DEV_RELOAD_REOPEN_KEY = 'reopenInventory'
local EMPTY_FIELD = inventoryData.EMPTY_FIELD
local CATEGORY_ORDER = inventoryData.CATEGORY_ORDER
local collectInventoryItems = inventoryData.collectItems
local itemName = inventoryData.itemName
local formatNumber = inventoryData.formatNumber
local formatCondition = inventoryData.formatCondition
local weaponDamageFields = inventoryData.weaponDamageFields
local typeText = inventoryData.typeText
local goldPerWeight = inventoryData.goldPerWeight

local WHITE_TEXTURE = ui.texture { path = 'white' }
local CATEGORY_ICON_ATLAS = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/category_icons.dds'
local CATEGORY_SMALL_ICON_ATLAS = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/small_icons.dds'
local BACKGROUND_COLOR = util.color.rgb(0, 0, 0)
local ICON_RELATIVE_SIZE = v2(0.58, 0.58)
local COUNT_RELATIVE_SIZE = v2(0.28, 0.22)
local ITEM_STATE_BADGE_RELATIVE_SIZE = v2(0.22, 0.22)
local LIST_STATE_BADGE_SIZE = v2(0.04, 0.24)
local CATEGORY_ICON_COUNT_SIZE = v2(0.34, 0.24)
local CATEGORY_ICON_TOGGLE_SIZE = v2(0.24, 0.24)
local STATIC_CAMERA_EXTRA_DISTANCE = 15
local MAIN_RELATIVE_SIZE = v2(1, 0)
local VIEW_TOGGLE_ICON_SIZE = v2(0.74, 0.74)
local SORT_ICON_RELATIVE_SIZE = v2(0.68, 0.68)
local SORT_DIRECTION_RELATIVE_SIZE = v2(0.34, 0.34)
local CATEGORY_HEADER_COLOR = util.color.rgb(0.18, 0.36, 0.68)
local CATEGORY_ACTIVE_COLOR = util.color.rgb(0.24, 0.47, 0.86)
local CATEGORY_COLLAPSED_COLOR = util.color.rgb(0.12, 0.18, 0.28)
local VIEW_GLYPH_COLOR = util.color.rgb(0.9, 0.84, 0.62)
local TOOLTIP_LAYER = 'S3UI_Tooltip'
local TOOLTIP_FIELD_ROW_COUNT = 11
local COMPACT_DETAIL_FIELD_COLUMNS = 4
local COMPACT_DETAIL_FIELD_ROWS = 3
local COMPACT_DETAIL_FIELD_SLOT_COUNT = COMPACT_DETAIL_FIELD_COLUMNS * COMPACT_DETAIL_FIELD_ROWS
local ACTIVE_MAIN_MENU_KEY = 'inventory'
local LIST_FIELD_WIDTH = 0.12
local LIST_FIELD_HEIGHT = 0.72
local LIST_FIELD_RIGHT_EDGE = {
    value = 0.68,
    weight = 0.8,
    effectiveness = 0.9,
    condition = 0.99,
}

local TOOLTIP_ICONS = {
    typeGeneric = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_generic.dds' },
    typeWeapon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_weapon.dds' },
    typeRangedWeapon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/tooltips/type_ranged_weapon.dds' },
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

local SORT_ICONS = {
    value = TOOLTIP_ICONS.value,
    weight = TOOLTIP_ICONS.weight,
    effectiveness = TOOLTIP_ICONS.damageSpeed,
    condition = TOOLTIP_ICONS.condition,
}

local SORT_DIRECTION_ICONS = {
    ascending = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/sort/ascending.dds' },
    descending = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/sort/descending.dds' },
}

local devReloadStorage = storage.playerSection(DEV_RELOAD_SECTION)
devReloadStorage:setLifeTime(storage.LIFE_TIME.GameSession)

local RANGED_WEAPON_TYPES = {
    [types.Weapon.TYPE.Arrow] = true,
    [types.Weapon.TYPE.Bolt] = true,
    [types.Weapon.TYPE.MarksmanBow] = true,
    [types.Weapon.TYPE.MarksmanCrossbow] = true,
    [types.Weapon.TYPE.MarksmanThrown] = true,
}

local TOOLTIP_FIELD_NAMES = {
    's3ui_tooltip_type',
    's3ui_tooltip_value',
    's3ui_tooltip_weight',
    's3ui_tooltip_gold_per_weight',
    's3ui_tooltip_condition',
    's3ui_tooltip_reach',
    's3ui_tooltip_speed',
    's3ui_tooltip_chop_damage',
    's3ui_tooltip_slash_damage',
    's3ui_tooltip_thrust_damage',
    's3ui_tooltip_effectiveness',
}

local DETAIL_FIELD_NAMES = {
    type = 's3ui_tooltip_type',
    value = 's3ui_tooltip_value',
    weight = 's3ui_tooltip_weight',
    goldPerWeight = 's3ui_tooltip_gold_per_weight',
    condition = 's3ui_tooltip_condition',
    reach = 's3ui_tooltip_reach',
    speed = 's3ui_tooltip_speed',
    chopDamage = 's3ui_tooltip_chop_damage',
    slashDamage = 's3ui_tooltip_slash_damage',
    thrustDamage = 's3ui_tooltip_thrust_damage',
    effectiveness = 's3ui_tooltip_effectiveness',
}

local rootElement = nil
local tooltipElement = nil
local compactDetailVisible = false
local cameraSnapshot = nil
local hudVisibleSnapshot = nil
local registeredWindow = false
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
local rebuildInventoryPending = false
local rebuildEventQueued = false
local rebuildInventoryRoot = nil
local scrollOffset = 0
local lastEntryCount = 0
local activeLayoutMetrics = nil

local CATEGORY_ICON_TEXTURES = {
    all = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(25, 29), size = v2(206, 204) },
    weapons = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(284, 3), size = v2(224, 225) },
    armor = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(555, 0), size = v2(169, 256) },
    apparel = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(17, 536), size = v2(222, 226) },
    alchemy = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(802, 25), size = v2(194, 212) },
    books = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(4, 260), size = v2(247, 241) },
    tools = ui.texture { path = CATEGORY_SMALL_ICON_ATLAS, offset = v2(786, 2), size = v2(86, 124) },
    misc = ui.texture { path = CATEGORY_ICON_ATLAS, offset = v2(1074, 29), size = v2(153, 207) },
}

local VIEW_TOGGLE_ICON = ui.texture { path = CATEGORY_SMALL_ICON_ATLAS, offset = v2(385, 1), size = v2(126, 126) }

local ITEM_STATE_ICONS = {
    equipped = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/status/equipped.dds' },
    enchanted = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/status/enchanted.dds' },
    broken = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/inventory/status/broken.dds' },
}

local MAIN_MENU_BUTTONS = {
    {
        key = 'inventory',
        icon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/inventory.dds' },
    },
    {
        key = 'magic',
        icon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/magic.dds' },
    },
    {
        key = 'journal',
        icon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/journal.dds' },
    },
    {
        key = 'character',
        icon = ui.texture { path = 'textures/s3ui/presets/coffee_ui/dark_s3ctor/menu/character.dds' },
    },
}

local CATEGORY_ICON_RELATIVE_SIZES = {
    all = v2(0.62, 0.58),
    weapons = v2(0.7, 0.6),
    armor = v2(0.48, 0.66),
    apparel = v2(0.58, 0.58),
    alchemy = v2(0.6, 0.62),
    books = v2(0.66, 0.6),
    tools = v2(0.44, 0.6),
    misc = v2(0.46, 0.58),
}

local function textProps(text, props)
    local result = {}
    if props then
        for key, value in pairs(props) do
            if key ~= 'name' then result[key] = value end
        end
    end
    result.text = text
    return result
end

local function textLine(text, template, props)
    local name = props and props.name or nil
    return {
        name = name,
        template = template or I.MWUI.templates.textNormal,
        props = textProps(text, props),
    }
end

local function typeIcon(data)
    local itemType = data and data.item and data.item.type
    if itemType == types.Weapon then
        local weaponType = data and data.record and data.record.type
        if RANGED_WEAPON_TYPES[weaponType] then return TOOLTIP_ICONS.typeRangedWeapon end
        return TOOLTIP_ICONS.typeWeapon
    end
    if itemType == types.Armor or itemType == types.Clothing then return TOOLTIP_ICONS.typeArmor end
    if itemType == types.Book then return TOOLTIP_ICONS.typeBook end
    return TOOLTIP_ICONS.typeGeneric
end

local function backgroundAlpha()
    return ui._getMenuTransparency()
end

local function layoutMetrics()
    return activeLayoutMetrics or inventoryLayout.compute()
end

local function ensureTooltipLayer()
    if ui.layers.indexOf(TOOLTIP_LAYER) == nil then
        ui.layers.insertAfter(ROOT_LAYER, TOOLTIP_LAYER, { interactive = false })
    end
end

local function tooltipPixelHeight(rowCount, metrics)
    metrics = metrics or layoutMetrics()
    if type(rowCount) ~= 'number' or rowCount < 1 then rowCount = 1 end
    return metrics.tooltipHeaderHeight + rowCount * metrics.tooltipFieldRowHeight + metrics.tooltipPadding
end

local function tooltipRelativeSize(rowCount, screen, metrics)
    metrics = metrics or layoutMetrics()
    screen = screen or metrics.screen or ui.screenSize()
    return v2(metrics.tooltipWidth / screen.x, tooltipPixelHeight(rowCount, metrics) / screen.y)
end

local function tooltipPosition(relativeSize)
    local screen = ui.screenSize()
    local metrics = layoutMetrics()
    relativeSize = relativeSize or tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT, screen, metrics)
    local size = v2(screen.x * relativeSize.x, screen.y * relativeSize.y)
    local preferred = v2(metrics.windowPosition.x + metrics.windowSize.x, metrics.windowPosition.y)
    local x = preferred.x
    local y = preferred.y
    if x + size.x > screen.x - metrics.tooltipMargin.x then x = screen.x - size.x - metrics.tooltipMargin.x end
    if y + size.y > screen.y - metrics.tooltipMargin.y then y = screen.y - size.y - metrics.tooltipMargin.y end
    if x < metrics.tooltipMargin.x then x = metrics.tooltipMargin.x end
    if y < metrics.tooltipMargin.y then y = metrics.tooltipMargin.y end
    return v2(x, y)
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
        if category.key ~= 'all' then
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
    local metrics = layoutMetrics()
    if viewMode == 'list' then
        local extraRows = entryCount - metrics.listRows
        if extraRows <= 0 then return 0 end
        return extraRows
    end

    local extraRows = math.ceil(entryCount / metrics.gridColumns) - metrics.gridRows
    if extraRows <= 0 then return 0 end
    return extraRows * metrics.gridColumns
end

local function scrollStepSize()
    if viewMode == 'list' then return 1 end
    return layoutMetrics().gridColumns
end

local function clampScrollOffset(entryCount)
    local maxOffset = maxScrollOffset(entryCount)
    local step = scrollStepSize()
    if scrollOffset < 0 then scrollOffset = 0 end
    if scrollOffset > maxOffset then scrollOffset = maxOffset end
    scrollOffset = math.floor(scrollOffset / step) * step
    return maxOffset
end

local function resetScrollOffset()
    scrollOffset = 0
end

local function tooltipText(name, text, props, template, external)
    return {
        name = name,
        template = template or I.MWUI.templates.textNormal,
        external = external,
        props = textProps(text, props),
    }
end

local function tooltipField(name, icon)
    local metrics = layoutMetrics()
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
                },
                content = ui.content {
                    {
                        name = name .. '_icon',
                        type = ui.TYPE.Image,
                        props = {
                            resource = icon,
                            anchor = v2(0.5, 0.5),
                            relativePosition = v2(0.5, 0.5),
                            size = metrics.tooltipFieldIconSize,
                        },
                    },
                },
            },
            tooltipText(name .. '_value', EMPTY_FIELD, {
                relativeSize = v2(0.84, 1),
                textSize = metrics.tooltipValueTextSize,
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

local function detailValueVisible(value)
    return value ~= nil and value ~= '' and value ~= EMPTY_FIELD
end

local function addDetailField(fields, key, icon, value, compactValue)
    if not detailValueVisible(value) then return end
    fields[#fields + 1] = {
        key = key,
        icon = icon,
        value = value,
        compactValue = compactValue or value,
    }
end

local function buildDetailModel(data)
    if not data then return nil end

    local record = data.record
    local fields = {}
    local valueText = record and type(record.value) == 'number' and tostring(record.value) or EMPTY_FIELD
    local weightText = formatNumber(record and record.weight, 2)
    local goldPerWeightText = goldPerWeight(record)
    local conditionText = formatCondition(data.condition)
    local itemType = data.item and data.item.type

    addDetailField(fields, 'type', typeIcon(data), typeText(data))
    addDetailField(fields, 'value', TOOLTIP_ICONS.value, valueText)
    addDetailField(fields, 'weight', TOOLTIP_ICONS.weight, weightText)
    addDetailField(fields, 'goldPerWeight', TOOLTIP_ICONS.goldPerWeight, goldPerWeightText)
    addDetailField(fields, 'condition', TOOLTIP_ICONS.condition, conditionText)

    if itemType == types.Weapon then
        addDetailField(fields, 'reach', TOOLTIP_ICONS.reach, formatNumber(record and record.reach, 2))
        addDetailField(fields, 'speed', TOOLTIP_ICONS.speed, formatNumber(record and record.speed, 2))
        for _, damage in ipairs(weaponDamageFields(record)) do
            addDetailField(fields, damage.key, TOOLTIP_ICONS.damage, damage.text, damage.compactText)
        end
        addDetailField(fields, 'effectiveness', TOOLTIP_ICONS.damageSpeed, formatNumber(data.effectiveness, 2))
    elseif itemType == types.Armor then
        addDetailField(fields, 'reach', TOOLTIP_ICONS.armorRating, formatNumber(record and record.baseArmor, 0))
    end

    return {
        icon = data.icon and ui.texture { path = data.icon } or WHITE_TEXTURE,
        name = data.name or itemName(data.item, record),
        fields = fields,
    }
end

local function makeTooltipLayout()
    local metrics = layoutMetrics()
    local defaultHeight = tooltipPixelHeight(TOOLTIP_FIELD_ROW_COUNT, metrics)
    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        layer = TOOLTIP_LAYER,
        props = {
            position = tooltipPosition(),
            relativeSize = tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT, nil, metrics),
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
                            relativeSize = v2(1, metrics.tooltipHeaderHeight / defaultHeight),
                            autoSize = false,
                        },
                        content = ui.content {
                            {
                                name = 's3ui_tooltip_icon_box',
                                type = ui.TYPE.Widget,
                                props = {
                                    relativeSize = v2(0.18, 1),
                                },
                                content = ui.content {
                                    {
                                        name = 's3ui_tooltip_icon',
                                        type = ui.TYPE.Image,
                                        props = {
                                            size = metrics.tooltipHeaderIconSize,
                                            anchor = v2(0.5, 0.5),
                                            relativePosition = v2(0.5, 0.5),
                                        },
                                    },
                                },
                            },
                            tooltipText('s3ui_tooltip_name', EMPTY_FIELD, {
                                relativeSize = v2(0.82, 1),
                                textSize = metrics.tooltipHeaderTextSize,
                                textAlignH = ui.ALIGNMENT.Start,
                                textAlignV = ui.ALIGNMENT.Center,
                                multiline = true,
                                wordWrap = true,
                                autoSize = false,
                            }, I.MWUI.templates.textHeader),
                        },
                    },
                    {
                        name = 's3ui_tooltip_fields',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            relativeSize = v2(1, TOOLTIP_FIELD_ROW_COUNT * metrics.tooltipFieldRowHeight / defaultHeight),
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
                            tooltipField('s3ui_tooltip_chop_damage', TOOLTIP_ICONS.damage),
                            tooltipField('s3ui_tooltip_slash_damage', TOOLTIP_ICONS.damage),
                            tooltipField('s3ui_tooltip_thrust_damage', TOOLTIP_ICONS.damage),
                            tooltipField('s3ui_tooltip_effectiveness', TOOLTIP_ICONS.damageSpeed),
                        },
                    },
                },
            },
        },
    }
end

local hideCompactDetail

local function hideTooltip()
    if hideCompactDetail then hideCompactDetail() end
    if not tooltipElement or not tooltipElement.layout then return end
    tooltipElement.layout.props.visible = false
    tooltipElement:update()
end

local function updateTooltip(data)
    if not tooltipElement or not tooltipElement.layout or not data then return end
    local model = buildDetailModel(data)
    if not model then return end

    local bodyContent = tooltipElement.layout.content.s3ui_tooltip_body.content
    local header = bodyContent.s3ui_tooltip_header.content
    local fields = bodyContent.s3ui_tooltip_fields

    local headerIcon = header.s3ui_tooltip_icon_box.content.s3ui_tooltip_icon
    headerIcon.props.resource = model.icon
    header.s3ui_tooltip_name.props.text = model.name

    for key, name in pairs(DETAIL_FIELD_NAMES) do
        setTooltipField(fields, name, '')
        setTooltipFieldIcon(fields, name, key == 'type' and TOOLTIP_ICONS.typeGeneric or TOOLTIP_ICONS[key] or WHITE_TEXTURE)
    end

    local visibleFields = {}
    for _, field in ipairs(model.fields) do
        local tooltipName = DETAIL_FIELD_NAMES[field.key]
        if tooltipName then
            setTooltipField(fields, tooltipName, field.value)
            setTooltipFieldIcon(fields, tooltipName, field.icon)
            visibleFields[#visibleFields + 1] = tooltipName
        end
    end

    local metrics = layoutMetrics()
    local visibleCount = setTooltipVisibleFields(fields, visibleFields)
    local relativeSize = tooltipRelativeSize(visibleCount, nil, metrics)
    local height = tooltipPixelHeight(visibleCount, metrics)
    tooltipElement.layout.props.relativeSize = relativeSize
    tooltipElement.layout.props.position = tooltipPosition(relativeSize)
    bodyContent.s3ui_tooltip_header.props.relativeSize = v2(1, metrics.tooltipHeaderHeight / height)
    fields.props.relativeSize = v2(1, visibleCount * metrics.tooltipFieldRowHeight / height)

    tooltipElement.layout.props.visible = true
    tooltipElement:update()
end

local function compactDetailFieldSlot(slotIndex)
    local metrics = layoutMetrics()
    local name = 's3ui_compact_detail_field_' .. tostring(slotIndex)
    return {
        name = name,
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            relativeSize = v2(1 / COMPACT_DETAIL_FIELD_COLUMNS, 1),
            autoSize = false,
        },
        content = ui.content {
            {
                name = name .. '_icon_box',
                type = ui.TYPE.Widget,
                props = {
                    relativeSize = v2(0.28, 1),
                },
                content = ui.content {
                    {
                        name = name .. '_icon',
                        type = ui.TYPE.Image,
                        props = {
                            resource = WHITE_TEXTURE,
                            alpha = 0,
                            anchor = v2(0.5, 0.5),
                            relativePosition = v2(0.5, 0.5),
                            size = metrics.compactDetailFieldIconSize,
                        },
                    },
                },
            },
            tooltipText(name .. '_value', '', {
                relativeSize = v2(0.72, 1),
                textSize = metrics.compactDetailFieldTextSize,
                textAlignH = ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                multiline = true,
                wordWrap = true,
                autoSize = false,
            }),
        },
    }
end

local function makeCompactDetailFields()
    local rows = {}
    local slotIndex = 1
    for rowIndex = 1, COMPACT_DETAIL_FIELD_ROWS do
        local row = {}
        for _ = 1, COMPACT_DETAIL_FIELD_COLUMNS do
            row[#row + 1] = compactDetailFieldSlot(slotIndex)
            slotIndex = slotIndex + 1
        end
        rows[#rows + 1] = {
            name = 's3ui_compact_detail_row_' .. tostring(rowIndex),
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                relativeSize = v2(1, 1 / COMPACT_DETAIL_FIELD_ROWS),
                autoSize = false,
            },
            content = ui.content(row),
        }
    end
    return ui.content(rows)
end

local function makeCompactDetailBar()
    local metrics = layoutMetrics()
    return {
        name = 's3ui_compact_detail_bar',
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = metrics.compactDetailRelativeSize,
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
                name = 's3ui_compact_detail_content',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    relativeSize = v2(1, 1),
                    visible = false,
                    autoSize = false,
                },
                content = ui.content {
                    {
                        name = 's3ui_compact_detail_header',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = true,
                            relativeSize = metrics.compactDetailHeaderRelativeSize,
                            autoSize = false,
                        },
                        content = ui.content {
                            {
                                name = 's3ui_compact_detail_icon_box',
                                type = ui.TYPE.Widget,
                                props = {
                                    relativeSize = v2(0.36, 1),
                                },
                                content = ui.content {
                                    {
                                        name = 's3ui_compact_detail_icon',
                                        type = ui.TYPE.Image,
                                        props = {
                                            resource = WHITE_TEXTURE,
                                            anchor = v2(0.5, 0.5),
                                            relativePosition = v2(0.5, 0.5),
                                            size = metrics.compactDetailIconSize,
                                        },
                                    },
                                },
                            },
                            {
                                name = 's3ui_compact_detail_title_box',
                                type = ui.TYPE.Flex,
                                props = {
                                    horizontal = false,
                                    relativeSize = v2(0.64, 1),
                                    autoSize = false,
                                },
                                content = ui.content {
                                    tooltipText('s3ui_compact_detail_name', '', {
                                        relativeSize = v2(1, 1),
                                        textSize = metrics.compactDetailHeaderTextSize,
                                        textAlignH = ui.ALIGNMENT.Start,
                                        textAlignV = ui.ALIGNMENT.Center,
                                        multiline = true,
                                        wordWrap = true,
                                        autoSize = false,
                                    }, I.MWUI.templates.textHeader),
                                },
                            },
                        },
                    },
                    {
                        name = 's3ui_compact_detail_fields',
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            relativeSize = metrics.compactDetailFieldsRelativeSize,
                            autoSize = false,
                        },
                        content = makeCompactDetailFields(),
                    },
                },
            },
        },
    }
end

local function compactDetailFieldLayout(fieldsLayout, slotIndex)
    local rowIndex = math.floor((slotIndex - 1) / COMPACT_DETAIL_FIELD_COLUMNS) + 1
    return fieldsLayout.content['s3ui_compact_detail_row_' .. tostring(rowIndex)].content['s3ui_compact_detail_field_' .. tostring(slotIndex)]
end

local function clearCompactDetailField(fieldsLayout, slotIndex)
    local slot = compactDetailFieldLayout(fieldsLayout, slotIndex)
    local prefix = 's3ui_compact_detail_field_' .. tostring(slotIndex)
    local icon = slot.content[prefix .. '_icon_box'].content[prefix .. '_icon']
    local value = slot.content[prefix .. '_value']
    icon.props.resource = WHITE_TEXTURE
    icon.props.alpha = 0
    value.props.text = ''
end

local function setCompactDetailField(fieldsLayout, slotIndex, field)
    local slot = compactDetailFieldLayout(fieldsLayout, slotIndex)
    local prefix = 's3ui_compact_detail_field_' .. tostring(slotIndex)
    local icon = slot.content[prefix .. '_icon_box'].content[prefix .. '_icon']
    local value = slot.content[prefix .. '_value']
    icon.props.resource = field.icon
    icon.props.alpha = 0.95
    value.props.text = field.compactValue or field.value
end

local function compactDetailLayout()
    if not rootElement or not rootElement.layout then return nil end
    local body = rootElement.layout.content.s3ui_body
    if not body or not body.content then return nil end
    local ok, bar = pcall(function() return body.content.s3ui_compact_detail_bar end)
    if ok then return bar end
    return nil
end

hideCompactDetail = function()
    if not compactDetailVisible then return end
    local bar = compactDetailLayout()
    if not bar then
        compactDetailVisible = false
        return
    end
    bar.content.s3ui_compact_detail_content.props.visible = false
    compactDetailVisible = false
    rootElement:update()
end

local function updateCompactDetail(data)
    local model = buildDetailModel(data)
    local bar = compactDetailLayout()
    if not model or not bar then return end

    local content = bar.content.s3ui_compact_detail_content
    local detailContent = content.content
    local headerContent = detailContent.s3ui_compact_detail_header.content
    local titleContent = headerContent.s3ui_compact_detail_title_box.content
    local fields = detailContent.s3ui_compact_detail_fields

    headerContent.s3ui_compact_detail_icon_box.content.s3ui_compact_detail_icon.props.resource = model.icon
    titleContent.s3ui_compact_detail_name.props.text = model.name

    for slotIndex = 1, COMPACT_DETAIL_FIELD_SLOT_COUNT do
        local field = model.fields[slotIndex]
        if field then
            setCompactDetailField(fields, slotIndex, field)
        else
            clearCompactDetailField(fields, slotIndex)
        end
    end

    content.props.visible = true
    compactDetailVisible = true
    rootElement:update()
end

local function updateDetails(data)
    if layoutMetrics().detailMode == 'compact' then
        updateCompactDetail(data)
    else
        updateTooltip(data)
    end
end

local function queueInventoryRebuild()
    hideTooltip()
    rebuildInventoryPending = true
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

local function sortDirectionIcon(name, icon)
    return {
        name = name,
        type = ui.TYPE.Image,
        props = {
            resource = icon,
            anchor = v2(1, 1),
            relativePosition = v2(0.92, 0.92),
            relativeSize = SORT_DIRECTION_RELATIVE_SIZE,
            alpha = 0.95,
        },
    }
end

local function makeSortButton(mode, label)
    local active = sortMode == mode
    local directionKey = sortAscending[mode] and 'ascending' or 'descending'
    local name = 's3ui_sort_' .. mode
    local generation = uiGeneration
    local content = ui.content {
        {
            name = name .. '_icon',
            type = ui.TYPE.Image,
            props = {
                resource = SORT_ICONS[mode],
                anchor = v2(0.5, 0.5),
                relativePosition = v2(0.5, 0.5),
                relativeSize = SORT_ICON_RELATIVE_SIZE,
                alpha = active and 1 or 0.82,
            },
        },
    }

    if active then
        content:add(sortDirectionIcon(name .. '_direction', SORT_DIRECTION_ICONS[directionKey]))
    end

    return {
        name = name,
        type = ui.TYPE.Widget,
        props = {
            size = layoutMetrics().controlButtonSize,
        },
        events = {
            focusGain = async:callback(function()
                hideTooltip()
            end),
            mouseClick = async:callback(function()
                if generation ~= uiGeneration then return end
                hideTooltip()
                if sortMode == mode then
                    sortAscending[mode] = not sortAscending[mode]
                end
                sortMode = mode
                resetScrollOffset()
                queueInventoryRebuild()
            end),
        },
        content = content,
    }
end

local function listFieldCenter(mode)
    return (LIST_FIELD_RIGHT_EDGE[mode] or 0.5) - LIST_FIELD_WIDTH * 0.5
end

local function makeToolbarSortButton(mode, label)
    local button = makeSortButton(mode, label)
    button.props.anchor = v2(0.5, 0.5)
    button.props.relativePosition = v2(listFieldCenter(mode), 0.5)
    return button
end

local function inventoryWindowActive()
    return rootElement and rootElement.layout and I.UI.isWindowVisible(WINDOW)
end

local function scrollInventoryRows(deltaRows)
    if not inventoryWindowActive() then return end
    local oldOffset = scrollOffset
    scrollOffset = scrollOffset + deltaRows * scrollStepSize()
    clampScrollOffset(lastEntryCount)
    if scrollOffset == oldOffset then return end
    queueInventoryRebuild()
end

local function glyphRect(name, position, size)
    return {
        name = name,
        type = ui.TYPE.Image,
        props = {
            resource = WHITE_TEXTURE,
            color = VIEW_GLYPH_COLOR,
            alpha = 0.95,
            anchor = v2(0.5, 0.5),
            relativePosition = position,
            relativeSize = size,
        },
    }
end

local function makeViewGlyph()
    local glyph = ui.content {}
    if viewMode == 'list' then
        glyph:add(glyphRect('s3ui_view_list_bar_1', v2(0.5, 0.41), v2(0.28, 0.045)))
        glyph:add(glyphRect('s3ui_view_list_bar_2', v2(0.5, 0.5), v2(0.28, 0.045)))
        glyph:add(glyphRect('s3ui_view_list_bar_3', v2(0.5, 0.59), v2(0.28, 0.045)))
    else
        glyph:add(glyphRect('s3ui_view_grid_dot_1', v2(0.45, 0.45), v2(0.075, 0.075)))
        glyph:add(glyphRect('s3ui_view_grid_dot_2', v2(0.55, 0.45), v2(0.075, 0.075)))
        glyph:add(glyphRect('s3ui_view_grid_dot_3', v2(0.45, 0.55), v2(0.075, 0.075)))
        glyph:add(glyphRect('s3ui_view_grid_dot_4', v2(0.55, 0.55), v2(0.075, 0.075)))
    end
    return glyph
end

local function makeViewToggleButton()
    local generation = uiGeneration
    return {
        name = 's3ui_view_toggle',
        type = ui.TYPE.Widget,
        props = {
            size = layoutMetrics().viewButtonSize,
        },
        events = {
            focusGain = async:callback(function()
                hideTooltip()
            end),
            mouseClick = async:callback(function()
                if generation ~= uiGeneration then return end
                hideTooltip()
                local targetMode = viewMode == 'grid' and 'list' or 'grid'
                viewMode = targetMode
                resetScrollOffset()
                queueInventoryRebuild()
            end),
        },
        content = ui.content {
            {
                name = 's3ui_view_toggle_icon',
                type = ui.TYPE.Image,
                props = {
                    resource = VIEW_TOGGLE_ICON,
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    relativeSize = VIEW_TOGGLE_ICON_SIZE,
                    alpha = 0.95,
                },
            },
            {
                name = 's3ui_view_toggle_glyph',
                type = ui.TYPE.Widget,
                props = {
                    relativeSize = v2(1, 1),
                },
                content = makeViewGlyph(),
            },
        },
    }
end

local function makeToolbarViewToggleButton()
    local button = makeViewToggleButton()
    button.props.anchor = v2(0.5, 0.5)
    button.props.relativePosition = v2(0.5, 0.5)
    return button
end

local function menuButtonIconSize(buttonCount)
    local metrics = layoutMetrics()
    local buttonHeight = metrics.viewSize.y / buttonCount
    local edge = math.floor(math.min(metrics.categoryRailSize.x, buttonHeight) * 0.72)
    if edge < 32 then edge = 32 end
    return v2(edge, edge)
end

local function makeMainMenuButton(button)
    local active = button.key == ACTIVE_MAIN_MENU_KEY
    local buttonCount = #MAIN_MENU_BUTTONS

    return {
        name = 's3ui_main_menu_' .. button.key,
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = v2(1, 1 / buttonCount),
        },
        events = {
            focusGain = async:callback(function()
                hideTooltip()
            end),
            mouseClick = async:callback(function()
                hideTooltip()
            end),
        },
        content = ui.content {
            controlBackground(active),
            {
                name = 's3ui_main_menu_' .. button.key .. '_icon',
                type = ui.TYPE.Image,
                props = {
                    resource = button.icon,
                    anchor = v2(0.5, 0.5),
                    relativePosition = v2(0.5, 0.5),
                    size = menuButtonIconSize(buttonCount),
                    alpha = active and 1 or 0.72,
                },
            },
        },
    }
end

local function makeCategoryRail()
    local buttons = ui.content {}
    for _, button in ipairs(MAIN_MENU_BUTTONS) do
        buttons:add(makeMainMenuButton(button))
    end

    return {
        name = 's3ui_category_rail',
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = layoutMetrics().categoryRailSize,
            autoSize = false,
        },
        external = { stretch = 1 },
        content = buttons,
    }
end

local function makeToolbar()
    local metrics = layoutMetrics()
    return {
        name = 's3ui_toolbar',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            relativeSize = layoutMetrics().toolbarRelativeSize,
            arrange = ui.ALIGNMENT.Center,
            autoSize = false,
        },
        content = ui.content {
            {
                name = 's3ui_toolbar_rail_area',
                type = ui.TYPE.Widget,
                props = {
                    size = v2(metrics.categoryRailSize.x, 0),
                },
                external = { stretch = 1 },
                content = ui.content {
                    makeToolbarViewToggleButton(),
                },
            },
            {
                name = 's3ui_toolbar_field_area',
                type = ui.TYPE.Widget,
                props = {
                    size = v2(0, 0),
                    relativeSize = v2(0, 1),
                },
                external = { grow = 1, stretch = 1 },
                content = ui.content {
                    makeToolbarSortButton('value', 'Gold'),
                    makeToolbarSortButton('weight', 'Weight'),
                    makeToolbarSortButton('effectiveness', 'Effectiveness'),
                    makeToolbarSortButton('condition', 'Condition'),
                },
            },
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
            relativeSize = v2(1 / layoutMetrics().gridColumns, 1),
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
                queueInventoryRebuild()
            end),
        },
        content = content,
    }
end

local function addStateBadge(content, name, icon, anchor, position, size)
    content:add {
        name = name,
        type = ui.TYPE.Image,
        props = {
            resource = icon,
            anchor = anchor,
            relativePosition = position,
            relativeSize = size,
            alpha = 0.96,
        },
    }
end

local function addGridStateBadges(content, prefix, data)
    if data.equipped then
        addStateBadge(content, prefix .. '_equipped', ITEM_STATE_ICONS.equipped, v2(0, 0), v2(0.08, 0.08), ITEM_STATE_BADGE_RELATIVE_SIZE)
    end
    if data.enchanted then
        addStateBadge(content, prefix .. '_enchanted', ITEM_STATE_ICONS.enchanted, v2(1, 0), v2(0.92, 0.08), ITEM_STATE_BADGE_RELATIVE_SIZE)
    end
    if data.broken then
        addStateBadge(content, prefix .. '_broken', ITEM_STATE_ICONS.broken, v2(0, 1), v2(0.08, 0.92), ITEM_STATE_BADGE_RELATIVE_SIZE)
    end
end

local function addListStateBadges(content, prefix, data)
    if data.equipped then
        addStateBadge(content, prefix .. '_equipped', ITEM_STATE_ICONS.equipped, v2(0, 0.5), v2(0.012, 0.25), LIST_STATE_BADGE_SIZE)
    end
    if data.enchanted then
        addStateBadge(content, prefix .. '_enchanted', ITEM_STATE_ICONS.enchanted, v2(0, 0.5), v2(0.012, 0.5), LIST_STATE_BADGE_SIZE)
    end
    if data.broken then
        addStateBadge(content, prefix .. '_broken', ITEM_STATE_ICONS.broken, v2(0, 0.5), v2(0.012, 0.75), LIST_STATE_BADGE_SIZE)
    end
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

        addGridStateBadges(content, 'slot_' .. tostring(index), data)
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
            relativeSize = v2(1 / layoutMetrics().gridColumns, 1),
        },
        userData = data,
        events = data and {
            focusGain = async:callback(function(mouseEvent, layout)
                if generation ~= uiGeneration then return end
                updateDetails(layout and layout.userData, mouseEvent)
            end),
            focusLoss = async:callback(function()
                if generation ~= uiGeneration then return end
                hideTooltip()
            end),
        } or nil,
        content = content,
    }
end

local function makeGrid(items, firstIndex)
    local metrics = layoutMetrics()
    local rows = ui.content {}
    local index = firstIndex or 1
    local slotIndex = 1

    for rowIndex = 1, metrics.gridRows do
        local row = ui.content {}
        for _ = 1, metrics.gridColumns do
            row:add(makeSlot(items[index], slotIndex))
            index = index + 1
            slotIndex = slotIndex + 1
        end
        rows:add {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                relativeSize = v2(1, 1 / metrics.gridRows),
                autoSize = false,
            },
            external = rowIndex == metrics.gridRows and { grow = 1 } or nil,
            content = row,
        }
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = v2(0, 0),
            relativeSize = v2(0, 1),
            autoSize = false,
        },
        external = { grow = 1, stretch = 1 },
        content = rows,
    }
end

local function makeListCategoryRow(entry, index)
    local collapsed = entry.collapsed
    local generation = uiGeneration
    local icon = CATEGORY_ICON_TEXTURES[entry.categoryKey]
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
        textLine(collapsed and '+' or '-', I.MWUI.templates.textHeader, {
            anchor = v2(0, 0.5),
            relativePosition = v2(0.04, 0.5),
            relativeSize = v2(0.06, 0.7),
            textSize = 16,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }),
        textLine(entry.label, I.MWUI.templates.textHeader, {
            anchor = v2(0, 0.5),
            relativePosition = v2(0.18, 0.5),
            relativeSize = v2(0.5, 0.7),
            textSize = 16,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }),
        textLine(tostring(entry.count), I.MWUI.templates.textNormal, {
            anchor = v2(1, 0.5),
            relativePosition = v2(0.94, 0.5),
            relativeSize = v2(0.12, 0.7),
            textSize = 14,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }),
    }

    if icon then
        content:add {
            name = 'list_' .. tostring(index) .. '_category_icon',
            type = ui.TYPE.Image,
            props = {
                resource = icon,
                anchor = v2(0, 0.5),
                relativePosition = v2(0.1, 0.5),
                size = layoutMetrics().listIconSize,
                alpha = collapsed and 0.62 or 0.95,
            },
        }
    end

    return {
        name = 'list_' .. tostring(index),
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = v2(1, 1 / layoutMetrics().listRows),
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
                queueInventoryRebuild()
            end),
        },
        content = content,
    }
end

local function makeListItemRow(entry, index)
    local data = entry and entry.data
    local generation = uiGeneration
    local content = ui.content {
        {
            type = ui.TYPE.Image,
            props = {
                resource = WHITE_TEXTURE,
                color = BACKGROUND_COLOR,
                alpha = index % 2 == 0 and 0.18 or 0.08,
                relativeSize = v2(1, 1),
            },
        },
    }

    if data then
        if data.icon then
            content:add {
                name = 'list_' .. tostring(index) .. '_icon',
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = data.icon },
                    anchor = v2(0, 0.5),
                    relativePosition = v2(0.06, 0.5),
                    size = layoutMetrics().listIconSize,
                },
            }
        end

        addListStateBadges(content, 'list_' .. tostring(index), data)

        local count = data.count > 1 and (' x' .. tostring(data.count)) or ''
        content:add(textLine(data.name .. count, I.MWUI.templates.textNormal, {
            anchor = v2(0, 0.5),
            relativePosition = v2(0.16, 0.5),
            relativeSize = v2(0.5, 0.72),
            textSize = 15,
            textAlignH = ui.ALIGNMENT.Start,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }))
        content:add(textLine(tostring(data.value), I.MWUI.templates.textNormal, {
            anchor = v2(1, 0.5),
            relativePosition = v2(LIST_FIELD_RIGHT_EDGE.value, 0.5),
            relativeSize = v2(LIST_FIELD_WIDTH, LIST_FIELD_HEIGHT),
            textSize = 14,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }))
        content:add(textLine(formatNumber(data.weight, 1), I.MWUI.templates.textNormal, {
            anchor = v2(1, 0.5),
            relativePosition = v2(LIST_FIELD_RIGHT_EDGE.weight, 0.5),
            relativeSize = v2(LIST_FIELD_WIDTH, LIST_FIELD_HEIGHT),
            textSize = 14,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }))
        content:add(textLine(formatNumber(data.effectiveness, 0), I.MWUI.templates.textNormal, {
            anchor = v2(1, 0.5),
            relativePosition = v2(LIST_FIELD_RIGHT_EDGE.effectiveness, 0.5),
            relativeSize = v2(LIST_FIELD_WIDTH, LIST_FIELD_HEIGHT),
            textSize = 14,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }))
        content:add(textLine(formatCondition(data.condition), I.MWUI.templates.textNormal, {
            anchor = v2(1, 0.5),
            relativePosition = v2(LIST_FIELD_RIGHT_EDGE.condition, 0.5),
            relativeSize = v2(LIST_FIELD_WIDTH, LIST_FIELD_HEIGHT),
            textSize = 14,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            autoSize = false,
        }))
    end

    return {
        name = 'list_' .. tostring(index),
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props = {
            relativeSize = v2(1, 1 / layoutMetrics().listRows),
        },
        userData = data,
        events = data and {
            focusGain = async:callback(function(mouseEvent, layout)
                if generation ~= uiGeneration then return end
                updateDetails(layout and layout.userData, mouseEvent)
            end),
            focusLoss = async:callback(function()
                if generation ~= uiGeneration then return end
                hideTooltip()
            end),
        } or nil,
        content = content,
    }
end

local function makeList(items, firstIndex)
    local metrics = layoutMetrics()
    local rows = ui.content {}
    local index = firstIndex or 1
    for slotIndex = 1, metrics.listRows do
        local entry = items[index]
        if entry and entry.kind == 'categoryHeader' then
            rows:add(makeListCategoryRow(entry, slotIndex))
        else
            rows:add(makeListItemRow(entry, slotIndex))
        end
        index = index + 1
    end

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = v2(0, 0),
            relativeSize = v2(0, 1),
            autoSize = false,
        },
        external = { grow = 1, stretch = 1 },
        content = rows,
    }
end

local function makeInventoryLayout(items)
    activeLayoutMetrics = inventoryLayout.compute()
    local metrics = activeLayoutMetrics
    local entries = buildDisplayEntries(items)
    lastEntryCount = #entries
    clampScrollOffset(#entries)
    local firstIndex = scrollOffset + 1
    local inventoryView = viewMode == 'list' and makeList(entries, firstIndex) or makeGrid(entries, firstIndex)
    local bodyLayouts = {
        makeToolbar(),
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
                inventoryView,
            },
        },
    }
    if metrics.detailMode == 'compact' then
        bodyLayouts[#bodyLayouts + 1] = makeCompactDetailBar()
    end
    local bodyContent = ui.content(bodyLayouts)

    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        layer = ROOT_LAYER,
        props = {
            anchor = metrics.windowAnchor,
            relativePosition = metrics.windowRelativePosition,
            size = metrics.windowSize,
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
                content = bodyContent,
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

local function reloadLuaAndReopenInventory()
    devReloadStorage:set(DEV_RELOAD_REOPEN_KEY, true)
    if I.UI.isWindowVisible(WINDOW) then
        I.UI.removeMode(MODE)
    end
    omwDebug.reloadLua()
end

local function processDevReloadReopen()
    if devReloadStorage:get(DEV_RELOAD_REOPEN_KEY) ~= true then return end
    devReloadStorage:set(DEV_RELOAD_REOPEN_KEY, false)
    if not I.UI.isWindowVisible(WINDOW) then
        I.UI.setMode(MODE, { windows = { WINDOW } })
    end
end

local function destroyInventoryWindow()
    uiGeneration = uiGeneration + 1
    rebuildInventoryPending = false
    rebuildEventQueued = false
    if tooltipElement and tooltipElement.layout then
        tooltipElement:destroy()
    end
    tooltipElement = nil
    if rootElement and rootElement.layout then
        rootElement:destroy()
    end
    rootElement = nil
    compactDetailVisible = false
end

rebuildInventoryRoot = function()
    uiGeneration = uiGeneration + 1
    hideTooltip()
    if rootElement and rootElement.layout then
        rootElement:destroy()
    end
    if tooltipElement and tooltipElement.layout then
        tooltipElement:destroy()
    end
    tooltipElement = nil
    rootElement = ui.create(makeInventoryLayout(collectInventoryItems()))
    compactDetailVisible = false
    if activeLayoutMetrics.detailMode == 'side' then
        ensureTooltipLayer()
        tooltipElement = ui.create(makeTooltipLayout())
    end
end

local function processPendingRebuild()
    rebuildEventQueued = false
    if not rebuildInventoryPending then return end
    rebuildInventoryPending = false
    if not rootElement or not rootElement.layout or not I.UI.isWindowVisible(WINDOW) then return end
    rebuildInventoryRoot()
end

local function showInventoryWindow()
    destroyInventoryWindow()
    saveHudVisibility()
    showStaticInventoryCamera()
    rebuildInventoryRoot()
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
async:newUnsavableSimulationTimer(0, processDevReloadReopen)

return {
    engineHandlers = {
        onKeyPress = function(key)
            if key.code == input.KEY.F8 then
                reloadLuaAndReopenInventory()
            elseif key.code == input.KEY.I then
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
