---@omw-context menu|player

local constructors = require 'scripts.h3.ui.constructors'
local merge = require 'scripts.h3.ui.merge'
local mutation = require 'scripts.h3.ui.mutation'
local selector = require 'scripts.h3.ui.selector'
local specModule = require 'scripts.h3.ui.spec'
local themeModule = require 'scripts.h3.ui.theme'
local token = require 'scripts.h3.ui.token'

local Assert, Error, Next, SetMetatable, StrFormat, TableConcat, TableSort, ToString, Type =
  assert, error, next, setmetatable, string.format, table.concat, table.sort, tostring, type

local StyleBagKeys = {
  external = true,
  props = true,
  template = true,
}

local ComponentMetadata = {
  class = true,
  classes = true,
  component = true,
  recipe = true,
  role = true,
  style = true,
  tone = true,
  variant = true,
}

local ChildKeys = {
  children = true,
  content = true,
  items = true,
}

local InteractiveStates = { 'hover', 'pressed' }
local ComponentStringTraits = { 'role', 'tone', 'variant' }
local WeakKeys = { __mode = 'k' }
local StylePlanCache = SetMetatable({}, WeakKeys)

---@param style H3UI.Style|H3UI.StyleMap
---@return boolean
local function isRootStyleBag(style)
  for key in Next, style do
    if StyleBagKeys[key] then return true end
  end

  return false
end

---@param registry H3UI.Registry
---@param componentName string
---@param style? H3UI.Style|H3UI.StyleMap
---@param activeTheme H3UI.Theme
---@return H3UI.StyleMap?
local function normalizeInlineStyle(registry, componentName, style, activeTheme)
  if style == nil then return end
  Assert(merge.isPlainTable(style), 'H3 UI inline style must be a plain table')

  local resolved = activeTheme.resolve(style)
  ---@cast resolved H3UI.Style|H3UI.StyleMap
  if isRootStyleBag(resolved) then
    registry.validateSlot(componentName, 'root')
    return { root = resolved }
  end

  local result = {}
  for slot, bag in Next, resolved do
    registry.validateSlot(componentName, slot)

    if not merge.isPlainTable(bag) then
      Error(StrFormat('H3 UI inline style slot must be a plain table: %s', ToString(slot)))
    end

    result[slot] = bag
  end

  return result
end

---@param registry H3UI.Registry
---@param theme H3UI.Theme
---@param componentRecord H3UI.ComponentRecord
---@param state 'hover'|'pressed'
---@return H3UI.StyleMap
local function stateStyles(registry, theme, componentRecord, state)
  return themeModule.matchingStyles(theme, componentRecord, state, registry)
end

