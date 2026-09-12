---@omw-context player

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local bookFrame = require 'scripts.s3.components.bookFrame'
local box = require 'scripts.s3.components.box'
local button = require 'scripts.s3.components.button'
local collapsible = require 'scripts.s3.components.collapsible'
local column = require 'scripts.s3.components.column'
local constants = require 'scripts.omw.mwui.constants'
local grid = require 'scripts.s3.components.grid'
local iconButton = require 'scripts.s3.components.iconButton'
local image = require 'scripts.s3.components.image'
local itemSlot = require 'scripts.s3.components.itemSlot'
local list = require 'scripts.s3.components.list'
local listItem = require 'scripts.s3.components.listItem'
local meter = require 'scripts.s3.components.meter'
local numberInput = require 'scripts.s3.components.numberInput'
local row = require 'scripts.s3.components.row'
local searchInput = require 'scripts.s3.components.searchInput'
local select = require 'scripts.s3.components.select'
local slider = require 'scripts.s3.components.slider'
local spacer = require 'scripts.s3.components.spacer'
local tabs = require 'scripts.s3.components.tabs'
local text = require 'scripts.s3.components.text'
local textInput = require 'scripts.s3.components.textInput'
local toggle = require 'scripts.s3.components.toggle'
local tooltip = require 'scripts.s3.components.tooltip'
local widget = require 'scripts.s3.components.widget'
local window = require 'scripts.s3.components.window'

local vector2 = util.vector2

local whiteTexture = constants.whiteTexture
local markerTexture = ui.texture { path = 'textures/menu_map_smark.dds' }
local leftArrowTexture = ui.texture { path = 'textures/omw_menu_scroll_left.dds' }

local sectionGapSize = vector2(0, 4)
local horizontalGapSize = vector2(8, 0)
local verticalGapSize = vector2(0, 8)
local fullSize = vector2(1, 1)
local markerSize = vector2(20, 20)
local swatchSize = vector2(24, 24)
local textInputSize = vector2(180, 24)
local smallIconSize = vector2(14, 14)
local meterSize = vector2(150, 18)
local sliderSize = vector2(160, 18)
local itemIconSize = vector2(28, 28)
local defaultPosition = vector2(80, 80)
local defaultSize = vector2(760, 720)

local swatchColor = util.color.rgb(0.30, 0.42, 0.72)
local meterFillColor = util.color.rgb(0.15, 0.65, 0.25)
local meterEmptyColor = util.color.rgb(0.18, 0.12, 0.12)
local slotTint = util.color.rgb(0.72, 0.48, 0.18)

local selectItems = { 'One', 'Two', 'Three' }
local tabItems = { 'First', 'Second', 'Third' }
local normalTextProps = {
    textColor = constants.normalColor,
    textSize = constants.textNormalSize,
}
local headerTextProps = {
    textColor = constants.headerColor,
    textSize = constants.textHeaderSize,
}

---@class H3ComponentTest.Options
---@field layer? string Root UI layer. Defaults to `Windows` for in-game console use.
---@field replace? boolean Destroy an existing owned root before creating a new one.
---@field position? openmw.util.Vector2 Optional root window position.
---@field size? openmw.util.Vector2 Optional root window size.

---@class openmw.interfaces.H3ComponentTest
---@field makeLayout fun(options?: H3ComponentTest.Options): openmw.ui.Layout
---@field create fun(options?: H3ComponentTest.Options): openmw.ui.Element
---@field destroy fun(): boolean
---@field toggle fun(options?: H3ComponentTest.Options): boolean
---@field isOpen fun(): boolean

---@class openmw.interfaces
---@field H3ComponentTest? openmw.interfaces.H3ComponentTest

---@type openmw.ui.Element|nil
local rootElement
---@type openmw.ui.Element|nil
local bodyElement
---@type fun(element: openmw.ui.Element)|nil
local elementUpdate
local rootDirty = false
local bodyDirty = false

local function isOpen() return rootElement ~= nil and rootElement.layout ~= nil end

local function destroy()
    local wasOpen = isOpen()

    if rootElement and rootElement.layout then rootElement:destroy() end
    rootElement = nil
    rootDirty = false

    if bodyElement and bodyElement.layout then bodyElement:destroy() end
    bodyElement = nil
    bodyDirty = false

    return wasOpen
end

local function notify(label)
    if isOpen() then ui.showMessage('H3 component test: ' .. label) end
end

local function updateElement(element)
    if not elementUpdate then elementUpdate = element.update end
    elementUpdate(element)
end

local function refreshRoot() rootDirty = true end

local function refreshBody()
    if bodyElement and bodyElement.layout then
        bodyDirty = true
    else
        rootDirty = true
    end
end

local function flushUpdates()
    if rootDirty then
        rootDirty = false
        local element = rootElement
        if element and element.layout then updateElement(element) end
    end

    if bodyDirty then
        bodyDirty = false
        local element = bodyElement
        if element and element.layout then updateElement(element) end
    end
end

