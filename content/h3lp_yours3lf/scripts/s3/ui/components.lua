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
    builder = require 'scripts.s3.components.bookFrame',
    slots = { root = root(), title = { props = 'titleProps' } },
  },
  box = {
    builder = require 'scripts.s3.components.box',
    slots = { root = root() },
  },
  button = {
    builder = require 'scripts.s3.components.button',
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
    builder = require 'scripts.s3.components.collapsible',
    slots = {
      root = root(false),
      header = { props = 'headerProps' },
      headerLabel = { props = 'headerLabelProps' },
    },
  },
  column = {
    builder = require 'scripts.s3.components.column',
    slots = { root = root() },
  },
  container = {
    builder = require 'scripts.s3.components.container',
    slots = { root = root() },
  },
  dialog = {
    builder = require 'scripts.s3.components.dialog',
    slots = { root = root(), title = { props = 'titleProps' } },
  },
  grid = {
    builder = require 'scripts.s3.components.grid',
    slots = { root = root(), row = { props = 'rowProps' } },
  },
  headBlock = {
    builder = require 'scripts.s3.components.headBlock',
    slots = { root = root(false) },
  },
  iconButton = {
    builder = require 'scripts.s3.components.iconButton',
    slots = {
      root = root(),
      icon = { props = 'iconProps' },
      label = { props = 'labelProps' },
    },
  },
  image = {
    builder = require 'scripts.s3.components.image',
    slots = { root = root() },
  },
  itemSlot = {
    builder = require 'scripts.s3.components.itemSlot',
    slots = {
      root = root(),
      icon = { props = 'iconProps' },
      count = { props = 'countProps' },
    },
  },
  list = {
    builder = require 'scripts.s3.components.list',
    slots = { root = root() },
  },
  listItem = {
    builder = require 'scripts.s3.components.listItem',
    slots = { root = root(), label = { props = 'labelProps' } },
  },
  meter = {
    builder = require 'scripts.s3.components.meter',
    slots = {
      root = root(),
      fill = { props = 'fillProps' },
      empty = { props = 'emptyProps' },
    },
  },
  numberInput = {
    builder = require 'scripts.s3.components.numberInput',
    slots = { root = root() },
  },
  pinButton = {
    builder = require 'scripts.s3.components.pinButton',
    slots = { root = root(false) },
  },
  row = {
    builder = require 'scripts.s3.components.row',
    slots = { root = root() },
  },
  searchInput = {
    builder = require 'scripts.s3.components.searchInput',
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
    builder = require 'scripts.s3.components.selector',
    slots = {
      root = root(false),
      button = { props = 'buttonProps' },
      icon = { props = 'iconProps' },
      label = { props = 'labelProps', template = 'labelTemplate' },
    },
  },
  slider = {
    builder = require 'scripts.s3.components.slider',
    slots = {
      root = root(),
      fill = { props = 'fillProps' },
      empty = { props = 'emptyProps' },
    },
  },
  spacer = {
    builder = require 'scripts.s3.components.spacer',
    slots = { root = root() },
  },
  tabs = {
    builder = require 'scripts.s3.components.tabs',
    slots = {
      root = root(false),
      button = { props = 'buttonProps' },
      selected = { props = 'selectedProps' },
      label = { props = 'labelProps' },
      selectedLabel = { props = 'selectedLabelProps' },
    },
  },
  text = {
    builder = require 'scripts.s3.components.text',
    slots = { root = root() },
  },
  textInput = {
    builder = require 'scripts.s3.components.textInput',
    slots = { root = root() },
  },
  toggle = {
    builder = require 'scripts.s3.components.toggle',
    slots = { root = root(), label = { props = 'labelProps' } },
  },
  tooltip = {
    builder = require 'scripts.s3.components.tooltip',
    slots = { root = root(), text = { props = 'textProps' } },
  },
  widget = {
    builder = require 'scripts.s3.components.widget',
    slots = { root = root() },
  },
  window = {
    builder = require 'scripts.s3.components.window',
    slots = { root = root(), caption = { props = 'captionProps' } },
  },
}
