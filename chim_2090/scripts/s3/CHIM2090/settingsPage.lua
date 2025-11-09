local core = require 'openmw.core'
local input = require 'openmw.input'

--- https://gitlab.com/OpenMW/openmw/-/merge_requests/4334
--- https://gitlab.com/OpenMW/openmw/-/blob/96d0d1fa7cd83e41853061cca68f612b7eb9c834/CMakeLists.txt#L85
local onHitAPIRevision = 85
if core.API_REVISION < onHitAPIRevision then
  error 'CHIM-2090 requires openmw 0.50 and later! Sorry :('
end

local modInfo = require 'scripts.s3.CHIM2090.modInfo'
local I = require 'openmw.interfaces'

---@class SettingsPageData
---@field key string
---@field l10n string
---@field name string
---@field description string

---@type fun(settingsData: SettingsPageData)
local RegisterPage = I.Settings.registerPage

RegisterPage {
  key = modInfo.name,
  l10n = modInfo.l10nName,
  name = 'PageCoreName',
  description = 'PageCoreDesc'
}

RegisterPage {
  key = modInfo.name .. 'Block & Parry',
  l10n = modInfo.l10nName,
  name = 'PageBlockAndParryName',
  description = 'PageBlockAndParryDesc'
}

RegisterPage {
  key = modInfo.name .. 'Dynamic Stats',
  l10n = modInfo.l10nName,
  name = 'PageDynamicName',
  description = 'PageDynamicDesc',
}

RegisterPage {
  key = modInfo.name .. 'Poise',
  l10n = modInfo.l10nName,
  name = 'PagePoiseName',
  description = 'PagePoiseDesc',
}

RegisterPage {
  key = modInfo.name .. 'Roll',
  l10n = modInfo.l10nName,
  name = 'RollPageName',
  description = 'RollPageDesc',
}

input.registerAction {
  key = 'CHIMBlockAction',
  name = 'BlockActionName',
  description = 'BlockActionDesc',
  l10n = modInfo.l10nName,
  defaultValue = false,
  type = input.ACTION_TYPE.Boolean,
}

input.registerTrigger {
  key = 'CHIMRollAction',
  name = 'RollActionName',
  description = 'RollActionDesc',
  l10n = modInfo.l10nName,
}

print(
  ('%s loaded version %s. Thank you for playing %s! <3'):format(
    modInfo.logPrefix,
    modInfo.version,
    modInfo.name)
)
