---@omw-context player

local I = require 'openmw.interfaces'
local core = require 'openmw.core'
local input = require 'openmw.input'
local openmwDebug = require 'openmw.debug'
local ui = require 'openmw.ui'

local manifest = require 'scripts.h3.parity.manifest'
local reconstructions = require 'scripts.h3.parity.reconstructions'
local trace = require 'scripts.s3.fixtures.trace'

local CoroutineCreate, CoroutineResume, CoroutineStatus, CoroutineYield, MathMax, StrFormat, TableConcat =
  coroutine.create,
  coroutine.resume,
  coroutine.status,
  coroutine.yield,
  math.max,
  string.format,
  table.concat

local ContentFiles, GetGmst, GetRealTime, IsKeyPressed =
  core.contentFiles, core.getGMST, core.getRealTime, input.isKeyPressed

local InfoColor, InsertKey = ui.CONSOLE_COLOR.Info, input.KEY.Insert

local Fixture, Context = 'h3ui_parity', 'player'
local Attempts, DefaultMessageSeconds, DefaultSettleFrames = 2, 15, 10
---@type H3UI.ParityVariant[]
local Variants = { 'baseline', 'vanilla', 'h3' }
local EmptyOptions, NoWindows = {}, {}

-- The engine adds builtin.omwscripts before every configured file (apps/openmw/main.cpp).
local AllowedContent = {
  ['bloodmoon.esm'] = true,
  ['builtin.omwscripts'] = true,
  ['h3-parity.omwscripts'] = true,
  ['h3lp yours3lf.esp'] = true,
  ['morrowind.esm'] = true,
  ['tribunal.esm'] = true,
}

local sequence = 0
local quietUntil = 0
local messageSeconds = DefaultMessageSeconds
local settleFrames = DefaultSettleFrames
local hudWasVisible = true

---@type thread?
local runner
---@type openmw.ui.Element?
local reconstruction

---@param event string
---@param phase string
---@param fields? table<string, string|number|boolean>
---@return nil
local function emit(event, phase, fields)
  sequence = sequence + 1

  local line = fields or {}
  line.fixture = Fixture
  line.ctx = Context
  line.seq = sequence
  line.event = event
  line.phase = phase
  trace.emit(line)
end

---@param frames integer
---@return nil
local function waitFrames(frames)
  for _ = 1, frames do
    CoroutineYield()
  end
end

---@return nil
local function waitQuiet()
  while GetRealTime() < quietUntil do
    CoroutineYield()
  end
end

---@return nil
local function waitInsert()
  local wasDown = IsKeyPressed(InsertKey)
  while true do
    CoroutineYield()

    local down = IsKeyPressed(InsertKey)
    if down and not wasDown then return end

    wasDown = down
  end
end

-- A message box stays for its length times fMessageTimePerChar (apps/openmw/mwgui/messagebox.cpp),
-- and the screenshot's own "saved as" box is one too. No capture starts before both have closed.
---@param seconds number
---@return nil
local function expectMessage(seconds) quietUntil = MathMax(quietUntil, GetRealTime() + seconds) end

