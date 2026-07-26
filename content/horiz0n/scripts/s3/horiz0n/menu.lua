---@omw-context menu

local I = require 'openmw.interfaces'

local GROUP_NAME = 'SettingsPlayerHoriz0n'

I.Settings.registerPage {
  key = 'Horiz0nPage',
  l10n = 'horiz0n',
  name = 'Horiz0nPageName',
  description = 'Horiz0nPageDesc',
}

I.Settings.registerGroup {
  key = GROUP_NAME,
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
    {
      key = 'Horiz0nAdjustFramerate',
      renderer = 'number',
      name = 'Horiz0nAdjustFramerateName',
      description = 'Horiz0nAdjustFramerateDesc',
      default = 30,
      argument = {
        min = 10,
        max = 144,
      },
    },
    {
      key = 'Horiz0nPercentAdjustNormal',
      renderer = 'number',
      name = 'Horiz0nPercentAdjustNormalName',
      description = 'Horiz0nPercentAdjustNormalDesc',
      default = 10,
      argument = {
        min = 1,
        max = 10,
      },
    },
    {
      key = 'Horiz0nPercentAdjustSevere',
      renderer = 'number',
      name = 'Horiz0nPercentAdjustSevereName',
      description = 'Horiz0nPercentAdjustSevereDesc',
      default = 30,
      argument = {
        min = 10,
        max = 50,
      },
    },
    {
      key = 'Horiz0nViewDistanceStep',
      renderer = 'number',
      name = 'Horiz0nViewDistanceStepName',
      description = 'Horiz0nViewDistanceStepDesc',
      default = 16,
      argument = {
        min = 8,
        max = 24,
      },
    },
    {
      key = 'Horiz0nViewDistanceSevereMult',
      renderer = 'number',
      name = 'Horiz0nViewDistanceSevereMultName',
      description = 'Horiz0nViewDistanceSevereMultDesc',
      default = 2.0,
      argument = {
        min = 1.0,
        max = 5.0,
      },
    },
  },
}

local Horiz0nSettings = require('openmw.storage').playerSection(GROUP_NAME)
Horiz0nSettings:subscribe(require('openmw.async'):callback(function(_, _)
  local disabled = not Horiz0nSettings:get 'Horiz0nToggle'

  local NormalAdjust, SevereAdjust =
    Horiz0nSettings:get 'Horiz0nPercentAdjustNormal',
    Horiz0nSettings:get 'Horiz0nPercentAdjustSevere'

  local MinDist, MaxDist =
    Horiz0nSettings:get 'Horiz0nMinViewDistance', Horiz0nSettings:get 'Horiz0nMaxViewDistance'

  I.Settings.updateRendererArgument(
    GROUP_NAME,
    'Horiz0nPercentAdjustNormal',
    { max = SevereAdjust - 1, disabled = disabled }
  )

  I.Settings.updateRendererArgument(
    GROUP_NAME,
    'Horiz0nPercentAdjustSevere',
    { min = NormalAdjust + 1, disabled = disabled }
  )

  I.Settings.updateRendererArgument(
    GROUP_NAME,
    'Horiz0nMinViewDistance',
    { max = MaxDist - 0.01, disabled = disabled }
  )

  I.Settings.updateRendererArgument(
    GROUP_NAME,
    'Horiz0nMaxViewDistance',
    { min = MinDist + 0.01, disabled = disabled }
  )

  I.Settings.updateRendererArgument(GROUP_NAME, 'Horiz0nViewDistanceStep', { disabled = disabled })

  I.Settings.updateRendererArgument(
    GROUP_NAME,
    'Horiz0nViewDistanceSevereMult',
    { disabled = disabled }
  )

  I.Settings.updateRendererArgument(GROUP_NAME, 'Horiz0nAdjustFramerate', { disabled = disabled })
end))