---@param componentRecord H3UI.ComponentRecord
---@return string
local function stylePlanKey(componentRecord)
  local classes = {}

  for className in Next, componentRecord.classes do
    classes[#classes + 1] = className
  end

  TableSort(classes)

  return TableConcat({
    componentRecord.component,
    componentRecord.recipe or '',
    componentRecord.role or '',
    componentRecord.tone or '',
    componentRecord.variant or '',
    componentRecord.selected == true and '1' or '0',
    TableConcat(classes, ','),
  }, '\31')
end

---@param registry H3UI.Registry
---@param theme H3UI.Theme
---@param componentRecord H3UI.ComponentRecord
---@return H3UI.StylePlan
local function stylePlan(registry, theme, componentRecord)
  local cache = StylePlanCache[theme]
  if not cache then
    cache = {}
    StylePlanCache[theme] = cache
  end

  local key = stylePlanKey(componentRecord)
  local cached = cache[key]

  if cached then return cached end

  local dynamicStyles
  local themeStyles = themeModule.matchingStyles(theme, componentRecord, nil, registry)

  if registry.supportsRuntimeState(componentRecord.component) then
    for index = 1, #InteractiveStates do
      local state = InteractiveStates[index]

      if themeModule.hasStateRules(theme, componentRecord.component, state) then
        local styles = stateStyles(registry, theme, componentRecord, state)

        if Next(styles) then
          dynamicStyles = dynamicStyles or {}
          dynamicStyles[state] = styles
        end
      end
    end
  end

  cached = {
    themeStyles = themeStyles,
    dynamicStyles = dynamicStyles,
  }
  cache[key] = cached

  return cached
end

---@param componentRecord H3UI.ComponentRecord
---@param selected boolean
---@return H3UI.ComponentRecord
local function styleRecord(componentRecord, selected)
  local result = {}

  for key, value in Next, componentRecord do
    result[key] = value
  end

  result.selected = selected

  return result
end

---@param componentRecord H3UI.ComponentRecord
---@param matched H3UI.CompiledThemeRule[]
---@param themeStyles H3UI.StyleMap
---@param inlineStyles? H3UI.StyleMap
---@return H3UI.TraceEntry
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
  for className in Next, componentRecord.classes do
    classes[#classes + 1] = className
  end

  TableSort(classes)

  return {
    classes = classes,
    component = componentRecord.component,
    inlineStyle = specModule.portable(inlineStyles),
    matched = rules,
    recipe = componentRecord.recipe,
    role = componentRecord.role,
    selected = componentRecord.selected,
    variant = componentRecord.variant,
    themeStyle = specModule.portable(themeStyles),
    tone = componentRecord.tone,
  }
end

---@param name string
---@param input? table
---@param recipeName? string
---@return H3UI.ComponentRecord
local function normalizeComponent(name, input, recipeName)
  input = input or {}

  Assert(Type(name) == 'string' and name ~= '', 'H3 UI component requires a component name')

  Assert(merge.isPlainTable(input), 'H3 UI component options must be a plain table')

  Assert(input.args == nil, 'H3 UI component args are flat; move fields out of args')

  Assert(
    input.invalidate == nil,
    'H3 UI invalidation belongs to the scope, not individual components'
  )

  Assert(
    input.density == nil,
    'H3 UI density was removed; style spacing explicitly or through theme rules'
  )

  Assert(
    input.state == nil,
    'H3 UI instance state was removed; interactive state is component-owned'
  )

  for index = 1, #ComponentStringTraits do
    local key = ComponentStringTraits[index]
    local value = input[key]

    if value ~= nil then
      if Type(value) ~= 'string' or value == '' then
        Error(StrFormat('H3 UI component %s must be a non-empty string', key))
      end
    end
  end

  local selected = input.selected
  if Type(selected) ~= 'boolean' then selected = nil end

  return {
    classes = selector.classes(input.classes, input.class),
    component = name,
    recipe = recipeName,
    role = input.role,
    selected = selected,
    source = input,
    style = input.style,
    tone = input.tone,
    variant = input.variant,
  }
end

---@param registry H3UI.Registry
---@param publicComponents string[]
---@return H3UI.Resolver
local function new(registry, publicComponents)
  publicComponents = publicComponents or {}
  local resolver = {}

  local resolveComponent, resolveRecipe, resolveValue
  ---@param scope H3UI.Scope
  ---@param name string
  ---@return H3UI.Recipe
  local function findRecipe(scope, name)
    local recipeFunction = scope.recipes[name]
    if not recipeFunction then Error(StrFormat('Unknown H3 UI recipe: %s', ToString(name))) end

    return recipeFunction
  end

  ---@param scope H3UI.Scope
  ---@param recipeName string
  ---@param parentContext? H3UI.ResolveContext
  ---@param trace? H3UI.TraceEntry[]
  ---@return H3UI.RecipeContext
  local function recipeContext(scope, recipeName, parentContext, trace)
    local invalidate = parentContext and parentContext.invalidate or scope.invalidate
    local context = {
      theme = parentContext and parentContext.theme or scope.resolveTheme(),
      recipe = recipeName,
      invalidate = invalidate,
    }

    ---@param name string
    ---@param childSpec? table
    ---@return openmw.ui.Layout
    function context.component(name, childSpec)
      childSpec = childSpec or {}

      Assert(merge.isPlainTable(childSpec), 'H3 UI component options must be a plain table')

      Assert(
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

    ---@param path string
    ---@return H3UI.TokenReference
    function context.token(path) return scope.token(path) end

    ---@param layout openmw.ui.Layout
    ---@param children openmw.ui.LayoutOrElement[]
    ---@return nil
    function context.setChildren(layout, children)
      mutation.setChildren(layout, children, invalidate)
    end

    ---@param childOptions? H3UI.ScopeOptions
    ---@return H3UI.RecipeContext
    function context.child(childOptions)
      childOptions = childOptions or {}

      Assert(merge.isPlainTable(childOptions), 'H3 UI recipe child options must be a plain table')

      local childScope = scope.child {
        element = childOptions.element,
        invalidate = childOptions.invalidate,
        recipes = childOptions.recipes,
        _ownsElement = childOptions._ownsElement,
      }

      local childContext = recipeContext(
        childScope,
        recipeName,
        { theme = context.theme, invalidate = childScope.invalidate },
        trace
      )
      ---@param layout openmw.ui.Layout
      ---@param styles table<string, H3UI.Style>
      ---@return nil
      function childContext.patch(layout, styles) childScope.patch(layout, styles) end
      ---@param layout openmw.ui.Layout
      ---@param selected boolean
      ---@return nil
      function childContext.setSelected(layout, selected) childScope.setSelected(layout, selected) end

      return childContext
    end

    ---@param name string
    ---@param childSpec? table
    ---@return openmw.ui.Layout
    local function recipe(name, childSpec)
      childSpec = childSpec or {}

      Assert(merge.isPlainTable(childSpec), 'H3 UI recipe options must be a plain table')

      Assert(
        childSpec.component == nil and childSpec.recipe == nil,
        'H3 UI recipe constructor options cannot select another component or recipe'
      )

      Assert(
        childSpec.invalidate == nil,
        'H3 UI invalidation belongs to the scope, not individual recipes'
      )

      return resolveRecipe(scope, name, childSpec, context, trace)
    end

    constructors(
      context,
      publicComponents,
      scope.recipes,
      ---@param name string
      ---@param childSpec? table
      ---@return openmw.ui.Layout
      function(name, childSpec) return context.component(name, childSpec) end,
      recipe
    )

    return context
  end

  ---@param scope H3UI.Scope
  ---@param recipeName string
  ---@param input table
  ---@param parentContext? H3UI.ResolveContext
  ---@param trace? H3UI.TraceEntry[]
  ---@return openmw.ui.Layout
  resolveRecipe = function(scope, recipeName, input, parentContext, trace)
    Assert(Type(recipeName) == 'string' and recipeName ~= '', 'H3 UI recipe requires a name')

    Assert(merge.isPlainTable(input), 'H3 UI recipe options must be a plain table')

    Assert(input.args == nil, 'H3 UI recipe args are flat; move fields out of args')

    Assert(
      input.invalidate == nil,
      'H3 UI invalidation belongs to the scope, not individual recipes'
    )

    Assert(input.density == nil, 'H3 UI density was removed')

    Assert(input.state == nil, 'H3 UI instance state was removed')

    local recipeFunction = findRecipe(scope, recipeName)
    local context = recipeContext(scope, recipeName, parentContext, trace)
    local recipeInput = input

    if input.recipe then
      recipeInput = {}

      for key, value in Next, input do
        if key ~= 'recipe' then recipeInput[key] = value end
      end
    end

    local result = recipeFunction(context, recipeInput)

    return resolveValue(scope, result, context, trace)
  end

  ---@param scope H3UI.Scope
  ---@param values H3UI.LuaValue[]
  ---@param context H3UI.ResolveContext
  ---@param trace? H3UI.TraceEntry[]
  ---@return H3UI.LuaValue[]
  local function resolveArray(scope, values, context, trace)
    local result = {}

    for index = 1, #values do
      result[index] = resolveValue(scope, values[index], context, trace)
    end

    return result
  end

  ---@param scope H3UI.Scope
  ---@param args table
  ---@param context H3UI.ResolveContext
  ---@param trace? H3UI.TraceEntry[]
  ---@return table
  local function resolveArgs(scope, args, context, trace)
    local result = {}
    for key, value in Next, args do
      if ComponentMetadata[key] then
        -- Semantic metadata is consumed by the resolver rather than forwarded to builders.
      elseif Type(key) == 'number' then
        result[key] = resolveValue(scope, value, context, trace)
      elseif ChildKeys[key] then
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

  ---@param scope H3UI.Scope
  ---@param componentRecord H3UI.ComponentRecord
  ---@param context H3UI.ResolveContext
  ---@param trace? H3UI.TraceEntry[]
  ---@return openmw.ui.Layout
  resolveComponent = function(scope, componentRecord, context, trace)
    registry.get(componentRecord.component)
    local sourceSelected = componentRecord.source.selected

    if registry.supportsSelection(componentRecord.component) then
      if sourceSelected ~= nil then
        Assert(Type(sourceSelected) == 'boolean', 'H3 UI selected must be boolean')
      end
    elseif Type(sourceSelected) == 'boolean' then
      Error(
        StrFormat('H3 UI selected is not supported by component: %s', componentRecord.component)
      )
    end

    local activeTheme = context.theme or scope.resolveTheme()
    local selected = componentRecord.selected == true
    local currentRecord = styleRecord(componentRecord, selected)
    local currentPlan = stylePlan(registry, activeTheme, currentRecord)
    local themeStyles = currentPlan.themeStyles
    local inlineStyles =
      normalizeInlineStyle(registry, componentRecord.component, componentRecord.style, activeTheme)

    if trace then
      trace[#trace + 1] = makeTraceEntry(
        componentRecord,
        themeModule.matching(activeTheme, currentRecord),
        themeStyles,
        inlineStyles
      )
    end

    local selectionStyles
    if registry.supportsSelection(componentRecord.component) then
      local basePlan = stylePlan(registry, activeTheme, styleRecord(componentRecord, false))
      local selectedPlan = stylePlan(registry, activeTheme, styleRecord(componentRecord, true))

      selectionStyles = {
        base = basePlan.themeStyles,
        baseRuntime = basePlan.dynamicStyles,
        selected = selectedPlan.themeStyles,
        selectedRuntime = selectedPlan.dynamicStyles,
      }
    end

    return registry.build(
      componentRecord.component,
      resolveArgs(scope, componentRecord.source, context, trace),
      themeStyles,
      inlineStyles or {},
      currentPlan.dynamicStyles,
      context.invalidate,
      selectionStyles,
      selected
    )
  end

  ---@param scope H3UI.Scope
  ---@param value H3UI.LuaValue
  ---@param context H3UI.ResolveContext
  ---@param trace? H3UI.TraceEntry[]
  ---@return H3UI.LuaValue
  resolveValue = function(scope, value, context, trace)
    if specModule.isComponent(value) then
      ---@cast value table
      return resolveComponent(
        scope,
        normalizeComponent(value.component, value, context.recipe),
        context,
        trace
      )
    end

    if specModule.isRecipe(value) then
      ---@cast value table
      return resolveRecipe(scope, value.recipe, value, context, trace)
    end

    if token.isRef(value) then
      ---@cast value H3UI.TokenReference
      return context.theme.resolve(value)
    end

    return value
  end

  ---@param kind 'component'|'recipe'
  ---@param input? table
  ---@return table
  local function constructorSpec(kind, input)
    input = input or {}

    if not merge.isPlainTable(input) then
      Error(StrFormat('H3 UI %s options must be a plain table', kind))
    end

    Assert(
      input.component == nil and input.recipe == nil,
      'H3 UI constructor options cannot select another component or recipe'
    )

    Assert(
      input.invalidate == nil,
      'H3 UI invalidation belongs to the scope, not individual components or recipes'
    )

    return input
  end

  ---@param scope H3UI.Scope
  ---@param name string
  ---@param input? table
  ---@param trace? table
  ---@return openmw.ui.Layout
  function resolver.component(scope, name, input, trace)
    input = constructorSpec('component', input)
    local context = {
      theme = scope.resolveTheme(),
      invalidate = scope.invalidate,
    }

    return resolveComponent(scope, normalizeComponent(name, input), context, trace)
  end

  ---@param scope H3UI.Scope
  ---@param name string
  ---@param input? table
  ---@param trace? table
  ---@return openmw.ui.Layout
  function resolver.recipe(scope, name, input, trace)
    input = constructorSpec('recipe', input)

    return resolveRecipe(scope, name, input, {
      theme = scope.resolveTheme(),
      invalidate = scope.invalidate,
    }, trace)
  end

  ---@param scope H3UI.Scope
  ---@param input H3UI.Spec|H3UI.Document
  ---@param trace? H3UI.TraceEntry[]
  ---@return openmw.ui.Layout
  function resolver.build(scope, input, trace)
    input = specModule.root(input)

    Assert(merge.isPlainTable(input), 'H3 UI build spec must be a plain table')

    Assert(
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

    Error 'H3 UI build requires recipe or component'
  end

  ---@param scope H3UI.Scope
  ---@param input H3UI.Spec|H3UI.Document
  ---@return H3UI.ExplainResult
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
