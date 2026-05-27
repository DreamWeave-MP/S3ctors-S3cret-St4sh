---@omw-context player

local core = require 'openmw.core'
local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local chrome = require 'scripts.s3ui.inventory.chrome'
local s3math = require 'scripts.s3.math'

local v2 = util.vector2

---@class S3UI.RepairBuilderModule
local M = {}

local PANEL_SIZE = v2(760, 560)
local PADDING = 24
local ROW_HEIGHT = 34
local ROWS_VISIBLE = 8
local BUTTON_SIZE = v2(120, 34)
local TEXT_COLOR = util.color.commaString(core.getGMST 'FontColor_color_normal')
local HOVER_COLOR = util.color.rgb(1, 0.94, 0.74)
local HIGHLIGHT_COLOR = util.color.rgb(0.86, 0.66, 0.28)
local NORMAL_ALPHA = 0.22
local HIGHLIGHT_ALPHA = 0.32
local CENTER = 0.5

local function text(value, props, template)
	return chrome.textLine(value, template or I.MWUI.templates.textNormal, props)
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
	local highlighted = ctx.hovered == name
	local content = ui.content {
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = highlighted and HIGHLIGHT_COLOR or chrome.BACKGROUND_COLOR,
				alpha = highlighted and 0.3 or 0.4,
				relativeSize = v2(1, 1),
			},
		},
		text(label, {
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			relativeSize = v2(1, 1),
			textColor = highlighted and HOVER_COLOR or TEXT_COLOR,
		}),
	}
	chrome.addSimpleBorder(content, name, highlighted and 0.95 or 0.7, 2)
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

local function itemRow(ctx, repairItem, index)
	local selected = index == ctx.selectedIndex
	local name = 's3ui_repair_item_' .. tostring(index)
	local percent = s3math.floor(repairItem.conditionPercent * 100 + 0.5)
	local content = ui.content {
		{
			name = name .. '_background',
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = selected and HIGHLIGHT_COLOR or chrome.BACKGROUND_COLOR,
				alpha = selected and HIGHLIGHT_ALPHA or NORMAL_ALPHA,
				relativeSize = v2(1, 1),
			},
		},
		text(repairItem.name, {
			position = v2(10, 0),
			size = v2(-112, 0),
			relativeSize = v2(1, 1),
			textSize = 15,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			textColor = selected and HOVER_COLOR or TEXT_COLOR,
		}),
		text(tostring(percent) .. '%', {
			anchor = v2(1, 0),
			relativePosition = v2(1, 0),
			position = v2(-10, 0),
			size = v2(92, 0),
			relativeSize = v2(0, 1),
			textSize = 15,
			textAlignH = ui.ALIGNMENT.End,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			textColor = selected and HOVER_COLOR or TEXT_COLOR,
		}),
	}
	chrome.addSimpleBorder(content, name, selected and 0.85 or 0.45, 2)
	return {
		name = name,
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 0), size = v2(0, ROW_HEIGHT) },
		events = {
			focusGain = ctx.async:callback(function()
				ctx.select(index)
			end),
			mouseClick = ctx.async:callback(function()
				ctx.select(index)
			end),
		},
		content = content,
	}
end

local function itemRows(ctx)
	local content = ui.content {}
	local first = ctx.scrollOffset + 1
	local last = s3math.min(#ctx.items, ctx.scrollOffset + ROWS_VISIBLE)
	for index = first, last do
		content:add(itemRow(ctx, ctx.items[index], index))
	end
	if #content == 0 then
		content:add(text('No damaged weapons or armor.', {
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			relativeSize = v2(1, 1),
			textColor = TEXT_COLOR,
		}))
	end
	return {
		name = 's3ui_repair_items',
		type = ui.TYPE.Flex,
		props = { horizontal = false, relativeSize = v2(1, 1), autoSize = false },
		content = content,
	}
end

function M.meterLayout(ctx)
	local strike = ctx.strike
	local marker = strike and strike.marker or 0
	local goodLeft = strike and CENTER - strike.goodHalfWidth or 0.4
	local goodWidth = strike and strike.goodHalfWidth * 2 or 0.2
	local perfectLeft = strike and CENTER - strike.perfectHalfWidth or 0.48
	local perfectWidth = strike and strike.perfectHalfWidth * 2 or 0.04
	local content = ui.content {
		{
			name = 's3ui_repair_meter_background',
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = 0.5,
				relativeSize = v2(1, 1),
			},
		},
		{
			name = 's3ui_repair_meter_good',
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = util.color.rgb(0.62, 0.48, 0.2),
				alpha = 0.75,
				relativePosition = v2(goodLeft, 0),
				relativeSize = v2(goodWidth, 1),
			},
		},
		{
			name = 's3ui_repair_meter_perfect',
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = util.color.rgb(0.95, 0.82, 0.35),
				alpha = 0.92,
				relativePosition = v2(perfectLeft, 0),
				relativeSize = v2(perfectWidth, 1),
			},
		},
		{
			name = 's3ui_repair_meter_marker',
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = HOVER_COLOR,
				alpha = 1,
				relativePosition = v2(marker, 0),
				size = v2(4, 0),
				relativeSize = v2(0, 1),
			},
		},
	}
	chrome.addSimpleBorder(content, 's3ui_repair_meter', 0.7, 2)
	return {
		name = 's3ui_repair_meter',
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 0), size = v2(0, 42) },
		content = content,
	}
