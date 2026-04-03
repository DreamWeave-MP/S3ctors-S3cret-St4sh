local deepPrint = require('openmw_aux.util').deepToString
local self = require("openmw.self")
local types = require("openmw.types")

local I = require("openmw.interfaces")

local function MenuAliases(alias)
  local aliases = {
    ['base item'] = I.transmogActions.menus.baseItemContainer,
    ['new item'] = I.transmogActions.menus.newItemContainer,
    ['main menu'] = I.transmogActions.menus.main,
    ['left pane'] = I.transmogActions.menus.leftPane,
    ['right pane'] = I.transmogActions.menus.rightPane,
    ['inventory container'] = I.transmogActions.menus.inventoryContainer,
    ['glamour button'] = I.transmogActions.menus.glamourButton,
    ['confirm screen'] = I.transmogActions.menus.confirmScreen,
    ['confirm screen input'] = I.transmogActions.menus.confirmScreenInput,
    ['tooltip'] = I.transmogActions.message.toolTip,
    ['message box'] = I.transmogActions.message.singleton,
    ['inventory'] = types.Actor.inventory(self):getAll(),
    ['original equipment'] = I.transmogActions.originalEquipment,
    ['current equipment'] = types.Actor.getEquipment(self),
  }

  if alias == 'diag' then
    deepPrint(aliases, 2)
    return
  end

  if alias and not aliases[alias] then
    return
  end

  return aliases[alias] or aliases
end

return MenuAliases
