---@omw-context menu|player

local constructors = require 'scripts.s3.ui.constructors'
local merge = require 'scripts.s3.ui.merge'
local mutation = require 'scripts.s3.ui.mutation'
local selector = require 'scripts.s3.ui.selector'
local specModule = require 'scripts.s3.ui.spec'
local themeModule = require 'scripts.s3.ui.theme'
local token = require 'scripts.s3.ui.token'

local styleBagKeys = {
  external = true,
  props = true,
  template = true,
}

local componentMetadata = {
  class = true,
  classes = true,
  component = true,
  recipe = true,
  role = true,
  style = true,
  tone = true,
  variant = true,
}

local childKeys = {
  children = true,
  content = true,
  items = true,
}

local interactiveStates = { 'hover', 'pressed' }
local componentStringTraits = { 'role', 'tone', 'variant' }
local stylePlanCache = setmetatable({}, { __mode = 'k' })

local function isRootStyleBag(style)
  for key in next, style do
    if styleBagKeys[key] then return true end
  end
  return false
end

local function normalizeInlineStyle(registry, componentName, style, activeTheme)
  if style == nil then return nil end
  assert(merge.isPlainTable(style), 'H3 UI inline style must be a plain table')

  local resolved = activeTheme.resolve(style)
  if isRootStyleBag(resolved) then
    registry.validateSlot(componentName, 'root')
    return { root = resolved }
  end

  local result = {}
  for slot, bag in next, resolved do
    registry.validateSlot(componentName, slot)
    assert(
      merge.isPlainTable(bag),
      'H3 UI inline style slot must be a plain table: ' .. tostring(slot)
    )
    result[slot] = bag
  end
  return result
end

local function stateStyles(registry, theme, componentRecord, state)
  return themeModule.matchingStyles(theme, componentRecord, state, registry)
end

