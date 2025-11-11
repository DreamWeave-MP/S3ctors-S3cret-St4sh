local animation = require 'openmw.animation'
local async = require 'openmw.async'
local camera
local core = require 'openmw.core'
local input

local I = require 'openmw.interfaces'
local Animation = I.AnimationController
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.chim2090.modinfo'

--- Add AI support
--- Maybe try that "latch" binding style ern mentioned
local types = require 'openmw.types'
local isPlayer = types.Player.objectIsInstance(s3lf.gameObject)

if isPlayer then
    camera = require 'openmw.camera'
    input = require 'openmw.input'
end

---@class RollManager: ProtectedTable
---@field EnableRollModule boolean
---@field DoubleTapRoll boolean
---@field DoubleTapDelay number
---@field RollSoundPitchRange number
local Roll = I.S3ProtectedTable.new { inputGroupName = 'SettingsGlobal' .. modInfo.name .. 'Roll', logPrefix = '[CHIMROLL]:' }
Roll.state = {
    lastPressedTime = core.getRealTime(),
    hasIFrames = false,
    prevAnimGroup = nil,
    lastMoveType = nil,
    disabledControls = {},
}

---@type RollInfo
local RollInfo = require 'scripts.s3.CHIM2090.roll.data'

function Roll:updateState(time, type)
    local state = self.state

    state.lastPressedTime = time
    state.lastMoveType = type
end

function Roll:setIframeState(state)
    assert(type(state) == 'boolean')
    self.state.hasIFrames = state
end

function Roll:hasIFrames()
    return self.state.hasIFrames
end

function Roll:getRandomPitch()
    return 1 + I.RandomGen.range(-self.RollSoundPitchRange, self.RollSoundPitchRange)
end

---@return RollType
function Roll.getRollType()
    local equipmentEncumbrance = I.s3ChimCore.getEquipmentEncumbrance()

    if equipmentEncumbrance <= 0.25 then
        return RollInfo.TYPE.FAST
    elseif equipmentEncumbrance <= 0.75 then
        return RollInfo.TYPE.NORMAL
    else
        return RollInfo.TYPE.FAT
    end
end

function Roll.getRollTypeName()
    local rollType = Roll.getRollType()

    if rollType == RollInfo.TYPE.FAST then
        return 'Fast'
    elseif rollType == RollInfo.TYPE.Normal then
        return 'Normal'
    else
        return 'Fat'
    end
end

--- Updates the current roll animation, returning whether or not it's currently nil.
--- Some weight classes don't have access to certain animations, so whether or not this value is nil tells us whether or not we can roll at all.
---@param direction RollDirection
---@return boolean wasUpdated
function Roll:updateRollAnimation(direction)
    local rollDirection = RollInfo.groups[direction]
    assert(rollDirection,
        'Invalid Roll direction provided: ' .. tostring(direction) .. ', movement direction values must be between 1-4')

    self.state.prevAnimGroup = rollDirection[self.getRollType()]

    return self.state.prevAnimGroup ~= nil
end

local SWITCH = types.Player.CONTROL_SWITCH

--- If ran on a player, enable or disable movement and combat controls while rolling
---@param state boolean
function Roll:toggleControls(state)
    if not isPlayer then return end
    local disabledControls = self.state.disabledControls

    if state then
        for _ = 1, #disabledControls do
            local control = table.remove(disabledControls)
            s3lf.setControlSwitch(control, true)
        end
    else
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
    end
end

local rollSounds = {
    'swishl',
    'swishm',
    'swishs',
}
local numRollSounds = #rollSounds

local animationKeyHandlers = {
    ['stop'] = function(group)
        if isPlayer then
            Roll:toggleControls(true)
        end

        if
            I.S3LockOn
            and not I.S3LockOn.Manager.shouldTrack()
        then
            I.S3LockOn.Manager.setTrackingState(true)
        end
    end,
    ['min iframes'] = function(group)
        Roll:setIframeState(true)

        local soundIndex = I.RandomGen.range(numRollSounds, true)
        local pitch, sound = Roll:getRandomPitch(), rollSounds[soundIndex]

        core.sound.playSound3d(sound, s3lf.gameObject, { pitch = pitch })
    end,
    ['max iframes'] = function(group)
        Roll:setIframeState(false)

        local landSound = 'defaultland'
        if s3lf.cell.hasWater and s3lf.position.z <= s3lf.cell.waterLevel then
            landSound = landSound .. 'water'
        end

        core.sound.playSound3d(landSound, s3lf.gameObject, { pitch = Roll:getRandomPitch() })
    end,
}

function Roll.keyHandler(group, key)
    local handler = animationKeyHandlers[key]
    if handler then handler(group) end
end

function Roll:isRolling()
    local lastAnim = self.state.prevAnimGroup
    if not lastAnim then return false end

    return s3lf.isPlaying(lastAnim)
end

for _, animGroup in ipairs(RollInfo.list) do
    I.AnimationController.addTextKeyHandler(animGroup, Roll.keyHandler)
end

