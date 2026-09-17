---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local menuSize = UtilVector2(620, 440)
local effectStripSize = UtilVector2(584, 30)
local spellListSize = UtilVector2(584, 316)
local effectIconSize = UtilVector2(18, 18)
local filterSize = UtilVector2(516, 24)
local relativeWidth = UtilVector2(1, 0)

local powers = {
  { name = 'Adrenaline Rush' },
  { name = 'Ancestor Guardian' },
}

local spells = {
  { name = 'Detect Creature', secondary = '19/63' },
  { name = 'Hearth Heal', secondary = '6/100' },
  { name = 'Water Walking', secondary = '9/92' },
  { name = 'Fire Bite', secondary = '7/87' },
  { name = 'Levitate', secondary = '14/74' },
  { name = 'Bound Longsword', secondary = '11/81' },
  { name = 'Summon Ancestral Ghost', secondary = '21/58' },
  { name = 'The Unnecessarily Verbose Telvanni Experimental Recall', secondary = '38/41' },
}

local enchantedItems = {
  { name = 'Engraved Ring of Healing', secondary = '18/20' },
  { name = 'Amulet of Recall', secondary = '9/12' },
  { name = 'Fargoth\'s Questionably Enchanted Pants', secondary = '3/5' },
}

local function effectIcon(ui, index)
  return ui.image {
    name = 'magic_effect_' .. tostring(index),
    resource = { path = 'textures/menu_icon_magic.dds' },
    props = { size = effectIconSize },
  }
end

local function entry(ui, refresh, status, item)
  return ui.listItem {
    label = item.name,
    secondary = item.secondary,
    onActivate = function()
      status.props.text = item.name
      refresh()
      return true
    end,
  }
end

local function section(ui, refresh, status, title, secondary, items)
  local children = {}
  for index = 1, #items do
    children[#children + 1] = entry(ui, refresh, status, items[index])
  end
  return ui.section {
    title = title,
    secondary = secondary,
    gap = 1,
    props = { relativeSize = relativeWidth },
    children = children,
  }
end

---@param invalidate? fun()
---@return openmw.ui.Layout
local function magicMenu(invalidate)
  local refresh = invalidate or function() end
  local ui = I.H3UI.scope { invalidate = invalidate }
  local status = ui.text { text = 'None', tone = 'muted' }
  local effectIcons = {}
  for index = 1, 5 do
    effectIcons[index] = effectIcon(ui, index)
  end

  local listBody = ui.column {
    gap = 2,
    props = { relativeSize = relativeWidth },
    section(ui, refresh, status, 'Powers', nil, powers),
    ui.divider(),
    section(ui, refresh, status, 'Spells', 'Cost/Chance', spells),
    ui.divider(),
    section(ui, refresh, status, 'Magic Items', 'Charge', enchantedItems),
  }

  return ui.window {
    name = 'ct_demo_magic_menu',
    title = 'None',
    size = menuSize,
    movable = true,
    resizable = false,
    closable = false,
    pinnable = true,
    children = {
      ui.column {
        gap = 6,
        ui.box {
          props = { size = effectStripSize },
          children = {
            ui.row {
              gap = 2,
              children = effectIcons,
            },
          },
        },
        ui.box {
          props = { size = spellListSize },
          children = { listBody },
        },
        ui.row {
          gap = 4,
          ui.textInput {
            text = '',
            props = { size = filterSize },
            onChange = function(value)
              status.props.text = value == '' and 'None' or ('Filter: ' .. value)
              refresh()
            end,
          },
          ui.button {
            label = 'Delete',
            tone = 'negative',
            onActivate = function()
              status.props.text = 'Delete requested'
              refresh()
              return true
            end,
          },
        },
        ui.row {
          ui.text 'Selected:',
          ui.spacer { grow = 1 },
          status,
        },
      },
    },
  }
end

return magicMenu
