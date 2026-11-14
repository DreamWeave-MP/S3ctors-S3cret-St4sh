---@omw-context global

local core = require 'openmw.core'
local types = require 'openmw.types'
local util = require 'openmw.util'
local world = require 'openmw.world'

local randomGen = require 'scripts.s3.randomGen'

local BatchCache = require 'Scripts.staticSwitcher.batchCache'
local Regions = require 'Scripts.staticSwitcher.regions'
local TriggerContext = require 'Scripts.staticSwitcher.triggerContext'

local WarnLog
do
  local logger = require 'Scripts.staticSwitcher.logger'
  WarnLog = logger.warn
end

local StrFormat = string.format

local next, pairs, pcall, type, unpack = next, pairs, pcall, type, unpack

local addTag, removeTag
local I = require 'openmw.interfaces'
if I.FlexTagG then
  addTag = I.FlexTagG.addTag
  removeTag = I.FlexTagG.removeTag
end

local rotateX = util.transform.rotateX
local rotateY = util.transform.rotateY
local rotateZ = util.transform.rotateZ
local rad = math.rad

local ActorObjectIsInstance = types.Actor.objectIsInstance
local ContainerObjectIsInstance = types.Container.objectIsInstance
local PlayerObjectIsInstance = types.Player.objectIsInstance

local Player = world.players[1]

local ActorSpells = types.Actor.spells
local ActorActiveSpells = types.Actor.activeSpells
local SpellRecords = core.magic.spells.records
local Weather = core.weather

local ACTIVE_SPELL_OPTION_KEYS = {
  'name',
  'stackable',
  'ignoreResistances',
  'ignoreSpellAbsorption',
  'ignoreReflect',
  'quiet',
}

---@type table<RecordId, true>
local UncreatableRecordWarnings = {}

--- Creates an object, warning once per record ID when the record cannot be instantiated.
---@param actionName string
---@param recordId RecordId
---@return openmw.GObject? createdObject
local function tryCreateObject(actionName, recordId)
  local wasCreated, createdObject = pcall(world.createObject, recordId)
  if wasCreated then return createdObject end

  if UncreatableRecordWarnings[recordId] then return end
  UncreatableRecordWarnings[recordId] = true

  WarnLog(
    StrFormat(
      '%s: could not create an object from record "%s": %s',
      actionName,
      recordId,
      tostring(createdObject)
    )
  )
end

---@type table<string, true>
local IssuedWarnings = {}

---@param message string
local function warnOnce(message)
  if IssuedWarnings[message] then return end
  IssuedWarnings[message] = true

  WarnLog(message)
end

--- A repeat of the same request for the same region inside this window is dropped. It is short
--- on purpose: something else may change the weather, and a later request must go through.
local WEATHER_REQUEST_REPEAT_SECONDS = 10

---@type table<string, SSSWeatherRequest>
local LastWeatherRequests = {}

---@param regionId string
---@param weatherId string
---@return boolean wasJustRequested
local function wasWeatherJustRequested(regionId, weatherId)
  local lastRequest = LastWeatherRequests[regionId]

  return lastRequest ~= nil
    and lastRequest.weatherId == weatherId
    and core.getSimulationTime() - lastRequest.time < WEATHER_REQUEST_REPEAT_SECONDS
end

---@param regionId string
---@param weather openmw.core.WeatherRecord
---@return boolean isAlreadyComing whether the player's region already has, or is turning to, this weather
local function playerRegionAlreadyHasWeather(regionId, weather)
  local playerCell = Player.cell
  if not playerCell or Regions.resolveRegion(playerCell, Player.position) ~= regionId then
    return false
  end

  local upcomingWeather = Weather.getNext(playerCell) or Weather.getCurrent(playerCell)

  return upcomingWeather ~= nil and upcomingWeather.recordId == weather.recordId
end

---@param object openmw.GObject
---@return openmw.core.Inventory? inventory
local function getObjectInventory(object)
  if not ContainerObjectIsInstance(object) and not ActorObjectIsInstance(object) then return end

  return object.type.inventory(object)
end

---@param object openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasAdded
local function addItemToInventory(object, recordId, count)
  if count < 1 then return false end

  local inventory = getObjectInventory(object)
  if not inventory then return false end

  world.createObject(recordId, count):moveInto(inventory)
  return true
end

