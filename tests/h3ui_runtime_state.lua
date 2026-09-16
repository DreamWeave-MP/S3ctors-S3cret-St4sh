local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_runtime_state%.lua$' or '.'

package.path = root .. '/content/h3lp_yours3lf/?.lua;' .. package.path

package.preload['openmw.async'] = function()
  return { callback = function(_, callback) return callback end }
end

package.preload['openmw.interfaces'] = function()
  return {
    MWUI = {
      templates = {
        borders = {},
        box = {},
        interval = {},
        padding = {},
        textNormal = {},
      },
    },
  }
end

package.preload['openmw.ui'] = function()
  local function content(value)
    local proxy = newproxy(true)
    local metatable = getmetatable(proxy)
    metatable.__index = function(_, key)
      if value[key] ~= nil then return value[key] end
      if type(key) == 'string' then
        for index = 1, #value do
          if value[index].name == key then return value[index] end
        end
      end
    end
    metatable.__len = function() return #value end
    return proxy
  end

  return {
    content = content,
    ALIGNMENT = { Center = 'Center' },
    TYPE = {
      Container = 'Container',
      Flex = 'Flex',
      Image = 'Image',
      TextEdit = 'TextEdit',
      Widget = 'Widget',
    },
    texture = function(value) return value end,
  }
end

package.preload['openmw.util'] = function()
  return {
    clamp = function(value, minimum, maximum) return math.max(minimum, math.min(value, maximum)) end,
    color = {
      commaString = function(value) return value end,
      rgb = function(red, green, blue) return { red, green, blue } end,
      rgba = function(red, green, blue, alpha) return { red, green, blue, alpha } end,
    },
    vector2 = function(x, y) return { x = x, y = y } end,
  }
end

package.preload['scripts.omw.mwui.constants'] = function()
  return {
    headerColor = 'header-color',
    normalColor = 'normal-color',
    textHeaderSize = 18,
    textNormalSize = 16,
    padding = 2,
    border = 2,
    thickBorder = 4,
    whiteTexture = { path = 'white' },
  }
end

package.preload['scripts.s3.ui.appearance'] = function()
  local chrome = require 'scripts.s3.ui.chrome'
  return {
    chrome = function(path) return chrome.resolve(nil, path) end,
    token = function(path)
      if path == 'color.chromeBorder' then return 'chrome-border' end
      if path == 'color.text' then return 'text-color' end
      if path == 'textSize.normal' then return 16 end
      if path == 'transparency.chrome' then return 0.75 end
      return nil
    end,
  }
end

local I = require 'openmw.interfaces'
local bookFrame = require 'scripts.s3.components.bookFrame'
local chrome = require 'scripts.s3.ui.chrome'
local itemSlot = require 'scripts.s3.components.itemSlot'
local meter = require 'scripts.s3.components.meter'
local newRegistry = require 'scripts.s3.ui.registry'
local newResolver = require 'scripts.s3.ui.resolver'
local newScope = require 'scripts.s3.ui.scope'
local pinButton = require 'scripts.s3.components.pinButton'
local searchInput = require 'scripts.s3.components.searchInput'
local selector = require 'scripts.s3.components.selector'
local tabs = require 'scripts.s3.components.tabs'
local textInput = require 'scripts.s3.components.textInput'
local textRules = require 'scripts.s3.ui.themes.textRules'
local themeModule = require 'scripts.s3.ui.theme'
local token = require 'scripts.s3.ui.token'
local tooltip = require 'scripts.s3.components.tooltip'
local ui = require 'openmw.ui'
local window = require 'scripts.s3.components.window'

