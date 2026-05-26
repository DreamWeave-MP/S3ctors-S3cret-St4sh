---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")
local icons = require("scripts.s3ui.inventory.icons")

local v2 = util.vector2
local LIST_FIELD_WIDTH = 0.12
local LIST_FIELD_RIGHT_EDGE = { value = 0.68, weight = 0.8, effectiveness = 0.9, condition = 0.99 }

local M = {}

local function controlBackground(active)
	return {
		type = ui.TYPE.Image,
		props = {
			resource = chrome.WHITE_TEXTURE,
			color = active and icons.CATEGORY_ACTIVE_COLOR or icons.CATEGORY_COLLAPSED_COLOR,
			alpha = active and 0.55 or 0.25,
			position = v2(chrome.SIMPLE_BORDER_THICKNESS, chrome.SIMPLE_BORDER_THICKNESS),
			size = v2(-chrome.SIMPLE_BORDER_THICKNESS * 2, -chrome.SIMPLE_BORDER_THICKNESS * 2),
			relativeSize = v2(1, 1),
		},
	}
end

local function controlText(name, text, textSize)
	return {
		name = name,
		template = I.MWUI.templates.textNormal,
		props = chrome.textProps(text, {
			relativeSize = v2(1, 1),
			textSize = textSize or 14,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			multiline = true,
			wordWrap = true,
			autoSize = false,
		}),
	}
end

local function sortDirectionIcon(name, icon)
	return {
		name = name,
		type = ui.TYPE.Image,
		props = {
			resource = icon,
			anchor = v2(1, 1),
			relativePosition = v2(0.92, 0.92),
			relativeSize = icons.SORT_DIRECTION_RELATIVE_SIZE,
			alpha = 0.95,
		},
	}
end

local function listFieldCenter(mode)
	return (LIST_FIELD_RIGHT_EDGE[mode] or 0.5) - LIST_FIELD_WIDTH * 0.5
end

local function makeSortButton(ctx, mode)
	local state, active = ctx.state, ctx.state.sortMode == mode
	local directionKey = state.sortAscending[mode] and "ascending" or "descending"
	local name, generation = "s3ui_sort_" .. mode, state.generation
	local content = ui.content({
		{
			name = name .. "_icon",
			type = ui.TYPE.Image,
			props = {
				resource = icons.SORT[mode],
				anchor = v2(0.5, 0.5),
				relativePosition = v2(0.5, 0.5),
				relativeSize = icons.SORT_ICON_RELATIVE_SIZE,
				alpha = active and 1 or 0.82,
			},
		},
	})
	if active then
		content:add(sortDirectionIcon(name .. "_direction", icons.SORT_DIRECTION[directionKey]))
	end
	return {
		name = name,
		type = ui.TYPE.Widget,
		props = { size = ctx.metrics().controlButtonSize },
		events = {
			focusGain = ctx.async:callback(ctx.clearSelection),
			mouseClick = ctx.async:callback(function()
				if generation ~= state.generation then
					return
				end
				ctx.clearSelection()
				state:activateSort(mode)
				ctx.queueRebuild()
			end),
		},
		content = content,
	}
end

local function makeToolbarSortButton(ctx, mode)
	local button = makeSortButton(ctx, mode)
	button.props.anchor = v2(0.5, 0.5)
	button.props.relativePosition = v2(listFieldCenter(mode), 0.5)
	return button
end

local function glyphRect(name, position, size)
	return {
		name = name,
		type = ui.TYPE.Image,
		props = {
			resource = chrome.WHITE_TEXTURE,
			color = icons.VIEW_GLYPH_COLOR,
			alpha = 0.95,
			anchor = v2(0.5, 0.5),
			relativePosition = position,
			relativeSize = size,
		},
	}
end

