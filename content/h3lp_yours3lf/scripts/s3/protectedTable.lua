---@omw-context local | player

local async = require 'openmw.async'
local gameSelf = require 'openmw.self'
local storage = require 'openmw.storage'

local assert, rawset, next, pairs, tostring, type = assert, rawset, next, pairs, tostring, type
local StrFormat = string.format
local TableConcat, TableInsert, TableSort = table.concat, table.insert, table.sort

local StorageGet, StorageSet = storage.globalSection('SettingsOMWCombat').get, nil

local isPlayer, ui
do
  local types = require 'openmw.types'
  isPlayer = types.Player.objectIsInstance(gameSelf)

  ---@omw-context-begin player
  if isPlayer then ui = require 'openmw.ui' end
  ---@omw-context-end player
end

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do
    TableInsert(a, n)
  end

  TableSort(a, f)

  local i = 0
  local iter = function()
    i = i + 1

    if a[i] == nil then
      return
    else
      return a[i], t[a[i]]
    end
  end

  return iter
end

---@type ShadowTableSubscriptionHandler
local function defaultSubscribeHandler(shadowSettings, group, _, key)
  shadowSettings[key] = StorageGet(group, key)
end

---@alias IndexFunction fun(key: string): any

--- Bridges onto a global storage section, providing easy access to the storage group with caching and logging methods
--- All settings associated with the storage section provided in the constructor are accessible by simply indexing the table.
--- They will always be up-to-date thanks to the provided subscription function, but that sub function may be overridden during construction.
---@class ProtectedTable:table table Semi-Read-only table which allows insertion of functions and hooks to a global storage section
---@field private shadowSettings ShadowSettingsTable Cached copies of setting values returned by the index method. Do NOT work with this directly.
---@field private thisGroup openmw.storage.StorageSection Storage section this ProtectedTable owns. Do not work with this directly, instead iterate over or index the ProtectedTable.
---@field state table a writable table to store arbitrary values in
---@field notifyPlayer fun(any) shorthand to display all arguments as a table in a Morrowind MessageBox from a protectedTable. Only works on player scripts.
---@field debugLog fun(...) If debug logging setting is enabled, then prints the arguments to log, as a concatenated table
---@field interface fun(handler: IndexFunction) Helper function to provide more convenience when binding a protectedTable into an interface

---@alias ShadowSettingsTable table<string, any>
---@alias ShadowTableSubscriptionHandler fun(shadowSettings: ShadowSettingsTable, group: openmw.storage.StorageSection, groupName: string, key: string)

---@class ProtectedTableConstructor
---@field logPrefix string
---@field storageSection openmw.storage.StorageSection? instead of the *name* of a global section, protectedTables may provide a storgae section which the table uses
---@field inputGroupName string? name of the *global* storage section to use. If no managerName is provided, also used in the __tostring method
---@field managerName string? optional name to override inputGroupName in the __tostring method
---@field subscribeHandler ShadowTableSubscriptionHandler|false? override function to use instead of the default subscription handler. Since global sections may not be written from local scripts, an explicit value of `false` can be used to indicate no subscription at all.

