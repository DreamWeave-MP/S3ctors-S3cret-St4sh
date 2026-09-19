---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'
local selector = require 'scripts.s3.ui.selector'
local token = require 'scripts.s3.ui.token'

local marker = {}
local nextThemeId = 0

local function isTheme(value) return type(value) == 'table' and rawget(value, marker) == true end

local function normalizeRawRule(input, source)
  assert(merge.isPlainTable(input), 'H3 UI theme rule must be a plain table')
  assert(input.style ~= nil, 'H3 UI theme rule requires style')
  assert(merge.isPlainTable(input.style), 'H3 UI theme rule style must be a plain table')

  return {
    selector = merge.copy(input.selector or {}),
    style = merge.copy(input.style),
    source = input.source or source,
  }
end

local function validateSelector(registry, ruleSelector)
  if ruleSelector.component ~= nil then
    registry.get(ruleSelector.component)
    if ruleSelector.slot ~= nil then
      registry.validateSlot(ruleSelector.component, ruleSelector.slot)
    end
  end
end

local function compareRules(left, right)
  if left.tier ~= right.tier then return left.tier < right.tier end
  if left.specificity ~= right.specificity then return left.specificity < right.specificity end
  return left.order < right.order
end

local function sortBuckets(index)
  table.sort(index.generic, compareRules)
  for _, bucket in next, index.component do
    table.sort(bucket, compareRules)
  end
  for _, stateIndex in next, index.state do
    table.sort(stateIndex.generic, compareRules)
    for _, bucket in next, stateIndex.component do
      table.sort(bucket, compareRules)
    end
  end
end

---@param spec H3UI.ThemeSpec
---@param registry table
---@param inheritedParent? H3UI.Theme
---@return H3UI.Theme
local function new(spec, registry, inheritedParent)
  spec = spec or {}
  assert(merge.isPlainTable(spec), 'H3 UI theme must be a plain table')

  local parent = spec.extends or inheritedParent
  if parent ~= nil then
    assert(isTheme(parent), 'H3 UI theme extends must be another compiled theme')
  end

  local rawTokens = parent and merge.copy(parent._rawTokens) or {}
  if spec.tokens ~= nil then
    assert(merge.isPlainTable(spec.tokens), 'H3 UI theme tokens must be a plain table')
    merge.mergeInto(rawTokens, spec.tokens)
  end

  local rawRules = {}
  if parent then
    for index = 1, #parent._rawRules do
      rawRules[#rawRules + 1] = merge.copy(parent._rawRules[index])
    end
  end

  local sourceName = spec.name or ('theme#' .. tostring(nextThemeId + 1))
  if spec.rules ~= nil then
    assert(
      merge.isPlainTable(spec.rules) and (next(spec.rules) == nil or merge.isArray(spec.rules)),
      'H3 UI theme rules must be a dense array'
    )
    for index = 1, #spec.rules do
      rawRules[#rawRules + 1] = normalizeRawRule(spec.rules[index], sourceName)
    end
  end

  local resolvedTokens = token.resolveTree(rawTokens)
  local rawChrome = parent and merge.copy(parent._rawChrome) or {}
  if spec.chrome ~= nil then
    assert(merge.isPlainTable(spec.chrome), 'H3 UI theme chrome must be a plain table')
    merge.mergeInto(rawChrome, spec.chrome)
  end
  local rules = {}
  local index = {
    generic = {},
    component = {},
    state = {},
  }

  for order = 1, #rawRules do
    local rawRule = rawRules[order]
    local normalizedSelector = selector.normalize(rawRule.selector)
    validateSelector(registry, normalizedSelector)

    local rule = {
      selector = normalizedSelector,
      slot = normalizedSelector.slot or 'root',
      style = token.resolveValue(rawRule.style, resolvedTokens),
      tier = selector.tier(normalizedSelector),
      specificity = selector.specificity(normalizedSelector),
      order = order,
      source = rawRule.source,
    }
    rules[#rules + 1] = rule

    if normalizedSelector.state == nil then
      if normalizedSelector.component ~= nil then
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
      if normalizedSelector.component ~= nil then
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
  local tokenCache = {}
  local theme = {
    [marker] = true,
    id = nextThemeId,
    name = spec.name or sourceName,
    parent = parent,
    _rawTokens = rawTokens,
    _rawChrome = rawChrome,
    _rawRules = rawRules,
    _tokens = resolvedTokens,
    _rules = rules,
    _index = index,
  }

  function theme.token(path)
    local cached = tokenCache[path]
    if cached == nil then
      cached = token.lookup(resolvedTokens, path)
      tokenCache[path] = cached
    end
    return merge.copy(cached)
  end
  function theme.resolve(value) return token.resolveValue(value, resolvedTokens) end
  function theme.chrome() return rawChrome end
  function theme.hasChrome() return next(rawChrome) ~= nil end

  return theme
end

local function matchingBuckets(generic, componentRules, componentRecord, state)
  local matched = {}
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

    if selector.matches(rule.selector, componentRecord, state) then matched[#matched + 1] = rule end
  end

  return matched
end

local function matching(theme, componentRecord)
  return matchingBuckets(
    theme._index.generic,
    theme._index.component[componentRecord.component],
    componentRecord
  )
end

local function matchingState(theme, componentRecord, state)
  local stateIndex = theme._index.state[state]
  if not stateIndex then return {} end
  return matchingBuckets(stateIndex.generic, stateIndex.component[componentRecord.component], componentRecord, state)
end

local function hasStateRules(theme, component, state)
  local stateIndex = theme._index.state[state]
  return stateIndex ~= nil and (#stateIndex.generic > 0 or stateIndex.component[component] ~= nil)
end

return {
  isTheme = isTheme,
  hasStateRules = hasStateRules,
  matching = matching,
  matchingState = matchingState,
  new = new,
}