local function makeViewGlyph(viewMode)
	local glyph = ui.content({})
	if viewMode == "list" then
		glyph:add(glyphRect("s3ui_view_list_bar_1", v2(0.5, 0.41), v2(0.28, 0.045)))
		glyph:add(glyphRect("s3ui_view_list_bar_2", v2(0.5, 0.5), v2(0.28, 0.045)))
		glyph:add(glyphRect("s3ui_view_list_bar_3", v2(0.5, 0.59), v2(0.28, 0.045)))
	else
		glyph:add(glyphRect("s3ui_view_grid_dot_1", v2(0.45, 0.45), v2(0.075, 0.075)))
		glyph:add(glyphRect("s3ui_view_grid_dot_2", v2(0.55, 0.45), v2(0.075, 0.075)))
		glyph:add(glyphRect("s3ui_view_grid_dot_3", v2(0.45, 0.55), v2(0.075, 0.075)))
		glyph:add(glyphRect("s3ui_view_grid_dot_4", v2(0.55, 0.55), v2(0.075, 0.075)))
	end
	return glyph
end

local function makeToolbarViewToggleButton(ctx)
	local generation, state = ctx.state.generation, ctx.state
	return {
		name = "s3ui_view_toggle",
		type = ui.TYPE.Widget,
		props = { size = ctx.metrics().viewButtonSize },
		events = {
			focusGain = ctx.async:callback(ctx.clearSelection),
			mouseClick = ctx.async:callback(function()
				if generation ~= state.generation then
					return
				end
				ctx.clearSelection()
				state:toggleViewMode()
				ctx.queueRebuild()
			end),
		},
		content = ui.content({
			{
				name = "s3ui_view_toggle_icon",
				type = ui.TYPE.Image,
				props = {
					resource = icons.VIEW_TOGGLE,
					anchor = v2(0.5, 0.5),
					relativePosition = v2(0.5, 0.5),
					relativeSize = icons.VIEW_TOGGLE_ICON_SIZE,
					alpha = 0.95,
				},
			},
			{
				name = "s3ui_view_toggle_glyph",
				type = ui.TYPE.Widget,
				props = { relativeSize = v2(1, 1) },
				content = makeViewGlyph(state.viewMode),
			},
		}),
	}
end

local function toolbarModeIcon(ctx)
	if ctx.state.primaryTab == "equipment" then
		return icons.SORT.weight, icons.SORT_ICON_RELATIVE_SIZE, "inventory"
	end
	return icons.MENU.equipment, icons.SORT_ICON_RELATIVE_SIZE, "equipment"
end

local function makeToolbarModeToggleButton(ctx)
	local generation, state = ctx.state.generation, ctx.state
	local icon, iconSize, targetTab = toolbarModeIcon(ctx)
	return {
		name = "s3ui_inventory_mode_toggle",
		type = ui.TYPE.Widget,
		props = { size = ctx.metrics().viewButtonSize },
		events = {
			focusGain = ctx.async:callback(ctx.clearSelection),
			mouseClick = ctx.async:callback(function()
				if generation ~= state.generation then
					return
				end
				ctx.clearSelection()
				if state:setPrimaryTab(targetTab) then
					ctx.queueRebuild()
				end
			end),
		},
		content = ui.content({
			{
				name = "s3ui_inventory_mode_toggle_icon",
				type = ui.TYPE.Image,
				props = {
					resource = icon,
					anchor = v2(0.5, 0.5),
					relativePosition = v2(0.5, 0.5),
					relativeSize = iconSize,
					alpha = 0.95,
				},
			},
		}),
	}
end

local function makeToolbarButtonRow(ctx)
	local content = ui.content({})
	if ctx.state.primaryTab == "inventory" then
		content:add(makeToolbarViewToggleButton(ctx))
	else
		content:add({
			name = "s3ui_view_toggle_reserved",
			type = ui.TYPE.Widget,
			props = { size = ctx.metrics().viewButtonSize },
		})
	end
	content:add(makeToolbarModeToggleButton(ctx))
	return {
		name = "s3ui_toolbar_button_row",
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			relativeSize = v2(1, 1),
			arrange = ui.ALIGNMENT.Center,
			autoSize = false,
		},
		content = content,
	}
