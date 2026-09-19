---@omw-context menu|player

local constructors = require 'scripts.s3.ui.constructors'
local merge = require 'scripts.s3.ui.merge'
local mutation = require 'scripts.s3.ui.mutation'
local node = require 'scripts.s3.ui.node'
local themeModule = require 'scripts.s3.ui.theme'
local token = require 'scripts.s3.ui.token'

local styleBagKeys = {
  external = true,
  props = true,
  template = true,
}

local interactiveStates = { 'hover', 'pressed' }

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

local function mergeRuleStyles(registry, componentName, matched)
  local styles = {}
  for index = 1, #matched do
    local rule = matched[index]
    registry.validateSlot(componentName, rule.slot)
    local slotStyle = styles[rule.slot]
    if not slotStyle then
      slotStyle = {}
      styles[rule.slot] = slotStyle
    end
    merge.mergeInto(slotStyle, rule.style)
  end
  return styles
end

local function stateStyles(registry, theme, componentNode, state)
  local stateNode = merge.shallowCopy(componentNode)
  stateNode.state = state

  return mergeRuleStyles(
    registry,
    componentNode.component,
    themeModule.matchingState(theme, stateNode, state)
  )
end

local function resolveList(resolveValue, values, context)
  local result = {}
  for index = 1, #values do
    result[index] = resolveValue(values[index], context)
  end
  return result
end