local registry = newRegistry {
  button = {
    builder = require 'scripts.s3.components.button',
    runtimeState = true,
    slots = { root = { props = 'props', external = 'external' }, label = { props = 'labelProps' } },
  },
  selector = {
    builder = function(options)
      return { events = options.events, props = options.props, content = {} }
    end,
    slots = { root = { props = 'props' }, label = { props = 'labelProps' } },
  },
  toggle = {
    builder = require 'scripts.s3.components.toggle',
    runtimeState = true,
    slots = { root = { props = 'props', external = 'external' }, label = { props = 'labelProps' } },
  },
  text = { builder = function() return {} end, slots = { root = { props = 'props' } } },
  dialog = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, title = { props = 'titleProps' } },
  },
  bookFrame = {
    builder = function() return {} end,
    slots = {
      root = { props = 'props' },
      title = { props = 'titleProps' },
      background = { props = 'backgroundProps' },
    },
  },
  caption = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, text = { props = 'textProps' } },
  },
  window = {
    builder = function() return {} end,
    slots = {
      root = { props = 'props' },
      captionText = { props = 'captionTextProps' },
      background = { props = 'backgroundProps' },
    },
  },
  numberInput = { builder = function() return {} end, slots = { root = { props = 'props' } } },
  textInput = { builder = function() return {} end, slots = { root = { props = 'props' } } },
  iconButton = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, label = { props = 'labelProps' } },
  },
  listItem = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, label = { props = 'labelProps' } },
  },
  tabs = {
    builder = function() return {} end,
    slots = {
      root = { props = 'props' },
      label = { props = 'labelProps' },
      selectedLabel = { props = 'selectedLabelProps' },
    },
  },
  collapsible = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, headerLabel = { props = 'headerLabelProps' } },
  },
  itemSlot = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, count = { props = 'countProps' } },
  },
  tooltip = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, text = { props = 'textProps' } },
  },
  searchInput = {
    builder = function() return {} end,
    slots = { root = { props = 'props' }, input = { props = 'inputProps' } },
  },
}

local sharedRules = {
  {
    selector = { component = 'button', slot = 'label' },
    style = { props = { textColor = token.ref 'color.text' } },
  },
  {
    selector = { component = 'toggle', slot = 'label' },
    style = { props = { textColor = token.ref 'color.text' } },
  },
  {
    selector = { component = 'button', slot = 'label', state = 'hover' },
    style = { props = { textColor = token.ref 'color.textHover' } },
  },
  {
    selector = { component = 'button', slot = 'label', state = 'pressed' },
    style = { props = { textColor = token.ref 'color.textPressed' } },
  },
  {
    selector = { component = 'toggle', slot = 'label', state = 'hover' },
    style = { props = { textColor = token.ref 'color.textHover' } },
  },
  {
    selector = { component = 'toggle', slot = 'label', state = 'pressed' },
    style = { props = { textColor = token.ref 'color.textPressed' } },
  },
}

local function makeTheme(name, colors)
  return themeModule.new({
    name = name,
    tokens = { color = colors },
    rules = sharedRules,
  }, registry)
end

local morrowind = makeTheme('morrowind-test', {
  text = 'morrowind-text',
  textHover = 'morrowind-hover',
  textPressed = 'morrowind-pressed',
})
local starwind = makeTheme('starwind-test', {
  text = 'starwind-text',
  textHover = 'starwind-hover',
  textPressed = 'starwind-pressed',
})
local resolver = newResolver(registry, {})

local function build(theme, spec)
  return resolver.build(
    { resolveTheme = function() return theme end, density = nil, recipes = {} },
    spec
  )
end

local function buildWith(theme, spec, recipes)
  return resolver.build(
    { resolveTheme = function() return theme end, density = nil, recipes = recipes or {} },
    spec
  )
end

local function labelProps(layout)
  local result = layout.content[1]
  while result.content do
    result = result.content[1]
  end
  return result.props
end

