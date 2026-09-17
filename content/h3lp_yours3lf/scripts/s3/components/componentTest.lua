---@omw-context player

local emptyOptions = {}

local async = require 'openmw.async'
local auxUi = require 'openmw_aux.ui'
local input = require 'openmw.input'
local omwDebug = require 'openmw.debug'
local storage = require 'openmw.storage'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local H3UI = require 'scripts.s3.ui'

local appearanceCoverage = require 'scripts.s3.components.componentTests.appearanceCoverage'
local applicationForm = require 'scripts.s3.components.componentTests.applicationForm'
local boundaries = require 'scripts.s3.components.componentTests.boundaries'
local controlStates = require 'scripts.s3.components.componentTests.controlStates'
local eventComposition = require 'scripts.s3.components.componentTests.eventComposition'
local inventoryPanel = require 'scripts.s3.components.componentTests.inventoryPanel'
local magicMenu = require 'scripts.s3.components.componentTests.magicMenu'
local relativeSizing = require 'scripts.s3.components.componentTests.relativeSizing'
local windowGeometry = require 'scripts.s3.components.componentTests.windowGeometry'

local UtilVector2 = util.vector2
local debugSettings = storage.playerSection 'SettingsPlayerH3UI'
local defaultPosition = UtilVector2(80, 80)
local defaultSize = UtilVector2(760, 720)

---@class H3ComponentTest.Options
---@field layer? string Root UI layer. Defaults to `Windows` for in-game console use.
---@field replace? boolean Destroy an existing owned root before creating a new one.
---@field position? openmw.util.Vector2 Optional diagnostic-shell position.
---@field size? openmw.util.Vector2 Optional diagnostic-shell size.
---@field shell? 'window'|'box' Use a plain box shell for diagnostic fixtures.

---@alias H3ComponentTest.DemoName
---| 'magicMenu'
---| 'inventoryPanel'
---| 'applicationForm'
---| 'appearanceCoverage'
---| 'boundaries'
---| 'controlStates'
---| 'eventComposition'
---| 'relativeSizing'
---| 'windowGeometry'

---@class openmw.interfaces.H3ComponentTest
---@field makeLayout fun(options?: H3ComponentTest.Options): openmw.ui.Layout
---@field create fun(options?: H3ComponentTest.Options): openmw.ui.Element
---@field createDemo fun(name: H3ComponentTest.DemoName, options?: H3ComponentTest.Options): openmw.ui.Element
---@field destroy fun(): boolean
---@field toggle fun(options?: H3ComponentTest.Options): boolean
---@field isOpen fun(): boolean
---@field refresh fun()
---@field magicMenu fun(invalidate?: fun()): openmw.ui.Layout
---@field inventoryPanel fun(invalidate?: fun()): openmw.ui.Layout
---@field applicationForm fun(invalidate?: fun()): openmw.ui.Layout
---@field appearanceCoverage fun(invalidate?: fun()): openmw.ui.Layout
---@field boundaries fun(): openmw.ui.Layout
---@field controlStates fun(): openmw.ui.Layout
---@field eventComposition fun(): openmw.ui.Layout
---@field relativeSizing fun(): openmw.ui.Layout
---@field windowGeometry fun(): openmw.ui.Layout

---@class openmw.interfaces
---@field H3ComponentTest? openmw.interfaces.H3ComponentTest

---@type openmw.ui.Element|nil
local rootElement
---@type openmw.ui.Element|nil
local bodyElement
---@type fun(element: openmw.ui.Element)|nil
local elementUpdate
local rootDirty = false
local bodyDirty = false

local demoDefinitions = {
  magicMenu = { constructor = magicMenu, standalone = true },
  inventoryPanel = { constructor = inventoryPanel, standalone = true },
  applicationForm = { constructor = applicationForm, standalone = true },
  appearanceCoverage = { constructor = appearanceCoverage },
  boundaries = { constructor = boundaries },
  controlStates = { constructor = controlStates },
  eventComposition = { constructor = eventComposition },
  relativeSizing = { constructor = relativeSizing },
  windowGeometry = { constructor = windowGeometry },
}

local demoNames = {
  'magicMenu',
  'inventoryPanel',
  'applicationForm',
  'appearanceCoverage',
  'controlStates',
  'eventComposition',
  'boundaries',
  'relativeSizing',
  'windowGeometry',
}
local currentDemoIndex = 0

local function isOpen() return rootElement ~= nil and rootElement.layout ~= nil end

local function destroy()
  local wasOpen = isOpen()
  local currentRoot = rootElement
  local currentBody = bodyElement

  rootElement = nil
  rootDirty = false
  bodyElement = nil
  bodyDirty = false

  if currentRoot and currentRoot.layout then
    auxUi.deepDestroy(currentRoot)
  elseif currentBody and currentBody.layout then
    auxUi.deepDestroy(currentBody)
  end

  return wasOpen
