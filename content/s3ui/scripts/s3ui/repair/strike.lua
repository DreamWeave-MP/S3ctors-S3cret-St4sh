---@omw-context player

local s3math = require 'scripts.s3.math'

---@class S3UI.RepairStrikeState
---@field marker number
---@field direction number
---@field speed number
---@field goodHalfWidth number
---@field perfectHalfWidth number
---@field lastRating? string
---@field lastGain? number
---@field lastWear? number

---@class S3UI.RepairStrikeModule
local M = {}

local CENTER = 0.5

---@param armorer number
---@param toolQuality number
---@return S3UI.RepairStrikeState
function M.new(armorer, toolQuality)
	local skill = s3math.clamp(armorer, 0, 100) / 100
	local quality = s3math.clamp(toolQuality, 0.5, 2)
	return {
		marker = 0,
		direction = 1,
		speed = 1.28 - skill * 0.28,
		goodHalfWidth = 0.105 + skill * 0.07 + (quality - 1) * 0.025,
		perfectHalfWidth = 0.025 + skill * 0.025 + (quality - 1) * 0.01,
	}
end

---@param state S3UI.RepairStrikeState
---@param dt number
function M.update(state, dt)
	state.marker = state.marker + state.direction * state.speed * (tonumber(dt) or 0)
	if state.marker > 1 then
		state.marker = 1 - (state.marker - 1)
		state.direction = -1
	elseif state.marker < 0 then
		state.marker = -state.marker
		state.direction = 1
	end
end

---@param state S3UI.RepairStrikeState
---@return string rating, number performance, number wearMultiplier
function M.rating(state)
	local distance = s3math.abs(state.marker - CENTER)
	if distance <= state.perfectHalfWidth then
		return 'Perfect', 1.25, 0.75
	elseif distance <= state.goodHalfWidth then
		return 'Good', 1, 1
	elseif distance <= state.goodHalfWidth * 1.75 then
		return 'Rough', 0.65, 1.35
	end
	return 'Failed', 0.15, 1.75
end

---@param repairItem S3UI.RepairItem
---@param armorer number
---@param toolQuality number
---@param performance number
---@return number
function M.conditionGain(repairItem, armorer, toolQuality, performance)
	local skillFactor = 0.55 + s3math.clamp(armorer, 0, 100) / 100 * 0.75
	local toolFactor = s3math.clamp(toolQuality, 0.5, 2)
	local base = s3math.max(4, repairItem.maxCondition * 0.09)
	return s3math.max(1, s3math.floor(base * skillFactor * toolFactor * performance + 0.5))
end

---@param toolQuality number
---@param wearMultiplier number
---@return number
function M.toolWear(toolQuality, wearMultiplier)
	local quality = s3math.clamp(toolQuality, 0.5, 2)
	return s3math.max(1, s3math.floor((2.4 / quality) * wearMultiplier + 0.5))
end

return M
