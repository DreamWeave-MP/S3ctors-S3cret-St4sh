local input = require 'openmw.input'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local MountTarget

---@alias ActionName
---| 'movement'
---| 'sideMovement'
---| 'jump'
---| 'yawChange'
---| 'pitchChange'
---| 'run'

---@alias InputFunction fun(): ActionName, number|boolean

---@type InputFunction[]
local InputFunctions = {
    function()
        return 'movement', input.getRangeActionValue('MoveForward') - input.getRangeActionValue('MoveBackward')
    end,
    function()
        return 'sideMovement', input.getRangeActionValue('MoveRight') - input.getRangeActionValue('MoveLeft')
    end,
    function()
        return 'yawChange', s3lf.controls.yawChange
    end,
    function()
        return 'pitchChange', s3lf.controls.pitchChange
    end,
    function()
        return 'run', s3lf.controls.run
    end,
    function()
        return 'jump', s3lf.controls.jump
    end,
}

---@class InputInfo
---@field movement number Forward/backward movement
---@field sideMovement number horizontal movement
---@field yawChange number
---@field pitchChange number
---@field jump boolean
---@field run boolean
local InputInfo = {
    movement = 0,
    sideMovement = 0,
    jump = false,
    yawChange = 0,
    pitchChange = 0,
}

--- Updates all appropriate movement info for the player, to be relayed to the mount.
--- Returns bool to indicate whether or not to actually bother updating controls.
--- Maybe this is bad...?
---@return boolean
local function updateInputInfo()
    local moved = false

    for _, inputFunction in ipairs(InputFunctions) do
        local actionName, actionValue = inputFunction()
        InputInfo[actionName] = actionValue

        local actionType = type(actionValue)

        if (actionType == 'number' and actionValue ~= 0) then
            s3lf.controls[actionName] = 0
            moved = true
        elseif (actionType == 'boolean' and actionValue) then
            s3lf.controls[actionName] = false
            moved = true
        end
    end

    return moved
end

return {
    engineHandlers = {
        onFrame = function()
            if not MountTarget or not updateInputInfo() then return end
            MountTarget:sendEvent('P37ZControl', InputInfo)
        end,
    },
    eventHandlers = {
        P37ZMountEnable = function(mount)
            MountTarget = MountTarget == nil and mount or nil
        end,
    },
}
