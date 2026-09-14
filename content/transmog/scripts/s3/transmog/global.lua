---@omw-context global

local types = require 'openmw.types'
local world = require 'openmw.world'

local function inventoryItem(actor, recordId)
  local item = types.Actor.inventory(actor):find(recordId)
  assert(item, 'Transmog source item is no longer in the inventory')
  return item
end

local function createWeapon(data)
  local base = inventoryItem(data.actor, data.baseRecordId)
  local appearance = inventoryItem(data.actor, data.appearanceRecordId)
  local appearanceRecord = appearance.type.record(appearance)

  base:remove(1)

  local draft = types.Weapon.createRecordDraft {
    template = types.Weapon.record(base),
    name = data.name,
    model = appearanceRecord.model,
    icon = appearanceRecord.icon,
  }

  local object = world.createObject(world.createRecord(draft).id)
  object:moveInto(types.Actor.inventory(data.actor))

  return object
end

local function createApparel(data)
  local base = inventoryItem(data.actor, data.baseRecordId)
  local appearance = inventoryItem(data.actor, data.appearanceRecordId)
  local baseRecord = base.type.record(base)
  local draft

  base:remove(1)

  local fields = {
    template = appearance.type.record(appearance),
    name = data.name,
    enchant = baseRecord.enchant,
    enchantCapacity = baseRecord.enchantCapacity,
    mwscript = baseRecord.mwscript,
    value = baseRecord.value,
    weight = baseRecord.weight,
  }

  if appearance.type == types.Armor then
    if base.type == types.Armor then
      fields.baseArmor = baseRecord.baseArmor
      fields.health = baseRecord.health
    end
    draft = types.Armor.createRecordDraft(fields)
  else
    draft = types.Clothing.createRecordDraft(fields)
  end

  local object = world.createObject(world.createRecord(draft).id)
  object:moveInto(types.Actor.inventory(data.actor))

  return object
end

local function createFromBook(data)
  local book = inventoryItem(data.actor, data.baseRecordId)
  local appearance = inventoryItem(data.actor, data.appearanceRecordId)
  local bookRecord = types.Book.record(book)
  local draft

  book:remove(1)
  appearance:remove(1)

  local fields = {
    template = appearance.type.record(appearance),
    name = data.name,
    enchant = bookRecord.enchant,
    enchantCapacity = bookRecord.enchantCapacity,
  }

  if appearance.type == types.Armor then
    draft = types.Armor.createRecordDraft(fields)
  elseif appearance.type == types.Clothing then
    draft = types.Clothing.createRecordDraft(fields)
  elseif appearance.type == types.Weapon then
    draft = types.Weapon.createRecordDraft(fields)
  else
    error 'Books can only transfer their enchantment to armor, clothing, or weapons'
  end

  local object = world.createObject(world.createRecord(draft).id)
  object:moveInto(types.Actor.inventory(data.actor))

  return object
end

local function createTransmog(data)
  local base = inventoryItem(data.actor, data.baseRecordId)
  local created

  if base.type == types.Weapon then
    created = createWeapon(data)
  elseif base.type == types.Book then
    created = createFromBook(data)
  elseif base.type == types.Armor or base.type == types.Clothing then
    created = createApparel(data)
  else
    error 'Unsupported Transmog base item type'
  end

  data.actor:sendEvent('TransmogCreated', { object = created })
end

return {
  eventHandlers = {
    TransmogCreate = createTransmog,
  },
}
