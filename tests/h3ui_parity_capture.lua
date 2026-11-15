---@omw-context none

local StrFormat, TableConcat = string.format, table.concat

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_parity_capture%.lua$' or '.'

package.path = StrFormat('%s/content/h3lp_yours3lf/?.lua;%s', root, package.path)

local calls = {}
local traces = {}
local now = 0
local insertDown = false
local hudVisible = true
local contentList =
  { 'builtin.omwscripts', 'morrowind.esm', 'tribunal.esm', 'bloodmoon.esm', 'h3-parity.omwscripts' }
local reconstructionMade = 0

local function record(call) calls[#calls + 1] = call end

local function windowsText(options)
  if not options then return '' end
  if not options.windows then return ' all' end
  if #options.windows == 0 then return ' none' end
  return StrFormat(' %s', TableConcat(options.windows, ','))
end

package.preload['openmw.core'] = function()
  return {
    API_REVISION = 160,
    contentFiles = { list = contentList },
    getGMST = function(name)
      assert(name == 'fMessageTimePerChar')
      return 0.1
    end,
    getRealTime = function() return now end,
    sendGlobalEvent = function(name) record(name) end,
  }
end
package.preload['openmw.input'] = function()
  return {
    KEY = { Insert = 73 },
    isKeyPressed = function(key)
      assert(key == 73)
      return insertDown
    end,
  }
end
package.preload['openmw.debug'] = function()
  return { takeScreenshot = function() record 'screenshot' end }
end
package.preload['openmw.ui'] = function()
  local windowsLayer = { size = { x = 1280, y = 720 } }
  return {
    CONSOLE_COLOR = { Info = 'info' },
    create = function(layout)
      record(StrFormat('create %s', layout.name))
      return { destroy = function() record(StrFormat('destroy %s', layout.name)) end }
    end,
    layers = setmetatable({ windowsLayer }, {
      __index = { indexOf = function(name) return name == 'Windows' and 1 or nil end },
    }),
    printToConsole = function() end,
    screenSize = function() return { x = 1280, y = 720 } end,
    showMessage = function(text) record(StrFormat('message %s', text)) end,
  }
end
package.preload['openmw.interfaces'] = function()
  return {
    UI = {
      isHudVisible = function() return hudVisible end,
      setHudVisibility = function(visible)
        hudVisible = visible
        record(StrFormat('hud %s', tostring(visible)))
      end,
      setMode = function(mode, options)
        record(StrFormat('mode %s%s', tostring(mode), windowsText(options)))
      end,
      showInteractiveMessage = function(text) record(StrFormat('interactive %s', text)) end,
    },
  }
end
package.preload['scripts.s3.fixtures.trace'] = function()
  return { emit = function(fields) traces[#traces + 1] = fields end }
end

local reconstructions = {
  messagebox = function(entry)
    reconstructionMade = reconstructionMade + 1
    assert(entry.layout == 'messagebox')
    return { name = 'messagebox reconstruction' }
  end,
}
package.preload['scripts.h3.parity.reconstructions'] = function() return reconstructions end

local Capture = require 'scripts.h3.parity.capture'
local onFrame = Capture.engineHandlers.onFrame
local Parity = Capture.interface

assert(Capture.interfaceName == 'H3UIParity')

local function reset()
  calls = {}
  traces = {}
end

local function frames(count)
  for _ = 1, count do
    onFrame(0)
  end
end

local function start(options)
  Parity.run(options)
  frames(1)
end

local function pressInsert()
  insertDown = true
  frames(1)
  insertDown = false
  frames(1)
end

local function waitSeconds(seconds)
  now = now + seconds
  frames(1)
end

local function running()
  for index = #traces, 1, -1 do
    local trace = traces[index]
    if trace.event == 'run' then return trace.phase == 'start' end
  end
  return false
end

-- Runs until the fixture finishes: Insert whenever it is pressed for, and time whenever it waits.
local function finishRun()
  for _ = 1, 2000 do
    if not running() then return end
    pressInsert()
    waitSeconds(1)
  end
  error 'the run did not finish'
end

local function screenshotsBefore(index)
  local count = 0
  for position = 1, index do
    if calls[position] == 'screenshot' then count = count + 1 end
  end
  return count
end

local function shotTraces()
  local shots = {}
  for index = 1, #traces do
    local trace = traces[index]
    if trace.event == 'capture' then
      shots[#shots + 1] = StrFormat('%s %s %d', trace.layout, trace.variant, trace.attempt)
    end
  end
  return TableConcat(shots, '|')
end

local function callsWithout(ignored)
  local kept = {}
  for index = 1, #calls do
    local call = calls[index]
    if not ignored[call] then kept[#kept + 1] = call end
  end
  return TableConcat(kept, '|')
end

local function testRefusesUnexpectedContent()
  reset()
  contentList[#contentList + 1] = 'tamriel_data.esm'
  Parity.run()
  contentList[#contentList] = nil

  assert(traces[1].event == 'run' and traces[1].phase == 'refuse')
  assert(traces[1].content == 'tamriel_data.esm')
  assert(calls[1] == 'message H3UI parity needs vanilla content only. Unload: tamriel_data.esm')

  frames(5)
  assert(#calls == 1)
end

local function testWaitsForInsertBeforeStarting()
  reset()
  start { layouts = { 'wait_dialog' } }
  frames(20)
  waitSeconds(60)

  assert(screenshotsBefore(#calls) == 0)
  assert(calls[1] == 'message H3UI parity: close the console, then press Insert to start.')
  assert(#calls == 1)

  Parity.stop()
  assert(calls[2] == 'mode nil')
  assert(calls[3] == 'hud true')
  assert(calls[4] == 'H3UIParityUnpause')
end

local function testCapturesAModeTwicePerVariant()
  reset()
  start { layouts = { 'wait_dialog' }, messageSeconds = 15, settleFrames = 2 }
  finishRun()

  assert(
    shotTraces()
      == 'wait_dialog baseline 1|wait_dialog baseline 2|wait_dialog vanilla 1|wait_dialog vanilla 2'
  )

  local expected = TableConcat({
    'hud false',
    'H3UIParityPause',
    'mode Rest none',
    'screenshot',
    'mode Rest',
    'mode nil',
    'mode Rest none',
    'screenshot',
    'mode Rest',
    'mode nil',
    'mode Rest all',
    'screenshot',
    'mode nil',
    'mode Rest all',
    'screenshot',
    'mode nil',
    'mode nil',
    'hud true',
    'H3UIParityUnpause',
  }, '|')
  local ignored = { ['message H3UI parity: close the console, then press Insert to start.'] = true }
  assert(callsWithout(ignored) == expected, callsWithout(ignored))
end

local function testWaitsForTheScreenshotMessage()
  reset()
  start { layouts = { 'wait_dialog' }, messageSeconds = 15, settleFrames = 2 }
  pressInsert()
  waitSeconds(20)
  frames(20)

  local shots = screenshotsBefore(#calls)
  assert(shots == 1, shots)

  frames(200)
  assert(screenshotsBefore(#calls) == 1)

  waitSeconds(15)
  frames(10)
  assert(screenshotsBefore(#calls) == 2)

  Parity.stop()
end

local function testShowsTheMessageAndItsReconstruction()
  reset()
  start { layouts = { 'messagebox' }, settleFrames = 1 }
  finishRun()

  assert(
    shotTraces()
      == 'messagebox baseline 1|messagebox baseline 2|messagebox vanilla 1|messagebox vanilla 2|messagebox h3 1|messagebox h3 2'
  )
  assert(reconstructionMade == 2)

  local text = 'message H3UI parity: the message box reference.'
  local vanilla = 0
  for index = 1, #calls do
    if calls[index] == text then
      vanilla = vanilla + 1
      assert(calls[index - 1] == 'mode nil')
      assert(calls[index + 1] == 'screenshot')
    end
  end
  assert(vanilla == 2)

  local created = 0
  for index = 1, #calls do
    if calls[index] == 'create messagebox reconstruction' then
      created = created + 1
      assert(calls[index + 1] == 'screenshot')
      assert(calls[index + 2] == 'destroy messagebox reconstruction')
    end
  end
  assert(created == 2)
end

local function testWaitsForOkOnAnInteractiveMessage()
  reset()
  start { layouts = { 'interactive_messagebox_notransp' }, settleFrames = 1 }
  pressInsert()
  for _ = 1, 100 do
    waitSeconds(1)
  end

  local text = 'interactive H3UI parity: the interactive message reference.'
  local shown
  for index = 1, #calls do
    if calls[index] == text then shown = index end
  end
  assert(calls[shown - 1] == 'mode Interface none')
  assert(calls[shown + 1] == 'screenshot')
  assert(calls[shown + 2] == 'message Click OK, then press Insert.')
  assert(#calls == shown + 2)

  pressInsert()
  assert(calls[shown + 3] == 'mode Interface')
  assert(calls[shown + 4] == 'mode nil')

  Parity.stop()
end

local function testRunsTheWorldOnlyWhileAStepIsFollowedByHand()
  reset()
  start { layouts = { 'count_window' }, settleFrames = 1 }
  finishRun()

  assert(
    shotTraces()
      == 'count_window vanilla 1|count_window vanilla 2|count_window baseline 1|count_window baseline 2'
  )

  local paused = false
  for index = 1, #calls do
    local call = calls[index]
    if call == 'H3UIParityPause' then paused = true end
    if call == 'H3UIParityUnpause' then paused = false end
    if call == 'screenshot' then assert(paused, 'a capture ran with the world running') end
  end

  local announced = 0
  for index = 1, #calls do
    if
      calls[index]
      == 'message Open count_window: In the inventory, drag one item from a stack. Then press Insert.'
    then
      announced = announced + 1
      assert(calls[index - 1] == 'H3UIParityUnpause')
    end
  end
  assert(announced == 2)
end

local function testRecordsTheConditions()
  reset()
  start { layouts = { 'messagebox' }, messageSeconds = 12, settleFrames = 3 }
  pressInsert()

  local recorded = {}
  for index = 1, #traces do
    local trace = traces[index]
    if trace.event == 'conditions' then
      for key, value in next, trace do
        recorded[key] = value
      end
    end
  end

  assert(recorded.screen == '1280x720')
  assert(recorded.windowsLayer == '1280x720')
  assert(
    recorded.content
      == 'builtin.omwscripts;morrowind.esm;tribunal.esm;bloodmoon.esm;h3-parity.omwscripts'
  )
  assert(recorded.apiRevision == 160)
  assert(recorded.messageTimePerChar == 0.1)
  assert(recorded.messageSeconds == 12 and recorded.settleFrames == 3)

  Parity.stop()
end

testRefusesUnexpectedContent()
testWaitsForInsertBeforeStarting()
testCapturesAModeTwicePerVariant()
testWaitsForTheScreenshotMessage()
testShowsTheMessageAndItsReconstruction()
testWaitsForOkOnAnInteractiveMessage()
testRunsTheWorldOnlyWhileAStepIsFollowedByHand()
testRecordsTheConditions()

print 'H3UI parity capture tests passed'
