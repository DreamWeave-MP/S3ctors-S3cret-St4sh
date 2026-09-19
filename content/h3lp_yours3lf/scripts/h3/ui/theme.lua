---@omw-context menu|player

local merge = require 'scripts.h3.ui.merge'
local selector = require 'scripts.h3.ui.selector'
local token = require 'scripts.h3.ui.token'

local Assert, Next, RawGet, StrFormat, TableSort, ToString, Type =
  assert, next, rawget, string.format, table.sort, tostring, type

local Marker = {}

local nextThemeId = 0

---@param value H3UI.LuaValue
---@return boolean
local function isTheme(value) return Type(value) == 'table' and RawGet(value, Marker) == true end

---@param input H3UI.ThemeRule
---@param source string
---@return H3UI.ThemeRule
local function normalizeRawRule(input, source)
  Assert(merge.isPlainTable(input), 'H3 UI theme rule must be a plain table')
  Assert(input.style, 'H3 UI theme rule requires style')
  Assert(merge.isPlainTable(input.style), 'H3 UI theme rule style must be a plain table')

  return {
    selector = merge.copy(input.selector or {}),
    source = input.source or source,
    style = merge.copy(input.style),
  }
end

---@param registry H3UI.Registry
---@param ruleSelector H3UI.ThemeSelector
---@return nil
local function validateSelector(registry, ruleSelector)
  if not ruleSelector.component then return end

  registry.get(ruleSelector.component)

  if not ruleSelector.slot then return end

  registry.validateSlot(ruleSelector.component, ruleSelector.slot)
end

---@param left H3UI.CompiledThemeRule
---@param right H3UI.CompiledThemeRule
---@return boolean
local function compareRules(left, right)
  if left.tier ~= right.tier then return left.tier < right.tier end
  if left.specificity ~= right.specificity then return left.specificity < right.specificity end

  return left.order < right.order
end

---@param index H3UI.ThemeRuleIndex
---@return nil
local function sortBuckets(index)
  TableSort(index.generic, compareRules)

  for _, bucket in Next, index.component do
    TableSort(bucket, compareRules)
  end

  for _, stateIndex in Next, index.state do
    TableSort(stateIndex.generic, compareRules)

    for _, bucket in Next, stateIndex.component do
      TableSort(bucket, compareRules)
    end
  end
end

