---@omw-context menu|player

local async = require 'openmw.async'

local button = require 'scripts.s3.components.button'
local column = require 'scripts.s3.components.column'

---@class H3.CollapsibleOptions
---@field title string
---@field expanded? boolean
---@field onToggle? fun(expanded: boolean)
---@field content? openmw.ui.Content|openmw.ui.Layout[]
---@field children? openmw.ui.Content|openmw.ui.Layout[]
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
  local body = options.content or options.children or {}
  local bodyLayout

  local function headerLabel()
    return (expanded and (options.expandedPrefix or '- ') or (options.collapsedPrefix or '+ '))
      .. options.title
  end

  local function setExpanded(nextExpanded, headerLayout)
    expanded = nextExpanded
    headerLayout.content[1].content[1].props.text = headerLabel()
    bodyLayout.props.visible = expanded
  end

  local header = button {
    name = 'header',
    label = headerLabel(),
    props = options.headerProps,
    labelProps = options.headerLabelProps,
    events = {
      mouseClick = async:callback(function(_, headerLayout)
        setExpanded(not expanded, headerLayout)
        if options.onToggle then options.onToggle(expanded) end
        return true
      end),
    },
  }

  bodyLayout = column {
    name = 'body',
    props = {
      visible = expanded,
    },
    children = body,
  }

  return column {
    name = options.name,
    props = options.props,
    external = options.external,
    userData = options.userData,
    events = options.events,
    children = { header, bodyLayout },
  }
end

return collapsible
