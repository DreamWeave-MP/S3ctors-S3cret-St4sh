---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local actions = require("scripts.s3ui.inventory.actions")
local chrome = require("scripts.s3ui.inventory.chrome")
local controls = require("scripts.s3ui.inventory.controls")
local data = require("scripts.s3ui.inventory.data")
local icons = require("scripts.s3ui.inventory.icons")

local v2 = util.vector2
local M = {}

local function addStateBadge(content, name, icon, anchor, position, size, absoluteSize)
	local props = { resource = icon, anchor = anchor, relativePosition = position, alpha = 0.96 }
	if absoluteSize then
		props.size = size
	else
		props.relativeSize = size
	end
	content:add({ name = name, type = ui.TYPE.Image, props = props })
end

local function listStateBadgeSize(metrics)
	local edge = math.floor(metrics.listIconSize.y * icons.LIST_STATE_BADGE_ICON_FRACTION)
	if edge < 10 then
		edge = 10
	end
	return v2(edge, edge)
end

local function addGridStateBadges(content, prefix, itemData)
	if itemData.equipped then
		addStateBadge(
			content,
			prefix .. "_equipped",
			icons.ITEM_STATE.equipped,
			v2(0, 0),
			v2(0.08, 0.08),
			icons.ITEM_STATE_BADGE_RELATIVE_SIZE
		)
	end
	if itemData.enchanted then
		addStateBadge(
			content,
			prefix .. "_enchanted",
			icons.ITEM_STATE.enchanted,
			v2(1, 0),
			v2(0.92, 0.08),
			icons.ITEM_STATE_BADGE_RELATIVE_SIZE
		)
	end
	if itemData.broken then
		addStateBadge(
			content,
			prefix .. "_broken",
			icons.ITEM_STATE.broken,
			v2(0, 1),
			v2(0.08, 0.92),
			icons.ITEM_STATE_BADGE_RELATIVE_SIZE
		)
	end
end

local function addListStateBadges(content, prefix, itemData, metrics)
	local badgeSize = listStateBadgeSize(metrics)
	if itemData.equipped then
		addStateBadge(
			content,
			prefix .. "_equipped",
			icons.ITEM_STATE.equipped,
			v2(0, 0.5),
			v2(0.012, 0.25),
			badgeSize,
			true
		)
	end
	if itemData.enchanted then
		addStateBadge(
			content,
			prefix .. "_enchanted",
			icons.ITEM_STATE.enchanted,
			v2(0, 0.5),
			v2(0.012, 0.5),
			badgeSize,
			true
		)
	end
	if itemData.broken then
		addStateBadge(
			content,
			prefix .. "_broken",
			icons.ITEM_STATE.broken,
			v2(0, 0.5),
			v2(0.012, 0.75),
			badgeSize,
			true
		)
	end
end