end

local function updateElement(element)
  if not elementUpdate then elementUpdate = element.update end
  elementUpdate(element)
end

local function refreshRoot() rootDirty = true end

local function refreshBody()
  if bodyElement and bodyElement.layout then
    bodyDirty = true
  else
    rootDirty = true
  end
end

local function flushUpdates()
  if rootDirty then
    rootDirty = false
    local element = rootElement
    if element and element.layout then updateElement(element) end
  end

  if bodyDirty then
    bodyDirty = false
    local element = bodyElement
    if element and element.layout then updateElement(element) end
  end
end

local function makeWindowLayout(options, body, title)
  local resizeDirty = false
  local function finishResize()
    if not resizeDirty then return end
    resizeDirty = false
    refreshBody()
  end

  local root = H3UI.window {
    name = 'ct_root_window',
    title = title or 'H3 Diagnostic Fixture',
    position = options.position or defaultPosition,
    size = options.size or defaultSize,
    movable = true,
    resizable = true,
    closable = true,
    pinnable = true,
    onMove = refreshRoot,
    onResize = function()
      resizeDirty = true
      refreshRoot()
    end,
    onClose = function() async:newUnsavableSimulationTimer(0, destroy) end,
    onPin = refreshRoot,
    events = {
      mouseRelease = async:callback(finishResize),
      focusLoss = async:callback(finishResize),
    },
    children = { body },
  }

  root.layer = options.layer or 'Windows'
  return root
end

local function makePlainShellLayout(options, body)
  local root = H3UI.box {
    name = 'ct_plain_shell',
    props = {
      position = options.position or defaultPosition,
      size = options.size or defaultSize,
    },
    children = { body },
  }
  root.layer = options.layer or 'Windows'
  return root
end

local function makeShellLayout(options, body, title)
  if options.shell == 'box' then return makePlainShellLayout(options, body) end
  return makeWindowLayout(options, body, title)
end

local function makeLayout(options)
  options = options or emptyOptions
  local layout = magicMenu()
  layout.layer = options.layer or 'Windows'
  if options.position then layout.props.position = options.position end
  if options.size then layout.props.size = options.size end
  return layout
end

local function createStandalone(options, constructor)
  if isOpen() then
    if options.replace ~= true then return rootElement end
    destroy()
  end

  local layout = constructor(refreshRoot)
  layout.layer = options.layer or 'Windows'
  if options.position then layout.props.position = options.position end
  if options.size then layout.props.size = options.size end
  rootElement = ui.create(layout)
  return rootElement
end

local function createBody(options, body, title)
  if isOpen() then
    if options.replace ~= true then return rootElement end
    destroy()
  end

  bodyElement = ui.create(body, { noWarnUnused = true })
  rootElement = ui.create(makeShellLayout(options, bodyElement, title))
  return rootElement
end

local function createDemo(name, options)
  local definition = demoDefinitions[name]
  assert(definition, 'Unknown H3 component demo: ' .. tostring(name))

  options = options or emptyOptions
  if definition.standalone then return createStandalone(options, definition.constructor) end

  local body = H3UI.column {
    name = 'ct_demo_body',
    children = { definition.constructor(refreshBody) },
  }
  return createBody(options, body, 'H3 Diagnostic: ' .. name)
end

local function create(options)
  options = options or emptyOptions
  currentDemoIndex = 1
  return createDemo(demoNames[currentDemoIndex], options)
end

local function cycleDemo()
  currentDemoIndex = currentDemoIndex % #demoNames + 1
  createDemo(demoNames[currentDemoIndex], { replace = true })
end

local function onKeyPress(key)
  if debugSettings:get 'enableDebugHotkeys' ~= true then return end
  if key.code ~= input.KEY.F7 then return end
  if key.withShift then
    omwDebug.reloadLua()
    return
  end
  cycleDemo()
end

local function toggle(options)
  if isOpen() then
    destroy()
    return false
  end

  create(options)
  return true
end

---@type openmw.interfaces.H3ComponentTest
local interface = {
  makeLayout = makeLayout,
  create = create,
  createDemo = createDemo,
  destroy = destroy,
  toggle = toggle,
  isOpen = isOpen,
  refresh = refreshBody,
  magicMenu = magicMenu,
  inventoryPanel = inventoryPanel,
  applicationForm = applicationForm,
  appearanceCoverage = appearanceCoverage,
  boundaries = boundaries,
  controlStates = controlStates,
  eventComposition = eventComposition,
  relativeSizing = relativeSizing,
  windowGeometry = windowGeometry,
}

return {
  interfaceName = 'H3ComponentTest',
  interface = interface,
  engineHandlers = {
    onFrame = flushUpdates,
    onKeyPress = onKeyPress,
  },
}
