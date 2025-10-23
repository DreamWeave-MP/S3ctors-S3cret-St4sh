local modInfo = require 'scripts.s3.CHIM2090.modInfo'
local I = require 'openmw.interfaces'

I.Settings.registerPage {
  key = modInfo.name,
  l10n = modInfo.l10nName,
  name = 'CHIM 2090 - Damage, Crit, Fumble',
  description = 'Manages actor fatigue, carry weight, hit chance, and strength in combat.'
}

I.Settings.registerPage {
  key = modInfo.name .. 'Block & Parry',
  l10n = modInfo.l10nName,
  name = 'CHIM 2090 - Block & Parry',
  description = 'Manages blocking and parrying effectiveness and formulae.'
}

I.Settings.registerPage {
  key = modInfo.name .. 'Dynamic Stats',
  l10n = modInfo.l10nName,
  name = 'CHIM 2090 - Dynamic Stats',
  description = 'DynamicStatPageDesc',
}

I.Settings.registerPage {
  key = modInfo.name .. 'Poise',
  l10n = modInfo.l10nName,
  name = 'CHIM 2090 - Poise',
  description = 'PoiseStatPageDesc',
}

print(
  ('%s loaded version %s. Thank you for playing %s! <3'):format(
    modInfo.logPrefix,
    modInfo.version,
    modInfo.name)
)
