local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/sss_triggers%.lua$' or '.'

package.path = table.concat({
  root .. '/content/h3lp_yours3lf/?.lua',
  root .. '/content/static_switching_system/?.lua',
  package.path,
}, ';')

local bit = require 'bit'

local logLines = {}
local realPrint = print
local echoLog = os.getenv 'SSS_TEST_VERBOSE' ~= nil
print = function(message)
  logLines[#logLines + 1] = tostring(message)
  if echoLog then realPrint(message) end
end

local function countLogLines(pattern)
  local count = 0
  for lineIndex = 1, #logLines do
    if logLines[lineIndex]:find(pattern) then count = count + 1 end
  end
  return count
end

local DEATH_WATCHER_SCRIPT = 'scripts/staticSwitcher/deathWatcher.lua'

local gameTime = 0
local simulationTime = 0
local questStages = {}
local regionWeather = {}
local weatherChanges = {}
local probeCalls = {}
local activationHandlers = {}
local itemUsageHandlers = {}
local typedEnumerations, untypedEnumerations = 0, 0
local nextObjectIndex = 0

local function newType(name)
  local objectType = { name = name, records = {} }
  function objectType.objectIsInstance(object) return object.type == objectType end
  return objectType
end

local openmwTypes = {
  Activator = newType 'Activator',
  Creature = newType 'Creature',
  Miscellaneous = newType 'Miscellaneous',
  NPC = newType 'NPC',
  Player = newType 'Player',
  Potion = newType 'Potion',
  Static = newType 'Static',
}
openmwTypes.Creature.TYPE = {}
openmwTypes.Door = {}
openmwTypes.Container = { objectIsInstance = function() return false end }
openmwTypes.Actor = {
  objectIsInstance = function(object)
    return object.type == openmwTypes.NPC
      or object.type == openmwTypes.Creature
      or object.type == openmwTypes.Player
  end,
  isDead = function(object) return object.isDead == true end,
}
openmwTypes.Player.quests = function()
  local quests = {}
  for questId, stage in pairs(questStages) do
    quests[questId] = { stage = stage }
  end
  return quests
end

local function newCell(gridX, gridY, region)
  local cell = {
    id = ('cell %d %d'):format(gridX, gridY),
    name = '',
    isExterior = true,
    region = region,
    gridX = gridX,
    gridY = gridY,
    objects = {},
  }

  function cell:getAll(objectType)
    if objectType then
      typedEnumerations = typedEnumerations + 1
    else
      untypedEnumerations = untypedEnumerations + 1
    end

    local objects = {}
    for objectIndex = 1, #self.objects do
      local object = self.objects[objectIndex]
      if not objectType or object.type == objectType then objects[#objects + 1] = object end
    end
    return objects
  end

  return cell
end

local exteriorCells = {}
local function getExteriorCell(gridX, gridY)
  local cellKey = gridX .. ',' .. gridY
  local cell = exteriorCells[cellKey]

  if not cell then
    cell = newCell(gridX, gridY, gridX >= 10 and 'far region' or 'west gash')
    exteriorCells[cellKey] = cell
  end

  return cell
end

local HOME_CELL = getExteriorCell(0, 0)
local NEIGHBOUR_CELL = getExteriorCell(1, -1)
local OUT_OF_RANGE_CELL = getExteriorCell(3, 0)

--- Objects are userdata proxies, as in OpenMW, so identity checks on the public entry points hold.
local function newObject(recordId, cell, objectType)
  nextObjectIndex = nextObjectIndex + 1

  local fields = {
    __type = { name = 'MWLua::GObject' },
    id = '@' .. nextObjectIndex,
    recordId = recordId,
    cell = cell,
    count = 1,
    enabled = true,
    owner = {},
    type = objectType or openmwTypes.Static,
    scripts = {},
  }

  function fields.isValid() return true end
  function fields.setScale() end
  function fields.hasScript(_, scriptPath) return fields.scripts[scriptPath] == true end
  function fields.addScript(_, scriptPath) fields.scripts[scriptPath] = true end

  local object = newproxy(true)
  local metatable = getmetatable(object)
  metatable.__index = fields
  metatable.__newindex = fields

  if cell then cell.objects[#cell.objects + 1] = object end

  return object
end

local player = newObject('player', HOME_CELL, openmwTypes.Player)

local function probeRule(triggerName, conditions)
  return {
    trigger = triggerName,
    conditions = conditions,
    actions = {
      {
        call_interface = {
          interface = 'TestProbe',
          ['function'] = 'record',
          args = { triggerName },
        },
      },
    },
  }
end

local activeOnlyModules = {
  ['scripts/staticswitcher/data/plain.yaml'] = function()
    return {
      instances = {
        {
          conditions = { { record_id = 'plain' } },
          actions = {
            {
              call_interface = {
                interface = 'TestProbe',
                ['function'] = 'record',
                args = { 'active' },
              },
            },
          },
        },
      },
    }
  end,
}

local triggerModules = {
  ['scripts/staticswitcher/data/plain.yaml'] = activeOnlyModules['scripts/staticswitcher/data/plain.yaml'],
  ['scripts/staticswitcher/data/triggers.yaml'] = function()
    local bothRule = probeRule(
      { 'active', 'hour' },
      { { object_type = 'Activator' }, { record_id = 'both' } }
    )
    bothRule.actions[1].call_interface.args = { 'both' }

    local weatherRule = probeRule('weather', { { record_id = 'vane' } })
    weatherRule.actions[2] = { set_weather = 'storm' }

    local pingRule = probeRule('custom:ping', { { record_id = 'bell' } })
    pingRule.actions[2] = { call_interface = { interface = 'TestProbe', ['function'] = 'refire' } }

    return {
      instances = {
        probeRule('hour', { { object_type = 'Activator' }, { record_id = 'clock' } }),
        bothRule,
        probeRule('day', { { record_id = 'calendar' } }),
        probeRule(
          'journal',
          { { has_journal = { quest = 'q1', min = 10 } }, { record_id = 'questprop' } }
        ),
        probeRule(
          'journal',
          { { has_journal = { quest = 'flap', min = 0 } }, { record_id = 'flapper' } }
        ),
        weatherRule,
        probeRule('activate', { { record_id = 'lever' }, { by_player = true } }),
        probeRule('use', { { used_item = '^Potion' }, { by_player = true } }),
        probeRule('death', { { record_id = 'rat' } }),
        pingRule,
        probeRule('drop', { { record_id = 'coin' } }),
        probeRule('place', { { record_id = 'coin' } }),
      },
    }
  end,
  ['scripts/staticswitcher/data/rejected.yaml'] = function()
    return {
      instances = {
        probeRule('bogus', { { record_id = 'plain' } }),
        probeRule('journal', { { record_id = 'plain' } }),
        probeRule('active', { { by_player = true } }),
        probeRule('activate', { { used_item = 'potion' } }),
        probeRule({}, { { record_id = 'plain' } }),
        probeRule('custom:', { { record_id = 'plain' } }),
        probeRule({ 'use', 'death' }, { { ['not'] = { by_player = true } } }),
      },
    }
  end,
}

local moduleSources = activeOnlyModules
local interfaces = { Settings = { registerGroup = function() end } }

package.preload['openmw.core'] = function()
  return {
    getGameTime = function() return gameTime end,
    getRealTime = function() return 1 end,
    getSimulationTime = function() return simulationTime end,
    magic = { spells = { records = {} } },
    sendGlobalEvent = function() end,
    weather = {
      records = {
        clear = { recordId = 'clear' },
        rain = { recordId = 'rain' },
        storm = { recordId = 'storm' },
      },
      getCurrent = function(cell) return regionWeather[cell.region] end,
      getNext = function() end,
      changeWeather = function(regionId, weather)
        weatherChanges[#weatherChanges + 1] = regionId .. '=' .. weather.recordId
        regionWeather[regionId] = weather
      end,
    },
  }
end
package.preload['openmw.interfaces'] = function() return interfaces end
package.preload['openmw.markup'] = function()
  return { decodeYaml = function(modulePath) return moduleSources[modulePath]() end }
end
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
    open = function(modulePath)
      return {
        close = function() end,
        read = function() return modulePath end,
      }
    end,
    pathsWithPrefix = function()
      local modulePaths = {}
      for modulePath in pairs(moduleSources) do
        modulePaths[#modulePaths + 1] = modulePath
      end

      local pathIndex = 0
      return function()
        pathIndex = pathIndex + 1
        return modulePaths[pathIndex]
      end
    end,
  }
end
package.preload['openmw.world'] = function()
  return {
    createObject = function(recordId) error('no record ' .. recordId) end,
    createRecord = function() end,
    getExteriorCell = getExteriorCell,
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
      local scored = {}
      for index = 1, #array do
        local score = scoreFn(array[index])
        if score then
          scored[#scored + 1] = { value = array[index], score = score, index = index }
        end
      end

      table.sort(scored, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.index < b.index
      end)

      local values = {}
      for index = 1, #scored do
        values[index] = scored[index].value
      end
      return values
    end,
  }
end

local function loadStaticSwitcher(sources)
  moduleSources = sources
  activationHandlers, itemUsageHandlers = {}, {}

  interfaces.Activation = {
    addHandlerForType = function(objectType, handler) activationHandlers[objectType] = handler end,
  }
  interfaces.ItemUsage = {
    addHandlerForType = function(objectType, handler) itemUsageHandlers[objectType] = handler end,
  }

  for moduleName in pairs(package.loaded) do
    if moduleName:find '^Scripts%.staticSwitcher%.' then package.loaded[moduleName] = nil end
  end

  return require 'Scripts.staticSwitcher.global'
end

local staticSwitcher, handlers

local function runFrames(frameCount, dt)
  for _ = 1, frameCount do
    simulationTime = simulationTime + dt
    handlers.onUpdate(dt)
  end
end

--- Enough frames for a poll to notice a change and for its sweep to start and finish.
local function settle() runFrames(40, 0.25) end

local function countProbes(tag, object)
  local count = 0
  for callIndex = 1, #probeCalls do
    local call = probeCalls[callIndex]
    if call.tag == tag and (object == nil or call.object == object) then count = count + 1 end
  end
  return count
end

interfaces.TestProbe = {
  record = function(object, tag) probeCalls[#probeCalls + 1] = { object = object, tag = tag } end,
  refire = function(object)
    probeCalls[#probeCalls + 1] = {
      object = object,
      tag = staticSwitcher.interface.trigger('ping', object) and 'refired' or 'refire-refused',
    }
  end,
}

-- With only `active` rules loaded, no trigger machinery is armed.
staticSwitcher = loadStaticSwitcher(activeOnlyModules)
handlers = staticSwitcher.engineHandlers

local unwatchedRat = newObject('rat', HOME_CELL, openmwTypes.Creature)
handlers.onObjectActive(unwatchedRat)
handlers.onObjectActive(newObject('plain', HOME_CELL))
gameTime = gameTime + 7200
settle()
assert(next(activationHandlers) == nil and next(itemUsageHandlers) == nil)
assert(not unwatchedRat:hasScript(DEATH_WATCHER_SCRIPT), 'no death rule, so no death script')
assert(typedEnumerations + untypedEnumerations == 0, 'no world trigger, so nothing is swept')
assert(countProbes 'active' == 1)

-- Reload with every trigger in use.
probeCalls = {}
staticSwitcher = loadStaticSwitcher(triggerModules)
handlers = staticSwitcher.engineHandlers
assert(staticSwitcher.interface.version == 6)

assert(countLogLines 'Skipped rule 1 in .-rejected%.yaml: unknown trigger "bogus"' == 1)
assert(
  countLogLines 'Skipped rule 2 in .-rejected%.yaml: trigger "journal" needs a has_journal' == 1
)
assert(
  countLogLines 'Skipped rule 3 in .-rejected%.yaml: condition "by_player" is not available on trigger "active"'
    == 1
)
assert(
  countLogLines 'Skipped rule 4 in .-rejected%.yaml: condition "used_item" is not available on trigger "activate"'
    == 1
)
assert(countLogLines 'Skipped rule 5 in .-rejected%.yaml: trigger is an empty list' == 1)
assert(countLogLines 'Skipped rule 6 in .-rejected%.yaml: unknown trigger "custom:"' == 1)
assert(
  countLogLines 'Skipped rule 7 in .-rejected%.yaml: condition "by_player" is not available on trigger "death"'
    == 1
)

-- Each rule runs only on the triggers it names; an untagged rule runs only on activation.
local plain = newObject('plain', HOME_CELL)
local clock = newObject('clock', HOME_CELL, openmwTypes.Activator)
local distantClock = newObject('clock', NEIGHBOUR_CELL, openmwTypes.Activator)
local unreachableClock = newObject('clock', OUT_OF_RANGE_CELL, openmwTypes.Activator)
local both = newObject('both', HOME_CELL, openmwTypes.Activator)
local calendar = newObject('calendar', HOME_CELL)
local questProp = newObject('questprop', HOME_CELL)
local vane = newObject('vane', HOME_CELL)

questStages.q1 = 5
questStages.flap = 0
regionWeather['west gash'] = { recordId = 'clear' }

for _, object in ipairs { plain, clock, both, calendar, questProp, vane } do
  handlers.onObjectActive(object)
end
settle()
assert(countProbes 'active' == 1 and countProbes('active', plain) == 1)
assert(countProbes 'both' == 1, 'a rule listing active and hour runs on activation')
assert(#probeCalls == 2, 'the first poll after a load records the world and fires nothing')

-- Time passing while paused is not polled.
gameTime = gameTime + 3600
runFrames(40, 0)
assert(countProbes 'hour' == 0)

-- A whole day passing in one step is one hour sweep and one day sweep.
typedEnumerations, untypedEnumerations = 0, 0
gameTime = gameTime + 86400
settle()
assert(countProbes('hour', clock) == 1)
assert(countProbes('hour', distantClock) == 1, 'adjacent exterior cells are swept')
assert(countProbes('hour', unreachableClock) == 0, 'cells beyond the adjacent ring are not swept')
assert(countProbes 'both' == 2)
assert(countProbes('day', calendar) == 1)
assert(countProbes('hour', plain) == 0 and countProbes('day', clock) == 0)
assert(typedEnumerations == 9, 'the hour sweep enumerates only the type its rules name')
assert(untypedEnumerations == 9, 'the day sweep leaves the type open')

-- A journal sweep fires for the watched quest only, once per stage change.
questStages.unrelated = 50
settle()
assert(countProbes 'journal' == 0)

questStages.q1 = 10
settle()
settle()
assert(countProbes('journal', questProp) == 1)

-- A weather change SSS made itself does not fire the weather trigger again.
regionWeather['west gash'] = { recordId = 'rain' }
settle()
settle()
assert(countProbes('weather', vane) == 1)
assert(#weatherChanges == 1 and weatherChanges[1] == 'west gash=storm')

-- Different weather because the player moved is not a weather change.
regionWeather['far region'] = { recordId = 'rain' }
player.cell = getExteriorCell(10, 0)
settle()
player.cell = HOME_CELL
settle()
assert(countProbes 'weather' == 1)

-- A sweep is budgeted per frame and waits behind the activation queue.
local clocks = { clock, distantClock }
for _ = 1, 98 do
  clocks[#clocks + 1] = newObject('clock', HOME_CELL, openmwTypes.Activator)
end

local sweepBudget = 16
local hourProbesBefore = countProbes 'hour'
gameTime = gameTime + 3600

local sawSweepStart = false
for _ = 1, 400 do
  local probesBeforeFrame = countProbes 'hour'
  runFrames(1, 0.25)
  local probesThisFrame = countProbes 'hour' - probesBeforeFrame

  assert(probesThisFrame <= sweepBudget, 'a frame ran more sweep objects than the budget')

  if probesThisFrame > 0 and not sawSweepStart then
    sawSweepStart = true

    for _ = 1, 8 do
      handlers.onObjectActive(newObject('plain', HOME_CELL))
    end

    local probesBeforeActivation = countProbes 'hour'
    runFrames(1, 0.25)
    assert(countProbes 'hour' == probesBeforeActivation, 'sweep ran ahead of the activation queue')

    -- The hour rolls over twice more while this sweep is still running.
    gameTime = gameTime + 7200
  end
end
assert(sawSweepStart)
assert(
  countProbes 'hour' - hourProbesBefore == 2 * #clocks,
  'two rollovers during a sweep must rerun it exactly once'
)

-- A trigger that keeps firing is suspended instead of sweeping forever.
local flapper = newObject('flapper', HOME_CELL)
for flip = 1, 12 do
  questStages.flap = flip
  runFrames(4, 0.25)
end
settle()
assert(countProbes('journal', flapper) == 4, 'the flapping quest may start four sweeps')
assert(countLogLines '%[WARN%] Trigger "journal:flap" fired more than 4 times' == 1)

-- Activation: registered through I.Activation, filtered by who activated.
local lever = newObject('lever', HOME_CELL, openmwTypes.Activator)
local npc = newObject('guard', HOME_CELL, openmwTypes.NPC)
local onActivated = assert(activationHandlers[openmwTypes.Activator])

assert(onActivated(lever, npc) == nil, 'the handler must not claim the activation')
assert(countProbes 'activate' == 0)

simulationTime = simulationTime + 1
onActivated(lever, player)
onActivated(lever, player)
assert(
  countProbes('activate', lever) == 1,
  'repeat activations inside the debounce window are dropped'
)

simulationTime = simulationTime + 1
onActivated(lever, player)
assert(countProbes('activate', lever) == 2)

-- Use: the rule runs on the actor, and the item is matched through used_item.
local potion = newObject('potion_healing', nil, openmwTypes.Potion)
local onItemUsed = assert(itemUsageHandlers[openmwTypes.Potion])
onItemUsed(potion, player)
assert(countProbes('use', player) == 1)

simulationTime = simulationTime + 1
onItemUsed(newObject('coin', nil, openmwTypes.Miscellaneous), player)
onItemUsed(potion, npc)
assert(countProbes 'use' == 1)

-- Drop and place.
local coin = newObject('coin', HOME_CELL, openmwTypes.Miscellaneous)
handlers.onDropped(coin, player)
handlers.onPlaced(coin, player)
assert(countProbes('drop', coin) == 1 and countProbes('place', coin) == 1)

-- Death: live actors are watched once a death rule exists; the relayed event runs the rule.
local rat = newObject('rat', HOME_CELL, openmwTypes.Creature)
local deadRat = newObject('rat', HOME_CELL, openmwTypes.Creature)
deadRat.isDead = true
handlers.onObjectActive(rat)
handlers.onObjectActive(deadRat)
handlers.onObjectActive(player)
assert(rat:hasScript(DEATH_WATCHER_SCRIPT))
assert(not deadRat:hasScript(DEATH_WATCHER_SCRIPT) and not player:hasScript(DEATH_WATCHER_SCRIPT))
assert(not lever:hasScript(DEATH_WATCHER_SCRIPT))

staticSwitcher.eventHandlers.StaticSwitcherActorDied(rat)
staticSwitcher.eventHandlers.StaticSwitcherActorDied 'not an object'
assert(countProbes('death', rat) == 1)

-- Custom triggers: by interface and by event; a trigger fired from inside a trigger is refused.
local bell = newObject('bell', HOME_CELL)
assert(staticSwitcher.interface.trigger('ping', bell) == true)
assert(countProbes('custom:ping', bell) == 1)
assert(countProbes 'refire-refused' == 1 and countProbes 'refired' == 0)
assert(countLogLines 'Trigger "custom:ping" was fired from inside another trigger' == 1)

assert(staticSwitcher.interface.trigger('unheard', bell) == false)
assert(staticSwitcher.interface.trigger('ping', 'not an object') == false)
assert(staticSwitcher.interface.trigger('ping', newObject('bell', nil)) == false)

simulationTime = simulationTime + 1
staticSwitcher.eventHandlers.StaticSwitcherTrigger { name = 'ping', object = bell }
assert(countProbes('custom:ping', bell) == 2)

assert(countLogLines '%[ERROR%]' == 0)

print = realPrint
print 'SSS trigger tests passed'
