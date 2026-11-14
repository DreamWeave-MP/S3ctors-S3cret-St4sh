local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/sss_instance_pipeline%.lua$' or '.'

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

local TEL_BRANORA = { id = 'tel branora', name = 'Tel Branora', isExterior = false }

local questStage = 0
local pendingActivations = {}
local createdRecordIds = {}
local createdObjects = {}
local placementsBeforeFailure
local sentGlobalEvents = {}
local globalEventsFail = false
local nextObjectIndex = 0

local knownRecords = {
  flora_muckspunge_03 = true,
  ck_disturbed_mucksponge = true,
  selfie = true,
  crate = true,
}

local objectType = { records = {}, inventory = function(object) return object.inventory end }
local lockableType = {
  records = {},
  setTrapSpell = function(object, trapId) object.trapId = trapId end,
  setKeyRecord = function(object, keyId) object.keyId = keyId end,
}

local function newObject(recordId, cell, type)
  nextObjectIndex = nextObjectIndex + 1

  local object = {
    id = ('@%d'):format(nextObjectIndex),
    recordId = recordId,
    cell = cell,
    count = 1,
    enabled = true,
    owner = {},
    type = type or objectType,
  }

  function object:isValid() return true end
  function object:setScale() end
  function object:remove() self.count = 0 end
  function object:hasScript() return false end
  function object:moveInto(inventory) inventory.items[#inventory.items + 1] = self end
  function object:teleport(targetCell)
    if placementsBeforeFailure then
      if placementsBeforeFailure == 0 then error 'the cell refused the object' end
      placementsBeforeFailure = placementsBeforeFailure - 1
    end

    self.cell = targetCell
    pendingActivations[#pendingActivations + 1] = self
  end

  return object
end

local player = newObject('player', TEL_BRANORA)

local moduleSources = {
  ['scripts/staticswitcher/data/broken.yaml'] = function() error 'yaml: bad indentation' end,
  ['scripts/staticswitcher/data/empty.yaml'] = function() return nil end,
  ['scripts/staticswitcher/data/mucksponge.yaml'] = function()
    return {
      instances = {
        {
          conditions = {
            { has_journal = { quest = 'ck_daedric_detective', index = 50 } },
            { cell = { 'tel branora' } },
            { record_id = 'flora_muckspunge_03' },
          },
          actions = { { replace = { ck_disturbed_mucksponge = 1 } }, { delete = true } },
          once = true,
        },
        {
          conditions = {
            { has_journal = { quest = 'ck_daedric_detective', min = 60 } },
            { cell = { 'Tel Branora' } },
            { record_id = 'ck_disturbed_mucksponge' },
          },
          actions = { { replace = { flora_muckspunge_03 = 1 } }, { delete = true } },
          once = true,
        },
      },
    }
  end,
  ['scripts/staticswitcher/data/pipeline.yaml'] = function()
    return {
      instances = {
        {
          conditions = { { cell = 'TEL BRANORA' }, { record_id = 'ownable' } },
          actions = { { set_ownership = { owner = 'marked' } } },
        },
        {
          conditions = { { record_id = 'thrower' }, { scale = { min = 1 } } },
          actions = { { set_ownership = { owner = 'marked' } } },
        },
        {
          conditions = { { record_id = 'herald' } },
          actions = { { send_global_event = { name = 'HeraldArrived' } } },
          once = true,
        },
        {
          conditions = { { record_id = 'fragile' } },
          actions = { { replace = { crate = 1 } } },
          once = true,
        },
        {
          conditions = { { record_id = 'sturdy' } },
          actions = {
            { replace = { crate = 1 } },
            { send_global_event = { name = 'SturdyReplaced' } },
          },
          once = true,
        },
        {
          conditions = { { record_id = 'doomed' } },
          actions = { { replace = { crate = 1 } }, { disable = true } },
        },
        {
          conditions = { { record_id = 'hoarder' } },
          actions = { { add = { 'crate', 'no_such_record' } } },
          once = true,
        },
        {
          conditions = { { record_id = 'spawner' } },
          actions = { { create = { crate = 3 } } },
          once = true,
        },
        {
          conditions = { { record_id = 'partial' } },
          actions = {
            { set_ownership = { owner = 'marked' } },
            { global_set = { name = 'unknownglobal', value = 1 } },
          },
          once = true,
        },
        {
          conditions = { { record_id = '^selfie$' } },
          actions = { { replace = 'self' } },
          once = true,
        },
        {
          conditions = { { record_id = 'trapped' }, { global_value = { { gamehour = 5 } } } },
          actions = { { trap = { { trap_fire00 = 1 } }, key = { { Key_Mixed = 1 } } } },
        },
        {
          conditions = { { record_id = 'locationless' } },
          actions = { { set_ownership = { owner = 'marked' } } },
        },
        {
          conditions = { { record_id = 'missing_target' } },
          actions = { { replace = { no_such_record = 1 } } },
        },
      },
    }
  end,
  ['scripts/staticswitcher/data/rejected.yaml'] = function()
    return {
      instances = {
        { conditions = { { cel = 'Tel Branora' } }, actions = { { delete = true } } },
        { conditions = { { record_id = '[unclosed' } }, actions = { { delete = true } } },
        { conditions = { { record_id = 'ownable' } }, actions = { { explode = true } } },
        { conditions = { { ['not'] = { nope = true } } }, actions = { { delete = true } } },
        { conditions = { { cell = 'Tel Branora' } }, actions = { { add_tag = 'kept' } } },
        { conditions = { { cell = 'tel branora' } }, actions = { { add_tag = 'kept' } } },
        { actions = { { create = { crate = { count = { min = 3 } } } } } },
        { actions = { { create = { crate = { count = { min = 5, max = 2 } } } } } },
        { actions = { { create = { crate = { position = { x = { min = -5 } } } } } } },
        { actions = { { transform = { rotate = { z = { min = 3 } } } } } },
        { actions = { { lock_level = { min = 9, max = 2 } } } },
        { actions = { { add = { gold_001 = { count = { min = 2 } } } } } },
        { actions = { { trap = { { trap_fire00 = { min = 0.2 } } } } } },
        { actions = { { teleport = { position = { x = { min = 1 } } } } } },
        { actions = { { global_set = { name = 'someglobal', value = { min = 1 } } } } },
        { actions = { { create = 'crate' } } },
        { actions = { { create = { crate = { scale = { max = 'bad' } } } } } },
        { actions = { { create = { crate = { transform_type = 'reltaive' } } } } },
        { actions = { { transform = { scale = 2, transform_type = 'sideways' } } } },
      },
    }
  end,
}

package.preload['openmw.core'] = function()
  return {
    getGameTime = function() return 0 end,
    getRealTime = function() return 1 end,
    magic = { spells = { records = {} } },
    sendGlobalEvent = function(eventName)
      sentGlobalEvents[#sentGlobalEvents + 1] = eventName
      if globalEventsFail then error 'the event could not be serialized' end
    end,
  }
end
package.preload['openmw.interfaces'] = function()
  return { Settings = { registerGroup = function() end } }
end
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
package.preload['openmw.types'] = function()
  local function neverInstance() return false end

  return {
    Actor = { objectIsInstance = neverInstance },
    Container = { objectIsInstance = function(object) return object.isContainer == true end },
    Creature = { TYPE = {} },
    Door = {},
    Player = {
      objectIsInstance = neverInstance,
      quests = function()
        return setmetatable({}, {
          __index = function(_, questId)
            if questId == 'ck_daedric_detective' then return { stage = questStage } end
          end,
        })
      end,
    },
    Static = { objectIsInstance = neverInstance },
  }
end
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
    createObject = function(recordId)
      if not knownRecords[recordId] then error(('no record %s'):format(recordId)) end

      createdRecordIds[#createdRecordIds + 1] = recordId

      local object = newObject(recordId)
      createdObjects[#createdObjects + 1] = object
      return object
    end,
    createRecord = function() end,
    mwscript = {
      getGlobalVariables = function()
        return setmetatable({ gamehour = 12 }, {
          __newindex = function(_, name) error(('No global variable %s'):format(name)) end,
        })
      end,
    },
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

--- A handler that only computes has no boundary of its own; this one can be made to fail the
--- way a programming error would, to show where such an error ends up.
local actionHandlersUnderTest = require 'Scripts.staticSwitcher.actionHandlers'
local disableHandler = actionHandlersUnderTest.disable
local disableRaises = false
actionHandlersUnderTest.disable = function(object, disableAction)
  if disableRaises then error 'a programming error' end
  return disableHandler(object, disableAction)
end

local staticSwitcher = require 'Scripts.staticSwitcher.global'
local handlers = staticSwitcher.engineHandlers
local ruleStore = staticSwitcher.interface.objectModificationStore()

local function activate(object) pendingActivations[#pendingActivations + 1] = object end

local function runFrames(frameCount)
  for _ = 1, frameCount do
    local activations = pendingActivations
    pendingActivations = {}

    for activationIndex = 1, #activations do
      handlers.onObjectActive(activations[activationIndex])
    end

    handlers.onUpdate()
  end
end

local function countCreated(recordId)
  local count = 0
  for createdIndex = 1, #createdRecordIds do
    if createdRecordIds[createdIndex] == recordId then count = count + 1 end
  end
  return count
end

-- Module loading: failures are isolated and invalid rules are rejected whole.
assert(countLogLines 'Skipped module scripts/staticswitcher/data/broken%.yaml' == 1)
assert(countLogLines 'Skipped module scripts/staticswitcher/data/empty%.yaml' == 1)
assert(ruleStore['scripts/staticswitcher/data/broken.yaml'] == nil)
assert(ruleStore['scripts/staticswitcher/data/empty.yaml'] == nil)
assert(#ruleStore['scripts/staticswitcher/data/mucksponge.yaml'].rules == 2)
assert(#ruleStore['scripts/staticswitcher/data/pipeline.yaml'].rules == 13)

local keptRules = ruleStore['scripts/staticswitcher/data/rejected.yaml'].rules
assert(#keptRules == 2, 'rules with unknown names or malformed patterns must be skipped')
assert(countLogLines 'Skipped rule 1 in .-rejected%.yaml: unknown condition "cel"' == 1)
assert(countLogLines 'Skipped rule 2 in .-rejected%.yaml: record_id "%[unclosed"' == 1)
assert(countLogLines 'Skipped rule 3 in .-rejected%.yaml: unknown action "explode"' == 1)
assert(countLogLines 'Skipped rule 4 in .-rejected%.yaml: unknown condition "nope"' == 1)

assert(
  countLogLines 'Skipped rule 7 in .-rejected%.yaml: create pool "crate" has a count range without a usable max'
    == 1
)
assert(
  countLogLines 'Skipped rule 8 in .-rejected%.yaml: create pool "crate" has a count range without a usable max'
    == 1
)
assert(
  countLogLines 'Skipped rule 9 in .-rejected%.yaml: create pool "crate" has a position range without max'
    == 1
)
assert(
  countLogLines 'Skipped rule 10 in .-rejected%.yaml: transform has a rotate range without max' == 1
)
assert(
  countLogLines 'Skipped rule 11 in .-rejected%.yaml: lock_level has a range without a usable max'
    == 1
)
assert(
  countLogLines 'Skipped rule 12 in .-rejected%.yaml: add "gold_001" has a count range without a usable max'
    == 1
)
assert(
  countLogLines 'Skipped rule 13 in .-rejected%.yaml: trap entry 1 needs a record ID and a chance'
    == 1
)
assert(
  countLogLines 'Skipped rule 14 in .-rejected%.yaml: teleport has a position range without max'
    == 1
)
assert(
  countLogLines 'Skipped rule 15 in .-rejected%.yaml: global_set has a value range without max' == 1
)
assert(
  countLogLines 'Skipped rule 16 in .-rejected%.yaml: create needs a map of record IDs to pools'
    == 1
)
assert(
  countLogLines 'Skipped rule 17 in .-rejected%.yaml: create pool "crate" has a scale that is not a number or range'
    == 1
)
assert(
  countLogLines 'Skipped rule 18 in .-rejected%.yaml: create pool "crate" has unknown transform_type "reltaive"'
    == 1
)
assert(
  countLogLines 'Skipped rule 19 in .-rejected%.yaml: transform has unknown transform_type "sideways"'
    == 1
)

-- `cell` is lowered for matching, but the hash still reflects the authored casing.
assert(keptRules[1].conditions[1].cell == 'tel branora')
assert(keptRules[2].conditions[1].cell == 'tel branora')
assert(keptRules[1].actionHash ~= keptRules[2].actionHash)

-- Lowercase single-entry keys survive load; mixed-case keys are lowered.
local trapRule = ruleStore['scripts/staticswitcher/data/pipeline.yaml'].rules[11]
assert(trapRule.actions[1].trap[1].trap_fire00 == 1)
assert(trapRule.actions[1].key[1].key_mixed == 1)
assert(trapRule.actions[1].key[1].Key_Mixed == nil)

-- An object taken out of the world while queued is skipped without blocking the queue.
local firstOwnable = newObject('ownable', TEL_BRANORA)
local carriedOwnable = newObject('ownable', nil)
local carriedLocationless = newObject('locationless', nil)
local lastOwnable = newObject('ownable', TEL_BRANORA)
activate(firstOwnable)
activate(carriedOwnable)
activate(carriedLocationless)
activate(lastOwnable)
runFrames(4)
assert(firstOwnable.owner.recordId == 'marked')
assert(lastOwnable.owner.recordId == 'marked')
assert(carriedOwnable.owner.recordId == nil)
assert(carriedLocationless.owner.recordId == nil, 'rules must not run on an object with no cell')
assert(countLogLines '%[ERROR%] Skipped @' == 0)

-- A condition that raises is reported for its object and does not block later objects.
local queuedBehindThrower = newObject('ownable', TEL_BRANORA)
activate(queuedBehindThrower)
activate(newObject('thrower', TEL_BRANORA))
runFrames(4)
assert(queuedBehindThrower.owner.recordId == 'marked')
assert(countLogLines '%[ERROR%] Skipped @%d+ %(thrower%)' == 1)

-- An action that raises is skipped on its own: the rule's other actions apply, the failure is
-- reported once however many objects hit it, and `once` is recorded for what did apply.
local firstPartial = newObject('partial', TEL_BRANORA)
local secondPartial = newObject('partial', TEL_BRANORA)
activate(firstPartial)
activate(secondPartial)
runFrames(4)
assert(firstPartial.owner.recordId == 'marked' and secondPartial.owner.recordId == 'marked')
assert(countLogLines '%[WARN%] Action global_set failed and was skipped' == 1)

firstPartial.owner.recordId = nil
activate(firstPartial)
runFrames(4)
assert(firstPartial.owner.recordId == nil, 'a once rule that partly failed must not replay')

-- A create that fails part-way keeps what it placed, removes what it could not place, and
-- counts as applied, so a once rule does not create the same objects again.
local spawner = newObject('spawner', TEL_BRANORA)
placementsBeforeFailure = 2
activate(spawner)
runFrames(6)
placementsBeforeFailure = nil

assert(countCreated 'crate' == 3)
assert(createdObjects[1].cell == TEL_BRANORA and createdObjects[2].cell == TEL_BRANORA)
assert(
  createdObjects[3].cell == nil and createdObjects[3].count == 0,
  'the unplaced crate was left behind'
)
assert(countLogLines '%[WARN%] create: "crate" could not be placed' == 1)

activate(spawner)
runFrames(6)
assert(countCreated 'crate' == 3, 'a once rule whose create partly failed must not replay')

-- An event that could not be sent did not apply, so a once rule tries again next time.
local herald = newObject('herald', TEL_BRANORA)
globalEventsFail = true
activate(herald)
runFrames(4)
globalEventsFail = false
assert(#sentGlobalEvents == 1)
assert(countLogLines '%[WARN%] Action send_global_event failed and was skipped' == 1)

activate(herald)
runFrames(4)
assert(#sentGlobalEvents == 2, 'a failed send must not use up once: true')

activate(herald)
runFrames(4)
assert(#sentGlobalEvents == 2, 'a successful send is recorded')

-- A replacement the engine refuses to place is removed, the original is left as it was, and
-- a rule that did nothing but replace is not recorded, so it replaces on the next attempt.
local fragile = newObject('fragile', TEL_BRANORA)
local createdBeforeFragile = #createdObjects
placementsBeforeFailure = 0
activate(fragile)
runFrames(4)
placementsBeforeFailure = nil

local unplacedReplacement = createdObjects[createdBeforeFragile + 1]
assert(fragile.enabled == true, 'the original was disabled although its replacement failed')
assert(unplacedReplacement.cell == nil and unplacedReplacement.count == 0)
assert(countLogLines '%[WARN%] Action placement failed and was skipped' == 1)

activate(fragile)
runFrames(4)
assert(
  #createdObjects == createdBeforeFragile + 2,
  'a replacement that never happened used up once'
)
assert(fragile.enabled == false)
assert(createdObjects[createdBeforeFragile + 2].cell == TEL_BRANORA)

-- A rule that also did something else is recorded even though its replacement failed: the
-- event went out and must not go out again.
local sturdy = newObject('sturdy', TEL_BRANORA)
local eventsBeforeSturdy, createdBeforeSturdy = #sentGlobalEvents, #createdObjects
placementsBeforeFailure = 0
activate(sturdy)
runFrames(4)
placementsBeforeFailure = nil
assert(#sentGlobalEvents == eventsBeforeSturdy + 1 and sturdy.enabled == true)

activate(sturdy)
runFrames(4)
assert(#sentGlobalEvents == eventsBeforeSturdy + 1 and #createdObjects == createdBeforeSturdy + 1)

-- An error that is not an engine refusal is reported as an error, and a replacement begun
-- before it is rolled back: the original is untouched and nothing is left outside a cell.
local doomed = newObject('doomed', TEL_BRANORA)
local createdBeforeDoomed = #createdObjects
disableRaises = true
activate(doomed)
runFrames(4)
disableRaises = false

local abandonedReplacement = createdObjects[createdBeforeDoomed + 1]
assert(doomed.enabled == true, 'an interrupted rule left its original disabled')
assert(abandonedReplacement.cell == nil and abandonedReplacement.count == 0)
assert(countLogLines '%[ERROR%] Skipped @%d+ %(doomed%).-a programming error' == 1)

-- An item action that the engine accepts in part reports what it added and does not add it
-- again.
local hoarder = newObject('hoarder', TEL_BRANORA)
hoarder.isContainer, hoarder.inventory = true, { items = {} }
activate(hoarder)
runFrames(4)
assert(#hoarder.inventory.items == 1 and hoarder.inventory.items[1].recordId == 'crate')
assert(countLogLines '%[WARN%] "no_such_record" was refused' == 1)

activate(hoarder)
runFrames(4)
assert(#hoarder.inventory.items == 1, 'the accepted item was added a second time')

-- Lowercase trap, key, and global names apply instead of clearing the lock data.
local trapped = newObject('trapped', TEL_BRANORA, lockableType)
activate(trapped)
runFrames(4)
assert(trapped.trapId == 'trap_fire00')
assert(trapped.keyId == 'key_mixed')

-- A replacement naming a missing record warns once, however many objects hit it.
activate(newObject('missing_target', TEL_BRANORA))
activate(newObject('missing_target', TEL_BRANORA))
runFrames(4)
assert(
  countLogLines '%[WARN%] replace: could not create an object from record "no_such_record"' == 1
)

-- `once: true` follows the replacement, so self-replacement happens exactly once.
activate(newObject('selfie', TEL_BRANORA))
runFrames(40)
assert(countCreated 'selfie' == 1, 'once: true self-replacement must not repeat')

-- The reported two-rule quest swap settles instead of replacing back and forth.
local activatedObjects, activatedById = {}, {}
local onObjectActive = handlers.onObjectActive
handlers.onObjectActive = function(object)
  if not activatedById[object.id] then
    activatedById[object.id] = true
    activatedObjects[#activatedObjects + 1] = object
  end

  return onObjectActive(object)
end

local function findLiveObjects()
  local liveObjects = {}

  for objectIndex = 1, #activatedObjects do
    local object = activatedObjects[objectIndex]
    if object.count >= 1 and object.enabled and object.cell then
      liveObjects[#liveObjects + 1] = object
    end
  end

  return liveObjects
end

local originalFlora = newObject('flora_muckspunge_03', TEL_BRANORA)
activate(originalFlora)
runFrames(10)
assert(countCreated 'ck_disturbed_mucksponge' == 0, 'rule 1 must wait for the journal stage')

questStage = 50
activate(originalFlora)
runFrames(40)
assert(countCreated 'ck_disturbed_mucksponge' == 1)
assert(originalFlora.count == 0, 'the separate delete action removes the replaced original')

local liveAtStageFifty = findLiveObjects()
assert(#liveAtStageFifty == 1 and liveAtStageFifty[1].recordId == 'ck_disturbed_mucksponge')

-- Re-entering the cell at the later stage reactivates the disturbed sponge.
questStage = 60
activate(liveAtStageFifty[1])
runFrames(200)
assert(countCreated 'flora_muckspunge_03' == 1, 'the restored flora must not be swapped again')
assert(countCreated 'ck_disturbed_mucksponge' == 1, 'rule 1 must not fire on the restored flora')

local liveAtStageSixty = findLiveObjects()
assert(#liveAtStageSixty == 1 and liveAtStageSixty[1].recordId == 'flora_muckspunge_03')

assert(countLogLines '%[ERROR%] Skipped @' == 2, 'only the two deliberately failing rules may fail')

print = realPrint
print 'SSS instance pipeline tests passed'
