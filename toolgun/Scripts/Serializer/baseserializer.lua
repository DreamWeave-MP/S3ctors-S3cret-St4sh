local aux_util = require('openmw_aux.util')
local core = require('openmw.core')
local types = require('openmw.types')
local vfs = require('openmw.vfs')
local world = require('openmw.world')

local Bits = math.pow(2, 24)
local Serializer = {}


function Serializer:new(serializerData)
  serializerData = serializerData or {}
  setmetatable(serializerData, self)
  self.__index = self
  self.cellsSaved = 0
  self.contentFiles = self.contentFiles or
    {'morrowind.esm',
    'tribunal.esm',
    'bloodmoon.esm'}
  self.contentIndex = 3
  self.espFiles = {}
  self.hasWarned = false
  self.objects = {}
  return serializerData
end

function Serializer:dumpAll(targets)

  if not targets then targets = self.objects end

  local saveString = ''

  local cellIndex = 1
  for cell, objects in pairs(targets) do
    local referenceCollection = ''
    for index, object in pairs(objects) do

      -- Needs an additional safeguard to add plugins which
      -- actually define an object if it is not in the master list
      if object.contentFile then
        self:handleESPWarning(object.contentFile)
        if not self.targetInTable(object.contentFile, self.contentFiles) then
          table.insert(self.contentFiles, object.contentFile)
          self.contentIndex = self.contentIndex + 1
        end
      end

      -- Common Instance Fields
      referenceCollection = referenceCollection .. self:makeBaseReference(object)

      -- Per-Type fields

      referenceCollection = referenceCollection .. '}'

      if index < #objects then
        referenceCollection = referenceCollection .. ','
      end
    end

    saveString = saveString .. '{' .. self:makeCellString(cell) .. '['.. referenceCollection .. ']}'

    if cellIndex ~= self.cellsSaved then
      saveString = saveString .. ','
      cellIndex = cellIndex + 1
    end

  end

  saveString = '[' .. self.makeHeaderString(self.contentFiles) .. saveString .. ']'

  print(saveString)
end

function Serializer:getPair(key, value, comma)
  if not key or type(key) ~= 'string' then print('#C90913 ' .. "Serializer: Invalid string key.") return end

  local stringPair = '"' .. key .. '":'

  if type(value) == 'number' then
    stringPair = stringPair .. value
  elseif type(value) == 'boolean' then
    if value then
      stringPair = stringPair .. 'true'
    else
      stringPair = stringPair .. 'false'
    end
  elseif type(value) == 'string' then
    stringPair = stringPair .. '"' .. value .. '"'
  elseif type(value) == 'table' then
    local separator = '[]'
    local tableString = ''

    for index, tableVal in ipairs(value) do

      if type(index) == 'string' then
        tableString = tableString .. self.GetPair(index, tableVal)
        separator = '{}'
      elseif type(tableVal) == 'number' then
        tableString = tableString .. tableVal
      elseif type(tableVal) == 'string' then
        tableString = tableString .. '"' .. tableVal .. '"'
      end

      if index ~= #value then tableString = tableString .. ',' end

    end
    stringPair = stringPair .. string.sub(separator, 1, 1) .. tableString .. string.sub(separator, 2, 2)
  end

  if not comma then stringPair = stringPair .. ',' end

  return stringPair
end

function Serializer:handleESPWarning(contentFile)
  if string.find(contentFile, '.esp') then
    table.insert(self.espFiles, contentFile)
  end

  if #self.espFiles > 1 and not self.hasWarned then
    print('#C90913' ..
          "WARNING: Modifications to more than one ESP file have been serialized by this toolGun project." ..
          "Please be aware you may not be able to properly utilize all of your changes. Affected plugins: " ..
          aux_util.deepToString(self.espFiles))
    self.hasWarned = true
  end
end

function Serializer:makeCellString(cellName)
  local cell = world.getCellByName(cellName)

  return self:getPair('type', 'Cell') ..
    self:getPair('flags', '') ..
    self:getPair('name', cellName) ..
    '"data":{' ..
    self:getPair('flags', self.makeFlagString(cell)) ..
    self:getPair('grid', { cell.gridX, cell.gridY }, true) ..
    '},' ..
    '"references":'
end

