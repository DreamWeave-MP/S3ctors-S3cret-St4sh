---@omw-context menu|player

local ui = require 'openmw.ui'

local Next, Type = next, type

local UiTexture, UiType = ui.texture, ui.TYPE

local EmptyOptions = {}
---Build an Image layout.
---Allocates fresh layout, props, and external tables. A texture options table passed as
---`resource` or `props.resource` is converted with `ui.texture`.
---@param options? H3.ImageOptions
---@return openmw.ui.Layout
local function image(options)
  options = options or EmptyOptions
  local props = {}
  if options.props then
    for key, value in Next, options.props do
      props[key] = value
    end
  end

  if options.resource then props.resource = options.resource end

  if Type(props.resource) == 'table' then
    local resource = props.resource
    ---@cast resource openmw.ui.TextureResourceOptions
    props.resource = UiTexture(resource)
  end
  if props.ignorePointerEvents == nil then props.ignorePointerEvents = not options.events end

  local external
  if options.external then
    external = {}
    for key, value in Next, options.external do
      external[key] = value
    end
  end

  return {
    type = UiType.Image,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
end

return image
