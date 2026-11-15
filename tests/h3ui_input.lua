---@omw-context none

local StrFormat = string.format

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_input%.lua$' or '.'

package.path = StrFormat('%s/content/h3lp_yours3lf/?.lua;%s', root, package.path)

local events = {}

local function record(event) events[#events + 1] = event end

local KEY = { A = 4, Backspace = 42, D = 7, Enter = 40, Escape = 41, S = 22, W = 26, X = 27 }
local KeyNames =
  { [4] = 'A', [7] = 'D', [22] = 'S', [26] = 'W', [27] = 'X', [40] = 'Enter', [41] = 'Escape' }

local CONTROLLER_BUTTON = {
  A = 0,
  B = 1,
  Back = 4,
  DPadDown = 12,
  DPadLeft = 13,
  DPadRight = 14,
  DPadUp = 11,
  Guide = 5,
  LeftShoulder = 9,
  LeftStick = 7,
  RightShoulder = 10,
  RightStick = 8,
  Start = 6,
  X = 2,
  Y = 3,
}

local actions = {}
local registeredActions = {}

local Input = {
  ACTION_TYPE = { Boolean = 0 },
  CONTROLLER_BUTTON = CONTROLLER_BUTTON,
  KEY = KEY,
  actions = actions,
  getKeyName = function(code) return KeyNames[code] or '' end,
  registerAction = function(info)
    record 'registerAction'
    registeredActions[#registeredActions + 1] = info
    actions[info.key] = info
  end,
}

local sections = {}
local writes = 0

local function storageSection(name)
  local values = {}
  local section = {
    values = values,
    get = function(_, key) return values[key] end,
    set = function(_, key, value)
      writes = writes + 1
      values[key] = value
    end,
  }
  sections[name] = section
  return section
end

local settingsPages = {}

package.preload['openmw.core'] = function()
  return {
    l10n = function()
      return function(key) return key end
    end,
  }
end
package.preload['openmw.input'] = function() return Input end
package.preload['openmw.storage'] = function() return { playerSection = storageSection } end
package.preload['openmw.ui'] = function()
  return {
    ALIGNMENT = { Center = 'Center' },
    create = function(layout)
      local element = { layout = layout }
      element.update = function() end
      return element
    end,
    registerSettingsPage = function(options) settingsPages[#settingsPages + 1] = options end,
  }
end
package.preload['openmw.util'] = function()
  return { vector2 = function(x, y) return { x = x, y = y } end }
end

local function component(kind)
  return function(options)
    record 'layout'
    options.kind = kind
    return options
  end
end

package.preload['scripts.h3.ui'] = function()
  return {
    button = component 'button',
    column = component 'column',
    row = component 'row',
    text = component 'text',
  }
end

local H3Input = require 'scripts.h3.input'
local InputPage = require 'scripts.h3.inputPage'

local Bindings = sections.OMWInputBindings
local BindingStates = sections.H3UIInputBindingState

local Intent = H3Input.Intent
local Devices = { 'keyboard', 'mouse', 'controller' }

local ExpectedDefinitions = {
  { key = Intent.Up, keyboard = KEY.W, controller = CONTROLLER_BUTTON.DPadUp },
  { key = Intent.Down, keyboard = KEY.S, controller = CONTROLLER_BUTTON.DPadDown },
  { key = Intent.Left, keyboard = KEY.A, controller = CONTROLLER_BUTTON.DPadLeft },
  { key = Intent.Right, keyboard = KEY.D, controller = CONTROLLER_BUTTON.DPadRight },
  { key = Intent.Activate, keyboard = KEY.Enter, controller = CONTROLLER_BUTTON.A },
  { key = Intent.Cancel, keyboard = KEY.Escape, controller = CONTROLLER_BUTTON.B },
}

local function keyPress(code)
  return {
    code = code,
    symbol = '',
    withAlt = false,
    withCtrl = false,
    withShift = false,
    withSuper = false,
  }
end

local function invalidBinding(binding)
  local devices = { keyboard = true, mouse = true, controller = true }

  if not binding.key then
    return 'has no key'
  elseif binding.type ~= 'action' and binding.type ~= 'trigger' then
    return 'has invalid type'
  elseif binding.type == 'action' and not actions[binding.key] then
    return 'action does not exist'
  elseif not binding.device or not devices[binding.device] then
    return 'invalid device'
  elseif not binding.button then
    return 'has no button'
  end
end

local function assertEngineRecord(binding, device, button, key)
  assert(binding, 'expected a binding record')
  assert(invalidBinding(binding) == nil, invalidBinding(binding))
  assert(binding.device == device)
  assert(binding.button == button)
  assert(binding.type == 'action')
  assert(binding.key == key)

  local fields = 0
  for _ in next, binding do
    fields = fields + 1
  end
  assert(fields == 4)
end

local function testDefinitions()
  local definitions = H3Input.getActionDefinitions()
  local slotIds = {}

  assert(Intent.Up == 'H3UI.NavigateUp')
  assert(Intent.Down == 'H3UI.NavigateDown')
  assert(Intent.Left == 'H3UI.NavigateLeft')
  assert(Intent.Right == 'H3UI.NavigateRight')
  assert(Intent.Activate == 'H3UI.Activate')
  assert(Intent.Cancel == 'H3UI.Cancel')

  assert(#definitions == #ExpectedDefinitions)
  for index = 1, #definitions do
    local definition = definitions[index]
    local expected = ExpectedDefinitions[index]

    assert(definition.info.key == expected.key)
    assert(definition.info.type == Input.ACTION_TYPE.Boolean)
    assert(definition.info.defaultValue == false)
    assert(definition.info.l10n == 'H3')
    assert(#definition.bindings == #Devices)

    for slotIndex = 1, #Devices do
      local slot = definition.bindings[slotIndex]
      assert(slot.device == Devices[slotIndex])
      assert(slot.id == StrFormat('%s.%s', expected.key, slot.device))
      assert(slot.default == expected[slot.device])
      assert(not slotIds[slot.id])
      slotIds[slot.id] = true
    end
  end

  assert(H3Input.getActionDefinitions() ~= definitions)
end

local function testInputOutsideRecordingWritesNothing()
  local writesBefore = writes

  InputPage.onKeyPress(keyPress(KEY.X))
  InputPage.onMouseButtonPress(1)
  InputPage.onControllerButtonPress(CONTROLLER_BUTTON.X)
  InputPage.bindInputButton('keyboard', KEY.X)

  assert(writes == writesBefore)
end

local function testRegisterActionsBeforePage()
  actions[Intent.Cancel] = { key = Intent.Cancel }
  InputPage.register()

  assert(#settingsPages == 1)
  assert(settingsPages[1].name == 'H3UIInputPageName')
  assert(#registeredActions == #ExpectedDefinitions - 1)

  local firstLayout
  local lastRegistration = 0
  for index = 1, #events do
    if events[index] == 'registerAction' then lastRegistration = index end
    if events[index] == 'layout' and not firstLayout then firstLayout = index end
  end
  assert(firstLayout and lastRegistration > 0 and lastRegistration < firstLayout)

  InputPage.register()
  H3Input.registerActions()
  assert(#settingsPages == 1)
  assert(#registeredActions == #ExpectedDefinitions - 1)
end

local function testDefaultsInitialised()
  local definitions = H3Input.getActionDefinitions()

  for index = 1, #definitions do
    for slotIndex = 1, #Devices do
      local slot = definitions[index].bindings[slotIndex]
      local binding = Bindings.values[slot.id]

      if slot.default == nil then
        assert(binding == nil)
        assert(BindingStates.values[slot.id] == nil)
      else
        assertEngineRecord(binding, slot.device, slot.default, definitions[index].info.key)
        assert(BindingStates.values[slot.id] == 'configured')
      end
    end
  end
end

local function slotControls(definitionIndex, slotIndex)
  local page = settingsPages[1].element.layout
  local bindingRow = page.children[3 + definitionIndex]
  local slot = bindingRow.children[1 + slotIndex]
  local slotActions = slot[3].children

  return {
    clear = slotActions[1],
    default = slotActions[2],
    label = slot[2].label,
    record = slot[2],
  }
end

local function activate(control)
  assert(control.kind == 'button')
  assert(control.onActivate({}, control) == true)
end

local function testRecordingWritesEngineRecord()
  local activateMouse = slotControls(5, 2)
  activate(activateMouse.record)
  assert(slotControls(5, 2).label == 'input_binding_listening')

  InputPage.onMouseButtonPress(3)
  assertEngineRecord(Bindings.values['H3UI.Activate.mouse'], 'mouse', 3, Intent.Activate)
  assert(BindingStates.values['H3UI.Activate.mouse'] == 'configured')
  assert(slotControls(5, 2).label ~= 'input_binding_listening')

  activate(slotControls(1, 3).record)
  InputPage.onControllerButtonPress(CONTROLLER_BUTTON.Y)
  assertEngineRecord(
    Bindings.values['H3UI.NavigateUp.controller'],
    'controller',
    CONTROLLER_BUTTON.Y,
    Intent.Up
  )

  activate(slotControls(2, 1).record)
  InputPage.onKeyPress(keyPress(KEY.X))
  assertEngineRecord(Bindings.values['H3UI.NavigateDown.keyboard'], 'keyboard', KEY.X, Intent.Down)
  assert(slotControls(2, 1).label == 'X')
end

local function testBackspaceAndBackCancelRecording()
  local writesBefore = writes

  activate(slotControls(3, 1).record)
  InputPage.onKeyPress(keyPress(KEY.Backspace))

  assert(writes == writesBefore)
  assertEngineRecord(Bindings.values['H3UI.NavigateLeft.keyboard'], 'keyboard', KEY.A, Intent.Left)
  assert(slotControls(3, 1).label == 'A')

  activate(slotControls(3, 3).record)
  InputPage.onControllerButtonPress(CONTROLLER_BUTTON.Back)

  assert(writes == writesBefore)
  assertEngineRecord(
    Bindings.values['H3UI.NavigateLeft.controller'],
    'controller',
    CONTROLLER_BUTTON.DPadLeft,
    Intent.Left
  )
  assert(slotControls(3, 3).label ~= 'input_binding_listening')

  InputPage.onKeyPress(keyPress(KEY.X))
  InputPage.onControllerButtonPress(CONTROLLER_BUTTON.X)
  assert(writes == writesBefore)
end

local function testEscapeRecordsLikeAnyKey()
  activate(slotControls(3, 1).record)
  InputPage.onKeyPress(keyPress(KEY.Escape))

  assertEngineRecord(
    Bindings.values['H3UI.NavigateLeft.keyboard'],
    'keyboard',
    KEY.Escape,
    Intent.Left
  )
  assert(slotControls(3, 1).label == 'Escape')

  activate(slotControls(3, 1).default)
  assertEngineRecord(Bindings.values['H3UI.NavigateLeft.keyboard'], 'keyboard', KEY.A, Intent.Left)
end

local function testClearAndRestoreDefault()
  local controls = slotControls(4, 1)
  assert(controls.default)
  activate(controls.clear)

  assert(Bindings.values['H3UI.NavigateRight.keyboard'] == nil)
  assert(BindingStates.values['H3UI.NavigateRight.keyboard'] == 'cleared')
  assert(slotControls(4, 1).label == 'None')

  activate(slotControls(4, 1).default)
  assertEngineRecord(
    Bindings.values['H3UI.NavigateRight.keyboard'],
    'keyboard',
    KEY.D,
    Intent.Right
  )
  assert(BindingStates.values['H3UI.NavigateRight.keyboard'] == 'configured')

  local mouse = slotControls(4, 2)
  assert(mouse.clear and mouse.default == nil)
end

local function testSecondRecordingCannotStart()
  activate(slotControls(6, 1).record)
  activate(slotControls(6, 3).record)

  assert(slotControls(6, 1).label == 'input_binding_listening')
  assert(slotControls(6, 3).label ~= 'input_binding_listening')

  InputPage.onControllerButtonPress(CONTROLLER_BUTTON.X)
  assertEngineRecord(
    Bindings.values['H3UI.Cancel.keyboard'],
    'controller',
    CONTROLLER_BUTTON.X,
    Intent.Cancel
  )
  assertEngineRecord(
    Bindings.values['H3UI.Cancel.controller'],
    'controller',
    CONTROLLER_BUTTON.B,
    Intent.Cancel
  )
end

testDefinitions()
testInputOutsideRecordingWritesNothing()
testRegisterActionsBeforePage()
testDefaultsInitialised()
testRecordingWritesEngineRecord()
testBackspaceAndBackCancelRecording()
testEscapeRecordsLikeAnyKey()
testClearAndRestoreDefault()
testSecondRecordingCannotStart()

print 'H3UI input tests passed'
