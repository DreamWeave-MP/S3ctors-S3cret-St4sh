local Object = {}

--- Throws if input isn't a table
--- This is to avoid getting references to the original table
--- on accident when using this technique with menu templates
--- I thought it needed to be done recursively, but that throws errors about bad ui content
--- @param original table: The table to copy
--- @param isDeepCopy boolean: Whether to copy nested tables (DON'T USE WITH UI CONTENT)
local function copyTable(original, isDeepCopy)
  if type(original) ~= "table" then error("Cannot copy this; it may be userData") end

  local copy = {}

  for key, value in pairs(original) do
    if isDeepCopy and type(value) == "table" then
      copy[key] = copyTable(value)  -- Recursively copy nested tables
    else
      copy[key] = value
    end
  end

  return copy
end

--- Makes the table into a self-referenceable object
--- @param inputData table: The table to make self-referenceable
function Object:new(inputData)
  if inputData and type(inputData) ~= 'table' then error("Cannot make this into an object; it may be userData") end
  inputData = copyTable(inputData) or {}
  setmetatable(inputData, self)
  self.__index = self
  return inputData
end

return Object
