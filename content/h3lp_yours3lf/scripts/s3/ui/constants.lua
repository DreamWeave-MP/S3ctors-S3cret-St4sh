---@omw-context menu|player

local unsetMarker = {}

local UNSET = {
  [unsetMarker] = true,
}

local function isUnset(value)
  return type(value) == 'table' and rawget(value, unsetMarker) == true
end

return {
  UNSET = UNSET,
  isUnset = isUnset,
}
