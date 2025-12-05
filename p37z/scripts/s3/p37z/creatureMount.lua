local core = require 'openmw.core'
local types = require 'openmw.types'
local util = require 'openmw.util'

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
    for i = #self.queue, 1, -1 do
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

local firstOrThird = false
local Offsets = {
    ['cliff racer'] = util.vector3(0, -50, 50),
    default = util.vector3(0, -50, -25),
    ['golden saint'] = util.vector3(0, -25, 45),
    guar = util.vector3(0, -50, -25),
}

--- Mount offsets are defined by the center of their box, plus some offset from the player per-mount
local Offset = Offsets[s3lf.recordId] or Offsets.default
local BackOffset

if s3lf.isBiped then
    BackOffset = util.vector3(Offset.x, Offset.y * 3, Offset.z)
else
    BackOffset = Offset
end

local function syncPlayerPosition()
    local center = s3lf.gameObject:getBoundingBox().center

    local doubleY = s3lf.controls.movement < 0

    local myYaw = s3lf.rotation:getYaw()
    local playerTargetPos = center +
        util.transform.rotateZ(myYaw)
        :apply(
            doubleY and BackOffset or Offset
        )
    local playerPosDelta = playerTargetPos - MountTarget.position

    playerPosDelta = playerPosDelta * 25

    local targetYaw = 0.
    if not firstOrThird then
        if util.round(math.deg(myYaw)) ~= util.round(math.deg(MountTarget.rotation:getYaw())) then
            if not core.isWorldPaused() then
                print('updating player yaw', util.round(math.deg(myYaw)),
                    util.round(math.deg(MountTarget.rotation:getYaw())))
            end
            targetYaw = myYaw
        end
    end

    core.sendGlobalEvent('P37Z_PlayerPosSync', {
        x = playerPosDelta.x,
        y = playerPosDelta.y,
        z = playerPosDelta.z,
        yaw = math.deg(targetYaw),
    })
end

---@type table<string, function>
local UpdateFunctions = {
    firstOrThird = function(value)
        firstOrThird = value
    end,
    pitchChange = function(value)
    end,
    run = function(value)
        s3lf.controls.run = value

        if s3lf.canFly and value and math.deg(s3lf.rotation:getPitch()) <= 89. then
            s3lf.controls.pitchChange = math.rad(1)
            print(math.deg(s3lf.rotation:getPitch()))
        end
    end,
    sneak = function(value)
        if not s3lf.canFly or not value or util.round(math.deg(s3lf.rotation:getPitch())) <= -89. then return end
        s3lf.controls.pitchChange = math.rad(-1)
    end,
    sideMovement = function(value)
        local animName = value < 0 and 'walkleft' or 'walkright'

        if s3lf.hasAnimation() and s3lf.hasGroup(animName) then
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

            local combatTargets = I.AI.getTargets('Combat')
            for _, target in ipairs(combatTargets) do
                if target.id == activator.id then return end
            end

            MountTarget = MountTarget == nil and activator or nil

            activator:sendEvent('P37ZMountEnable', s3lf.gameObject)

            local isMounted, position = MountTarget ~= nil, nil

            if isMounted then
                position = s3lf.gameObject:getBoundingBox().center +
                    util.transform.rotateZ(s3lf.rotation:getYaw()):apply(Offset)
            else
                position = s3lf.position
            end

            core.sendGlobalEvent('P37Z_ToggleMount', {
                isMounted = isMounted,
                owner = activator,
                mount = s3lf.gameObject,
                position = position,
            })

            if MountTarget then
                UpdateFunctionManager:addUpdateFunction(syncPlayerPosition)
            else
                UpdateFunctionManager:removeUpdateFunction(syncPlayerPosition)
            end
        end,
        onUpdate = UpdateFunctionManager.update,
        onSave = function()
            return {
                MountTarget = MountTarget,
            }
        end,
        onLoad = function(data)
            data = data or {}
            MountTarget = data.MountTarget
        end,
    },
}
