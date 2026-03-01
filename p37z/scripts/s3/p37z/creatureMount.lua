local core = require 'openmw.core'
local nearby = require 'openmw.nearby'
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

function UpdateFunctionManager.update(dt)
    if core.isWorldPaused() then return end

    for _, updateFunction in ipairs(UpdateFunctionManager.queue) do if updateFunction(dt) then break end end
end

local firstOrThird = false
--- Describes relative offsets using the actor's current halfSizes
--- Generally, should be 0 on X axis and between -1, 1 on Y/Z
---@type table<string, util.vector3>
local Offsets = {
    ['cliff racer'] = util.vector3(0, -.5, .5),
    default = util.vector3(0, -.5, 1.),
    ['golden saint'] = util.vector3(0, -.8, .5),
    guar = util.vector3(0, -.5, 1),
    imperfect = util.vector3(.05, -.195, .925),
    -- rat = util.vector3(0, 0, 0),
    -- sw_spevensmugship02 = util.vector3(0, 0, 0),
    -- sw_spevenpirategen = util.vector3(0, -250, -50),
}

local isBiped, Offset = s3lf.isBiped, Offsets[s3lf.recordId] or Offsets.default
local BackMult = util.vector3(1, 3, 1)
local function getTargetPosition(goingBackwards)
    local box = s3lf.gameObject:getBoundingBox()
    local center, halfSize = box.center, box.halfSize

    local activeOffset = Offset:emul(halfSize)
    if goingBackwards and isBiped then
        activeOffset = activeOffset:emul(BackMult)
    end

    local myYaw = s3lf.rotation:getYaw()
    return center + util.transform.rotateZ(myYaw):apply(activeOffset)
end

local function syncPlayerPosition()
    local myYaw = s3lf.rotation:getYaw()

    local playerTargetPos = getTargetPosition(s3lf.controls.movement < 0)
        - MountTarget:getBoundingBox().halfSize['00z']

    local targetYaw = 0.
    if not firstOrThird then
        if util.round(math.deg(myYaw)) ~= util.round(math.deg(MountTarget.rotation:getYaw())) then
            targetYaw = myYaw
        end
    end

    core.sendGlobalEvent('P37Z_PlayerPosSync', {
        movement = playerTargetPos,
        yaw = math.deg(targetYaw),
    })
end

---@alias CreatureInputFunction fun(inputInfo: InputInfo)

---@type table<string, CreatureInputFunction>
local UpdateFunctions = {
    firstOrThird = function(inputInfo)
        firstOrThird = inputInfo.firstOrThird
    end,
    pitchChange = function(inputInfo)
    end,
    run = function(inputInfo)
        s3lf.controls.run = inputInfo.run ~= inputInfo.alwaysRun

        --- Engage the run action regardless of whether it's run, or always run,
        --- but don't allow descending with flyers unless explicitly running
        if s3lf.canFly and inputInfo.run and math.deg(s3lf.rotation:getPitch()) <= 89. then
            s3lf.controls.pitchChange = math.rad(1)
        end
    end,
    sneak = function(inputInfo)
        if not s3lf.canFly or not inputInfo.sneak or util.round(math.deg(s3lf.rotation:getPitch())) <= -89. then return end
        s3lf.controls.pitchChange = math.rad(-1)
    end,
    sideMovement = function(inputInfo)
        local value = inputInfo.sideMovement
        local animName = value < 0 and 'walkleft' or 'walkright'

        if s3lf.hasAnimation() and s3lf.hasGroup(animName) then
            s3lf.controls.sideMovement = value
        elseif value ~= 0 then
            s3lf.controls.yawChange = s3lf.controls.yawChange + math.rad(value)
        end
    end,
    yawChange = function(inputInfo)
        if inputInfo.previewIfStandStill then return end
        s3lf.controls.yawChange = s3lf.controls.yawChange + inputInfo.yawChange
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
                    updater(inputInfo)
                elseif actionValue ~= 0 and actionValue and s3lf.controls[actionName] then
                    s3lf.controls[actionName] = actionValue
                end
            end
        end,
        P37ZYawSync = function(yawChange)
            s3lf.controls.yawChange = yawChange
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
            local box = s3lf.gameObject:getBoundingBox()

            if isMounted then
                position = box.center +
                    util.transform.rotateZ(s3lf.rotation:getYaw()):apply(Offset)
            else
                position = nearby.findRandomPointAroundCircle(s3lf.position, box.halfSize.x * .1, {
                    includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
                })
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
