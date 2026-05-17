--[[
local ui = require('openmw.ui')

local keys = common.keys

local Mode = require('Scripts.Modes.Mode')
]]--
local common = require('openmw.interfaces').toolGun_p
local core = require('openmw.core')
local playerSelf = require('openmw.self')

local Delete = {
  name = "Delete"
}

function Delete:input(key)
  if key.symbol == common.keys.scaleDown and key.withShift then
    core.sendGlobalEvent("Delete", {playerCell = playerSelf.cell.name})
    if self.undoIndex and self.undoIndex <= 10 then
      self.undotable[self.undoIndex] = nil
    end
  end
end

return Delete
