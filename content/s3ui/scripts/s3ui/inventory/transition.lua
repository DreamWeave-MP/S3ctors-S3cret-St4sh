---@omw-context none

local s3math = require 'scripts.s3.math'

---@class S3UI.InventoryTransitionModule
local M = {}

local HALF_PI = s3math.pi * 0.5

M.OPENING = 'opening'
M.CLOSING = 'closing'
M.OPEN_DURATION = 0.28
M.CLOSE_DURATION = 0.22

function M.duration(phase)
	if phase == M.CLOSING then
		return M.CLOSE_DURATION
	end
	return M.OPEN_DURATION
end

function M.progress(phase, rawT)
	local t = s3math.clamp(rawT, 0, 1)
	if phase == M.CLOSING then
		return t
	end
	return s3math.sin(t * HALF_PI)
end

return M
