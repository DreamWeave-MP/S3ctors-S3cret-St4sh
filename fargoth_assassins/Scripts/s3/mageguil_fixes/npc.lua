local core = require('openmw.core')
local self = require('openmw.self')

local I = require('openmw.interfaces')

return {
  eventHandlers = {
    S3_AffAss_FargothMinionSpawn = function(playerTarget)
      if string.find(self.recordId, 'affass_') then return end

      local package = I.AI.getActivePackage()

      if not package or package.type ~= "Wander" or package.distance == 0 or math.random() >= .25 then return end

      playerTarget:sendEvent('S3_AffAss_FargothSelected', self.object)
      core.sendGlobalEvent('S3_AffAss_NewFargothMinion', self.object)
    end,
    S3_AffAss_MinionEquip = function(equipment)
      self.type.setEquipment(self, equipment)
    end,
  }
}
