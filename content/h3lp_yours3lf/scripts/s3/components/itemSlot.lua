---@omw-context menu|player

local emptyOptions = {}

local I = require 'openmw.interfaces'
local image = require 'scripts.s3.components.image'
local ui = require 'openmw.ui'

---Build a bordered item slot layout with optional icon and count label.
---Allocates fresh layout, props, external, and content tables. A texture options table passed as
---`resource` is converted by the image component; this primitive does not query game state or own any Element.
---@param options? {resource?: openmw.ui.TextureResource|openmw.ui.TextureResourceOptions, count?: string|number, name?: string, props?: table, iconProps?: table, countProps?: table, external?: table, events?: table, userData?: any, template?: openmw.ui.Template}
---@return openmw.ui.Layout
local function itemSlot(options)
  options = options or emptyOptions

  local iconProps = {}
  if options.iconProps then
    for key, value in next, options.iconProps do
      iconProps[key] = value
    end
  end

  if options.resource ~= nil then iconProps.resource = options.resource end
  iconProps.ignorePointerEvents = true

  local content = {
    image { name = 'icon', resource = options.resource, props = iconProps },
  }
  if options.count ~= nil then
    local countProps = {}
    if options.countProps then
      for key, value in next, options.countProps do
        countProps[key] = value
      end
    end

    countProps.text = tostring(options.count)
    countProps.ignorePointerEvents = true
    content[#content + 1] = {
      template = I.MWUI.templates.textNormal,
      props = countProps,
    }
  end

  local props = {}
  if options.props then
    for key, value in next, options.props do
      props[key] = value
    end
  end

  local external
  if options.external then
    external = {}
    for key, value in next, options.external do
      external[key] = value
    end
  end

  return {
    template = options.template or I.MWUI.templates.box,
    name = options.name,
    props = props,
    external = external,
    events = options.events,
    userData = options.userData,
    content = ui.content(content),
  }
end

return itemSlot
