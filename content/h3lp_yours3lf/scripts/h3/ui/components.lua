---@omw-context menu|player

local bookFrame = require 'scripts.h3.components.bookFrame'
local box = require 'scripts.h3.components.box'
local button = require 'scripts.h3.components.button'
local caption = require 'scripts.h3.components.caption'
local collapsible = require 'scripts.h3.components.collapsible'
local column = require 'scripts.h3.components.column'
local container = require 'scripts.h3.components.container'
local divider = require 'scripts.h3.components.divider'
local grid = require 'scripts.h3.components.grid'
local headBlock = require 'scripts.h3.components.headBlock'
local iconButton = require 'scripts.h3.components.iconButton'
local image = require 'scripts.h3.components.image'
local itemSlot = require 'scripts.h3.components.itemSlot'
local list = require 'scripts.h3.components.list'
local listItem = require 'scripts.h3.components.listItem'
local meter = require 'scripts.h3.components.meter'
local numberInput = require 'scripts.h3.components.numberInput'
local pinButton = require 'scripts.h3.components.pinButton'
local row = require 'scripts.h3.components.row'
local searchInput = require 'scripts.h3.components.searchInput'
local selector = require 'scripts.h3.components.selector'
local slider = require 'scripts.h3.components.slider'
local spacer = require 'scripts.h3.components.spacer'
local tabs = require 'scripts.h3.components.tabs'
local text = require 'scripts.h3.components.text'
local textInput = require 'scripts.h3.components.textInput'
local toggle = require 'scripts.h3.components.toggle'
local tooltip = require 'scripts.h3.components.tooltip'
local widget = require 'scripts.h3.components.widget'
local window = require 'scripts.h3.components.window'

---@param template? boolean
---@return H3UI.ComponentSlot
local function root(template)
  local slot = {
    props = 'props',
    external = 'external',
  }

  if template ~= false then slot.template = 'template' end

  return slot
end

return {
  bookFrame = {
    isPublic = true,
    builder = bookFrame,
    slots = {
      root = root(),
      title = { props = 'titleProps' },
      background = { props = 'backgroundProps' },
    },
  },

  box = {
    isPublic = true,
    builder = box,
    slots = { root = root() },
  },

  button = {
    isPublic = true,
    builder = button,
    runtimeState = true,
    slots = { root = root(), label = { props = 'labelProps' } },
  },

  caption = {
    builder = caption,
    slots = {
      root = root(false),
      text = { props = 'textProps' },
      pin = { props = 'pinProps' },
      close = { props = 'closeProps' },
    },
  },

  collapsible = {
    isPublic = true,
    builder = collapsible,
    invalidateOn = 'onToggle',
    slots = {
      root = root(false),
      header = { props = 'headerProps' },
      headerLabel = { props = 'headerLabelProps' },
    },
  },

  column = {
    isPublic = true,
    builder = column,
    slots = { root = root() },
  },

  divider = {
    isPublic = true,
    builder = divider,
    slots = { root = root() },
  },

  container = {
    builder = container,
    slots = { root = root() },
  },

  grid = {
    isPublic = true,
    builder = grid,
    slots = { root = root(), row = { props = 'rowProps' } },
  },

  headBlock = {
    builder = headBlock,
    slots = { root = root(false) },
  },

  iconButton = {
    isPublic = true,
    builder = iconButton,
    runtimeState = true,
    selectable = true,
    slots = {
      root = root(),
      icon = { props = 'iconProps' },
      label = { props = 'labelProps' },
      selectedChrome = { props = 'selectionProps', retained = true },
    },
  },

  image = {
    isPublic = true,
    builder = image,
    slots = { root = root() },
  },

  itemSlot = {
    isPublic = true,
    builder = itemSlot,
    selectable = true,
    slots = {
      root = root(),
      icon = { props = 'iconProps' },
      count = { props = 'countProps' },
      selectedChrome = { props = 'selectionProps', retained = true },
    },
  },

  list = {
    isPublic = true,
    builder = list,
    slots = { root = root() },
  },

  listItem = {
    isPublic = true,
    builder = listItem,
    runtimeState = true,
    selectable = true,
    slots = {
      root = root(),
      label = { props = 'labelProps' },
      secondary = { props = 'secondaryProps' },
    },
  },

  meter = {
    isPublic = true,
    builder = meter,
    slots = {
      root = root(),
      fill = { props = 'fillProps' },
      empty = { props = 'emptyProps' },
    },
  },

  numberInput = {
    isPublic = true,
    builder = numberInput,
    invalidateOn = 'onCommit',
    slots = { root = root() },
  },

  pinButton = {
    builder = pinButton,
    slots = { root = root(false) },
  },

  row = {
    isPublic = true,
    builder = row,
    slots = { root = root() },
  },

  searchInput = {
    isPublic = true,
    builder = searchInput,
    invalidateOn = 'onCommit',
    slots = {
      root = root(false),
      input = {
        props = 'inputProps',
        external = 'inputExternal',
        template = 'template',
      },
    },
  },

  selector = {
    isPublic = true,
    builder = selector,
    invalidateOn = 'onSelect',
    slots = {
      root = root(false),
      button = { props = 'buttonProps' },
      icon = { props = 'iconProps' },
      label = { props = 'labelProps', template = 'labelTemplate' },
    },
  },

  slider = {
    isPublic = true,
    builder = slider,
    invalidateOn = 'onChange',
    slots = {
      root = root(),
      fill = { props = 'fillProps' },
      empty = { props = 'emptyProps' },
    },
  },

  spacer = {
    isPublic = true,
    builder = spacer,
    slots = { root = root() },
  },

  tabs = {
    isPublic = true,
    builder = tabs,
    invalidateOn = 'onSelect',
    slots = {
      root = root(false),
      button = { props = 'buttonProps' },
      selected = { props = 'selectedProps' },
      label = { props = 'labelProps' },
      selectedLabel = { props = 'selectedLabelProps' },
    },
  },

  text = {
    isPublic = true,
    builder = text,
    slots = { root = root() },
  },

  textInput = {
    isPublic = true,
    builder = textInput,
    slots = { root = root() },
  },

  toggle = {
    isPublic = true,
    builder = toggle,
    runtimeState = true,
    invalidateOn = 'onChange',
    slots = { root = root(), label = { props = 'labelProps' } },
  },

  tooltip = {
    isPublic = true,
    builder = tooltip,
    slots = { root = root(), text = { props = 'textProps' } },
  },

  widget = {
    builder = widget,
    slots = { root = root() },
  },

  window = {
    isPublic = true,
    builder = window,
    invalidateOn = { 'onMove', 'onResize', 'onPin' },
    slots = {
      root = root(),
      background = { props = 'backgroundProps' },
      caption = { props = 'captionProps' },
      captionText = { props = 'captionTextProps' },
    },
  },
}
