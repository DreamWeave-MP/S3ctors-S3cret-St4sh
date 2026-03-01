local I = require('openmw.interfaces')

local async = require('openmw.async')
local common = require('scripts.s3.transmog.ui.common')
local input = require('openmw.input')
-- local self = require('openmw.self')
-- local types = require('openmw.types')
-- local ui = require('openmw.ui')

-- UI Elements
-- local InventoryContainer = require('scripts.s3.transmog.ui.inventorycontainer.main')
local Aliases = require('scripts.s3.transmog.ui.menualiases')

-- Lib
local tearDownTransmog = require('scripts.s3.transmog.lib.teardowntransmog')
-- add safeties for unsupported types
-- add stacking for ammunition

local prevStance = nil

local outInterface = {
  message = {
    singleton = nil,
    toolTip = nil,
    hasShowedPreviewWarning = false,
  },
  menus = {
    -- Standalone widgets
    main = nil,
    confirmScreen = nil,
    -- child widgets, but still referenced somehow
    leftPane = nil,
    rightPane = nil,
    baseItemContainer = nil,
    newItemContainer = nil,
    inventoryContainer = nil,
  },
  originalEquipment = {},
  consoleOpen = false,
  messageBox = common.messageBoxSingleton,
}

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
  },
  engineHandlers = {
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
        if common.isVisible('confirm screen') then
          local confirmScreen = Aliases('confirm screen')
          local mainMenu = Aliases('main menu')
          confirmScreen.layout.props.visible = false
          mainMenu.layout.props.visible = true
          mainMenu:update()
          confirmScreen:update()
          I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
        elseif common.isVisible('main menu') then
          tearDownTransmog(prevStance)
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
          if common.isVisible('main menu') or common.isVisible('confirm screen') then
            if common.isVisible('confirm screen') then
              local confirmScreen = Aliases('confirm screen')
              confirmScreen.layout.props.visible = false
              confirmScreen:update()
            end
            tearDownTransmog(prevStance)
          end
        end
      end
    end,
  }
}