local function makeTraceEntry(componentNode, matched, themeStyles, inlineStyles)
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
  for className in next, componentNode.classes do
    classes[#classes + 1] = className
  end
  table.sort(classes)

  return {
    component = componentNode.component,
    recipe = componentNode.recipe,
    role = componentNode.role,
    selected = componentNode.selected,
    variant = componentNode.variant,
    tone = componentNode.tone,
    classes = classes,
    matched = rules,
    themeStyle = merge.copy(themeStyles),
    inlineStyle = merge.copy(inlineStyles),
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
    return recipeFunction, name
  end

  local function recipeContext(scope, recipeName, spec, parentContext, trace)
    local baseRecipe = recipeName
    local invalidate = spec.invalidate
    if invalidate == nil then invalidate = parentContext and parentContext.invalidate end
    if invalidate ~= nil then
      assert(type(invalidate) == 'function', 'H3 UI invalidate must be a function')
    end

    local context = {
      theme = parentContext and parentContext.theme or scope.resolveTheme(),
      recipe = baseRecipe,
      invalidate = invalidate,
    }

    function context.component(name, childSpec)
      childSpec = childSpec or {}
      assert(merge.isPlainTable(childSpec), 'H3 UI component options must be a plain table')
      local componentNode = node.component(name, childSpec, {
        recipe = baseRecipe,
        invalidate = invalidate,
      })
      return resolveComponent(scope, componentNode, context, trace)
    end

    function context.token(path) return scope.token(path) end

    function context.setChildren(layout, children)
      mutation.setChildren(layout, children, invalidate)
    end

    local function recipe(name, childSpec)
      childSpec = childSpec or {}
      assert(merge.isPlainTable(childSpec), 'H3 UI recipe options must be a plain table')
      assert(
        childSpec.component == nil and childSpec.recipe == nil,
        'H3 UI recipe constructor options cannot select another component or recipe'
      )
      local nested = merge.shallowCopy(childSpec)
      nested.recipe = name
      return resolveRecipe(scope, name, nested, context, trace)
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

  resolveRecipe = function(scope, recipeName, spec, parentContext, trace)
    local recipeFunction = findRecipe(scope, recipeName)
    local context = recipeContext(scope, recipeName, spec, parentContext, trace)
    local result = recipeFunction(context, spec)
    return resolveValue(scope, result, context, trace)
  end

  local function resolveArgs(scope, args, context, trace)
    local result = merge.shallowCopy(args or {})
    local childKeys = { children = true, content = true, items = true }

    for key, value in next, result do
      if type(key) == 'number' then
        result[key] = resolveValue(scope, value, context, trace)
      elseif childKeys[key] then
        if node.isComponent(value) or node.isRecipe(value) then
          result[key] = resolveValue(scope, value, context, trace)
        elseif type(value) == 'table' and merge.isArray(value) then
          result[key] = resolveList(
            function(item, nestedContext) return resolveValue(scope, item, nestedContext, trace) end,
            value,
            context
          )
        end
      elseif token.isRef(value) then
        result[key] = resolveValue(scope, value, context, trace)
      end
    end

    return result
  end

  resolveComponent = function(scope, componentNode, context, trace)
    registry.get(componentNode.component)
    local selected = componentNode.args.selected
    if registry.supportsSelection(componentNode.component) then
      if selected ~= nil then
        assert(type(selected) == 'boolean', 'H3 UI selected must be boolean')
      end
    elseif componentNode.selected ~= nil then
      error('H3 UI selected is not supported by component: ' .. componentNode.component)
    end

    local activeTheme = context.theme or scope.resolveTheme()
    local matched = themeModule.matching(activeTheme, componentNode)
    local themeStyles = mergeRuleStyles(registry, componentNode.component, matched)
    local inlineStyles =
      normalizeInlineStyle(registry, componentNode.component, componentNode.style, activeTheme)

    local dynamicStyles
    if registry.supportsRuntimeState(componentNode.component) then
      for index = 1, #interactiveStates do
        local state = interactiveStates[index]
        if themeModule.hasStateRules(activeTheme, componentNode.component, state) then
          dynamicStyles = dynamicStyles or {}
          local styles = stateStyles(registry, activeTheme, componentNode, state)
          if next(styles) ~= nil then dynamicStyles[state] = styles end
        end
      end
    end
    if trace then
      trace[#trace + 1] = makeTraceEntry(componentNode, matched, themeStyles, inlineStyles)
    end

    local args = resolveArgs(scope, componentNode.args, context, trace)
    local invalidate = componentNode.invalidate or context.invalidate
    if invalidate ~= nil then
      assert(type(invalidate) == 'function', 'H3 UI invalidate must be a function')
    end
    return registry.build(
      componentNode.component,
      args,
      themeStyles,
      inlineStyles,
      dynamicStyles,
      invalidate
    )
  end

  resolveValue = function(scope, value, context, trace)
    if node.isComponent(value) then return resolveComponent(scope, value, context, trace) end
    if node.isRecipe(value) then
      return resolveRecipe(scope, value.spec.recipe, value.spec, context, trace)
    end
    if token.isRef(value) then return context.theme.resolve(value) end
    return value
  end

  local function constructorSpec(kind, spec)
    spec = spec or {}
    assert(merge.isPlainTable(spec), 'H3 UI ' .. kind .. ' options must be a plain table')
    assert(
      spec.component == nil and spec.recipe == nil,
      'H3 UI constructor options cannot select another component or recipe'
    )
    return spec
  end

  function resolver.component(scope, name, spec, trace)
    spec = constructorSpec('component', spec)
    local componentNode = node.component(name, spec)
    return resolveComponent(scope, componentNode, {
      theme = scope.resolveTheme(),
      invalidate = spec.invalidate or scope.invalidate,
    }, trace)
  end

  function resolver.recipe(scope, name, spec, trace)
    spec = constructorSpec('recipe', spec)
    return resolveRecipe(scope, name, spec, {
      theme = scope.resolveTheme(),
      invalidate = spec.invalidate or scope.invalidate,
    }, trace)
  end

  function resolver.build(scope, spec, trace)
    assert(merge.isPlainTable(spec), 'H3 UI build spec must be a plain table')

    if spec.recipe ~= nil then
      local invalidate = spec.invalidate
      if invalidate == nil then invalidate = scope.invalidate end
      return resolveRecipe(scope, spec.recipe, spec, {
        theme = scope.resolveTheme(),
        invalidate = invalidate,
      }, trace)
    end

    if spec.component ~= nil then
      local componentNode = node.component(spec.component, spec)
      return resolveComponent(scope, componentNode, {
        theme = scope.resolveTheme(),
        invalidate = scope.invalidate,
      }, trace)
    end

    error 'H3 UI build requires recipe or component'
  end

  function resolver.explain(scope, spec)
    local trace = {}
    local layout = resolver.build(scope, spec, trace)
    return {
      layout = layout,
      nodes = trace,
      theme = scope.resolveTheme().name,
    }
  end

  return resolver
end

return new
