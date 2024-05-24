local core = require('openmw.core')
local input = require('openmw.input')
local playerSelf = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')

local Mode = require('Scripts.Modes.Mode')

local Clone = Mode:new({
  name = "Clone",
  clipboardTarget = nil,
  submodeIndex = 1,
  subModes = {
    "copy",
    "paste"
  }
})

function Clone:input(key)
  self:switchSubmode(key)
end

function Clone:func()
    local cloneMode = self:getSubmode()
    local target = self.getTarget()

    if not target or target.recordId == 'player' then return end

    if cloneMode == "copy" then
        if not target.hitObject then return end
        local copyString

        self.clipboardTarget = target.hitObject

        if input.isKeyPressed(input.KEY.LeftShift) then
            core.sendGlobalEvent('Delete', {target = target.hitObject})
            copyString = "Cut"
        else
            copyString = "Copied"
        end

        ui.showMessage(copyString .. ": " .. self.clipboardTarget.recordId)

    elseif cloneMode == 'paste' then

        if input.isKeyPressed(input.KEY.LeftShift) then
            if not target.hitObject then return end

            if not self.clipboardTarget then
                ui.showMessage("Warning! No clipboard item is selected. Use the Clone mode to copy an object first.")
                return
            end

            core.sendGlobalEvent('Clone', {
                                     object = self.clipboardTarget,
                                     target = target.hitObject,
                                     position = target.hitObject.position,
                                     rotation = target.hitObject.rotation,
                                     cell = target.hitObject.cell.name
        })
        else
            if not target.hitPos then return end

            core.sendGlobalEvent('Clone', {
                                     object = self.clipboardTarget,
                                     position = target.hitPos,
                                     rotation = util.vector3(0, 0, 0),
            cell = playerSelf.cell.name,
            })
        end
    end
end

return Clone
