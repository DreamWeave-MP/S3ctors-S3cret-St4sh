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

-- Also just make most of this an event; everything that isn't related to the menus directly
-- Now we set up the callback
outInterface.menuStateSwitch = function()
  if not canUseMogMenu() then return end
  --- Maybe some event should handle this bit?
  self:sendEvent('switchTransmogMenu')

  if not I.transmogActions.menus.main then
      MainWidget()
      common.updateOriginalInventory()
      -- print('inventory has been assigned on initial construction...')
      -- common.deepPrint(Aliases('original inventory'), 3)
      prevStance = types.Actor.getStance(self)
      rotateWarning()
    else
      local mainMenu = Aliases('main menu')
      local mainIsVisible = common.isVisible('main menu')
      mainMenu.layout.props.visible = not mainIsVisible
      if common.isVisible('main menu') then
        common.resetPortraits()
        -- So when you close it, it keeps whatever layout it had last.
        -- Is this desirable??
        local itemContainer = Aliases('item container')
        itemContainer.content = ui.content(ItemContainer.updateContent(itemContainer.userData))
        common.updateOriginalInventory()
        prevStance = types.Actor.getStance(self)
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        rotateWarning()
      else
        outInterface.message.hasShowedPreviewWarning = false
        types.Actor.setEquipment(self, Aliases()['original inventory'])
        types.Actor.setStance(self, prevStance)
      end
      if common.toolTipIsVisible() then
        outInterface.message.toolTip.layout.props.visible = false
        outInterface.message.toolTip:update()
      end
      Aliases('main menu'):update()
    end
end

-- make this an event
local isPreviewing = false
outInterface.updatePreview = function()
  if not canUseMogMenu() or not common.isVisible('main menu') then return end
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
          local mainMenu = common.mainMenu()
          mainMenu.layout.props.visible = true
          mainMenu:update()
          outInterface.message.confirmScreen:update()
          I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
        elseif common.mainIsVisible() then
          common.teardownTransmog(prevStance)
        end
      end
    end,
    onInputAction = function(action)
      lastAction = action
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
