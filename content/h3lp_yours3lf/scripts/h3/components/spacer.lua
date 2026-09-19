---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'

local Assert, Next, Type = assert, next, type

local UiType, UtilVector2 = ui.TYPE, util.vector2
local EmptyOptions = {}

---Options for building a spacer layout. Not an `openmw.ui.Layout`: `type` is set
---internally to `ui.TYPE.Widget`, and `layer`/`content` are not exposed.
---Build an empty Widget spacer layout.
---Allocates fresh layout, props, and external tables. The
---spacer has no lifetime beyond the returned layout until a caller mounts it.
---
---Shorthand: pass numbers to set `props.size` directly.
---  `spacer(8)`       -> `spacer({ props = { size = vector2(8, 8) } })`  (square)
---  `spacer(8, 4)`    -> `spacer({ props = { size = vector2(8, 4) } })` (width, height)
---@overload fun(size: number): openmw.ui.Layout
---@overload fun(w: number, h: number): openmw.ui.Layout
---@param options? H3.SpacerOptions|number
---@param height? number
---@return openmw.ui.Layout
local function spacer(options, height)
  if Type(options) == 'number' then
    local width = options
    local resolvedHeight = height or width

    Assert(width >= 0, 'H3 spacer width must be non-negative')
    Assert(
      Type(resolvedHeight) == 'number' and resolvedHeight >= 0,
      'H3 spacer height must be non-negative'
    )

    options = { props = { size = UtilVector2(width, resolvedHeight) } }
  else
    options = options or EmptyOptions
  end

  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  if not props.size and (options.width or options.height) then
    local width = options.width or 0
    local resolvedHeight = options.height or width

    Assert(Type(width) == 'number' and width >= 0, 'H3 spacer width must be non-negative')
    Assert(
      Type(resolvedHeight) == 'number' and resolvedHeight >= 0,
      'H3 spacer height must be non-negative'
    )

    props.size = UtilVector2(width, resolvedHeight)
  end

  local external
  if options.external then
    external = {}

    for key, value in Next, options.external do
      external[key] = value
    end
  elseif options.grow or options.stretch then
    external = {
      grow = options.grow,
      stretch = options.stretch,
    }
  end

  if props.ignorePointerEvents == nil then props.ignorePointerEvents = not options.events end

  return {
    type = UiType.Widget,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
end

return spacer
