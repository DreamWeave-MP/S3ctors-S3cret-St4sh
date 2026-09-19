---@omw-context menu|player

local emptyContent = {}

local button = require 'scripts.s3.components.button'
local column = require 'scripts.s3.components.column'

---@class H3.CollapsibleOptions
---@field title string
---@field expanded? boolean
---@field onToggle? fun(expanded: boolean)
---@field content? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field children? openmw.ui.Content|openmw.ui.LayoutOrElement[]
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field headerProps? table
---@field headerLabelProps? table
---@field expandedPrefix? string
---@field collapsedPrefix? string

---@param options H3.CollapsibleOptions
---@return openmw.ui.Layout
local function collapsible(options)
  local expanded = options.expanded == true
  local expandedPrefix = options.expandedPrefix or '- '
  local collapsedPrefix = options.collapsedPrefix or '+ '
  local onToggle = options.onToggle
  local body = options.content or options.children
  body = body or emptyContent
  local bodyLayout
  local rootLayout
  local expandedLabel = expandedPrefix .. options.title
  local collapsedLabel = collapsedPrefix .. options.title

  local function labelLayout(layout)
    local result = layout.content[1]
    while result.content do
      result = result.content[1]
    end
    return result
  end

  local function setExpanded(nextExpanded, headerLayout)
    expanded = nextExpanded
    labelLayout(headerLayout).props.text = expanded and expandedLabel or collapsedLabel
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