---@param spec H3UI.ThemeSpec
---@param registry H3UI.Registry
---@param inheritedParent? H3UI.Theme
---@return H3UI.Theme
local function new(spec, registry, inheritedParent)
  spec = spec or {}
  Assert(merge.isPlainTable(spec), 'H3 UI theme must be a plain table')

  local parent = spec.extends or inheritedParent
  if parent ~= nil then
    Assert(isTheme(parent), 'H3 UI theme extends must be another compiled theme')
  end

  local rawTokens = parent and merge.copy(parent._rawTokens) or {}
  if spec.tokens ~= nil then
    Assert(merge.isPlainTable(spec.tokens), 'H3 UI theme tokens must be a plain table')
    merge.mergeInto(rawTokens, spec.tokens)
  end

  local rawRules = {}
  if parent then
    for index = 1, #parent._rawRules do
      rawRules[#rawRules + 1] = merge.copy(parent._rawRules[index])
    end
  end

  local sourceName = spec.name or StrFormat('theme#%s', ToString(nextThemeId + 1))
  if spec.rules ~= nil then
    Assert(
      merge.isPlainTable(spec.rules) and (not Next(spec.rules) or merge.isArray(spec.rules)),
      'H3 UI theme rules must be a dense array'
    )

    for index = 1, #spec.rules do
      rawRules[#rawRules + 1] = normalizeRawRule(spec.rules[index], sourceName)
    end
  end

  local resolvedTokens = token.resolveTree(rawTokens)
  local rawChrome = parent and merge.copy(parent._rawChrome) or {}
  if spec.chrome ~= nil then
    Assert(merge.isPlainTable(spec.chrome), 'H3 UI theme chrome must be a plain table')
    merge.mergeInto(rawChrome, spec.chrome)
  end

  local index, rules = {
    generic = {},
    component = {},
    state = {},
  }, {}

  for order = 1, #rawRules do
    local rawRule = rawRules[order]
    local normalizedSelector = selector.normalize(rawRule.selector)

    validateSelector(registry, normalizedSelector)

    local rule = {
      order = order,
      selector = normalizedSelector,
      slot = normalizedSelector.slot or 'root',
      source = rawRule.source,
      specificity = selector.specificity(normalizedSelector),
      style = token.resolveValue(rawRule.style, resolvedTokens),
      tier = selector.tier(normalizedSelector),
    }

    rules[#rules + 1] = rule

    if not normalizedSelector.state then
      if normalizedSelector.component then
        local bucket = index.component[normalizedSelector.component]

        if not bucket then
          bucket = {}
          index.component[normalizedSelector.component] = bucket
        end

        bucket[#bucket + 1] = rule
      else
        index.generic[#index.generic + 1] = rule
      end
    else
      local stateIndex = index.state[normalizedSelector.state]

      if not stateIndex then
        stateIndex = { generic = {}, component = {} }
        index.state[normalizedSelector.state] = stateIndex
      end

      if normalizedSelector.component then
        local componentStateRules = stateIndex.component[normalizedSelector.component]

        if not componentStateRules then
          componentStateRules = {}
          stateIndex.component[normalizedSelector.component] = componentStateRules
        end

        componentStateRules[#componentStateRules + 1] = rule
      else
        stateIndex.generic[#stateIndex.generic + 1] = rule
      end
    end
  end

  sortBuckets(index)

  nextThemeId = nextThemeId + 1
  local theme, tokenCache =
    {
      [Marker] = true,
      id = nextThemeId,
      name = spec.name or sourceName,
      parent = parent,
      _rawTokens = rawTokens,
      _rawChrome = rawChrome,
      _rawRules = rawRules,
      _tokens = resolvedTokens,
      _rules = rules,
      _index = index,
    }, {}

  ---@param path string
  ---@return H3UI.TokenValue
  function theme.token(path)
    local cached = tokenCache[path]

    if cached == nil then
      cached = token.lookup(resolvedTokens, path)
      tokenCache[path] = cached
    end

    return merge.copy(cached)
  end
  ---@param path string
  ---@return H3UI.TokenValue?, boolean
  function theme.findToken(path) return token.find(resolvedTokens, path) end
  ---@param value H3UI.TokenValue|H3UI.TokenReference
  ---@return H3UI.TokenValue
  function theme.resolve(value) return token.resolveValue(value, resolvedTokens) end
  ---@return H3UI.ChromeSpec
  function theme.chrome() return rawChrome end
  ---@return boolean
  function theme.hasChrome() return Next(rawChrome) ~= nil end

  return theme
end

---@param generic H3UI.CompiledThemeRule[]
---@param componentRules? H3UI.CompiledThemeRule[]
---@param componentRecord H3UI.ComponentRecord
---@param state? string
---@param visitor fun(rule: H3UI.CompiledThemeRule): nil
---@return nil
local function visitMatchingBuckets(generic, componentRules, componentRecord, state, visitor)
  componentRules = componentRules or {}

  local genericIndex = 1
  local componentIndex = 1
  local genericCount = #generic
  local componentCount = componentRules and #componentRules or 0

  while genericIndex <= genericCount or componentIndex <= componentCount do
    local rule
    if componentIndex > componentCount then
      rule = generic[genericIndex]
      genericIndex = genericIndex + 1
    elseif genericIndex > genericCount then
      rule = componentRules[componentIndex]
      componentIndex = componentIndex + 1
    elseif compareRules(generic[genericIndex], componentRules[componentIndex]) then
      rule = generic[genericIndex]
      genericIndex = genericIndex + 1
    else
      rule = componentRules[componentIndex]
      componentIndex = componentIndex + 1
    end

    if selector.matches(rule.selector, componentRecord, state) then visitor(rule) end
  end
end

---@param generic H3UI.CompiledThemeRule[]
---@param componentRules? H3UI.CompiledThemeRule[]
---@param componentRecord H3UI.ComponentRecord
---@param state? string
---@return H3UI.CompiledThemeRule[]
local function matchingBuckets(generic, componentRules, componentRecord, state)
  local matched = {}
  visitMatchingBuckets(
    generic,
    componentRules,
    componentRecord,
    state,
    ---@param rule H3UI.CompiledThemeRule
    ---@return nil
    function(rule) matched[#matched + 1] = rule end
  )

  return matched
end

---@param theme H3UI.Theme
---@param componentRecord H3UI.ComponentRecord
---@param state? string
---@param registry H3UI.Registry
---@param matched? H3UI.CompiledThemeRule[]
---@return H3UI.StyleMap
local function matchingStyles(theme, componentRecord, state, registry, matched)
  local styles, themeIndex = {}, nil

  if not state then
    themeIndex = theme._index
  else
    themeIndex = theme._index.state[state]

    if not themeIndex then return styles end
  end

  local generic = themeIndex.generic
  local componentRules = themeIndex.component[componentRecord.component]
  local genericIndex = 1
  local componentIndex = 1
  local genericCount = #generic
  local componentCount = componentRules and #componentRules or 0

  while genericIndex <= genericCount or componentIndex <= componentCount do
    local rule
    if componentIndex > componentCount then
      rule = generic[genericIndex]
      genericIndex = genericIndex + 1
    elseif genericIndex > genericCount then
      rule = componentRules[componentIndex]
      componentIndex = componentIndex + 1
    elseif compareRules(generic[genericIndex], componentRules[componentIndex]) then
      rule = generic[genericIndex]
      genericIndex = genericIndex + 1
    else
      rule = componentRules[componentIndex]
      componentIndex = componentIndex + 1
    end

    if selector.matches(rule.selector, componentRecord, state) then
      if matched then matched[#matched + 1] = rule end
      registry.validateSlot(componentRecord.component, rule.slot)
      local slotStyle = styles[rule.slot]
      if not slotStyle then
        slotStyle = {}
        styles[rule.slot] = slotStyle
      end
      merge.mergeInto(slotStyle, rule.style)
    end
  end

  return styles
end

---@param theme H3UI.Theme
---@param componentRecord H3UI.ComponentRecord
---@return H3UI.CompiledThemeRule[]
local function matching(theme, componentRecord)
  return matchingBuckets(
    theme._index.generic,
    theme._index.component[componentRecord.component],
    componentRecord
  )
end

---@param theme H3UI.Theme
---@param componentRecord H3UI.ComponentRecord
---@param state string
---@return H3UI.CompiledThemeRule[]
local function matchingState(theme, componentRecord, state)
  local stateIndex = theme._index.state[state]

  if not stateIndex then return {} end

  return matchingBuckets(
    stateIndex.generic,
    stateIndex.component[componentRecord.component],
    componentRecord,
    state
  )
end

---@param theme H3UI.Theme
---@param component string
---@param state string
---@return boolean
local function hasStateRules(theme, component, state)
  local stateIndex = theme._index.state[state]

  if not stateIndex then return false end

  return #stateIndex.generic > 0 or stateIndex.component[component] ~= nil
end

return {
  isTheme = isTheme,
  hasStateRules = hasStateRules,
  matching = matching,
  matchingState = matchingState,
  matchingStyles = matchingStyles,
  new = new,
}
