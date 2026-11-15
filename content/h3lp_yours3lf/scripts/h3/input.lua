---@omw-context menu|player
---@module 'scripts.h3.input'

local input = require 'openmw.input'

local StrFormat = string.format

local Input = {}

---@type H3UI.Intent
local Intent = {
  Activate = 'H3UI.Activate',
  Cancel = 'H3UI.Cancel',
  Down = 'H3UI.NavigateDown',
  Left = 'H3UI.NavigateLeft',
  Right = 'H3UI.NavigateRight',
  Up = 'H3UI.NavigateUp',
}

Input.Intent = Intent

---@type H3UI.InputActionDefinition[]
local ActionDefinitions = {}
local actionsRegistered = false

---@param info openmw.input.ActionInfo
---@param settingKey string
---@param bindings H3UI.InputBindingSlot[]
---@return nil
local function registerAction(info, settingKey, bindings)
  local definition = {
    bindings = bindings,
    info = info,
    settingKey = settingKey,
  }
  ActionDefinitions[#ActionDefinitions + 1] = definition
end

---@param key string
---@param name string
---@param description string
---@param settingKey string
---@param keyboardDefault number
---@param controllerDefault number
---@return nil
local function registerBooleanAction(
  key,
  name,
  description,
  settingKey,
  keyboardDefault,
  controllerDefault
)
  registerAction(
    {
      key = key,
      type = input.ACTION_TYPE.Boolean,
      l10n = 'H3',
      name = name,
      description = description,
      defaultValue = false,
    },
    settingKey,
    {
      {
        id = StrFormat('%s.keyboard', key),
        device = 'keyboard',
        default = keyboardDefault,
      },
      {
        id = StrFormat('%s.mouse', key),
        device = 'mouse',
      },
      {
        id = StrFormat('%s.controller', key),
        device = 'controller',
        default = controllerDefault,
      },
    }
  )
end

registerBooleanAction(
  Intent.Up,
  'H3UIInputNavigateUpName',
  'H3UIInputNavigateUpDescription',
  'navigateUp',
  input.KEY.W,
  input.CONTROLLER_BUTTON.DPadUp
)
registerBooleanAction(
  Intent.Down,
  'H3UIInputNavigateDownName',
  'H3UIInputNavigateDownDescription',
  'navigateDown',
  input.KEY.S,
  input.CONTROLLER_BUTTON.DPadDown
)
registerBooleanAction(
  Intent.Left,
  'H3UIInputNavigateLeftName',
  'H3UIInputNavigateLeftDescription',
  'navigateLeft',
  input.KEY.A,
  input.CONTROLLER_BUTTON.DPadLeft
)
registerBooleanAction(
  Intent.Right,
  'H3UIInputNavigateRightName',
  'H3UIInputNavigateRightDescription',
  'navigateRight',
  input.KEY.D,
  input.CONTROLLER_BUTTON.DPadRight
)
registerBooleanAction(
  Intent.Activate,
  'H3UIInputActivateName',
  'H3UIInputActivateDescription',
  'activate',
  input.KEY.Enter,
  input.CONTROLLER_BUTTON.A
)
registerBooleanAction(
  Intent.Cancel,
  'H3UIInputCancelName',
  'H3UIInputCancelDescription',
  'cancel',
  input.KEY.Escape,
  input.CONTROLLER_BUTTON.B
)

---@return H3UI.InputActionDefinition[]
function Input.getActionDefinitions()
  local definitions = {}

  for index = 1, #ActionDefinitions do
    definitions[index] = ActionDefinitions[index]
  end

  return definitions
end

---@return nil
function Input.registerActions()
  if actionsRegistered then return end

  for index = 1, #ActionDefinitions do
    local definition = ActionDefinitions[index]
    if not input.actions[definition.info.key] then input.registerAction(definition.info) end
  end

  actionsRegistered = true
end

return Input
