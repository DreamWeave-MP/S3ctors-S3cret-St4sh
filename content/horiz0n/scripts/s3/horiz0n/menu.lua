---@omw-context menu

local I = require 'openmw.interfaces'

I.Settings.registerPage {
  key = 'Horiz0nPage',
  l10n = 'horiz0n',
  name = 'Horiz0nPageName',
  description = 'Horiz0nPageDesc',
}

I.Settings.registerGroup {
  key = 'SettingsPlayerHoriz0n',
  page = 'Horiz0nPage',
  l10n = 'horiz0n',
  name = 'Horiz0nManagerSettingsName',
  description = 'Horiz0nManagerSettingsDesc',
  permanentStorage = true,
  settings = {
    {
      key = 'Horiz0nToggle',
      renderer = 'checkbox',
      name = 'Horiz0nToggleName',
      description = '',
      default = true,
      argument = {
        l10n = 'horiz0n',
        trueLabel = 'Horiz0nToggleOn',
        falseLabel = 'Horiz0nToggleOff',
      },
    },
    {
      key = 'Horiz0nMinViewDistance',
      renderer = 'number',
      name = 'Horiz0nMinViewDistName',
      description = 'Horiz0nMinViewDistDesc',
      default = 0.25,
      argument = {
        integer = false,
        max = 1.0,
        min = 0.01,
      },
    },
    {
      key = 'Horiz0nMaxViewDistance',
      renderer = 'number',
      name = 'Horiz0nMaxViewDistName',
      description = 'Horiz0nMaxViewDistDesc',
      default = 25.0,
      argument = {
        integer = false,
        min = 1.0,
        max = 100.0,
      },
    },
  },
}
