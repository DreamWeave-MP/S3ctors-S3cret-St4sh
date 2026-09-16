---@module 'scripts.s3.components.headBlock'
---@omw-context menu|player

local emptyOptions = {}

local appearance = require 'scripts.s3.ui.appearance'
local chrome = require 'scripts.s3.ui.chrome'
local util = require 'openmw.util'

local UtilVector2 = util.vector2

---@class H3.HeadBlockOptions
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field height? number

---@param options? H3.HeadBlockOptions
---@return openmw.ui.Layout
local function headBlock(options)
  options = options or emptyOptions

  local height = options.height or 20
  assert(height >= 4, 'HeadBlock height must be at least 4')

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  props.size = props.size or UtilVector2(0, height)
  props.relativeSize = props.relativeSize or UtilVector2(1, 0)

  return chrome.frame {
    skin = appearance.chrome 'caption',
    name = options.name,
    props = props,
    external = options.external,
    events = options.events,
    userData = options.userData,
    tint = appearance.token 'color.chromeBorder',
    alpha = appearance.token 'transparency.chrome',
  }
end

return headBlock
