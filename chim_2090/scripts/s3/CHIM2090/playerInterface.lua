local ui = require('openmw.ui')

local modInfo = require('scripts.s3.CHIM2090.modInfo')

return {
  interfaceName = 'chimInterfacePlayer',
  interface = {
    version = modInfo.version,
    notifyPlayer = function(...)
      ui.showMessage(table.concat({...}, " "))
    end,
  }
}
