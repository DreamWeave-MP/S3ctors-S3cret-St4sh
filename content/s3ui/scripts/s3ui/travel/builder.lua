---@omw-context player

local I = require("openmw.interfaces")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")

local v2 = util.vector2

local M = {}

local PANEL_SIZE = v2(520, 430)
local PADDING = 24
local ROW_HEIGHT = 36
local BUTTON_SIZE = v2(104, 34)
local ROWS_VISIBLE = 8
local HOVER_COLOR = util.color.rgb(1, 0.94, 0.74)
local DISABLED_COLOR = util.color.rgb(0.55, 0.52, 0.48)
local SELECTED_ALPHA = 0.48
local NORMAL_ALPHA = 0.25

local function text(text, props, template)
	return chrome.textLine(text, template or I.MWUI.templates.textNormal, props)
end

local function panelBackground()
	return {
		type = ui.TYPE.Image,
		props = {
			resource = chrome.WHITE_TEXTURE,
			color = chrome.BACKGROUND_COLOR,
			alpha = chrome.backgroundAlpha(),
			relativeSize = v2(1, 1),
		},
	}
end

local function button(ctx, name, label, callback)
	local content = ui.content({
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = 0.38,
				relativeSize = v2(1, 1),
			},
		},
		text(label, {
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			relativeSize = v2(1, 1),
			textColor = ctx.hovered == name and HOVER_COLOR or nil,
		}),
	})
	chrome.addSimpleBorder(content, name, 0.78, 2)
	return {
		name = name,
		type = ui.TYPE.Widget,
		props = { size = BUTTON_SIZE },
		events = {
			focusGain = ctx.async:callback(function()
				ctx.setHovered(name)
			end),
			focusLoss = ctx.async:callback(function()
				ctx.clearHovered(name)
			end),
			mouseClick = ctx.async:callback(callback),
		},
		content = content,
	}
end

local function destinationRow(ctx, row, visualIndex)
	local selected = ctx.selectedIndex == row.index
	local enabled = row.enabled ~= false
	local name = "s3ui_travel_destination_" .. tostring(row.index)
	local content = ui.content({
		{
			name = name .. "_background",
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = selected and SELECTED_ALPHA or NORMAL_ALPHA,
				relativeSize = v2(1, 1),
			},
		},
		text(row.label, {
			position = v2(12, 0),
			size = v2(-116, 0),
			relativeSize = v2(1, 1),
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			textColor = enabled and nil or DISABLED_COLOR,
		}),
		text(tostring(row.price) .. " gp", {
			anchor = v2(1, 0),
			relativePosition = v2(1, 0),
			position = v2(-12, 0),
			size = v2(100, 0),
			relativeSize = v2(0, 1),
			textSize = 16,
			textAlignH = ui.ALIGNMENT.End,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			textColor = enabled and nil or DISABLED_COLOR,
		}),
	})
	chrome.addSimpleBorder(content, name, selected and 0.9 or 0.5, 2)
	return {
		name = name,
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 0), size = v2(0, ROW_HEIGHT) },
		events = {
			focusGain = ctx.async:callback(function()
				ctx.select(row.index)
			end),
			mouseClick = ctx.async:callback(function()
				ctx.activate(row.index)
			end),
		},
		content = content,
	}
end

local function destinationRows(ctx)
	local content = ui.content({})
	local first = ctx.scrollOffset + 1
	local last = math.min(#ctx.rows, ctx.scrollOffset + ROWS_VISIBLE)
	for visualIndex = first, last do
		content:add(destinationRow(ctx, ctx.rows[visualIndex], visualIndex - first + 1))
	end
	return {
		name = "s3ui_travel_destinations",
		type = ui.TYPE.Flex,
		props = { horizontal = false, relativeSize = v2(1, 1), autoSize = false },
		content = content,
	}
end

local function statusText(ctx)
	if #ctx.rows == 0 then
		return "No destinations available."
	end
	if #ctx.rows <= ROWS_VISIBLE then
		return ""
	end
	return tostring(ctx.scrollOffset + 1)
		.. "-"
		.. tostring(math.min(#ctx.rows, ctx.scrollOffset + ROWS_VISIBLE))
		.. " / "
		.. tostring(#ctx.rows)
end

function M.make(ctx)
	local panelContent = ui.content({
		panelBackground(),
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				position = v2(PADDING, 20),
				size = v2(-PADDING * 2, -40),
				relativeSize = v2(1, 1),
				autoSize = false,
			},
			content = ui.content({
				text("Travel", {
					textSize = 22,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
					autoSize = false,
					relativeSize = v2(1, 0),
					size = v2(0, 42),
				}, I.MWUI.templates.textHeader),
				text(ctx.serviceName, {
					textSize = 16,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
					autoSize = false,
					relativeSize = v2(1, 0),
					size = v2(0, 28),
				}),
				destinationRows(ctx),
				text("Gold: " .. tostring(ctx.playerGold) .. "     " .. statusText(ctx), {
					textSize = 15,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
					autoSize = false,
					relativeSize = v2(1, 0),
					size = v2(0, 30),
				}),
				{
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
						relativeSize = v2(1, 0),
						size = v2(0, 42),
						arrange = ui.ALIGNMENT.Center,
					},
					content = ui.content({
						button(ctx, "s3ui_travel_confirm", "Travel", ctx.confirm),
						button(ctx, "s3ui_travel_cancel", "Cancel", ctx.cancel),
					}),
				},
			}),
		},
	})
	chrome.addOrnateFrame(panelContent, "s3ui_travel", chrome.FRAME_SIZE_MEDIUM, 1)
	return {
		name = "s3ui_travel_root",
		type = ui.TYPE.Widget,
		layer = "Windows",
		props = { relativeSize = v2(1, 1) },
		content = ui.content({
			{
				name = "s3ui_travel_panel",
				type = ui.TYPE.Widget,
				props = {
					anchor = v2(0.5, 0.5),
					relativePosition = v2(0.5, 0.5),
					size = PANEL_SIZE,
				},
				content = panelContent,
			},
		}),
	}
end

M.ROWS_VISIBLE = ROWS_VISIBLE

return M