end

local function mainMenuActive(ctx, button)
	if button.tab == "inventory" and ctx.state.primaryTab == "equipment" then
		return true
	end
	return button.tab ~= nil and button.tab == ctx.state.primaryTab
end

local function menuButtonIconSize(metrics, buttonCount)
	local buttonHeight = metrics.viewSize.y / buttonCount
	local edge = math.floor(math.min(metrics.categoryRailSize.x, buttonHeight) * 0.72)
	if edge < 32 then
		edge = 32
	end
	return v2(edge, edge)
end

local function makeMainMenuButton(ctx, button)
	local active, buttonCount = mainMenuActive(ctx, button), #icons.MAIN_MENU_BUTTONS
	local generation, state = ctx.state.generation, ctx.state
	local content = ui.content({
		controlBackground(active),
		{
			name = "s3ui_main_menu_" .. button.key .. "_icon",
			type = ui.TYPE.Image,
			props = {
				resource = button.icon,
				anchor = v2(0.5, 0.5),
				relativePosition = v2(0.5, 0.5),
				size = menuButtonIconSize(ctx.metrics(), buttonCount),
				alpha = active and 1 or 0.72,
			},
		},
	})
	chrome.addSimpleBorder(content, "s3ui_main_menu_" .. button.key, active and 0.9 or 0.62, 2)
	return {
		name = "s3ui_main_menu_" .. button.key,
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 1 / buttonCount) },
		events = {
			focusGain = ctx.async:callback(ctx.clearSelection),
			mouseClick = ctx.async:callback(function()
				if generation ~= state.generation then
					return
				end
				ctx.clearSelection()
				if button.tab and state:setPrimaryTab(button.tab) then
					ctx.queueRebuild()
				end
			end),
		},
		content = content,
	}
end

function M.makeCategoryRail(ctx)
	local buttons = ui.content({})
	for _, button in ipairs(icons.MAIN_MENU_BUTTONS) do
		buttons:add(makeMainMenuButton(ctx, button))
	end
	return {
		name = "s3ui_category_rail",
		type = ui.TYPE.Flex,
		props = { horizontal = false, size = ctx.metrics().categoryRailSize, autoSize = false },
		external = { stretch = 1 },
		content = buttons,
	}
end

function M.makeToolbar(ctx)
	local metrics = ctx.metrics()
	return {
		name = "s3ui_toolbar",
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			relativeSize = metrics.toolbarRelativeSize,
			arrange = ui.ALIGNMENT.Center,
			autoSize = false,
		},
		content = ui.content({
			{
				name = "s3ui_toolbar_rail_area",
				type = ui.TYPE.Widget,
				props = { size = v2(metrics.categoryRailSize.x, 0) },
				external = { stretch = 1 },
				content = ui.content({ makeToolbarButtonRow(ctx) }),
			},
			{
				name = "s3ui_toolbar_field_area",
				type = ui.TYPE.Widget,
				props = { size = v2(0, 0), relativeSize = v2(0, 1) },
				external = { grow = 1, stretch = 1 },
				content = ctx.state.primaryTab == "inventory" and ui.content({
					makeToolbarSortButton(ctx, "value"),
					makeToolbarSortButton(ctx, "weight"),
					makeToolbarSortButton(ctx, "effectiveness"),
					makeToolbarSortButton(ctx, "condition"),
				}) or ui.content({}),
			},
		}),
	}
end

M.controlText = controlText
M.LIST_FIELD_RIGHT_EDGE = LIST_FIELD_RIGHT_EDGE
M.LIST_FIELD_WIDTH = LIST_FIELD_WIDTH
M.LIST_FIELD_HEIGHT = 0.72

return M