local function testThemeTokens()
  assert(
    labelProps(build(morrowind, { component = 'button', args = { label = 'Morrowind' } })).textColor
      == 'morrowind-text'
  )
  assert(
    labelProps(build(starwind, { component = 'button', args = { label = 'Starwind' } })).textColor
      == 'starwind-text'
  )

  local starwindSpec = require 'scripts.s3.ui.themes.starwind'
  local canonicalStarwind = themeModule.new(starwindSpec, registry, morrowind)
  local disabled = canonicalStarwind.token 'color.disabled'
  assert(disabled[1] == 77 / 255 and disabled[2] == 156 / 255 and disabled[3] == 221 / 255)
  local weaponFill = canonicalStarwind.token 'color.weaponFill'
  assert(weaponFill[1] == 182 / 255 and weaponFill[2] == 72 / 255 and weaponFill[3] == 31 / 255)

  local canonicalMorrowind = themeModule.new(require 'scripts.s3.ui.themes.morrowind', registry)
  assert(canonicalMorrowind.token 'transparency.menu' == 0.84)
end

local function testTextRuleSlots()
  local rules = textRules()
  for index = 1, #rules do
    local component = rules[index].selector.component
    if component == 'numberInput' or component == 'textInput' then
      assert(rules[index].selector.slot == 'root')
    end
  end
end

local function testBookFrameBackground()
  local background = { color = 'starwind-background', alpha = 0.84 }
  local layout = bookFrame { backgroundProps = background }
  local frameContent = layout.template.content
  assert(layout.template.type == ui.TYPE.Container)
  assert(frameContent[1].props.color == background.color)
  assert(frameContent[1].props.alpha == background.alpha)
  assert(layout.content[1].props.horizontal == false)
  assert(frameContent[2].props.resource.path == 'textures/h3ui/h3ui_chrome.dds')
  assert(frameContent[2].props.resource.offset.x == 0)
  assert(frameContent[2].props.resource.offset.y == 0)
  assert(frameContent[2].props.size.x == 2 and frameContent[2].props.size.y == 2)
  assert(frameContent[4].props.position.x == 0 and frameContent[4].props.position.y == 0)
  assert(frameContent[6].props.position.x == 0 and frameContent[6].props.position.y == 2)
  assert(frameContent[7].props.position.x == 0 and frameContent[7].props.position.y == 0)
  assert(frameContent[8].props.position.x == 2 and frameContent[8].props.position.y == 0)
  assert(frameContent[9].props.position.x == 0 and frameContent[9].props.position.y == 0)
end

local function testBuiltinPinChromePaths()
  assert(chrome.resolve(nil, 'pin.up').path == 'textures/h3ui/h3ui_chrome.dds')
  assert(chrome.resolve(nil, 'pin.up').offset.x == 402)
  assert(chrome.resolve(nil, 'pin.down').path == 'textures/h3ui/h3ui_chrome.dds')
  assert(chrome.resolve(nil, 'pin.down').offset.x == 424)
  assert(chrome.resolve(nil, 'scroll.left').size.x == 8)
  assert(chrome.resolve(nil, 'scroll.left').size.y == 8)
end

local function testWindowInnerBorder()
  local layout = window { title = 'window', size = { x = 400, y = 300 } }
  local innerBorder = layout.content[3]
  local body = layout.content[4]

  assert(innerBorder.name == 'innerBorder')
  assert(innerBorder.props.position.x == 4 and innerBorder.props.position.y == 24)
  assert(innerBorder.props.size.x == -8 and innerBorder.props.size.y == -28)
  assert(body.props.position.x == 8 and body.props.position.y == 28)
  assert(body.props.size.x == -16 and body.props.size.y == -36)

  local outerOnly = window { innerBorder = false }
  assert(outerOnly.content[2].name == 'body')
end

