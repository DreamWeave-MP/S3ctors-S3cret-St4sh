local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local Actor = require('openmw.types').Actor
local Player = require('openmw.types').Player

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
local function handleToggleWeaponActions(action)
    if action == input.ACTION.Use then
        if Actor.getStance(self) == Actor.STANCE.Nothing and settings.autoDrawWeapon() then
            local weaponAllowed = input.getControlSwitch(input.CONTROL_SWITCH.Fighting)
            local magicAllowed = input.getControlSwitch(input.CONTROL_SWITCH.Magic) and not Player.isWerewolf(self)
                and (Actor.getSelectedSpell(self) or Actor.getSelectedEnchantedItem(self))
            if weaponAllowed and magicAllowed then
                Actor.setStance(self, defaultStance)
            elseif weaponAllowed then
                defaultStance = Actor.STANCE.Weapon
                Actor.setStance(self, defaultStance)
            elseif magicAllowed then
                defaultStance = Actor.STANCE.Spell
                Actor.setStance(self, defaultStance)
            end
        end
    elseif action == input.ACTION.ToggleWeapon then
        defaultStance = Actor.STANCE.Weapon
    elseif action == input.ACTION.ToggleSpell then
        defaultStance = Actor.STANCE.Spell
    end
end

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
        elseif checkNotWerewolf() and Player.isCharGenFinished(self) then
            I.UI.addMode(MODE.QuickKeysMenu)
        end
    end

    if not core.isWorldPaused() and not I.UI.getMode() then
        handleToggleWeaponActions(action)
    end
end

local function isShortcutsAllowed(mode)
    return settings.uiModesShortcuts() and (not mode or mode == MODE.Interface or mode == MODE.Journal)
end

local function onKeyPress(key)
    if not input.getControlSwitch(input.CONTROL_SWITCH.Controls) then
        return
    end

    if isShortcutsAllowed(I.UI.getMode()) then
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
    if camera.getMode() == camera.MODE.FirstPerson or camera.getMode() == camera.MODE.Static or I.UI.getMode() == nil then
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

local lastRealTime = 0

local function onFrame()
    local dt = math.min(core.getRealTime() - lastRealTime, 0.1)
    lastRealTime = core.getRealTime()
    handleCameraRotation(dt)
end

return {
    engineHandlers = {
        onInputAction = onInputAction,
        onKeyPress = onKeyPress,
        onFrame = onFrame,
    },
    eventHandlers = {
        UiModeChanged = function(m)
            if not m.newMode then
                windows.mode = nil
            end
        end,
    },
}