---@param object openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasRemoved
local function removeItemFromInventory(object, recordId, count)
  if count < 1 then return false end

  local inventory = getObjectInventory(object)
  if not inventory then return false end

  local availableCount = inventory:countOf(recordId)
  if availableCount < 1 then return false end

  local remainingCount = math.min(count, availableCount)
  local items = inventory:findAll(recordId)

  for i = 1, #items do
    local itemStack = items[i]
    local removeCount = math.min(remainingCount, itemStack.count)

    itemStack:remove(removeCount)
    remainingCount = remainingCount - removeCount

    if remainingCount <= 0 then return true end
  end

  return false
end

---@param actor openmw.GObject
---@param recordId RecordId
---@param count integer
---@return openmw.GObject? item
local function getOrCreateInventoryItem(actor, recordId, count)
  if count < 1 or not ActorObjectIsInstance(actor) then return end

  local inventory = getObjectInventory(actor)
  if not inventory then return end

  local item = inventory:find(recordId)
  if item then return item end

  item = world.createObject(recordId, count)
  item:moveInto(inventory)

  return item
end

---@param actor openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasEquipped
local function equipInventoryItem(actor, recordId, count)
  local item = getOrCreateInventoryItem(actor, recordId, count)
  if not item then return false end

  core.sendGlobalEvent('UseItem', { object = item, actor = actor, force = true })
  return true
end

---@param actor openmw.GObject
---@param recordId RecordId
---@return integer count
local function countEquippedItems(actor, recordId)
  if not ActorObjectIsInstance(actor) then return 0 end

  local count = 0

  for _, item in pairs(actor.type.getEquipment(actor)) do
    if item.recordId == recordId then count = count + 1 end
  end

  return count
end

---@param actor openmw.GObject
---@param recordId RecordId
---@param count integer
---@return boolean wasUnequipped
local function unequipInventoryItem(actor, recordId, count)
  if count < 1 or countEquippedItems(actor, recordId) < count then return false end

  local remainingCount = count

  for _, item in pairs(actor.type.getEquipment(actor)) do
    if item.recordId == recordId then
      core.sendGlobalEvent('UseItem', { object = item, actor = actor, force = true })
      remainingCount = remainingCount - 1

      if remainingCount <= 0 then return true end
    end
  end

  return false
end

---@param actor openmw.GObject
---@param spellId RecordId
---@return boolean wasAdded
local function addSpellToActor(actor, spellId)
  if not ActorObjectIsInstance(actor) then return false end

  local spells = ActorSpells(actor)
  if spells[spellId] then return false end

  spells:add(spellId)
  return true
end

---@param actor openmw.GObject
---@param spellId RecordId
---@return boolean wasRemoved
local function removeSpellFromActor(actor, spellId)
  if not ActorObjectIsInstance(actor) then return false end

  local spells = ActorSpells(actor)
  if not spells[spellId] then return false end

  spells:remove(spellId)
  return true
end

---@param spellId RecordId
---@return integer[]? effectIndexes
local function getAllSpellEffectIndexes(spellId)
  local spellRecord = SpellRecords[spellId]
  if not spellRecord then return end

  local effectIndexes = {}
  for effectIndex = 1, #spellRecord.effects do
    effectIndexes[effectIndex] = effectIndex - 1
  end

  return effectIndexes
end

---@param actor openmw.GObject
---@param spellId RecordId
---@param details SSSActiveSpellDetails?
---@return boolean wasAdded
local function addActiveSpellToActor(actor, spellId, details)
  if not ActorObjectIsInstance(actor) then return false end

  local effectIndexes = details and details.effects or getAllSpellEffectIndexes(spellId)
  if not effectIndexes then
    WarnLog(
      StrFormat('add_active_spell: %s is not a spell record and has no effects list', spellId)
    )
    return false
  end

  ---@type openmw.types.ActiveSpellAddOptions
  local options = { id = spellId, effects = effectIndexes }

  if details then
    for keyIndex = 1, #ACTIVE_SPELL_OPTION_KEYS do
      local optionKey = ACTIVE_SPELL_OPTION_KEYS[keyIndex]
      options[optionKey] = details[optionKey]
    end
  end

  ActorActiveSpells(actor):add(options)
  return true
end

