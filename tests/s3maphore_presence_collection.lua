local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_presence_collection%.lua$' or '.'

package.path = table.concat({
  root .. '/content/h3lp_yours3lf/?.lua',
  root .. '/content/s3maphore/00 Core/?.lua',
  package.path,
}, ';')

local storageValues = {}
local quitCalled = false

local presenceSection = {}
function presenceSection:setLifeTime() end
function presenceSection:set(key, value) storageValues[key] = value end

package.preload['openmw.storage'] = function()
  return {
    LIFE_TIME = { Temporary = 2 },
    globalSection = function() return presenceSection end,
  }
end

local types = {
  Actor = {
    activeEffects = function()
      return { getEffect = function() return nil end }
    end,
    canMove = function() return true end,
    isDead = function() return false end,
    stats = { ai = { fight = function(object) return { modified = object.fight or 0 } end } },
  },
  Creature = {},
  Door = {
    destCell = function() return { region = nil } end,
    isTeleport = function() return false end,
    objectIsInstance = function() return false end,
  },
  NPC = {
    getDisposition = function() return 50 end,
    isWerewolf = function() return false end,
    objectIsInstance = function(object) return object.npc == true end,
  },
  Static = {},
}

package.preload['openmw.types'] = function() return types end
package.preload['openmw.core'] = function()
  return {
    quit = function() quitCalled = true end,
    getGMST = function(name)
      local values = {
        fFightDispMult = 0,
        iFightDistanceBase = 0,
        fFightDistanceMultiplier = 0,
        iWerewolfFightMod = 0,
      }
      return values[name]
    end,
    magic = { EFFECT_TYPE = { CalmCreature = 'calm-creature', CalmHumanoid = 'calm-humanoid' } },
    weather = { getCurrent = function() return nil end },
  }
end

package.preload['openmw.util'] = function()
  return {
    vector3 = function()
      return { length2 = function() return 0 end }
    end,
  }
end

package.preload['openmw.async'] = function() return {} end

local cells = {}
local function cellKey(x, y) return string.format('%d:%d', x, y) end

local zeroPosition = setmetatable({}, {
  __sub = function()
    return { length = function() return 0 end }
  end,
})

local function makeCell(x, y, id, objects, isExterior)
  local cell = {
    gridX = x,
    gridY = y,
    id = id,
    isExterior = isExterior ~= false,
    name = id,
    objects = objects or {},
  }
  cell.getAll = function(targetCell) return targetCell.objects end
  return cell
end

for x = -1, 5 do
  for y = -1, 1 do
    cells[cellKey(x, y)] = makeCell(x, y, 'cell:' .. cellKey(x, y))
  end
end

local centerE = cells[cellKey(0, 0)]
local centerF = cells[cellKey(1, 0)]
local centerG = cells[cellKey(2, 0)]
local centerH = cells[cellKey(4, 0)]
local west = cells[cellKey(-1, 0)]
centerE.objects = {
  {
    id = 'e-shared',
    recordId = 'record/shared',
    type = types.Static,
    contentFile = 'shared.esm',
    cell = centerE,
  },
}
west.objects = {
  {
    id = 'west-shared',
    recordId = 'record/shared',
    type = types.Static,
    contentFile = 'shared.esm',
    cell = west,
  },
}
centerF.objects = {
  {
    id = 'f-center-hostile',
    recordId = 'record/f-center',
    type = types.NPC,
    fight = 100,
    hostile = true,
    count = 1,
    position = zeroPosition,
    isValid = function() return true end,
    cell = centerF,
  },
}

local interior = makeCell(0, 0, 'interior', {}, false)
local player = {
  id = 'player',
  cell = centerE,
  count = 1,
  npc = true,
  object = 'player-object',
  position = zeroPosition,
}
function player:isValid() return true end
function player:sendEvent() end

package.preload['openmw.world'] = function()
  return {
    cells = {},
    mwscript = { getGlobalVariables = function() return { PCKnownWerewolf = 0 } end },
    players = { player },
    getExteriorCell = function(x, y) return cells[cellKey(x, y)] end,
  }
end

local staticCollection = require 'scripts.s3.music.staticCollection'

local function assertEqual(actual, expected, message)
  assert(
    actual == expected,
    string.format('%s: expected %s, got %s', message, tostring(expected), tostring(actual))
  )
end

local function waitForGeneration(generation)
  for _ = 1, 200 do
    staticCollection.engineHandlers.onUpdate()
    local presence = storageValues[player.id]
    if presence and presence.generation == generation then return presence end
  end
  error('presence generation did not publish: ' .. generation)
end

local function transition(cell, oldCell, generation)
  player.cell = cell
  staticCollection.eventHandlers.S3maphoreUpdatePresence { player, oldCell, generation }
  return waitForGeneration(generation)
end

staticCollection.eventHandlers.S3maphoreInitializationComplete { player, nil, 1 }
local initial = waitForGeneration(1)
assertEqual(
  initial.currentExteriorCellObjects.byRecord['record/shared'],
  1,
  'initial center projection'
)
assertEqual(initial.byRecord['record/shared'], 2, 'initial aggregate duplicate count')
assertEqual(initial.staticContentFiles[1], 'shared.esm', 'initial static content union')
assertEqual(initial.staticContentFiles[2], nil, 'initial static content union deduplication')
assertEqual(initial.cellHasHostileActors, false, 'initial center hostility')
assertEqual(initial.areaHasHostileActors, true, 'initial area hostility')

