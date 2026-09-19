---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local openmwUi = require 'openmw.ui'
local util = require 'openmw.util'

local Assert, Next, SetMetatable, StrFind, StrFormat, StrLower, ToString =
  assert, next, setmetatable, string.find, string.format, string.lower, tostring

local ColorRGB, UtilVector2 = util.color.rgb, util.vector2
local MenuSize, EffectStripSize, SpellListSize, EffectIconSize, FilterSize, FullSize =
  UtilVector2(620, 448),
  UtilVector2(584, 30),
  UtilVector2(584, 326),
  UtilVector2(18, 18),
  UtilVector2(516, 24),
  UtilVector2(1, 1)
local WeakKeys = { __mode = 'k' }

local EffectColors = {
  ColorRGB(0.58, 0.33, 0.82),
  ColorRGB(0.18, 0.66, 0.88),
  ColorRGB(0.87, 0.30, 0.19),
  ColorRGB(0.33, 0.76, 0.39),
  ColorRGB(0.88, 0.72, 0.22),
}

local Powers = {
  { name = 'Adrenaline Rush' },
  { name = 'Ancestor Guardian' },
}

local Spells = {
  { name = 'Detect Creature', secondary = '19/63' },
  { name = 'Hearth Heal', secondary = '6/100' },
  { name = 'Water Walking', secondary = '9/92' },
  { name = 'Fire Bite', secondary = '7/87' },
  { name = 'Levitate', secondary = '14/74' },
  { name = 'Bound Longsword', secondary = '11/81' },
  { name = 'Summon Ancestral Ghost', secondary = '21/58' },
  { name = 'The Unnecessarily Verbose Telvanni Experimental Recall', secondary = '38/41' },
}

local EnchantedItems = {
  { name = 'Engraved Ring of Healing', secondary = '18/20' },
  { name = 'Amulet of Recall', secondary = '9/12' },
  { name = 'Fargoth\'s Questionably Enchanted Pants', secondary = '3/5' },
}

---@param item H3ComponentTest.MagicEntry
---@param query string
---@param deleted table<string, boolean>
---@return boolean
local function matches(item, query, deleted)
  if deleted[item.name] then return false end
  if query == '' then return true end

  return not not StrFind(StrLower(item.name), query, 1, true)
end

