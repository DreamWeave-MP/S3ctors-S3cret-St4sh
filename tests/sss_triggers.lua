local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/sss_triggers%.lua$' or '.'

package.path = table.concat({
  ('%s/content/h3lp_yours3lf/?.lua'):format(root),
  ('%s/content/static_switching_system/?.lua'):format(root),
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
local recordingRaises = false

--- OpenMW queues a move and applies it at the end of the frame; so do these stubs.
local engineActions = {}

local function applyEngineActions()
  local actions = engineActions
  engineActions = {}

  for actionIndex = 1, #actions do
    actions[actionIndex]()
  end
end

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
openmwTypes.Door = newType 'Door'
openmwTypes.Door.isTeleport = function(door) return door.destinationCell ~= nil end
openmwTypes.Door.destCell = function(door) return door.destinationCell end
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
  local cellKey = ('%d,%d'):format(gridX, gridY)
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
    id = ('@%d'):format(nextObjectIndex),
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
  function fields.addScript(_, scriptPath)
    if fields.refusesScripts then error 'this actor cannot hold scripts' end
    fields.scripts[scriptPath] = true
  end
  function fields.teleport(_, targetCell)
    if fields.refusesTeleport then error 'the engine refused the teleport' end
    engineActions[#engineActions + 1] = function() fields.cell = targetCell end
  end
  function fields.remove() fields.count = 0 end

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

    local arrivalRule = probeRule('cell_enter', { { cell = 'Cell 5 5' } })
    arrivalRule.once = true
    arrivalRule.actions[1].call_interface.args = { 'arrival' }

    local visitNineRule = probeRule('cell_enter', { { cell = 'cell 9 9' } })
    visitNineRule.actions[1].call_interface.args = { 'entered-9' }
    local visitTwelveRule = probeRule('cell_enter', { { cell = 'cell 12 12' } })
    visitTwelveRule.actions[1].call_interface.args = { 'entered-12' }

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
        arrivalRule,
        probeRule('cell_enter', { { cell = 'cell 6 6' } }),
        {
          trigger = 'cell_enter',
          conditions = { { cell = 'cell 7 7' } },
          actions = {
            {
              call_interface = {
                interface = 'TestProbe',
                ['function'] = 'record',
                args = { 'sent-east' },
              },
            },
            { teleport = { cell = { x = 8, y = 8 } } },
          },
        },
        {
          trigger = 'cell_enter',
          conditions = { { cell = 'cell 8 8' } },
          actions = {
            {
              call_interface = {
                interface = 'TestProbe',
                ['function'] = 'record',
                args = { 'sent-west' },
              },
            },
            { teleport = { cell = { x = 7, y = 7 } } },
          },
        },
        {
          trigger = 'hour',
          conditions = { { object_type = 'Activator' }, { record_id = 'sweepbell' } },
          actions = { { call_interface = { interface = 'TestProbe', ['function'] = 'refire' } } },
        },
        {
          conditions = { { record_id = 'activebell' } },
          actions = { { call_interface = { interface = 'TestProbe', ['function'] = 'refire' } } },
        },
        probeRule('hour', {
          { object_type = 'Miscellaneous' },
          { record_id = 'livecheck' },
          { has_journal = { quest = 'q1', min = 10 } },
        }),
        {
          trigger = 'custom:farweather',
          actions = { { set_weather = { weather = 'storm', region = 'far region' } } },
        },
        probeRule('custom:indoors', { { region = 'far region' } }),
        visitNineRule,
        visitTwelveRule,
        {
          trigger = 'use',
          conditions = { { used_item = '^relocator' } },
          actions = { { teleport = { cell = { x = 12, y = 12 } } } },
          once = true,
        },
        {
          trigger = 'use',
          conditions = { { used_item = '^cursed' } },
          actions = { { delete = true }, { disable = true }, { replace = 'self' } },
        },
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
        { trigger = 'cell_enter', actions = { { delete = true } } },
        { trigger = { 'active', 'cell_enter' }, actions = { { replace = 'self' } } },
        probeRule({ 'custom:double', 'custom:double' }, { { record_id = 'bell' } }),
        probeRule('custom:badtype', { { object_type = 'NoSuchType' } }),
        {
          trigger = 'custom:badweather',
          actions = { { set_weather = { region = 'far region' } } },
        },
        {
          trigger = 'custom:badcall',
          actions = { { call_interface = { interface = 'TestProbe' } } },
        },
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
        weatherChanges[#weatherChanges + 1] = ('%s=%s'):format(regionId, weather.recordId)
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
    createObject = function(recordId) error(('no record %s'):format(recordId)) end,
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

  --- Recording a rule is the last thing a pass does, after its move has been accepted. Making
  --- it fail shows what happens to a pass that goes wrong at that point.
  local logger = require 'Scripts.staticSwitcher.logger'
  local debugLog = logger.debug
  logger.debug = function(formatString, ...)
    if recordingRaises and formatString:find('once=true cached', 1, true) then
      error 'a programming error after the move'
    end

    return debugLog(formatString, ...)
  end

  return require 'Scripts.staticSwitcher.global'
end

local staticSwitcher, handlers

local function runFrames(frameCount, dt)
  for _ = 1, frameCount do
    simulationTime = simulationTime + dt
    handlers.onUpdate(dt)
    applyEngineActions()
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
assert(
  countLogLines 'Skipped rule 8 in .-rejected%.yaml: action "delete" is not available on trigger "cell_enter"'
    == 1
)
assert(
  countLogLines 'Skipped rule 9 in .-rejected%.yaml: action "replace" is not available on trigger "cell_enter"'
    == 1
)

assert(
  countLogLines 'Skipped rule 10 in .-rejected%.yaml: trigger "custom:double" is listed twice' == 1
)
assert(countLogLines 'Skipped rule 11 in .-rejected%.yaml: unknown object_type "NoSuchType"' == 1)
assert(
  countLogLines 'Skipped rule 12 in .-rejected%.yaml: set_weather needs a weather record ID' == 1
)
assert(countLogLines 'Skipped rule 13 in .-rejected%.yaml: call_interface needs an interface' == 1)

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
settle()
assert(countProbes('hour', clock) == 1)
assert(countProbes('hour', distantClock) == 1, 'adjacent exterior cells are swept')
assert(countProbes('hour', unreachableClock) == 0, 'cells beyond the adjacent ring are not swept')
assert(countProbes 'both' == 2)
assert(countProbes('day', calendar) == 1)
assert(countProbes('hour', plain) == 0 and countProbes('day', clock) == 0)
assert(typedEnumerations == 18, 'the hour sweep enumerates only the two types its rules name')
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
  runFrames(20, 0.05)
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

-- Removing actions never apply to the player, whichever trigger put the player in their path.
simulationTime = simulationTime + 1
onItemUsed(newObject('cursed_ring', nil, openmwTypes.Miscellaneous), player)
assert(player.count == 1 and player.enabled == true)

-- Cell entry: the rule runs on the player, once per entry; `once: true` makes it once ever.
assert(countProbes 'arrival' == 0 and countProbes 'cell_enter' == 0)

player.cell = getExteriorCell(5, 5)
settle()
assert(countProbes('arrival', player) == 1)

player.cell = getExteriorCell(6, 6)
settle()
settle()
assert(countProbes('cell_enter', player) == 1, 'standing in a cell is one entry')

player.cell = getExteriorCell(5, 5)
settle()
player.cell = getExteriorCell(6, 6)
settle()
assert(countProbes 'arrival' == 1, 'once: true survives leaving and returning')
assert(countProbes 'cell_enter' == 2, 'a rule without once runs on every entry')

player.cell = HOME_CELL
settle()

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
assert(countLogLines 'Trigger "custom:ping" was fired while a rule was running' == 1)

assert(staticSwitcher.interface.trigger('unheard', bell) == false)
assert(staticSwitcher.interface.trigger('ping', 'not an object') == false)
assert(staticSwitcher.interface.trigger('ping', newObject('bell', nil)) == false)

simulationTime = simulationTime + 1
staticSwitcher.eventHandlers.StaticSwitcherTrigger { name = 'ping', object = bell }
assert(countProbes('custom:ping', bell) == 2)

-- A malformed public event is ignored, not raised.
staticSwitcher.eventHandlers.StaticSwitcherTrigger(nil)
staticSwitcher.eventHandlers.StaticSwitcherTrigger 'ping'
staticSwitcher.eventHandlers.StaticSwitcherTrigger { name = 7, object = bell }
staticSwitcher.eventHandlers.StaticSwitcherTrigger { name = 'ping' }
assert(countProbes('custom:ping', bell) == 2)

-- Two different items used by one actor are two events; the same item twice is one.
simulationTime = simulationTime + 1
local usesBefore = countProbes 'use'
local firstPotion = newObject('potion_custom_a', nil, openmwTypes.Potion)
onItemUsed(firstPotion, player)
onItemUsed(newObject('potion_custom_b', nil, openmwTypes.Potion), player)
onItemUsed(firstPotion, player)
assert(countProbes 'use' - usesBefore == 2)

-- A burst larger than the debounce table keeps every recent entry.
simulationTime = simulationTime + 1
local firstOfBurst = newObject('bell', HOME_CELL)
assert(staticSwitcher.interface.trigger('ping', firstOfBurst) == true)
for _ = 1, 600 do
  staticSwitcher.interface.trigger('ping', newObject('bell', HOME_CELL))
end
assert(
  staticSwitcher.interface.trigger('ping', firstOfBurst) == false,
  'a recent entry was evicted'
)

-- A trigger fired from a rule's own actions is refused whichever path is running the rule:
-- an activation, a world sweep, or another trigger.
local refusedBefore = countProbes 'refire-refused'
handlers.onObjectActive(newObject('activebell', HOME_CELL))
settle()
assert(countProbes 'refire-refused' - refusedBefore == 1, 'activation let a rule fire a trigger')

newObject('sweepbell', HOME_CELL, openmwTypes.Activator)
gameTime = gameTime + 3600
settle()
settle()
assert(countProbes 'refire-refused' - refusedBefore == 2, 'a sweep let a rule fire a trigger')
assert(countProbes 'refired' == 0)

-- Sweep conditions see the world as it is on the frame they run, not as it was at the start.
for _ = 1, 40 do
  newObject('livecheck', HOME_CELL, openmwTypes.Miscellaneous)
end
questStages.q1 = 10
settle()
gameTime = gameTime + 3600

local function countLiveChecks()
  local count = 0
  for callIndex = 1, #probeCalls do
    local call = probeCalls[callIndex]
    if call.tag == 'hour' and call.object.recordId == 'livecheck' then count = count + 1 end
  end
  return count
end

for _ = 1, 400 do
  runFrames(1, 0.25)
  if countLiveChecks() > 0 then break end
end

local checkedBeforeChange = countLiveChecks()
assert(checkedBeforeChange > 0 and checkedBeforeChange < 40)

questStages.q1 = 0
settle()
settle()
assert(
  countLiveChecks() == checkedBeforeChange,
  'a sweep kept using the quest stage it started with'
)

-- The same weather requested again for the same region is one engine call, but only for a
-- while: a later request must still go through.
simulationTime = simulationTime + 1
local weatherChangesBefore = #weatherChanges
staticSwitcher.interface.trigger('farweather', newObject('anything', HOME_CELL))
simulationTime = simulationTime + 1
staticSwitcher.interface.trigger('farweather', newObject('anything', HOME_CELL))
assert(#weatherChanges - weatherChangesBefore == 1)

simulationTime = simulationTime + 30
staticSwitcher.interface.trigger('farweather', newObject('anything', HOME_CELL))
assert(#weatherChanges - weatherChangesBefore == 2)

-- An interior with exits into two regions belongs to whichever exit is nearer.
local function newPosition(x)
  return setmetatable({ x = x }, {
    __sub = function(a, b)
      local distance = a.x - b.x
      return { length2 = function() return distance * distance end }
    end,
  })
end

local interior = newCell(0, 0, nil)
interior.id, interior.isExterior = 'two-door cave', false

local westDoor = newObject('door', interior, openmwTypes.Door)
westDoor.position, westDoor.destinationCell = newPosition(0), HOME_CELL
local eastDoor = newObject('door', interior, openmwTypes.Door)
eastDoor.position, eastDoor.destinationCell = newPosition(1000), getExteriorCell(10, 0)

local nearWestDoor = newObject('crate', interior)
nearWestDoor.position = newPosition(100)
local nearEastDoor = newObject('crate', interior)
nearEastDoor.position = newPosition(900)

staticSwitcher.interface.trigger('indoors', nearWestDoor)
staticSwitcher.interface.trigger('indoors', nearEastDoor)
assert(countProbes('custom:indoors', nearWestDoor) == 0)
assert(countProbes('custom:indoors', nearEastDoor) == 1)

-- Arriving where an SSS teleport sent the player is not a cell entry, so two rules that send
-- the player to each other's cells do not chase each other.
player.cell = getExteriorCell(7, 7)
settle()
settle()
assert(countProbes 'sent-east' == 1 and countProbes 'sent-west' == 0)
assert(player.cell == getExteriorCell(8, 8))

-- A teleport the engine refused sent the player nowhere, so walking into that cell later is
-- an ordinary entry and its rule runs.
player.cell = HOME_CELL
settle()
player.refusesTeleport = true
player.cell = getExteriorCell(7, 7)
settle()
settle()
player.refusesTeleport = nil
assert(countProbes 'sent-east' == 2 and player.cell == getExteriorCell(7, 7))
assert(countLogLines '%[WARN%] Action placement failed and was skipped' == 1)

player.cell = getExteriorCell(8, 8)
settle()
settle()
assert(countProbes 'sent-west' == 1, 'a failed teleport left a stale arrival to ignore')

player.cell = HOME_CELL
settle()

-- A player moved by a pass that then failed turns up at the destination before being put
-- back. Neither that arrival nor the return is a cell entry. The pass is started by using an
-- item, outside the frame's own poll, so the arrival is there to be seen on the next poll.
player.cell = getExteriorCell(9, 9)
settle()
assert(countProbes 'entered-9' == 1)

recordingRaises = true
simulationTime = simulationTime + 1
onItemUsed(newObject('relocator', nil, openmwTypes.Miscellaneous), player)
recordingRaises = false
applyEngineActions()
assert(player.cell == getExteriorCell(12, 12), 'the accepted move did not happen')
assert(countLogLines '%[ERROR%] Skipped @%d+ %(player%)' == 1)

runFrames(1, 0.5)
assert(countProbes 'entered-12' == 0, 'the intermediate arrival was treated as an entry')
assert(player.cell == getExteriorCell(9, 9), 'the player was not put back')

runFrames(8, 0.5)
assert(countProbes 'entered-9' == 1, 'being put back was treated as an entry')
assert(countProbes 'entered-12' == 0)

player.cell = getExteriorCell(12, 12)
runFrames(2, 0.5)
assert(countProbes 'entered-12' == 1, 'entries stopped counting after the player was put back')

player.cell = HOME_CELL
settle()

-- One actor that cannot be watched does not end death watching for the rest.
local unwatchable = newObject('rat', HOME_CELL, openmwTypes.Creature)
unwatchable.refusesScripts = true
local laterRat = newObject('rat', HOME_CELL, openmwTypes.Creature)
local alsoUnwatchable = newObject('rat', HOME_CELL, openmwTypes.Creature)
alsoUnwatchable.refusesScripts = true
handlers.onObjectActive(unwatchable)
handlers.onObjectActive(alsoUnwatchable)
handlers.onObjectActive(laterRat)
assert(laterRat:hasScript(DEATH_WATCHER_SCRIPT))
assert(countLogLines '%[WARN%] The death of rat cannot be watched' == 1)

assert(countLogLines '%[ERROR%]' == 1, 'only the deliberately failing pass may fail')

print = realPrint
print 'SSS trigger tests passed'