local interiorPresence = transition(interior, centerE.id, 2)
assertEqual(interiorPresence.currentExteriorCellObjects, nil, 'interior projection')
assertEqual(interiorPresence.cellHasHostileActors, false, 'interior center hostility')
assertEqual(interiorPresence.areaHasHostileActors, false, 'interior area hostility')

local restored = transition(centerE, interior.id, 3)
assert(restored.currentExteriorCellObjects, 'same-grid snapshot must restore center projection')
assertEqual(
  restored.currentExteriorCellObjects.byRecord['record/shared'],
  1,
  'same-grid snapshot center projection'
)
assertEqual(restored.cellHasHostileActors, false, 'restored center hostility')
assertEqual(restored.areaHasHostileActors, true, 'restored area hostility')

local moved = transition(centerF, centerE.id, 4)
assertEqual(
  moved.currentExteriorCellObjects.byRecord['record/f-center'],
  1,
  'retained center projection'
)
assertEqual(moved.byRecord['record/shared'], 1, 'aggregate duplicate removal by count')
assertEqual(moved.staticContentFiles[1], 'shared.esm', 'retained static content union')
assertEqual(moved.staticContentFiles[2], nil, 'retained static content union deduplication')
assertEqual(moved.cellHasHostileActors, true, 'retained center hostility')
assertEqual(moved.areaHasHostileActors, true, 'retained area hostility')

local dynamicObject = {
  id = 'f-dynamic',
  recordId = 'record/f-dynamic',
  type = types.Static,
  cell = centerF,
}
staticCollection.engineHandlers.onObjectActive(dynamicObject)

local dynamicPresence
for _ = 1, 40 do
  staticCollection.engineHandlers.onUpdate()
  dynamicPresence = storageValues[player.id]
  if dynamicPresence.byRecord['record/f-dynamic'] then break end
end
assertEqual(dynamicPresence.byRecord['record/f-dynamic'], 1, 'dynamic aggregate presence')
assertEqual(
  dynamicPresence.currentExteriorCellObjects.byRecord['record/f-dynamic'],
  1,
  'dynamic center projection'
)

local movedAgain = transition(centerG, centerF.id, 5)
assertEqual(movedAgain.byRecord['record/shared'], nil, 'aggregate removal after cell leaves scope')
assertEqual(movedAgain.staticContentFiles[1], nil, 'static content union removal')
assertEqual(
  movedAgain.currentExteriorCellObjects.byRecord['record/shared'],
  nil,
  'empty center projection'
)
assertEqual(
  movedAgain.currentExteriorCellObjects.byRecord['record/f-dynamic'],
  nil,
  'empty center projection dynamic records'
)
assertEqual(movedAgain.cellHasHostileActors, false, 'new center hostility')
assertEqual(movedAgain.areaHasHostileActors, true, 'retained hostile neighbor')

local dynamicAdjacent = {
  id = 'g-adjacent-dynamic',
  recordId = 'record/g-adjacent',
  type = types.Static,
  cell = cells[cellKey(3, 0)],
}
staticCollection.engineHandlers.onObjectActive(dynamicAdjacent)

local adjacentPresence
for _ = 1, 40 do
  staticCollection.engineHandlers.onUpdate()
  adjacentPresence = storageValues[player.id]
  if adjacentPresence.byRecord['record/g-adjacent'] then break end
end
assertEqual(adjacentPresence.byRecord['record/g-adjacent'], 1, 'adjacent aggregate presence')
assertEqual(
  adjacentPresence.currentExteriorCellObjects.byRecord['record/g-adjacent'],
  nil,
  'adjacent center projection isolation'
)

local dynamicHostile = {
  id = 'g-dynamic-hostile',
  recordId = 'record/g-hostile',
  type = types.NPC,
  fight = 100,
  hostile = true,
  count = 1,
  position = zeroPosition,
  isValid = function() return true end,
  cell = centerG,
}
staticCollection.engineHandlers.onObjectActive(dynamicHostile)

local hostilePresence
for _ = 1, 40 do
  staticCollection.engineHandlers.onUpdate()
  hostilePresence = storageValues[player.id]
  if hostilePresence.currentExteriorCellObjects.byRecord['record/g-hostile'] then break end
end
assertEqual(hostilePresence.cellHasHostileActors, true, 'dynamic center hostility')
assertEqual(hostilePresence.areaHasHostileActors, true, 'dynamic area hostility')

local cleared = transition(centerH, centerG.id, 6)
assertEqual(cleared.byRecord['record/g-hostile'], nil, 'dynamic hostile removal from leaving cell')
assertEqual(cleared.cellHasHostileActors, false, 'empty center after hostile removal')
assertEqual(cleared.areaHasHostileActors, false, 'empty area after hostile removal')

local dynamicHostileCenter = {
  id = 'h-dynamic-hostile',
  recordId = 'record/h-hostile',
  type = types.NPC,
  fight = 100,
  hostile = true,
  count = 1,
  position = zeroPosition,
  isValid = function() return true end,
  cell = centerH,
}
staticCollection.engineHandlers.onObjectActive(dynamicHostileCenter)

local hostileCenterPresence
for _ = 1, 40 do
  staticCollection.engineHandlers.onUpdate()
  hostileCenterPresence = storageValues[player.id]
  if hostileCenterPresence.currentExteriorCellObjects.byRecord['record/h-hostile'] then break end
end
assertEqual(hostileCenterPresence.cellHasHostileActors, true, 'dynamic hostile center promotion')
assertEqual(hostileCenterPresence.areaHasHostileActors, true, 'dynamic hostile area promotion')
assertEqual(quitCalled, false, 'presence collection should not quit')

print 'S3maphore presence collection tests passed'
