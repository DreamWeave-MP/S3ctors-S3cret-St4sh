---@omw-context player

local I = require 'openmw.interfaces'
local types = require 'openmw.types'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local chrome = require 'scripts.s3ui.inventory.chrome'
local data = require 'scripts.s3ui.inventory.data'
local icons = require 'scripts.s3ui.inventory.icons'

local v2 = util.vector2
local EMPTY_FIELD = data.EMPTY_FIELD
local TOOLTIP = icons.TOOLTIP
local WHITE_TEXTURE = chrome.WHITE_TEXTURE
local BACKGROUND_COLOR = chrome.BACKGROUND_COLOR
local FRAME_SIZE_MEDIUM = chrome.FRAME_SIZE_MEDIUM
local textProps = chrome.textProps

local TOOLTIP_LAYER = 'S3UI_Tooltip'
local TOOLTIP_FIELD_ROW_COUNT = 11
local COMPACT_DETAIL_FIELD_COLUMNS = 4
local COMPACT_DETAIL_FIELD_ROWS = 3
local COMPACT_DETAIL_FIELD_SLOT_COUNT = COMPACT_DETAIL_FIELD_COLUMNS * COMPACT_DETAIL_FIELD_ROWS
local TOOLTIP_FIELD_NAMES = {
    's3ui_tooltip_type', 's3ui_tooltip_value', 's3ui_tooltip_weight', 's3ui_tooltip_gold_per_weight',
    's3ui_tooltip_condition', 's3ui_tooltip_reach', 's3ui_tooltip_speed', 's3ui_tooltip_chop_damage',
    's3ui_tooltip_slash_damage', 's3ui_tooltip_thrust_damage', 's3ui_tooltip_effectiveness',
}
local DETAIL_FIELD_NAMES = {
    type = 's3ui_tooltip_type', value = 's3ui_tooltip_value', weight = 's3ui_tooltip_weight',
    goldPerWeight = 's3ui_tooltip_gold_per_weight', condition = 's3ui_tooltip_condition',
    reach = 's3ui_tooltip_reach', speed = 's3ui_tooltip_speed', chopDamage = 's3ui_tooltip_chop_damage',
    slashDamage = 's3ui_tooltip_slash_damage', thrustDamage = 's3ui_tooltip_thrust_damage',
    effectiveness = 's3ui_tooltip_effectiveness',
}
local RANGED_WEAPON_TYPES = {
    [types.Weapon.TYPE.Arrow] = true,
    [types.Weapon.TYPE.Bolt] = true,
    [types.Weapon.TYPE.MarksmanBow] = true,
    [types.Weapon.TYPE.MarksmanCrossbow] = true,
    [types.Weapon.TYPE.MarksmanThrown] = true,
}

local M = {}

local function typeIcon(itemData)
    local itemType = itemData and itemData.item and itemData.item.type
    if itemType == types.Weapon then
        local weaponType = itemData and itemData.record and itemData.record.type
        if RANGED_WEAPON_TYPES[weaponType] then return TOOLTIP.typeRangedWeapon end
        return TOOLTIP.typeWeapon
    end
    if itemType == types.Armor or itemType == types.Clothing then return TOOLTIP.typeArmor end
    if itemType == types.Book then return TOOLTIP.typeBook end
    return TOOLTIP.typeGeneric
end