local function testStateMachineAndEventReturns()
  local returnValue = {}
  local mouseReturn = false
  local callbackCalled = false
  local invalidationCount = 0
  local layout = build(morrowind, {
    component = 'button',
    args = {
      label = 'Button',
      events = {
        focusGain = function()
          callbackCalled = true
          return returnValue
        end,
        mousePress = function() return mouseReturn end,
      },
    },
    invalidate = function()
      assert(callbackCalled)
      invalidationCount = invalidationCount + 1
    end,
  })
  assert(type(layout.content) == 'userdata')
  local props = labelProps(layout)
  props.unrelated = 'preserved'
  props.textColor = 'changed-before-focus'

  assert(layout.events.focusGain(nil, layout) == returnValue)
  assert(invalidationCount == 1)
  assert(props.textColor == 'morrowind-hover')
  layout.events.focusGain(nil, layout)
  assert(invalidationCount == 1)
  assert(layout.events.mousePress({ button = 1 }, layout) == mouseReturn)
  assert(invalidationCount == 2)
  assert(props.textColor == 'morrowind-pressed')
  assert(layout.events.mouseRelease({ button = 1 }, layout) == nil)
  assert(invalidationCount == 3)
  assert(props.textColor == 'morrowind-hover')
  layout.events.focusLoss(nil, layout)
  assert(invalidationCount == 4)
  assert(props.textColor == 'changed-before-focus')
  assert(props.unrelated == 'preserved')

  local noResurrection = build(morrowind, { component = 'button', args = { label = 'Button' } })
  local noResurrectionProps = labelProps(noResurrection)
  noResurrection.events.mousePress({ button = 1 }, noResurrection)
  noResurrection.events.focusLoss(nil, noResurrection)
  noResurrection.events.mouseRelease({ button = 1 }, noResurrection)
  assert(noResurrectionProps.textColor == 'morrowind-text')

  local hoverOnly = themeModule.new({
    name = 'hover-only',
    tokens = {
      color = { text = 'normal', textHover = 'hover' },
    },
    rules = {
      sharedRules[1],
      {
        selector = { component = 'button', slot = 'label', state = 'hover' },
        style = { props = { textColor = token.ref 'color.textHover' } },
      },
    },
  }, registry)
  local hoverOnlyLayout =
    build(hoverOnly, { component = 'button', args = { label = 'Hover only' } })
  local hoverOnlyProps = labelProps(hoverOnlyLayout)
  hoverOnlyLayout.events.focusGain(nil, hoverOnlyLayout)
  hoverOnlyLayout.events.mousePress({ button = 1 }, hoverOnlyLayout)
  assert(hoverOnlyProps.textColor == 'hover')
  hoverOnlyLayout.events.mouseRelease({ button = 1 }, hoverOnlyLayout)
  hoverOnlyLayout.events.focusLoss(nil, hoverOnlyLayout)
  assert(hoverOnlyProps.textColor == 'normal')

  local pressedOnly = themeModule.new({
    name = 'pressed-only',
    tokens = {
      color = { text = 'normal', textPressed = 'pressed' },
    },
    rules = {
      sharedRules[1],
      {
        selector = { component = 'button', slot = 'label', state = 'pressed' },
        style = { props = { textColor = token.ref 'color.textPressed' } },
      },
    },
  }, registry)
  local pressedOnlyLayout =
    build(pressedOnly, { component = 'button', args = { label = 'Pressed only' } })
  local pressedOnlyProps = labelProps(pressedOnlyLayout)
  pressedOnlyLayout.events.focusGain(nil, pressedOnlyLayout)
  assert(pressedOnlyProps.textColor == 'normal')
  pressedOnlyLayout.events.mousePress({ button = 1 }, pressedOnlyLayout)
  assert(pressedOnlyProps.textColor == 'pressed')
  pressedOnlyLayout.events.mouseRelease({ button = 1 }, pressedOnlyLayout)
  assert(pressedOnlyProps.textColor == 'normal')

  local recipeLayout = buildWith(morrowind, {
    recipe = 'buttonRecipe',
    invalidate = function() invalidationCount = invalidationCount + 1 end,
  }, {
    buttonRecipe = function(context)
      return context.component('button', { args = { label = 'Recipe button' } })
    end,
  })
  recipeLayout.events.focusGain(nil, recipeLayout)
  assert(invalidationCount == 5)

  local scoped = newScope({
    invalidate = function() invalidationCount = invalidationCount + 1 end,
  }, { resolveTheme = function() return morrowind end, recipes = {}, resolver = resolver })
  local scopeLayout = scoped.build { component = 'button', args = { label = 'Scoped button' } }
  scopeLayout.events.focusGain(nil, scopeLayout)
  assert(invalidationCount == 6)

  local overrideCount = 0
  local overrideLayout = scoped.build {
    component = 'button',
    invalidate = function() overrideCount = overrideCount + 1 end,
    args = { label = 'Override button' },
  }
  overrideLayout.events.focusGain(nil, overrideLayout)
  assert(overrideCount == 1)
  assert(invalidationCount == 6)
