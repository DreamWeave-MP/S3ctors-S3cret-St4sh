---@omw-context player

local I = require 'openmw.interfaces'
local openmwUi = require 'openmw.ui'
local util = require 'openmw.util'

local UtilVector2 = util.vector2
local menuSize = UtilVector2(620, 448)
local effectStripSize = UtilVector2(584, 30)
local spellListSize = UtilVector2(584, 326)
local effectIconSize = UtilVector2(18, 18)
local filterSize = UtilVector2(516, 24)
local fullSize = UtilVector2(1, 1)

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
    resource = { path = 'textures/menu_icon_magic_mini.dds' },
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

  local function buildListBody()
    local listChildren = {}

    local visiblePowers = filtered(powers, state)
    if next(visiblePowers) ~= nil then
      listChildren[#listChildren + 1] = section(ui, rebuild, state, 'Powers', nil, visiblePowers)
    end
    local visibleSpells = filtered(spells, state)
    if next(visibleSpells) ~= nil then
      listChildren[#listChildren + 1] =
        section(ui, rebuild, state, 'Spells', 'Cost/Chance', visibleSpells)
    end
    local visibleItems = filtered(enchantedItems, state)
    if next(visibleItems) ~= nil then
      listChildren[#listChildren + 1] =
        section(ui, rebuild, state, 'Magic Items', 'Charge', visibleItems)
    end

    if next(listChildren) == nil then
      listChildren[1] = ui.text {
        text = 'No spells or magic items match this filter.',
        tone = 'muted',
      }
    end

    return ui.column {
      gap = 4,
      props = { autoSize = false, relativeSize = fullSize },
      children = listChildren,
    }
  end

  local spellBox
  local function refilter()
    spellBox.content = openmwUi.content { buildListBody() }
    refresh()
  end

  local effectIcons = { ui.spacer(4, 0) }
  for index = 1, #effectColors do
    effectIcons[#effectIcons + 1] = effectIcon(ui, index)
  end

  local listBody = buildListBody()

  spellBox = ui.box {
    props = { size = spellListSize },
    children = { listBody },
  }

  return ui.window {
    name = 'ct_demo_magic_menu',
    title = state.selected or 'None',
    size = menuSize,
    movable = true,
    resizable = false,
    closable = false,
    pinnable = true,
    onMove = refresh,
    onPin = refresh,
    children = {
      ui.column {
        gap = 6,
        ui.box {
          props = { size = effectStripSize },
          children = {
            ui.row {
              gap = 2,
              props = {
                anchor = UtilVector2(0, 0.5),
                relativePosition = UtilVector2(0, 0.5),
              },
              children = effectIcons,
            },
          },
        },
        spellBox,
        ui.row {
          gap = 4,
          ui.searchInput {
            value = state.query,
            clearable = false,
            inputProps = { size = filterSize },
            onChange = function(value)
              state.query = value
              refilter()
            end,
          },
          ui.spacer(8, 0),
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
