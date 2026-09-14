---@omw-context player

local input = require 'openmw.input'
local Settings = require('openmw.interfaces').Settings

local L10N = 'Transmog'

local actions = {
  {
    key = 'transmogRotateLeft',
    l10n = L10N,
    name = 'TransmogRotateLeftActionName',
    description = 'TransmogRotateLeftActionDesc',
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false,
  },

  {
    key = 'transmogRotateRight',
    l10n = L10N,
    name = 'TransmogRotateRightActionName',
    description = 'TransmogRotateRightActionDesc',
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false,
  },

  {
    key = 'transmogPreview',
    l10n = L10N,
    name = 'TransmogPreviewActionName',
    description = 'TransmogPreviewActionDesc',
    type = input.ACTION_TYPE.Boolean,
    defaultValue = false,
  },
}

local triggers = {
  {
    key = 'transmogOpen',
    l10n = L10N,
    name = 'TransmogOpenActionName',
    description = 'TransmogOpenActionDesc',
  },

  {
    key = 'transmogConfirm',
    l10n = L10N,
    name = 'TransmogConfirmActionName',
    description = 'TransmogConfirmActionDesc',
  },
}

for index = 1, #actions do
  input.registerAction(actions[index])
end

for index = 1, #triggers do
  input.registerTrigger(triggers[index])
end

Settings.registerPage {
  key = 's3_transmog',
  l10n = L10N,
  name = 'TransmogPageName',
  description = 'TransmogPageDesc',
}

Settings.registerGroup {
  key = 'SettingsTransmog',
  page = 's3_transmog',
  l10n = L10N,
  name = 'TransmogSettingsName',
  description = 'TransmogSettingsDesc',
  permanentStorage = true,
  settings = {
    {
      key = 'open',
      renderer = 'inputBinding',
      name = 'TransmogOpenBindingName',
      description = 'TransmogOpenBindingDesc',
      default = 'TransmogOpenBindingKey',
      argument = { key = 'transmogOpen', type = 'trigger' },
    },

    {
      key = 'confirm',
      renderer = 'inputBinding',
      name = 'TransmogConfirmBindingName',
      description = 'TransmogConfirmBindingDesc',
      default = 'TransmogConfirmBindingKey',
      argument = { key = 'transmogConfirm', type = 'trigger' },
    },

    {
      key = 'preview',
      renderer = 'inputBinding',
      name = 'TransmogPreviewBindingName',
      description = 'TransmogPreviewBindingDesc',
      default = 'TransmogPreviewBindingKey',
      argument = { key = 'transmogPreview', type = 'action' },
    },

    {
      key = 'left',
      renderer = 'inputBinding',
      name = 'TransmogRotateLeftBindingName',
      description = 'TransmogRotateLeftBindingDesc',
      default = 'TransmogRotateLeftBindingKey',
      argument = { key = 'transmogRotateLeft', type = 'action' },
    },

    {
      key = 'right',
      renderer = 'inputBinding',
      name = 'TransmogRotateRightBindingName',
      description = 'TransmogRotateRightBindingDesc',
      default = 'TransmogRotateRightBindingKey',
      argument = { key = 'transmogRotateRight', type = 'action' },
    },
  },
}
