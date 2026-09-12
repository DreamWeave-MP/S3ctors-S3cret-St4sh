---@omw-context menu|player

local async = require 'openmw.async'

local button = require 'scripts.s3.components.button'
local row = require 'scripts.s3.components.row'

local emptyItems = {}

---@class H3.TabItem
---@field label string
---@field value? any

---@class H3.TabsOptions
---@field items? (string|H3.TabItem)[]
---@field selected? number
---@field onSelect? fun(index: number, item: string|H3.TabItem)
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field buttonProps? table
---@field selectedProps? table
---@field labelProps? table
---@field selectedLabelProps? table
---@field selectedPrefix? string
---@field selectedSuffix? string

local function itemLabel(item)
    if type(item) == 'table' then return item.label end
    return item
end

local function mergeInto(target, base, overrides)
    for key in next, target do
        target[key] = nil
    end

    if base then
        for key, value in next, base do
            target[key] = value
        end
    end

    if overrides then
        for key, value in next, overrides do
            target[key] = value
        end
    end

    return target
end

---@param options? H3.TabsOptions
---@return openmw.ui.Layout
local function tabs(options)
    options = options or {}

    local items = options.items or emptyItems
    local selected = math.floor(options.selected or 1)
    selected = math.max(1, math.min(selected, math.max(#items, 1)))

    local selectedPrefix = options.selectedPrefix or '[ '
    local selectedSuffix = options.selectedSuffix or ' ]'
    local onSelect = options.onSelect
    local children = {}

    local function setTabState(layout, index, isSelected)
        local label = itemLabel(items[index])
        if isSelected then label = selectedPrefix .. label .. selectedSuffix end

        local labelLayout = layout.content[1].content[1]
        mergeInto(layout.props, options.buttonProps, isSelected and options.selectedProps or nil)
        mergeInto(
            labelLayout.props,
            options.labelProps,
            isSelected and options.selectedLabelProps or nil
        )
        labelLayout.props.text = label
    end

    for index = 1, #items do
        local item = items[index]
        local itemIndex = index
        local itemEvents = {
            mouseClick = async:callback(function(_, layout)
                if itemIndex == selected then return true end

                setTabState(children[selected], selected, false)
                selected = itemIndex
                setTabState(layout, itemIndex, true)

                if onSelect then onSelect(itemIndex, item) end
                return true
            end),
        }

        local label = itemLabel(item)
        if index == selected then label = selectedPrefix .. label .. selectedSuffix end

        children[index] = button {
            name = 'tab_' .. index,
            label = label,
            props = mergeInto(
                {},
                options.buttonProps,
                index == selected and options.selectedProps or nil
            ),
            labelProps = mergeInto(
                {},
                options.labelProps,
                index == selected and options.selectedLabelProps or nil
            ),
            events = itemEvents,
        }
    end

    return row {
        name = options.name,
        props = options.props,
        external = options.external,
        events = options.events,
        userData = options.userData,
        children = children,
    }
end

return tabs