---@param items H3ComponentTest.MagicEntry[]
---@param state H3ComponentTest.MagicState
---@return H3ComponentTest.MagicEntry[]
local function filtered(items, state)
  local result = {}
  local query = StrLower(state.query or '')
  for index = 1, #items do
    local item = items[index]
    if matches(item, query, state.deleted) then result[#result + 1] = item end
  end
  return result
end

---@param ui H3UI.Scope
---@param index integer
---@return openmw.ui.Layout
local function effectIcon(ui, index)
  return ui.image {
    name = StrFormat('magic_effect_%s', ToString(index)),
    resource = { path = 'textures/menu_icon_magic_mini.dds' },
    props = {
      size = EffectIconSize,
      color = EffectColors[index],
    },
  }
end

---@param ui H3UI.Scope
---@param activation H3ComponentTest.MagicActivation
---@param state H3ComponentTest.MagicState
---@param item H3ComponentTest.MagicEntry
---@param layouts? table<string, openmw.ui.Layout>
---@return openmw.ui.Layout
local function entry(ui, activation, state, item, layouts)
  local layout = ui.listItem {
    label = item.name,
    secondary = item.secondary,
    selected = state.selected == item.name,
  }
  activation.targets[layout] = item
  local events = layout.events or {}
  events.mouseClick = activation.callback
  layout.events = events
  if layouts and state.selected == item.name then layouts[item.name] = layout end
  return layout
end

---@param ui H3UI.Scope
---@param activation H3ComponentTest.MagicActivation
---@param state H3ComponentTest.MagicState
---@param title string
---@param secondary? string
---@param items H3ComponentTest.MagicEntry[]
---@param layouts? table<string, openmw.ui.Layout>
---@return openmw.ui.Layout
local function section(ui, activation, state, title, secondary, items, layouts)
  local children = {}
  for index = 1, #items do
    children[#children + 1] = entry(ui, activation, state, items[index], layouts)
  end

  return ui.section {
    title = title,
    secondary = secondary,
    gap = 1,
    children = children,
  }
end

---@param windowLayout openmw.ui.Layout
---@return openmw.ui.Layout?
local function findCaptionText(windowLayout)
  local caption = windowLayout.content[2]
  if not caption then return end
  for index = 1, #caption.content do
    local child = caption.content[index]
    if child.name == 'text' and child.content then
      for subIndex = 1, #child.content do
        local sub = child.content[subIndex]
        if sub.type == openmwUi.TYPE.Text then return sub end
      end
    end
  end
  return nil
end

---@param invalidate? fun(): nil
---@param rebuild? fun(): nil
---@param state? H3ComponentTest.MagicState
---@return openmw.ui.Layout
local function magicMenu(invalidate, rebuild, state)
  rebuild = rebuild or
    ---@return nil
    function() end
  state = state or {}
  state.query = state.query or ''
  state.deleted = state.deleted or {}

  local shellUi = I.H3UI.scope { invalidate = invalidate }

  local listElement
  local listUi = shellUi.child {
    ---@return openmw.ui.Element?
    element = function() return listElement end,
  }

  local spellBox
  local titleText
  local selectSpell
  local selectedLayouts = {}
  local activation = {
    targets = SetMetatable({}, WeakKeys),
  }
  activation.callback = async:callback(
    ---@param event openmw.ui.MouseEvent
    ---@param layout openmw.ui.Layout
    ---@return boolean
    function(event, layout)
    local item = activation.targets[layout]
    if not item then return true end
    selectSpell(item.name, layout)
    return true
  end)

  ---@return openmw.ui.Layout
  local function buildListBody()
    local listChildren = {}

    local visiblePowers = filtered(Powers, state)
    if Next(visiblePowers) then
      listChildren[#listChildren + 1] =
        section(listUi, activation, state, 'Powers', nil, visiblePowers, selectedLayouts)
    end
    local visibleSpells = filtered(Spells, state)
    if Next(visibleSpells) then
      listChildren[#listChildren + 1] =
        section(listUi, activation, state, 'Spells', 'Cost/Chance', visibleSpells, selectedLayouts)
    end
    local visibleItems = filtered(EnchantedItems, state)
    if Next(visibleItems) then
      listChildren[#listChildren + 1] =
        section(listUi, activation, state, 'Magic Items', 'Charge', visibleItems, selectedLayouts)
    end

    if not Next(listChildren) then
      listChildren[1] = listUi.text {
        text = 'No spells or magic items match this filter.',
        tone = 'muted',
      }
    end

    return listUi.column {
      gap = 4,
      props = { autoSize = false, relativeSize = FullSize },
      children = listChildren,
    }
  end

  ---@return nil
  local function updateTitle()
    if titleText then titleText.props.text = state.selected or 'None' end
  end

  ---@return nil
  local function refreshShell()
    if shellUi.invalidate then shellUi.invalidate() end
  end

  ---@param name string
  ---@param layout openmw.ui.Layout
  ---@return nil
  function selectSpell(name, layout)
    local previous = selectedLayouts[state.selected]
    if previous and previous ~= layout then listUi.setSelected(previous, false) end
    state.selected = name
    selectedLayouts[name] = layout
    listUi.setSelected(layout, true)
    updateTitle()
    refreshShell()
  end

  ---@return nil
  local function refilter()
    selectedLayouts = {}
    listUi.setChildren(spellBox, { buildListBody() })
  end

  local effectIcons = { shellUi.spacer(4, 0) }
  for index = 1, #EffectColors do
    effectIcons[#effectIcons + 1] = effectIcon(shellUi, index)
  end

  spellBox = listUi.box {
    props = { size = SpellListSize },
    children = { buildListBody() },
  }
  listElement = openmwUi.create(spellBox)

  local windowLayout = shellUi.window {
    name = 'ct_demo_magic_menu',
    title = state.selected or 'None',
    size = MenuSize,
    movable = true,
    resizable = false,
    closable = false,
    pinnable = true,
    children = {
      shellUi.column {
        gap = 6,
        shellUi.box {
          props = { size = EffectStripSize },
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
            inputProps = { size = FilterSize },
            ---@param value string
            ---@return nil
            onChange = function(value)
              state.query = value
              refilter()
            end,
          },

          shellUi.spacer(8, 0),
          shellUi.button {
            label = 'Delete',
            tone = 'negative',
            ---@return boolean
            onActivate = function()
              if not state.selected then return true end
              state.deleted[state.selected] = true
              state.selected = nil
              selectedLayouts = {}
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
  Assert(titleText, 'H3 magic menu fixture requires a caption text layout')

  return windowLayout
end

return magicMenu