local function makeGridCategoryHeader(ctx, entry, index)
	local metrics, generation = ctx.metrics(), ctx.state.generation
	local collapsed, icon = entry.collapsed, icons.CATEGORY[entry.categoryKey]
	local iconSize = icons.CATEGORY_RELATIVE_SIZES[entry.categoryKey] or v2(0.58, 0.58)
	local content = ui.content({
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = collapsed and icons.CATEGORY_COLLAPSED_COLOR or icons.CATEGORY_HEADER_COLOR,
				alpha = 0.72,
				position = v2(chrome.SIMPLE_BORDER_THICKNESS, chrome.SIMPLE_BORDER_THICKNESS),
				size = v2(-chrome.SIMPLE_BORDER_THICKNESS * 2, -chrome.SIMPLE_BORDER_THICKNESS * 2),
				relativeSize = v2(1, 1),
			},
		},
	})
	if icon then
		content:add({
			name = "slot_" .. tostring(index) .. "_category_icon",
			type = ui.TYPE.Image,
			props = {
				resource = icon,
				anchor = v2(0.5, 0.5),
				relativePosition = v2(0.5, 0.48),
				relativeSize = iconSize,
				alpha = collapsed and 0.62 or 0.95,
			},
		})
	else
		content:add(controls.controlText("slot_" .. tostring(index) .. "_category_text", entry.label, 13))
	end
	content:add(chrome.textLine(collapsed and "+" or "-", I.MWUI.templates.textHeader, {
		name = "slot_" .. tostring(index) .. "_category_toggle",
		anchor = v2(0, 0),
		relativePosition = v2(0.08, 0.06),
		relativeSize = icons.CATEGORY_ICON_TOGGLE_SIZE,
		textSize = 16,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}))
	content:add(chrome.textLine(tostring(entry.count), I.MWUI.templates.textNormal, {
		name = "slot_" .. tostring(index) .. "_category_count",
		anchor = v2(1, 1),
		relativePosition = v2(0.92, 0.92),
		relativeSize = icons.CATEGORY_ICON_COUNT_SIZE,
		textSize = 14,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = false,
	}))
	chrome.addSimpleBorder(content, "slot_" .. tostring(index) .. "_category", collapsed and 0.52 or 0.72, 2)
	return {
		name = "slot_" .. tostring(index),
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1 / metrics.gridColumns, 1) },
		userData = entry,
		events = {
			focusGain = ctx.async:callback(function()
				if generation ~= ctx.state.generation then
					return
				end
				ctx.selectSlot(index, nil)
			end),
			mouseClick = ctx.async:callback(function(_, layout)
				if generation ~= ctx.state.generation then
					return
				end
				local clicked = layout and layout.userData
				if not clicked then
					return
				end
				ctx.selectSlot(index, nil)
				ctx.state:toggleCategory(clicked.categoryKey)
				ctx.queueRebuild()
			end),
		},
		content = content,
	}
end

local function makeGridSlot(ctx, entry, index)
	if entry and entry.kind == "categoryHeader" then
		return makeGridCategoryHeader(ctx, entry, index)
	end
	local metrics, itemData, generation = ctx.metrics(), entry and entry.data, ctx.state.generation
	local content = ui.content({})
	if itemData then
		local iconProps =
			{ anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.45), relativeSize = icons.ICON_RELATIVE_SIZE }
		if itemData.icon then
			iconProps.resource = ui.texture({ path = itemData.icon })
		end
		content:add({ type = ui.TYPE.Image, props = iconProps })
		if itemData.count > 1 then
			content:add(chrome.textLine(tostring(itemData.count), I.MWUI.templates.textNormal, {
				anchor = v2(1, 1),
				relativePosition = v2(0.88, 0.88),
				relativeSize = icons.COUNT_RELATIVE_SIZE,
				textSize = 13,
			}))
		end
		addGridStateBadges(content, "slot_" .. tostring(index), itemData)
	else
		content:add({ type = ui.TYPE.Widget, props = { relativeSize = v2(1, 1) } })
	end
	chrome.addSimpleBorder(content, "slot_" .. tostring(index), itemData and 0.42 or 0.28, 1)
	return {
		name = "slot_" .. tostring(index),
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1 / metrics.gridColumns, 1) },
		userData = itemData,
		events = itemData and {
			focusGain = ctx.async:callback(function(_, layout)
				if generation ~= ctx.state.generation then
					return
				end
				ctx.selectSlot(index, layout and layout.userData)
			end),
			mouseClick = ctx.async:callback(function(event, layout)
				if generation ~= ctx.state.generation or event.button ~= 1 then
					return
				end
				local clicked = layout and layout.userData
				if not clicked then
					return
				end
				ctx.selectSlot(index, clicked)
				actions.activateItem(clicked, ctx)
			end),
			focusLoss = ctx.async:callback(function()
				if generation ~= ctx.state.generation then
					return
				end
				ctx.clearSelection()
			end),
		} or nil,
		content = content,
	}
end

