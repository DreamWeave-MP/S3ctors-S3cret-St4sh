---@omw-context none

local StrFormat = string.format

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_parity_reconstructions%.lua$' or '.'

package.path = StrFormat('%s/content/h3lp_yours3lf/?.lua;%s', root, package.path)

local Gmst = {
  sBack = 'Back',
  sClassChoiceMenu1 = 'Answer questions',
  sClassChoiceMenu2 = 'Pick a class',
  sClassChoiceMenu3 = 'Create a class',
  sName = 'Name',
  sNext = 'Next',
  sRestMenu2 = 'hours',
  sRestMenu3 = 'Rest',
  sTake = 'Take',
}

local L10n = {
  Calendar = { am = 'a.m.', day = 'Day', month3 = 'First Seed', pm = 'p.m.' },
  Interface = { Cancel = 'Cancel', No = 'No', OK = 'OK', Yes = 'Yes' },
  OMWEngine = { QuitGameConfirmation = 'Quit the game?' },
}

package.preload['openmw.core'] = function()
  return {
    getGameTime = function() return (16 * 24 + 14) * 3600 end,
    getGMST = function(name) return Gmst[name] end,
    l10n = function(context)
      return function(key) return L10n[context][key] end
    end,
  }
end
package.preload['openmw.self'] = function() return { object = 'player' } end
package.preload['openmw.types'] = function()
  return {
    Ingredient = {
      record = function(id)
        assert(id == 'ingred_ash_yam_01')
        return { name = 'Ash Yam' }
      end,
    },
    NPC = {
      record = function(object)
        assert(object == 'player')
        return { name = 'Nerevar' }
      end,
    },
  }
end
package.preload['openmw_aux.calendar'] = function()
  return {
    formatGameTime = function(format, time)
      assert(format == '*t')
      assert(time == (16 * 24 + 14) * 3600)
      return { day = 17, hour = 14, month = 3 }
    end,
  }
end
package.preload['openmw.async'] = function()
  return { callback = function(_, callback) return callback end }
end
package.preload['openmw.interfaces'] = function() return {} end
package.preload['openmw.ui'] = function()
  local function content(value)
    return setmetatable({}, {
      __index = function(_, key) return value[key] end,
      __len = function() return #value end,
    })
  end

  local modal = { size = { x = 1280, y = 720 } }
  return {
    ALIGNMENT = { Center = 'Center', End = 'End', Start = 'Start' },
    TYPE = {
      Container = 'Container',
      Flex = 'Flex',
      Image = 'Image',
      Text = 'Text',
      TextEdit = 'TextEdit',
      Widget = 'Widget',
    },
    content = content,
    layers = setmetatable({ modal }, {
      __index = { indexOf = function(name) return name == 'Modal' and 1 or nil end },
    }),
    screenSize = function() return { x = 1280, y = 720 } end,
    texture = function(value) return value end,
  }
end
package.preload['openmw.util'] = function()
  return {
    clamp = function(value, minimum, maximum) return math.max(minimum, math.min(value, maximum)) end,
    color = {
      rgb = function(red, green, blue) return { red, green, blue } end,
      rgba = function(red, green, blue, alpha) return { red, green, blue, alpha } end,
    },
    vector2 = function(x, y) return { x = x, y = y } end,
    vector4 = function(x, y, z, w) return { x = x, y = y, z = z, w = w } end,
  }
end
package.preload['scripts.omw.mwui.constants'] = function()
  return { padding = 2, border = 2, thickBorder = 4, whiteTexture = { path = 'white' } }
end
package.preload['scripts.h3.ui.appearance'] = function()
  local chrome = require 'scripts.h3.ui.chrome'
  local tokens = {
    ['border.normal'] = 2,
    ['color.background'] = 'background',
    ['color.chromeBorder'] = 'chrome-border',
    ['color.text'] = 'text-color',
    ['spacing.padding'] = 2,
    ['textSize.normal'] = 16,
    ['texture.white'] = 'white',
    ['transparency.chrome'] = 0.75,
    ['transparency.menu'] = 0.84,
  }
  return {
    chrome = function(path) return chrome.resolve(nil, path) end,
    token = function(path) return tokens[path] end,
  }
end

