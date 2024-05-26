local debug = true
local common = {}

common.debugMePls = function(message)
  if debug and message then print(message) end
end

return common
