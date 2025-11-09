local animation = require 'openmw.animation'
local async = require 'openmw.async'
local camera = require 'openmw.camera'
local core = require 'openmw.core'

local I = require 'openmw.interfaces'
local Animation = I.AnimationController
local s3lf = I.s3lf

local modInfo = require 'scripts.s3.chim2090.modinfo'

--- Add AI support
--- Maybe try that "latch" binding style ern mentioned
local types = require 'openmw.types'
local isPlayer = types.Player.objectIsInstance(s3lf.gameObject)

local input
if isPlayer then
    input = require 'openmw.input'
end

---@class RollManager
---@field EnableRollModule boolean
---@field DoubleTapRoll boolean
---@field DoubleTapDelay number
---@field PitchRange number
local RollManager = I.S3ProtectedTable.new { inputGroupName = 'SettingsGlobal' .. modInfo.name .. 'Roll', logPrefix = '[CHIMROLL]:' }
RollManager.state = {
    lastPressedTime = core.getRealTime(),
    hasIFrames = false,
    prevAnimGroup = nil,
    lastMoveType = nil,
    disabledControls = {},
}

---@type RollInfo
local Roll = require 'scripts.s3.CHIM2090.roll.data'

function RollManager:updateState(time, type)
    local state = self.state

    state.lastPressedTime = time
    state.lastMoveType = type
end

function RollManager:setIframeState(state)
    assert(type(state) == 'boolean')
    self.state.hasIFrames = state
end

function RollManager:hasIFrames()
    return self.state.hasIFrames
end

function RollManager:getRandomPitch()
    return 1 + math.random(-self.PitchRange, self.PitchRange) / 100
end

---@return RollType
function RollManager.getRollType()
    local equipmentEncumbrance = I.s3ChimCore.getEquipmentEncumbrance()

    if equipmentEncumbrance <= 0.25 then
        return Roll.TYPE.FAST
    elseif equipmentEncumbrance <= 0.75 then
        return Roll.TYPE.NORMAL
    else
        return Roll.TYPE.FAT
    end
end

function RollManager.getRollTypeName()
    local rollType = RollManager.getRollType()

    if rollType == Roll.TYPE.FAST then
        return 'Fast'
    elseif rollType == Roll.TYPE.Normal then
        return 'Normal'
    else
        return 'Fat'
    end
end

--- Updates the current roll animation, returning whether or not it's currently nil.
--- Some weight classes don't have access to certain animations, so whether or not this value is nil tells us whether or not we can roll at all.
---@param direction RollDirection
---@return boolean wasUpdated
function RollManager:updateRollAnimation(direction)
    local rollDirection = Roll.groups[direction]
    assert(rollDirection,
        'Invalid Roll direction provided: ' .. tostring(direction) .. ', movement direction values must be between 1-4')

    self.state.prevAnimGroup = rollDirection[self.getRollType()]

    return self.state.prevAnimGroup ~= nil
end

local SWITCH = types.Player.CONTROL_SWITCH

--- If ran on a player, enable or disable movement and combat controls while rolling
---@param state boolean
function RollManager:toggleControls(state)
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

local animationKeyHandlers = {
    ['stop'] = function(group)
        if isPlayer then
            RollManager:toggleControls(true)
        end

        if
            I.S3LockOn
            and not I.S3LockOn.Manager.shouldTrack()
        then
            I.S3LockOn.Manager.setTrackingState(true)
        end
    end,
    ['min iframes'] = function(group)
        RollManager:setIframeState(true)

        local pitch, sound = RollManager:getRandomPitch(), nil

        local rand = math.random(1, 3)
        if rand == 1 then
            sound = 'swishm'
        elseif rand == 2 then
            sound = 'swishl'
        elseif rand == 3 then
            sound = 'swishs'
        end

        core.sound.playSound3d(sound, s3lf.gameObject, { pitch = pitch })
    end,
    ['max iframes'] = function(group)
        RollManager:setIframeState(false)

        local landSound = 'defaultland'
        if s3lf.cell.hasWater and s3lf.position.z <= s3lf.cell.waterLevel then
            landSound = landSound .. 'water'
        end

        core.sound.playSound3d(landSound, s3lf.gameObject, { pitch = RollManager:getRandomPitch() })
    end,
}