function Roll:canRoll()
    local canRoll = self.EnableRollModule
        and not self:isRolling()
        and s3lf.isOnGround()
        and s3lf.canMove()
        -- and not core.isWorldPaused()
        and not s3lf.isSwimming()

    if isPlayer then
        canRoll = canRoll and not I.UI.getMode()
    end

    return canRoll
end

local oppositeDirections = {
    [1] = 3, -- Forward -> Back
    [2] = 4, -- Right -> Left
    [3] = 1, -- Back -> Forward
    [4] = 2  -- Left -> Right
}

---@param direction RollDirection
---@return RollDirection
function Roll.getOppositeDirection(direction)
    local opposite = oppositeDirections[direction]
    assert(opposite)
    return opposite
end

---@param direction RollDirection
---@return boolean whether or not a roll happened
function Roll:activate(direction)
    if not self:canRoll() or not Roll:updateRollAnimation(direction) then
        return false
    end

    Roll:toggleControls(false)

    if
        I.S3LockOn
        and I.S3LockOn.Manager.shouldTrack()
        and camera.getMode() ~= camera.MODE.FirstPerson
    then
        I.S3LockOn.Manager.setTrackingState(false)
    end

    Animation.playBlendedAnimation(Roll.state.prevAnimGroup, {
        priority = animation.PRIORITY.Scripted,
    })

    return true
end

---@return RollDirection
function Roll.getRollDirectionFromInput()
    if not isPlayer then
        local controls = s3lf.controls
        if controls.sideMovement < 0 then
            return RollInfo.DIRECTION.LEFT
        elseif controls.sideMovement > 0 then
            return RollInfo.DIRECTION.RIGHT
        elseif controls.movement > 0 then
            return RollInfo.DIRECTION.FORWARD
        elseif controls.movement < 0 then
            return RollInfo.DIRECTION.BACK
        end
    else
        local forwardDir = input.getRangeActionValue('MoveForward') - input.getRangeActionValue('MoveBackward')
        local horizontalDir = input.getRangeActionValue('MoveRight') - input.getRangeActionValue('MoveLeft')

        if horizontalDir > 0 then
            return RollInfo.DIRECTION.RIGHT
        elseif horizontalDir < 0 then
            return RollInfo.DIRECTION.LEFT
        elseif forwardDir > 0 then
            return RollInfo.DIRECTION.FORWARD
        elseif forwardDir < 0 then
            return RollInfo.DIRECTION.BACK
        end
    end

    return RollInfo.DIRECTION.BACK
end

if isPlayer then
    for index, action in ipairs {
        'MoveForward',
        'MoveRight',
        'MoveBackward',
        'MoveLeft',
    } do
        input.registerActionHandler(action, async:callback(
            function(state)
                if
                    not Roll.DoubleTapRoll
                    or state ~= 1
                    or not Roll:canRoll()
                then
                    return
                end

                local currentTime = core.getRealTime()

                if
                    currentTime - Roll.state.lastPressedTime >= Roll.DoubleTapDelay
                    or not Roll.state.lastMoveType
                    or Roll.state.lastMoveType ~= index
                    or (Roll.state.prevAnimGroup and s3lf.isPlaying(Roll.state.prevAnimGroup))
                then
                    return Roll:updateState(currentTime, index)
                end

                if not Roll:activate(index) then return Roll:updateState(currentTime, index) end

                Roll:updateState(currentTime, index)
            end
        ))
    end

    input.registerTriggerHandler('CHIMRollAction', async:callback(function()
        Roll:activate(Roll.getRollDirectionFromInput())
    end
    ))
end

local function noActions()
    if core.isWorldPaused() or not Roll:isRolling() then return end

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

    function engineHandlers.onSave()
        return {
            disabledControls = Roll.state.disabledControls,
        }
    end

    function engineHandlers.onLoad(data)
        data = data or {}

        Roll.state.disabledControls = data.disabledControls or {}
        Roll:toggleControls(true)
    end

    function eventHandlers.UiModeChanged()
        if Roll:isRolling() then return end
        Roll:toggleControls(true)
    end
else
    engineHandlers.onUpdate = noActions
end

---@class RollState
---@field type RollType
---@field direction RollDirection

---@param rollDirection RollDirection?
eventHandlers.CHIMToggleRoll = function(rollDirection)
    if isPlayer then
        input.activateTrigger('CHIMRollAction')
    else
        Roll:activate(rollDirection or I.RandomGen.range(4, true))
    end
end

local interfaceKeyHandlers = {
    DIRECTION = RollInfo.DIRECTION,
    hasIFrames = function()
        return Roll:hasIFrames()
    end,
    isRolling = function()
        return Roll:isRolling()
    end,
    rollTypeName = function()
        return Roll.getRollTypeName()
    end,
    TYPE = RollInfo.TYPE,
}

return {
    interfaceName = 's3ChimRoll',
    interface = Roll.interface(function(key)
        local keyHandler = interfaceKeyHandlers[key]
        local managerKey = Roll[key]

        if keyHandler then
            if type(keyHandler) == 'function' then
                return keyHandler()
            else
                return keyHandler
            end
        elseif managerKey then
            return managerKey
        elseif key == 'Manager' then
            return Roll
        end
    end),
    engineHandlers = engineHandlers,
    eventHandlers = eventHandlers,
}
