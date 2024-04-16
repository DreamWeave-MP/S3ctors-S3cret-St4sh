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
    ['item container'] = I.transmogActions.menus.itemContainer,
    ['glamour button'] = I.transmogActions.menus.glamourButton,
    ['confirm screen'] = I.transmogActions.menus.confirmScreen,
    ['confirm screen input'] = I.transmogActions.menus.confirmScreenInput,
    ['message box'] = I.transmogActions.message.singleton,
    ['original inventory'] = I.transmogActions.originalInventory,
    ['current inventory'] = types.Actor.inventory(self):getAll(),
    ['equipment'] = types.Actor.getEquipment(self),
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
