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
local removalsRefused = false
local removeCalls = 0

--- OpenMW does not carry out a move, a rescale or an inventory transfer when a script asks for
--- it. It checks the request, queues it, and applies the queue at the end of the frame. Until
--- then a moving object reports a count of zero, cannot be moved again, and cannot be removed.
--- These stubs behave the same way, so nothing here passes merely because a request and its
--- effect happen to coincide.
local engineActions = {}

local function queueEngineAction(action) engineActions[#engineActions + 1] = action end

local function applyEngineActions()
  local actions = engineActions
  engineActions = {}

  for actionIndex = 1, #actions do
    actions[actionIndex]()
  end
end
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
    scale = 1,
    teleportCount = 0,
    type = type or objectType,
  }

  function object:isValid() return true end
  function object:hasScript() return false end

  function object:setScale(scale)
    queueEngineAction(function() self.scale = scale end)
  end

  function object:remove()
    removeCalls = removeCalls + 1

    if removalsRefused then error 'the engine kept the object' end
    if self.count < 1 then error 'Can\'t remove 0 of 0 items' end

    self.count = 0
  end

  function object:moveInto(inventory)
    if inventory.refusesItems then error 'the inventory is full' end

    local count = self.count
    self.count = 0

    queueEngineAction(function()
      self.count = count
      inventory.items[#inventory.items + 1] = self
    end)
  end

  function object:teleport(targetCell)
    if self.count < 1 then
      error 'Object is either removed or already in the process of teleporting'
    end

    if placementsBeforeFailure then
      if placementsBeforeFailure == 0 then error 'the cell refused the object' end
      placementsBeforeFailure = placementsBeforeFailure - 1
    end

    local count = self.count
    self.count = 0
    self.teleportCount = self.teleportCount + 1

    queueEngineAction(function()
      self.count = count
      self.cell = targetCell

      if not self.arrivesSilently then pendingActivations[#pendingActivations + 1] = self end
    end)
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
          conditions = { { record_id = 'ephemeral' } },
          actions = { { replace = { crate = 1 }, set_ownership = { owner = 'marked' } } },
          once = true,
        },
        {
          conditions = { { record_id = 'stretchy' } },
          actions = { { transform = { scale = 2 } } },
          once = true,
        },
        {
          conditions = { { record_id = 'noisy' } },
          actions = { { send_global_event = { name = 'OnceExpected' }, disable = true } },
          once = true,
        },
        {
          conditions = { { record_id = 'clingy' } },
          actions = { { replace = { crate = 1 } } },
        },
        {
          conditions = { { record_id = 'brittle' } },
          actions = { { transform = { scale = 2 }, disable = true } },
          once = true,
        },
        {
          conditions = { { record_id = 'condemned' } },
          actions = { { transform = { scale = 2 }, delete = true } },
          once = true,
        },
        {
          conditions = { { record_id = 'jinxed' } },
          actions = { { replace = { crate = 1 }, delete = true } },
          once = true,
        },
        {
          conditions = { { record_id = 'litterer' } },
          actions = { { create = { crate = 1 } } },
        },
        {
          conditions = { { record_id = 'pickpocketed' } },
          actions = { { remove = { gold_001 = 5 } } },
          once = true,
        },
        {
          conditions = { { record_id = 'butterfingers' } },
          actions = { { add = { 'crate' } } },
          once = true,
        },
        {
          conditions = { { record_id = 'wanderer' } },
          actions = { { transform = { scale = 2 }, delete = true } },
          once = true,
        },
        {
          conditions = { { record_id = 'evictee' } },
          actions = { { delete = true } },
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
        { actions = { { transform = { scale = { min = 5 } } } } },
        { actions = { { transform = { scale = { min = 3, max = 2 } } } } },
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
    getCellById = function(cellId)
      if cellId ~= TEL_BRANORA.id then error(('no cell %s'):format(cellId)) end
      return TEL_BRANORA
    end,
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

--- The delete queue is the last thing a pass touches; making it fail shows what happens when
--- the final step of a commit goes wrong after placement has already been accepted.
local deleteManagerUnderTest = require 'Scripts.staticSwitcher.deleteManager'
local addObjectToDeleteQueue = deleteManagerUnderTest.addObjectToDeleteQueue
local deleteQueueRaises = false
deleteManagerUnderTest.addObjectToDeleteQueue = function(self, object, removeOrDisable)
  if deleteQueueRaises then error 'the delete queue is unavailable' end
  return addObjectToDeleteQueue(self, object, removeOrDisable)
end

--- Objects in this test are tables, not engine userdata, so the check a loaded save is held to
--- is pointed at what stands in for an object here.
require('Scripts.staticSwitcher.util').isGObject = function(value)
  return type(value) == 'table' and value.recordId ~= nil
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
    applyEngineActions()
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
assert(#ruleStore['scripts/staticswitcher/data/pipeline.yaml'].rules == 25)

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
  countLogLines 'Skipped rule 17 in .-rejected%.yaml: create pool "crate" has a scale range without a usable max'
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
assert(
  countLogLines 'Skipped rule 20 in .-rejected%.yaml: transform has a scale range without a usable max'
    == 1
)
assert(
  countLogLines 'Skipped rule 21 in .-rejected%.yaml: transform has a scale range without a usable max'
    == 1
)

-- `cell` is lowered for matching, but the hash still reflects the authored casing.
assert(keptRules[1].conditions[1].cell == 'tel branora')
assert(keptRules[2].conditions[1].cell == 'tel branora')
assert(keptRules[1].actionHash ~= keptRules[2].actionHash)

-- Lowercase single-entry keys survive load; mixed-case keys are lowered.
local trapRule = ruleStore['scripts/staticswitcher/data/pipeline.yaml'].rules[23]
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
local thrower = newObject('thrower', TEL_BRANORA)
thrower.scale = nil
activate(thrower)
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

-- What a rule did to a replacement is gone when the replacement is discarded, so it does not
-- count: the rule stays eligible and replaces on the next attempt.
local ephemeral = newObject('ephemeral', TEL_BRANORA)
local createdBeforeEphemeral = #createdObjects
placementsBeforeFailure = 0
activate(ephemeral)
runFrames(4)
placementsBeforeFailure = nil
assert(ephemeral.enabled == true and #createdObjects == createdBeforeEphemeral + 1)

activate(ephemeral)
runFrames(4)
assert(
  #createdObjects == createdBeforeEphemeral + 2,
  'work on a discarded replacement used up once'
)
assert(createdObjects[createdBeforeEphemeral + 2].owner.recordId == 'marked')
assert(ephemeral.enabled == false)

-- A transform the engine refuses leaves the object's scale as it was, so a relative scale
-- does not compound when the rule runs again.
local stretchy = newObject('stretchy', TEL_BRANORA)
placementsBeforeFailure = 0
activate(stretchy)
runFrames(4)
placementsBeforeFailure = nil
assert(stretchy.scale == 1, 'a refused transform left its scale behind')

activate(stretchy)
runFrames(4)
assert(stretchy.scale == 2)

activate(stretchy)
runFrames(4)
assert(stretchy.scale == 2, 'a once transform ran again after succeeding')

-- An effect that cannot be taken back is recorded when it happens, so an error later in the
-- same rule does not let it happen twice.
local noisy = newObject('noisy', TEL_BRANORA)
local eventsBeforeNoisy = #sentGlobalEvents
disableRaises = true
activate(noisy)
runFrames(4)
disableRaises = false
assert(#sentGlobalEvents == eventsBeforeNoisy + 1)
assert(countLogLines '%[ERROR%] Skipped @%d+ %(noisy%)' == 1)

activate(noisy)
runFrames(4)
assert(#sentGlobalEvents == eventsBeforeNoisy + 1, 'an event already sent was sent again')

-- A replacement the engine will neither place nor remove is reported and remembered, and is
-- removed as soon as the engine allows it.
local clingy = newObject('clingy', TEL_BRANORA)
local createdBeforeClingy = #createdObjects
placementsBeforeFailure, removalsRefused = 0, true
activate(clingy)
runFrames(4)
placementsBeforeFailure, removalsRefused = nil, false

local strandedReplacement = createdObjects[createdBeforeClingy + 1]
assert(clingy.enabled == true)
assert(strandedReplacement.cell == nil and strandedReplacement.count == 1)
assert(countLogLines '%[WARN%] A stray crate could not be removed and will be retried' == 1)

activate(clingy)
runFrames(4)
assert(strandedReplacement.count == 0, 'a replacement whose removal failed was forgotten')
assert(clingy.enabled == false)

-- Disabling and deleting are part of the commit: when placement is refused they do not happen,
-- and the rule stays eligible.
local brittle = newObject('brittle', TEL_BRANORA)
placementsBeforeFailure = 0
activate(brittle)
runFrames(4)
placementsBeforeFailure = nil
assert(brittle.enabled == true, 'disabled although its placement was refused')
assert(brittle.scale == 1)

activate(brittle)
runFrames(4)
assert(brittle.scale == 2 and brittle.enabled == false)

local condemned = newObject('condemned', TEL_BRANORA)
placementsBeforeFailure = 0
activate(condemned)
runFrames(12)
placementsBeforeFailure = nil
assert(condemned.count == 1, 'deleted although its placement was refused')
assert(condemned.scale == 1)

activate(condemned)
runFrames(12)
assert(condemned.count == 0)

-- A move the engine has accepted cannot be called off. When a pass fails after its replacement
-- is already on its way, the replacement is removed once it has landed and the original is
-- left as it was: nothing extra materialises.
local jinxed = newObject('jinxed', TEL_BRANORA)
local createdBeforeJinxed = #createdObjects
deleteQueueRaises = true
activate(jinxed)
runFrames(6)
deleteQueueRaises = false

local straggler = createdObjects[createdBeforeJinxed + 1]
assert(straggler.teleportCount == 1, 'the replacement was not yet on its way when the pass failed')
assert(straggler.count == 0, 'a replacement materialised after its pass was abandoned')
assert(jinxed.enabled == true and jinxed.count == 1)
assert(countLogLines '%[ERROR%] Skipped @%d+ %(jinxed%)' == 1)

activate(jinxed)
runFrames(12)
assert(#createdObjects == createdBeforeJinxed + 2 and jinxed.count == 0)

-- An original that was disabled before the pass is still disabled after the pass is abandoned.
local dormant = newObject('jinxed', TEL_BRANORA)
dormant.enabled = false
deleteQueueRaises = true
activate(dormant)
runFrames(6)
deleteQueueRaises = false
assert(dormant.enabled == false, 'an abandoned pass enabled an object that had been disabled')
assert(dormant.count == 1)

-- An object that was itself moved by a pass that then failed is put back once the move has
-- landed, and its rule can still run.
local wanderer = newObject('wanderer', TEL_BRANORA)
wanderer.arrivesSilently = true
deleteQueueRaises = true
activate(wanderer)
runFrames(1)
deleteQueueRaises = false
assert(wanderer.teleportCount == 1 and wanderer.scale == 2, 'the accepted move did not happen')

runFrames(6)
assert(wanderer.teleportCount == 2, 'a moved object was not put back after its pass failed')
assert(wanderer.scale == 1 and wanderer.cell == TEL_BRANORA and wanderer.count == 1)

activate(wanderer)
runFrames(12)
assert(wanderer.scale == 2 and wanderer.count == 0, 'the rule did not stay eligible')

-- Removals the engine keeps refusing are worked off a few per frame however many are waiting,
-- and each is given up after a fixed number of tries.
local STRAY_OBJECTS = 300
local removeCallsBeforeBacklog = removeCalls
placementsBeforeFailure, removalsRefused = 0, true
for _ = 1, STRAY_OBJECTS do
  activate(newObject('litterer', TEL_BRANORA))
end

local mostRemovalsInOneFrame = 0
for _ = 1, 900 do
  local removeCallsBeforeFrame = removeCalls
  runFrames(1)
  mostRemovalsInOneFrame = math.max(mostRemovalsInOneFrame, removeCalls - removeCallsBeforeFrame)
end
placementsBeforeFailure, removalsRefused = nil, false

assert(mostRemovalsInOneFrame <= 8, 'removal attempts in one frame grew with the backlog')
assert(
  removeCalls - removeCallsBeforeBacklog == STRAY_OBJECTS * 8,
  'a refused removal was retried without limit'
)
assert(countLogLines '%[WARN%] Gave up: a stray crate was never removed' == 1)

local removeCallsAfterBacklog = removeCalls
runFrames(20)
assert(removeCalls == removeCallsAfterBacklog, 'given-up removals were still being retried')

-- A delayed deletion whose target is being moved when its turn comes waits for the target to
-- land. A zero count is what a moving object reports, not proof that it is gone.
local evictee = newObject('evictee', TEL_BRANORA)
activate(evictee)
runFrames(2)
evictee.count = 0
runFrames(4)
evictee.count = 1
runFrames(3)
assert(evictee.count == 0, 'a deletion was dropped because its target was in transit')

-- Corrections still owed when the game is saved are saved with it and carried out after
-- loading: a removal, and a move back to a cell that is saved by ID.
local ObjectCleanup = require 'Scripts.staticSwitcher.objectCleanup'

local createdBeforeKeepsake = #createdObjects
placementsBeforeFailure, removalsRefused = 0, true
activate(newObject('litterer', TEL_BRANORA))
runFrames(2)
placementsBeforeFailure = nil

local keepsake = createdObjects[createdBeforeKeepsake + 1]
assert(keepsake.count == 1)

local drifter = newObject('wanderer', TEL_BRANORA)
drifter.arrivesSilently = true
deleteQueueRaises = true
activate(drifter)
runFrames(1)
deleteQueueRaises = false
assert(drifter.scale == 2, 'the accepted move did not happen')

local savedCorrections = handlers.onSave().pendingCorrections
assert(#savedCorrections == 2)

local savedRemoval, savedReturn = savedCorrections[1], savedCorrections[2]
assert(savedRemoval.object == keepsake and savedRemoval.cellId == nil)
assert(savedReturn.object == drifter and savedReturn.cellId == TEL_BRANORA.id)
assert(savedReturn.cell == nil, 'a cell cannot be written to a save')

ObjectCleanup.loadCorrections(nil)
removalsRefused = false
runFrames(4)
assert(keepsake.count == 1 and drifter.scale == 2, 'corrections ran without having been loaded')

ObjectCleanup.loadCorrections(savedCorrections)
runFrames(4)
assert(keepsake.count == 0, 'a saved removal was not carried out after loading')
assert(drifter.scale == 1 and drifter.teleportCount == 2, 'a saved move back was not carried out')

ObjectCleanup.loadCorrections {
  'junk',
  { object = 'not an object' },
  { object = keepsake, cellId = 'nowhere' },
}
assert(not ObjectCleanup.hasPending(), 'a correction that cannot be carried out was kept')

-- A delayed deletion the engine refuses is reported and dropped; the queue keeps working.
local stubborn = newObject('condemned', TEL_BRANORA)
activate(stubborn)
runFrames(2)
removalsRefused = true
runFrames(10)
removalsRefused = false
assert(stubborn.count == 1)
assert(countLogLines '%[WARN%] A queued removal was refused and dropped' == 1)

local compliant = newObject('condemned', TEL_BRANORA)
activate(compliant)
runFrames(12)
assert(compliant.count == 0, 'the delete queue stopped working after a refused removal')

-- A created object that can be neither placed nor removed is kept for another attempt, the
-- same way a replacement is.
local litterer = newObject('litterer', TEL_BRANORA)
local createdBeforeLitterer = #createdObjects
placementsBeforeFailure, removalsRefused = 0, true
activate(litterer)
runFrames(4)
placementsBeforeFailure, removalsRefused = nil, false

local strandedCrate = createdObjects[createdBeforeLitterer + 1]
assert(strandedCrate.cell == nil and strandedCrate.count == 1)

activate(newObject('ownable', TEL_BRANORA))
runFrames(4)
assert(strandedCrate.count == 0, 'a created object whose removal failed was forgotten')

-- A removal spread over several stacks reports what it removed before a stack was refused,
-- so a once rule does not take the same items again.
local firstStack, secondStack = { count = 3 }, { count = 10 }
function firstStack:remove(removeCount) self.count = self.count - removeCount end
function secondStack:remove() error 'the stack is locked' end

local pocket = {}
function pocket:countOf() return firstStack.count + secondStack.count end
function pocket:findAll() return { firstStack, secondStack } end

local pickpocketed = newObject('pickpocketed', TEL_BRANORA)
pickpocketed.isContainer, pickpocketed.inventory = true, pocket
activate(pickpocketed)
runFrames(4)
assert(firstStack.count == 0 and secondStack.count == 10)
assert(countLogLines '%[WARN%] "gold_001" could not be removed from an inventory' == 1)

firstStack.count = 3
activate(pickpocketed)
runFrames(4)
assert(firstStack.count == 3, 'a partly completed removal ran again')

-- An item the inventory refuses is removed again, not left outside any cell.
local butterfingers = newObject('butterfingers', TEL_BRANORA)
butterfingers.isContainer = true
butterfingers.inventory = { items = {}, refusesItems = true }
local createdBeforeButterfingers = #createdObjects
activate(butterfingers)
runFrames(4)
assert(#butterfingers.inventory.items == 0)
assert(createdObjects[createdBeforeButterfingers + 1].count == 0)
assert(countLogLines '%[WARN%] "crate" could not be put in an inventory' == 1)

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

assert(
  countLogLines '%[ERROR%] Skipped @' == 7,
  'only the seven deliberately failing passes may fail'
)

print = realPrint
print 'SSS instance pipeline tests passed'
