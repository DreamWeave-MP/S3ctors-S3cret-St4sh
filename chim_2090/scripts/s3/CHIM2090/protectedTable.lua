local modInfo = require('scripts.s3.CHIM2090.modInfo')
local storage = require('openmw.storage')

return function(inputTable, inputGroupName)
  assert(inputTable ~= nil and inputGroupName ~= nil, 'Failed to provide required inputs!')
  local proxy = {}
  local meta = {
    __index = inputTable,
    __newindex = function(_, key, value)
      if type(value) ~= 'function' then
        if value ~= storage.globalSection(inputGroupName):get(key) then
          error(
            string.format(
              [[%s Unauthorized table access when updating '%s' to '%s'.
This table must be updated through its associated storage group: '%s']],
              modInfo.logPrefix,
              tostring(key),
              tostring(value),
              inputGroupName),
            2)
        end
      end
      inputTable[key] = value
    end,
  }
  setmetatable(proxy, meta)
  return proxy
end
