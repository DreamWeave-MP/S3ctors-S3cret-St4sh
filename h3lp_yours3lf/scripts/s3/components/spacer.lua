---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'
local v2 = util.vector2

---Options for building a spacer layout. Not an `openmw.ui.Layout`: `type` is set
---internally to `ui.TYPE.Widget`, and `layer`/`content` are not exposed.
---@class H3.SpacerOpts
---@field name? string Optional layout name for lookup from Content.
---@field props? table Optional widget properties (e.g. `size = v2(8, 8)`).
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
---  `spacer(8)`       -> `spacer({ props = { size = v2(8, 8) } })`  (square)
---  `spacer(8, 4)`    -> `spacer({ props = { size = v2(8, 4) } })` (width, height)
---@overload fun(size: number): openmw.ui.Layout
---@overload fun(w: number, h: number): openmw.ui.Layout
---@param opts? H3.SpacerOpts
---@return openmw.ui.Layout
local function spacer(opts, h)
    if type(opts) == 'number' then
        local w = opts
        opts = { props = { size = v2(w, h or w) } }
    else
        opts = opts or {}
    end
    local props = {}
    for key, value in pairs(opts.props or {}) do
        props[key] = value
    end
    local external = nil
    if opts.external then
        external = {}
        for key, value in pairs(opts.external) do
            external[key] = value
        end
    elseif opts.grow or opts.stretch then
        external = {
            grow = opts.grow,
            stretch = opts.stretch,
        }
    end
    return {
        type = ui.TYPE.Widget,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
    }
end

return spacer
