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

print(
  ('%s loaded version %s. Thank you for playing %s! <3'):format(
    modInfo.logPrefix,
    modInfo.version,
    modInfo.name)
)