---@param itemData integer|SSSItemActionDetails
---@return integer count
---@return SSSChanceRange? chance
local function getItemActionDetails(itemData)
  if type(itemData) == 'table' then
    if not itemData.count and not itemData.chance then return 0 end

    local count = itemData.count or 1
    if type(count) == 'table' then
      assert(count.max, 'RangeTable requires a "max"')
      count.min = count.min or 1
      assert(count.min <= count.max, 'RangeTable requires min <= max')
      -- Must use randomGen.range(_, true) for integer output;
      -- getRangeValue returns floats (correct for positions, not counts).
      count = randomGen.range(count.min or 1, count.max, true)
    end

    return count, itemData.chance
  end

  return itemData
end

---@param chance SSSChanceRange?
---@return boolean shouldApply
local function shouldApplyChance(chance)
  if not chance then return true end

  if type(chance) == 'number' then
    if chance <= 0 then
      return false
    elseif chance >= 1 then
      return true
    end

    return randomGen.float() <= chance
  end

  assert(chance.max, 'Chance range table is missing required "max" field')

  if chance.max <= 0 then
    return false
  elseif chance.min and chance.min >= 1 then
    return true
  end

  local roll = randomGen.float()

  return roll >= (chance.min or 0) and roll <= chance.max
end

---@param object openmw.GObject
---@param itemAction SSSItemAction
---@param itemHandler fun(object: openmw.GObject, recordId: RecordId, count: integer): boolean
---@param arrayItemCount integer? Default count to use for each element in the array form.
---@return boolean wasApplied
local function applyItemAction(object, itemAction, itemHandler, arrayItemCount)
  local actionType = type(itemAction)

  if actionType == 'string' then
    return itemHandler(object, itemAction, 1)
  elseif actionType == 'table' then
    local firstKey = next(itemAction)

    -- Array of record IDs: apply the same count to each.
    if firstKey and type(firstKey) == 'number' then
      local wasApplied = false
      local count = arrayItemCount or 1
      local numItems = #itemAction

      for i = 1, numItems do
        wasApplied = itemHandler(object, itemAction[i], count) or wasApplied
      end

      return wasApplied
    end

    -- Map of record IDs to counts: existing behavior.
    local wasApplied = false

    for recordId, itemData in pairs(itemAction) do
      local count, chance = getItemActionDetails(itemData)

      if count >= 1 and shouldApplyChance(chance) then
        wasApplied = itemHandler(object, recordId, count) or wasApplied
      end
    end

    return wasApplied
  end

  return false
end

---@param object openmw.GObject
---@param spellAction SSSSpellAction
---@param spellHandler fun(object: openmw.GObject, spellId: RecordId): boolean
---@return boolean wasApplied
local function applySpellAction(object, spellAction, spellHandler)
  local actionType = type(spellAction)

  if actionType == 'string' then return spellHandler(object, spellAction) end
  if actionType ~= 'table' then return false end

  local wasApplied = false
  local firstKey = next(spellAction)

  if firstKey and type(firstKey) == 'number' then
    ---@cast spellAction RecordId[]
    for spellIndex = 1, #spellAction do
      wasApplied = spellHandler(object, spellAction[spellIndex]) or wasApplied
    end

    return wasApplied
  end

  ---@cast spellAction table<RecordId, SSSSpellDetails>
  for spellId, details in pairs(spellAction) do
    if shouldApplyChance(details.chance) then
      wasApplied = spellHandler(object, spellId) or wasApplied
    end
  end

  return wasApplied
end

---@param object openmw.GObject
---@param activeSpellAction SSSActiveSpellAction
---@return boolean wasApplied
local function applyActiveSpellAction(object, activeSpellAction)
  local actionType = type(activeSpellAction)

  if actionType == 'string' then return addActiveSpellToActor(object, activeSpellAction) end
  if actionType ~= 'table' then return false end

  local wasApplied = false
  local firstKey = next(activeSpellAction)

  if firstKey and type(firstKey) == 'number' then
    ---@cast activeSpellAction RecordId[]
    for spellIndex = 1, #activeSpellAction do
      wasApplied = addActiveSpellToActor(object, activeSpellAction[spellIndex]) or wasApplied
    end

    return wasApplied
  end

  ---@cast activeSpellAction table<RecordId, SSSActiveSpellDetails>
  for spellId, details in pairs(activeSpellAction) do
    if shouldApplyChance(details.chance) then
      wasApplied = addActiveSpellToActor(object, spellId, details) or wasApplied
    end
  end

  return wasApplied
end

