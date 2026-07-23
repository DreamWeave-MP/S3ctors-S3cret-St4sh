---@omw-context player

local async = require 'openmw.async'
local input = require 'openmw.input'
local ui = require 'openmw.ui'
local util = require 'openmw.util'
local modalLayout = require 'scripts.s3ui.components.count_modal_layout'

---@class S3UI.CountModalModule
local M = {}

local MIN_COUNT = 1
local HOVER_TEXT_COLOR = util.color.rgb(1, 0.94, 0.74)

local rootElement = nil
local value = 1
local minValue = 1
local maxValue = 1
local inputText = '1'
local title = 'Select Count'
local draggingControl = nil
local closed = true
local hoveredControl = nil
local generation = 0
local onOk = nil
local onCancel = nil
local layout

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
	rootElement.layout = layout()
	rootElement:update()
end

local function setTextEditFocused(layout, focused, callbackGeneration)
	if not (not closed and callbackGeneration == generation and rootElement and rootElement.layout) then
		return
	end
	if not layout or not layout.props then
		return
	end
	layout.props.textColor = focused and HOVER_TEXT_COLOR or nil
	if not focused then
		layout.props.text = inputText
	end
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
	if inputText == '' then
		return value
	end
	return clampInteger(inputText)
end

local function isAlive(callbackGeneration)
	return not closed and callbackGeneration == generation and rootElement and rootElement.layout
end

local function updateRoot()
	if rootElement and rootElement.layout then
		rootElement.layout = layout()
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

local function setValueFromTrack(offsetX, trackWidth, skipUpdate)
	local ratio = offsetX / trackWidth
	if ratio < 0 then
		ratio = 0
	elseif ratio > 1 then
		ratio = 1
	end
	setValue(minValue + math.floor((maxValue - minValue) * ratio + 0.5), skipUpdate)
end

local function closeWithoutCallback()
	closed = true
	draggingControl = nil
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

layout = function()
	return modalLayout.make {
		async = async,
		generation = generation,
		title = title,
		inputText = inputText,
		maxValue = maxValue,
		value = value,
		hoverTextColor = hoverTextColor,
		setHoveredControl = setHoveredControl,
		setTextEditFocused = setTextEditFocused,
		isAlive = isAlive,
		setInputText = function(text)
			inputText = text
		end,
		commitInputText = function()
			value = parseInputText()
			inputText = tostring(value)
		end,
		sliderRatio = sliderRatio,
		setValue = setValue,
		setValueFromTrack = setValueFromTrack,
		beginDrag = function(name)
			draggingControl = name
		end,
		isDragging = function(name)
			return draggingControl == name
		end,
		endDrag = function()
			draggingControl = nil
			updateRoot()
		end,
		confirm = confirm,
		cancel = cancel,
	}
end

function M.layout()
	return layout()
end

---@param opts? S3UI.CountModalOptions
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
	title = opts.title or 'Select Count'
	onOk = opts.onOk
	onCancel = opts.onCancel
	draggingControl = nil
	closed = false
	generation = generation + 1
	rootElement = ui.create(layout())
end

function M.hide()
	closeWithoutCallback()
end

function M.isOpen()
	return not closed and rootElement ~= nil and rootElement.layout ~= nil
end

---@param key table
---@return boolean handled
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
