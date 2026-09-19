---@omw-context menu|player

local Assert, StrFormat, ToString, Type = assert, string.format, tostring, type

---@param ctx H3UI.RecipeContext
---@param target openmw.ui.Layout[]
---@param body? H3UI.DialogBody
---@return nil
local function appendBody(ctx, target, body)
  if not body then return end
  if Type(body) == 'string' or Type(body) == 'number' then
    target[#target + 1] = ctx.text { role = 'message', text = ToString(body) }
    return
  end
  if Type(body) == 'table' and body[1] then
    for index = 1, #body do
      target[#target + 1] = body[index]
    end
    return
  end
  target[#target + 1] = body
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.DialogOptions
---@return openmw.ui.Layout
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

---@param spec H3UI.ConfirmDialogOptions
---@param action H3UI.DialogAction
---@return (fun(action: H3UI.DialogAction, layout: openmw.ui.Layout): boolean?)?
local function actionCallback(spec, action)
  if action.onActivate then return action.onActivate end
  if action.role == 'confirm' then return spec.onConfirm end
  if action.role == 'cancel' then return spec.onCancel end
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.ConfirmDialogOptions
---@param action string|H3UI.DialogAction
---@param index integer
---@return openmw.ui.Layout
local function actionLayout(ctx, spec, action, index)
  if Type(action) == 'string' then action = { label = action } end
  Assert(Type(action) == 'table', 'H3 UI dialog action must be a string or table')
  local callback = actionCallback(spec, action)
  return ctx.component(action.component or 'button', {
    role = action.role or 'action',
    variant = action.variant,
    tone = action.tone,
    class = action.class,
    classes = action.classes,
    style = action.style,
    name = action.name or StrFormat('action_%s', ToString(index)),
    label = action.label or action.role or StrFormat('Action %s', ToString(index)),
    props = action.props,
    labelProps = action.labelProps,
    external = action.external,
    events = action.events,
    userData = action.userData,
    template = action.template,
    onActivate = callback and
      ---@param _ openmw.ui.MouseEvent
      ---@param layout openmw.ui.Layout
      ---@return boolean?
      function(_, layout) return callback(action, layout) end or nil,
  })
end

---@param ctx H3UI.RecipeContext
---@param spec H3UI.ConfirmDialogOptions
---@return openmw.ui.Layout
local function confirm(ctx, spec)
  local children = {}
  appendBody(ctx, children, spec.body)
  appendBody(ctx, children, spec.content or spec.children)

  local actions = spec.actions
  if not actions and (spec.onCancel or spec.onConfirm) then
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
      actionChildren[index] = actionLayout(ctx, spec, actions[index], index)
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
