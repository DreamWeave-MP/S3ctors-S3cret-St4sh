---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")
local detailModel = require("scripts.s3ui.inventory.details_model")

local v2 = util.vector2

local M = {}

local CARD_COLUMNS = 3
local DETAIL_WIDTH = 0.34
local GROUP_HEIGHTS = { weapons = 0.22, armor = 0.36, clothing = 0.42 }
local SELECTED_BORDER_ALPHA = 0.94
local SELECTED_STRIP_COLOR = util.color.rgb(0.86, 0.72, 0.42)
local EMPTY_TEXT = "—"

local function textLine(name, text, props, template)
	props = props or {}
	props.name = name
	return chrome.textLine(text, template or I.MWUI.templates.textNormal, props)
end

local function cardSummary(slot, selected)
	if selected then
		return slot.itemData and "Click or press Enter to unequip" or "Click or press Enter to browse items"
	end
	return slot.summary or ""
end

local function addSelectedBadge(content, slot)
	content:add(textLine("s3ui_equipment_" .. slot.key .. "_selected", "Selected", {
		anchor = v2(1, 0),
		relativePosition = v2(0.94, 0.08),
		relativeSize = v2(0.38, 0.2),
		textSize = 11,
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}, I.MWUI.templates.textHeader))
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

local function iconLayout(name, itemData)
	if not itemData or not itemData.icon then
		return nil
	end
	return {
		name = name,
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture({ path = itemData.icon }),
			anchor = v2(0, 0.5),
			relativePosition = v2(0.04, 0.56),
			relativeSize = v2(0.2, 0.56),
		},
	}
end

local function slotHitbox(ctx, slot, generation)
	return {
		name = "s3ui_equipment_" .. slot.key .. "_hitbox",
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 1) },
		userData = { slot = slot, generation = generation },
		events = {
			focusGain = ctx.async:callback(function(_, layout)
				local focused = layout and layout.userData
				if not focused or focused.generation ~= ctx.state.generation then
					return
				end
				if focused.slot then
					ctx.selectEquipmentSlot(focused.slot)
				end
			end),
			mouseMove = ctx.async:callback(function(_, layout)
				local hovered = layout and layout.userData
				if not hovered or hovered.generation ~= ctx.state.generation then
					return
				end
				if hovered.slot then
					ctx.selectEquipmentSlot(hovered.slot)
				end
			end),
			mouseClick = ctx.async:callback(function(_, layout)
				local clicked = layout and layout.userData
				if not clicked or clicked.generation ~= ctx.state.generation then
					return
				end
				if clicked.slot and clicked.slot.itemData then
					ctx.activateEquipmentSlot(clicked.slot)
				elseif clicked.slot then
					ctx.openEquipmentCategory(clicked.slot)
				end
			end),
		},
	}
end

local function makeSlotCard(ctx, slot)
	local selected = ctx.state.selectedEquipmentSlotKey == slot.key
	local generation = ctx.state.generation
	local itemData = slot.itemData
	local content = ui.content({})
	addBackground(content, selected and 0.48 or 0.18)
	if selected then
		content:add({
			name = "s3ui_equipment_" .. slot.key .. "_selected_strip",
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = SELECTED_STRIP_COLOR,
				alpha = 0.75,
				relativeSize = v2(1, 0.055),
			},
		})
		addSelectedBadge(content, slot)
	end
	local icon = iconLayout("s3ui_equipment_" .. slot.key .. "_icon", itemData)
	if icon then
		content:add(icon)
	end
	content:add(textLine("s3ui_equipment_" .. slot.key .. "_label", slot.label, {
		anchor = v2(0, 0),
		relativePosition = v2(0.06, 0.08),
		relativeSize = v2(0.88, 0.23),
		textSize = 13,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}, I.MWUI.templates.textHeader))
	content:add(textLine("s3ui_equipment_" .. slot.key .. "_name", itemData and itemData.name or EMPTY_TEXT, {
		anchor = v2(0, 0),
		relativePosition = v2(itemData and 0.27 or 0.06, 0.35),
		relativeSize = v2(itemData and 0.67 or 0.88, 0.34),
		textSize = 14,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Center,
		multiline = true,
		wordWrap = true,
		autoSize = false,
	}))
	content:add(textLine("s3ui_equipment_" .. slot.key .. "_summary", cardSummary(slot, selected), {
		anchor = v2(0, 1),
		relativePosition = v2(0.06, 0.9),
		relativeSize = v2(0.88, 0.22),
		textSize = 12,
		textAlignH = ui.ALIGNMENT.Start,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}))
	chrome.addSimpleBorder(
		content,
		"s3ui_equipment_" .. slot.key,
		selected and SELECTED_BORDER_ALPHA or 0.48,
		selected and 3 or 2
	)
	content:add(slotHitbox(ctx, slot, generation))
	return {
		name = "s3ui_equipment_slot_" .. slot.key,
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1 / CARD_COLUMNS, 1) },
		content = content,
	}