---@param object openmw.GObject
---@param eventAction SSSEventAction
---@return SSSEventPayload payload
local function buildEventPayload(object, eventAction)
  local payload = {}

  local eventData = eventAction.data
  if eventData then
    for key, value in pairs(eventData) do
      payload[key] = value
    end
  end

  payload.object = object

  return payload
end

---@param object openmw.GObject
---@param runAction SSSRunLuaScriptAction
local function runTransientScript(object, runAction)
  local scriptPath = runAction.script

  ---@type SSSRunLuaScriptInitData
  local initData = { ['function'] = runAction['function'], args = runAction.args }

  object:addScript(scriptPath, initData)
  object:removeScript(scriptPath)
end

---
--- Helper: extract a numeric value from a number or {min, max} range table.
---@param numberOrTable SSSRandomNumericRange
---@return number
local function getRangeValue(numberOrTable)
  local actionDataType = type(numberOrTable)

  if actionDataType == 'number' then
    return numberOrTable
  elseif actionDataType == 'table' then
    assert(numberOrTable.max, 'An upper bound is required when selecting a numeric range!')
    return randomGen.range(numberOrTable.min or 0, numberOrTable.max)
  elseif actionDataType == 'nil' then
    return 0
  else
    error(StrFormat('Incorrect type provided to getRangeValue: %s', actionDataType))
  end
end

---
--- Apply rotation to a transform, optionally relative to current.
---@param isRelative boolean
---@param rotateActionDetails SSSVector3Range
---@param currentTransform openmw.util.Transform
---@return openmw.util.Transform
local function getRotationValue(isRelative, rotateActionDetails, currentTransform)
  local rootTransform = isRelative and currentTransform or util.transform.identity

  local z = rotateActionDetails.z
  if z then rootTransform = rotateZ(rad(getRangeValue(z))) * rootTransform end

  local y = rotateActionDetails.y
  if y then rootTransform = rotateY(rad(getRangeValue(y))) * rootTransform end

  local x = rotateActionDetails.x
  if x then rootTransform = rotateX(rad(getRangeValue(x))) * rootTransform end

  return rootTransform
end

---
--- Calculate target scale from a scale action, relative to a reference.
---@param scaleAction SSSRandomNumericRange
---@param referenceScale number
---@return number
local function getScaleValue(scaleAction, referenceScale)
  local scaleType = type(scaleAction)

  if scaleType == 'number' then
    return referenceScale * scaleAction
  elseif scaleType == 'table' then
    return referenceScale * randomGen.range(scaleAction.min or 1.0, scaleAction.max)
  end

  error(StrFormat('Invalid type for scale parameter: %s', scaleType))
end

--- Rolls how many objects a pool creates this time.
---@param details string|number|SSSCreatePool
---@return SSSRolledCreatePool? pool nil when the pool creates nothing this time
local function rollCreatePool(details)
  local detailsType = type(details)

  if detailsType == 'string' then return { count = 1, usesRelativeTransform = true } end
  if detailsType == 'number' then
    local count = math.floor(details)
    return count >= 1 and { count = count, usesRelativeTransform = true } or nil
  end
  if detailsType ~= 'table' then return end

  local count = details.count or 1
  if type(count) == 'table' then
    assert(count.max, 'RangeTable requires a "max"')
    count.min = count.min or 1
    assert(count.min <= count.max, 'RangeTable requires min <= max')
    -- Must use randomGen.range(_, true) for integer output;
    -- getRangeValue returns floats (correct for positions, not counts).
    count = randomGen.range(count.min or 1, count.max, true)
  end

  if count < 1 or (details.chance and not shouldApplyChance(details.chance)) then return end

  local transformType = details.transform_type

  return {
    count = count,
    position = details.position,
    rotate = details.rotate,
    scale = details.scale,
    usesRelativeTransform = transformType == nil or transformType == 'relative',
  }
end

---@param pool SSSRolledCreatePool
---@param basePosition openmw.util.Vector3
---@param baseRotation openmw.util.Transform
---@param baseScale number
---@return openmw.util.Vector3 position
---@return openmw.util.Transform rotation
---@return number scale
local function resolveCreatedPlacement(pool, basePosition, baseRotation, baseScale)
  local position, rotation, scale = basePosition, baseRotation, baseScale
  local usesRelativeTransform = pool.usesRelativeTransform

  local positionOverride = pool.position
  if positionOverride then
    local offset = util.vector3(
      getRangeValue(positionOverride.x),
      getRangeValue(positionOverride.y),
      getRangeValue(positionOverride.z)
    )

    position = usesRelativeTransform and position + offset or offset
  end

  if pool.rotate then rotation = getRotationValue(usesRelativeTransform, pool.rotate, rotation) end

  if pool.scale then scale = getScaleValue(pool.scale, usesRelativeTransform and scale or 1.0) end

  return position, rotation, scale