function Serializer:getObjectIndices(object, contentFiles)
  local masterIndex
  local refIndex
  if object.contentFile then
    refIndex = tostring(object.id) % Bits
  else
    refIndex = string.sub(tostring(object.id), 2) % Bits
  end

  if not object.contentFile then masterIndex = 0
  elseif contentFiles[self.contentIndex] == object.contentFile then
    masterIndex = self.contentIndex
  else
    for contentFileIndex, file in pairs(contentFiles) do
      if file == object.contentFile then
        masterIndex = contentFileIndex
        self.contentIndex = masterIndex
        break
      end
    end
  end

  return refIndex, masterIndex
end

function Serializer:makeBaseReference(object)
  local refIndex, masterIndex = Serializer:getObjectIndices(object, self.contentFiles)
  local rotZ, rotY, rotX = object.rotation:getAnglesZYX()
        return '{' ..
          self:getPair('mast_index', masterIndex) ..
          self:getPair('refr_index', refIndex) ..
          self:getPair('id', object.recordId) ..
          self:getPair('temporary', true) ..
          self:getPair('translation' , { object.position.x, object.position.y, object.position.z }) ..
          self:getPair('rotation', { rotX, rotY, rotZ }) ..
          self:getPair('scale', object.scale) ..
          self:getPair('disabled', object.enabled, true)
end

function Serializer:sortContentFiles()

  local sortedContentFiles = {}
  local indices = {}

  for _, file in pairs(self.contentFiles) do
    table.insert(indices, {index = core.contentFiles.indexOf(file), plugin = file})
  end

  while(#indices >= 1) do
    table.insert(sortedContentFiles, table.remove(indices, self.getLowestContentIndex(indices)).plugin)
  end

  return sortedContentFiles

end

function Serializer:makeHeaderString(contentFiles)
  local headerString = ''

  headerString = headerString .. '{"type":"Header","flags":"","version":1.3,"file_type":"Esp","author":"Based ToolGun User","description":"This plugin was generated by the ToolGun!","num_objects":0,"masters":['

  local sortedContentFiles = Serializer:sortContentFiles(contentFiles)

  for index, file in ipairs(sortedContentFiles) do
    headerString = headerString .. '["' .. file .. '",' .. Serializer.getSize(file) .. ']'
    if index ~= #sortedContentFiles then
      headerString = headerString .. ','
    end
  end

  headerString = headerString .. ']},'

  return headerString
end

function Serializer:preserveTarget(eventData, targetTable)

  local currentTarget = eventData.target
  local cellName = currentTarget.cell.name

  if not targetTable then targetTable = self.objects end

  if not targetTable[cellName] then
    targetTable[cellName] = {}
    if targetTable == self.objects then
      self.cellsSaved = self.cellsSaved + 1
    end
  end

  if not self.targetInTable(currentTarget, targetTable[cellName]) then
    table.insert(targetTable[cellName], currentTarget)
  end

  if targetTable ~= self.objects then
    self:preserveTarget(eventData, self.objects)
  end

  return currentTarget
end

function Serializer.getLowestContentIndex(indicesTable)

  local lowestPluginIndex = math.huge
  local pluginTableIndex = 1

  for index, fileData in pairs(indicesTable) do
    if fileData.index < lowestPluginIndex then
      lowestPluginIndex = fileData.index
      pluginTableIndex = index
    end
  end

  return pluginTableIndex
end

function Serializer.getSize(file)
  file = vfs.open(file)
  local size = tostring(file:seek('end'))
  file:close()
  return size
end

function Serializer.getDisabledString(state)
  if not state then
    return ',"deleted":true'
  end
  return ''
end

function Serializer.getScaleString(scale)
  local scaleString = ''
  local targetScale

  if scale == 1.0 then
    return scaleString
  elseif scale < -2.0 then
    targetScale = -2.0
  elseif scale > 2.0 then
    targetScale = 2.0
  else
    targetScale = scale
  end
  return ',"scale":' .. targetScale
end

function Serializer.makeFlagString(object)
  local flagString = ''
  local flags = {}

  if object.type == types.Cell then

    if not object.isExterior then
      table.insert(flags, "IS_INTERIOR")
    end

    if object:hasTag("NoSleep") then
      table.insert(flags, "RESTING_IS_ILLEGAL")
    end

    if object.hasWater then
      table.insert(flags, "HAS_WATER")
    end

    if object:hasTag("QuasiExterior") then
      table.insert(flags, "BEHAVES_LIKE_EXTERIOR")
    end

  end

  for index, flag in pairs(flags) do
    flagString = flagString .. flag

    if index ~= #flags then
      flagString = flagString .. ' | '
    end
  end

  return flagString
end

function Serializer.targetInTable(target, targetTable)
  for _, value in pairs(targetTable) do
    if value == target then return true end
  end
  return false
end

return Serializer
