---@omw-context menu|player

local emptyOptions = {}
local spacer = require 'scripts.s3.components.spacer'
local ui = require 'openmw.ui'

local function collectChildren(options)
  local explicit = options.content or options.children
  if #options == 0 then return explicit end
  assert(explicit == nil, 'H3 row accepts array children or children/content, not both')
  local result = {}
  for index = 1, #options do
    result[index] = options[index]
  end
  return result
end

local function withGap(children, gap)
  if not children or #children < 2 or gap == nil or gap == 0 then return children end
  assert(type(gap) == 'number' and gap >= 0, 'H3 row gap must be a non-negative number')
  local result = {}
  for index = 1, #children do
    if index > 1 then result[#result + 1] = spacer(gap, 0) end
    result[#result + 1] = children[index]
  end
  return result
end

---@param options? table
---@return openmw.ui.Layout
local function row(options)
  options = options or emptyOptions
  local props = {}
  for key, value in next, options.props or {} do
    props[key] = value
  end
  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end
  props.horizontal = true
  local layout = {
    type = ui.TYPE.Flex,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
  local children = withGap(collectChildren(options), options.gap)
  if children then layout.content = ui.content(children) end
  return layout
end

return row
