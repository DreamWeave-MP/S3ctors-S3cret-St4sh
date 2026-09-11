---@omw-context global

local I = require 'openmw.interfaces'

I.Settings.registerGroup {
  key = 'SettingsStaticSwitcher',
  l10n = 'StaticSwitcher',
  page = 'StaticSwitcherPage',
  name = 'StaticSwitcherSettings',
  description = '',
  permanentStorage = true,
  settings = {
    {
      key = 'StaticSwitcherEnableDebug',
      renderer = 'checkbox',
      name = 'StaticSwitcherEnableDebugName',
      description = 'StaticSwitcherEnableDebugDesc',
      default = false,
      argument = {
        l10n = 'StaticSwitcher',
        trueLabel = 'StaticSwitcherTrueLabel',
        falseLabel = 'StaticSwitcherFalseLabel',
      },
    },
  },
}
