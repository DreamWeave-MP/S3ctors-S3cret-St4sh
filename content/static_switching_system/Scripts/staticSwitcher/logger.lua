---@omw-context global

local storage = require('openmw.storage')
local staticUtil = require('Scripts.staticSwitcher.util')

local LOG_PREFIX = 'SSS'
local SettingsSection = storage.globalSection 'SettingsStaticSwitcher'

---@param message string
local function log(message)
	staticUtil.Log(message, LOG_PREFIX)
end

---@return boolean
local function isDebugEnabled()
	return SettingsSection:get('StaticSwitcherEnableDebug') == true
end

--- Detailed trace. Format inside the guard — no work when logging is off.
--- First arg is the format string, remaining args are format values.
---@param formatString string
---@param ... any
local function debug(formatString, ...)
	if not isDebugEnabled() then return end
	log(select('#', ...) > 0 and formatString:format(...) or formatString)
end

--- General operation info. Same deferred-format behavior as debug.
---@param formatString string
---@param ... any
local function info(formatString, ...)
	if not isDebugEnabled() then return end
	local message = select('#', ...) > 0 and formatString:format(...) or formatString
	staticUtil.Log('[INFO] ' .. message, LOG_PREFIX)
end

--- Non-critical issue surfaced regardless of debug setting.
---@param message string
local function warn(message)
	staticUtil.Log('[WARN] ' .. message, LOG_PREFIX)
end

--- Critical error surfaced regardless of debug setting.
---@param message string
local function error(message)
	staticUtil.Log('[ERROR] ' .. message, LOG_PREFIX)
end

---@type SSSLogger
return {
	debug = debug,
	info = info,
	warn = warn,
	error = error,
	isDebugEnabled = isDebugEnabled,
}
