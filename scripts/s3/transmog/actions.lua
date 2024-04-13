local I = require('openmw.interfaces')

local async = require('openmw.async')
local aux_util = require('openmw_aux.util')
local camera = require('openmw.camera')
local common = require('scripts.s3.transmog.ui.common')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local MainWidget = require('scripts.s3.transmog.ui.mainwidget')
local ItemContainer = require('scripts.s3.transmog.ui.rightpanel.itemcontainer')
local ConfirmScreen = require('scripts.s3.transmog.ui.leftpanel.glamourbutton').createCallback
local ToolTip = require('scripts.s3.transmog.ui.tooltip.main')

local mogBinds = storage.playerSection('Settingss3_transmogMenuGroup'):asTable()

-- add safeties for unsupported types
-- add stacking for ammunition

local prevCam = nil
local prevStance = nil
local rotateStopFn = {
  funcLeft = nil,
  funcRight = nil,
}

local outInterface = {
  message = {},
  consoleOpen = false,
  messageBox = common.messageBoxSingleton,
}

local function rotateWarning()
  if outInterface.message.hasShowedControls then return end
  common.messageBoxSingleton("Rotate Warning", "Use the "
                             .. string.upper(mogBinds.SettingsTransmogMenuRotateRight)
                             ..  " and " .. string.upper(mogBinds.SettingsTransmogMenuRotateLeft)
                             .. " keys to rotate your character.", 2)
  common.messageBoxSingleton("Confirm Warning", "Confirm your choices with the "
                             .. string.upper(mogBinds.SettingsTransmogMenuKeyConfirm) .. " key", 2)
  outInterface.message.hasShowedControls = true
end

outInterface.acceptTransmog = function()
  if I.transmogActions.message.confirmScreen == nil then return end

  local newItemName = I.transmogActions.message.confirmScreen.layout.content[2].content[1].props.text

  if newItemName == "" then
    common.messageBoxSingleton("No Name Warning", "You must name your item!")
    return
  end

  local baseItem = I.transmogActions.baseItemContainer.content[2].userData
  local newItem = I.transmogActions.newItemContainer.content[2].userData

  -- A weapon is used as base, with the appearance of a non-equippable item
  -- In this case we only apply the model from the new item on the new record.
  if baseItem.type == types.Weapon then
    local weaponTable = {name = newItemName, model = newItem.record.model, icon = newItem.record.icon}
    core.sendGlobalEvent("mogOnWeaponCreate",
                         {
                           target = self,
                           item = weaponTable,
                           toRemove = baseItem.recordId
    })
  elseif baseItem.type == types.Book then
    local bookTable = { name = newItemName }
    core.sendGlobalEvent("mogOnBookCreate",
                         {
                           target = self,
                           item = bookTable,
                           toRemoveBook = baseItem.recordId,
                           toRemoveItem = newItem.recordId,
    })
  elseif baseItem.type == types.Clothing or baseItem.type == types.Armor then
    local apparelTable = { name = newItemName }
    core.sendGlobalEvent("mogOnApparelCreate",
                         {
                           target = self,
                           item = apparelTable,
                           oldItem = baseItem.recordId,
                           newItem = newItem.recordId,
    })
  end
  types.Actor.setEquipment(self, I.transmogActions.originalInventory)
  common.resetPortraits()
  outInterface.itemContainer.content = ui.content(ItemContainer.updateContent("Apparel"))
  outInterface.menu.layout.props.visible = true
  outInterface.message.confirmScreen.layout.props.visible = false
  outInterface.message.confirmScreen:update()
  outInterface.menu:update()
end

outInterface.restoreUserInterface = function()
  if prevCam then
    types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Controls, true)
    types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Looking, true)
    I.Controls.overrideUiControls(false)
    camera.showCrosshair(true)
    camera.setMode(prevCam)
    I.UI.setHudVisibility(true)
    I.UI.setPauseOnMode(I.UI.MODE.Interface, true)
    I.UI.setMode()
    prevCam = nil
  end
end

