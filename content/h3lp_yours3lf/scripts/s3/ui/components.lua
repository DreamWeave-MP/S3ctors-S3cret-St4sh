---@omw-context menu|player

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
    public = true,
    builder = require 'scripts.s3.components.bookFrame',
    slots = {
      root = root(),
      title = { props = 'titleProps' },
      background = { props = 'backgroundProps' },
    },
  },
  box = {
    public = true,
    builder = require 'scripts.s3.components.box',
    slots = { root = root() },
  },
  button = {
    public = true,
    builder = require 'scripts.s3.components.button',
    runtimeState = true,
    slots = { root = root(), label = { props = 'labelProps' } },
  },
  caption = {
    builder = require 'scripts.s3.components.caption',
    slots = {
      root = root(false),
      text = { props = 'textProps' },
      pin = { props = 'pinProps' },
      close = { props = 'closeProps' },
    },
  },
  collapsible = {
    public = true,
    builder = require 'scripts.s3.components.collapsible',
    invalidateOn = 'onToggle',
    slots = {
      root = root(false),
      header = { props = 'headerProps' },
      headerLabel = { props = 'headerLabelProps' },
    },
  },
  column = {
    public = true,
    builder = require 'scripts.s3.components.column',
    slots = { root = root() },
  },
  divider = {
    public = true,
    builder = require 'scripts.s3.components.divider',
    slots = { root = root() },
  },
  container = {
    builder = require 'scripts.s3.components.container',
    slots = { root = root() },
  },
  grid = {
    public = true,
    builder = require 'scripts.s3.components.grid',
    slots = { root = root(), row = { props = 'rowProps' } },
  },
  headBlock = {
    builder = require 'scripts.s3.components.headBlock',
    slots = { root = root(false) },
  },
  iconButton = {
    public = true,
    builder = require 'scripts.s3.components.iconButton',
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
    public = true,
    builder = require 'scripts.s3.components.image',
    slots = { root = root() },
  },
  itemSlot = {
    public = true,
    builder = require 'scripts.s3.components.itemSlot',
    selectable = true,
    slots = {
      root = root(),
      icon = { props = 'iconProps' },
      count = { props = 'countProps' },
      selectedChrome = { props = 'selectionProps', retained = true },
    },
  },
  list = {
    public = true,
    builder = require 'scripts.s3.components.list',
    slots = { root = root() },
  },
  listItem = {
    public = true,
    builder = require 'scripts.s3.components.listItem',
    runtimeState = true,
    selectable = true,
    slots = {
      root = root(),
      label = { props = 'labelProps' },
      secondary = { props = 'secondaryProps' },
    },
  },
  meter = {
    public = true,
    builder = require 'scripts.s3.components.meter',
    slots = {
      root = root(),
      fill = { props = 'fillProps' },
      empty = { props = 'emptyProps' },
    },
  },
  numberInput = {
    public = true,
    builder = require 'scripts.s3.components.numberInput',
    invalidateOn = 'onCommit',
    slots = { root = root() },
  },
  pinButton = {
    builder = require 'scripts.s3.components.pinButton',
    slots = { root = root(false) },
  },
  row = {
    public = true,
    builder = require 'scripts.s3.components.row',
    slots = { root = root() },
  },
  searchInput = {
    public = true,
    builder = require 'scripts.s3.components.searchInput',
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
    public = true,
    builder = require 'scripts.s3.components.selector',
    invalidateOn = 'onSelect',
    slots = {
      root = root(false),
      button = { props = 'buttonProps' },
      icon = { props = 'iconProps' },
      label = { props = 'labelProps', template = 'labelTemplate' },
    },
  },
  slider = {
    public = true,
    builder = require 'scripts.s3.components.slider',
    invalidateOn = 'onChange',
    slots = {
      root = root(),
      fill = { props = 'fillProps' },
      empty = { props = 'emptyProps' },
    },
  },
  spacer = {
    public = true,
    builder = require 'scripts.s3.components.spacer',
    slots = { root = root() },
  },
  tabs = {
    public = true,
    builder = require 'scripts.s3.components.tabs',
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
    public = true,
    builder = require 'scripts.s3.components.text',
    slots = { root = root() },
  },
  textInput = {
    public = true,
    builder = require 'scripts.s3.components.textInput',
    slots = { root = root() },
  },
  toggle = {
    public = true,
    builder = require 'scripts.s3.components.toggle',
    runtimeState = true,
    invalidateOn = 'onChange',
    slots = { root = root(), label = { props = 'labelProps' } },
  },
  tooltip = {
    public = true,
    builder = require 'scripts.s3.components.tooltip',
    slots = { root = root(), text = { props = 'textProps' } },
  },
  widget = {
    builder = require 'scripts.s3.components.widget',
    slots = { root = root() },
  },
  window = {
    public = true,
    builder = require 'scripts.s3.components.window',
    invalidateOn = { 'onMove', 'onResize', 'onPin' },
    slots = {
      root = root(),
      background = { props = 'backgroundProps' },
      caption = { props = 'captionProps' },
      captionText = { props = 'captionTextProps' },
    },
  },
}