---@param constructorData ProtectedTableConstructor
---@return ProtectedTable
local function new(constructorData)
  local requestedGroup
  if constructorData.storageSection then
    requestedGroup = constructorData.storageSection
  elseif constructorData.inputGroupName then
    requestedGroup = storage.globalSection(constructorData.inputGroupName)
  else
    error('No group or group name provded to protectedTable constructor!', 2)
  end

  assert(requestedGroup ~= nil, 'An invalid storage section was provided!')
  local testKey, testValue = next(requestedGroup:asTable())

  ---@diagnostic disable-next-line: undefined-field
  StorageSet = requestedGroup.set

  local groupIsWritable = pcall(StorageSet, requestedGroup, testKey, testValue)

  local methods, proxy, shadowSettings, state = {}, {}, {}, {}

  requestedGroup:subscribe(
    async:callback(
      function(group, key) defaultSubscribeHandler(shadowSettings, requestedGroup, group, key) end
    )
  )

  if constructorData.subscribeHandler then
    assert(type(constructorData.subscribeHandler) == 'function')

    requestedGroup:subscribe(
      async:callback(
        function(group, key)
          constructorData.subscribeHandler(shadowSettings, requestedGroup, group, key)
        end
      )
    )
  end

  local managerString = constructorData.managerName or constructorData.inputGroupName

  function methods.debugLog(...)
    if not shadowSettings.DebugEnable then return end

    print(constructorData.logPrefix, TableConcat({ ... }, ' '))
  end

  ---@omw-context-begin player
  if isPlayer then
    function methods.notifyPlayer(...)
      if not shadowSettings.MessageEnable then return end

      ui.showMessage(constructorData.logPrefix .. ' ' .. TableConcat({ ... }, ' '))
    end
  end
  ---@omw-context-end player

  function methods.interface(handlerFunction)
    assert(type(handlerFunction) == 'function')

    return setmetatable({}, {
      __index = function(_, key) return handlerFunction(key) end,
    })
  end

  local meta = {
    __metatable = 'S3ProtectedTable',
    __index = function(_, key)
      if key == 'state' then return state end

      local result = shadowSettings[key]
      if result ~= nil then return result end

      result = methods[key]
      if result ~= nil then return result end

      result = state[key]
      if result ~= nil then return result end

      local savedValue = StorageGet(requestedGroup, key)
      shadowSettings[key] = savedValue

      return savedValue
    end,
    __newindex = function(_, key, value)
      if key == 'state' and type(value) == 'table' then
        for k in pairs(state) do
          state[k] = nil
        end

        for k, v in pairs(value) do
          state[k] = v
        end
      elseif state[key] ~= nil and type(value) ~= 'function' then
        state[key] = value
      elseif type(value) ~= 'function' or (type(value) ~= 'table' and key == 'state') then
        if groupIsWritable then
          shadowSettings[key] = value

          ---@cast requestedGroup openmw.storage.MutableStorageSection
          StorageSet(requestedGroup, key, value)
        else
          error(
            ([[%s Unauthorized table access when updating '%s' to '%s'.
This table is not writable and values must be updated through its associated storage group: '%s'.]]):format(
              constructorData.logPrefix,
              tostring(key),
              tostring(value),
              constructorData.inputGroupName or 'NO NAME PROVIDED'
            ),
            2
          )
        end
      else
        rawset(methods, key, value)
      end
    end,
    __tostring = function(_)
      local members, methodParts, stateParts = {}, {}, {}

      for key, value in pairsByKeys(requestedGroup:asTable()) do
        members[#members + 1] = StrFormat('        %s = %s', tostring(key), tostring(value))
      end

      for key, value in pairsByKeys(state) do
        stateParts[#stateParts + 1] = StrFormat('        %s = %s', tostring(key), tostring(value))
      end

      for key, _ in pairsByKeys(methods) do
        methodParts[#methodParts + 1] = StrFormat('        %s', tostring(key))
      end

      if next(members) == nil then members[1] = '        None' end
      if next(methodParts) == nil then methodParts[1] = '        None' end
      if next(stateParts) == nil then stateParts[1] = '        None' end

      return StrFormat(
        '%sManager {\n    Members:\n%s\n    Methods:\n%s\n    State:\n%s\n    }',
        managerString,
        TableConcat(members, ',\n'),
        TableConcat(methodParts, ',\n'),
        TableConcat(stateParts, ',\n')
      )
    end,
    __call = function()
      local settings = requestedGroup:asTable()
      local keys = {}

      for key in pairs(settings) do
        keys[#keys + 1] = key
      end

      TableSort(keys)

      local i = 0

      return function()
        i = i + 1
        local key = keys[i]

        if key then return key, settings[key] end
      end
    end,
  }

  setmetatable(proxy, meta)

  return proxy
end

local ProtectedTableInterface = {
  interfaceName = 'S3ProtectedTable',
  --- Local-scope interface for building stateful game
  --- systems which respond to setting values without
  --- the boilerplate bullshit of rewriting :subscribe handlers
  --- all the time
  ---
  --- Usage:
  --- ```lua
  --- local LockOnManager = I.S3ProtectedTable.new {
  ---  -- Name of a setting group to read from. Uses global storage by default.
  ---  inputGroupName = ModInfo.groupName,
  ---  -- Prefix to use in log messages if your storage section includes a `DebugEnable` key,
  ---  -- Its value is `true`, and you use the log function PT provides
  ---  logPrefix = ModInfo.logPrefix,
  ---  -- Overrides the `inputGroupName` in the ProtectedTable's __tostring method
  ---  managerName = ModInfo.name,
  ---  -- Optionally provide your own subscribe handler
  ---  -- PT wraps it in async:callback for you
  ---  subscribeHandler = false,
  ---  -- Provide a writable player section instead of a read-only
  ---  -- global section if needed
  ---  storageSection = require('openmw.storage').playerSection(ModInfo.groupName),
  ---}
  --- ```
  ---
  ---@class ProtectedTableInterface
  ---@field help string Display help string in the in-game console
  ---@field new fun(ProtectedTableConstructor: ProtectedTableConstructor): ProtectedTable
  interface = {
    new = new,
    help = [[
        The ProtectedTable constructor takes three required arguments:
        logPrefix: string applied as a prefix when using the built-in debugLog function
        inputGroupName: A settings group to which this table will attached

        Optional Arguments:
        managerName: overrides the inputGroupName in __tostring
        subscribeHandler: overrides the built-in subscription handler for more advanced change handling, such as changing a UI element when the user sets a different size.

        To make a new ProtectedTable bound to a settings group, simply call the interface: I.S3ProtectedTable.new { logPrefix = '[ SW4Mounts ]', inputGroupName = 'SettingsGlobalSW4Mounts' }
        ]],
  },
}

---@class openmw.interfaces
---@field S3ProtectedTable ProtectedTableInterface

return ProtectedTableInterface
