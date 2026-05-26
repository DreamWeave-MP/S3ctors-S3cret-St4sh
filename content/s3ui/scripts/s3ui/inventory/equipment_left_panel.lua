---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")

local v2 = util.vector2

local M = {}

local CARD_COLUMNS = 4
local GROUP_HEIGHTS = { equipped = 1 }
local SELECTED_BORDER_ALPHA = 0.94
local ICON_SIZE = v2(52, 52)
local EMPTY_TEXT = "—"

M.CARD_COLUMNS = CARD_COLUMNS

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

local function iconLayout(name, itemData)
	if not itemData or not itemData.icon then
		return nil
	end
	return {
		name = name,
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture({ path = itemData.icon }),
			anchor = v2(0.5, 0.5),
			relativePosition = v2(0.5, 0.5),
			size = ICON_SIZE,
		},
	}
end

local function emptySlotLayout(name)
	return textLine(name, EMPTY_TEXT, {
		relativeSize = v2(1, 1),
		textSize = 30,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}, I.MWUI.templates.textHeader)
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
				if focused and focused.generation == ctx.state.generation and focused.slot then
					ctx.selectEquipmentSlot(focused.slot)
				end
			end),
			mouseMove = ctx.async:callback(function(_, layout)
				local hovered = layout and layout.userData
				if hovered and hovered.generation == ctx.state.generation and hovered.slot then
					ctx.selectEquipmentSlot(hovered.slot)
				end
			end),
			mouseClick = ctx.async:callback(function(_, layout)
				local clicked = layout and layout.userData
				if not clicked or clicked.generation ~= ctx.state.generation or not clicked.slot then
					return
				end
				if clicked.slot.itemData then
					ctx.activateEquipmentSlot(clicked.slot)
				else
					ctx.openEquipmentCategory(clicked.slot)
				end
			end),
		},
	}
end

local function makeSlotCard(ctx, slot)
	local selected = ctx.state.selectedEquipmentSlotKey == slot.key
	local itemData = slot.itemData
	local content = ui.content({})
	addBackground(content, selected and 0.48 or 0.18)
	local icon = iconLayout("s3ui_equipment_" .. slot.key .. "_icon", itemData)
	if icon then
		content:add(icon)
	else
		content:add(emptySlotLayout("s3ui_equipment_" .. slot.key .. "_empty"))
	end
	chrome.addSimpleBorder(
		content,
		"s3ui_equipment_" .. slot.key,
		selected and SELECTED_BORDER_ALPHA or 0.48,
		selected and 3 or 2
	)
	content:add(slotHitbox(ctx, slot, ctx.state.generation))
	return {
		name = "s3ui_equipment_slot_" .. slot.key,
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1 / CARD_COLUMNS, 1) },
		content = content,
	}
end

local function makeSlotRowFromSlots(ctx, slots, rowHeight)
	local row = ui.content({})
	for column = 1, CARD_COLUMNS do
		local slot = slots[column]
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

local function makeSlotRow(ctx, slots, startIndex, rowHeight)
	local rowSlots = {}
	for column = 1, CARD_COLUMNS do
		rowSlots[column] = slots[startIndex + column - 1]
	end
	return makeSlotRowFromSlots(ctx, rowSlots, rowHeight)
end

local function slotsByKey(slots)
	local byKey = {}
	for _, slot in ipairs(slots or {}) do
		byKey[slot.key] = slot
	end
	return byKey
end

local function makeExplicitRows(ctx, group, rows, rowHeight)
	local byKey = slotsByKey(group.slots)
	for _, rowDef in ipairs(group.rows or {}) do
		local rowSlots = {}
		for column = 1, CARD_COLUMNS do
			local key = rowDef[column]
			rowSlots[column] = key and byKey[key] or nil
		end
		rows:add(makeSlotRowFromSlots(ctx, rowSlots, rowHeight))
	end
end

local function makeGroup(ctx, group)
	local hasExplicitRows = group.rows and #group.rows > 0
	local rowCount = hasExplicitRows and #group.rows or math.max(math.ceil(#group.slots / CARD_COLUMNS), 1)
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
	if hasExplicitRows then
		makeExplicitRows(ctx, group, rows, rowHeight)
	else
		for index = 1, #group.slots, CARD_COLUMNS do
			rows:add(makeSlotRow(ctx, group.slots, index, rowHeight))
		end
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

function M.layout(ctx, width)
	local groups = ui.content({})
	for _, group in ipairs(ctx.groups or {}) do
		groups:add(makeGroup(ctx, group))
	end
	return {
		name = "s3ui_equipment_slots",
		type = ui.TYPE.Flex,
		props = { horizontal = false, relativeSize = v2(width, 1), autoSize = false },
		content = groups,
	}
end

function M.create(ctx, width)
	return ui.create(M.layout(ctx, width))
end

function M.update(element, ctx, width)
	if not element or not element.layout then
		return false
	end
	element.layout = M.layout(ctx, width)
	element:update()
	return true
end

return M
