---@omw-context player

local types = require 'openmw.types'

local catalog = {
  [types.Armor] = {
    wearable = true,
  },

  [types.Clothing] = {
    wearable = true,
  },

  [types.Weapon] = {
    wearable = true,
    slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
  },

  [types.Light] = {
    wearable = true,
    slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
  },

  [types.Lockpick] = {
    wearable = true,
    slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
  },

  [types.Probe] = {
    wearable = true,
    slot = types.Actor.EQUIPMENT_SLOT.CarriedRight,
  },

  [types.Book] = {},

  [types.Miscellaneous] = {},

  [types.Apparatus] = {},

  [types.Ingredient] = {},

  [types.Repair] = {},

  [types.Potion] = {},
}

local armorSlots = {
  [types.Armor.TYPE.Cuirass] = types.Actor.EQUIPMENT_SLOT.Cuirass,

  [types.Armor.TYPE.Greaves] = types.Actor.EQUIPMENT_SLOT.Greaves,

  [types.Armor.TYPE.Boots] = types.Actor.EQUIPMENT_SLOT.Boots,

  [types.Armor.TYPE.Helmet] = types.Actor.EQUIPMENT_SLOT.Helmet,

  [types.Armor.TYPE.LPauldron] = types.Actor.EQUIPMENT_SLOT.LeftPauldron,

  [types.Armor.TYPE.RPauldron] = types.Actor.EQUIPMENT_SLOT.RightPauldron,

  [types.Armor.TYPE.LGauntlet] = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,

  [types.Armor.TYPE.LBracer] = types.Actor.EQUIPMENT_SLOT.LeftGauntlet,

  [types.Armor.TYPE.RGauntlet] = types.Actor.EQUIPMENT_SLOT.RightGauntlet,

  [types.Armor.TYPE.RBracer] = types.Actor.EQUIPMENT_SLOT.RightGauntlet,

  [types.Armor.TYPE.Shield] = types.Actor.EQUIPMENT_SLOT.CarriedLeft,
}

local clothingSlots = {
  [types.Clothing.TYPE.Shirt] = types.Actor.EQUIPMENT_SLOT.Shirt,

  [types.Clothing.TYPE.Pants] = types.Actor.EQUIPMENT_SLOT.Pants,

  [types.Clothing.TYPE.Skirt] = types.Actor.EQUIPMENT_SLOT.Skirt,

  [types.Clothing.TYPE.Robe] = types.Actor.EQUIPMENT_SLOT.Robe,

  [types.Clothing.TYPE.Shoes] = types.Actor.EQUIPMENT_SLOT.Boots,

  [types.Clothing.TYPE.Amulet] = types.Actor.EQUIPMENT_SLOT.Amulet,

  [types.Clothing.TYPE.Belt] = types.Actor.EQUIPMENT_SLOT.Belt,

  [types.Clothing.TYPE.Ring] = types.Actor.EQUIPMENT_SLOT.LeftRing,
}

function catalog.isSupported(item) return catalog[item.type] ~= nil end

function catalog.isWearable(item)
  local entry = catalog[item.type]

  return entry and entry.wearable == true
end

function catalog.slot(item)
  local entry = catalog[item.type]

  if not entry or not entry.wearable then return end

  if entry.slot then return entry.slot end

  local record = item.type.records[item.recordId]

  if item.type == types.Armor then return armorSlots[record.type] end

  if item.type == types.Clothing then return clothingSlots[record.type] end
end

return catalog
