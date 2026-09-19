---@omw-context menu|player

local button = require 'scripts.h3.components.button'
local column = require 'scripts.h3.components.column'

local StrFormat = string.format

local EmptyContent = {}

---@param options H3.CollapsibleOptions
---@return openmw.ui.Layout
local function collapsible(options)
  local expanded = options.expanded == true
  local expandedPrefix = options.expandedPrefix or '- '
  local collapsedPrefix = options.collapsedPrefix or '+ '
  local onToggle = options.onToggle
  local body = options.content or options.children
  body = body or EmptyContent
  local bodyLayout
  local rootLayout
  local expandedLabel = StrFormat('%s%s', expandedPrefix, options.title)
  local collapsedLabel = StrFormat('%s%s', collapsedPrefix, options.title)

  ---@param layout openmw.ui.Layout
  ---@return openmw.ui.Layout
  local function labelLayout(layout)
    ---@type openmw.ui.Layout
    local result = layout.content[1]
    while result.content do
      result = result.content[1]
    end
    return result
  end

  ---@param nextExpanded boolean
  ---@param headerLayout openmw.ui.Layout
  ---@return nil
  local function setExpanded(nextExpanded, headerLayout)
    expanded = nextExpanded
    labelLayout(headerLayout).props.text = expanded and expandedLabel or collapsedLabel
    ---@type H3.CollapsibleContent
    local content = rootLayout.content
    if expanded then
      content:add(bodyLayout)
    else
      content.body = nil
    end
  end

  local header = button {
    name = 'header',
    label = expanded and expandedLabel or collapsedLabel,
    props = options.headerProps,
    labelProps = options.headerLabelProps,
    ---@param _ openmw.ui.MouseEvent
    ---@param headerLayout openmw.ui.Layout
    ---@return boolean
    onActivate = function(_, headerLayout)
      setExpanded(not expanded, headerLayout)
      if onToggle then onToggle(expanded) end
      return true
    end,
  }

  bodyLayout = column {
    name = 'body',
    children = body,
  }

  local children = { header }
  if expanded then children[#children + 1] = bodyLayout end

  rootLayout = column {
    name = options.name,
    props = options.props,
    external = options.external,
    userData = options.userData,
    events = options.events,
    children = children,
  }
  return rootLayout
end

return collapsible