-- Now we set up the callback
local menuStateSwitch = async:callback(function()
    if not types.Actor.isOnGround(self)
      or types.Actor.isSwimming(self)
      or I.UI.getMode() == I.UI.MODE.MainMenu
      or outInterface.consoleOpen
      or common.messageIsVisible()
      or common.confirmIsVisible()
    then return end

    if not prevCam then
      types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Controls, false)
      types.Player.setControlSwitch(self, input.CONTROL_SWITCH.Looking, false)
      I.Controls.overrideUiControls(true)
      self.controls.sneak = false -- This is a special case, it's not covered by the control switch
      camera.showCrosshair(false)
      camera.setYaw(3.14)
      camera.setPitch(0)
      camera.setRoll(0)
      prevCam = camera.getMode()
      camera.setMode(camera.MODE.Static)
      camera.setStaticPosition(self.position + util.vector3(25, 75, 75))
      I.UI.setHudVisibility(false)
      I.UI.setPauseOnMode(I.UI.MODE.Interface, false)
      I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
    else
      outInterface.restoreUserInterface()
    end

    if not outInterface.menu then
      outInterface.menu = MainWidget()
      outInterface.leftPane = outInterface.menu.layout.content[1].content[1]
      outInterface.rightPane = outInterface.menu.layout.content[1].content[3]
      outInterface.baseItemContainer = outInterface.leftPane.content[2]
      outInterface.newItemContainer = outInterface.leftPane.content[4]
      outInterface.itemContainer = outInterface.rightPane.content[1].content[3].content[1].content[1]
      outInterface.originalInventory = types.Actor.getEquipment(self)
      outInterface.message.singleton = nil
      outInterface.message.confirmScreen = nil
      outInterface.message.toolTip = nil
      outInterface.message.hasShowedPreviewWarning = false
      prevStance = types.Actor.getStance(self)
      rotateWarning()
    else
      outInterface.menu.layout.props.visible = not outInterface.menu.layout.props.visible
      if outInterface.menu.layout.props.visible then
        common.resetPortraits()
        outInterface.itemContainer.content = ui.content(ItemContainer.updateContent("Apparel"))
        outInterface.originalInventory = types.Actor.getEquipment(self)
        prevStance = types.Actor.getStance(self)
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        rotateWarning()
      else
        outInterface.message.hasShowedPreviewWarning = false
        types.Actor.setEquipment(self, outInterface.originalInventory)
        types.Actor.setStance(self, prevStance)
      end
      if common.toolTipIsVisible() then
        outInterface.message.toolTip.layout.props.visible = false
        outInterface.message.toolTip:update()
      end
      outInterface.menu:update()
    end
end)

input.registerActionHandler("transmogMenuRotateRight", async:callback(function()
    if not outInterface.menu or outInterface.message.confirmScreen or not outInterface.menu.layout.props.visible then return end
    if not input.getBooleanActionValue("transmogMenuRotateRight") and rotateStopFn.funcRight then
        rotateStopFn.funcRight()
        return
    end
    rotateStopFn.funcRight = time.runRepeatedly(function()
                                             self.controls.yawChange = 0.3
    end,
      0.1,
      {})
end))

input.registerActionHandler("transmogMenuRotateLeft", async:callback(function()
    if not outInterface.menu or outInterface.message.confirmScreen or not outInterface.menu.layout.props.visible then return end
    if not input.getBooleanActionValue("transmogMenuRotateLeft") and rotateStopFn.funcLeft then
        rotateStopFn.funcLeft()
        return
    end

    rotateStopFn.funcLeft = time.runRepeatedly(function()
        self.controls.yawChange = -0.3
    end,
      0.1,
      {})
end))

