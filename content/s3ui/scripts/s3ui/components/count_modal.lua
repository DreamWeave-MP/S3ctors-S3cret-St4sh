---@omw-context player

local async = require("openmw.async")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")
local util = require("openmw.util")
local chrome = require("scripts.s3ui.inventory.chrome")

local v2 = util.vector2

local M = {}

local ROOT_LAYER = "Windows"
local PANEL_SIZE = v2(420, 230)
local SLIDER_SIZE = v2(240, 24)
local COUNT_DISPLAY_SIZE = v2(148, 34)
local COUNT_INPUT_SIZE = v2(58, 30)
local COUNT_LABEL_SIZE = v2(64, 30)
local ARROW_BUTTON_SIZE = v2(44, 34)
local ACTION_BUTTON_SIZE = v2(92, 34)
local MIN_COUNT = 1
local BUTTON_ALPHA = { fill = 0.42, border = 0.72 }
local INPUT_ALPHA = { fill = 0.34, border = 0.76 }
local HOVER_TEXT_COLOR = util.color.rgb(1, 0.94, 0.74)

local rootElement = nil
local value = 1
local minValue = 1
local maxValue = 1
local inputText = "1"
local title = "Select Count"
local dragging = false
local closed = true
local hoveredControl = nil
local generation = 0
local onOk = nil
local onCancel = nil

local function hoverTextColor(name)
	if hoveredControl == name then
		return HOVER_TEXT_COLOR
	end
	return nil
end

local function setHoveredControl(name, hovering, callbackGeneration)
	if not (not closed and callbackGeneration == generation and rootElement and rootElement.layout) then
		return
	end
	local nextHovered = hovering and name or hoveredControl
	if not hovering and hoveredControl == name then
		nextHovered = nil
	end
	if hoveredControl == nextHovered then
		return
	end
	hoveredControl = nextHovered
	rootElement.layout = M.layout()
	rootElement:update()
end

local function clampInteger(nextValue)
	nextValue = math.floor(tonumber(nextValue) or minValue)
	if nextValue < minValue then
		return minValue
	end
	if nextValue > maxValue then
		return maxValue
	end
	return nextValue
end

local function parseInputText()
	if inputText == "" then
		return value
	end
	return clampInteger(inputText)
end

local function isAlive(callbackGeneration)
	return not closed and callbackGeneration == generation and rootElement and rootElement.layout
end

local function updateRoot()
	if rootElement and rootElement.layout then
		rootElement.layout = M.layout()
		rootElement:update()
	end
end

local function setValue(nextValue, skipUpdate)
	local clamped = clampInteger(nextValue)
	if clamped == value and inputText == tostring(clamped) then
		return
	end
	value = clamped
	inputText = tostring(value)
	if not skipUpdate then
		updateRoot()
	end
end

local function sliderRatio()
	if maxValue <= minValue then
		return 1
	end
	return (value - minValue) / (maxValue - minValue)
end

local function setValueFromSlider(offsetX)
	local ratio = offsetX / SLIDER_SIZE.x
	if ratio < 0 then
		ratio = 0
	elseif ratio > 1 then
		ratio = 1
	end
	setValue(minValue + math.floor((maxValue - minValue) * ratio + 0.5), true)
end

local function closeWithoutCallback()
	closed = true
	dragging = false
	hoveredControl = nil
	generation = generation + 1
	onOk = nil
	onCancel = nil
	if rootElement and rootElement.layout then
		rootElement:destroy()
	end
	rootElement = nil
end

local function confirm()
	if closed then
		return
	end
	local callback = onOk
	local selected = parseInputText()
	closeWithoutCallback()
	if callback then
		callback(selected)
	end
end

local function cancel()
	if closed then
		return
	end
	local callback = onCancel
	closeWithoutCallback()
	if callback then
		callback()
	end
end

local function modalText(text, props, template)
	return chrome.textLine(text, template or I.MWUI.templates.textNormal, props)
end

