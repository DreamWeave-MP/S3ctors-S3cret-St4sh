---@omw-context menu
---@module 'scripts.h3.inputPage'

local core = require 'openmw.core'
local input = require 'openmw.input'
local storage = require 'openmw.storage'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local H3Input = require 'scripts.h3.input'
local H3UI = require 'scripts.h3.ui'

local StrFormat = string.format

local BindingSection = storage.playerSection 'OMWInputBindings'
local BindingStateSection = storage.playerSection 'H3UIInputBindingState'
local EngineL10n, InterfaceL10n, L10n = core.l10n 'OMWEngine', core.l10n 'Interface', core.l10n 'H3'
local UiAlignment, UiCreate, UtilVector2 = ui.ALIGNMENT, ui.create, util.vector2

local PageSize = UtilVector2(900, 640)
local InputBindingColumnSize = UtilVector2(112, 0)

local BindingState = {
  Configured = 'configured',
  Cleared = 'cleared',
  Uninitialized = 'uninitialized',
}

local MouseButtonNames = {
  [1] = 'Left',
  [2] = 'Middle',
  [3] = 'Right',
  [4] = '4',
  [5] = '5',
}

local ControllerButtonNames = {
  [-1] = 'Invalid',
  [input.CONTROLLER_BUTTON.A] = 'A',
  [input.CONTROLLER_BUTTON.B] = 'B',
  [input.CONTROLLER_BUTTON.X] = 'X',
  [input.CONTROLLER_BUTTON.Y] = 'Y',
  [input.CONTROLLER_BUTTON.Back] = 'Back',
  [input.CONTROLLER_BUTTON.Guide] = 'Guide',
  [input.CONTROLLER_BUTTON.Start] = 'Start',
  [input.CONTROLLER_BUTTON.LeftStick] = 'Left Stick',
  [input.CONTROLLER_BUTTON.RightStick] = 'Right Stick',
  [input.CONTROLLER_BUTTON.LeftShoulder] = 'LB',
  [input.CONTROLLER_BUTTON.RightShoulder] = 'RB',
  [input.CONTROLLER_BUTTON.DPadUp] = 'D-pad Up',
  [input.CONTROLLER_BUTTON.DPadDown] = 'D-pad Down',
  [input.CONTROLLER_BUTTON.DPadLeft] = 'D-pad Left',
  [input.CONTROLLER_BUTTON.DPadRight] = 'D-pad Right',
}

---@type H3UI.InputBindingRecording?
local inputBindingRecording

---@type openmw.ui.Element?
local pageElement

---@type openmw.ui.SettingsPageOptions?
local pageOptions
local pageLayout

---@param binding? H3UI.InputBindingRecord
---@param isRecording boolean
---@return string
local function inputBindingLabel(binding, isRecording)
  if isRecording then return L10n 'input_binding_listening' end
  if not binding or not binding.button then return InterfaceL10n 'None' end

  if binding.device == 'keyboard' then
    local name = input.getKeyName(binding.button)
    return name ~= '' and name or InterfaceL10n 'NotAvailableShort'
  elseif binding.device == 'mouse' then
    return StrFormat(
      '%s %s',
      InterfaceL10n 'Mouse',
      MouseButtonNames[binding.button] or InterfaceL10n 'NotAvailableShort'
    )
  elseif binding.device == 'controller' then
    return StrFormat(
      '%s %s',
      EngineL10n 'Controller',
      ControllerButtonNames[binding.button] or InterfaceL10n 'NotAvailableShort'
    )
  end

  return InterfaceL10n 'NotAvailableShort'
end

---@param slot H3UI.InputBindingSlot
---@param definition H3UI.InputActionDefinition
---@param button number
---@return H3UI.InputBindingRecord
local function inputBindingRecord(slot, definition, button)
  return {
    device = slot.device,
    button = button,
    type = 'action',
    key = definition.info.key,
  }
end

---@param slot H3UI.InputBindingSlot
---@param definition H3UI.InputActionDefinition
---@return nil
local function initializeInputBinding(slot, definition)
  local state = BindingStateSection:get(slot.id) or BindingState.Uninitialized
  if state == BindingState.Configured or state == BindingState.Cleared then return end

  if BindingSection:get(slot.id) ~= nil then
    BindingStateSection:set(slot.id, BindingState.Configured)
  elseif slot.default ~= nil then
    BindingSection:set(slot.id, inputBindingRecord(slot, definition, slot.default))
    BindingStateSection:set(slot.id, BindingState.Configured)
  end
end

---@return nil
local function refreshPage()
  if not pageElement or not pageElement.layout then return end

  pageElement.layout = pageLayout()
  pageElement:update()
end

---@param slot H3UI.InputBindingSlot
---@param _ H3UI.InputActionDefinition
---@return nil
local function clearInputBinding(slot, _)
  inputBindingRecording = nil
  BindingSection:set(slot.id, nil)
  BindingStateSection:set(slot.id, BindingState.Cleared)
  refreshPage()
end

---@param slot H3UI.InputBindingSlot
---@param definition H3UI.InputActionDefinition
---@return nil
local function restoreInputBinding(slot, definition)
  if slot.default == nil then return end

  inputBindingRecording = nil
  BindingSection:set(slot.id, inputBindingRecord(slot, definition, slot.default))
  BindingStateSection:set(slot.id, BindingState.Configured)
  refreshPage()
