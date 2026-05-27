---@omw-context player

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local chrome = require 'scripts.s3ui.inventory.chrome'
local compactFactory = require 'scripts.s3ui.inventory.details_compact'
local data = require 'scripts.s3ui.inventory.data'
local detailModel = require 'scripts.s3ui.inventory.details_model'
local icons = require 'scripts.s3ui.inventory.icons'

local v2 = util.vector2
local EMPTY_FIELD = data.EMPTY_FIELD
local TOOLTIP = icons.TOOLTIP
local WHITE_TEXTURE = chrome.WHITE_TEXTURE
local BACKGROUND_COLOR = chrome.BACKGROUND_COLOR
local FRAME_SIZE_MEDIUM = chrome.FRAME_SIZE_MEDIUM
local TOOLTIP_LAYER = 'S3UI_Tooltip'
local TOOLTIP_FIELD_ROW_COUNT = 11

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

---@class S3UI.InventoryDetailsModule
local M = {}

local function tooltipText(name, text, props, template)
	return {
		name = name,
		template = template or I.MWUI.templates.textNormal,
		props = chrome.textProps(text, props),
	}
end

---@param ctx S3UI.InventoryDetailsContext
---@return S3UI.InventoryDetailsController
function M.new(ctx)
	local self = { tooltipElement = nil }
	local metrics = ctx.metrics
	local root = ctx.root

	local function updateRoot()
		local rootElement = root()
		if rootElement and rootElement.layout then
			rootElement:update()
		end
	end

	local compact = compactFactory.new { metrics = metrics, root = root, updateRoot = updateRoot }

	local function tooltipPixelHeight(rowCount, m)
		m = m or metrics()
		if type(rowCount) ~= 'number' or rowCount < 1 then
			rowCount = 1
		end
		return m.tooltipHeaderHeight + rowCount * m.tooltipFieldRowHeight + m.tooltipPadding
	end

	local function tooltipRelativeSize(rowCount, screen, m)
		m = m or metrics()
		screen = screen or m.screen or ui.screenSize()
		return v2(m.tooltipWidth / screen.x, tooltipPixelHeight(rowCount, m) / screen.y)
	end

	local function tooltipPosition(relativeSize)
		local screen, m = ui.screenSize(), metrics()
		relativeSize = relativeSize or tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT, screen, m)
		local size = v2(screen.x * relativeSize.x, screen.y * relativeSize.y)
		local x, y = m.windowPosition.x + m.windowSize.x, m.windowPosition.y
		if x + size.x > screen.x - m.tooltipMargin.x then
			x = screen.x - size.x - m.tooltipMargin.x
		end
		if y + size.y > screen.y - m.tooltipMargin.y then
			y = screen.y - size.y - m.tooltipMargin.y
		end
		if x < m.tooltipMargin.x then
			x = m.tooltipMargin.x
		end
		if y < m.tooltipMargin.y then
			y = m.tooltipMargin.y
		end
		return v2(x, y)
	end

	local function tooltipField(name, icon)
		local m = metrics()
		return {
			name = name .. '_row',
			type = ui.TYPE.Flex,
			props = { horizontal = true, autoSize = false, relativeSize = v2(1, 1 / TOOLTIP_FIELD_ROW_COUNT) },
			content = ui.content {
				{
					name = name .. '_icon_box',
					type = ui.TYPE.Widget,
					props = { relativeSize = v2(0.16, 1) },
					content = ui.content {
						{
							name = name .. '_icon',
							type = ui.TYPE.Image,
							props = {
								resource = icon,
								anchor = v2(0.5, 0.5),
								relativePosition = v2(0.5, 0.5),
								size = m.tooltipFieldIconSize,
							},
						},
					},
				},
				tooltipText(name .. '_value', EMPTY_FIELD, {
					relativeSize = v2(0.84, 1),
					textSize = m.tooltipValueTextSize,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Center,
					multiline = true,
					wordWrap = true,
					autoSize = false,
				}),
			},
		}
	end

	local function setTooltipField(fieldsLayout, name, value)
		fieldsLayout.content[name .. '_row'].content[name .. '_value'].props.text = value or EMPTY_FIELD
	end

	local function setTooltipFieldIcon(fieldsLayout, name, icon)
		fieldsLayout.content[name .. '_row'].content[name .. '_icon_box'].content[name .. '_icon'].props.resource = icon
	end

	local function setVisibleFields(fieldsLayout, visibleNames)
		local visible = {}
		for _, name in ipairs(visibleNames) do
			visible[name] = true
		end
		local visibleCount = math.max(#visibleNames, 1)
		for _, name in ipairs(TOOLTIP_FIELD_NAMES) do
			local row = fieldsLayout.content[name .. '_row']
			local isVisible = visible[name] == true
			row.props.visible = isVisible
			row.props.relativeSize = isVisible and v2(1, 1 / visibleCount) or v2(1, 0)
		end
		return visibleCount
	end

	function self.ensureTooltipLayer()
		if ui.layers.indexOf(TOOLTIP_LAYER) == nil then
			ui.layers.insertAfter(ctx.rootLayer, TOOLTIP_LAYER, { interactive = false })
		end
	end

	function self.makeTooltipLayout()
		local m, defaultHeight = metrics(), tooltipPixelHeight(TOOLTIP_FIELD_ROW_COUNT, metrics())
		local inset = chrome.frameInset(FRAME_SIZE_MEDIUM)
		local content = ui.content {
			{
				type = ui.TYPE.Image,
				props = {
					resource = WHITE_TEXTURE,
					color = BACKGROUND_COLOR,
					alpha = chrome.backgroundAlpha(),
					relativeSize = v2(1, 1),
				},
			},
			{
				name = 's3ui_tooltip_body',
				type = ui.TYPE.Flex,
				props = {
					horizontal = false,
					position = v2(inset, inset),
					size = v2(-inset * 2, -inset * 2),
					relativeSize = v2(1, 1),
					autoSize = false,
				},
				content = ui.content {
					{
						name = 's3ui_tooltip_header',
						type = ui.TYPE.Flex,
						props = {
							horizontal = true,
							relativeSize = v2(1, m.tooltipHeaderHeight / defaultHeight),
							autoSize = false,
						},
						content = ui.content {
							{
								name = 's3ui_tooltip_icon_box',
								type = ui.TYPE.Widget,
								props = { relativeSize = v2(0.18, 1) },
								content = ui.content {
									{
										name = 's3ui_tooltip_icon',
										type = ui.TYPE.Image,
										props = {
											size = m.tooltipHeaderIconSize,
											anchor = v2(0.5, 0.5),
											relativePosition = v2(0.5, 0.5),
										},
									},
								},
							},
							tooltipText('s3ui_tooltip_name', EMPTY_FIELD, {
								relativeSize = v2(0.82, 1),
								textSize = m.tooltipHeaderTextSize,
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
							relativeSize = v2(1, TOOLTIP_FIELD_ROW_COUNT * m.tooltipFieldRowHeight / defaultHeight),
							autoSize = false,
						},
						content = ui.content {
							tooltipField('s3ui_tooltip_type', TOOLTIP.typeGeneric),
							tooltipField('s3ui_tooltip_value', TOOLTIP.value),
							tooltipField('s3ui_tooltip_weight', TOOLTIP.weight),
							tooltipField('s3ui_tooltip_gold_per_weight', TOOLTIP.goldPerWeight),
							tooltipField('s3ui_tooltip_condition', TOOLTIP.condition),
							tooltipField('s3ui_tooltip_reach', TOOLTIP.reach),
							tooltipField('s3ui_tooltip_speed', TOOLTIP.speed),
							tooltipField('s3ui_tooltip_chop_damage', TOOLTIP.damage),
							tooltipField('s3ui_tooltip_slash_damage', TOOLTIP.damage),
							tooltipField('s3ui_tooltip_thrust_damage', TOOLTIP.damage),
							tooltipField('s3ui_tooltip_effectiveness', TOOLTIP.damageSpeed),
						},
					},
				},
			},
		}
		chrome.addOrnateFrame(content, 's3ui_tooltip', FRAME_SIZE_MEDIUM, 0.95)
		return {
			type = ui.TYPE.Widget,
			layer = TOOLTIP_LAYER,
			props = {
				position = tooltipPosition(),
				relativeSize = tooltipRelativeSize(TOOLTIP_FIELD_ROW_COUNT, nil, m),
				visible = false,
			},
			content = content,
		}
	end

	function self.createSideTooltip()
		self.ensureTooltipLayer()
		self.tooltipElement = ui.create(self.makeTooltipLayout())
	end

	function self.destroy()
		if self.tooltipElement and self.tooltipElement.layout then
			self.tooltipElement:destroy()
		end
		self.tooltipElement = nil
		compact.destroy()
	end

	function self.hide()
		compact.hide()
		if not self.tooltipElement or not self.tooltipElement.layout then
			return
		end
		self.tooltipElement.layout.props.visible = false
		self.tooltipElement:update()
	end

	function self.updateTooltip(itemData)
		if not self.tooltipElement or not self.tooltipElement.layout or not itemData then
			return
		end
		local model = detailModel.build(itemData)
		if not model then
			return
		end
		local bodyContent = self.tooltipElement.layout.content.s3ui_tooltip_body.content
		local header, fields = bodyContent.s3ui_tooltip_header.content, bodyContent.s3ui_tooltip_fields
		header.s3ui_tooltip_icon_box.content.s3ui_tooltip_icon.props.resource = model.icon
		header.s3ui_tooltip_name.props.text = model.name
		for key, name in pairs(DETAIL_FIELD_NAMES) do
			setTooltipField(fields, name, '')
			setTooltipFieldIcon(fields, name, key == 'type' and TOOLTIP.typeGeneric or TOOLTIP[key] or WHITE_TEXTURE)
		end
		local visibleFields = {}
		for _, field in ipairs(model.fields) do
			local name = DETAIL_FIELD_NAMES[field.key]
			if name then
				setTooltipField(fields, name, field.value)
				setTooltipFieldIcon(fields, name, field.icon)
				visibleFields[#visibleFields + 1] = name
			end
		end
		local m, visibleCount = metrics(), setVisibleFields(fields, visibleFields)
		local relativeSize, height = tooltipRelativeSize(visibleCount, nil, m), tooltipPixelHeight(visibleCount, m)
		self.tooltipElement.layout.props.relativeSize = relativeSize
		self.tooltipElement.layout.props.position = tooltipPosition(relativeSize)
		bodyContent.s3ui_tooltip_header.props.relativeSize = v2(1, m.tooltipHeaderHeight / height)
		fields.props.relativeSize = v2(1, visibleCount * m.tooltipFieldRowHeight / height)
		self.tooltipElement.layout.props.visible = true
		self.tooltipElement:update()
	end

	function self.makeCompactDetailBar()
		return compact.makeBar()
	end

	function self.update(itemData)
		if metrics().detailMode == 'compact' then
			compact.update(itemData)
		else
			self.updateTooltip(itemData)
		end
	end

	return self
end

return M
