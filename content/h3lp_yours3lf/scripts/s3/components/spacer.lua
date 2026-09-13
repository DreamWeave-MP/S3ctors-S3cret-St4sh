---@omw-context menu|player

local emptyOptions = {}

local ui = require 'openmw.ui'
local util = require 'openmw.util'
local UtilVector2 = util.vector2

---Options for building a spacer layout. Not an `openmw.ui.Layout`: `type` is set
---internally to `ui.TYPE.Widget`, and `layer`/`content` are not exposed.
---@class H3.SpacerOptions
---@field name? string Optional layout name for lookup from Content.
---@field props? table Optional widget properties (e.g. `size = vector2(8, 8)`).
---@field external? table Optional external properties table. When present, takes precedence over `grow`/`stretch`.
---@field events? table Optional event callbacks table.
---@field userData? any Arbitrary user data attached to the returned layout.
---@field template? openmw.ui.Template Optional widget template.
---@field grow? number Convenience: if `external` is nil, sets `external.grow`. Ignored when `external` is provided.
---@field stretch? number Convenience: if `external` is nil, sets `external.stretch`. Ignored when `external` is provided.

---Build an empty Widget spacer layout.
---Allocates fresh layout, props, and external tables. The
---spacer has no lifetime beyond the returned layout until a caller mounts it.
---
---Shorthand: pass numbers to set `props.size` directly.
---  `spacer(8)`       -> `spacer({ props = { size = vector2(8, 8) } })`  (square)
---  `spacer(8, 4)`    -> `spacer({ props = { size = vector2(8, 4) } })` (width, height)
---@overload fun(size: number): openmw.ui.Layout
---@overload fun(w: number, h: number): openmw.ui.Layout
---@param options? H3.SpacerOptions
---@return openmw.ui.Layout
local function spacer(options, height)
  if type(options) == 'number' then
    local width = options
    options = { props = { size = UtilVector2(width, height or width) } }
  else
    options = options or emptyOptions
  end

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  elseif options.grow or options.stretch then
    external = {
      grow = options.grow,
      stretch = options.stretch,
    }
  end

  if props.ignorePointerEvents == nil then props.ignorePointerEvents = options.events == nil end

  return {
    type = ui.TYPE.Widget,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
end

return spacer
