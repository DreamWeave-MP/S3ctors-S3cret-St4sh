---@omw-context player

local ui = require 'openmw.ui'
local util = require 'openmw.util'
local chrome = require 'scripts.s3ui.inventory.chrome'

local v2 = util.vector2

---@class S3UI.RepairMeterModule
local M = {}

local HOVER_COLOR = util.color.rgb(1, 0.94, 0.74)
local CENTER = 0.5

local markerLayout = nil
local goodLayout = nil
local perfectLayout = nil

---@param strike S3UI.RepairStrikeState|nil
---@return number marker
---@return number goodLeft
---@return number goodWidth
---@return number perfectLeft
---@return number perfectWidth
local function strikeMetrics(strike)
	local marker = strike and strike.marker or 0
	local goodLeft = strike and CENTER - strike.goodHalfWidth or 0.4
	local goodWidth = strike and strike.goodHalfWidth * 2 or 0.2
	local perfectLeft = strike and CENTER - strike.perfectHalfWidth or 0.48
	local perfectWidth = strike and strike.perfectHalfWidth * 2 or 0.04
	return marker, goodLeft, goodWidth, perfectLeft, perfectWidth
end

---@param strike S3UI.RepairStrikeState|nil
---@return openmw.ui.Layout
function M.make(strike)
	local marker, goodLeft, goodWidth, perfectLeft, perfectWidth = strikeMetrics(strike)
	local good = {
		name = 's3ui_repair_meter_good',
		type = ui.TYPE.Image,
		props = {
			resource = chrome.WHITE_TEXTURE,
			color = util.color.rgb(0.62, 0.48, 0.2),
			alpha = 0.75,
			relativePosition = v2(goodLeft, 0),
			relativeSize = v2(goodWidth, 1),
		},
	}
	local perfect = {
		name = 's3ui_repair_meter_perfect',
		type = ui.TYPE.Image,
		props = {
			resource = chrome.WHITE_TEXTURE,
			color = util.color.rgb(0.95, 0.82, 0.35),
			alpha = 0.92,
			relativePosition = v2(perfectLeft, 0),
			relativeSize = v2(perfectWidth, 1),
		},
	}
	local markerVisual = {
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
	}
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
	}
	chrome.addSimpleBorder(content, 's3ui_repair_meter', 0.7)
	content:add(good)
	content:add(perfect)
	content:add(markerVisual)
	return {
		name = 's3ui_repair_meter',
		type = ui.TYPE.Widget,
		props = { relativeSize = v2(1, 0), size = v2(0, 42) },
		content = content,
	}
end

---@param meterLayout openmw.ui.Layout|nil
---@return boolean bound
function M.bind(meterLayout)
	if not (meterLayout and meterLayout.content) then
		markerLayout = nil
		goodLayout = nil
		perfectLayout = nil
		return false
	end
	local content = meterLayout.content
	goodLayout = content.s3ui_repair_meter_good
	perfectLayout = content.s3ui_repair_meter_perfect
	markerLayout = content.s3ui_repair_meter_marker
	return markerLayout ~= nil and goodLayout ~= nil and perfectLayout ~= nil
end

function M.reset()
	markerLayout = nil
	goodLayout = nil
	perfectLayout = nil
end

---@param rootElement openmw.ui.Element|nil
---@param strike S3UI.RepairStrikeState|nil
---@return boolean updated
function M.update(rootElement, strike)
	if not (rootElement and rootElement.layout) then
		return false
	end
	if not (markerLayout and goodLayout and perfectLayout) then
		return false
	end
	local marker, goodLeft, goodWidth, perfectLeft, perfectWidth = strikeMetrics(strike)
	markerLayout.props.relativePosition = v2(marker, 0)
	goodLayout.props.relativePosition = v2(goodLeft, 0)
	goodLayout.props.relativeSize = v2(goodWidth, 1)
	perfectLayout.props.relativePosition = v2(perfectLeft, 0)
	perfectLayout.props.relativeSize = v2(perfectWidth, 1)
	rootElement:update()
	return true
end

return M
