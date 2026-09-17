---@omw-context menu|player

---@class H3UI.SectionOptions
---@field title? string
---@field secondary? string|number
---@field content? openmw.ui.Layout|openmw.ui.Layout[]
---@field children? openmw.ui.Layout|openmw.ui.Layout[]
---@field gap? number
---@field headerGap? number
---@field titleProps? table
---@field secondaryProps? table
---@field dividerProps? table
---@field bodyProps? table
---@field bodyExternal? table
---@field variant? string
---@field tone? string
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field style? table
---@field name? string
---@field props? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

local function contentChildren(spec)
  local content = spec.content or spec.children
  if content ~= nil then
    if type(content) == 'table' and content[1] ~= nil then return content end
    return { content }
  end

  local result = {}
  for index = 1, #spec do
    result[index] = spec[index]
  end
  return result
end

local function section(ctx, spec)
  local body = contentChildren(spec)
  local children = {}

  if spec.title ~= nil or spec.secondary ~= nil then
    local headerChildren = {
      ctx.text {
        role = 'title',
        text = spec.title or '',
        props = spec.titleProps,
        external = spec.secondary ~= nil and { grow = 1 } or nil,
      },
    }
    if spec.secondary ~= nil then
      headerChildren[#headerChildren + 1] = ctx.text {
        role = 'secondary',
        text = tostring(spec.secondary),
        props = spec.secondaryProps,
      }
    end
    children[#children + 1] = ctx.row {
      role = 'header',
      gap = spec.headerGap or ctx.token 'spacing.sm',
      children = headerChildren,
    }
  end

  children[#children + 1] = ctx.divider { role = 'divider', props = spec.dividerProps }
  children[#children + 1] = ctx.column {
    role = 'body',
    props = spec.bodyProps,
    external = spec.bodyExternal,
    gap = spec.gap or ctx.token 'spacing.sm',
    children = body,
  }

  return ctx.column {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    name = spec.name,
    props = spec.props,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
    gap = spec.gap or ctx.token 'spacing.sm',
    children = children,
  }
end

return section
