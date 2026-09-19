---@omw-context player

local async = require 'openmw.async'
local input = require 'openmw.input'
local omwDebug = require 'openmw.debug'
local storage = require 'openmw.storage'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local auxUi = require 'openmw_aux.ui'

local H3UI = require 'scripts.h3.ui'

local appearanceCoverage = require 'scripts.h3.componentTests.appearanceCoverage'
local applicationForm = require 'scripts.h3.componentTests.applicationForm'
local boundaries = require 'scripts.h3.componentTests.boundaries'
local controlStates = require 'scripts.h3.componentTests.controlStates'
local eventComposition = require 'scripts.h3.componentTests.eventComposition'
local inventoryPanel = require 'scripts.h3.componentTests.inventoryPanel'
local magicMenu = require 'scripts.h3.componentTests.magicMenu'
local relativeSizing = require 'scripts.h3.componentTests.relativeSizing'
local windowGeometry = require 'scripts.h3.componentTests.windowGeometry'

local Error, StrFormat, ToString = error, string.format, tostring

local DeepDestroy, InputKey, PlayerSection, ReloadLua, UiCreate, UtilVector2 =
  auxUi.deepDestroy, input.KEY, storage.playerSection, omwDebug.reloadLua, ui.create, util.vector2

local EmptyOptions = {}

local DebugSettings = PlayerSection 'SettingsPlayerH3UI'

local DefaultPosition, DefaultSize = UtilVector2(80, 80), UtilVector2(760, 720)

---@type openmw.ui.Element|nil
local rootElement
---@type openmw.ui.Element|nil
local bodyElement
---@type fun(element: openmw.ui.Element)|nil
local elementUpdate
local rootDirty = false
local rootRebuildDirty = false
local bodyDirty = false
local standaloneConstructor
local standaloneOptions
local standaloneState

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

---@return boolean
local function isOpen() return not not (rootElement and rootElement.layout) end

---@return boolean
local function destroy()
  local wasOpen = isOpen()
  local currentRoot = rootElement
  local currentBody = bodyElement

  rootElement = nil
  rootDirty = false
  rootRebuildDirty = false
  bodyElement = nil
  bodyDirty = false
  standaloneConstructor = nil
  standaloneOptions = nil
  standaloneState = nil

  if currentRoot and currentRoot.layout then
    DeepDestroy(currentRoot)
  elseif currentBody and currentBody.layout then
    DeepDestroy(currentBody)
  end

  return wasOpen
end

---@param element openmw.ui.Element
---@return nil
local function updateElement(element)
  if not elementUpdate then elementUpdate = element.update end
  elementUpdate(element)
end

---@return nil
local function refreshRoot() rootDirty = true end
---@return nil
local function rebuildRoot() rootRebuildDirty = true end

---@return nil
local function refreshBody()
  if bodyElement and bodyElement.layout then
    bodyDirty = true
  else
    rootDirty = true
  end
end

---@return openmw.ui.Layout
local function buildStandaloneLayout()
  local layout = standaloneConstructor(refreshRoot, rebuildRoot, standaloneState)
  local options = standaloneOptions or EmptyOptions
  layout.layer = options.layer or 'Windows'
  if options.position then layout.props.position = options.position end
  if options.size then layout.props.size = options.size end

  return layout
end

---@return nil
local function flushUpdates()
  if rootRebuildDirty then
    rootRebuildDirty = false
    rootDirty = false

    local current = rootElement
    if current and current.layout and standaloneConstructor then
      local position = current.layout.props and current.layout.props.position
      local size = current.layout.props and current.layout.props.size
      local layout = buildStandaloneLayout()

      if not standaloneOptions.position and position then layout.props.position = position end
      if not standaloneOptions.size and size then layout.props.size = size end

      DeepDestroy(current)
      rootElement = UiCreate(layout)
    end
  elseif rootDirty then
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