local function section(id, title, children)
    return box {
        name = 'ct_box_' .. id,
        children = {
            column {
                name = 'ct_column_' .. id,
                children = {
                    text { name = 'ct_text_' .. id, text = title, props = headerTextProps },
                    spacer { name = 'ct_spacer_' .. id, props = { size = sectionGapSize } },
                    column { name = 'ct_section_body_' .. id, children = children },
                },
            },
        },
    }
end

local function newState()
    return {
        expanded = true,
        number = 5,
        search = 'search',
        selected = 1,
        slider = 50,
        tabs = 1,
        toggle = true,
    }
end

local function makeBodyLayout(state)
    return column {
        name = 'ct_body_column',
        children = {
            row {
                name = 'ct_header_row',
                children = {
                    image {
                        name = 'ct_image_marker',
                        resource = markerTexture,
                        props = { size = markerSize },
                    },
                    spacer { name = 'ct_header_gap', props = { size = horizontalGapSize } },
                    text {
                        name = 'ct_header_text',
                        text = 'Manual player-context smoke layout for every H3 UI component.',
                        props = normalTextProps,
                    },
                },
            },

            spacer { name = 'ct_after_header_spacer', props = { size = verticalGapSize } },

            section('primitives', 'Primitives', {
                row {
                    name = 'ct_primitives_row',
                    children = {
                        widget {
                            name = 'ct_widget_swatch',
                            props = {
                                size = swatchSize,
                            },
                            children = {
                                image {
                                    name = 'ct_widget_image_fill',
                                    resource = whiteTexture,
                                    props = {
                                        relativeSize = fullSize,
                                        color = swatchColor,
                                    },
                                },
                            },
                        },
                        spacer { name = 'ct_primitive_gap_a', props = { size = horizontalGapSize } },
                        text {
                            name = 'ct_primitive_text',
                            text = 'widget + image + text',
                            props = normalTextProps,
                        },
                    },
                },
                textInput {
                    name = 'ct_text_input',
                    text = 'edit me',
                    props = {
                        size = textInputSize,
                        textColor = constants.normalColor,
                        textSize = constants.textNormalSize,
                    },
                    events = {
                        textChanged = async:callback(function()
                            -- Deliberately no persistence; this just verifies callback plumbing.
                        end),
                        focusLoss = async:callback(function() notify 'text input focus lost' end),
                    },
                },
            }),

            spacer { name = 'ct_mid_spacer_a', props = { size = verticalGapSize } },

            section('actions', 'Actions and meters', {
                row {
                    name = 'ct_actions_row',
                    children = {
                        button {
                            name = 'ct_button_notify',
                            label = 'Button',
                            labelProps = normalTextProps,
                            events = {
                                mouseClick = async:callback(function() notify 'button clicked' end),
                            },
                        },
                        spacer { name = 'ct_action_gap_a', props = { size = horizontalGapSize } },
                        iconButton {
                            name = 'ct_icon_button_notify',
                            label = 'Icon',
                            resource = leftArrowTexture,
                            iconProps = { size = smallIconSize },
                            labelProps = normalTextProps,
                            events = {
                                mouseClick = async:callback(
                                    function() notify 'icon button clicked' end
                                ),
                            },
                        },
                        spacer { name = 'ct_action_gap_b', props = { size = horizontalGapSize } },
                        meter {
                            name = 'ct_meter_demo',
                            value = 67,
                            max = 100,
                            props = { size = meterSize },
                            fillProps = { color = meterFillColor },
                            emptyProps = { color = meterEmptyColor },
                        },
                    },
                },
            }),

            spacer { name = 'ct_mid_spacer_interactive', props = { size = verticalGapSize } },

            section('interactive', 'Interactive controls', {
                row {
                    name = 'ct_interactive_row',
                    children = {
                        toggle {
                            name = 'ct_toggle',
                            value = state.toggle,
                            onChange = function(value)
                                state.toggle = value
                                notify('toggle changed to ' .. tostring(value))
                                refreshBody()
                            end,
                        },
                        spacer {
                            name = 'ct_interactive_gap_a',
                            props = { size = horizontalGapSize },
                        },
                        slider {
                            name = 'ct_slider',
                            value = state.slider,
                            min = 0,
                            max = 100,
                            step = 5,
                            props = { size = sliderSize },
                            onChange = function(value)
                                state.slider = value
                                notify('slider changed to ' .. tostring(value))
                                refreshBody()
                            end,
                        },
                        spacer {
                            name = 'ct_interactive_gap_b',
                            props = { size = horizontalGapSize },
                        },
                        select {
                            name = 'ct_select',
                            items = selectItems,
                            selected = state.selected,
                            onSelect = function(index)
                                state.selected = index
                                notify('selected item ' .. tostring(index))
                                refreshBody()
                            end,
                        },
                    },
                },
                tabs {
                    name = 'ct_tabs',
                    items = tabItems,
                    selected = state.tabs,
                    onSelect = function(index)
                        state.tabs = index
                        notify('selected tab ' .. tostring(index))
                        refreshBody()
                    end,
                },
                collapsible {
                    name = 'ct_collapsible',
                    title = 'Details',
                    expanded = state.expanded,
                    onToggle = function(expanded)
                        state.expanded = expanded
                        notify('collapsible ' .. tostring(expanded))
                        refreshBody()
                    end,
                    children = {
                        text {
                            name = 'ct_collapsible_text',
                            text = 'Disclosure content.',
                            props = normalTextProps,
                        },
                    },
                },
                numberInput {
                    name = 'ct_number_input',
                    value = state.number,
                    min = 0,
                    max = 10,
                    step = 1,
                    integer = true,
                    onChange = function(value)
                        state.number = value
                        notify('number input changed to ' .. tostring(value))
                    end,
                    onCommit = refreshBody,
                },
                searchInput {
                    name = 'ct_search_input',
                    value = state.search,
                    onChange = function(value)
                        state.search = value
                        notify('search input changed to ' .. value)
                        refreshBody()
                    end,
                },
            }),

            spacer { name = 'ct_mid_spacer_b', props = { size = verticalGapSize } },

            row {
                name = 'ct_lists_and_frames_row',
                children = {
                    section('list', 'List', {
                        list {
                            name = 'ct_list_demo',
                            items = {
                                listItem { name = 'ct_list_item_one', label = 'listItem one' },
                                listItem { name = 'ct_list_item_two', label = 'listItem two' },
                                listItem { name = 'ct_list_item_three', label = 'listItem three' },
                            },
                        },
                    }),
                    spacer { name = 'ct_between_columns_gap', props = { size = horizontalGapSize } },
                    section('grid', 'Grid and item slots', {
                        grid {
                            name = 'ct_grid_demo',
                            columns = 3,
                            items = {
                                itemSlot {
                                    name = 'ct_item_slot_one',
                                    resource = markerTexture,
                                    count = 1,
                                    iconProps = { size = itemIconSize },
                                },
                                itemSlot {
                                    name = 'ct_item_slot_two',
                                    resource = whiteTexture,
                                    count = 2,
                                    iconProps = { size = itemIconSize, color = slotTint },
                                },
                                itemSlot {
                                    name = 'ct_item_slot_three',
                                    resource = leftArrowTexture,
                                    count = 3,
                                    iconProps = { size = itemIconSize },
                                },
                            },
                        },
                    }),
                },
            },

            spacer { name = 'ct_mid_spacer_c', props = { size = verticalGapSize } },

            bookFrame {
                name = 'ct_book_frame_demo',
                title = 'bookFrame + tooltip',
                children = {
                    tooltip {
                        name = 'ct_tooltip_demo',
                        text = 'Tooltip layout demo; not cursor-attached in this test interface.',
                    },
                },
            },

            spacer { name = 'ct_before_footer_spacer', props = { size = verticalGapSize } },

            row {
                name = 'ct_footer_row',
                children = {
                    spacer { name = 'ct_footer_grow', grow = 1 },
                    button {
                        name = 'ct_close_button',
                        label = 'Destroy',
                        events = {
                            mouseClick = async:callback(
                                function() async:newUnsavableSimulationTimer(0, destroy) end
                            ),
                        },
                    },
                },
            },
        },
    }