end

local function makeSlotRow(ctx, slots, startIndex, rowHeight)
	local row = ui.content({})
	for column = 1, CARD_COLUMNS do
		local slot = slots[startIndex + column - 1]
		if slot then
			row:add(makeSlotCard(ctx, slot))
		else
			row:add({ type = ui.TYPE.Widget, props = { relativeSize = v2(1 / CARD_COLUMNS, 1) } })
		end
	end
	return {
		type = ui.TYPE.Flex,
		props = { horizontal = true, relativeSize = v2(1, rowHeight), autoSize = false },
		content = row,
	}
end

local function makeGroup(ctx, group)
	local rowCount = math.max(math.ceil(#group.slots / CARD_COLUMNS), 1)
	local rows = ui.content({
		textLine("s3ui_equipment_group_" .. group.key, group.title, {
			relativeSize = v2(1, 0.18),
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}, I.MWUI.templates.textHeader),
	})
	local rowHeight = 0.82 / rowCount
	for index = 1, #group.slots, CARD_COLUMNS do
		rows:add(makeSlotRow(ctx, group.slots, index, rowHeight))
	end
	return {
		name = "s3ui_equipment_group_" .. group.key .. "_body",
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			relativeSize = v2(1, GROUP_HEIGHTS[group.key] or 0.33),
			autoSize = false,
		},
		content = rows,
	}
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

local function detailPanelContent(state)
	local selectedData = state.selectedEquipmentData
	local selectedLabel = state.selectedEquipmentSlotLabel or "Equipment"
	local model = detailModel.build(selectedData)
	local content = ui.content({})
	addBackground(content, 0.22)
	local body = ui.content({})
	if model then
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
	else
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
			body:add(
				textLine("s3ui_equipment_detail_empty_hint", "Click, Enter, or Space to browse compatible items.", {
					relativeSize = v2(1, 0.14),
					textSize = 13,
					textAlignH = ui.ALIGNMENT.Start,
					textAlignV = ui.ALIGNMENT.Center,
					multiline = true,
					wordWrap = true,
					autoSize = false,
				})
			)
		end
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

local function makeDetailPanel(ctx)
	return {
		name = "s3ui_equipment_detail",
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(DETAIL_WIDTH, 1) },
		content = detailPanelContent(ctx.state),
	}
end

function M.updateDetailPanel(rootElement, state)
	if not rootElement or not rootElement.layout or not rootElement.layout.content then
		return false
	end
	local body = rootElement.layout.content.s3ui_body
	local main = body and body.content and body.content.s3ui_main
	local equipmentView = main and main.content and main.content.s3ui_equipment_view
	local detail = equipmentView and equipmentView.content and equipmentView.content.s3ui_equipment_detail
	if not detail then
		return false
	end
	detail.content = detailPanelContent(state)
	rootElement:update()
	return true
end

function M.make(ctx)
	local groups = ui.content({})
	for _, group in ipairs(ctx.groups or {}) do
		groups:add(makeGroup(ctx, group))
	end
	return {
		name = "s3ui_equipment_view",
		type = ui.TYPE.Flex,
		props = { horizontal = true, size = v2(0, 0), relativeSize = v2(0, 1), autoSize = false },
		external = { grow = 1, stretch = 1 },
		content = ui.content({
			{
				name = "s3ui_equipment_slots",
				type = ui.TYPE.Flex,
				props = { horizontal = false, relativeSize = v2(1 - DETAIL_WIDTH, 1), autoSize = false },
				content = groups,
			},
			makeDetailPanel(ctx),
		}),
	}
end

return M
