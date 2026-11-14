local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/horiz0n_controller%.lua$' or '.'

local PLAYER_SCRIPT = ('%s/content/horiz0n/scripts/s3/horiz0n/player.lua'):format(root)
local CELL_SIZE = 8192
local TARGET_FRAME_TIME = 1 / 60

local DEFAULT_SETTINGS = {
  Horiz0nToggle = true,
  Horiz0nTargetFramerate = 60,
  Horiz0nMinViewDistance = 0.25,
  Horiz0nMaxViewDistance = 25,
  Horiz0nAdjustFramerate = 30,
  Horiz0nPercentAdjustNormal = 10,
  Horiz0nPercentAdjustSevere = 30,
  Horiz0nViewDistanceStepPercent = 1,
  Horiz0nViewDistanceSevereMult = 2,
  Horiz0nGrowCooldown = 3,
}

---@class Horiz0nTestWorld
---@field affordableCells number view distance, in cells, the scene can render at the target framerate
---@field baseCells number OpenMW's configured viewing distance in cells
---@field clock number
---@field cell { isExterior: boolean, hasTag: fun(): boolean }
---@field engineDistance number
---@field externalDistance number? written to the engine by another mod before every frame
---@field frameTimeFloor number fastest frame the scene can produce regardless of view distance
---@field handlers table<string, function>
---@field history number[] every distinct distance written to the engine
---@field realFrameTime fun(): number
---@field settings table<string, boolean|number>
---@field subscriber fun(section: string?, key: string)
---@field timeScale number

