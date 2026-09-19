---@omw-context menu|player

local ToString, Type = tostring, type

---@param spec H3UI.SectionOptions
---@return openmw.ui.Layout[]
local function contentChildren(spec)
  local content = spec.content or spec.children
  if content then
    if Type(content) == 'table' and content[1] then return content end
    return { content }
  end

  local result = {}
  for index = 1, #spec do
    result[index] = spec[index]
  end
  return result
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.SectionOptions
---@return openmw.ui.Layout
local function section(ctx, spec)
  local body = contentChildren(spec)
  local children = {}

  if spec.title or spec.secondary then
    local headerChildren = {
      ctx.text {
        role = 'title',
        text = spec.title or '',
        props = spec.titleProps,
        external = spec.secondary and { grow = 1 } or nil,
      },
    }
    if spec.secondary then
      headerChildren[#headerChildren + 1] = ctx.text {
        role = 'secondary',
        text = ToString(spec.secondary),
        props = spec.secondaryProps,
      }
    end
    children[#children + 1] = ctx.row {
      role = 'header',
      external = { stretch = 1 },
      gap = spec.headerGap or ctx.token 'spacing.sm',
      children = headerChildren,
    }
  end

  children[#children + 1] = ctx.divider { role = 'divider', props = spec.dividerProps }
  children[#children + 1] = ctx.column {
    role = 'body',
    props = spec.bodyProps,
    external = spec.bodyExternal or { stretch = 1 },
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
    external = spec.external or { stretch = 1 },
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
    gap = spec.gap or ctx.token 'spacing.sm',
    children = children,
  }
end

return section
