---@omw-context menu|player
---@module 'scripts.h3.runtime'

local IsLuau = _VERSION == 'Luau'

---@type H3.Runtime
local Runtime = {
  isLuaJIT = not IsLuau,
  isLuau = IsLuau,
}

return Runtime
