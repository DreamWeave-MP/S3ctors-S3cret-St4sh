local animation = require 'openmw.animation'
local async = require 'openmw.async'
local camera = require 'openmw.camera'
local core = require 'openmw.core'

local I = require 'openmw.interfaces'
local Animation = I.AnimationController
local s3lf = I.s3lf

local types = require 'openmw.types'
local isPlayer = types.Player.objectIsInstance(s3lf.gameObject)

local input
if isPlayer then
    input = require 'openmw.input'
end

local Roll = require 'scripts.s3.CHIM2090.roll.data'

local pressDelay = 0.2
local lastPressedTime, prevAnimGroup, lastMoveType, prevStance = core.getRealTime()
local hasIFrames = false

local function updateState(time, type)
    lastPressedTime = time
    lastMoveType = type
end

local disabledControls = {}

local keyHandlers = {
    ['stop'] = function(group)
        for _ = 1, #disabledControls do
            local control = table.remove(disabledControls)
            s3lf.setControlSwitch(control, true)
        end

        if
            I.S3LockOn
            and not I.S3LockOn.Manager.shouldTrack()
        then
            I.S3LockOn.Manager.setTrackingState(true)
        end
    end,
    ['min iframes'] = function(group)
        hasIFrames = true
    end,
    ['max iframes'] = function(group)
        hasIFrames = false
    end,
}

local function keyHandlerGlobal(group, key)
    local handler = keyHandlers[key]
    if handler then handler(group) end
end

local function isRolling()
    if not prevAnimGroup then return false end

    return s3lf.isPlaying(prevAnimGroup)
end

for _, animGroup in ipairs(Roll.list) do
    I.AnimationController.addTextKeyHandler(animGroup, keyHandlerGlobal)
end

if isPlayer then
    local SWITCH = types.Player.CONTROL_SWITCH
    for index, action in ipairs {
        'MoveForward',
        'MoveRight',
        'MoveBackward',
        'MoveLeft',
    } do
        input.registerActionHandler(action, async:callback(
            function(state)
                if
                    state ~= 1
                    or I.UI.getMode()
                    or core.isWorldPaused()
                    or not s3lf.isOnGround()
                    or s3lf.isSwimming()
                then
                    return
                end

                local currentTime = core.getRealTime()

                if
                    currentTime - lastPressedTime >= pressDelay
                    or not lastMoveType
                    or lastMoveType ~= index
                    or (prevAnimGroup and s3lf.isPlaying(prevAnimGroup))
                then
                    return updateState(currentTime, index)
                end

                local rollDirection = Roll.groups[index]

                local equipmentEncumbrance, rollType = I.s3ChimCore.getEquipmentEncumbrance()

                if equipmentEncumbrance <= 0.25 then
                    rollType = Roll.TYPE.FAST
                elseif equipmentEncumbrance <= 0.75 then
                    rollType = Roll.TYPE.NORMAL
                else
                    rollType = Roll.TYPE.FAT
                end

                prevAnimGroup = rollDirection[rollType]

                if not prevAnimGroup then return updateState(currentTime, index) end

                for _, control in ipairs {
                    SWITCH.Controls,
                    SWITCH.Fighting,
                    SWITCH.Jumping,
                    SWITCH.Magic,
                    SWITCH.VanityMode,
                    SWITCH.ViewMode
                } do
                    if s3lf.getControlSwitch(control) then
                        disabledControls[#disabledControls + 1] = control
                        s3lf.setControlSwitch(control, false)
                    end
                end

                if
                    I.S3LockOn
                    and I.S3LockOn.Manager.shouldTrack()
                    and camera.getMode() ~= camera.MODE.FirstPerson
                then
                    I.S3LockOn.Manager.setTrackingState(false)
                end

                Animation.playBlendedAnimation(prevAnimGroup, {
                    priority = animation.PRIORITY.Scripted,
                })

                updateState(currentTime, index)
            end
        ))
    end
end

local function noActions()
    if core.isWorldPaused() or not isRolling() then return end

    if not isPlayer then
        s3lf.controls.use = 0
        s3lf.controls.movement = 0
        s3lf.controls.sideMovement = 0
        s3lf.controls.jump = false
    end

    s3lf.controls.yawChange = 0
    s3lf.controls.pitchChange = 0
end

local engineHandlers, eventHandlers = {}, {}

if isPlayer then
    engineHandlers.onFrame = noActions

    engineHandlers.onSave = function()
        return {
            disabledControls = disabledControls,
        }
    end

    engineHandlers.onLoad = function(data)
        data = data or {}

        for _, control in ipairs(data.disabledControls or {}) do
            s3lf.setControlSwitch(control, true)
        end
    end
else
    engineHandlers.onUpdate = noActions
end

return {
    interfaceName = 's3ChimRoll',
    interface = {
        hasIFrames = hasIFrames,
        isRolling = isRolling,
    },
    engineHandlers = engineHandlers,
    eventHandlers = eventHandlers,
}
