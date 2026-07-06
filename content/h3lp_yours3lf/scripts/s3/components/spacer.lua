---@omw-context menu|player

local ui = require 'openmw.ui'
local util = require 'openmw.util'
local v2 = util.vector2

---Build an empty Widget spacer layout.
---Allocates fresh layout, props, and external tables. The
---spacer has no lifetime beyond the returned layout until a caller mounts it.
---
---Shorthand: pass numbers to set `props.size` directly.
---  `spacer(8)`       -> `spacer({ props = { size = v2(8, 8) } })`  (square)
---  `spacer(8, 4)`    -> `spacer({ props = { size = v2(8, 4) } })` (width, height)
---@param opts? {name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template, grow?: number, stretch?: number}
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
