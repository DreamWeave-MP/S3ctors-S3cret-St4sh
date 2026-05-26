---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")
local detailModel = require("scripts.s3ui.inventory.details_model")

local v2 = util.vector2

local M = {}

M.WIDTH = 0.34

local function textLine(name, text, props, template)
	props = props or {}
	props.name = name
	return chrome.textLine(text, template or I.MWUI.templates.textNormal, props)
end

local function addBackground(content, alpha, color)
	content:add({
		type = ui.TYPE.Image,
		props = {
			resource = chrome.WHITE_TEXTURE,
			color = color or chrome.BACKGROUND_COLOR,
			alpha = alpha,
			relativeSize = v2(1, 1),
		},
	})
end

local function detailField(field, index)
	return {
		name = "s3ui_equipment_detail_field_" .. tostring(index),
		type = ui.TYPE.Flex,
		props = { horizontal = true, relativeSize = v2(1, 0.065), autoSize = false },
		content = ui.content({
			{
				type = ui.TYPE.Widget,
				props = { relativeSize = v2(0.18, 1) },
				content = ui.content({
					{
						type = ui.TYPE.Image,
						props = {
							resource = field.icon,
							anchor = v2(0.5, 0.5),
							relativePosition = v2(0.5, 0.5),
							size = v2(22, 22),
						},
					},
				}),
			},
			textLine("s3ui_equipment_detail_field_" .. tostring(index) .. "_value", field.value, {
				relativeSize = v2(0.82, 1),
				textSize = 14,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Center,
				multiline = true,
				wordWrap = true,
				autoSize = false,
			}),
		}),
	}
end

local function populatedBody(body, selectedLabel, model)
	body:add(textLine("s3ui_equipment_detail_slot", selectedLabel, {
		relativeSize = v2(1, 0.09),
		textSize = 14,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}, I.MWUI.templates.textHeader))
	body:add({
		type = ui.TYPE.Flex,
		props = { horizontal = true, relativeSize = v2(1, 0.2), autoSize = false },
		content = ui.content({
			{
				type = ui.TYPE.Widget,
				props = { relativeSize = v2(0.28, 1) },
				content = ui.content({
					{
						type = ui.TYPE.Image,
						props = {
							resource = model.icon,
							anchor = v2(0.5, 0.5),
							relativePosition = v2(0.5, 0.5),
							size = v2(48, 48),
						},
					},
				}),
			},
			textLine("s3ui_equipment_detail_name", model.name, {
				relativeSize = v2(0.72, 1),
				textSize = 18,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Center,
				multiline = true,
				wordWrap = true,
				autoSize = false,
			}, I.MWUI.templates.textHeader),
		}),
	})
	for index, field in ipairs(model.fields) do
		body:add(detailField(field, index))
	end
	body:add(textLine("s3ui_equipment_detail_hint", "Click, Enter, or Space to unequip the selected item.", {
		relativeSize = v2(1, 0.12),
		textSize = 13,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Center,
		multiline = true,
		wordWrap = true,
		autoSize = false,
	}))
end

local function emptyBody(body, state, selectedLabel)
	body:add(textLine("s3ui_equipment_detail_empty_title", selectedLabel, {
		relativeSize = v2(1, 0.16),
		textSize = 18,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}, I.MWUI.templates.textHeader))
	body:add(
		textLine(
			"s3ui_equipment_detail_empty_text",
			state.selectedEquipmentSlotKey and ("No item equipped in " .. selectedLabel .. ".")
				or "Select an equipment slot.",
			{
				relativeSize = v2(1, 0.14),
				textSize = 15,
				textAlignH = ui.ALIGNMENT.Start,
				textAlignV = ui.ALIGNMENT.Center,
				autoSize = false,
			}
		)
	)
	if state.selectedEquipmentSlotKey then
		body:add(textLine("s3ui_equipment_detail_empty_hint", "Click, Enter, or Space to browse compatible items.", {
			relativeSize = v2(1, 0.14),
			textSize = 13,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			multiline = true,
			wordWrap = true,
			autoSize = false,
		}))
	end
end

function M.content(state)
	local selectedData = state.selectedEquipmentData
	local selectedLabel = state.selectedEquipmentSlotLabel or "Equipment"
	local model = detailModel.build(selectedData)
	local content = ui.content({})
	local body = ui.content({})
	addBackground(content, 0.22)
	if model then
		populatedBody(body, selectedLabel, model)
	else
		emptyBody(body, state, selectedLabel)
	end
	content:add({
		name = "s3ui_equipment_detail_body",
		type = ui.TYPE.Flex,
		props = { horizontal = false, position = v2(10, 10), size = v2(-20, -20), relativeSize = v2(1, 1) },
		content = body,
	})
	chrome.addSimpleBorder(content, "s3ui_equipment_detail", 0.62, 2)
	return content
end

function M.layout(state)
	return {
		name = "s3ui_equipment_detail",
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(M.WIDTH, 1) },
		content = M.content(state),
	}
end

function M.create(state)
	return ui.create(M.layout(state))
end

function M.update(element, state)
	if not element or not element.layout then
		return false
	end
	element.layout = M.layout(state)
	element:update()
	return true
end

return M
