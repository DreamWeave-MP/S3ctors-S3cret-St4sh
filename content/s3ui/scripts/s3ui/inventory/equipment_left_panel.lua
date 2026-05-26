---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")

local v2 = util.vector2

local M = {}

local GROUP_HEIGHTS = { equipped = 1 }
local SELECTED_BORDER_ALPHA = 0.94
local CARD_SIZE = v2(60, 60)
local ICON_SIZE = v2(52, 52)
local EMPTY_TEXT = "—"

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

local function scaledSize(size, scale)
	return v2(size.x * scale, size.y * scale)
end

local function iconLayout(name, itemData, scale)
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
			size = scaledSize(ICON_SIZE, scale),
		},
	}
end

local function emptySlotLayout(name, scale)
	return textLine(name, EMPTY_TEXT, {
		relativeSize = v2(1, 1),
		textSize = 30 * scale,
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

local function makeSlotCard(ctx, slot, placement)
	local selected = ctx.state.selectedEquipmentSlotKey == slot.key
	local itemData = slot.itemData
	local scale = placement.scale or 1
	local cardContent = ui.content({})
	addBackground(cardContent, selected and 0.48 or 0.18)
	local icon = iconLayout("s3ui_equipment_" .. slot.key .. "_icon", itemData, scale)
	if icon then
		cardContent:add(icon)
	else
		cardContent:add(emptySlotLayout("s3ui_equipment_" .. slot.key .. "_empty", scale))
	end
	chrome.addSimpleBorder(
		cardContent,
		"s3ui_equipment_" .. slot.key,
		selected and SELECTED_BORDER_ALPHA or 0.48,
		selected and 3 or 2
	)
	cardContent:add(slotHitbox(ctx, slot, ctx.state.generation))
	return {
		name = "s3ui_equipment_slot_" .. slot.key,
		type = ui.TYPE.Widget,
		props = {
			anchor = v2(0.5, 0.5),
			relativePosition = v2(placement.x, placement.y),
			size = scaledSize(CARD_SIZE, scale),
		},
		content = cardContent,
	}
end

local function makeGroup(ctx, group)
	local content = ui.content({
		textLine("s3ui_equipment_group_" .. group.key, group.title, {
			relativeSize = v2(1, 0.1),
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}, I.MWUI.templates.textHeader),
	})
	local paperdoll = ui.content({})
	for _, slot in ipairs(group.slots or {}) do
		local placement = group.layout and group.layout[slot.key]
		if placement then
			paperdoll:add(makeSlotCard(ctx, slot, placement))
		end
	end
	content:add({
		name = "s3ui_equipment_group_" .. group.key .. "_paperdoll",
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 0.9), autoSize = false },
		content = paperdoll,
	})
	return {
		name = "s3ui_equipment_group_" .. group.key .. "_body",
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			relativeSize = v2(1, GROUP_HEIGHTS[group.key] or 0.33),
			autoSize = false,
		},
		content = content,
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