local isPreviewing = false
outInterface.updatePreview = function()
  if not common.toolTipIsVisible() and not isPreviewing then
    common.messageBoxSingleton("Preview Warning", "You must have an item selected to preview it!", 2)
    return
  end

  if outInterface.newItemContainer.content[2].userData then
    isPreviewing = true
    common.messageBoxSingleton("Preview Warning", "You must confirm your current choices before previewing another item!", 2)
    return
  end

  local toolTip = ToolTip.get()

  local equipment = {}
  for slot, item in pairs(outInterface.originalInventory) do
    equipment[slot] = item
  end

  if input.getBooleanActionValue("transmogMenuActivePreview") then
    local recordId = ToolTip.getRecordId()
    local targetItem = types.Actor.inventory(self):find(recordId)

    if not targetItem then return end

    if not common.recordAliases[ToolTip.getRecordType()].wearable then
      common.messageBoxSingleton("Preview Warning", "This item cannot be previewed!")
      return
    end

    local slot = common.recordAliases[ToolTip.getRecordType()].slot
      or common.recordAliases[ToolTip.getRecordType()][ToolTip.getRecord().type].slot

    equipment[slot] = recordId
    isPreviewing = true
    toolTip.layout.props.visible = false
  else
    print("Disengaging preview...")
    isPreviewing = false
    toolTip.layout.props.visible = true
  end
  toolTip:update()
  async:newUnsavableSimulationTimer(0.1, function()
                                      types.Actor.setEquipment(self, equipment)
  end)
end

input.registerActionHandler("transmogMenuActivePreview", async:callback(outInterface.updatePreview))

-- And this is where we actually bind the action to the callback
input.registerTriggerHandler("transmogMenuOpen", menuStateSwitch)

input.registerTriggerHandler("transmogMenuConfirm", async:callback(function()
                                -- Use this key to finish the 'mog
                                -- Only if either of the two relevant menus is open
                                -- Guess we'll also need to do this for enhancements as well.
                                -- I decided I like doing it this way better than attaching
                                -- callbacks to the widget directly because I can't actually correlate a keybind to a widget there
                                if outInterface.menu
                                  and outInterface.menu.layout.props.visible then
                                  ConfirmScreen()
                                elseif outInterface.message.confirmScreen
                                  and outInterface.message.confirmScreen.layout.props.visible then
                                  outInterface.acceptTransmog()
                                end
end))

local consoleOpenedThisFrame = false
return {
  interface = outInterface,
  interfaceName = 'transmogActions',
  engineHandlers = {
    onInit = function()
      common.messageBoxSingleton("Welcome", "Thank you for installing Glamour Menu!", 3)
      common.messageBoxSingleton("Welcome", "Please be aware that OpenMW does not\npresently allow mods to use default keybinds!", 3)
      common.messageBoxSingleton("Welcome", "We recommend the following defaults:\n"
                                 .. "Q and E for rotate right and left respectively\n"
                                 .. "Enter/Return for select\n"
                                 .. "And L to open the menu.\n"
                                 .. "Happy Glamming!", 3)
      -- Add a check for Kartoffel's empty gear mod

    end,
    onKeyRelease = function(key)
      -- Since the engine doesn't let you bind ESC
      -- and it's generally just used to close stuff, do that here
      if key.code == input.KEY.Escape then
        if outInterface.consoleOpen then
          outInterface.consoleOpen = false
        end
        if common.confirmIsVisible() then
          outInterface.message.confirmScreen.layout.props.visible = false
          outInterface.menu.layout.props.visible = true
          outInterface.menu:update()
          outInterface.message.confirmScreen:update()
          I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
        elseif common.mainIsVisible() then
          common.teardownTransmog(prevStance)
        end
      end
    end,
    onInputAction = function(action)
        -- Intercept attempts to reopen the HUD and override them while 'mogging
        -- Not sure if this one can be made into an action?
      if action == input.ACTION.ToggleHUD
        and I.UI.isHudVisible()
        and (common.mainIsVisible() or common.confirmIsVisible()) then
          I.UI.setHudVisibility(false)
      end
    end,
    onFrame = function()
      if input.isActionPressed(input.ACTION.Console) and not consoleOpenedThisFrame then
        consoleOpenedThisFrame = true
      end
      -- close the menu if the console is opened
      if consoleOpenedThisFrame and not input.isActionPressed(input.ACTION.Console) then
        consoleOpenedThisFrame = false
        outInterface.consoleOpen = not outInterface.consoleOpen
        if outInterface.consoleOpen then
          if common.mainIsVisible() or common.confirmIsVisible() then
            if common.confirmIsVisible() then
              outInterface.message.confirmScreen.layout.props.visible = false
              outInterface.message.confirmScreen:update()
            end
            common.teardownTransmog(prevStance)
          end
        end
      end
    end,
  }
}
