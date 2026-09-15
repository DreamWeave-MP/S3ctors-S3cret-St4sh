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
    metatable.__index = function(_, key) return value[key] end
    metatable.__len = function() return #value end
    return proxy
  end

  return {
    content = content,
    TYPE = { Container = 'Container', Flex = 'Flex', Image = 'Image' },
    texture = function(value) return value end,
  }
end

package.preload['openmw.util'] = function()
  return {
    color = {
      commaString = function(value) return value end,
      rgb = function(red, green, blue) return { red, green, blue } end,
    },
    vector2 = function(x, y) return { x = x, y = y } end,
  }
end

local I = require 'openmw.interfaces'
local bookFrame = require 'scripts.s3.components.bookFrame'
local newRegistry = require 'scripts.s3.ui.registry'
local newResolver = require 'scripts.s3.ui.resolver'
local newScope = require 'scripts.s3.ui.scope'
local textRules = require 'scripts.s3.ui.themes.textRules'
local themeModule = require 'scripts.s3.ui.theme'
local token = require 'scripts.s3.ui.token'

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

local function labelProps(layout) return layout.content[1].content[1].props end

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
  local frameContent = layout.content[1].content
  assert(layout.template == I.MWUI.templates.box)
  assert(frameContent[1].props.color == background.color)
  assert(frameContent[1].props.alpha == background.alpha)
  assert(frameContent[2].props.horizontal == false)
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

testTextRuleSlots()
testThemeTokens()
testBookFrameBackground()
testStateMachineAndEventReturns()
testProtectionAndTraversal()
testToggleLabelMutation()

print 'H3UI runtime state tests passed'