function M.makeGrid(entries, firstIndex, ctx)
	local metrics, rows, index, slotIndex = ctx.metrics(), ui.content({}), firstIndex or 1, 1
	for rowIndex = 1, metrics.gridRows do
		local row = ui.content({})
		for _ = 1, metrics.gridColumns do
			row:add(makeGridSlot(ctx, entries[index], slotIndex))
			index = index + 1
			slotIndex = slotIndex + 1
		end
		rows:add({
			type = ui.TYPE.Flex,
			props = { horizontal = true, relativeSize = v2(1, 1 / metrics.gridRows), autoSize = false },
			external = rowIndex == metrics.gridRows and { grow = 1 } or nil,
			content = row,
		})
	end
	return {
		type = ui.TYPE.Flex,
		props = { horizontal = false, size = v2(0, 0), relativeSize = v2(0, 1), autoSize = false },
		external = { grow = 1, stretch = 1 },
		content = rows,
	}
end

local function makeListCategoryRow(ctx, entry, index)
	local metrics, collapsed, generation = ctx.metrics(), entry.collapsed, ctx.state.generation
	local icon = icons.CATEGORY[entry.categoryKey]
	local content = ui.content({
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = collapsed and icons.CATEGORY_COLLAPSED_COLOR or icons.CATEGORY_HEADER_COLOR,
				alpha = 0.72,
				position = v2(chrome.SIMPLE_BORDER_THICKNESS, chrome.SIMPLE_BORDER_THICKNESS),
				size = v2(-chrome.SIMPLE_BORDER_THICKNESS * 2, -chrome.SIMPLE_BORDER_THICKNESS * 2),
				relativeSize = v2(1, 1),
			},
		},
		chrome.textLine(collapsed and "+" or "-", I.MWUI.templates.textHeader, {
			anchor = v2(0, 0.5),
			relativePosition = v2(0.04, 0.5),
			relativeSize = v2(0.06, 0.7),
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}),
		chrome.textLine(entry.label, I.MWUI.templates.textHeader, {
			anchor = v2(0, 0.5),
			relativePosition = v2(0.18, 0.5),
			relativeSize = v2(0.5, 0.7),
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}),
		chrome.textLine(tostring(entry.count), I.MWUI.templates.textNormal, {
			anchor = v2(1, 0.5),
			relativePosition = v2(0.94, 0.5),
			relativeSize = v2(0.12, 0.7),
			textSize = 14,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}),
	})
	if icon then
		content:add({
			name = "list_" .. tostring(index) .. "_category_icon",
			type = ui.TYPE.Image,
			props = {
				resource = icon,
				anchor = v2(0, 0.5),
				relativePosition = v2(0.1, 0.5),
				size = metrics.listIconSize,
				alpha = collapsed and 0.62 or 0.95,
			},
		})
	end
	chrome.addSimpleBorder(content, "list_" .. tostring(index) .. "_category", collapsed and 0.52 or 0.72, 2)
	return {
		name = "list_" .. tostring(index),
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 1 / metrics.listRows) },
		userData = entry,
		events = {
			focusGain = ctx.async:callback(function()
				if generation ~= ctx.state.generation then
					return
				end
				ctx.selectSlot(index, nil)
			end),
			mouseClick = ctx.async:callback(function(_, layout)
				if generation ~= ctx.state.generation then
					return
				end
				local clicked = layout and layout.userData
				if not clicked then
					return
				end
				ctx.selectSlot(index, nil)
				ctx.state:toggleCategory(clicked.categoryKey)
				ctx.queueRebuild()
			end),
		},
		content = content,
	}
end