end

local function makeWindowLayout(options, body)
    -- The body is a child Element in create(); keep live resize updates on the window shell.
    local resizeDirty = false

    local function finishResize()
        if not resizeDirty then return end
        resizeDirty = false
        refreshBody()
    end

    local root = window {
        name = 'ct_root_window',
        title = 'H3 Component Test',
        props = {
            position = options.position or defaultPosition,
            size = options.size or defaultSize,
        },
        movable = true,
        resizable = true,
        closable = true,
        pinnable = true,
        onMove = refreshRoot,
        onResize = function()
            resizeDirty = true
            refreshRoot()
        end,
        onClose = function()
            notify 'window closed'
            async:newUnsavableSimulationTimer(0, destroy)
        end,
        onPin = function(pinned)
            notify('window pinned ' .. tostring(pinned))
            refreshRoot()
        end,
        events = {
            mouseRelease = async:callback(finishResize),
            focusLoss = async:callback(finishResize),
        },
        children = { body },
    }

    root.layer = options.layer or 'Windows'
    return root
end

local function makeLayout(options)
    options = options or {}
    return makeWindowLayout(options, makeBodyLayout(newState()))
end

local function create(options)
    options = options or {}
    if isOpen() then
        if options.replace ~= true then return rootElement end
        destroy()
    end

    local state = newState()
    -- Element:update() does not lay out child Elements, so this keeps drag/resize off the heavy test tree.
    bodyElement = ui.create(makeBodyLayout(state), { noWarnUnused = true })
    rootElement = ui.create(makeWindowLayout(options, bodyElement))
    return rootElement
end

local function toggle(options)
    if isOpen() then
        destroy()
        return false
    end

    create(options)
    return true
end

---@type openmw.interfaces.H3ComponentTest
local interface = {
    makeLayout = makeLayout,
    create = create,
    destroy = destroy,
    toggle = toggle,
    isOpen = isOpen,
}

return {
    interfaceName = 'H3ComponentTest',
    interface = interface,
    engineHandlers = {
        onFrame = flushUpdates,
    },
}
