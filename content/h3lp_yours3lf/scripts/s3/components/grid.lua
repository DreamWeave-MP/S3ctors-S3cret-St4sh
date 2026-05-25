---@omw-context menu|player

local ui = require 'openmw.ui'

---Build a grid as a vertical Flex of horizontal Flex rows.
---Allocates fresh layout, props, external, and content tables for the grid and each row. `items` are not
---copied; callers own child layout mutation and any mounted elements.
---@param opts? {items?: openmw.ui.Layout[], columns?: integer, name?: string, props?: table, rowProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function grid(opts)
    opts = opts or {}
    local columns = opts.columns or 1
    if columns < 1 then
        columns = 1
    end
    local rows = {}
    local row = nil
    for index, item in ipairs(opts.items or {}) do
        if (index - 1) % columns == 0 then
            local rowProps = {}
            for key, value in pairs(opts.rowProps or {}) do
                rowProps[key] = value
            end
            rowProps.horizontal = true
            row = { type = ui.TYPE.Flex, props = rowProps, content = ui.content({}) }
            rows[#rows + 1] = row
        end
        row.content:add(item)
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
    end
    props.horizontal = false
    return {
        type = ui.TYPE.Flex,
        name = opts.name,
        props = props,
        external = external,
        events = opts.events,
        userData = opts.userData,
        template = opts.template,
        content = ui.content(rows),
    }
end

return grid
