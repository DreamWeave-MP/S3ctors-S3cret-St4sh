---@omw-context player

local I = require 'openmw.interfaces'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local chrome = require 'scripts.s3ui.inventory.chrome'

local v2 = util.vector2

---@class S3UI.CountModalLayoutModule
local M = {}

local ROOT_LAYER = 'Windows'
local PANEL_SIZE = v2(420, 230)
local SLIDER_SIZE = v2(240, 24)
local COUNT_DISPLAY_SIZE = v2(148, 34)
local COUNT_INPUT_SIZE = v2(58, 30)
local COUNT_LABEL_SIZE = v2(64, 30)
local ARROW_BUTTON_SIZE = v2(44, 34)
local ACTION_BUTTON_SIZE = v2(92, 34)
local BUTTON_ALPHA = { fill = 0.42, border = 0.72 }
local INPUT_ALPHA = { fill = 0.34, border = 0.76 }

local function modalText(text, props, template)
	return chrome.textLine(text, template or I.MWUI.templates.textNormal, props)
end

local function dragEvents(ctx, name, trackWidth, callbackGeneration)
	return {
		mousePress = ctx.async:callback(function(event)
			if not ctx.isAlive(callbackGeneration) or not event or event.button ~= 1 then
				return
			end
			ctx.beginDrag(name)
			ctx.setValueFromTrack(event.offset.x, trackWidth)
		end),
		mouseMove = ctx.async:callback(function(event)
			if not ctx.isAlive(callbackGeneration) or not ctx.isDragging(name) or not event then
				return
			end
			ctx.setValueFromTrack(event.offset.x, trackWidth)
		end),
		mouseRelease = ctx.async:callback(function()
			if ctx.isAlive(callbackGeneration) and ctx.isDragging(name) then
				ctx.endDrag()
			end
		end),
		focusLoss = ctx.async:callback(function()
			if ctx.isAlive(callbackGeneration) and ctx.isDragging(name) then
				ctx.endDrag()
			end
		end),
	}
end

local function modalButton(ctx, name, label, callback, callbackGeneration, size, textHover)
	local content = ui.content {
		{
			name = name .. '_background',
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = BUTTON_ALPHA.fill,
				relativeSize = v2(1, 1),
			},
		},
		modalText(label, {
			name = name .. '_label',
			textSize = 16,
			textColor = textHover and ctx.hoverTextColor(name) or nil,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			relativeSize = v2(1, 1),
		}),
	}
	chrome.addSimpleBorder(content, name, BUTTON_ALPHA.border, 2)
	local events = {
		mouseClick = ctx.async:callback(function()
			if ctx.isAlive(callbackGeneration) then
				callback()
			end
		end),
	}
	if textHover then
		events.focusGain = ctx.async:callback(function()
			ctx.setHoveredControl(name, true, callbackGeneration)
		end)
		events.focusLoss = ctx.async:callback(function()
			ctx.setHoveredControl(name, false, callbackGeneration)
		end)
	end
	return {
		name = name,
		type = ui.TYPE.Widget,
		props = { size = size or ACTION_BUTTON_SIZE },
		events = events,
		content = content,
	}
end

local function countInput(ctx, callbackGeneration)
	local content = ui.content {
		{
			name = 's3ui_count_input_frame_background',
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = INPUT_ALPHA.fill,
				relativeSize = v2(1, 1),
			},
		},
		{
			type = ui.TYPE.TextEdit,
			name = 's3ui_count_input',
			template = I.MWUI.templates.textEditLine,
			props = {
				text = ctx.inputText,
				position = v2(13, 2),
				size = COUNT_INPUT_SIZE,
				autoSize = false,
				textColor = ctx.hoverTextColor 's3ui_count_input',
				multiline = false,
				textSize = 16,
				textAlignH = ui.ALIGNMENT.End,
				textAlignV = ui.ALIGNMENT.Center,
			},
			events = {
				focusGain = ctx.async:callback(function(_, layout)
					ctx.setTextEditFocused(layout, true, callbackGeneration)
				end),
				textChanged = ctx.async:callback(function(text)
					if ctx.isAlive(callbackGeneration) then
						ctx.setInputText(text or '')
					end
				end),
				focusLoss = ctx.async:callback(function(_, layout)
					if ctx.isAlive(callbackGeneration) then
						ctx.commitInputText()
					end
					ctx.setTextEditFocused(layout, false, callbackGeneration)
				end),
			},
		},
		modalText('/ ' .. tostring(ctx.maxValue), {
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			position = v2(77, 2),
			size = COUNT_LABEL_SIZE,
		}),
	}
	chrome.addSimpleBorder(content, 's3ui_count_input_frame', INPUT_ALPHA.border, 1)
	return {
		name = 's3ui_count_input_frame',
		type = ui.TYPE.Widget,
		props = { anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5), size = COUNT_DISPLAY_SIZE },
		events = dragEvents(ctx, 'count_input', COUNT_DISPLAY_SIZE.x, callbackGeneration),
		content = content,
	}
