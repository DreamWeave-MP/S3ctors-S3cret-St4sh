---@omw-context player

local I = require 'openmw.interfaces'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local menuSize = UtilVector2(620, 440)
local effectStripSize = UtilVector2(584, 30)
local spellListSize = UtilVector2(584, 326)
local effectIconSize = UtilVector2(18, 18)
local filterSize = UtilVector2(516, 24)
local relativeWidth = UtilVector2(1, 0)

local effectColors = {
  util.color.rgb(0.58, 0.33, 0.82),
  util.color.rgb(0.18, 0.66, 0.88),
  util.color.rgb(0.87, 0.30, 0.19),
  util.color.rgb(0.33, 0.76, 0.39),
  util.color.rgb(0.88, 0.72, 0.22),
}

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

local function matches(item, query, deleted)
  if deleted[item.name] then return false end
  if query == '' then return true end
  return string.find(string.lower(item.name), query, 1, true) ~= nil
end

local function filtered(items, state)
  local result = {}
  local query = string.lower(state.query or '')
  for index = 1, #items do
    local item = items[index]
    if matches(item, query, state.deleted) then result[#result + 1] = item end
  end
  return result
end

local function effectIcon(ui, index)
  return ui.image {
    name = 'magic_effect_' .. tostring(index),
    resource = { path = 'textures/menu_icon_magic.dds' },
    props = {
      size = effectIconSize,
      color = effectColors[index],
    },
  }
end

local function entry(ui, rebuild, state, item)
  return ui.listItem {
    label = item.name,
    secondary = item.secondary,
    selected = state.selected == item.name,
    onActivate = function()
      state.selected = item.name
      rebuild()
      return true
    end,
  }
end

local function section(ui, rebuild, state, title, secondary, items)
  if #items == 0 then return nil end

  local children = {}
  for index = 1, #items do
    children[#children + 1] = entry(ui, rebuild, state, items[index])
  end

  return ui.section {
    title = title,
    secondary = secondary,
    gap = 1,
    children = children,
  }
end

local function append(children, value)
  if value ~= nil then children[#children + 1] = value end
end

---@param invalidate? fun()
---@param rebuild? fun()
---@param state? table
---@return openmw.ui.Layout
local function magicMenu(invalidate, rebuild, state)
  local refresh = invalidate or function() end
  rebuild = rebuild or refresh
  state = state or {}
  state.query = state.query or ''
  state.deleted = state.deleted or {}

  local ui = I.H3UI.scope { invalidate = invalidate }
  local listChildren = {}

  append(listChildren, section(ui, rebuild, state, 'Powers', nil, filtered(powers, state)))
  append(
    listChildren,
    section(ui, rebuild, state, 'Spells', 'Cost/Chance', filtered(spells, state))
  )
  append(
    listChildren,
    section(ui, rebuild, state, 'Magic Items', 'Charge', filtered(enchantedItems, state))
  )

  if #listChildren == 0 then
    listChildren[1] = ui.text {
      text = 'No spells or magic items match this filter.',
      tone = 'muted',
    }
  end

  local effectIcons = {}
  for index = 1, #effectColors do
    effectIcons[index] = effectIcon(ui, index)
  end

  local listBody = ui.column {
    gap = 4,
    props = { relativeSize = relativeWidth },
    children = listChildren,
  }

  return ui.window {
    name = 'ct_demo_magic_menu',
    title = state.selected or 'None',
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
            text = state.query,
            props = { size = filterSize },
            onChange = function(value)
              state.query = value
              rebuild()
            end,
          },
          ui.button {
            label = 'Delete',
            tone = 'negative',
            onActivate = function()
              if state.selected == nil then return true end
              state.deleted[state.selected] = true
              state.selected = nil
              rebuild()
              return true
            end,
          },
        },
      },
    },
  }
end

return magicMenu