end

---@param slot H3UI.InputBindingSlot
---@param definition H3UI.InputActionDefinition
---@return nil
local function startInputBindingRecording(slot, definition)
  if inputBindingRecording then return end

  inputBindingRecording = {
    argument = {
      bindings = definition.bindings,
      key = definition.info.key,
      type = 'action',
    },
    refresh = refreshPage,
    slot = slot,
  }
  refreshPage()
end

---@param device? H3UI.InputBindingDevice
---@param button number
---@return nil
local function bindInputButton(device, button)
  local recording = inputBindingRecording
  if not recording then return end

  if device == nil then
    inputBindingRecording = nil
    refreshPage()
    return
  end

  BindingSection:set(recording.slot.id, {
    device = device,
    button = button,
    type = recording.argument.type,
    key = recording.argument.key,
  })
  BindingStateSection:set(recording.slot.id, BindingState.Configured)
  inputBindingRecording = nil
  refreshPage()
end

---@param slot H3UI.InputBindingSlot
---@param definition H3UI.InputActionDefinition
---@return openmw.ui.Layout
local function bindingSlot(slot, definition)
  initializeInputBinding(slot, definition)

  local binding = BindingSection:get(slot.id)
  local isRecording = inputBindingRecording and inputBindingRecording.slot.id == slot.id
  local deviceLabel = slot.label or L10n(StrFormat('input_binding_%s', slot.device))
  local controls = {
    H3UI.button {
      label = L10n 'input_binding_clear',
      props = { size = UtilVector2(52, 24) },
      onActivate =
        ---@param _ openmw.ui.MouseEvent
        ---@param __ openmw.ui.Layout
        ---@return boolean
        function(_, __)
          clearInputBinding(slot, definition)
          return true
        end,
    },
  }

  if slot.default ~= nil then
    controls[#controls + 1] = H3UI.button {
      label = L10n 'input_binding_default',
      props = { size = UtilVector2(56, 24) },
      onActivate =
        ---@param _ openmw.ui.MouseEvent
        ---@param __ openmw.ui.Layout
        ---@return boolean
        function(_, __)
          restoreInputBinding(slot, definition)
          return true
        end,
    }
  end

  return H3UI.column {
    gap = 4,
    props = { size = InputBindingColumnSize },
    H3UI.text {
      text = deviceLabel,
      props = { textAlignH = UiAlignment.Center },
    },
    H3UI.button {
      label = inputBindingLabel(binding, isRecording),
      props = { size = UtilVector2(112, 28) },
      onActivate =
        ---@param _ openmw.ui.MouseEvent
        ---@param __ openmw.ui.Layout
        ---@return boolean
        function(_, __)
          startInputBindingRecording(slot, definition)
          return true
        end,
    },
    H3UI.row {
      gap = 4,
      children = controls,
    },
  }
end

---@param definition H3UI.InputActionDefinition
---@return openmw.ui.Layout
local function bindingRow(definition)
  local info = definition.info
  local slots = {}

  for index = 1, #definition.bindings do
    slots[index] = bindingSlot(definition.bindings[index], definition)
  end

  local children = {
    H3UI.column {
      gap = 2,
      external = { grow = 1 },
      H3UI.text { text = L10n(info.name) },
      H3UI.text { text = L10n(info.description) },
    },
  }
  for index = 1, #slots do
    children[#children + 1] = slots[index]
  end

  return H3UI.row {
    gap = 8,
    children = children,
  }
end

---@return openmw.ui.Layout
pageLayout = function()
  local definitions = H3Input.getActionDefinitions()
  local rows = {
    H3UI.text { text = L10n 'H3UIInputPageName' },
    H3UI.text { text = L10n 'H3UIInputPageDescription' },
  }

  local headings = { H3UI.text { external = { grow = 1 } } }
  for index = 1, #definitions[1].bindings do
    local slot = definitions[1].bindings[index]
    headings[#headings + 1] = H3UI.text {
      text = slot.label or L10n(StrFormat('input_binding_%s', slot.device)),
      props = { size = InputBindingColumnSize, textAlignH = UiAlignment.Center },
    }
  end
  rows[#rows + 1] = H3UI.row { gap = 8, children = headings }

  for index = 1, #definitions do
    rows[#rows + 1] = bindingRow(definitions[index])
  end

  return H3UI.column {
    props = { size = PageSize },
    gap = 8,
    children = rows,
  }
end

---@return nil
local function register()
  if pageOptions then return end

  H3Input.registerActions()
  pageElement = UiCreate(pageLayout())
  pageOptions = {
    name = L10n 'H3UIInputPageName',
    searchHints = 'H3 controls input bindings keyboard mouse controller navigation',
    element = pageElement,
  }
  ui.registerSettingsPage(pageOptions)
end

---@param event openmw.input.KeyboardEvent
---@return nil
local function onKeyPress(event)
  bindInputButton(event.code ~= input.KEY.Escape and 'keyboard' or nil, event.code)
end

---@param button number
---@return nil
local function onMouseButtonPress(button) bindInputButton('mouse', button) end

---@param button number
---@return nil
local function onControllerButtonPress(button) bindInputButton('controller', button) end

return {
  bindInputButton = bindInputButton,
  onControllerButtonPress = onControllerButtonPress,
  onKeyPress = onKeyPress,
  onMouseButtonPress = onMouseButtonPress,
  register = register,
}