local function makeListItemRow(ctx, entry, index)
	local metrics, itemData, generation = ctx.metrics(), entry and entry.data, ctx.state.generation
	local content = ui.content({
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = index % 2 == 0 and 0.18 or 0.08,
				relativeSize = v2(1, 1),
			},
		},
	})
	if itemData then
		if itemData.icon then
			content:add({
				name = "list_" .. tostring(index) .. "_icon",
				type = ui.TYPE.Image,
				props = {
					resource = ui.texture({ path = itemData.icon }),
					anchor = v2(0, 0.5),
					relativePosition = v2(0.06, 0.5),
					size = metrics.listIconSize,
				},
			})
		end
		addListStateBadges(content, "list_" .. tostring(index), itemData, metrics)
		local count = itemData.count > 1 and (" x" .. tostring(itemData.count)) or ""
		content:add(chrome.textLine(itemData.name .. count, I.MWUI.templates.textNormal, {
			anchor = v2(0, 0.5),
			relativePosition = v2(0.16, 0.5),
			relativeSize = v2(0.5, 0.72),
			textSize = 15,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}))
		content:add(chrome.textLine(tostring(itemData.value), I.MWUI.templates.textNormal, {
			anchor = v2(1, 0.5),
			relativePosition = v2(controls.LIST_FIELD_RIGHT_EDGE.value, 0.5),
			relativeSize = v2(controls.LIST_FIELD_WIDTH, controls.LIST_FIELD_HEIGHT),
			textSize = 14,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}))
		content:add(chrome.textLine(data.formatNumber(itemData.weight, 1), I.MWUI.templates.textNormal, {
			anchor = v2(1, 0.5),
			relativePosition = v2(controls.LIST_FIELD_RIGHT_EDGE.weight, 0.5),
			relativeSize = v2(controls.LIST_FIELD_WIDTH, controls.LIST_FIELD_HEIGHT),
			textSize = 14,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}))
		content:add(chrome.textLine(data.formatNumber(itemData.effectiveness, 0), I.MWUI.templates.textNormal, {
			anchor = v2(1, 0.5),
			relativePosition = v2(controls.LIST_FIELD_RIGHT_EDGE.effectiveness, 0.5),
			relativeSize = v2(controls.LIST_FIELD_WIDTH, controls.LIST_FIELD_HEIGHT),
			textSize = 14,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}))
		content:add(chrome.textLine(data.formatCondition(itemData.condition), I.MWUI.templates.textNormal, {
			anchor = v2(1, 0.5),
			relativePosition = v2(controls.LIST_FIELD_RIGHT_EDGE.condition, 0.5),
			relativeSize = v2(controls.LIST_FIELD_WIDTH, controls.LIST_FIELD_HEIGHT),
			textSize = 14,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
		}))
	end
	chrome.addSimpleBorder(content, "list_" .. tostring(index), itemData and 0.42 or 0.28, 2)
	return {
		name = "list_" .. tostring(index),
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 1 / metrics.listRows) },
		userData = itemData,
		events = itemData and {
			focusGain = ctx.async:callback(function(_, layout)
				if generation ~= ctx.state.generation then
					return
				end
				ctx.selectSlot(index, layout and layout.userData)
			end),
			mouseClick = ctx.async:callback(function(event, layout)
				if generation ~= ctx.state.generation or event.button ~= 1 then
					return
				end
				local clicked = layout and layout.userData
				if not clicked then
					return
				end
				ctx.selectSlot(index, clicked)
				actions.activateItem(clicked, ctx)
			end),
			focusLoss = ctx.async:callback(function()
				if generation ~= ctx.state.generation then
					return
				end
				ctx.clearSelection()
			end),
		} or nil,
		content = content,
	}
end

function M.makeList(entries, firstIndex, ctx)
	local metrics, rows, index = ctx.metrics(), ui.content({}), firstIndex or 1
	for slotIndex = 1, metrics.listRows do
		local entry = entries[index]
		rows:add(
			entry and entry.kind == "categoryHeader" and makeListCategoryRow(ctx, entry, slotIndex)
				or makeListItemRow(ctx, entry, slotIndex)
		)
		index = index + 1
	end
	return {
		type = ui.TYPE.Flex,
		props = { horizontal = false, size = v2(0, 0), relativeSize = v2(0, 1), autoSize = false },
		external = { grow = 1, stretch = 1 },
		content = rows,
	}
end

return M