local function stylePlanKey(componentRecord)
  local classes = {}
  for className in next, componentRecord.classes do
    classes[#classes + 1] = className
  end
  table.sort(classes)

  return table.concat({
    componentRecord.component,
    componentRecord.recipe or '',
    componentRecord.role or '',
    componentRecord.tone or '',
    componentRecord.variant or '',
    componentRecord.selected == true and '1' or '0',
    table.concat(classes, ','),
  }, '\31')
end

local function stylePlan(registry, theme, componentRecord)
  local cache = stylePlanCache[theme]
  if cache == nil then
    cache = {}
    stylePlanCache[theme] = cache
  end

  local key = stylePlanKey(componentRecord)
  local cached = cache[key]
  if cached then return cached end

  local matched = {}
  local themeStyles = themeModule.matchingStyles(theme, componentRecord, nil, registry, matched)
  local dynamicStyles
  if registry.supportsRuntimeState(componentRecord.component) then
    for index = 1, #interactiveStates do
      local state = interactiveStates[index]
      if themeModule.hasStateRules(theme, componentRecord.component, state) then
        local styles = stateStyles(registry, theme, componentRecord, state)
        if next(styles) ~= nil then
          dynamicStyles = dynamicStyles or {}
          dynamicStyles[state] = styles
        end
      end
    end
  end

  cached = {
    matched = matched,
    themeStyles = themeStyles,
    dynamicStyles = dynamicStyles,
  }
  cache[key] = cached
  return cached
end

local function styleRecord(componentRecord, selected)
  local result = {}
  for key, value in next, componentRecord do
    result[key] = value
  end
  result.selected = selected
  return result
end

local function makeTraceEntry(componentRecord, matched, themeStyles, inlineStyles)
  local rules = {}
  for index = 1, #matched do
    local rule = matched[index]
    rules[index] = {
      order = rule.order,
      selector = merge.copy(rule.selector),
      slot = rule.slot,
      source = rule.source,
      specificity = rule.specificity,
      tier = rule.tier,
    }
  end

  local classes = {}
  for className in next, componentRecord.classes do
    classes[#classes + 1] = className
  end
  table.sort(classes)

  return {
    component = componentRecord.component,
    recipe = componentRecord.recipe,
    role = componentRecord.role,
    selected = componentRecord.selected,
    variant = componentRecord.variant,
    tone = componentRecord.tone,
    classes = classes,
    matched = rules,
    themeStyle = specModule.portable(themeStyles),
    inlineStyle = specModule.portable(inlineStyles),
  }
end

local function normalizeComponent(name, input, recipeName)
  input = input or {}
  assert(type(name) == 'string' and name ~= '', 'H3 UI component requires a component name')
  assert(merge.isPlainTable(input), 'H3 UI component options must be a plain table')
  assert(input.args == nil, 'H3 UI component args are flat; move fields out of args')
  assert(
    input.invalidate == nil,
    'H3 UI invalidation belongs to the scope, not individual components'
  )
  assert(
    input.density == nil,
    'H3 UI density was removed; style spacing explicitly or through theme rules'
  )
  assert(
    input.state == nil,
    'H3 UI instance state was removed; interactive state is component-owned'
  )
  for index = 1, #componentStringTraits do
    local key = componentStringTraits[index]
    local value = input[key]
    if value ~= nil then
      assert(
        type(value) == 'string' and value ~= '',
        'H3 UI component ' .. key .. ' must be a non-empty string'
      )
    end
  end

  local selected = input.selected
  if type(selected) ~= 'boolean' then selected = nil end

  return {
    component = name,
    recipe = recipeName,
    role = input.role,
    selected = selected,
    variant = input.variant,
    tone = input.tone,
    classes = selector.classes(input.classes, input.class),
    source = input,
    style = input.style,
  }
end

local function new(registry, publicComponents)
  publicComponents = publicComponents or {}
  local resolver = {}

  local resolveValue
  local resolveComponent
  local resolveRecipe

  local function findRecipe(scope, name)
    local recipeFunction = scope.recipes[name]
    if not recipeFunction then error('Unknown H3 UI recipe: ' .. tostring(name)) end
    return recipeFunction
  end

  local function recipeContext(scope, recipeName, parentContext, trace)
    local invalidate = parentContext and parentContext.invalidate or scope.invalidate
    local context = {
      theme = parentContext and parentContext.theme or scope.resolveTheme(),
      recipe = recipeName,
      invalidate = invalidate,
    }

    function context.component(name, childSpec)
      childSpec = childSpec or {}
      assert(merge.isPlainTable(childSpec), 'H3 UI component options must be a plain table')
      assert(
        childSpec.component == nil and childSpec.recipe == nil,
        'H3 UI component constructor options cannot select another component or recipe'
      )
      return resolveComponent(
        scope,
        normalizeComponent(name, childSpec, recipeName),
        context,
        trace
      )
    end

    function context.token(path) return scope.token(path) end

    function context.setChildren(layout, children)
      mutation.setChildren(layout, children, invalidate)
    end

    function context.child(childOptions)
      childOptions = childOptions or {}
      assert(merge.isPlainTable(childOptions), 'H3 UI recipe child options must be a plain table')
      local childScope = scope.child {
        invalidate = childOptions.invalidate,
        element = childOptions.element,
        recipes = childOptions.recipes,
        _ownsElement = childOptions._ownsElement,
      }
      local childContext = recipeContext(
        childScope,
        recipeName,
        { theme = context.theme, invalidate = childScope.invalidate },
        trace
      )
      function childContext.patch(layout, styles) childScope.patch(layout, styles) end
      function childContext.setSelected(layout, selected) childScope.setSelected(layout, selected) end
      return childContext
    end

    local function recipe(name, childSpec)
      childSpec = childSpec or {}
      assert(merge.isPlainTable(childSpec), 'H3 UI recipe options must be a plain table')
      assert(
        childSpec.component == nil and childSpec.recipe == nil,
        'H3 UI recipe constructor options cannot select another component or recipe'
      )
      assert(
        childSpec.invalidate == nil,
        'H3 UI invalidation belongs to the scope, not individual recipes'
      )
      return resolveRecipe(scope, name, childSpec, context, trace)
    end

    constructors(
      context,
      publicComponents,
      scope.recipes,
      function(name, childSpec) return context.component(name, childSpec) end,
      recipe
    )

    return context
  end

  resolveRecipe = function(scope, recipeName, input, parentContext, trace)
    assert(type(recipeName) == 'string' and recipeName ~= '', 'H3 UI recipe requires a name')
    assert(merge.isPlainTable(input), 'H3 UI recipe options must be a plain table')
    assert(input.args == nil, 'H3 UI recipe args are flat; move fields out of args')
    assert(
      input.invalidate == nil,
      'H3 UI invalidation belongs to the scope, not individual recipes'
    )
    assert(input.density == nil, 'H3 UI density was removed')
    assert(input.state == nil, 'H3 UI instance state was removed')

    local recipeFunction = findRecipe(scope, recipeName)
    local context = recipeContext(scope, recipeName, parentContext, trace)
    local recipeInput = input
    if input.recipe ~= nil then
      recipeInput = {}
      for key, value in next, input do
        if key ~= 'recipe' then recipeInput[key] = value end
      end
    end
    local result = recipeFunction(context, recipeInput)
    return resolveValue(scope, result, context, trace)
  end

  local function resolveArray(scope, values, context, trace)
    local result = {}
    for index = 1, #values do
      result[index] = resolveValue(scope, values[index], context, trace)
    end
    return result
  end

  local function resolveArgs(scope, args, context, trace)
    local result = {}
    for key, value in next, args do
      if componentMetadata[key] then
        -- Semantic metadata is consumed by the resolver rather than forwarded to builders.
      elseif type(key) == 'number' then
        result[key] = resolveValue(scope, value, context, trace)
      elseif childKeys[key] then
        if specModule.isComponent(value) or specModule.isRecipe(value) then
          result[key] = resolveValue(scope, value, context, trace)
        elseif merge.isArray(value) then
          result[key] = resolveArray(scope, value, context, trace)
        else
          result[key] = value
        end
      elseif token.isRef(value) then
        result[key] = context.theme.resolve(value)
      else
        result[key] = value
      end
    end
    return result
  end

  resolveComponent = function(scope, componentRecord, context, trace)
    registry.get(componentRecord.component)
    local selected = componentRecord.source.selected
    if registry.supportsSelection(componentRecord.component) then
      if selected ~= nil then
        assert(type(selected) == 'boolean', 'H3 UI selected must be boolean')
      end
    elseif componentRecord.selected ~= nil then
      error('H3 UI selected is not supported by component: ' .. componentRecord.component)
    end

    local activeTheme = context.theme or scope.resolveTheme()
    local selected = componentRecord.selected == true
    local currentRecord = styleRecord(componentRecord, selected)
    local currentPlan = stylePlan(registry, activeTheme, currentRecord)
    local themeStyles = currentPlan.themeStyles
    local inlineStyles =
      normalizeInlineStyle(registry, componentRecord.component, componentRecord.style, activeTheme)

    if trace then
      trace[#trace + 1] =
        makeTraceEntry(componentRecord, currentPlan.matched, themeStyles, inlineStyles)
    end

    local selectionStyles
    if registry.supportsSelection(componentRecord.component) then
      local basePlan = stylePlan(registry, activeTheme, styleRecord(componentRecord, false))
      local selectedPlan = stylePlan(registry, activeTheme, styleRecord(componentRecord, true))
      selectionStyles = {
        base = basePlan.themeStyles,
        selected = selectedPlan.themeStyles,
        baseRuntime = basePlan.dynamicStyles,
        selectedRuntime = selectedPlan.dynamicStyles,
      }
    end

    return registry.build(
      componentRecord.component,
      resolveArgs(scope, componentRecord.source, context, trace),
      themeStyles,
      inlineStyles,
      currentPlan.dynamicStyles,
      context.invalidate,
      selectionStyles,
      selected
    )
  end

  resolveValue = function(scope, value, context, trace)
    if specModule.isComponent(value) then
      return resolveComponent(
        scope,
        normalizeComponent(value.component, value, context.recipe),
        context,
        trace
      )
    end
    if specModule.isRecipe(value) then
      return resolveRecipe(scope, value.recipe, value, context, trace)
    end
    if token.isRef(value) then return context.theme.resolve(value) end
    return value
  end

  local function constructorSpec(kind, input)
    input = input or {}
    assert(merge.isPlainTable(input), 'H3 UI ' .. kind .. ' options must be a plain table')
    assert(
      input.component == nil and input.recipe == nil,
      'H3 UI constructor options cannot select another component or recipe'
    )
    assert(
      input.invalidate == nil,
      'H3 UI invalidation belongs to the scope, not individual components or recipes'
    )
    return input
  end

  function resolver.component(scope, name, input, trace)
    input = constructorSpec('component', input)
    local context = {
      theme = scope.resolveTheme(),
      invalidate = scope.invalidate,
    }
    return resolveComponent(scope, normalizeComponent(name, input), context, trace)
  end

  function resolver.recipe(scope, name, input, trace)
    input = constructorSpec('recipe', input)
    return resolveRecipe(scope, name, input, {
      theme = scope.resolveTheme(),
      invalidate = scope.invalidate,
    }, trace)
  end

  function resolver.build(scope, input, trace)
    input = specModule.root(input)
    assert(merge.isPlainTable(input), 'H3 UI build spec must be a plain table')
    assert(
      not (input.component ~= nil and input.recipe ~= nil),
      'H3 UI build spec cannot select both component and recipe'
    )

    if specModule.isRecipe(input) then
      return resolveRecipe(scope, input.recipe, input, {
        theme = scope.resolveTheme(),
        invalidate = scope.invalidate,
      }, trace)
    end

    if specModule.isComponent(input) then
      return resolveComponent(scope, normalizeComponent(input.component, input), {
        theme = scope.resolveTheme(),
        invalidate = scope.invalidate,
      }, trace)
    end

    error 'H3 UI build requires recipe or component'
  end

  function resolver.explain(scope, input)
    local root = specModule.root(input)
    local trace = {}
    local layout = resolver.build(scope, root, trace)
    return {
      document = specModule.document(root),
      layout = layout,
      nodes = trace,
      theme = scope.resolveTheme().name,
    }
  end

  return resolver
end

return new