end

local function makeSlider(ctx, callbackGeneration)
	local knobX = math.floor(SLIDER_SIZE.x * ctx.sliderRatio())
	local content = ui.content {
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = 0.36,
				relativeSize = v2(1, 1),
			},
		},
		{
			type = ui.TYPE.Image,
			props = { resource = chrome.WHITE_TEXTURE, alpha = 0.72, size = v2(knobX, 0), relativeSize = v2(0, 1) },
		},
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				anchor = v2(0.5, 0.5),
				position = v2(knobX, 0),
				relativePosition = v2(0, 0.5),
				size = v2(14, 34),
				alpha = 0.95,
			},
		},
	}
	chrome.addSimpleBorder(content, 's3ui_count_slider', 0.82, 2)
	return {
		name = 's3ui_count_slider',
		type = ui.TYPE.Widget,
		props = { size = SLIDER_SIZE },
		events = dragEvents(ctx, 'slider', SLIDER_SIZE.x, callbackGeneration),
		content = content,
	}
end

local function arrowButton(ctx, name, label, delta, callbackGeneration)
	return modalButton(ctx, name, label, function()
		ctx.setValue(ctx.value + delta)
	end, callbackGeneration, ARROW_BUTTON_SIZE, true)
end

---@param ctx S3UI.CountModalLayoutContext
---@return table layout
function M.make(ctx)
	local callbackGeneration = ctx.generation
	local panelContent = ui.content {
		{
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = chrome.backgroundAlpha(),
				relativeSize = v2(1, 1),
			},
		},
		{
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				position = v2(24, 20),
				size = v2(-48, -40),
				relativeSize = v2(1, 1),
				autoSize = false,
			},
			content = ui.content {
				modalText(ctx.title, {
					textSize = 20,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
					autoSize = false,
					relativeSize = v2(1, 0.2),
				}, I.MWUI.templates.textHeader),
				{
					type = ui.TYPE.Widget,
					props = { relativeSize = v2(1, 0.18) },
					content = ui.content { countInput(ctx, callbackGeneration) },
				},
				{
					type = ui.TYPE.Flex,
					props = { horizontal = true, relativeSize = v2(1, 0.25), arrange = ui.ALIGNMENT.Center },
					content = ui.content {
						arrowButton(ctx, 's3ui_count_left', '<', -1, callbackGeneration),
						makeSlider(ctx, callbackGeneration),
						arrowButton(ctx, 's3ui_count_right', '>', 1, callbackGeneration),
					},
				},
				{
					type = ui.TYPE.Flex,
					props = { horizontal = true, relativeSize = v2(1, 0.23), arrange = ui.ALIGNMENT.Center },
					content = ui.content {
						modalButton(ctx, 's3ui_count_ok', 'OK', ctx.confirm, callbackGeneration, nil, true),
						modalButton(ctx, 's3ui_count_cancel', 'Cancel', ctx.cancel, callbackGeneration, nil, true),
					},
				},
			},
		},
	}
	chrome.addOrnateFrame(panelContent, 's3ui_count_modal', chrome.FRAME_SIZE_MEDIUM, 1)
	return {
		type = ui.TYPE.Widget,
		layer = ROOT_LAYER,
		props = { relativeSize = v2(1, 1) },
		content = ui.content {
			{
				type = ui.TYPE.Image,
				props = {
					resource = chrome.WHITE_TEXTURE,
					color = chrome.BACKGROUND_COLOR,
					alpha = 0.48,
					relativeSize = v2(1, 1),
				},
			},
			{
				name = 's3ui_count_panel',
				type = ui.TYPE.Widget,
				props = { anchor = v2(0.5, 0.5), relativePosition = v2(0.5, 0.5), size = PANEL_SIZE },
				content = panelContent,
			},
		},
	}
end

return M
