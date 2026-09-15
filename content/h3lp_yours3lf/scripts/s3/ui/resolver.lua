---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'
local node = require 'scripts.s3.ui.node'
local themeModule = require 'scripts.s3.ui.theme'

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
    variant = componentNode.variant,
    tone = componentNode.tone,
    density = componentNode.density,
    state = componentNode.state,
    classes = classes,
    matched = rules,
    themeStyle = merge.copy(themeStyles),
    inlineStyle = merge.copy(inlineStyles),
  }
end

local function new(registry, builtinRecipes)
  local resolver = {}

  local resolveValue
  local resolveComponent
  local resolveRecipe

  local function findRecipe(scope, name, variant)
    local specific = variant and (name .. '.' .. variant) or nil
    if specific and scope.recipes[specific] then return scope.recipes[specific], specific end
    local recipeFunction = scope.recipes[name]
    if not recipeFunction then error('Unknown H3 UI recipe: ' .. tostring(name)) end
    return recipeFunction, name
  end

  local function recipeContext(scope, spec, parentContext)
    local baseRecipe = spec.recipe
    local density = spec.density
    if density == nil then density = parentContext and parentContext.density or scope.density end
    local invalidate = spec.invalidate
    if invalidate == nil then invalidate = parentContext and parentContext.invalidate end
    if invalidate ~= nil then
      assert(type(invalidate) == 'function', 'H3 UI invalidate must be a function')
    end

    local context = {
      theme = parentContext and parentContext.theme or scope.resolveTheme(),
      density = density,
      recipe = baseRecipe,
      invalidate = invalidate,
    }

    function context.component(name, childSpec)
      return node.component(name, childSpec, {
        recipe = baseRecipe,
        density = density,
        invalidate = invalidate,
      })
    end

    function context.build(childSpec) return node.recipe(childSpec) end
    function context.token(path) return scope.token(path) end
    return context
  end

  resolveRecipe = function(scope, spec, parentContext, trace)
    local recipeFunction = findRecipe(scope, spec.recipe, spec.variant)
    local context = recipeContext(scope, spec, parentContext)
    local result = recipeFunction(context, spec)
    return resolveValue(scope, result, context, trace)
  end

  local function resolveArgs(scope, args, context, trace)
    local result = merge.shallowCopy(args or {})
    local keys = { 'children', 'content', 'items' }

    for index = 1, #keys do
      local key = keys[index]
      local value = result[key]
      if node.isComponent(value) or node.isRecipe(value) then
        result[key] = resolveValue(scope, value, context, trace)
      elseif type(value) == 'table' and merge.isArray(value) then
        result[key] = resolveList(
          function(item, nestedContext) return resolveValue(scope, item, nestedContext, trace) end,
          value,
          context
        )
      end
    end

    return result
  end

  resolveComponent = function(scope, componentNode, context, trace)
    registry.get(componentNode.component)

    local activeTheme = context.theme or scope.resolveTheme()
    local matched = themeModule.matching(activeTheme, componentNode)
    local themeStyles = mergeRuleStyles(registry, componentNode.component, matched)
    local inlineStyles =
      normalizeInlineStyle(registry, componentNode.component, componentNode.style, activeTheme)

    local dynamicStyles
    if componentNode.state == nil and registry.supportsRuntimeState(componentNode.component) then
      for index = 1, #interactiveStates do
        local state = interactiveStates[index]
        if themeModule.hasStateRules(activeTheme, componentNode.component, state) then
          dynamicStyles = dynamicStyles or {}
          local styles = stateStyles(registry, activeTheme, componentNode, state)
          if next(styles) ~= nil then dynamicStyles[state] = styles end
        end
      end
    end
    if dynamicStyles and next(dynamicStyles) ~= nil then
      dynamicStyles.baseState = componentNode.state
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
    if node.isRecipe(value) then return resolveRecipe(scope, value.spec, context, trace) end
    return value
  end

  function resolver.build(scope, spec, trace)
    assert(merge.isPlainTable(spec), 'H3 UI build spec must be a plain table')

    if spec.recipe ~= nil then
      local invalidate = spec.invalidate
      if invalidate == nil then invalidate = scope.invalidate end
      return resolveRecipe(
        scope,
        spec,
        { theme = scope.resolveTheme(), density = scope.density, invalidate = invalidate },
        trace
      )
    end

    if spec.component ~= nil then
      local componentNode = node.component(spec.component, spec, { density = scope.density })
      return resolveComponent(scope, componentNode, {
        theme = scope.resolveTheme(),
        density = componentNode.density,
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
