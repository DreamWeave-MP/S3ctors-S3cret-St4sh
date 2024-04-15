local I = require('openmw.interfaces')

local async = require('openmw.async')
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
  message = {
  },
  menus = {
    main = nil,
    leftPane = nil,
    rightPane = nil,
    baseItemContainer = nil,
    newItemContainer = nil,
    itemContainer = nil,
    originalInventory = nil,
  },
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

  local baseItem = I.transmogActions.menus.baseItemContainer.content[2].userData
  local newItem = I.transmogActions.menus.newItemContainer.content[2].userData

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
  types.Actor.setEquipment(self, I.transmogActions.menus.originalInventory)
  common.resetPortraits()
  outInterface.menus.itemContainer.content = ui.content(ItemContainer.updateContent(outInterface.itemContainer.userData))
  outInterface.menus.main.layout.props.visible = true
  outInterface.message.confirmScreen.layout.props.visible = false
  outInterface.message.confirmScreen:update()
  outInterface.menus.main:update()
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

local canUseMogMenu = function()
    if not types.Actor.isOnGround(self) then
      if not outInterface.message.cantUseControls then
        outInterface.message.cantUseControls = true
        common.messageBoxSingleton("Ground Warning", "You must be on the ground to use the glamour menu!", 2)
      end
      return false
    elseif types.Actor.isSwimming(self) then
      if not outInterface.message.cantUseSwimming then
        outInterface.message.cantUseSwimming = true
        common.messageBoxSingleton("Swimming Warning", "You use the glamour menu while swimming!", 2)
      end
      return false
    elseif I.UI.getMode() == I.UI.MODE.MainMenu then
      if not outInterface.message.cantUseMainMenu then
        outInterface.message.cantUseMainMenu = true
        common.messageBoxSingleton("Main Menu Warning", "You must not be in the main menu to use the glamour menu!", 2)
      end
      return false
    elseif outInterface.consoleOpen then
      if not outInterface.message.cantUseConsole then
        outInterface.message.cantUseConsole = true
        common.messageBoxSingleton("Console Warning", "You must close the console before opening the glamour menu!", 2)
      end
      return false
    elseif common.messageIsVisible() then
      if not outInterface.message.cantUseMessage then
        outInterface.message.cantUseMessage = true
        common.messageBoxSingleton("Message Warning", "You must not have a messagebox open before opening the glamour menu!", 2)
      end
      return false
    elseif common.confirmIsVisible() then
      if not outInterface.message.cantUseConfirm then
        outInterface.message.cantUseConfirm = true
        common.messageBoxSingleton("Confirm Warning", "You must confirm or cancel your current choices before opening the glamour menu!", 2)
      end
      return false
    end
    return true
end

-- Now we set up the callback
local menuStateSwitch = function()
    if not canUseMogMenu() then return end
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

    if not outInterface.menus.main then
      outInterface.menus.main = MainWidget()
      outInterface.menus.leftPane = outInterface.menus.main.layout.content[1].content[1]
      outInterface.menus.rightPane = outInterface.menus.main.layout.content[1].content[3]
      outInterface.menus.baseItemContainer = outInterface.menus.leftPane.content[2]
      outInterface.menus.newItemContainer = outInterface.menus.leftPane.content[4]
      outInterface.menus.itemContainer = outInterface.menus.rightPane.content[1].content[3].content[1].content[1]
      outInterface.menus.originalInventory = types.Actor.getEquipment(self)
      outInterface.message.singleton = nil
      outInterface.message.confirmScreen = nil
      outInterface.message.toolTip = nil
      outInterface.message.hasShowedPreviewWarning = false
      prevStance = types.Actor.getStance(self)
      rotateWarning()
    else
      outInterface.menus.main.layout.props.visible = not outInterface.menus.main.layout.props.visible
      if outInterface.menus.main.layout.props.visible then
        common.resetPortraits()
        -- So when you close it, it keeps whatever layout it had last.
        -- Is this desirable??
        outInterface.menus.main.itemContainer.content
          = ui.content(ItemContainer.updateContent(outInterface.itemContainer.userData))
        outInterface.menus.main.originalInventory = types.Actor.getEquipment(self)
        prevStance = types.Actor.getStance(self)
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        rotateWarning()
      else
        outInterface.message.hasShowedPreviewWarning = false
        types.Actor.setEquipment(self, outInterface.menus.originalInventory)
        types.Actor.setStance(self, prevStance)
      end
      if common.toolTipIsVisible() then
        outInterface.message.toolTip.layout.props.visible = false
        outInterface.message.toolTip:update()
      end
      outInterface.menus.main:update()
    end
end

