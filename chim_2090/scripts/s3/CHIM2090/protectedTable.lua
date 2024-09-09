local gameSelf = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')

local modInfo = require('scripts.s3.CHIM2090.modInfo')

local function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0
  local iter = function ()
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

return function(inputGroupName)
  assert(inputGroupName ~= nil and storage.globalSection(inputGroupName) ~= nil,
         'An invalid setting group was provided!')

  local proxy = {
    thisGroup = storage.globalSection(inputGroupName)
  }
  local methods = {}

  function proxy.debugLog(...)
    if gameSelf.type ~= types.Player or not proxy.DebugLog then return end
    print(modInfo.logPrefix, table.concat({...}, ' '))
  end

  function proxy.notifyPlayer(...)
    if gameSelf.type ~= types.Player then return end
    require('openmw.ui').showMessage(modInfo.logPrefix .. ' ' .. table.concat({...}, ' '))
  end

  local meta = {
    __index = function(_, key)
      if key == 'DebugLog' then
        return storage.globalSection('SettingsGlobal' .. modInfo.name):get('DebugEnable')
      elseif key == 'MessageEnable' then
        return storage.globalSection('SettingsGlobal' .. modInfo.name):get('MessageEnable')
      elseif key == 'debugLog' then
        return proxy.debugLog
      end
      return methods[key] or proxy.thisGroup:get(key)
    end,
    __newindex = function(_, key, value)
      if type(value) ~= 'function' then
        error(
          string.format([[%s Unauthorized table access when updating '%s' to '%s'.
This table is not writable and values must be updated through its associated storage group: '%s'.]], modInfo.logPrefix,
          tostring(key), tostring(value), inputGroupName),
          2)
      end
      rawset(methods, key, value)
    end,
    __tostring = function(_)
      local members = {}
      local methodParts = {}

      for key, value in pairsByKeys(proxy.thisGroup:asTable()) do
        members[#members + 1] = string.format('%s = %s', tostring(key), tostring(value))
      end

      for key, _ in pairsByKeys(methods) do
        methodParts[#methodParts + 1] = string.format('%s', tostring(key))
      end

      return string.format('CHIMManager{ Members: %s Methods: %s }',
                           table.concat(members, ', '), table.concat(methodParts, ', '))
    end,
    __pairs = function()
      return next, proxy.thisGroup:asTable(), nil
    end,
  }
  setmetatable(proxy, meta)

  return proxy
end
