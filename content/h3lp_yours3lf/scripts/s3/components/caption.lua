---@omw-context menu|player

local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local button = require 'scripts.s3.components.button'
local constants = require 'scripts.omw.mwui.constants'
local headBlock = require 'scripts.s3.components.headBlock'
local pinButton = require 'scripts.s3.components.pinButton'
local text = require 'scripts.s3.components.text'

local vector2 = util.vector2

local controlSize = vector2(19, 19)
local zero = vector2(0, 0)
local relativeWidth = vector2(1, 0)

---@class H3.CaptionOptions
---@field text? string
---@field pinnable? boolean
---@field pinned? boolean
---@field onPin? fun(pinned: boolean)
---@field closable? boolean
---@field onClose? fun()
---@field closeLabel? string
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field height? number
---@field textProps? table
---@field pinProps? table
---@field closeProps? table

---@param options? H3.CaptionOptions
---@return openmw.ui.Layout
local function caption(options)
    options = options or {}

    local height = options.height or 20
    local minimumHeight = (options.pinnable or options.closable) and controlSize.y or 4
    assert(height >= minimumHeight, 'Caption height is too small for its controls')

    local heightSize = vector2(0, height)
    local props = {}
    if options.props then
        for key, value in next, options.props do
            props[key] = value
        end
    end

    props.size = props.size or heightSize
    props.relativeSize = props.relativeSize or relativeWidth
    props.horizontal = true
    props.autoSize = false
    props.arrange = props.arrange or ui.ALIGNMENT.Center

    local textProps = {
        textSize = constants.textHeaderSize,
        textColor = constants.headerColor,
    }
    if options.textProps then
        for key, value in next, options.textProps do
            textProps[key] = value
        end
    end

    local function controlProps(input)
        local control = {}
        if input then
            for key, value in next, input do
                control[key] = value
            end
        end

        control.size = control.size or controlSize
        assert(control.size.y <= height, 'Caption control is taller than the caption')
        control.propagateEvents = false
        return control
    end

    local children = {
        headBlock {
            props = {
                size = heightSize,
                relativeSize = zero,
            },
            external = { grow = 1 },
            height = height,
        },
        text {
            name = 'text',
            text = options.text or '',
            props = textProps,
        },
        headBlock {
            props = {
                size = heightSize,
                relativeSize = zero,
            },
            external = { grow = 1 },
            height = height,
        },
    }

    if options.pinnable then
        children[#children + 1] = pinButton {
            name = 'pin',
            pinned = options.pinned,
            onToggle = options.onPin,
            props = controlProps(options.pinProps),
        }
    end

    if options.closable then
        local onClose = options.onClose
        children[#children + 1] = button {
            name = 'close',
            label = options.closeLabel or 'X',
            props = controlProps(options.closeProps),
            events = {
                mousePress = async:callback(function() end),
                mouseClick = async:callback(function()
                    if onClose then onClose() end
                end),
            },
        }
    end

    return {
        type = ui.TYPE.Flex,
        name = options.name,
        props = props,
        external = options.external,
        events = options.events,
        userData = options.userData,
        content = ui.content(children),
    }
end

return caption
