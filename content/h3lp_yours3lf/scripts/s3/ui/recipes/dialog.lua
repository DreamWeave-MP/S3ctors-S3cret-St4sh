---@omw-context menu|player

---@class H3UI.DialogAction
---@field role? string
---@field label? string
---@field component? string
---@field variant? string
---@field tone? string
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field style? table
---@field name? string
---@field props? table
---@field labelProps? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template
---@field onActivate? fun(action: H3UI.DialogAction, layout: openmw.ui.Layout): any

---@class H3UI.DialogOptions
---@field title? string
---@field body? string|number|openmw.ui.Layout|openmw.ui.Layout[]
---@field content? openmw.ui.Layout|openmw.ui.Layout[]
---@field children? openmw.ui.Layout|openmw.ui.Layout[]
---@field variant? string
---@field tone? string
---@field class? string
---@field classes? string[]|table<string, boolean>
---@field style? table
---@field name? string
---@field props? table
---@field titleProps? table
---@field external? table
---@field events? table
---@field userData? any
---@field template? openmw.ui.Template

---@class H3UI.ConfirmDialogOptions: H3UI.DialogOptions
---@field actions? (string|H3UI.DialogAction)[]
---@field actionGap? number
---@field cancelLabel? string
---@field confirmLabel? string
---@field confirmTone? string
---@field onCancel? fun(action: H3UI.DialogAction, layout: openmw.ui.Layout): any
---@field onConfirm? fun(action: H3UI.DialogAction, layout: openmw.ui.Layout): any

local function appendBody(ctx, target, body)
  if body == nil then return end
  if type(body) == 'string' or type(body) == 'number' then
    target[#target + 1] = ctx.text { role = 'message', text = tostring(body) }
    return
  end
  if type(body) == 'table' and body[1] ~= nil then
    for index = 1, #body do
      target[#target + 1] = body[index]
    end
    return
  end
  target[#target + 1] = body
end

local function dialog(ctx, spec)
  local children = {}
  appendBody(ctx, children, spec.body)
  appendBody(ctx, children, spec.content or spec.children)
  return ctx.bookFrame {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    title = spec.title,
    name = spec.name,
    props = spec.props,
    titleProps = spec.titleProps,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
    children = children,
  }
end

local function actionCallback(spec, action)
  if action.onActivate then return action.onActivate end
  if action.role == 'confirm' then return spec.onConfirm end
  if action.role == 'cancel' then return spec.onCancel end
end

local function actionNode(ctx, spec, action, index)
  if type(action) == 'string' then action = { label = action } end
  assert(type(action) == 'table', 'H3 UI dialog action must be a string or table')
  local callback = actionCallback(spec, action)
  return ctx.component(action.component or 'button', {
    role = action.role or 'action',
    variant = action.variant,
    tone = action.tone,
    class = action.class,
    classes = action.classes,
    style = action.style,
    name = action.name or ('action_' .. tostring(index)),
    label = action.label or action.role or ('Action ' .. tostring(index)),
    props = action.props,
    labelProps = action.labelProps,
    external = action.external,
    events = action.events,
    userData = action.userData,
    template = action.template,
    onActivate = callback and function(_, layout) return callback(action, layout) end or nil,
  })
end

local function confirm(ctx, spec)
  local children = {}
  appendBody(ctx, children, spec.body)
  appendBody(ctx, children, spec.content or spec.children)

  local actions = spec.actions
  if actions == nil and (spec.onCancel or spec.onConfirm) then
    actions = {
      { role = 'cancel', label = spec.cancelLabel or 'Cancel' },
      {
        role = 'confirm',
        tone = spec.confirmTone or spec.tone,
        label = spec.confirmLabel or 'Confirm',
      },
    }
  end

  if actions and #actions > 0 then
    local actionChildren = {}
    for index = 1, #actions do
      actionChildren[index] = actionNode(ctx, spec, actions[index], index)
    end
    children[#children + 1] = ctx.row {
      role = 'actions',
      gap = spec.actionGap or ctx.token 'spacing.sm',
      children = actionChildren,
    }
  end

  return ctx.bookFrame {
    role = 'root',
    variant = spec.variant,
    tone = spec.tone,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    title = spec.title,
    name = spec.name,
    props = spec.props,
    titleProps = spec.titleProps,
    external = spec.external,
    events = spec.events,
    userData = spec.userData,
    template = spec.template,
    children = children,
  }
end

return { basic = dialog, confirm = confirm }
