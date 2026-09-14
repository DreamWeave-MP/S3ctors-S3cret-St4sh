---@omw-context menu|player

local merge = require 'scripts.s3.ui.merge'

local windowKeys = {
  'title',
  'position',
  'size',
  'minSize',
  'maxSize',
  'movable',
  'resizable',
  'closable',
  'pinnable',
  'pinned',
  'onMove',
  'onResize',
  'onClose',
  'onPin',
  'clampToScreen',
  'referenceSize',
  'captionHeight',
  'resizeHandle',
  'name',
  'props',
  'external',
  'events',
  'userData',
  'captionProps',
  'template',
}

local function tabbedWindow(ctx, spec)
  local tabsArgs = merge.shallowCopy(spec.tabsArgs or {})
  tabsArgs.items = spec.tabs or spec.items or tabsArgs.items
  if spec.selected ~= nil then tabsArgs.selected = spec.selected end
  if spec.onSelect ~= nil then tabsArgs.onSelect = spec.onSelect end
  if spec.tabProps ~= nil then tabsArgs.props = spec.tabProps end

  local children = {
    ctx.component('tabs', {
      role = 'tabs',
      style = spec.tabsStyle,
      args = tabsArgs,
    }),
  }

  local page = spec.page or spec.content or spec.children
  if page ~= nil then
    if type(page) == 'table' and page[1] ~= nil then
      for index = 1, #page do children[#children + 1] = page[index] end
    else
      children[#children + 1] = page
    end
  end

  local body = ctx.component('column', {
    role = 'body',
    style = spec.bodyStyle,
    args = {
      props = spec.bodyProps,
      external = spec.bodyExternal,
      children = children,
    },
  })

  local args = merge.shallowCopy(spec.args or {})
  for index = 1, #windowKeys do
    local key = windowKeys[index]
    if spec[key] ~= nil then args[key] = spec[key] end
  end
  args.children = { body }

  return ctx.component('window', {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    density = spec.density,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    args = args,
  })
end

return tabbedWindow