---@param overrides { baseCells: number?, engineCells: number?, settings: table<string, boolean|number>? }?
---@return Horiz0nTestWorld
local function newWorld(overrides)
  overrides = overrides or {}

  local world = {
    affordableCells = 1000,
    baseCells = overrides.baseCells or 10,
    clock = 0,
    cell = { isExterior = true, hasTag = function() return false end },
    frameTimeFloor = TARGET_FRAME_TIME,
    history = {},
    settings = {},
    timeScale = 1,
  }
  world.engineDistance = (overrides.engineCells or world.baseCells) * CELL_SIZE

  for key, value in next, DEFAULT_SETTINGS do
    world.settings[key] = value
  end
  for key, value in next, overrides.settings or {} do
    world.settings[key] = value
  end

  local section = {}
  function section:get(key) return world.settings[key] end
  function section:subscribe(callback) world.subscriber = callback end

  local function realFrameTime()
    local loadFactor = world.engineDistance / (world.affordableCells * CELL_SIZE)
    return math.max(world.frameTimeFloor, TARGET_FRAME_TIME * loadFactor)
  end
  world.realFrameTime = realFrameTime

  local modules = {
    ['openmw.self'] = setmetatable(
      {},
      { __index = function(_, key) return key == 'cell' and world.cell or nil end }
    ),
    ['openmw.camera'] = {
      getBaseViewDistance = function() return world.baseCells * CELL_SIZE end,
      getViewDistance = function() return world.engineDistance end,
      setViewDistance = function(distance)
        assert(
          distance == distance and math.abs(distance) ~= math.huge,
          'engine rejects non-finite view distance'
        )
        if distance ~= world.engineDistance then world.history[#world.history + 1] = distance end
        world.engineDistance = distance
      end,
    },
    --- OpenMW's main loop multiplies the frame duration by the simulation time scale before Lua sees it.
    ['openmw.core'] = {
      getRealFrameDuration = function() return realFrameTime() * world.timeScale end,
      getRealTime = function() return world.clock end,
      getSimulationTimeScale = function() return world.timeScale end,
    },
    ['openmw.storage'] = { playerSection = function() return section end },
    ['openmw.async'] = { callback = function(_, callback) return callback end },
  }

  local chunk = assert(loadfile(PLAYER_SCRIPT))
  setfenv(
    chunk,
    setmetatable(
      { require = function(name) return assert(modules[name], name) end },
      { __index = _G }
    )
  )
  world.handlers = chunk().engineHandlers

  return world
end

---@param world Horiz0nTestWorld
---@param seconds number
---@param paused boolean?
---@return integer writes
local function run(world, seconds, paused)
  local elapsed, writesBefore = 0, #world.history

  while elapsed < seconds do
    if world.externalDistance then world.engineDistance = world.externalDistance end

    local frameTime = world.realFrameTime()
    world.clock = world.clock + frameTime
    world.handlers.onFrame(paused and 0 or frameTime * world.timeScale)
    elapsed = elapsed + frameTime
  end

  return #world.history - writesBefore
end

---@param world Horiz0nTestWorld
---@param key string
---@param value boolean|number
local function setSetting(world, key, value)
  world.settings[key] = value
  world.subscriber(nil, key)
end

---@param world Horiz0nTestWorld
---@return number cells
local function cells(world) return world.engineDistance / CELL_SIZE end

local failures, checks = 0, 0

---@param condition boolean
---@param message string
---@param ... string|number
local function check(condition, message, ...)
  checks = checks + 1
  if condition then return end

  failures = failures + 1
  print(('FAIL %s'):format(message:format(...)))
end

do
  local world = newWorld()
  local writes = run(world, 30)
  check(writes == 0, 'stable 60 FPS at the ceiling wrote %d times', writes)
  check(cells(world) == 10, 'stable at the ceiling ended at %.2f cells', cells(world))
end

do
  local world = newWorld()
  world.handlers.onLoad { viewDistance = 0.25 * CELL_SIZE }
  local writes = run(world, 10)
  check(
    writes > 0 and writes <= 41,
    'recovery from a low saved distance wrote %d times in 10s',
    writes
  )
  check(cells(world) < 10, 'recovery reached the ceiling within 10s: %.2f cells', cells(world))

  run(world, 600)
  check(cells(world) == 10, 'recovery never reached the ceiling: %.2f cells', cells(world))
end

do
  local world = newWorld()
  world.frameTimeFloor = 1 / 40
  run(world, 60)
  check(cells(world) == 0.25, 'unrelated 40 FPS bottleneck ended at %.2f cells', cells(world))

  local writes = run(world, 60)
  check(writes == 0, 'pinned at the minimum still wrote %d times', writes)
end

do
  local world = newWorld()
  run(world, 5)

  world.frameTimeFloor = 0.2
  world.handlers.onFrame(0.2)
  world.frameTimeFloor = TARGET_FRAME_TIME

  local writes = run(world, 5)
  check(writes == 0, 'one loading hitch wrote %d times', writes)
end

do
  local world = newWorld()
  world.affordableCells = 5
  run(world, 30)
  local settled = cells(world)
  check(settled < 5.6 and settled > 4.5, 'heavy area settled at %.2f cells', settled)

  local firstMinute = run(world, 60)
  local secondMinute = run(world, 60)
  check(firstMinute <= 12, 'failed probes wrote %d times in the first minute', firstMinute)
  check(secondMinute <= 4, 'backoff did not grow: %d writes in the second minute', secondMinute)
end

do
  local world = newWorld()
  world.affordableCells = 5
  run(world, 30)

  world.affordableCells = 1000
  local firstSecondAfterCooldown = run(world, 4)
  check(
    firstSecondAfterCooldown <= 8,
    'successful probes were not rate limited: %d writes in 4s',
    firstSecondAfterCooldown
  )

  run(world, 600)
  check(cells(world) == 10, 'successful probes never reached the ceiling: %.2f cells', cells(world))
end

for _, timeScale in next, { 0.5, 2 } do
  local world = newWorld()
  world.timeScale = timeScale
  local writes = run(world, 30)
  check(writes == 0, 'simulation scale %.1f at a real 60 FPS wrote %d times', timeScale, writes)
end

do
  local world = newWorld { baseCells = 0.125 }
  world.frameTimeFloor = 1 / 40
  local writes = run(world, 30)
  check(writes == 0, 'ceiling below the minimum wrote %d times', writes)
  check(cells(world) == 0.125, 'ceiling below the minimum ended at %.3f cells', cells(world))
end

do
  local world = newWorld()
  world.affordableCells = 5
  run(world, 30)
  local outdoors = cells(world)

  for _ = 1, 5 do
    world.cell.isExterior = false
    run(world, 1)
    check(cells(world) == 10, 'indoors was not maxed: %.2f cells', cells(world))

    world.cell.isExterior = true
    world.handlers.onFrame(TARGET_FRAME_TIME)
    check(
      math.abs(cells(world) - outdoors) < 0.01,
      'returning outdoors did not resume %.2f cells: %.2f',
      outdoors,
      cells(world)
    )
  end
end

do
  local world = newWorld()
  world.affordableCells = 5
  run(world, 30)

  setSetting(world, 'Horiz0nToggle', false)
  run(world, 1, true)
  check(cells(world) == 10, 'disabling did not restore OpenMW distance: %.2f cells', cells(world))

  world.engineDistance = 7 * CELL_SIZE
  local writes = run(world, 5)
  check(writes == 0, 'disabled Horiz0n wrote %d times over another distance', writes)

  world.engineDistance = 10 * CELL_SIZE
  setSetting(world, 'Horiz0nToggle', true)
  world.handlers.onFrame(0)
  check(cells(world) == 10, 're-enabling resumed a stale distance: %.2f cells', cells(world))
end

do
  local world = newWorld()
  run(world, 1)

  setSetting(world, 'Horiz0nMaxViewDistance', 4)
  world.handlers.onFrame(0)
  check(cells(world) == 4, 'lowered maximum was not respected: %.2f cells', cells(world))

  world.baseCells = 2
  world.handlers.onFrame(0)
  check(cells(world) == 2, 'lowered OpenMW distance was not respected: %.2f cells', cells(world))

  setSetting(world, 'Horiz0nMinViewDistance', 1)
  world.frameTimeFloor = 1 / 40
  run(world, 60)
  check(cells(world) == 1, 'raised minimum was not respected: %.2f cells', cells(world))

  world.frameTimeFloor = TARGET_FRAME_TIME
  setSetting(world, 'Horiz0nGrowCooldown', 0)
  local writes = run(world, 1)
  check(writes > 0, 'shortened cooldown did not release the active wait')
end

for _, savedViewDistance in next, { 0 / 0, math.huge, -math.huge, 'far', true } do
  local world = newWorld()
  world.handlers.onLoad { viewDistance = savedViewDistance }
  local ok, message = pcall(run, world, 5)
  check(ok, 'saved distance %s raised: %s', tostring(savedViewDistance), tostring(message))
  check(
    cells(world) >= 0.25 and cells(world) <= 10,
    'saved distance %s left %.2f cells',
    tostring(savedViewDistance),
    cells(world)
  )
end

do
  local world = newWorld()
  world.handlers.onLoad(nil)
  world.affordableCells = 5
  run(world, 30)

  local saved = world.handlers.onSave()
  check(type(saved.viewDistance) == 'number', 'onSave did not return a numeric view distance')

  local reloaded = newWorld()
  reloaded.handlers.onLoad(saved)
  reloaded.handlers.onFrame(0)
  check(
    math.abs(reloaded.engineDistance - world.engineDistance) <= 1,
    'reload did not restore the saved distance: %.2f cells',
    cells(reloaded)
  )
end

print(('horiz0n_controller: %d checks, %d failed'):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