---@param text string
---@return nil
local function expectMessageText(text) expectMessage(#text * GetGmst 'fMessageTimePerChar' + 1) end

---@param text string
---@return nil
local function announce(text)
  ui.showMessage(text)
  ui.printToConsole(text, InfoColor)
  expectMessageText(text)
  emit('announce', 'show', { text = text })
end

---@param entry H3UI.ParityManifestEntry
---@param variant H3UI.ParityVariant
---@param attempt integer
---@return nil
local function shoot(entry, variant, attempt)
  waitFrames(settleFrames)
  emit('capture', 'shot', { attempt = attempt, layout = entry.layout, variant = variant })
  openmwDebug.takeScreenshot()
  expectMessage(messageSeconds)

  -- takeScreenshot captures the next frame, so the window stays up a little longer.
  waitFrames(settleFrames)
end

---@param entry H3UI.ParityManifestEntry
---@return string?
local function backgroundMode(entry)
  local opens = entry.opens
  if opens.kind == 'mode' then return opens.mode end

  return opens.inMode
end

---@param entry H3UI.ParityManifestEntry
---@return nil
local function showBackground(entry)
  local mode = backgroundMode(entry)
  if mode then
    I.UI.setMode(mode, { windows = NoWindows })
  else
    I.UI.setMode()
  end
end

---@param entry H3UI.ParityManifestEntry
---@return nil
local function closeBackground(entry)
  local mode = backgroundMode(entry)

  -- setMode with windows = {} disables the mode's windows until the mode is set again without a
  -- window list (scripts/omw/ui.lua, updateHidden), so they are given back before closing.
  if mode then I.UI.setMode(mode) end
  I.UI.setMode()
end

---@param entry H3UI.ParityManifestEntry
---@return nil
local function showVanilla(entry)
  local opens = entry.opens
  local kind = opens.kind

  if kind == 'mode' then
    I.UI.setMode(opens.mode, { windows = opens.windows })
  elseif kind == 'message' then
    I.UI.setMode()
    ui.showMessage(opens.text)
    expectMessageText(opens.text)
  elseif kind == 'interactiveMessage' then
    showBackground(entry)
    I.UI.showInteractiveMessage(opens.text)
  elseif kind == 'hud' then
    I.UI.setMode()
    I.UI.setHudVisibility(true)
  end
end

---@param entry H3UI.ParityManifestEntry
---@return nil
local function closeVanilla(entry)
  local kind = entry.opens.kind

  if kind == 'mode' then
    I.UI.setMode()
  elseif kind == 'interactiveMessage' then
    announce 'Click OK, then press Insert.'
    waitInsert()
    closeBackground(entry)
  elseif kind == 'hud' then
    I.UI.setHudVisibility(false)
  end
end

---@param entry H3UI.ParityManifestEntry
---@return nil
local function showReconstruction(entry)
  reconstruction = ui.create(reconstructions[entry.layout](entry))
end

---@return nil
local function destroyReconstruction()
  if not reconstruction then return end

  reconstruction:destroy()
  reconstruction = nil
end

---@param entry H3UI.ParityManifestEntry
---@param variant H3UI.ParityVariant
---@return nil
local function showVariant(entry, variant)
  if variant == 'vanilla' then return showVanilla(entry) end

  showBackground(entry)
  if variant == 'h3' then showReconstruction(entry) end
end

---@param entry H3UI.ParityManifestEntry
---@param variant H3UI.ParityVariant
---@return nil
local function closeVariant(entry, variant)
  if variant == 'vanilla' then return closeVanilla(entry) end

  destroyReconstruction()
  closeBackground(entry)
end

---@param entry H3UI.ParityManifestEntry
---@return nil
local function captureAutomatically(entry)
  for index = 1, #Variants do
    local variant = Variants[index]

    if variant ~= 'h3' or reconstructions[entry.layout] then
      for attempt = 1, Attempts do
        waitQuiet()
        showVariant(entry, variant)
        shoot(entry, variant, attempt)
        closeVariant(entry, variant)
      end
    end
  end
end

-- No Lua call opens these windows, and the player cannot act while the world is paused, so the
-- world runs while the steps are followed by hand and pauses again for each capture.
---@param entry H3UI.ParityManifestEntry
---@return nil
local function captureByHand(entry)
  for attempt = 1, Attempts do
    waitQuiet()
    core.sendGlobalEvent 'H3UIParityUnpause'
    announce(StrFormat('Open %s: %s Then press Insert.', entry.layout, entry.opens.steps))
    waitInsert()

    core.sendGlobalEvent 'H3UIParityPause'
    waitQuiet()
    shoot(entry, 'vanilla', attempt)

    announce(StrFormat('Close %s, then press Insert.', entry.layout))
    waitInsert()
  end

  for attempt = 1, Attempts do
    waitQuiet()
    shoot(entry, 'baseline', attempt)
  end

  if not reconstructions[entry.layout] then return end

  for attempt = 1, Attempts do
    waitQuiet()
    showReconstruction(entry)
    shoot(entry, 'h3', attempt)
    destroyReconstruction()
  end
end

---@return nil
local function recordConditions()
  local screenSize = ui.screenSize()
  local windowsLayer = ui.layers[ui.layers.indexOf 'Windows']

  emit('conditions', 'record', { apiRevision = core.API_REVISION })
  emit('conditions', 'record', { screen = StrFormat('%gx%g', screenSize.x, screenSize.y) })
  emit(
    'conditions',
    'record',
    { windowsLayer = StrFormat('%gx%g', windowsLayer.size.x, windowsLayer.size.y) }
  )
  emit('conditions', 'record', { content = TableConcat(ContentFiles.list, ';') })
  emit('conditions', 'record', { messageTimePerChar = GetGmst 'fMessageTimePerChar' })
  emit('conditions', 'record', { messageSeconds = messageSeconds, settleFrames = settleFrames })
end

---@param options H3UI.ParityCaptureOptions
---@return H3UI.ParityManifestEntry[]
local function selectEntries(options)
  local wanted = options.layouts
  if not wanted then return manifest end

  local names = {}
  for index = 1, #wanted do
    names[wanted[index]] = true
  end

  local entries = {}
  for index = 1, #manifest do
    local entry = manifest[index]
    if names[entry.layout] then entries[#entries + 1] = entry end
  end

  return entries
end

---@return string[]
local function unexpectedContent()
  local list = ContentFiles.list
  local unexpected = {}
  for index = 1, #list do
    if not AllowedContent[list[index]] then unexpected[#unexpected + 1] = list[index] end
  end

  return unexpected
end

---@return nil
local function finish()
  destroyReconstruction()
  I.UI.setMode()
  I.UI.setHudVisibility(hudWasVisible)
  core.sendGlobalEvent 'H3UIParityUnpause'
  runner = nil
end

---@param options? H3UI.ParityCaptureOptions
---@return nil
local function run(options)
  options = options or EmptyOptions

  if runner then return emit('run', 'refuse', { reason = 'running' }) end

  local unexpected = unexpectedContent()
  if #unexpected > 0 then
    local files = TableConcat(unexpected, ', ')
    emit('run', 'refuse', { content = files, reason = 'content' })
    ui.showMessage(StrFormat('H3UI parity needs vanilla content only. Unload: %s', files))
    return
  end

  messageSeconds = options.messageSeconds or DefaultMessageSeconds
  settleFrames = options.settleFrames or DefaultSettleFrames
  local entries = selectEntries(options)

  runner = CoroutineCreate(function()
    announce 'H3UI parity: close the console, then press Insert to start.'
    waitInsert()

    hudWasVisible = I.UI.isHudVisible()
    I.UI.setHudVisibility(false)
    core.sendGlobalEvent 'H3UIParityPause'
    recordConditions()

    for index = 1, #entries do
      local entry = entries[index]
      emit('layout', 'start', { layout = entry.layout })

      if entry.opens.kind == 'manual' then
        captureByHand(entry)
      else
        captureAutomatically(entry)
      end

      emit('layout', 'done', { layout = entry.layout })
    end

    waitQuiet()
    emit('run', 'done', { layouts = #entries })
  end)

  emit('run', 'start', { layouts = #entries })
end

---@return nil
local function stop()
  if not runner then return end

  emit('run', 'stop')
  finish()
end

return {
  interfaceName = 'H3UIParity',
  ---@type openmw.interfaces.H3UIParity
  interface = {
    run = run,
    stop = stop,
  },
  engineHandlers = {
    ---@return nil
    onFrame = function()
      if not runner then return end

      local resumed, problem = CoroutineResume(runner)
      if not resumed then emit('run', 'error', { reason = tostring(problem) }) end
      if not resumed or CoroutineStatus(runner) == 'dead' then finish() end
    end,
  },
}
