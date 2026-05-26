---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")
local detailModel = require("scripts.s3ui.inventory.details_model")

local v2 = util.vector2

local M = {}

local FRAME_SIZE = chrome.FRAME_SIZE_MEDIUM
local FIELD_ROW_COUNT = 10
local TITLE_TEXT_SIZE = 18
local BODY_TEXT_SIZE = 15
local ICON_SIZE = v2(54, 54)
local FIELD_ICON_SIZE = v2(22, 22)

local function detailText(name, text, props, template)
	return {
		name = name,
		template = template or I.MWUI.templates.textNormal,
		props = chrome.textProps(text, props),
	}
end

local function background(content)
	content:add({
		type = ui.TYPE.Image,
		props = {
			resource = chrome.WHITE_TEXTURE,
			color = chrome.BACKGROUND_COLOR,
			alpha = chrome.backgroundAlpha(),
			relativeSize = v2(1, 1),
		},
	})
end

local function header(model)
	return {
		name = "s3ui_equipment_detail_header",
		type = ui.TYPE.Flex,
		props = { horizontal = true, relativeSize = v2(1, 0.22), autoSize = false },
		content = ui.content({
			{
				name = "s3ui_equipment_detail_icon_box",
				type = ui.TYPE.Widget,
				props = { relativeSize = v2(0.3, 1), autoSize = false },
				content = ui.content({
					{
						name = "s3ui_equipment_detail_icon",
						type = ui.TYPE.Image,
						props = {
							resource = model.icon,
							anchor = v2(0.5, 0.5),
							relativePosition = v2(0.5, 0.5),
							size = ICON_SIZE,
						},
					},
				}),
			},
			detailText("s3ui_equipment_detail_name", model.name or "", {
				relativeSize = v2(0.7, 1),
				textSize = TITLE_TEXT_SIZE,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Center,
				multiline = true,
				wordWrap = true,
				autoSize = false,
			}, I.MWUI.templates.textHeader),
		}),
	}
end

local function fieldRow(index, field)
	local name = "s3ui_equipment_detail_field_" .. tostring(index)
	return {
		name = name,
		type = ui.TYPE.Flex,
		props = { horizontal = true, relativeSize = v2(1, 1 / FIELD_ROW_COUNT), autoSize = false },
		content = ui.content({
			{
				name = name .. "_icon_box",
				type = ui.TYPE.Widget,
				props = { relativeSize = v2(0.18, 1), autoSize = false },
				content = ui.content({
					{
						name = name .. "_icon",
						type = ui.TYPE.Image,
						props = {
							resource = field.icon,
							alpha = 0.95,
							anchor = v2(0.5, 0.5),
							relativePosition = v2(0.5, 0.5),
							size = FIELD_ICON_SIZE,
						},
					},
				}),
			},
			detailText(name .. "_value", field.value or "", {
				relativeSize = v2(0.82, 1),
				textSize = BODY_TEXT_SIZE,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Center,
				multiline = true,
				wordWrap = true,
				autoSize = false,
			}),
		}),
	}
end

local function fields(model)
	local rows = {}
	for index = 1, FIELD_ROW_COUNT do
		local field = model.fields[index]
		if field then
			rows[#rows + 1] = fieldRow(index, field)
		end
	end
	return {
		name = "s3ui_equipment_detail_fields",
		type = ui.TYPE.Flex,
		props = { horizontal = false, relativeSize = v2(1, 0.78), autoSize = false },
		content = ui.content(rows),
	}
end

local function placeholder(ctx)
	local title = ctx.state.selectedEquipmentSlotLabel or "Equipment"
	local body = ctx.state.selectedEquipmentSlotKey and "Empty slot" or "Hover equipment to inspect it."
	return {
		name = "s3ui_equipment_detail_placeholder",
		type = ui.TYPE.Flex,
		props = { horizontal = false, relativeSize = v2(1, 1), autoSize = false },
		content = ui.content({
			detailText("s3ui_equipment_detail_placeholder_title", title, {
				relativeSize = v2(1, 0.25),
				textSize = TITLE_TEXT_SIZE,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.End,
				autoSize = false,
			}, I.MWUI.templates.textHeader),
			detailText("s3ui_equipment_detail_placeholder_body", body, {
				relativeSize = v2(1, 0.75),
				textSize = BODY_TEXT_SIZE,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Start,
				multiline = true,
				wordWrap = true,
				autoSize = false,
			}),
		}),
	}
end

local function body(ctx)
	local model = detailModel.build(ctx.state.selectedEquipmentData)
	if not model then
		return placeholder(ctx)
	end
	return {
		name = "s3ui_equipment_detail_body",
		type = ui.TYPE.Flex,
		props = { horizontal = false, relativeSize = v2(1, 1), autoSize = false },
		content = ui.content({ header(model), fields(model) }),
	}
end

function M.layout(ctx, width, x, height, y)
	local inset = chrome.frameInset(FRAME_SIZE)
	local content = ui.content({})
	x = x or 0
	height = height or 1
	y = y or 0
	background(content)
	content:add({
		name = "s3ui_equipment_detail_inner",
		type = ui.TYPE.Widget,
		props = { position = v2(inset, inset), size = v2(-inset * 2, -inset * 2), relativeSize = v2(1, 1) },
		content = ui.content({ body(ctx) }),
	})
	chrome.addOrnateFrame(content, "s3ui_equipment_detail", FRAME_SIZE, 0.95)
	return {
		name = "s3ui_equipment_detail_panel",
		type = ui.TYPE.Widget,
		props = { relativePosition = v2(x, y), relativeSize = v2(width, height), autoSize = false },
		content = content,
	}
end

function M.create(ctx, width, x, height, y)
	return ui.create(M.layout(ctx, width, x, height, y))
end

function M.update(element, ctx, width, x, height, y)
	if not element or not element.layout then
		return false
	end
	element.layout = M.layout(ctx, width, x, height, y)
	element:update()
	return true
end

return M