function RollManager.keyHandler(group, key)
    local handler = animationKeyHandlers[key]
    if handler then handler(group) end
end

function RollManager:isRolling()
    local lastAnim = self.state.prevAnimGroup
    if not lastAnim then return false end

    return s3lf.isPlaying(lastAnim)
end

for _, animGroup in ipairs(Roll.list) do
    I.AnimationController.addTextKeyHandler(animGroup, RollManager.keyHandler)
end

function RollManager:canRoll()
    return s3lf.isOnGround()
        and self.EnableRollModule
        and not I.UI.getMode()
        and not core.isWorldPaused()
        and not s3lf.isSwimming()
end

local oppositeDirections = {
    [1] = 3, -- Forward -> Back
    [2] = 4, -- Right -> Left
    [3] = 1, -- Back -> Forward
    [4] = 2  -- Left -> Right
}

---@param direction RollDirection
---@return RollDirection
function RollManager.getOppositeDirection(direction)
    local opposite = oppositeDirections[direction]
    assert(opposite)
    return opposite
end

---@param direction RollDirection
---@return boolean whether or not a roll happened
function RollManager:roll(direction)
    if not RollManager:updateRollAnimation(direction) then return false end

    RollManager:toggleControls(false)

    if
        I.S3LockOn
        and I.S3LockOn.Manager.shouldTrack()
        and camera.getMode() ~= camera.MODE.FirstPerson
    then
        I.S3LockOn.Manager.setTrackingState(false)
    end

    Animation.playBlendedAnimation(RollManager.state.prevAnimGroup, {
        priority = animation.PRIORITY.Scripted,
    })

    return true
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
                    not RollManager.DoubleTapRoll
                    or state ~= 1
                    or not RollManager:canRoll()
                then
                    return
                end

                local currentTime = core.getRealTime()

                if
                    currentTime - RollManager.state.lastPressedTime >= RollManager.DoubleTapDelay
                    or not RollManager.state.lastMoveType
                    or RollManager.state.lastMoveType ~= index
                    or (RollManager.state.prevAnimGroup and s3lf.isPlaying(RollManager.state.prevAnimGroup))
                then
                    return RollManager:updateState(currentTime, index)
                end

                if not RollManager:roll(index) then return RollManager:updateState(currentTime, index) end

                RollManager:updateState(currentTime, index)
            end
        ))
    end
end

local function noActions()
    if core.isWorldPaused() or not RollManager:isRolling() then return end

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
            disabledControls = RollManager.state.disabledControls,
        }
    end

    engineHandlers.onLoad = function(data)
        data = data or {}

        RollManager.state.disabledControls = data.disabledControls or {}
        RollManager:toggleControls(true)
    end
else
    engineHandlers.onUpdate = noActions
end

local interfaceKeyHandlers = {
    rollTypeName = function()
        return RollManager.getRollTypeName()
    end,
    hasIFrames = function()
        return RollManager:hasIFrames()
    end,
    isRolling = function()
        return RollManager:isRolling()
    end,
}

return {
    interfaceName = 's3ChimRoll',
    interface = setmetatable(
        {},
        {
            __index = function(_, key)
                local keyHandler = interfaceKeyHandlers[key]
                local managerKey = RollManager[key]

                if keyHandler then
                    assert(type(keyHandler) == 'function')
                    return keyHandler()
                elseif managerKey then
                    return managerKey
                elseif key == 'Manager' then
                    return RollManager
                end
            end,
        }
    ),
    engineHandlers = engineHandlers,
    eventHandlers = eventHandlers,
}
