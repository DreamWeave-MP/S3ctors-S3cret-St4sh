---@omw-context menu|player

local emptyOptions = {}

local ui = require 'openmw.ui'

---Build an Image layout.
---Allocates fresh layout, props, and external tables. A texture options table passed as
---`resource` or `props.resource` is converted with `ui.texture`.
---@param options? {resource?: openmw.ui.TextureResource|openmw.ui.TextureResourceOptions, name?: string, props?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function image(options)
  options = options or emptyOptions
  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  if options.resource ~= nil then props.resource = options.resource end

  if type(props.resource) == 'table' then props.resource = ui.texture(props.resource) end
  if props.ignorePointerEvents == nil then props.ignorePointerEvents = options.events == nil end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  return {
    type = ui.TYPE.Image,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    template = options.template,
  }
end

return image
