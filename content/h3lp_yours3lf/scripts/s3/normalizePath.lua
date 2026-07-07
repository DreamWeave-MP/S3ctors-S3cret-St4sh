---@omw-context none

local StrGsub, StrLower = string.gsub, string.lower

---@param path string
---@return string normalizedPath
local function normalizePath(path)
  local normalized, _ = StrGsub(StrGsub(StrLower(path), '\\', '/'), '/+', '/')
  return normalized
end

return normalizePath
