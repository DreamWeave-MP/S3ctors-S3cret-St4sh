---@omw-context menu|player

local RawGet, Type = rawget, type

local UnsetMarker = {}

local UNSET = {
  [UnsetMarker] = true,
}

---@param value H3UI.LuaValue
---@return boolean
local function isUnset(value) return Type(value) == 'table' and RawGet(value, UnsetMarker) == true end

return {
  UNSET = UNSET,
  isUnset = isUnset,
}
