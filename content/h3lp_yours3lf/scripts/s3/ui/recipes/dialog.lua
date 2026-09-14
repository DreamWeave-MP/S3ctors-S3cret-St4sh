---@omw-context menu|player

local async = require 'openmw.async'
local merge = require 'scripts.s3.ui.merge'

local passthrough = {
  'name',
  'props',
  'titleProps',
  'external',
  'events',
  'userData',
  'template',
}

local function rootArgs(spec)
  local args = merge.shallowCopy(spec.args or {})
  for index = 1, #passthrough do
    local key = passthrough[index]
    if spec[key] ~= nil then args[key] = spec[key] end
  end
  if spec.title ~= nil then args.title = spec.title end
  return args
end

local function appendBody(ctx, target, body)
  if body == nil then return end

  if type(body) == 'string' or type(body) == 'number' then
    target[#target + 1] = ctx.component('text', {
      role = 'message',
      args = { text = tostring(body) },
    })
    return
  end

  if type(body) == 'table' and body[1] ~= nil then
    for index = 1, #body do target[#target + 1] = body[index] end
    return
  end

  target[#target + 1] = body
end

local function basic(ctx, spec)
  local children = {}
  appendBody(ctx, children, spec.body)
  appendBody(ctx, children, spec.content or spec.children)

  local args = rootArgs(spec)
  if #children > 0 then args.children = children end

  return ctx.component('dialog', {
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

local function actionCallback(spec, action)
  if action.onActivate then return action.onActivate end
  if action.role == 'confirm' then return spec.onConfirm end
  if action.role == 'cancel' then return spec.onCancel end
end

local function actionNode(ctx, spec, action, index)
  if type(action) == 'string' then action = { label = action } end
  assert(type(action) == 'table', 'H3 UI dialog action must be a string or table')

  local callback = actionCallback(spec, action)
  local events = merge.copy(action.events or {})
  local previousClick = events.mouseClick
  if callback then
    events.mouseClick = async:callback(function(event, layout)
      callback(action, layout)
      if previousClick then return previousClick(event, layout) end
      return true
    end)
  end

  local args = merge.shallowCopy(action.args or {})
  args.name = action.name or args.name or ('action_' .. tostring(index))
  args.label = action.label or args.label or action.role or ('Action ' .. tostring(index))
  if action.props ~= nil then args.props = action.props end
  if action.labelProps ~= nil then args.labelProps = action.labelProps end
  if action.external ~= nil then args.external = action.external end
  if action.userData ~= nil then args.userData = action.userData end
  if action.template ~= nil then args.template = action.template end
  if next(events) ~= nil then args.events = events end

  return ctx.component(action.component or 'button', {
    role = action.role or 'action',
    variant = action.variant,
    tone = action.tone,
    class = action.class,
    classes = action.classes,
    style = action.style,
    args = args,
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
      { role = 'confirm', tone = spec.confirmTone or spec.tone, label = spec.confirmLabel or 'Confirm' },
    }
  end

  if actions and #actions > 0 then
    local actionChildren = {}
    for index = 1, #actions do
      actionChildren[index] = actionNode(ctx, spec, actions[index], index)
    end
    children[#children + 1] = ctx.component('row', {
      role = 'actions',
      args = { children = actionChildren },
    })
  end

  local args = rootArgs(spec)
  if #children > 0 then args.children = children end

  return ctx.component('dialog', {
    role = 'root',
    variant = 'confirm',
    tone = spec.tone,
    density = spec.density,
    class = spec.class,
    classes = spec.classes,
    style = spec.style,
    args = args,
  })
end

return {
  basic = basic,
  confirm = confirm,
}
