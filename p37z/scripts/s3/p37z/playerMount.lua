local animation = require 'openmw.animation'
local async = require 'openmw.async'
local camera = require 'openmw.camera'
local core = require 'openmw.core'
local input = require 'openmw.input'
local storage = require 'openmw.storage'

local I = require 'openmw.interfaces'
local s3lf = I.s3lf

local OMWCameraSettings = storage.playerSection('SettingsOMWCameraThirdPerson')

---@class MountState
---@field MountTarget GameObject?
---@field LastMount GameObject?
local MountState = {
    PreviewIfStandStill = OMWCameraSettings:get('previewIfStandStill'),
    LastMount = nil,
    MountTarget = nil,
    previewStateSwitched = false,
}

OMWCameraSettings:subscribe(
    async:callback(
        function(_, key)
            local value = OMWCameraSettings:get(key)

            if key == 'previewIfStandStill' then
                MountState.PreviewIfStandStill = value

                local currentMode = camera.getMode()
                if currentMode == camera.MODE.ThirdPerson and value then
                    camera.setMode(camera.MODE.Preview)
                elseif currentMode == camera.MODE.Preview and not value then
                    camera.setMode(camera.MODE.ThirdPerson)
                elseif currentMode == camera.MODE.FirstPerson and not value and MountState.MountTarget then
                    MountState.MountTarget:sendEvent('P37ZYawSync',
                        s3lf.rotation:getYaw() - MountState.MountTarget.rotation:getYaw()
                    )
                end
            end
        end
    )
)

---@alias ActionName
---| 'movement'
---| 'sideMovement'
---| 'jump'
---| 'yawChange'
---| 'pitchChange'
---| 'run'
---| 'firstOrThird'
---| 'sneak'
---| 'alwaysRun'

---@alias InputFunction fun(): ActionName, number|boolean

local ControlSettings = storage.playerSection('SettingsOMWControls')
local AlwaysRun = ControlSettings:get('alwaysRun')
ControlSettings:subscribe(
    async:callback(
        function(_, key)
            local value = ControlSettings:get(key)

            if key == 'alwaysRun' then
                AlwaysRun = value
            end
        end
    )
)

local autoRun = false
input.registerTriggerHandler('AutoMove', async:callback(
    function()
        if not MountState.MountTarget then return end
        if input.isShiftPressed() then
            OMWCameraSettings:set('previewIfStandStill', not OMWCameraSettings:get('previewIfStandStill'))
        else
            autoRun = not autoRun
        end
    end
))

input.registerTriggerHandler('AlwaysRun', async:callback(
    function()
        if not MountState.MountTarget then return end
        ControlSettings:set('alwaysRun', not ControlSettings:get('alwaysRun'))
    end
))

---@class InputInfo
---@field movement number Forward/backward movement
---@field sideMovement number horizontal movement
---@field yawChange number
---@field pitchChange number
---@field jump boolean
---@field run boolean
---@field firstOrThird boolean
---@field sneak boolean
---@field alwaysRun boolean
---@field previewIfStandStill boolean
local InputInfo = {
    movement = 0,
    sideMovement = 0,
    jump = false,
    yawChange = 0,
    pitchChange = 0,
    firstOrThird = camera.getMode() == camera.MODE.FirstPerson,
    alwaysRun = AlwaysRun,
    previewIfStandStill = MountState.PreviewIfStandStill or false,
}

--- Updates all appropriate movement info for the player, to be relayed to the mount.
--- Returns bool to indicate whether or not to actually bother updating controls.
--- Maybe this is bad...?
---@return InputInfo
local function updateInputInfo()
    local movement = input.getRangeActionValue('MoveForward') - input.getRangeActionValue('MoveBackward')

    if movement ~= 0 then
        autoRun = false
    elseif autoRun then
        movement = 1
    end

    InputInfo.movement = movement
    InputInfo.sideMovement = input.getRangeActionValue('MoveRight') - input.getRangeActionValue('MoveLeft')
    InputInfo.run = input.getBooleanActionValue('Run')
    InputInfo.jump = s3lf.controls.jump
    InputInfo.firstOrThird = camera.getMode() == camera.MODE.FirstPerson
    InputInfo.sneak = input.getBooleanActionValue('Sneak')
    InputInfo.alwaysRun = AlwaysRun
    InputInfo.previewIfStandStill = MountState.PreviewIfStandStill

    InputInfo.yawChange = s3lf.controls.yawChange
    if s3lf.controls.yawChange ~= 0. and not InputInfo.firstOrThird then
        s3lf.controls.yawChange = 0.
    end

    return InputInfo
end

local function playLegAnimation()
    I.AnimationController.playBlendedAnimation('idlesneak',
        {
            priority = animation.PRIORITY.Scripted,
            blendMask = animation.BLEND_MASK.LowerBody,
            autoDisable = false,
        }
    )
end

return {
    engineHandlers = {
        onFrame = function()
            if core.isWorldPaused() or not MountState.MountTarget then return end
            MountState.MountTarget:sendEvent('P37ZControl', updateInputInfo())
        end,
        onSave = function()
            return MountState
        end,
        onLoad = function(data)
            for k, v in pairs(data or {}) do MountState[k] = v end
        end,
    },
    eventHandlers = {
        P37ZMountEnable = function(mount)
            local isMountedAlready = MountState.MountTarget ~= nil
            MountState.MountTarget = (not isMountedAlready and mount) or nil

            I.Controls.overrideMovementControls(not isMountedAlready)

            if not MountState.MountTarget then
                MountState.LastMount = mount

                if MountState.previewStateSwitched then
                    OMWCameraSettings:set('previewIfStandStill', true)
                    MountState.previewStateSwitched = false
                end

                s3lf.cancel('idlesneak')
            else
                if MountState.PreviewIfStandStill then
                    OMWCameraSettings:set('previewIfStandStill', false)

                    if camera.getMode() == camera.MODE.Preview then
                        camera.setMode(camera.MODE.ThirdPerson)
                    end

                    MountState.previewStateSwitched = true
                end

                playLegAnimation()
            end
        end,
    },
}
