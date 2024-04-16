local Object = {}

--- Makes the table into a self-referenceable object
--- @param inputData table: The table to make self-referenceable
function Object:new(inputData)
  if type(inputData) ~= 'table' then error("Cannot make this into an object; it may be userData") end
  inputData = inputData or {}
  setmetatable(inputData, self)
  self.__index = self
  return inputData
end

return Object
