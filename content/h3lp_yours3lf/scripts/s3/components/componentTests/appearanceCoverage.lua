---@omw-context player
---@module 'scripts.s3.components.componentTests.appearanceCoverage'

local util = require 'openmw.util'

local appearance = require 'scripts.s3.ui.appearance'
local bookFrame = require 'scripts.s3.components.bookFrame'
local box = require 'scripts.s3.components.box'
local button = require 'scripts.s3.components.button'
local chrome = require 'scripts.s3.ui.chrome'
local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local headBlock = require 'scripts.s3.components.headBlock'
local iconButton = require 'scripts.s3.components.iconButton'
local itemSlot = require 'scripts.s3.components.itemSlot'
local listItem = require 'scripts.s3.components.listItem'
local meter = require 'scripts.s3.components.meter'
local pinButton = require 'scripts.s3.components.pinButton'
local row = require 'scripts.s3.components.row'
local searchInput = require 'scripts.s3.components.searchInput'
local selector = require 'scripts.s3.components.selector'
local spacer = require 'scripts.s3.components.spacer'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local textInput = require 'scripts.s3.components.textInput'
local toggle = require 'scripts.s3.components.toggle'
local tooltip = require 'scripts.s3.components.tooltip'
local window = require 'scripts.s3.components.window'

local UtilVector2 = util.vector2
local lime = util.color.rgb(0, 1, 0)
local magenta = util.color.rgb(1, 0, 1)

local entryGap = UtilVector2(0, 4)
local columnGap = UtilVector2(12, 0)
local controlSize = UtilVector2(180, 24)
local frameSize = UtilVector2(180, 54)
local headBlockSize = UtilVector2(180, 20)
local itemSize = UtilVector2(48, 48)
local toggleValue = true

local function labelProps(color)
  return { textColor = color, textSize = appearance.token 'textSize.normal' }
end

local function entry(name, role, component)
  return column {
    children = {
      text {
        text = name .. ' [' .. role .. ']',
        props = labelProps(magenta),
      },
      spacer { props = { size = entryGap } },
      component,
      spacer { props = { size = entryGap } },
    },
  }
end

local function coverage(invalidate)
  local refresh = invalidate or function() end

  return column {
    name = 'ct_demo_appearance_coverage',
    children = {
      text {
        text = 'Appearance coverage: use a loud custom palette and chrome color; legacy gold should be obvious.',
        props = labelProps(magenta),
      },
      spacer { props = { size = UtilVector2(0, 8) } },
      row {
        children = {
          entry('text', 'none', text { text = 'default text' }),
          spacer { props = { size = columnGap } },
          entry('button', 'frame.button', button { label = 'default button' }),
          spacer { props = { size = columnGap } },
          entry(
            'iconButton',
            'frame.button',
            iconButton {
              resource = chrome.texture(appearance.chrome 'scroll.left'),
              iconProps = { size = UtilVector2(16, 16) },
              label = 'icon',
            }
          ),
        },
      },
      row {
        children = {
          entry(
            'itemSlot',
            'frame.thin',
            itemSlot {
              resource = { path = 'white' },
              count = 7,
              props = { size = itemSize },
              iconProps = { size = UtilVector2(40, 40) },
            }
          ),
          spacer { props = { size = columnGap } },
          entry('listItem', 'padding', listItem { label = 'default list item' }),
          spacer { props = { size = columnGap } },
          entry(
            'toggle',
            'frame.button',
            toggle {
              value = toggleValue,
              onChange = function(value)
                toggleValue = value
                refresh()
              end,
            }
          ),
        },
      },
      row {
        children = {
          entry(
            'selector',
            'frame.button',
            selector {
              items = { 'One', 'Two' },
              labelProps = { size = UtilVector2(72, 20) },
              onSelect = refresh,
            }
          ),
          spacer { props = { size = columnGap } },
          entry(
            'tabs',
            'frame.button',
            tabs {
              items = { 'A', 'B' },
              onSelect = refresh,
            }
          ),
          spacer { props = { size = columnGap } },
          entry(
            'collapsible',
            'frame.button',
            collapsible {
              title = 'Details',
              children = { text { text = 'default details' } },
              onToggle = refresh,
            }
          ),
        },
      },
      row {
        children = {
          entry('searchInput', 'frame.thin', searchInput { props = { size = controlSize } }),
          spacer { props = { size = columnGap } },
          entry(
            'textInput',
            'H3 TextEdit',
            textInput { text = 'editable text', props = { size = controlSize } }
          ),
          spacer { props = { size = columnGap } },
          entry(
            'meter',
            'frame.thin',
            meter {
              value = 65,
              max = 100,
              props = { size = controlSize },
            }
          ),
        },
      },
      row {
        children = {
          entry('tooltip', 'frame.thin + H3 padding', tooltip { text = 'bright tooltip' }),
          spacer { props = { size = columnGap } },
          entry(
            'meter (unsized)',
            'frame.thin, no size',
            meter {
              value = 65,
              max = 100,
            }
          ),
        },
      },
      row {
        children = {
          entry(
            'box',
            'frame.thin',
            box {
              props = { size = frameSize },
              children = { text { text = 'default box' } },
            }
          ),
          spacer { props = { size = columnGap } },
          entry(
            'bookFrame',
            'frame.thin',
            bookFrame {
              title = 'Book frame',
              children = { text { text = 'default book' } },
            }
          ),
        },
      },
      row {
        children = {
          entry(
            'window',
            'frame.thick + caption',
            window {
              title = 'Window',
              props = { size = frameSize },
              children = { text { text = 'default window' } },
            }
          ),
          spacer { props = { size = columnGap } },
          entry('headBlock', 'caption', headBlock { props = { size = headBlockSize } }),
          spacer { props = { size = columnGap } },
          entry('pinButton', 'pin.up/down', pinButton {}),
        },
      },
      spacer { props = { size = UtilVector2(0, 8) } },
      text {
        text = 'Expected: control text follows the active H3UI palette, and every H3-owned frame follows the chosen chrome color.',
        props = labelProps(lime),
      },
    },
  }
end

return coverage
