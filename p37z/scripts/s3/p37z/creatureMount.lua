local core = require 'openmw.core'
local types = require 'openmw.types'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local MountTarget

---@alias UpdateFunction fun(dt: number): boolean

---@class UpdateFunctionManager
local UpdateFunctionManager = {
    ---@type UpdateFunction[]
    queue = {}
}

---@param updateFunction UpdateFunction
---@return boolean
function UpdateFunctionManager:removeUpdateFunction(updateFunction)
    for i = #self.queue, -1 do
        if self.queue[i] == updateFunction then
            table.remove(self.queue, i)
            return true
        end
    end

    return false
end

---@param updateFunction UpdateFunction
---@return boolean
function UpdateFunctionManager:addUpdateFunction(updateFunction)
    local numUpdaters = #self.queue
    for i = numUpdaters, -1 do if self.queue[i] == updateFunction then return false end end
    self.queue[numUpdaters + 1] = updateFunction

    return true
end

---@param inputFunction UpdateFunction
---@return number? updateFunctionIndex
function UpdateFunctionManager:getUpdateFunctionIndex(inputFunction)
    for i, updateFunction in ipairs(self.queue) do if inputFunction == updateFunction then return i end end
end

function UpdateFunctionManager.update()
    local realFrameTime = core.getRealFrameDuration()
    for _, updateFunction in ipairs(UpdateFunctionManager.queue) do if updateFunction(realFrameTime) then break end end
end

---@type table<string, function>
local UpdateFunctions = {
    sideMovement = function(value)
        local animName = value < 0 and 'walkleft' or 'walkright'

        if s3lf.hasGroup(animName) then
            s3lf.controls.sideMovement = value
        else
            s3lf.controls.yawChange = math.rad(value)
        end
    end,
}

return {
    eventHandlers = {
        --- Most creatures don't have horizontal/backward movement, so maybe
        --- We need an explicit check for whether or not they have any of those three anims.
        --- But, in almost every case, we should at least have one
        ---@param inputInfo InputInfo
        P37ZControl = function(inputInfo)
            for actionName, actionValue in pairs(inputInfo) do
                local updater = UpdateFunctions[actionName]
                if updater then
                    updater(actionValue)
                elseif actionValue ~= 0 and actionValue then
                    s3lf.controls[actionName] = actionValue
                end
            end
        end,
    },
    engineHandlers = {
        onActivated = function(activator)
            if not types.Player.objectIsInstance(activator) then return end
            MountTarget = MountTarget == nil and activator or nil
            activator:sendEvent('P37ZMountEnable', s3lf.gameObject)
        end,
        -- onUpdate = UpdateFunctionManager.update,
    },
}