end

---@param object openmw.GObject
---@param cell openmw.core.GCell
---@param position openmw.util.Vector3
---@param rotation openmw.util.Transform
---@param scale number? only set when the pool overrides scale
local function placeCreatedObject(object, cell, position, rotation, scale)
  object:teleport(cell, position, rotation)
  if scale then object:setScale(scale) end
end

--- Creates one pool object and puts it in the world. An object that cannot be placed is
--- removed again rather than left stranded outside any cell. Each object stands alone, so the
--- caller can count exactly what now exists even when a later object fails.
--- Only the engine calls are protected. Pool shapes are checked when the module loads, so
--- working out a placement cannot fail on anything an author wrote.
---@param recordId RecordId
---@param pool SSSRolledCreatePool
---@param cell openmw.core.GCell
---@param basePosition openmw.util.Vector3
---@param baseRotation openmw.util.Transform
---@param baseScale number
---@return openmw.GObject? placedObject
local function createPlacedObject(recordId, pool, cell, basePosition, baseRotation, baseScale)
  local position, rotation, scale =
    resolveCreatedPlacement(pool, basePosition, baseRotation, baseScale)

  local object = tryCreateObject('create', recordId)
  if not object then return end

  local wasPlaced, placeError =
    pcall(placeCreatedObject, object, cell, position, rotation, pool.scale and scale)

  if wasPlaced then return object end

  pcall(object.remove, object)
  warnOnce(StrFormat('create: "%s" could not be placed: %s', recordId, tostring(placeError)))
end

