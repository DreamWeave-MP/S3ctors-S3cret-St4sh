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

local function entry(ui, selectSpell, state, item)
  return ui.listItem {
    label = item.name,
    secondary = item.secondary,
    selected = state.selected == item.name,
    onActivate = function()
      selectSpell(item.name)
      return true
    end,
  }
end

local function section(ui, selectSpell, state, title, secondary, items)
  local children = {}
  for index = 1, #items do
    children[#children + 1] = entry(ui, selectSpell, state, items[index])
  end

  return ui.section {
    title = title,
    secondary = secondary,
    gap = 1,
    children = children,
  }
end

local function findCaptionText(windowLayout)
  local caption = windowLayout.content[2]
  if caption == nil then return nil end
  for index = 1, #caption.content do
    local child = caption.content[index]
    if child.name == 'text' and child.content ~= nil then
      for subIndex = 1, #child.content do
        local sub = child.content[subIndex]
        if sub.type == openmwUi.TYPE.Text then return sub end
      end
    end
  end
  return nil
end

---@param invalidate? fun()
---@param rebuild? fun()
---@param state? table
---@return openmw.ui.Layout
local function magicMenu(invalidate, rebuild, state)
  rebuild = rebuild or function() end
  state = state or {}
  state.query = state.query or ''
  state.deleted = state.deleted or {}

  local shellUi = I.H3UI.scope { invalidate = invalidate }

  local listElement
  local listUi = I.H3UI.scope {
    element = function() return listElement end,
  }

  local spellBox
  local titleText
  local selectSpell

  local function buildListBody()
    local listChildren = {}

    local visiblePowers = filtered(powers, state)
    if next(visiblePowers) ~= nil then
      listChildren[#listChildren + 1] =
        section(listUi, selectSpell, state, 'Powers', nil, visiblePowers)
    end
    local visibleSpells = filtered(spells, state)
    if next(visibleSpells) ~= nil then
      listChildren[#listChildren + 1] =
        section(listUi, selectSpell, state, 'Spells', 'Cost/Chance', visibleSpells)
    end
    local visibleItems = filtered(enchantedItems, state)
    if next(visibleItems) ~= nil then
      listChildren[#listChildren + 1] =
        section(listUi, selectSpell, state, 'Magic Items', 'Charge', visibleItems)
    end

    if next(listChildren) == nil then
      listChildren[1] = listUi.text {
        text = 'No spells or magic items match this filter.',
        tone = 'muted',
      }
    end

    return listUi.column {
      gap = 4,
      props = { autoSize = false, relativeSize = fullSize },
      children = listChildren,
    }
  end

  local function updateTitle()
    if titleText then titleText.props.text = state.selected or 'None' end
  end

  local function refreshShell()
    if shellUi.invalidate then shellUi.invalidate() end
  end

  function selectSpell(name)
    state.selected = name
    listUi.setChildren(spellBox, { buildListBody() })
    updateTitle()
    refreshShell()
  end

  local function refilter() listUi.setChildren(spellBox, { buildListBody() }) end

  local effectIcons = { shellUi.spacer(4, 0) }
  for index = 1, #effectColors do
    effectIcons[#effectIcons + 1] = effectIcon(shellUi, index)
  end

  spellBox = listUi.box {
    props = { size = spellListSize },
    children = { buildListBody() },
  }
  listElement = openmwUi.create(spellBox)

  local windowLayout = shellUi.window {
    name = 'ct_demo_magic_menu',
    title = state.selected or 'None',
    size = menuSize,
    movable = true,
    resizable = false,
    closable = false,
    pinnable = true,
    children = {
      shellUi.column {
        gap = 6,
        shellUi.box {
          props = { size = effectStripSize },
          children = {
            shellUi.row {
              gap = 2,
              props = {
                anchor = UtilVector2(0, 0.5),
                relativePosition = UtilVector2(0, 0.5),
              },
              children = effectIcons,
            },
          },
        },
        listElement,
        shellUi.row {
          gap = 4,
          shellUi.searchInput {
            value = state.query,
            clearable = false,
            inputProps = { size = filterSize },
            onChange = function(value)
              state.query = value
              refilter()
            end,
          },
          shellUi.spacer(8, 0),
          shellUi.button {
            label = 'Delete',
            tone = 'negative',
            onActivate = function()
              if state.selected == nil then return true end
              state.deleted[state.selected] = true
              state.selected = nil
              listUi.setChildren(spellBox, { buildListBody() })
              updateTitle()
              refreshShell()
              return true
            end,
          },
        },
      },
    },
  }

  titleText = findCaptionText(windowLayout)
  assert(titleText ~= nil, 'H3 magic menu fixture requires a caption text layout')

  return windowLayout
end

return magicMenu
