local async     = require 'openmw.async'
local camera    = require 'openmw.camera'
local core      = require 'openmw.core'
local input     = require 'openmw.input'
local self      = require 'openmw.self'
local types     = require 'openmw.types'
local ui        = require 'openmw.ui'
local util      = require 'openmw.util'

local I         = require('openmw.interfaces')

local Actor     = types.Actor
local Player    = types.Player

local ErrString = 'UI Windows requires a newer version of OpenMW, please update.'
if core.API_REVISION < 71 then
    ui.showMessage(ErrString)
    error(ErrString)
end

local settings = require('scripts.uimodes.settings')
local windows = require('scripts.uimodes.windows')

local MODE = I.UI.MODE

I.Controls.overrideUiControls(true)

local function checkNotWerewolf()
    if Player.isWerewolf(self) then
        ui.showMessage(core.getGMST('sWerewolfRefusal'))
        return false
    else
        return true
    end
end

local defaultStance = Actor.STANCE.Weapon
local lastSwingTime, totalNoAttackDuration = math.huge, 5.

for actionName, stance in pairs { ToggleSpell = Actor.STANCE.Spell, ToggleWeapon = Actor.STANCE.Weapon, } do
    input.registerTriggerHandler(actionName,
        async:callback(
            function()
                defaultStance = stance
            end
        )
    )
end

local SWITCH, getControlSwitch = input.CONTROL_SWITCH, input.getControlSwitch
local FightSwitch, MagicSwitch = SWITCH.Fighting, SWITCH.Magic

---@return boolean
local function weaponAllowed()
    return getControlSwitch(FightSwitch)
end

---@return boolean
local function magicAllowed()
    return getControlSwitch(MagicSwitch)
        and not self.type.isWerewolf(self)
        and (
            self.type.getSelectedSpell(self) or self.type.getSelectedEnchantedItem(self)
        )
end

--- Design a use-first system where we don't need to draw weapons anymore
input.registerActionHandler('Use',
    async:callback(
        function(state)
            if I.UI.getMode()
                or core.isWorldPaused()
                or state
                or not settings.autoDrawWeapon()
                or self.type.getStance(self) ~= self.type.STANCE.Nothing
            then
                return
            end

            local weaponAvailable, magicAvailable = weaponAllowed(), magicAllowed()

            if not weaponAvailable and not magicAvailable then return end

            if weaponAvailable and not magicAvailable then
                defaultStance = Actor.STANCE.Weapon
            elseif magicAvailable and not weaponAvailable then
                defaultStance = Actor.STANCE.Spell
            end

            self.type.setStance(self, defaultStance)
        end
    )
)

local function onInputAction(action)
    if not input.getControlSwitch(input.CONTROL_SWITCH.Controls) then
        return
    end

    if action == input.ACTION.Inventory then
        if I.UI.getMode() then
            I.UI.removeMode(I.UI.getMode())
            windows.mode = nil
        end
    elseif action == input.ACTION.Journal then
        windows.toggleJournal()
    elseif action == input.ACTION.QuickKeysMenu then
        if I.UI.getMode() == MODE.QuickKeysMenu then
            I.UI.removeMode(MODE.QuickKeysMenu)
        elseif checkNotWerewolf() and self.type.isCharGenFinished(self) then
            I.UI.addMode(MODE.QuickKeysMenu)
        end
    end
end

local function isShortcutsAllowed(mode)
    return settings.uiModesShortcuts() and (not mode or mode == MODE.Interface or mode == MODE.Journal)
end

local function onKeyPress(key)
    if not getControlSwitch(SWITCH.Controls) then
        return
    end

    if not isShortcutsAllowed(I.UI.getMode()) then return end

    if key.code == input.KEY.M then
        if key.withShift and settings.allowOpenMap() then
            windows.toggleMap()
        else
            windows.toggleMagic()
        end
    elseif key.code == input.KEY.I then
        windows.toggleInventory()
    elseif key.code == input.KEY.C then
        windows.toggleStats()
    end
end

local dialogModes = {
    Barter = true,
    Companion = true,
    Dialogue = true,
    Enchanting = true,
    MerchantRepair = true,
    SpellBuying = true,
    SpellCreation = true,
    Training = true,
    Travel = true,
}

local inventoryModesWithRotation = {
    Container = true,
    Alchemy = true,
}

local function shouldRotateCamera()
    if windows.mode == 'stats' or windows.mode == 'magic' or windows.mode == 'inventory' or inventoryModesWithRotation[I.UI.getMode()] then
        return settings.rotateCameraInInventory()
    end
    return dialogModes[I.UI.getMode()] and settings.rotateCameraInDialogs()
end

local rotateCameraCoef = 0
local prevCameraMode = nil