end

local function meterParts(element)
	local layout = element and element.layout
	local content = layout and layout.content
	if not content then
		return nil, nil, nil
	end
	return content.s3ui_repair_meter_marker, content.s3ui_repair_meter_good, content.s3ui_repair_meter_perfect
end

function M.updateMeter(element, strike, updateBands)
	local marker, good, perfect = meterParts(element)
	if not (marker and marker.props and strike) then
		return false
	end
	marker.props.relativePosition = v2(strike.marker, 0)
	if updateBands then
		local goodLeft = CENTER - strike.goodHalfWidth
		local goodWidth = strike.goodHalfWidth * 2
		local perfectLeft = CENTER - strike.perfectHalfWidth
		local perfectWidth = strike.perfectHalfWidth * 2
		if good and good.props then
			good.props.relativePosition = v2(goodLeft, 0)
			good.props.relativeSize = v2(goodWidth, 1)
		end
		if perfect and perfect.props then
			perfect.props.relativePosition = v2(perfectLeft, 0)
			perfect.props.relativeSize = v2(perfectWidth, 1)
		end
	end
	element:update()
	return true
end

local function selectedPanel(ctx)
	local item = ctx.selectedItem
	local status = ctx.lastMessage or 'Time the marker inside the gold band, then strike.'
	if not item then
		return text('Select a damaged item to begin.', {
			textSize = 17,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			relativeSize = v2(1, 1),
		})
	end
	return {
		type = ui.TYPE.Flex,
		props = { horizontal = false, relativeSize = v2(1, 1), autoSize = false },
		content = ui.content {
			text('Selected Damage: Bent Edge', { textSize = 18, relativeSize = v2(1, 0), size = v2(0, 30) }),
			text('Recommended: Strike     Expected: +' .. tostring(ctx.expectedGain) .. ' condition', {
				textSize = 15,
				relativeSize = v2(1, 0),
				size = v2(0, 26),
				textColor = TEXT_COLOR,
			}),
			text('Condition: ' .. tostring(item.condition) .. ' / ' .. tostring(item.maxCondition), {
				textSize = 15,
				relativeSize = v2(1, 0),
				size = v2(0, 26),
				textColor = TEXT_COLOR,
			}),
			ctx.meterElement or M.meterLayout(ctx),
			text(status, {
				textSize = 16,
				textAlignH = ui.ALIGNMENT.Center,
				textAlignV = ui.ALIGNMENT.Center,
				autoSize = false,
				relativeSize = v2(1, 0),
				size = v2(0, 46),
				textColor = HOVER_COLOR,
			}),
		},
	}
end

---@param ctx table
---@return table layout
function M.make(ctx)
	local tool = ctx.tool
	local panelContent = ui.content {
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
			content = ui.content {
				text('True Temper', {
					textSize = 24,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
					autoSize = false,
					relativeSize = v2(1, 0),
					size = v2(0, 42),
				}, I.MWUI.templates.textHeader),
				text(
					'Armorer: '
						.. tostring(ctx.armorer)
						.. '     Tool: '
						.. (tool and tool.name or 'None')
						.. ' ('
						.. tostring(tool and tool.uses or 0)
						.. ' uses)',
					{
						textSize = 15,
						textAlignH = ui.ALIGNMENT.Center,
						textAlignV = ui.ALIGNMENT.Center,
						autoSize = false,
						relativeSize = v2(1, 0),
						size = v2(0, 28),
						textColor = TEXT_COLOR,
					}
				),
				{
					type = ui.TYPE.Flex,
					props = { horizontal = true, relativeSize = v2(1, 1), autoSize = false },
					content = ui.content {
						{
							type = ui.TYPE.Widget,
							props = { relativeSize = v2(0.46, 1) },
							content = ui.content { itemRows(ctx) },
						},
						{
							type = ui.TYPE.Widget,
							props = { relativeSize = v2(0.54, 1), position = v2(18, 0), size = v2(-18, 0) },
							content = ui.content { selectedPanel(ctx) },
						},
					},
				},
				{
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
						relativeSize = v2(1, 0),
						size = v2(0, 42),
						arrange = ui.ALIGNMENT.Center,
					},
					content = ui.content {
						button(ctx, 's3ui_repair_strike', 'Strike', ctx.strikeNow),
						button(ctx, 's3ui_repair_stop', 'Stop', ctx.cancel),
					},
				},
			},
		},
	}
	chrome.addOrnateFrame(panelContent, 's3ui_repair', chrome.FRAME_SIZE_MEDIUM, 1)
	return {
		name = 's3ui_repair_root',
		type = ui.TYPE.Widget,
		layer = 'Windows',
		props = { relativeSize = v2(1, 1) },
		content = ui.content {
			{
				name = 's3ui_repair_panel',
				type = ui.TYPE.Widget,
				props = { anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5), size = PANEL_SIZE },
				content = panelContent,
			},
		},
	}
end

M.ROWS_VISIBLE = ROWS_VISIBLE

return M
