local async = require('openmw.async')
local core = require('openmw.core')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')

local freighterData = {
  currentPlanet = nil,
  replacementFreighterId = nil,
  replacementDoorId = nil,
  replacementLightSpeed = nil,
  doorModel = 'meshes/ig/activators/door1.nif',
  freighterModel = 'meshes/ig/spshipfreight.nif',
  lightSpeedModel = 'meshes/ig/freightltspeed.nif',
  travelEffect = 'sound/ig/flyingsound.wav',
  doorEffect = 'sound/fx/trans/drmtl_opn.wav',
  travelActive = false,
}

local freighterQuestData = {
  repairedShip = false,
  -- componentsSpent = 0,
}

local playerShipIds = {
  ['sw_playershipnew'] = true,
  ['sw_playershipnewtaris'] = true,
  ['sw_playersshipmana'] = true,
}

local buttonToCellMap = {
  ['sw_buttondan'] = 'dantooine, ballast',
  ['sw_buttonmana'] = 'manaan, docking bay',
  ['sw_buttonnar'] = 'nar shaddaa, north hanger',
  ['sw_buttongamorr'] = 'gamorr, ucksmug',
  ['sw_buttonhoth'] = 'hoth, wasteland',
  ['sw_buttontaris'] = 'taris, central plaza',
  ['sw_buttontat'] = 'tatooine, sandriver',
  ['sw_buttonkash'] = 'kashyyk, boyle research facility',
  ['sw_buttonm4'] = 'm4-78: landing arm',
  ['sw_buttondathomir'] = 'dathomir, exterior',
}

local liveButtonToCellMap = {}

local freighterCells = {
  ['dantooine, ballast'] = {
    planetActivator = 'sw_freightplandant',
    door = 'sw_freightertodantooine',
    teleportTo = {
      pos = util.vector3(5916, -1030, 145),
      rot = 0,
    },
  },
  ['dathomir, exterior'] = {
    planetActivator = 'sw_freightplandath',
    door = 'sw_freightertodathomir',
    teleportTo = {
      pos = util.vector3(1163, 1423, 12468),
      rot = 97,
    },
  },
  ['derelict station, antechamber'] = {
    planetActivator = 'sw_freightderelict1',
    door = 'sw_freightertoderelict',
    teleportTo = {
      pos = util.vector3(10249, 6049, 14377),
      rot = 360,
    }
  },
  ['gamorr, ucksmug'] = {
    planetActivator = 'sw_freightplangamor',
    door = 'sw_freightertogamorr',
    teleportTo = {
      pos = util.vector3(3014, -1093, 147),
      rot = 40,
    },
  },
  ['hoth, wasteland'] = {
    planetActivator = 'sw_freightplanhoth',
    door = 'sw_freightertohoth',
    teleportTo = {
      pos = util.vector3(8090, 6426, 13141),
      rot = 193,
    },
  },
  ['kashyyk, boyle research facility'] = {
    planetActivator = 'sw_freightplankash',
    door = 'sw_freightertokashyyk',
    teleportTo = {
      pos = util.vector3(9726, -4728, 13393),
      rot = 237,
    },
  },
  ['lok, graveridge'] = {
    planetActivator = 'sw_freightplanlok',
    door = 'sw_freightertolok',
    teleportTo = {
      pos = util.vector3(11491, 15117, 727),
      rot = -123,
    },
  },
  ['m4-78: landing arm'] = {
    planetActivator  = 'sw_freightplanm478',
    door = 'sw_freightertom4',
    teleportTo = {
      pos = util.vector3(4708, 8282, 17356),
      rot = 183,
    },
  },
  ['manaan, docking bay'] = {
    planetActivator = 'sw_freightplanmana',
    door = 'sw_freightertomanaan',
    teleportTo = {
      pos = util.vector3(6935, 11504, 7848),
      rot = 142,
    },
  },
  ['nar shaddaa, north hanger'] = {
    planetActivator = 'sw_freightplannar',
    door = 'sw_freightertonarshad',
    teleportTo = {
      pos = util.vector3(3249, 4341, 13450),
      rot = 166,
    },
  },
  ['taris, central plaza'] = {
    planetActivator = 'sw_freightplantaris',
    door = 'sw_freightertotaris',
    teleportTo = {
      pos = util.vector3(3394, 9979, 12843),
      rot = 274,
    },
  },
  ['tatooine, sandriver'] = {
    planetActivator = 'sw_freighterplantat',
    door = 'sw_freightertotatooine',
    teleportTo = {
      pos = util.vector3(7687, 6619, 12366),
      rot = 314,
    },
  },
}