local function modalButton(name, label, callback, callbackGeneration, size, textHover)
	local content = ui.content({
		{
			name = name .. "_background",
			type = ui.TYPE.Image,
			props = {
				resource = chrome.WHITE_TEXTURE,
				color = chrome.BACKGROUND_COLOR,
				alpha = BUTTON_ALPHA.fill,
				relativeSize = v2(1, 1),
			},
		},
		modalText(label, {
			name = name .. "_label",
			textSize = 16,
			textColor = textHover and hoverTextColor(name) or nil,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			relativeSize = v2(1, 1),
		}),
	})
	chrome.addSimpleBorder(content, name, BUTTON_ALPHA.border, 2)
	local events = {
		mouseClick = async:callback(function()
			if not isAlive(callbackGeneration) then
				return
			end
			callback()
		end),
	}
	if textHover then
		events.focusGain = async:callback(function()
			setHoveredControl(name, true, callbackGeneration)
		end)
		events.focusLoss = async:callback(function()
			setHoveredControl(name, false, callbackGeneration)
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

local function countInput(callbackGeneration)
	local content = ui.content({
		{
			name = "s3ui_count_input_frame_background",
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
			name = "s3ui_count_input",
			template = I.MWUI.templates.textEditLine,
			props = {
				text = inputText,
				position = v2(13, 2),
				size = COUNT_INPUT_SIZE,
				autoSize = false,
				textColor = hoverTextColor("s3ui_count_input"),
				multiline = false,
				textSize = 16,
				textAlignH = ui.ALIGNMENT.End,
				textAlignV = ui.ALIGNMENT.Center,
			},
			events = {
				focusGain = async:callback(function()
					setHoveredControl("s3ui_count_input", true, callbackGeneration)
				end),
				textChanged = async:callback(function(text)
					if isAlive(callbackGeneration) then
						inputText = text or ""
					end
				end),
				focusLoss = async:callback(function()
					if isAlive(callbackGeneration) then
						value = parseInputText()
						inputText = tostring(value)
					end
					setHoveredControl("s3ui_count_input", false, callbackGeneration)
				end),
			},
		},
		modalText("/ " .. tostring(maxValue), {
			textSize = 16,
			textAlignH = ui.ALIGNMENT.Start,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			position = v2(77, 2),
			size = COUNT_LABEL_SIZE,
		}),
	})
	chrome.addSimpleBorder(content, "s3ui_count_input_frame", INPUT_ALPHA.border, 1)
	return {
		name = "s3ui_count_input_frame",
		type = ui.TYPE.Widget,
		props = {
			anchor = v2(0.5, 0.5),
			relativePosition = v2(0.5, 0.5),
			size = COUNT_DISPLAY_SIZE,
		},
		content = content,
	}
end

local function makeSlider(callbackGeneration)
	local ratio = sliderRatio()
	local knobX = math.floor(SLIDER_SIZE.x * ratio)
	local content = ui.content({
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
			props = {
				resource = chrome.WHITE_TEXTURE,
				alpha = 0.72,
				size = v2(knobX, 0),
				relativeSize = v2(0, 1),
			},
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
	})
	chrome.addSimpleBorder(content, "s3ui_count_slider", 0.82, 2)
	return {
		name = "s3ui_count_slider",
		type = ui.TYPE.Widget,
		props = { size = SLIDER_SIZE },
		events = {
			mousePress = async:callback(function(event)
				if not isAlive(callbackGeneration) or not event or event.button ~= 1 then
					return
				end
				dragging = true
				setValueFromSlider(event.offset.x)
			end),
			mouseMove = async:callback(function(event)
				if not isAlive(callbackGeneration) or not dragging or not event then
					return
				end
				setValueFromSlider(event.offset.x)
			end),
			mouseRelease = async:callback(function()
				dragging = false
				updateRoot()
			end),
			focusLoss = async:callback(function()
				dragging = false
				updateRoot()
			end),
		},
		content = content,
	}
end

local function arrowButton(name, label, delta, callbackGeneration)
	return modalButton(name, label, function()
		setValue(value + delta)
	end, callbackGeneration, ARROW_BUTTON_SIZE)
end

function M.layout()
	local callbackGeneration = generation
	local panelContent = ui.content({
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
			content = ui.content({
				modalText(title, {
					textSize = 20,
					textAlignH = ui.ALIGNMENT.Center,
					textAlignV = ui.ALIGNMENT.Center,
					autoSize = false,
					relativeSize = v2(1, 0.2),
				}, I.MWUI.templates.textHeader),
				{
					type = ui.TYPE.Widget,
					props = { relativeSize = v2(1, 0.18) },
					content = ui.content({
						countInput(callbackGeneration),
					}),
				},
				{
					type = ui.TYPE.Flex,
					props = { horizontal = true, relativeSize = v2(1, 0.25), arrange = ui.ALIGNMENT.Center },
					content = ui.content({
						arrowButton("s3ui_count_left", "<", -1, callbackGeneration),
						makeSlider(callbackGeneration),
						arrowButton("s3ui_count_right", ">", 1, callbackGeneration),
					}),
				},
				{
					type = ui.TYPE.Flex,
					props = { horizontal = true, relativeSize = v2(1, 0.23), arrange = ui.ALIGNMENT.Center },
					content = ui.content({
						modalButton("s3ui_count_ok", "OK", confirm, callbackGeneration, nil, true),
						modalButton("s3ui_count_cancel", "Cancel", cancel, callbackGeneration, nil, true),
					}),
				},
			}),
		},
	})
	chrome.addOrnateFrame(panelContent, "s3ui_count_modal", chrome.FRAME_SIZE_MEDIUM, 1)
	local content = ui.content({
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
			name = "s3ui_count_panel",
			type = ui.TYPE.Widget,
			props = {
				anchor = v2(0.5, 0.5),
				relativePosition = v2(0.5, 0.5),
				size = PANEL_SIZE,
			},
			content = panelContent,
		},
	})
	return {
		type = ui.TYPE.Widget,
		layer = ROOT_LAYER,
		props = { relativeSize = v2(1, 1) },
		content = content,
	}
end

function M.show(opts)
	opts = opts or {}
	closeWithoutCallback()
	minValue = math.floor(tonumber(opts.min) or MIN_COUNT)
	if minValue < MIN_COUNT then
		minValue = MIN_COUNT
	end
	maxValue = math.floor(tonumber(opts.max) or minValue)
	if maxValue < minValue then
		maxValue = minValue
	end
	value = clampInteger(opts.initial or maxValue)
	inputText = tostring(value)
	title = opts.title or "Select Count"
	onOk = opts.onOk
	onCancel = opts.onCancel
	dragging = false
	closed = false
	generation = generation + 1
	rootElement = ui.create(M.layout())
end

function M.hide()
	closeWithoutCallback()
end

function M.isOpen()
	return not closed and rootElement ~= nil and rootElement.layout ~= nil
end

function M.handleKeyPress(key)
	if not M.isOpen() then
		return false
	end
	if key.code == input.KEY.LeftArrow then
		setValue(value - 1)
		return true
	elseif key.code == input.KEY.RightArrow then
		setValue(value + 1)
		return true
	elseif key.code == input.KEY.Enter or key.code == input.KEY.NP_Enter then
		confirm()
		return true
	elseif key.code == input.KEY.Escape then
		cancel()
		return true
	end
	return true
end

return M