local function addDetailField(fields, key, icon, value, compactValue)
    if value == nil or value == '' or value == EMPTY_FIELD then return end
    fields[#fields + 1] = { key = key, icon = icon, value = value, compactValue = compactValue or value }
end

local function buildDetailModel(itemData)
    if not itemData then return nil end
    local record = itemData.record
    local fields = {}
    addDetailField(fields, 'type', typeIcon(itemData), data.typeText(itemData))
    addDetailField(fields, 'value', TOOLTIP.value, record and type(record.value) == 'number' and tostring(record.value) or EMPTY_FIELD)
    addDetailField(fields, 'weight', TOOLTIP.weight, data.formatNumber(record and record.weight, 2))
    addDetailField(fields, 'goldPerWeight', TOOLTIP.goldPerWeight, data.goldPerWeight(record))
    addDetailField(fields, 'condition', TOOLTIP.condition, data.formatCondition(itemData.condition))
    if itemData.item and itemData.item.type == types.Weapon then
        addDetailField(fields, 'reach', TOOLTIP.reach, data.formatNumber(record and record.reach, 2))
        addDetailField(fields, 'speed', TOOLTIP.speed, data.formatNumber(record and record.speed, 2))
        for _, damage in ipairs(data.weaponDamageFields(record)) do
            addDetailField(fields, damage.key, TOOLTIP.damage, damage.text, damage.compactText)
        end
        addDetailField(fields, 'effectiveness', TOOLTIP.damageSpeed, data.formatNumber(itemData.effectiveness, 2))
    elseif itemData.item and itemData.item.type == types.Armor then
        addDetailField(fields, 'reach', TOOLTIP.armorRating, data.formatNumber(record and record.baseArmor, 0))
    end
    return { icon = itemData.icon and ui.texture { path = itemData.icon } or WHITE_TEXTURE, name = itemData.name or data.itemName(itemData.item, record), fields = fields }
end

local function tooltipText(name, text, props, template, external)
    return { name = name, template = template or I.MWUI.templates.textNormal, external = external, props = textProps(text, props) }
end

function M.new(ctx)
    local self = { tooltipElement = nil, compactDetailVisible = false }
    local metrics = ctx.metrics
    local root = ctx.root

    local function updateRoot()
        local rootElement = root()
        if rootElement and rootElement.layout then rootElement:update() end
    end
    local function tooltipPixelHeight(rowCount, m)
        m = m or metrics()
        if type(rowCount) ~= 'number' or rowCount < 1 then rowCount = 1 end
        return m.tooltipHeaderHeight + rowCount * m.tooltipFieldRowHeight + m.tooltipPadding
    end
    local function tooltipRelativeSize(rowCount, screen, m)
        m = m or metrics(); screen = screen or m.screen or ui.screenSize()
        return v2(m.tooltipWidth / screen.x, tooltipPixelHeight(rowCount, m) / screen.y)
    end
    local function tooltipPosition(relativeSize)
        local screen, m = ui.screenSize(), metrics()
        relativeSize = relativeSize or tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT, screen, m)
        local size = v2(screen.x * relativeSize.x, screen.y * relativeSize.y)
        local x, y = m.windowPosition.x + m.windowSize.x, m.windowPosition.y
        if x + size.x > screen.x - m.tooltipMargin.x then x = screen.x - size.x - m.tooltipMargin.x end
        if y + size.y > screen.y - m.tooltipMargin.y then y = screen.y - size.y - m.tooltipMargin.y end
        if x < m.tooltipMargin.x then x = m.tooltipMargin.x end
        if y < m.tooltipMargin.y then y = m.tooltipMargin.y end
        return v2(x, y)
    end
    local function tooltipField(name, icon)
        local m = metrics()
        return { name = name .. '_row', type = ui.TYPE.Flex, props = { horizontal = true, autoSize = false, relativeSize = v2(1, 1 / TOOLTIP_FIELD_ROW_COUNT) }, content = ui.content {
            { name = name .. '_icon_box', type = ui.TYPE.Widget, props = { relativeSize = v2(0.16, 1) }, content = ui.content { { name = name .. '_icon', type = ui.TYPE.Image, props = { resource = icon, anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5), size = m.tooltipFieldIconSize } } } },
            tooltipText(name .. '_value', EMPTY_FIELD, { relativeSize = v2(0.84, 1), textSize = m.tooltipValueTextSize, textAlignH = ui.ALIGNMENT.Start, textAlignV = ui.ALIGNMENT.Center, multiline = true, wordWrap = true, autoSize = false }),
        } }
    end
    local function setTooltipField(fieldsLayout, name, value)
        fieldsLayout.content[name .. '_row'].content[name .. '_value'].props.text = value or EMPTY_FIELD
    end
    local function setTooltipFieldIcon(fieldsLayout, name, icon)
        fieldsLayout.content[name .. '_row'].content[name .. '_icon_box'].content[name .. '_icon'].props.resource = icon
    end
    local function setTooltipVisibleFields(fieldsLayout, visibleNames)
        local visible = {}; for _, name in ipairs(visibleNames) do visible[name] = true end
        local visibleCount = math.max(#visibleNames, 1)
        for _, name in ipairs(TOOLTIP_FIELD_NAMES) do
            local row = fieldsLayout.content[name .. '_row']; local isVisible = visible[name] == true
            row.props.visible = isVisible; row.props.relativeSize = isVisible and v2(1, 1 / visibleCount) or v2(1, 0)
        end
        return visibleCount
    end

    function self.ensureTooltipLayer()
        if ui.layers.indexOf(TOOLTIP_LAYER) == nil then ui.layers.insertAfter(ctx.rootLayer, TOOLTIP_LAYER, { interactive = false }) end
    end
    function self.makeTooltipLayout()
        local m, defaultHeight = metrics(), tooltipPixelHeight(TOOLTIP_FIELD_ROW_COUNT, metrics())
        local inset = chrome.frameInset(FRAME_SIZE_MEDIUM)
        local content = ui.content {
            { type = ui.TYPE.Image, props = { resource = WHITE_TEXTURE, color = BACKGROUND_COLOR, alpha = chrome.backgroundAlpha(), relativeSize = v2(1, 1) } },
            { name = 's3ui_tooltip_body', type = ui.TYPE.Flex, props = { horizontal = false, position = v2(inset, inset), size = v2(-inset * 2, -inset * 2), relativeSize = v2(1, 1), autoSize = false }, content = ui.content {
                { name = 's3ui_tooltip_header', type = ui.TYPE.Flex, props = { horizontal = true, relativeSize = v2(1, m.tooltipHeaderHeight / defaultHeight), autoSize = false }, content = ui.content {
                    { name = 's3ui_tooltip_icon_box', type = ui.TYPE.Widget, props = { relativeSize = v2(0.18, 1) }, content = ui.content { { name = 's3ui_tooltip_icon', type = ui.TYPE.Image, props = { size = m.tooltipHeaderIconSize, anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5) } } } },
                    tooltipText('s3ui_tooltip_name', EMPTY_FIELD, { relativeSize = v2(0.82, 1), textSize = m.tooltipHeaderTextSize, textAlignH = ui.ALIGNMENT.Start, textAlignV = ui.ALIGNMENT.Center, multiline = true, wordWrap = true, autoSize = false }, I.MWUI.templates.textHeader),
                } },
                { name = 's3ui_tooltip_fields', type = ui.TYPE.Flex, props = { horizontal = false, relativeSize = v2(1, TOOLTIP_FIELD_ROW_COUNT * m.tooltipFieldRowHeight / defaultHeight), autoSize = false }, content = ui.content {
                    tooltipField('s3ui_tooltip_type', TOOLTIP.typeGeneric), tooltipField('s3ui_tooltip_value', TOOLTIP.value), tooltipField('s3ui_tooltip_weight', TOOLTIP.weight), tooltipField('s3ui_tooltip_gold_per_weight', TOOLTIP.goldPerWeight), tooltipField('s3ui_tooltip_condition', TOOLTIP.condition), tooltipField('s3ui_tooltip_reach', TOOLTIP.reach), tooltipField('s3ui_tooltip_speed', TOOLTIP.speed), tooltipField('s3ui_tooltip_chop_damage', TOOLTIP.damage), tooltipField('s3ui_tooltip_slash_damage', TOOLTIP.damage), tooltipField('s3ui_tooltip_thrust_damage', TOOLTIP.damage), tooltipField('s3ui_tooltip_effectiveness', TOOLTIP.damageSpeed),
                } },
            } },
        }
        chrome.addOrnateFrame(content, 's3ui_tooltip', FRAME_SIZE_MEDIUM, 0.95)
        return { type = ui.TYPE.Widget, layer = TOOLTIP_LAYER, props = { position = tooltipPosition(), relativeSize = tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT, nil, m), visible = false }, content = content }
    end
    function self.createSideTooltip()
        self.ensureTooltipLayer(); self.tooltipElement = ui.create(self.makeTooltipLayout())
    end
    function self.destroy()
        if self.tooltipElement and self.tooltipElement.layout then self.tooltipElement:destroy() end
        self.tooltipElement, self.compactDetailVisible = nil, false
    end
    function self.hide()
        self.hideCompactDetail()
        if not self.tooltipElement or not self.tooltipElement.layout then return end
        self.tooltipElement.layout.props.visible = false; self.tooltipElement:update()
    end
    function self.updateTooltip(itemData)
        if not self.tooltipElement or not self.tooltipElement.layout or not itemData then return end
        local model = buildDetailModel(itemData); if not model then return end
        local bodyContent = self.tooltipElement.layout.content.s3ui_tooltip_body.content
        local header, fields = bodyContent.s3ui_tooltip_header.content, bodyContent.s3ui_tooltip_fields
        header.s3ui_tooltip_icon_box.content.s3ui_tooltip_icon.props.resource = model.icon; header.s3ui_tooltip_name.props.text = model.name
        for key, name in pairs(DETAIL_FIELD_NAMES) do setTooltipField(fields, name, ''); setTooltipFieldIcon(fields, name, key == 'type' and TOOLTIP.typeGeneric or TOOLTIP[key] or WHITE_TEXTURE) end
        local visibleFields = {}
        for _, field in ipairs(model.fields) do local name = DETAIL_FIELD_NAMES[field.key]; if name then setTooltipField(fields, name, field.value); setTooltipFieldIcon(fields, name, field.icon); visibleFields[#visibleFields + 1] = name end end
        local m, visibleCount = metrics(), setTooltipVisibleFields(fields, visibleFields)
        local relativeSize, height = tooltipRelativeSize(visibleCount, nil, m), tooltipPixelHeight(visibleCount, m)
        self.tooltipElement.layout.props.relativeSize = relativeSize; self.tooltipElement.layout.props.position = tooltipPosition(relativeSize)
        bodyContent.s3ui_tooltip_header.props.relativeSize = v2(1, m.tooltipHeaderHeight / height); fields.props.relativeSize = v2(1, visibleCount * m.tooltipFieldRowHeight / height)
        self.tooltipElement.layout.props.visible = true; self.tooltipElement:update()
    end

    local function compactDetailFieldSlot(slotIndex)
        local m, name = metrics(), 's3ui_compact_detail_field_' .. tostring(slotIndex)
        return { name = name, type = ui.TYPE.Flex, props = { horizontal = true, relativeSize = v2(1 / COMPACT_DETAIL_FIELD_COLUMNS, 1), autoSize = false }, content = ui.content {
            { name = name .. '_icon_box', type = ui.TYPE.Widget, props = { relativeSize = v2(0.28, 1) }, content = ui.content { { name = name .. '_icon', type = ui.TYPE.Image, props = { resource = WHITE_TEXTURE, alpha = 0, anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5), size = m.compactDetailFieldIconSize } } } },
            tooltipText(name .. '_value', '', { relativeSize = v2(0.72, 1), textSize = m.compactDetailFieldTextSize, textAlignH = ui.ALIGNMENT.Start, textAlignV = ui.ALIGNMENT.Center, multiline = true, wordWrap = true, autoSize = false }),
        } }
    end
    local function makeCompactDetailFields()
        local rows, slotIndex = {}, 1
        for rowIndex = 1, COMPACT_DETAIL_FIELD_ROWS do
            local row = {}; for _ = 1, COMPACT_DETAIL_FIELD_COLUMNS do row[#row + 1] = compactDetailFieldSlot(slotIndex); slotIndex = slotIndex + 1 end
            rows[#rows + 1] = { name = 's3ui_compact_detail_row_' .. tostring(rowIndex), type = ui.TYPE.Flex, props = { horizontal = true, relativeSize = v2(1, 1 / COMPACT_DETAIL_FIELD_ROWS), autoSize = false }, content = ui.content(row) }
        end
        return ui.content(rows)
    end
    function self.makeCompactDetailBar()
        local m, inset = metrics(), chrome.frameInset(FRAME_SIZE_MEDIUM)
        local content = ui.content {
            { type = ui.TYPE.Image, props = { resource = WHITE_TEXTURE, color = BACKGROUND_COLOR, alpha = chrome.backgroundAlpha(), relativeSize = v2(1, 1) } },
            { name = 's3ui_compact_detail_content', type = ui.TYPE.Flex, props = { horizontal = true, position = v2(inset, inset), size = v2(-inset * 2, -inset * 2), relativeSize = v2(1, 1), visible = false, autoSize = false }, content = ui.content {
                { name = 's3ui_compact_detail_header', type = ui.TYPE.Flex, props = { horizontal = true, relativeSize = m.compactDetailHeaderRelativeSize, autoSize = false }, content = ui.content {
                    { name = 's3ui_compact_detail_icon_box', type = ui.TYPE.Widget, props = { relativeSize = v2(0.36, 1) }, content = ui.content { { name = 's3ui_compact_detail_icon', type = ui.TYPE.Image, props = { resource = WHITE_TEXTURE, anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5), size = m.compactDetailIconSize } } } },
                    { name = 's3ui_compact_detail_title_box', type = ui.TYPE.Flex, props = { horizontal = false, relativeSize = v2(0.64, 1), autoSize = false }, content = ui.content { tooltipText('s3ui_compact_detail_name', '', { relativeSize = v2(1, 1), textSize = m.compactDetailHeaderTextSize, textAlignH = ui.ALIGNMENT.Start, textAlignV = ui.ALIGNMENT.Center, multiline = true, wordWrap = true, autoSize = false }, I.MWUI.templates.textHeader) } },
                } },
                { name = 's3ui_compact_detail_fields', type = ui.TYPE.Flex, props = { horizontal = false, relativeSize = m.compactDetailFieldsRelativeSize, autoSize = false }, content = makeCompactDetailFields() },
            } },
        }
        chrome.addOrnateFrame(content, 's3ui_compact_detail', FRAME_SIZE_MEDIUM, 0.95)
        return { name = 's3ui_compact_detail_bar', type = ui.TYPE.Widget, props = { relativeSize = m.compactDetailRelativeSize }, content = content }
    end
    local function compactBar()
        local rootElement = root(); if not rootElement or not rootElement.layout then return nil end
        local body = rootElement.layout.content.s3ui_body; if not body or not body.content then return nil end
        local ok, bar = pcall(function() return body.content.s3ui_compact_detail_bar end); if ok then return bar end
        return nil
    end
    function self.hideCompactDetail()
        if not self.compactDetailVisible then return end
        local bar = compactBar(); if not bar then self.compactDetailVisible = false; return end
        bar.content.s3ui_compact_detail_content.props.visible = false; self.compactDetailVisible = false; updateRoot()
    end
    function self.updateCompactDetail(itemData)
        local model, bar = buildDetailModel(itemData), compactBar(); if not model or not bar then return end
        local content = bar.content.s3ui_compact_detail_content
        local detailContent, prefix = content.content, 's3ui_compact_detail_field_'
        local headerContent = detailContent.s3ui_compact_detail_header.content
        headerContent.s3ui_compact_detail_icon_box.content.s3ui_compact_detail_icon.props.resource = model.icon
        headerContent.s3ui_compact_detail_title_box.content.s3ui_compact_detail_name.props.text = model.name
        local fields = detailContent.s3ui_compact_detail_fields
        for slotIndex = 1, COMPACT_DETAIL_FIELD_SLOT_COUNT do
            local row = fields.content['s3ui_compact_detail_row_' .. tostring(math.floor((slotIndex - 1) / COMPACT_DETAIL_FIELD_COLUMNS) + 1)]
            local slot = row.content[prefix .. tostring(slotIndex)]
            local icon = slot.content[prefix .. tostring(slotIndex) .. '_icon_box'].content[prefix .. tostring(slotIndex) .. '_icon']
            local value = slot.content[prefix .. tostring(slotIndex) .. '_value']
            local field = model.fields[slotIndex]
            icon.props.resource = field and field.icon or WHITE_TEXTURE; icon.props.alpha = field and 0.95 or 0; value.props.text = field and (field.compactValue or field.value) or ''
        end
        content.props.visible = true; self.compactDetailVisible = true; updateRoot()
    end
    function self.update(itemData)
        if metrics().detailMode == 'compact' then self.updateCompactDetail(itemData) else self.updateTooltip(itemData) end
    end
    return self
end

return M