-- Numbers no vanilla layout has, so a reconstruction that follows them read them from here.
local SyntheticMetrics = {
  layouts = {
    confirmation_dialog = {
      widgets = {
        {
          layer = 'Modal',
          position = { 0, 0, 330, 120 },
          skin = 'TestDialog',
          type = 'Window',
          widgets = {
            {
              name = 'Message',
              position = { 16, 8, 300, 120 },
              properties = { { 'TextAlign', 'Top HCenter' } },
              type = 'EditBox',
            },
            {
              position = { 0, 80, 330, 30 },
              type = 'VBox',
              widgets = {
                {
                  properties = { { 'Spacing', '11' } },
                  type = 'HBox',
                  widgets = {
                    {
                      name = 'OkButton',
                      properties = { { 'Caption', '#{Interface:Yes}' } },
                      type = 'AutoSizedButton',
                    },
                    {
                      name = 'CancelButton',
                      properties = { { 'Caption', '#{Interface:No}' } },
                      type = 'AutoSizedButton',
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    count_window = {
      widgets = {
        {
          layer = 'Modal',
          position = { 0, 0, 500, 130 },
          skin = 'TestDialog',
          type = 'Window',
          widgets = {
            {
              align = 'Left Top HStretch',
              name = 'LabelText',
              position = { 0, 3, 490, 20 },
              type = 'TextBox',
            },
            {
              align = 'Right Top',
              name = 'ItemEdit',
              position = { 400, 30, 70, 20 },
              type = 'NumericEditBox',
            },
            { align = 'Top', name = 'Centred', position = { 10, 60, 50, 10 }, type = 'TextBox' },
            {
              align = 'Left Top HStretch',
              name = 'CountSlider',
              position = { 7, 90, 470, 18 },
              type = 'ScrollBar',
            },
          },
        },
      },
    },
    infobox = { widgets = { { layer = 'Modal', skin = 'TestDialog', type = 'Window' } } },
    interactive_messagebox = {
      widgets = { { layer = 'Modal', skin = 'TestDialog', type = 'Window' } },
    },
    messagebox = {
      widgets = {
        {
          layer = 'Notification',
          properties = { { 'Padding', '13' } },
          skin = 'HUD_Box',
          type = 'VBox',
          widgets = {
            {
              position = { 0, 0, 250, 0 },
              properties = { { 'TextAlign', 'Center' } },
              type = 'AutoSizedEditBox',
            },
          },
        },
      },
    },
    text_input = {
      widgets = {
        {
          layer = 'Modal',
          position = { 0, 0, 310, 90 },
          skin = 'TestDialog',
          type = 'Window',
          widgets = {
            { name = 'LabelT', position = { 5, 7, 290, 17 }, type = 'TextBox' },
            { name = 'TextEdit', position = { 5, 27, 290, 29 }, type = 'EditBox' },
            { name = 'OKButton', position = { 250, 59, 40, 22 }, type = 'AutoSizedButton' },
          },
        },
      },
    },
    wait_dialog = {
      widgets = {
        {
          layer = 'Windows',
          properties = { { 'Padding', '9' }, { 'Spacing', '5' } },
          skin = 'TestDialog',
          type = 'VBox',
          widgets = {
            { name = 'DateTimeText', type = 'AutoSizedTextBox' },
            { name = 'HourSlider', position = { 0, 0, 450, 18 }, type = 'ScrollBar' },
          },
        },
      },
    },
  },
  skins = {
    TestDialog = {
      children = { { name = 'Client', offset = { 5, 3, 240, 48 } } },
      size = { 250, 54 },
    },
  },
}

local function load(metrics)
  package.loaded['scripts.h3.parity.reconstructions'] = nil
  package.loaded['scripts.h3.parity.vanillaMetrics'] = nil
  package.preload['scripts.h3.parity.vanillaMetrics'] = metrics and function() return metrics end
    or nil
  return require 'scripts.h3.parity.reconstructions'
end

local function each(layout, visit)
  visit(layout)

  local template = layout.template
  local sources = { layout.content, template and template.content }
  for source = 1, 2 do
    local content = sources[source]
    if content then
      for index = 1, #content do
        each(content[index], visit)
      end
    end
  end
end

local function texts(layout)
  local found = {}
  each(layout, function(node)
    if node.type == 'Text' or node.type == 'TextEdit' then found[#found + 1] = node.props.text end
  end)
  return table.concat(found, '|')
end

local function nodeWithText(layout, wanted)
  local found
  each(layout, function(node)
    if node.props and node.props.text == wanted then found = node end
  end)
  return assert(found, wanted)
end

local function nodeWhere(layout, test)
  local found
  each(layout, function(node)
    if not found and test(node) then found = node end
  end)
  return found
end

local function same(vector, x, y) return vector and vector.x == x and vector.y == y end

local Entry = {
  messagebox = { layout = 'messagebox', opens = { text = 'A fixed message.' } },
  interactive_messagebox = { layout = 'interactive_messagebox', opens = { text = 'Asked.' } },
}

local function testSevenReconstructions()
  local reconstructions = load(SyntheticMetrics)
  local names = {}
  for name in next, reconstructions do
    names[#names + 1] = name
  end
  table.sort(names)

  assert(
    table.concat(names, ',')
      == 'confirmation_dialog,count_window,infobox,interactive_messagebox,messagebox,text_input,wait_dialog'
  )
end

local function testCountWindowFollowsTheMetrics()
  local layout = load(SyntheticMetrics).count_window()

  -- 320 wide (CountDialog's minimum for a short name), the declared 130 tall, centred in the
  -- 1280x720 layer by integer division.
  assert(same(layout.props.size, 320, 130))
  assert(same(layout.props.position, 480, 295))
  assert(layout.layer == 'Modal')
  assert(texts(layout) == 'Take|5|')

  -- The client area was declared 250 - (250 - 240) = 490 wide: HStretch keeps the child's 0 margin
  -- by stretching with its parent, Right keeps its distance to the far edge, and Top alone centres.
  local label = nodeWithText(layout, 'Take')
  assert(same(label.props.size, 0, 20) and same(label.props.relativeSize, 1, 0))
  assert(same(label.props.position, 0, 3))

  local edit = nodeWithText(layout, '5')
  assert(same(edit.props.relativePosition, 1, 0) and same(edit.props.position, 400 - 490, 30))

  local centred = nodeWithText(layout, '')
  assert(same(centred.props.relativePosition, 0.5, 0) and same(centred.props.anchor, 0.5, 0))
end

local function testTextInputKeepsItsDeclaredGeometry()
  local layout = load(SyntheticMetrics).text_input()

  assert(same(layout.props.size, 310, 90))
  assert(same(layout.props.position, 485, 315))
  assert(texts(layout) == 'Name|Nerevar|Next')

  local label = nodeWithText(layout, 'Name')
  assert(same(label.props.position, 5, 7) and same(label.props.size, 290, 17))
end

local function testMessageBoxFollowsTheMetrics()
  local layout = load(SyntheticMetrics).messagebox(Entry.messagebox)
  assert(layout.layer == 'Notification')
  assert(same(layout.props.relativePosition, 0.5, 1) and same(layout.props.anchor, 0.5, 1))
  assert(same(layout.props.position, 0, -48))

  local message = nodeWithText(layout, 'A fixed message.')
  assert(same(message.props.size, 250, 0) and message.props.textAlignH == 'Center')

  local padded = nodeWhere(
    layout,
    function(node) return node.props and same(node.props.size, -26, -26) end
  )
  assert(padded, 'the surface is not padded by the layout Padding of 13')
end

local function testDialogsUseTheirTexts()
  local reconstructions = load(SyntheticMetrics)

  local confirmation = reconstructions.confirmation_dialog()
  assert(texts(confirmation) == 'Quit the game?|Yes|No', texts(confirmation))
  local padding = (24 - (250 - 240)) / 2
  assert(
    nodeWhere(
      confirmation,
      function(node) return node.props and same(node.props.size, -2 * padding, -2 * padding) end
    )
  )

  local interactive = reconstructions.interactive_messagebox(Entry.interactive_messagebox)
  assert(texts(interactive) == 'Asked.|OK')

  local info = reconstructions.infobox()
  assert(texts(info) == 'Answer questions|Pick a class|Create a class|Back')

  local wait = reconstructions.wait_dialog()
  assert(texts(wait) == '17 First Seed (Day 16) 2 p.m.', texts(wait))
  assert(nodeWhere(wait, function(node) return node.props and same(node.props.size, -18, -18) end))
end

local function testRealMetricsBuildEveryReconstruction()
  local reconstructions = load(nil)
  local metrics = require 'scripts.h3.parity.vanillaMetrics'

  local textInput = reconstructions.text_input()
  local declared = metrics.layouts.text_input.widgets[1].position
  assert(same(textInput.props.size, declared[3], declared[4]))
  assert(texts(textInput) == 'Name|Nerevar|Next')

  assert(
    texts(reconstructions.count_window()) == 'Take|Ash Yam|5|OK|Cancel',
    texts(reconstructions.count_window())
  )
  reconstructions.confirmation_dialog()
  reconstructions.infobox()
  reconstructions.interactive_messagebox(Entry.interactive_messagebox)
  reconstructions.messagebox(Entry.messagebox)
  reconstructions.wait_dialog()
end

testSevenReconstructions()
testCountWindowFollowsTheMetrics()
testTextInputKeepsItsDeclaredGeometry()
testMessageBoxFollowsTheMetrics()
testDialogsUseTheirTexts()
testRealMetricsBuildEveryReconstruction()

print 'H3UI parity reconstruction tests passed'