local function handleCameraRotation(dt)
    local currentMode = camera.getMode()

    if
        currentMode == camera.MODE.FirstPerson
        or currentMode == camera.MODE.Static
        or not I.UI.getMode()
    then
        rotateCameraCoef = 0

        if prevCameraMode and camera.getMode() == camera.MODE.Preview then
            camera.setMode(prevCameraMode)
            prevCameraMode = nil
        end

        return
    end

    local controllerYaw = input.getAxisValue(input.CONTROLLER_AXIS.LookLeftRight)
    local controllerPitch = input.getAxisValue(input.CONTROLLER_AXIS.LookUpDown)
    if math.abs(controllerYaw) < 0.05 then controllerYaw = 0 end
    if math.abs(controllerPitch) < 0.05 then controllerPitch = 0 end
    local speed = math.rad(settings.rotateCameraSpeed())
    local speedCoef = 1.0
    if input.isKeyPressed(input.KEY.LeftArrow) then
        rotateCameraCoef = math.min(1, rotateCameraCoef + 2 * speedCoef * dt)
    elseif input.isKeyPressed(input.KEY.RightArrow) then
        rotateCameraCoef = math.max(-1, rotateCameraCoef - 2 * speedCoef * dt)
    elseif shouldRotateCamera() and controllerYaw == 0 then
        if rotateCameraCoef > 0 then
            rotateCameraCoef = math.min(1, rotateCameraCoef + speedCoef * dt)
        elseif rotateCameraCoef < 0 then
            rotateCameraCoef = math.max(-1, rotateCameraCoef - speedCoef * dt)
        else
            rotateCameraCoef = (speed > 0 and 1 or -1) * math.min(1, speedCoef * dt)
        end
    else
        if rotateCameraCoef > 0 then
            rotateCameraCoef = math.max(0, rotateCameraCoef - speedCoef * dt)
        elseif rotateCameraCoef < 0 then
            rotateCameraCoef = math.min(0, rotateCameraCoef + speedCoef * dt)
        end
        rotateCameraCoef = util.clamp(rotateCameraCoef + controllerYaw, -1, 1)
    end

    local deltaYaw = dt * (rotateCameraCoef * math.abs(speed) + controllerYaw)

    if deltaYaw ~= 0 or controllerPitch ~= 0 then
        if camera.getMode() ~= camera.MODE.Preview then
            prevCameraMode = camera.getMode()
            camera.setMode(camera.MODE.Preview)
        end

        camera.setYaw(camera.getYaw() + deltaYaw)
        camera.setPitch(camera.getPitch() + dt * controllerPitch)
    end
end

local currentStance = self.type.getStance(self) or self.type.STANCE.Nothing
input.registerTriggerHandler('ToggleWeapon',
    async:callback(
        function()
            if
                core.isWorldPaused()
                or I.UI.getMode()
                or not self.type.canMove(self)
            then
                return
            end

            if currentStance ~= self.type.STANCE.Weapon then
                self.type.setStance(self, self.type.STANCE.Weapon)
                lastSwingTime = I.s3lf.isInCombat and math.huge or core.getRealTime()
            else
                self.controls.use = 1
            end

            local chimBlock = I.s3ChimBlock

            if chimBlock and chimBlock.isBlocking then chimBlock.toggleBlock(false) end
        end
    )
)

local attackCompletions, weaponGroups, attackContinues = {
    ['chop max attack'] = true,
    ['slash max attack'] = true,
    ['shoot max attack'] = true,
    ['thrust max attack'] = true,
}, {
    'bowandarrow',
    'crossbow',
    'handtohand',
    'throwweapon',
    'weapononehand',
    'weapontwohand',
    'weapontwowide',
}, {
    ['chop large follow stop'] = true,
    ['slash large follow stop'] = true,
    ['shoot follow stop'] = true,
    ['thrust large follow stop'] = true,
}

local function handleAttackGroups(_, key)
    if attackCompletions[key] and self.controls.use ~= 0 then
        self.controls.use = 0
        lastSwingTime = core.getRealTime()
    elseif attackContinues[key]
        and input.isActionPressed(input.ACTION.ToggleWeapon)
        and settings.continueAttackingWhileHeld
    then
        self:sendEvent('S3ControlsContinueAttack')
    end
end

for _, groupName in ipairs(weaponGroups) do
    I.AnimationController.addTextKeyHandler(groupName, handleAttackGroups)
end

local function onFrame()
    I.Controls.overrideCombatControls(true)
    handleCameraRotation(core.getRealFrameDuration())
    currentStance = self.type.getStance(self)

    if currentStance == self.type.STANCE.Weapon
        and not I.s3lf.isInCombat
        and (core.getRealTime() - lastSwingTime) >= totalNoAttackDuration
    then
        self.type.setStance(self, self.type.STANCE.Nothing)
    end
end

return {
    engineHandlers = {
        onInputAction = onInputAction,
        onKeyPress = onKeyPress,
        onFrame = onFrame,
    },
    eventHandlers = {
        S3CombatTargetAdded = function(_)
            if
                not settings.autoDrawWeaponOnCombatStart()
                or self.type.getStance(self) ~= self.type.STANCE.Nothing
            then
                return
            end

            self.type.setStance(self, defaultStance)
        end,
        S3CombatTargetRemoved = function(_)
            if
                not settings.autoSheathWeaponOnCombatEnd()
                or self.type.getStance(self) == self.type.STANCE.Nothing
                or I.s3lf.isInCombat
            then
                return
            end

            self.type.setStance(self, self.type.STANCE.Nothing)
        end,
        S3ControlsContinueAttack = function()
            if not input.isActionPressed(input.ACTION.ToggleWeapon) then return end

            self.controls.use = 1
        end,
        UiModeChanged = function(m)
            if m.newMode then return end
            windows.mode = nil
        end,
    },
}