input.registerActionHandler("transmogMenuRotateRight", async:callback(function()
    if not outInterface.menus.main or outInterface.message.confirmScreen
      or not outInterface.menus.main.layout.props.visible then return end
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
    if not outInterface.menus.main or outInterface.message.confirmScreen
      or not outInterface.menus.main.layout.props.visible then return end
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
  if not canUseMogMenu() or not common.mainIsVisible() then return end
  if not common.toolTipIsVisible() and not isPreviewing then
    common.messageBoxSingleton("Preview Warning", "You must have an item selected to preview it!", 0.5)
    return
  end

  if outInterface.menus.newItemContainer.content[2].userData then
    isPreviewing = true
    common.messageBoxSingleton("Preview Warning", "You must confirm your current choices before previewing another item!", 0.5)
    return
  end

  local toolTip = ToolTip.get()
  local recordId = ToolTip.getRecordId()

  local equipment = {}
  for slot, item in pairs(outInterface.menus.originalInventory) do
    if item.recordId == recordId then
      common.messageBoxSingleton("Preview Warning", "You cannot preview an item you are currently wearing!", 0.5)
      return
    end
    equipment[slot] = item
  end

  if input.getBooleanActionValue("transmogMenuActivePreview") then
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
input.registerTriggerHandler("transmogMenuOpen", async:callback(menuStateSwitch))

input.registerTriggerHandler("transmogMenuConfirm", async:callback(function()
                                -- Use this key to finish the 'mog
                                -- Only if either of the two relevant menus is open
                                -- Guess we'll also need to do this for enhancements as well.
                                -- I decided I like doing it this way better than attaching
                                -- callbacks to the widget directly because I can't actually correlate a keybind to a widget there
                                 if common.mainIsVisible() then
                                  ConfirmScreen()
                                 elseif common.confirmIsVisible() then
                                  outInterface.acceptTransmog()
                                 end
end))

local lastAction = nil
local lastKey = nil
local lastMouse = nil
local updateQueued = false
local pressedKeys = {}
local pressedMice = {}

local savedBinds = {
  keys = {},
  mice = {},
}
local neededActions = {
  [input.ACTION.Console] = "Console",
  [input.ACTION.Sneak] = "Sneak",
  [input.ACTION.ZoomOut] = "Zoom Out",
  [input.ACTION.ZoomIn] = "Zoom In",
  [input.ACTION.Use] = "Use",
  [input.ACTION.Jump] = "Jump",
  [input.ACTION.Activate] = "Activate",
  [input.ACTION.MoveForward] = "Forward",
  [input.ACTION.MoveBackward] = "Backward",
}
local keyAliases = {
  [input.KEY.LeftCtrl] = "Left Ctrl",
  [input.KEY.RightCtrl] = "Right Ctrl",
  [input.KEY.LeftAlt] = "Left Alt",
  [input.KEY.RightAlt] = "Right Alt",
  [input.KEY.LeftShift] = "Left Shift",
  [input.KEY.RightShift] = "Right Shift",
  [input.KEY.LeftSuper] = "Left Super",
  [input.KEY.RightSuper] = "Right Super",
  [input.KEY.Space] = "Space",
  [input.KEY.Enter] = "Return",
}

local function updateKeybind(actionBind, key)
  if not lastKey or lastKey.code ~= key.code or lastMouse then return end
  local updateKey = true
  for savedKey, _ in pairs(savedBinds.keys) do
    if savedBinds.keys[savedKey] == actionBind then
      if savedKey.code ~= key.code then
        savedBinds.keys[savedKey] = nil
      else
        updateKey = false
      end
    end
  end

  if updateKey then
    savedBinds.keys[actionBind] = {code = key.code, symbol = keyAliases[key.code] or key.symbol}
  end
end

local function updateMouse(actionBind, mouseButton)
  if not lastMouse or lastMouse ~= mouseButton or lastKey then return end
  local updateMouseBind = true
  for savedMouse, _ in pairs(savedBinds.mice) do
    if savedBinds.mice[savedMouse] == actionBind then
      if savedMouse ~= mouseButton then
        savedBinds.mice[savedMouse] = nil
      else
        updateMouseBind = false
      end
    end
  end
  if updateMouseBind then
    savedBinds.mice[actionBind] = mouseButton
  end
end

local function removePressedKey(key)
  for index, oldKey in pairs(pressedKeys) do
    if oldKey.code == key.code then
      pressedKeys[index] = nil
    end
  end
end

local function removePressedMouse(mouse)
  for index, oldMouse in pairs(pressedMice) do
    if oldMouse == mouse then
      pressedMice[index] = nil
    end
  end
end

local function removePressedWheels(wheelState)
  -- ????
  -- for index, oldWheel in pairs(pressedWheels) do
    -- if oldMouse == input.MOUSE.WheelUp or oldMouse == input.MOUSE.WheelDown then
    --   pressedMice[index] = nil
    -- end
end

--- This function is used to delete a keybind if it is not unique
--- @param actionBind openmw.input.ACTION: table key for all intercepted keybinds
--- @param userInput openmw.input.KEY: the actual button pressed by the user when trying to intercept this bind
local function deleteUniqueAction(actionBind, userInput)
  for action, key in pairs(savedBinds.keys) do
    if action == actionBind then
      if key.code == userInput and not savedBinds.mice[actionBind] then return true end
      savedBinds.keys[action] = nil
    end
  end
  for action, button in pairs(savedBinds.mice) do
    if action == actionBind then
      if button == userInput and not savedBinds.keys[actionBind] then return true end
      savedBinds.mice[action] = nil
    end
  end
end

--- This function is used to filter out keybinds that are not unique
--- If it exists at all in one of the two tables (we'll need more) we see if it's the same as our current input
--- If not, we delete it, if it is, we return true and bail on the whole thing
--- @param actionBind openmw.input.ACTION: table key for all intercepted keybinds
--- @param userInput openmw.input.KEY: the actual button pressed by the user when trying to intercept this bind
local function filterUniqueActions(actionBind, userInput)
  if savedBinds.keys[actionBind] or savedBinds.mice[actionBind] then
    return deleteUniqueAction(actionBind, userInput)
  end
end

--- This function is used to map a keybind to an action
--- Agnostic of input, but does act based on what exactly you're binding against
--- of course doing system keybinds is a bit different than just using the settings menu which
--- requires far less fuckery
local function mapKeyToAction(actionBind, userInput, isMouse)
  if not actionBind then return end
  local convertKeyboard = isMouse and userInput or userInput.code
  if filterUniqueActions(actionBind, convertKeyboard) then return end
  if isMouse then
    updateMouse(actionBind, userInput)
  else
    updateKeybind(actionBind, userInput)
    common.deepPrint(savedBinds.keys, 3)
  end
  updateQueued = false
  lastKey = nil
  lastMouse = nil
  lastAction = nil
end

local function queueActionBinding(action, userInput, isMouse)
  async:newUnsavableSimulationTimer(0.25, function()
                                if #pressedMice == 0 and #pressedKeys == 0 then
                                  mapKeyToAction(action, userInput, isMouse)
                                else
                                  queueActionBinding(action, userInput, isMouse)
                                end
  end)
end

outInterface.getKeyByAction = function(requestedAction)
  for action, key in pairs(savedBinds.keys) do
    if action == requestedAction then return keyAliases[key.code] or key.symbol end
  end
end

outInterface.getMiceActions = function()
  return savedBinds.mice
end

outInterface.getWheelActions = function()
  return savedBinds.wheels
end

local consoleOpenedThisFrame = false
return {
  interface = outInterface,
  -- interfaceName = 'transmogActions',
  eventHandlers = {
    inputKeyRequest = function(actionData)
      local action = actionData.action
      local foundKey = savedBinds.keys[action]
      -- Unimplemented, but we send this event back to ourselves to get the right keybind
      -- local responseName = actionData.responseName
      if not foundKey then
        if not common.defaultActions[action] then return end
        foundKey = common.defaultActions[action] .. " from defaults"
      else
        foundKey = keyAliases[foundKey.code] or foundKey.symbol .. " from input"
      end
      if not foundKey then return end
      print("Key requested for action: " .. common.actionNames[action]
            .. " and is "
            .. foundKey)
    end,
    itemContainerRequest = function(receiver)
      self:sendEvent(receiver, outInterface.itemContainer)
    end,
  },
  engineHandlers = {
    onInit = function()
      common.messageBoxSingleton("Welcome One", "Thank you for installing Glamour Menu!", 3)
      common.messageBoxSingleton("Welcome Two", "Please be aware that OpenMW does not\npresently allow mods to use default keybinds!", 3)
      common.messageBoxSingleton("Welcome Three", "We recommend the following defaults:\n"
                                 .. "Q and E for rotate right and left respectively\n"
                                 .. "Enter/Return for select\n"
                                 .. "And L to open the menu.\n"
                                 .. "Happy Glamming!", 3)
      -- Add a check for Kartoffel's empty gear mod
    end,
    onMouseButtonRelease = function(button)
      removePressedMouse(button)
      if not updateQueued
        and lastAction
        and neededActions[lastAction]
        and #pressedMice == 0
        and button == lastMouse then
        queueActionBinding(lastAction, button, true)
      end
    end,
    onMouseButtonPress = function(button)
      pressedMice[#pressedMice + 1] = button
      lastMouse = button
    end,
    onKeyPress = function(key)
      pressedKeys[#pressedKeys + 1] = key
      lastKey = key
    end,
    onKeyRelease = function(key)
      removePressedKey(key)
      if not updateQueued
        and lastAction
        and neededActions[lastAction]
        and #pressedKeys == 0
        and key.code == lastKey.code then
        queueActionBinding(lastAction, key, false)
      end
      -- Since the engine doesn't let you bind ESC
      -- and it's generally just used to close stuff, do that here
      if key.code == input.KEY.Escape then
        if outInterface.consoleOpen then
          outInterface.consoleOpen = false
        end
        if common.confirmIsVisible() then
          outInterface.message.confirmScreen.layout.props.visible = false
          outInterface.menus.main.layout.props.visible = true
          outInterface.menus.main:update()
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
      lastAction = action
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
      if I.UI.getMode() == I.UI.MODE.MainMenu then
        for _, bindTable in pairs(savedBinds) do
          for action, _ in pairs(bindTable) do
            bindTable[action] = nil
          end
        end
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