-- Position the activator actually teleports you to when entering the ship
local teleportPosition = util.vector3(3947, 5156, 15363)
local teleportRot = util.transform.rotateZ(math.rad(270), util.transform.identity)

-- Position of replacement doors
local doorPositionDefault = util.vector3(3981, 5151, 15240)
local doorRotDefault = util.transform.rotateZ(math.rad(90), util.transform.identity)

local freighterCellName = 'The Outer Rim, Freighter'

local ActivatorDraft = types.Activator.createRecordDraft
local CreateRecord = world.createRecord

--- Disables all planets which the player is not actually on
--- Bit edge casey since not all planets have a corresponding freighter,
--- but this shouldn't *break* anything per se
--- I don't think. :D
---@param targetPlanet core.Cell
local function activateCurrentPlanet(targetPlanet)
  if targetPlanet.name ~= freighterCellName then return end

  local localActivators = world.getCellByName(freighterCellName):getAll(types.Activator)

  for _, activator in ipairs(localActivators) do

    for cellId, planetData in pairs(freighterCells) do
      if activator.recordId == planetData.planetActivator then
        activator.enabled = (cellId == freighterData.currentPlanet)
        break
      end
    end

  end
end

local lightSpeedActivatorCallback =
    async:registerTimerCallback('SW4_TravelEndCallback', function(activatorData)
      activatorData.activator.enabled = false
      for _, player in ipairs(world.players) do
        if player.cell.name == freighterCellName then
          player:sendEvent('SW4_UIMessage', string.format('You have reached %s.', activatorData.cellDest))
          freighterData.travelActive = false
        end
      end
    end)

local function getLightSpeedActivator(freighterCell)
  local replacementLightSpeed = freighterData.replacementLightSpeed

  for _, object in ipairs(freighterCell:getAll(types.Activator)) do
    if object.recordId == 'sw_lightspeedact' then

      local newActivator =  world.createObject(freighterData.replacementLightSpeed)
      newActivator:teleport(freighterCell,
        object.position,
        object.rotation)

      object.enabled = false
      object:remove()
      return newActivator
    elseif object.recordId == replacementLightSpeed then
      object.enabled = true
      return object
    end
  end
end

local function enterShip(actor)
  actor:sendEvent('SW4_AmbientEvent', {
    soundFile = freighterData.doorEffect,
    options = {},
  })

  async:newUnsavableSimulationTimer(0.1 * time.second, function()
    actor:teleport(freighterCellName, teleportPosition, teleportRot)
  end)
end

local function handleButtonActivate(object)
  local targetCell = liveButtonToCellMap[object.recordId]
  if not targetCell then return end

  if freighterData.travelActive then return end

  freighterData.currentPlanet = targetCell
  activateCurrentPlanet(object.cell)

  local ambientData = {
    soundFile = freighterData.travelEffect,
    options = {},
  }
  -- local travelDelay = math.random(15, 45)
  -- local travelStr = string.format('You will reach your destination in %d minutes. Please enjoy the trip.', travelDelay)
  -- Maybe if we later come up with interesting things to do in the ship, we can make up an excuse to increase travel times.
  -- For now I think it's a bad idea since it would be boring and you'd just sleep through it.
  -- Or maybe fight through it...
  local targetPlanet = object.type.records[object.recordId].name
  local travelStr = string.format("Engaging warp drive, on course for %s.", targetPlanet)

  for _, player in ipairs(world.players) do
    if player.cell.name == freighterCellName then
      player:sendEvent('SW4_AmbientEvent', ambientData)
      player:sendEvent('SW4_UIMessage', travelStr)
    end
  end

  local lightSpeedActivator = getLightSpeedActivator(object.cell)
  assert(lightSpeedActivator, 'Failed to locate lightspeed activator in freighter cell!')

  time.newSimulationTimer(time.second * 5,
                          lightSpeedActivatorCallback,
                          {
                            activator = lightSpeedActivator,
                            cellDest = targetPlanet,
  })
  freighterData.travelActive = true
end

local function handleDoorActivate(door, actor)
  if door.recordId ~= freighterData.replacementDoorId or freighterData.travelActive then return end

  local teleportTarget = freighterCells[freighterData.currentPlanet]
  assert(teleportTarget, "Could not find current planet in cell data!")

  actor:sendEvent('SW4_AmbientEvent', {
    soundFile = freighterData.doorEffect,
    options = {},
  })

  -- Maybe can deduplicate this and enterShip later
  async:newUnsavableSimulationTimer(0.05 * time.second, function()
    actor:teleport(freighterData.currentPlanet,
      teleportTarget.teleportTo.pos,
      util.transform.rotateZ(math.rad(teleportTarget.teleportTo.rot),
        util.transform.identity))
  end)

  return true
