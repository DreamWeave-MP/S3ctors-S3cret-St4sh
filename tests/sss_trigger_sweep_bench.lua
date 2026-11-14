--- Reports what world-trigger polling and sweeping cost in pure Lua.
--- Objects here are plain tables, so engine-side property access is not measured.
local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/sss_trigger_sweep_bench%.lua$' or '.'

package.path = table.concat({
  root .. '/content/h3lp_yours3lf/?.lua',
  root .. '/content/static_switching_system/?.lua',
  package.path,
}, ';')

local bit = require 'bit'

local OBJECT_COUNT = 5000
local RULE_COUNT = 50
local IDLE_FRAMES = 200000

local gameTime, simulationTime = 0, 0
local probeCount = 0
local rulesNameObjectType = false

local function newType()
  local objectType = { records = {} }
  function objectType.objectIsInstance(object) return object.type == objectType end
  return objectType
end

local openmwTypes = {
  Activator = newType(),
  Static = newType(),
  Player = newType(),
  Creature = { TYPE = {} },
  Door = {},
  Container = { objectIsInstance = function() return false end },
  Actor = { objectIsInstance = function() return false end },
}
openmwTypes.Player.quests = function() return {} end

local cell = { id = 'bench', name = 'Bench', isExterior = false, objects = {} }
function cell:getAll(objectType)
  if not objectType then return self.objects end

  local objects = {}
  for objectIndex = 1, #self.objects do
    local object = self.objects[objectIndex]
    if object.type == objectType then objects[#objects + 1] = object end
  end
  return objects
end

local function newObject(recordId, objectType)
  local object = {
    id = '@' .. (#cell.objects + 1),
    recordId = recordId,
    cell = cell,
    count = 1,
    enabled = true,
    owner = {},
    type = objectType,
  }
  function object:isValid() return true end
  function object:setScale() end

  cell.objects[#cell.objects + 1] = object
  return object
end

--- One object in ten is an Activator; one in a hundred is a rule's target, spread across
--- the whole list so a sweep has to reach the last object to finish.
for objectIndex = 1, OBJECT_COUNT do
  local isActivator = objectIndex % 10 == 0
  local isTarget = objectIndex % (OBJECT_COUNT / RULE_COUNT) == 0
  local recordId = isTarget and ('target_' .. objectIndex / (OBJECT_COUNT / RULE_COUNT))
    or ('filler_' .. objectIndex)

  newObject(recordId, isActivator and openmwTypes.Activator or openmwTypes.Static)
end

local player = { id = 'player', recordId = 'player', cell = cell, type = openmwTypes.Player }

local function buildModule()
  local instances = {}

  for ruleIndex = 1, RULE_COUNT do
    local conditions = { { record_id = '^target_' .. ruleIndex .. '$' } }
    if rulesNameObjectType then conditions[2] = { object_type = 'Activator' } end

    instances[ruleIndex] = {
      trigger = 'hour',
      conditions = conditions,
      actions = { { call_interface = { interface = 'Bench', ['function'] = 'probe' } } },
    }
  end

  return { instances = instances }
end

local interfaces = {
  Settings = { registerGroup = function() end },
  Bench = { probe = function() probeCount = probeCount + 1 end },
}

package.preload['openmw.core'] = function()
  return {
    getGameTime = function() return gameTime end,
    getRealTime = function() return 1 end,
    getSimulationTime = function() return simulationTime end,
    magic = { spells = { records = {} } },
    sendGlobalEvent = function() end,
    weather = { records = {} },
  }
end
package.preload['openmw.interfaces'] = function() return interfaces end
package.preload['openmw.markup'] = function() return { decodeYaml = buildModule } end
package.preload['openmw.storage'] = function()
  return {
    globalSection = function()
      return { get = function() return false end }
    end,
  }
end
package.preload['openmw.types'] = function() return openmwTypes end
package.preload['openmw.util'] = function()
  return {
    bitAnd = bit.band,
    bitXor = bit.bxor,
    makeReadOnly = function(value) return value end,
    transform = {},
  }
end
package.preload['openmw.vfs'] = function()
  return {
    fileExists = function() return true end,
    open = function()
      return { close = function() end, read = function() return '' end }
    end,
    pathsWithPrefix = function()
      local wasReturned = false
      return function()
        if wasReturned then return end
        wasReturned = true
        return 'scripts/staticswitcher/data/bench.yaml'
      end
    end,
  }
end
package.preload['openmw.world'] = function()
  return {
    createObject = function() error 'unused' end,
    createRecord = function() end,
    mwscript = { getGlobalVariables = function() return {} end },
    players = { player },
  }
end
package.preload['openmw_aux.calendar'] = function()
  return { formatGameTime = function() return '0' end }
end
package.preload['openmw_aux.util'] = function()
  return {
    deepToString = tostring,
    mapFilterSort = function(array, scoreFn)
      local values = {}
      for index = 1, #array do
        if scoreFn(array[index]) then values[#values + 1] = array[index] end
      end
      table.sort(values, function(a, b) return scoreFn(a) < scoreFn(b) end)
      return values
    end,
  }
end

local function loadHandlers()
  for moduleName in pairs(package.loaded) do
    if moduleName:find '^Scripts%.staticSwitcher%.' then package.loaded[moduleName] = nil end
  end

  return require('Scripts.staticSwitcher.global').engineHandlers
end

local function runFrame(handlers, dt)
  simulationTime = simulationTime + dt
  handlers.onUpdate(dt)
end

local function measureSweep(label)
  local handlers = loadHandlers()
  runFrame(handlers, 1)

  probeCount = 0
  gameTime = gameTime + 3600

  local snapshotStart = os.clock()
  runFrame(handlers, 1)
  local snapshotSeconds = os.clock() - snapshotStart

  local frameCount, slowestFrame = 0, 0
  local sweepStart = os.clock()

  repeat
    local frameStart = os.clock()
    runFrame(handlers, 1)
    slowestFrame = math.max(slowestFrame, os.clock() - frameStart)
    frameCount = frameCount + 1
  until probeCount == RULE_COUNT or frameCount > OBJECT_COUNT

  assert(probeCount == RULE_COUNT, label .. ': sweep did not reach every matching object')

  local sweepSeconds = os.clock() - sweepStart

  print(
    ('%-22s snapshot %6.3f ms; %4d frames, %6.3f ms mean, %6.3f ms slowest'):format(
      label,
      snapshotSeconds * 1000,
      frameCount,
      sweepSeconds / frameCount * 1000,
      slowestFrame * 1000
    )
  )
end

print(('%d objects, %d hour rules'):format(OBJECT_COUNT, RULE_COUNT))

rulesNameObjectType = false
measureSweep 'untyped rules'

rulesNameObjectType = true
measureSweep 'object_type prefilter'

local handlers = loadHandlers()
runFrame(handlers, 1)
runFrame(handlers, 1)

local idleStart = os.clock()
for _ = 1, IDLE_FRAMES do
  runFrame(handlers, 1 / 60)
end
print(
  ('%-22s %7.1f ns per frame over %d frames'):format(
    'armed, nothing changes',
    (os.clock() - idleStart) / IDLE_FRAMES * 1e9,
    IDLE_FRAMES
  )
)
