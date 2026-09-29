---@omw-context menu

local I = require 'openmw.interfaces'

local GROUP_NAME = 'SettingsPlayerHoriz0n'

---@type table<string, { integer: boolean?, min: number, max: number }>
local ARGUMENTS = {
  Horiz0nTargetFramerate = { integer = true, min = 20, max = 360 },
  Horiz0nMinViewDistance = { integer = false, min = 0.01, max = 1.0 },
  Horiz0nMaxViewDistance = { integer = false, min = 1.0, max = 100.0 },
  Horiz0nAdjustFramerate = { min = 10, max = 144 },
  Horiz0nPercentAdjustNormal = { min = 1, max = 10 },
  Horiz0nPercentAdjustSevere = { min = 10, max = 50 },
  Horiz0nViewDistanceStepPercent = { integer = false, min = 0.25, max = 5.0 },
  Horiz0nViewDistanceSevereMult = { min = 1.0, max = 5.0 },
}

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
      key = 'Horiz0nTargetFramerate',
      renderer = 'number',
      name = 'Horiz0nTargetFramerateName',
      description = 'Horiz0nTargetFramerateDesc',
      default = 60,
      argument = ARGUMENTS.Horiz0nTargetFramerate,
    },
    {
      key = 'Horiz0nMinViewDistance',
      renderer = 'number',
      name = 'Horiz0nMinViewDistName',
      description = 'Horiz0nMinViewDistDesc',
      default = 0.25,
      argument = ARGUMENTS.Horiz0nMinViewDistance,
    },
    {
      key = 'Horiz0nMaxViewDistance',
      renderer = 'number',
      name = 'Horiz0nMaxViewDistName',
      description = 'Horiz0nMaxViewDistDesc',
      default = 25.0,
      argument = ARGUMENTS.Horiz0nMaxViewDistance,
    },
    {
      key = 'Horiz0nAdjustFramerate',
      renderer = 'number',
      name = 'Horiz0nAdjustFramerateName',
      description = 'Horiz0nAdjustFramerateDesc',
      default = 30,
      argument = ARGUMENTS.Horiz0nAdjustFramerate,
    },
    {
      key = 'Horiz0nPercentAdjustNormal',
      renderer = 'number',
      name = 'Horiz0nPercentAdjustNormalName',
      description = 'Horiz0nPercentAdjustNormalDesc',
      default = 10,
      argument = ARGUMENTS.Horiz0nPercentAdjustNormal,
    },
    {
      key = 'Horiz0nPercentAdjustSevere',
      renderer = 'number',
      name = 'Horiz0nPercentAdjustSevereName',
      description = 'Horiz0nPercentAdjustSevereDesc',
      default = 30,
      argument = ARGUMENTS.Horiz0nPercentAdjustSevere,
    },
    {
      key = 'Horiz0nViewDistanceStepPercent',
      renderer = 'number',
      name = 'Horiz0nViewDistanceStepPercentName',
      description = 'Horiz0nViewDistanceStepPercentDesc',
      default = 1.0,
      argument = ARGUMENTS.Horiz0nViewDistanceStepPercent,
    },
    {
      key = 'Horiz0nViewDistanceSevereMult',
      renderer = 'number',
      name = 'Horiz0nViewDistanceSevereMultName',
      description = 'Horiz0nViewDistanceSevereMultDesc',
      default = 2.0,
      argument = ARGUMENTS.Horiz0nViewDistanceSevereMult,
    },
  },
}

--- OpenMW replaces the whole renderer argument, so the registered bounds must be resent with every update.
---@param settingKey string
---@param dynamicArgument { disabled: boolean, min: number?, max: number? }
local function updateArgument(settingKey, dynamicArgument)
  local argument = {}
  for key, value in next, ARGUMENTS[settingKey] do
    argument[key] = value
  end
  for key, value in next, dynamicArgument do
    argument[key] = value
  end

  I.Settings.updateRendererArgument(GROUP_NAME, settingKey, argument)
end

local Horiz0nSettings = require('openmw.storage').playerSection(GROUP_NAME)
Horiz0nSettings:subscribe(require('openmw.async'):callback(function(_, _)
  local disabled = not Horiz0nSettings:get 'Horiz0nToggle'

  local NormalAdjust, SevereAdjust =
    Horiz0nSettings:get 'Horiz0nPercentAdjustNormal',
    Horiz0nSettings:get 'Horiz0nPercentAdjustSevere'

  local MinDist, MaxDist =
    Horiz0nSettings:get 'Horiz0nMinViewDistance', Horiz0nSettings:get 'Horiz0nMaxViewDistance'

  updateArgument('Horiz0nTargetFramerate', { disabled = disabled })

  updateArgument('Horiz0nPercentAdjustNormal', {
    max = math.min(ARGUMENTS.Horiz0nPercentAdjustNormal.max, SevereAdjust - 1),
    disabled = disabled,
  })

  updateArgument('Horiz0nPercentAdjustSevere', {
    min = math.max(ARGUMENTS.Horiz0nPercentAdjustSevere.min, NormalAdjust + 1),
    disabled = disabled,
  })

  updateArgument('Horiz0nMinViewDistance', {
    max = math.min(ARGUMENTS.Horiz0nMinViewDistance.max, MaxDist - 0.01),
    disabled = disabled,
  })

  updateArgument('Horiz0nMaxViewDistance', {
    min = math.max(ARGUMENTS.Horiz0nMaxViewDistance.min, MinDist + 0.01),
    disabled = disabled,
  })

  updateArgument('Horiz0nViewDistanceStepPercent', { disabled = disabled })

  updateArgument('Horiz0nViewDistanceSevereMult', { disabled = disabled })

  updateArgument('Horiz0nAdjustFramerate', { disabled = disabled })
end))
