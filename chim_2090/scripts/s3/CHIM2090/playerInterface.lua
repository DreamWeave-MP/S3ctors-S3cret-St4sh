local I = require('openmw.interfaces')

local modInfo = require('scripts.s3.CHIM2090.modInfo')

I.Settings.registerPage {
  key = modInfo.name,
  l10n = modInfo.l10nName,
  name = "CHIM 2090",
  description = "Manages actor fatigue, carry weight, hit chance, and strength in combat."
}

print(string.format("%s loaded version %s. Thank you for playing %s! <3",
                    modInfo.logPrefix,
                    modInfo.version,
                    modInfo.name))

return {
  interfaceName = 'chimInterfacePlayer',
  interface = {
    version = modInfo.version,
  }
}