---@type table<string, function>
local actionHandlers = {
  ['transform'] = function(_, transformAction, newTransform, newPos, targetScale)
    local wasModified = false
    local useRelativeTransform = transformAction.transform_type == nil
      or transformAction.transform_type == 'relative'

    local scaleAction = transformAction.scale
    if scaleAction then
      local referenceScale = useRelativeTransform and targetScale or 1.0
      targetScale = getScaleValue(scaleAction, referenceScale)
      wasModified = true
    end

    local rotateAction = transformAction.rotate
    if rotateAction then
      newTransform = getRotationValue(useRelativeTransform, rotateAction, newTransform)
      wasModified = true
    end

    local positionAction = transformAction.position
    if positionAction then
      local actionTargetPos = util.vector3(
        getRangeValue(positionAction.x),
        getRangeValue(positionAction.y),
        getRangeValue(positionAction.z)
      )

      if useRelativeTransform then
        newPos = newPos + actionTargetPos
      else
        newPos = actionTargetPos
      end

      wasModified = true
    end

    return wasModified, newTransform, newPos, targetScale
  end,
  ['replace'] = function(object, replaceActionData)
    if PlayerObjectIsInstance(object) then return end

    if replaceActionData == 'self' then return tryCreateObject('replace', object.recordId) end

    for replaceId, replaceChance in pairs(replaceActionData) do
      if randomGen.float() <= replaceChance then
        local replacement = tryCreateObject('replace', replaceId)

        if replacement then return replacement end
      end
    end
  end,
  ['add'] = function(object, addActionData)
    return applyItemAction(object, addActionData, addItemToInventory, 1)
  end,
  ['remove'] = function(object, removeActionData)
    return applyItemAction(object, removeActionData, removeItemFromInventory, math.huge)
  end,
  ['equip'] = function(object, equipActionData)
    return applyItemAction(object, equipActionData, equipInventoryItem, 1)
  end,
  ['unequip'] = function(object, unequipActionData)
    return applyItemAction(object, unequipActionData, unequipInventoryItem, 1)
  end,
  ['add_spell'] = function(object, addSpellActionData)
    return applySpellAction(object, addSpellActionData, addSpellToActor)
  end,
  ['remove_spell'] = function(object, removeSpellActionData)
    return applySpellAction(object, removeSpellActionData, removeSpellFromActor)
  end,
  ['add_active_spell'] = function(object, addActiveSpellActionData)
    return applyActiveSpellAction(object, addActiveSpellActionData)
  end,
  ['disable'] = function(object, disableAction)
    if PlayerObjectIsInstance(object) then return false end

    if disableAction == true then return true end
    if type(disableAction) == 'table' then
      if not disableAction.chance then return true end
      return randomGen.float() <= disableAction.chance
    end
    return false
  end,
  ['delete'] = function(object, deleteAction, replaceAction, replaceActionSucceeded)
    if PlayerObjectIsInstance(object) then return false end

    return deleteAction and (not replaceAction or replaceActionSucceeded)
  end,
  ['create'] = function(
    _,
    createActionData,
    accumulatedCell,
    accumulatedPosition,
    accumulatedRotation,
    accumulatedScale
  )
    local totalCreated = 0
    local createdObjects = {}

    for recordId, details in pairs(createActionData) do
      local pool = rollCreatePool(details)

      if pool then
        for _ = 1, pool.count do
          local object = createPlacedObject(
            recordId,
            pool,
            accumulatedCell,
            accumulatedPosition,
            accumulatedRotation,
            accumulatedScale
          )
          if not object then break end

          totalCreated = totalCreated + 1
          createdObjects[totalCreated] = object
        end
      end
    end

    return totalCreated, createdObjects
  end,
  ['lock_level'] = function(object, lockData)
    local objType = object.type
    if not objType or not objType.lock then return false end

    local level
    if type(lockData) == 'number' then
      level = lockData
    elseif type(lockData) == 'table' then
      lockData.min = lockData.min or 1
      assert(lockData.min <= lockData.max, 'RangeTable requires min <= max')
      level = randomGen.range(lockData.min or 1, lockData.max, true)
    else
      return false
    end

    if level <= 0 then
      objType.unlock(object)
    else
      objType.lock(object, level)
    end

    return true
  end,
  ['playsound'] = function(object, soundData)
    local soundId, soundFile, chance, volume, pitch, doLoop, timeOffset

    if type(soundData) == 'string' then
      soundId = soundData
    elseif type(soundData) == 'table' then
      soundId = soundData.id
      soundFile = soundData.file
      chance = soundData.chance
      volume = soundData.volume
      pitch = soundData.pitch
      doLoop = soundData.loop
      timeOffset = soundData.timeOffset
    end

    if not soundId and not soundFile then return false end

    if chance and not shouldApplyChance(chance) then return false end

    local options
    if volume or pitch or doLoop or timeOffset then
      options = {}
      if volume then options.volume = volume end
      if pitch then options.pitch = pitch end
      if doLoop then options.loop = doLoop end
      if timeOffset then options.timeOffset = timeOffset end
    end

    if soundFile then
      core.sound.playSoundFile3d(soundFile, object, options)
    else
      core.sound.playSound3d(soundId, object, options)
    end

    return true
  end,
  ['set_ownership'] = function(object, ownershipData)
    local madeChange = false
    local owner = object.owner

    if ownershipData.owner then
      owner.recordId = ownershipData.owner
      madeChange = true
    end
    if ownershipData.faction then
      owner.factionId = ownershipData.faction
      madeChange = true
    end
    if ownershipData.factionRank then
      owner.factionRank = ownershipData.factionRank
      madeChange = true
    end

    return madeChange
  end,
  ['key'] = function(object, keyData)
    local objType = object.type
    if not objType or not objType.setKeyRecord then return false end

    if keyData == false then
      objType.setKeyRecord(object, nil)
      return true
    end

    for i = 1, #keyData do
      local keyId, chance = next(keyData[i])
      if shouldApplyChance(chance) then
        objType.setKeyRecord(object, keyId)
        return true
      end
    end

    return false
  end,
  ['trap'] = function(object, trapData)
    local objType = object.type
    if not objType or not objType.setTrapSpell then return false end

    if trapData == false then
      objType.setTrapSpell(object, nil)
      return true
    end

    for i = 1, #trapData do
      local trapId, chance = next(trapData[i])
      if shouldApplyChance(chance) then
        objType.setTrapSpell(object, trapId)
        return true
      end
    end

    return false
  end,
  ['add_lua_script'] = function(object, scriptPath)
    if object:hasScript(scriptPath) then return false end

    object:addScript(scriptPath)
    return true
  end,
  ['activate_by_player'] = function(object)
    object:activateBy(Player)
    return true
  end,
  ['remove_lua_script'] = function(object, scriptPath)
    if not object:hasScript(scriptPath) then return false end

    object:removeScript(scriptPath)
    return true
  end,
  ['run_lua_script'] = function(object, runAction)
    local didRun, runError = pcall(runTransientScript, object, runAction)
    if not didRun then
      WarnLog(
        StrFormat('run_lua_script: %s on %s failed: %s', runAction.script, object.id, runError)
      )
    end

    return didRun
  end,
  ['call_interface'] = function(object, callAction)
    local interfaceName, functionName = callAction.interface, callAction['function']
    local interface = I[interfaceName]
    local interfaceFunction = interface and interface[functionName]

    if type(interfaceFunction) ~= 'function' then
      WarnLog(StrFormat('call_interface: %s.%s is not available', interfaceName, functionName))
      return false
    end

    local args = callAction.args
    local didCall, callError
    if args then
      didCall, callError = pcall(interfaceFunction, object, unpack(args))
    else
      didCall, callError = pcall(interfaceFunction, object)
    end

    if not didCall then
      WarnLog(
        StrFormat(
          'call_interface: %s.%s on %s failed: %s',
          interfaceName,
          functionName,
          object.id,
          callError
        )
      )
    end

    return didCall
  end,
  ['send_event'] = function(object, eventAction)
    object:sendEvent(eventAction.name, buildEventPayload(object, eventAction))
    return true
  end,
  ['send_global_event'] = function(object, eventAction)
    core.sendGlobalEvent(eventAction.name, buildEventPayload(object, eventAction))
    return true
  end,
  ['global_set'] = function(_, globalData)
    local globals = BatchCache.globalVariables()
    local value = globalData.value

    if type(value) == 'table' then value = randomGen.range(value.min or 1, value.max, true) end

    globals[globalData.name] = value
    return true
  end,
  ['set_weather'] = function(_, weatherAction)
    local weatherId, regionId = weatherAction, nil
    if type(weatherAction) == 'table' then
      weatherId, regionId = weatherAction.weather, weatherAction.region
    end

    local weather = type(weatherId) == 'string' and Weather.records[weatherId] or nil
    if not weather then
      warnOnce(StrFormat('set_weather: "%s" is not a weather record', tostring(weatherId)))
      return false
    end

    local playerCell = Player.cell
    local playerRegionId = playerCell and Regions.resolveRegion(playerCell, Player.position)

    regionId = regionId or playerRegionId
    if not regionId then return false end

    local weatherRecordId = weather.recordId

    if
      wasWeatherJustRequested(regionId, weatherRecordId)
      or playerRegionAlreadyHasWeather(regionId, weather)
    then
      return false
    end

    local didChange, changeError = pcall(Weather.changeWeather, regionId, weather)
    if not didChange then
      warnOnce(
        StrFormat('set_weather: could not change region "%s": %s', regionId, tostring(changeError))
      )
      return false
    end

    LastWeatherRequests[regionId] = { weatherId = weatherRecordId, time = core.getSimulationTime() }

    if regionId == playerRegionId then
      local expectedWeatherIds = TriggerContext.expectedWeatherIds
      expectedWeatherIds[#expectedWeatherIds + 1] = weatherRecordId
    end

    return true
  end,
  ['teleport'] = function(object, teleportData, currentCell, currentPos, currentRotation)
    local cell = teleportData.cell
    local pos = teleportData.position
    local rot = teleportData.rotation
    local onGround = teleportData.onGround

    local targetCell = currentCell

    if cell then
      local cellType = type(cell)
      if cellType == 'string' then
        targetCell = world.getCellByName(cell)
      elseif cellType == 'table' then
        targetCell = world.getExteriorCell(cell.x, cell.y)
      end

      if not targetCell then
        WarnLog(StrFormat('teleport: cell not found for %s', object.id))
        return false
      end
    end

    local targetPos = currentPos
    local targetRot = currentRotation

    if pos then
      targetPos = util.vector3(
        pos.x and getRangeValue(pos.x) or targetPos.x,
        pos.y and getRangeValue(pos.y) or targetPos.y,
        pos.z and getRangeValue(pos.z) or targetPos.z
      )
    end

    if rot then targetRot = getRotationValue(true, rot, targetRot) end

    return true, targetCell, targetPos, targetRot, onGround
  end,
  ['add_tag'] = function(object, tag)
    if not addTag then return false end

    addTag(object, tag)
    return true
  end,
  ['remove_tag'] = function(object, tag)
    if not removeTag then return false end

    removeTag(object, tag)
    return true
  end,
}

return actionHandlers
