--- Migrate this into H3 later as a generic logger
---@omw-context menu|player
local ModInfo = require 'scripts.s3.S4V3R.modInfo'

local Print, Select, StrFormat = print, select, string.format

local Debug
do
  local S4V3RStorage = require('openmw.storage').playerSection(ModInfo.GroupName)
  local StorageGet = S4V3RStorage.get
  Debug = StorageGet(S4V3RStorage, 'DebugEnable')

  S4V3RStorage:subscribe(require('openmw.async'):callback(function(_, key)
    if key == 'DebugEnable' then Debug = StorageGet(S4V3RStorage, key) end
  end))
end

local LogPrefix = StrFormat('[ %s ]: ', ModInfo.Name)
return function(message, ...)
  if not Debug then return end

  local lenVarArgs = Select('#', ...)

  if lenVarArgs > 0 then
    message = StrFormat(LogPrefix .. message, ...)
  else
    message = LogPrefix .. message
  end

  Print(StrFormat(message))
end
