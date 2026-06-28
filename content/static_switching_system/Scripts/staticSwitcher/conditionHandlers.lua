---@omw-context global

local types = require 'openmw.types'

local staticUtil = require 'scripts.staticSwitcher.util'

local INVALID_TYPE = 'Invalid type was provided: %s'

---@type table<string, SSSConditionHandler>
local conditionHandlers = {
  ---@param object openmw.GObject
  ---@param itemId RecordId|table<RecordId, integer>
  ---@return boolean
  carrying = function(object, itemId)
    if not object.type then return false end

    local objectHasInventory = object.type.inventory ~= nil
    if not objectHasInventory then return false end

    local objectInventory = object.type.inventory(object)

    local itemType = type(itemId)
    if itemType == 'string' then
      return objectInventory:find(itemId) ~= nil
    else
      local itemName, itemCount = next(itemId)

      return objectInventory:countOf(itemName) >= itemCount
    end
  end,
  ---@param object openmw.GObject
  ---@param cellName string
  ---@return boolean
  cell = function(object, cellName)
    return object.cell.name == cellName
  end,
  ---@param object openmw.GObject
  ---@param cellCoords ExteriorGrid
  ---@return boolean
  coords = function(object, cellCoords)
    if not object.cell.isExterior then return false end
    return object.cell.gridX == cellCoords.x and object.cell.gridY == cellCoords.y
  end,
  ---@param object openmw.GObject
  ---@param contentFileName string
  ---@return boolean
  content_file = function(object, contentFileName)
    return (
      object.contentFile == contentFileName:lower()
    ) or (
      not object.contentFile and contentFileName:upper() == 'GENERATED'
    )
  end,
  ---@param object openmw.GObject
  ---@param targetName string
  ---@return boolean
  name = function(object, targetName)
    --- Statics may never have a name
    if types.Static.objectIsInstance(object) or not object.type then return false end

    local objectRecord = object.type.records[object.recordId]

    if objectRecord.name == nil or objectRecord.name == '' then return false end

    return objectRecord.name == targetName
        or objectRecord.name:find(targetName, 1, true) ~= nil
  end,
  ---@param object openmw.GObject
  ---@param targetTypeName string
  ---@return boolean
  object_type = function(object, targetTypeName)
    local capitalizedTypeName = (targetTypeName:lower() == 'npc' and 'NPC') or staticUtil.capitalize(targetTypeName)
    local targetType = types[capitalizedTypeName]

    assert(
      targetType ~= nil,
      INVALID_TYPE:format(capitalizedTypeName)
    )

    return targetType.objectIsInstance(object)
  end,
  ---@param object openmw.GObject
  ---@param targetRecordId RecordId
  ---@return boolean
  record_id = function(object, targetRecordId)
    local originalId, lowerId = object.recordId, targetRecordId:lower()

    return originalId == lowerId or originalId:find(lowerId, 1, true) ~= nil
  end,
  ---@param object openmw.GObject
  ---@param targetRefNum number
  ---@return boolean
  ref_num = function(object, targetRefNum)
    local _, refNum = staticUtil.getRefNum(object)

    return refNum == targetRefNum
  end,
}

return conditionHandlers