end

local function testProtectionAndTraversal()
  local callerOwned = build(morrowind, {
    component = 'button',
    args = { label = 'Button', labelProps = { textColor = 'caller' } },
  })
  assert(labelProps(callerOwned).textColor == 'caller')
  assert(callerOwned.events == nil)

  local inlineOwned = build(morrowind, {
    component = 'button',
    args = { label = 'Button' },
    style = { label = { props = { textColor = 'inline' } } },
  })
  assert(labelProps(inlineOwned).textColor == 'inline')
  assert(inlineOwned.events == nil)

  local customContent = build(morrowind, {
    component = 'button',
    args = { content = { { props = { textColor = 'custom' } } } },
  })
  assert(customContent.events == nil)
  assert(customContent.content[1].props.textColor == 'custom')

  local composite = build(morrowind, { component = 'selector' })
  assert(composite.events == nil)

  local explicitState = build(morrowind, { component = 'button', state = 'disabled' })
  assert(explicitState.events == nil)

  local plain = themeModule.new({ name = 'plain' }, registry)
  local plainLayout = build(plain, { component = 'button', args = { label = 'Plain' } })
  assert(plainLayout.events == nil)
end

local function testToggleLabelMutation()
  local layout = build(morrowind, { component = 'toggle', args = { value = false } })
  local props = labelProps(layout)

  layout.events.focusGain(nil, layout)
  layout.events.mousePress({ button = 1 }, layout)
  layout.events.mouseClick(nil, layout)
  assert(props.text == 'On')
  layout.events.focusLoss(nil, layout)
  assert(props.text == 'On')
end

local function testTabStyleRetention()
  local layout = tabs {
    items = { 'First', 'Second' },
    buttonProps = { marker = 'base' },
    selectedProps = { marker = 'selected' },
    labelProps = { textColor = 'base' },
    selectedLabelProps = { textColor = 'selected' },
  }
  local first = layout.content[1]
  local second = layout.content[2]

  assert(first.props.marker == 'selected')
  assert(labelProps(first).textColor == 'selected')
  assert(second.props.marker == 'base')
  assert(labelProps(second).textColor == 'base')

  second.events.mouseClick(nil, second)
  assert(first.props.marker == 'base')
  assert(labelProps(first).textColor == 'base')
  assert(second.props.marker == 'selected')
  assert(labelProps(second).textColor == 'selected')
end

local function testSelectorAlignment()
  local layout = selector { items = { 'First' } }
  local arrow = layout.content[1].content[1].content[1].content[1].content[1].content[1]
  local value = layout.content[2]
  for _ = 1, 3 do
    value = value.content[1]
  end

  assert(layout.props.arrange == 'Center')
  assert(arrow.props.color == 'chrome-border')
  assert(value.props.textAlignH == 'Center')
  assert(value.props.textAlignV == 'Center')
end