end

--- Handles freighter activation by teleporting the player into the freighter,
--- playing necessary sounds and journal checks, and updating the interior state of the freighter
---@param object core.gameObject Object which was activated
---@param actor types.Actor Actor whom activated the ship (hopefully, a player, but we're not picky)
local function handleFreighterActivate(object, actor)
  local freighterId = freighterData.replacementFreighterId
  if not freighterId or object.recordId ~= freighterId then return end

  -- When activating the freighter, set the current planet
  -- Before actually doing any handling of said planet
  -- We want the freighter to be up-to-date at all times
  -- So even if this isn't necessary due to an invalid activation
  -- It's still necessary for diagesis
  -- We should also apply the `activateCurrentPlanet` function
  -- When handling other teleports, when possible
  freighterData.currentPlanet = actor.cell.name:lower()

  if not types.Player.objectIsInstance(actor) then return end

  local playerQuests = actor.type.quests(actor)
  local shipQuest = playerQuests['sw_tarischap1-2']
  local shipQuestProgress = shipQuest.stage

  if shipQuestProgress < 10 then
    actor:sendEvent('SW4_UIMessage', 'I wonder whose ship this is. . .')
  elseif shipQuestProgress == 10 then
    local inventory = actor.type.inventory(actor)
    local environmentFilterCount = inventory:countOf('sw_envirofilter')
    if environmentFilterCount >= 3 then
      inventory:find('sw_envirofilter'):remove(environmentFilterCount)

      -- Still need to add the topic "head to ship"
      for _, activeActor in ipairs(world.activeActors) do
        if activeActor.recordId == 'sw_shademanaan1' then
          core.sound.say('sound/ig/kellishipfix.wav', activeActor, 'It\'s all fixed up! Let\'s check it out.')
          break
        end
      end

      actor:sendEvent('SW4_UIMessage', 'You repair the ship!')
      shipQuest:addJournalEntry(15, actor)
      playerQuests['sw_shipown']:addJournalEntry(15, actor)
      -- enterShip(actor)
    else
      actor:sendEvent('SW4_UIMessage',
                      string.format('This ship needs repairs! Components %d/3',
                                    environmentFilterCount))
    end
  else
    enterShip(actor)
    return true
  end
end

---@param replaceCell core.Cell target cell containing the player and freighter to remove
---@return boolean? returns true if a ship was replaced in this cell
local function replaceFreighter(replaceCell)
  local localDoors = replaceCell:getAll(types.Door)
  for _, door in ipairs(localDoors) do

    if playerShipIds[door.recordId] then
      local replacementFreighter = world.createObject(freighterData.replacementFreighterId)
      replacementFreighter:setScale(door.scale)
      replacementFreighter:teleport(replaceCell.name, door.position, door.rotation)
      door.enabled = false
      door:remove()
      return true
    end

  end
end

---@param freighterCell core.Cell target cell containing the player and freighter to remove
---@return boolean? returns true if doors were already replaced
local function removeOldDoors(freighterCell)
  if freighterCell.name ~= freighterCellName then return end
  assert(freighterData.replacementDoorId, 'Replacement freighter door couldn\'t be found!')

  local localDoors = freighterCell:getAll(types.Door)
  local replaceCount = 0

  for _, doorData in pairs(freighterCells) do
    local doorId = doorData.door

    for _, door in ipairs(localDoors) do
      if door.recordId == doorId then
        door.enabled = false
        door:remove()
        replaceCount = replaceCount + 1
        break
      end
    end

  end

  for _, door in ipairs(localDoors) do
    if door.recordId == 'sw_freightertonone' or door.recordId == 'sw_freightertoextra' then
      door.enabled = false
      door:remove()
      replaceCount = replaceCount + 1
    end
  end

  if replaceCount == 0 then return end

  local replaceDoor = world.createObject(freighterData.replacementDoorId)
  replaceDoor:teleport(freighterCellName,
                       doorPositionDefault,
                       doorRotDefault)
  replaceDoor:setScale(1.12)
  return true
end

local function replaceOldButtons(freighterCell)
  if freighterCell.name ~= freighterCellName then return end
  local localActivators = freighterCell:getAll(types.Activator)

  local replaceCount = 0

  for _, activator in ipairs(localActivators) do
    local buttonTargetCell = buttonToCellMap[activator.recordId]
    if buttonTargetCell then

      local targetButtonId
      for buttonId, targetCellName in pairs(liveButtonToCellMap) do
        if targetCellName == buttonTargetCell then
          targetButtonId = buttonId
          break
        end
      end

      local newButtonInstance = world.createObject(targetButtonId)
      newButtonInstance:teleport(freighterCell.name, activator.position, activator.rotation)
      newButtonInstance:setScale(activator.scale)

      activator.enabled = false
      activator:remove()
      replaceCount = replaceCount + 1
    end
  end

  return replaceCount > 0
end

-- Disables relevant NPCs when sw_tarischap1-2 is over 10 and the player repairs the ship
local function disableShipQuestActors(object)
  if not freighterQuestData.repairedShip then return end
  if object.recordId == 'sw_shademanaan1' or object.recordId == 'sw_shipquester' then
    object.enabled = false
    object:remove()
  end
end

return {
  interfaceName = 'SW4_FreighterController',
  interface = {
    freighterData = freighterData,
    spaceButtons = function()
      return liveButtonToCellMap
    end,
  },
  engineHandlers = {
    onSave = function()
      return {
        currentPlanet = freighterData.currentPlanet,
        replacementLightSpeed = freighterData.replacementLightSpeed,
        replacementFreighterId = freighterData.replacementFreighterId,
        replacementDoorId = freighterData.replacementDoorId,
        travelActive = freighterData.travelActive,
        buttonToCellMap = liveButtonToCellMap,
        freighterQuestData = freighterQuestData,
      }
    end,
    onLoad = function(saveData)
      freighterData.currentPlanet = saveData.currentPlanet
      freighterData.replacementDoorId = saveData.replacementDoorId
      freighterData.replacementFreighterId = saveData.replacementFreighterId
      freighterData.replacementLightSpeed = saveData.replacementLightSpeed
      freighterData.travelActive = saveData.travelActive
      liveButtonToCellMap = saveData.buttonToCellMap
      freighterQuestData = saveData.freighterQuestData or
        {
          repairedShip = false,
        }
    end,
    onActivate = function(object, actor)
      if handleFreighterActivate(object, actor) then return
      elseif handleButtonActivate(object) then return
      elseif handleDoorActivate(object, actor) then return
      end
    end,
    onObjectActive = function(object)
      disableShipQuestActors(object)
    end,
    --- Player is passed as the first argument to this function, but right now we don't actually use it.
    onPlayerAdded = function(_)
      -- Create a replacement activator for the freighter itself, so we don't use the original script at all
      if not freighterData.replacementFreighterId then
        local newFreighter = CreateRecord(ActivatorDraft {
          name = 'Freighter',
          model = freighterData.freighterModel,
        })
        freighterData.replacementFreighterId = newFreighter.id
      end

      -- Replace the freighter doors so that we can have only a single one
      if not freighterData.replacementDoorId then
        local newDoor = CreateRecord(ActivatorDraft {
          name = 'Ship Exit Door',
          model = freighterData.doorModel,
        })
        freighterData.replacementDoorId = newDoor.id
      end

      -- Replace lightspeed activator since it self-deletes
      if not freighterData.replacementLightSpeed then
        local newLightSpeed = CreateRecord(ActivatorDraft {
          model = freighterData.lightSpeedModel,
        })
        freighterData.replacementLightSpeed = newLightSpeed.id
      end

      -- Check if the live button to cell map is empty, and if so, create necessary records for buttons
      if not next(liveButtonToCellMap) then
        for recordId, targetCell in pairs(buttonToCellMap) do
          local sourceRecord = types.Activator.records[recordId]

          local newButtonRecord = CreateRecord(ActivatorDraft {
                                                 name = sourceRecord.name,
                                                 model = sourceRecord.model,
          })
          -- Track the new, replacement buttons, inside of save data
          -- Since we don't necessarily know the id of the object which correlates to a specific planet button
          -- We need to know that later when trying to activate it
          liveButtonToCellMap[newButtonRecord.id] = targetCell

        end
      end
    end,
  },
  eventHandlers = {
    SW4_PlayerCellChanged = function(cellChangeData)
      local newCell = cellChangeData.player.cell

      if replaceFreighter(newCell) then return
      else
        replaceOldButtons(newCell)
        removeOldDoors(newCell)
        activateCurrentPlanet(newCell)
      end
    end,
  }
}