---@param options H3ComponentTest.Options
---@param body openmw.ui.LayoutOrElement
---@param title? string
---@return openmw.ui.Layout
local function makeWindowLayout(options, body, title)
  local resizeDirty = false
  ---@return nil
  local function finishResize()
    if not resizeDirty then return end
    resizeDirty = false
    refreshBody()
  end

  local root = H3UI.window {
    name = 'ct_root_window',
    title = title or 'H3 Diagnostic Fixture',
    position = options.position or DefaultPosition,
    size = options.size or DefaultSize,
    movable = true,
    resizable = true,
    closable = true,
    pinnable = true,
    onMove = refreshRoot,
    ---@return nil
    onResize = function()
      resizeDirty = true
      refreshRoot()
    end,
    ---@return nil
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

---@param options H3ComponentTest.Options
---@param body openmw.ui.LayoutOrElement
---@return openmw.ui.Layout
local function makePlainShellLayout(options, body)
  local root = H3UI.box {
    name = 'ct_plain_shell',
    props = {
      position = options.position or DefaultPosition,
      size = options.size or DefaultSize,
    },
    children = { body },
  }
  root.layer = options.layer or 'Windows'

  return root
end

---@param options H3ComponentTest.Options
---@param body openmw.ui.LayoutOrElement
---@param title? string
---@return openmw.ui.Layout
local function makeShellLayout(options, body, title)
  if options.shell == 'box' then return makePlainShellLayout(options, body) end

  return makeWindowLayout(options, body, title)
end

---@param options H3ComponentTest.Options
---@return openmw.ui.Layout
local function makeLayout(options)
  options = options or EmptyOptions
  local layout = magicMenu()
  layout.layer = options.layer or 'Windows'
  if options.position then layout.props.position = options.position end
  if options.size then layout.props.size = options.size end

  return layout
end

---@param options H3ComponentTest.Options
---@param constructor fun(): openmw.ui.Layout
---@return openmw.ui.Element
local function createStandalone(options, constructor)
  if isOpen() then
    if options.replace ~= true then
      ---@cast rootElement openmw.ui.Element
      return rootElement
    end
    destroy()
  end

  standaloneConstructor = constructor
  standaloneOptions = options
  standaloneState = {}

  rootElement = UiCreate(buildStandaloneLayout())

  ---@cast rootElement openmw.ui.Element
  return rootElement
end

---@param options H3ComponentTest.Options
---@param body openmw.ui.Layout
---@param title? string
---@return openmw.ui.Element
local function createBody(options, body, title)
  if isOpen() then
    if options.replace ~= true then
      ---@cast rootElement openmw.ui.Element
      return rootElement
    end
    destroy()
  end

  bodyElement = UiCreate(body)
  rootElement = UiCreate(makeShellLayout(options, bodyElement, title))

  ---@cast rootElement openmw.ui.Element
  return rootElement
end

---@param name H3ComponentTest.DemoName
---@param options? H3ComponentTest.Options
---@return openmw.ui.Element
local function createDemo(name, options)
  local definition = demoDefinitions[name]
  if not definition then Error(StrFormat('Unknown H3 component demo: %s', ToString(name))) end

  options = options or EmptyOptions
  if definition.standalone then return createStandalone(options, definition.constructor) end

  local body = H3UI.column {
    name = 'ct_demo_body',
    children = { definition.constructor(refreshBody) },
  }

  return createBody(options, body, StrFormat('H3 Diagnostic: %s', name))
end

---@param options? H3ComponentTest.Options
---@return openmw.ui.Element
local function create(options)
  options = options or EmptyOptions
  currentDemoIndex = 1

  return createDemo(demoNames[currentDemoIndex], options)
end

---@return nil
local function cycleDemo()
  currentDemoIndex = currentDemoIndex % #demoNames + 1
  createDemo(demoNames[currentDemoIndex], { replace = true })
end

---@param key openmw.input.KeyboardEvent
---@return nil
local function onKeyPress(key)
  if DebugSettings:get 'enableDebugHotkeys' ~= true then return end
  if key.code ~= InputKey.F7 then return end
  if key.withShift then
    ReloadLua()
    return
  end
  cycleDemo()
end

---@param options? H3ComponentTest.Options
---@return boolean
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