local function testSearchInputHeight()
  local layout = searchInput { inputProps = { size = { x = 420, y = 28 } } }
  local input = layout.content[1].content[1].content[1].content[1]

  assert(input.props.size.y == 20)

  local defaultLayout = searchInput {}
  local defaultInput = defaultLayout.content[1].content[1].content[1].content[1]
  assert(defaultInput.props.size.y == 20)
end

local function testItemSlotChrome()
  local layout = itemSlot {}
  assert(layout.template.content[1].props.color == 'chrome-border')

  local customTemplate = {}
  assert(itemSlot({ template = customTemplate }).template == customTemplate)
end

local function testChromeCacheAndSkinSwap()
  local skin = chrome.resolve(nil, 'frame.thin')
  local first = chrome.box {
    skin = skin,
    alpha = 0.75,
    backgroundProps = { color = 'background' },
  }
  local second = chrome.box {
    skin = skin,
    alpha = 0.75,
    backgroundProps = { color = 'background' },
  }
  assert(first.template == second.template)
  assert(first.template.content[2].props.alpha == 0.75)

  local pin = pinButton {}
  local pinTopLeft = pin.content[2]
  assert(pinTopLeft.name == 'h3ui_topLeft')
  assert(pinTopLeft.props.resource.path == 'textures/h3ui/h3ui_chrome.dds')
  assert(pinTopLeft.props.resource.offset.x == 402)
  pin.events.mouseClick(nil, pin)
  assert(pinTopLeft.props.resource.path == 'textures/h3ui/h3ui_chrome.dds')
  assert(pinTopLeft.props.resource.offset.x == 424)

  local defaultMeter = meter {}
  assert(defaultMeter.type == ui.TYPE.Widget)
  assert(defaultMeter.props.size.x == 150 and defaultMeter.props.size.y == 18)
  assert(defaultMeter.content[2].name == 'h3ui_topLeft')
  assert(defaultMeter.content[2].props.color == 'chrome-border')

  local defaultTooltip = tooltip {}
  assert(defaultTooltip.template == nil)
  local tooltipContent = defaultTooltip.content[1]
  assert(tooltipContent.type == ui.TYPE.Widget)
  assert(tooltipContent.props.position.x == 2 and tooltipContent.props.position.y == 2)
  assert(tooltipContent.props.size.x == -4 and tooltipContent.props.size.y == -4)
  assert(tooltipContent.props.relativeSize.x == 1 and tooltipContent.props.relativeSize.y == 1)
  local tooltipText = tooltipContent.content[1]
  assert(tooltipText.type == ui.TYPE.TextEdit)
  assert(tooltipText.props.readOnly == true and tooltipText.props.wordWrap == true)
end

local function testTextInputDefaults()
  local layout = textInput {}
  assert(layout.type == ui.TYPE.TextEdit)
  assert(layout.template == nil)
  assert(layout.props.size.x == 150 and layout.props.size.y == 0)
  assert(layout.props.autoSize == true)
  assert(layout.props.multiline == false)
  assert(layout.props.textAlignV == 'Center')
  assert(layout.props.textColor == 'text-color')
  assert(layout.props.textSize == 16)
  local enteredLayout = textInput { text = 'typed text', props = { size = { x = 180, y = 24 } } }
  assert(enteredLayout.props.text == 'typed text')
  assert(enteredLayout.props.textAlignV == 'Center')

  local customTemplate = {}
  local customLayout = textInput { template = customTemplate }
  assert(customLayout.template == customTemplate)
  assert(customLayout.props.textColor == 'text-color')
  assert(customLayout.props.textSize == 16)
end

testTextRuleSlots()
testThemeTokens()
testBookFrameBackground()
testBuiltinPinChromePaths()
testWindowInnerBorder()
testStateMachineAndEventReturns()
testProtectionAndTraversal()
testToggleLabelMutation()
testTabStyleRetention()
testSelectorAlignment()
testSearchInputHeight()
testItemSlotChrome()
testChromeCacheAndSkinSwap()
testTextInputDefaults()

print 'H3UI runtime state tests passed'
