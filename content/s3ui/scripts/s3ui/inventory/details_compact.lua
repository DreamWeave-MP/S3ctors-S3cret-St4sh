---@omw-context player

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local chrome = require 'scripts.s3ui.inventory.chrome'
local detailModel = require 'scripts.s3ui.inventory.details_model'

local v2 = util.vector2
local WHITE_TEXTURE = chrome.WHITE_TEXTURE
local BACKGROUND_COLOR = chrome.BACKGROUND_COLOR
local FRAME_SIZE_MEDIUM = chrome.FRAME_SIZE_MEDIUM
local FIELD_COLUMNS = 4
local FIELD_ROWS = 3
local FIELD_SLOT_COUNT = FIELD_COLUMNS * FIELD_ROWS

---@class S3UI.InventoryCompactDetailsModule
local M = {}

local function detailText(name, text, props, template)
	return {
		name = name,
		template = template or I.MWUI.templates.textNormal,
		props = chrome.textProps(text, props),
	}
end

function M.new(ctx)
	local self = { visible = false }
	local metrics = ctx.metrics
	local root = ctx.root
	local updateRoot = ctx.updateRoot

	local function fieldSlot(slotIndex)
		local m, name = metrics(), 's3ui_compact_detail_field_' .. tostring(slotIndex)
		return {
			name = name,
			type = ui.TYPE.Flex,
			props = { horizontal = true, relativeSize = v2(1 / FIELD_COLUMNS, 1), autoSize = false },
			content = ui.content {
				{
					name = name .. '_icon_box',
					type = ui.TYPE.Widget,
					props = { relativeSize = v2(0.28, 1) },
					content = ui.content {
						{
							name = name .. '_icon',
							type = ui.TYPE.Image,
							props = {
								resource = WHITE_TEXTURE,
								alpha = 0,
								anchor = v2(0.5, 0.5),
								relativePosition = v2(0.5, 0.5),
								size = m.compactDetailFieldIconSize,
							},
						},
					},
				},
				detailText(name .. '_value', '', {
					relativeSize = v2(0.72, 1),
					textSize = m.compactDetailFieldTextSize,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Center,
					multiline = true,
					wordWrap = true,
					autoSize = false,
				}),
			},
		}
	end

	local function fieldsLayout()
		local rows, slotIndex = {}, 1
		for rowIndex = 1, FIELD_ROWS do
			local row = {}
			for _ = 1, FIELD_COLUMNS do
				row[#row + 1] = fieldSlot(slotIndex)
				slotIndex = slotIndex + 1
			end
			rows[#rows + 1] = {
				name = 's3ui_compact_detail_row_' .. tostring(rowIndex),
				type = ui.TYPE.Flex,
				props = { horizontal = true, relativeSize = v2(1, 1 / FIELD_ROWS), autoSize = false },
				content = ui.content(row),
			}
		end
		return ui.content(rows)
	end

	local function compactBar()
		local rootElement = root()
		if not rootElement or not rootElement.layout then
			return nil
		end
		local body = rootElement.layout.content.s3ui_body
		if not body or not body.content then
			return nil
		end
		local ok, bar = pcall(function()
			return body.content.s3ui_compact_detail_bar
		end)
		if ok then
			return bar
		end
		return nil
	end

	function self.makeBar()
		local m, inset = metrics(), chrome.frameInset(FRAME_SIZE_MEDIUM)
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
				name = 's3ui_compact_detail_content',
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					position = v2(inset, inset),
					size = v2(-inset * 2, -inset * 2),
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
							relativeSize = m.compactDetailHeaderRelativeSize,
							autoSize = false,
						},
						content = ui.content {
							{
								name = 's3ui_compact_detail_icon_box',
								type = ui.TYPE.Widget,
								props = { relativeSize = v2(0.36, 1) },
								content = ui.content {
									{
										name = 's3ui_compact_detail_icon',
										type = ui.TYPE.Image,
										props = {
											resource = WHITE_TEXTURE,
											anchor = v2(0.5, 0.5),
											relativePosition = v2(0.5, 0.5),
											size = m.compactDetailIconSize,
										},
									},
								},
							},
							{
								name = 's3ui_compact_detail_title_box',
								type = ui.TYPE.Flex,
								props = { horizontal = false, relativeSize = v2(0.64, 1), autoSize = false },
								content = ui.content {
									detailText('s3ui_compact_detail_name', '', {
										relativeSize = v2(1, 1),
										textSize = m.compactDetailHeaderTextSize,
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
							relativeSize = m.compactDetailFieldsRelativeSize,
							autoSize = false,
						},
						content = fieldsLayout(),
					},
				},
			},
		}
		chrome.addOrnateFrame(content, 's3ui_compact_detail', FRAME_SIZE_MEDIUM, 0.95)
		return {
			name = 's3ui_compact_detail_bar',
			type = ui.TYPE.Widget,
			props = { relativeSize = m.compactDetailRelativeSize },
			content = content,
		}
	end

	function self.hide()
		if not self.visible then
			return
		end
		local bar = compactBar()
		if not bar then
			self.visible = false
			return
		end
		bar.content.s3ui_compact_detail_content.props.visible = false
		self.visible = false
		updateRoot()
	end

	function self.update(itemData)
		local model, bar = detailModel.build(itemData), compactBar()
		if not model or not bar then
			return
		end
		local content = bar.content.s3ui_compact_detail_content
		local detailContent, prefix = content.content, 's3ui_compact_detail_field_'
		local headerContent = detailContent.s3ui_compact_detail_header.content
		headerContent.s3ui_compact_detail_icon_box.content.s3ui_compact_detail_icon.props.resource = model.icon
		headerContent.s3ui_compact_detail_title_box.content.s3ui_compact_detail_name.props.text = model.name
		local fields = detailContent.s3ui_compact_detail_fields
		for slotIndex = 1, FIELD_SLOT_COUNT do
			local row =
				fields.content['s3ui_compact_detail_row_' .. tostring(math.floor((slotIndex - 1) / FIELD_COLUMNS) + 1)]
			local slot = row.content[prefix .. tostring(slotIndex)]
			local icon = slot.content[prefix .. tostring(slotIndex) .. '_icon_box'].content[prefix .. tostring(
				slotIndex
			) .. '_icon']
			local value = slot.content[prefix .. tostring(slotIndex) .. '_value']
			local field = model.fields[slotIndex]
			icon.props.resource = field and field.icon or WHITE_TEXTURE
			icon.props.alpha = field and 0.95 or 0
			value.props.text = field and (field.compactValue or field.value) or ''
		end
		content.props.visible = true
		self.visible = true
		updateRoot()
	end

	function self.destroy()
		self.visible = false
	end

	return self
end

return M
