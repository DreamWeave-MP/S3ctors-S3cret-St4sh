---@omw-context menu|player
---@module 'scripts.s3.ui.spec'

local constants = require 'scripts.s3.ui.constants'
local constructors = require 'scripts.s3.ui.constructors'
local merge = require 'scripts.s3.ui.merge'
local token = require 'scripts.s3.ui.token'

local DOCUMENT_VERSION = 1
local OMIT = {}
local utilModule

local function openmwUtil()
  if utilModule == nil then utilModule = require 'openmw.util' end
  return utilModule
end

local MathHuge = math.huge

local runtimeOnlyKeys = {
  events = true,
  invalidate = true,
  template = true,
  userData = true,
}

local function assertConstructorOptions(kind, options)
  options = options or {}
  assert(merge.isPlainTable(options), 'H3 UI ' .. kind .. ' options must be a plain table')
  assert(
    options.component == nil and options.recipe == nil,
    'H3 UI ' .. kind .. ' options cannot select another component or recipe'
  )
  assert(options.args == nil, 'H3 UI args are flat; move fields out of args')
  assert(
    options.invalidate == nil,
    'H3 UI invalidation belongs to the scope, not individual components or recipes'
  )
  assert(
    options.density == nil,
    'H3 UI density was removed; style spacing explicitly or through theme rules'
  )
  assert(
    options.state == nil,
    'H3 UI instance state was removed; interactive state is component-owned'
  )
  return options
end

local function named(kind, name, options)
  assert(type(name) == 'string' and name ~= '', 'H3 UI ' .. kind .. ' name must be a string')
  options = assertConstructorOptions(kind, options)
  local result = {}
  local count = #options
  if count > 0 then
    assert(
      options.children == nil and options.content == nil,
      'H3 UI specs accept positional children or children/content, not both'
    )
    local children = {}
    for index = 1, count do children[index] = options[index] end
    result.children = children
  end
  for key, value in next, options do
    if type(key) ~= 'number' or key > count then result[key] = value end
  end
  result[kind] = name
  return result
end

local function component(name, options) return named('component', name, options) end
local function recipe(name, options) return named('recipe', name, options) end

local function isComponent(value)
  return merge.isPlainTable(value)
    and type(value.component) == 'string'
    and value.component ~= ''
    and value.recipe == nil
end

local function isRecipe(value)
  return merge.isPlainTable(value)
    and type(value.recipe) == 'string'
    and value.recipe ~= ''
    and value.component == nil
end

local function assertFinite(value, context)
  assert(
    value == value and value ~= MathHuge and value ~= -MathHuge,
    'H3 UI document cannot contain non-finite number' .. (context and ': ' .. context or '')
  )
  return value
end

local function safeGet(value, key)
  local ok, result = pcall(function() return value[key] end)
  return ok and result or nil
end

local function portableUserdata(value)
  local x = safeGet(value, 'x')
  local y = safeGet(value, 'y')
  if type(x) == 'number' and type(y) == 'number' then
    assertFinite(x, 'vector x')
    assertFinite(y, 'vector y')
    local z = safeGet(value, 'z')
    local w = safeGet(value, 'w')
    if type(w) == 'number' then
      assert(type(z) == 'number', 'H3 UI vector4 userdata requires z')
      assertFinite(z, 'vector z')
      assertFinite(w, 'vector w')
      return { __h3ui = 'vector4', x = x, y = y, z = z, w = w }
    end
    if type(z) == 'number' then
      assertFinite(z, 'vector z')
      return { __h3ui = 'vector3', x = x, y = y, z = z }
    end
    return { __h3ui = 'vector2', x = x, y = y }
  end

  local r = safeGet(value, 'r')
  local g = safeGet(value, 'g')
  local b = safeGet(value, 'b')
  if type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
    local a = safeGet(value, 'a')
    if type(a) ~= 'number' then a = 1 end
    assertFinite(r, 'color r')
    assertFinite(g, 'color g')
    assertFinite(b, 'color b')
    assertFinite(a, 'color a')
    return { __h3ui = 'color', r = r, g = g, b = b, a = a }
  end

  return OMIT
end

local portableValue

local function isRuntimeLayout(value)
  if isComponent(value) or isRecipe(value) then return false end
  if rawget(value, 'type') == nil then return false end
  return rawget(value, 'props') ~= nil
    or rawget(value, 'content') ~= nil
    or rawget(value, 'events') ~= nil
    or rawget(value, 'template') ~= nil
end

local function portableTable(value, active)
  if token.isRef(value) then return { __h3ui = 'token', path = value.path } end
  if constants.isUnset(value) then return { __h3ui = 'unset' } end
  assert(rawget(value, '__h3ui') == nil, 'H3 UI document field __h3ui is reserved')
  if active[value] then error 'H3 UI document cannot contain table cycles' end

  active[value] = true
  local result = {}
  local count = #value
  local isSpec = isComponent(value) or isRecipe(value)

  if not isSpec and merge.isArray(value) then
    for index = 1, count do
      local item = portableValue(value[index], active)
      if item ~= OMIT then result[#result + 1] = item end
    end
    active[value] = nil
    return result
  end

  if isSpec and count > 0 then
    assert(
      value.children == nil and value.content == nil,
      'H3 UI portable specs cannot mix positional children with children/content'
    )
    local children = {}
    for index = 1, count do
      local child = portableValue(value[index], active)
      if child ~= OMIT then children[#children + 1] = child end
    end
    if #children > 0 then result.children = children end
  end

  for key, item in next, value do
    if type(key) == 'string' then
      if runtimeOnlyKeys[key] then
        -- Runtime ownership never crosses the document boundary, including nested descriptors.
      elseif not (isSpec and key == 'children' and count > 0) then
        local portable = portableValue(item, active)
        if portable ~= OMIT then result[key] = portable end
      end
    elseif type(key) == 'number' and isSpec and key <= count then
      -- Positional spec children were canonicalized to `children` above.
    else
      error('H3 UI document maps require string keys: ' .. tostring(key))
    end
  end

  active[value] = nil
  return result
end

portableValue = function(value, active)
  local valueType = type(value)
  if value == nil or valueType == 'boolean' or valueType == 'string' then return value end
  if valueType == 'number' then return assertFinite(value) end
  if valueType == 'function' or valueType == 'thread' then return OMIT end
  if valueType == 'userdata' then return portableUserdata(value) end
  if valueType ~= 'table' then return OMIT end
  if not merge.isPlainTable(value) and not token.isRef(value) and not constants.isUnset(value) then
    return OMIT
  end
  if merge.isPlainTable(value) and isRuntimeLayout(value) then return OMIT end
  return portableTable(value, active)
end

local function portable(value)
  local result = portableValue(value, {})
  if result == OMIT then return nil end
  return result
end

local function document(root)
  assert(
    not (merge.isPlainTable(root) and root.h3ui ~= nil),
    'H3 UI document() expects a root spec, not an existing document'
  )
  assert(isComponent(root) or isRecipe(root), 'H3 UI document root must be a component or recipe spec')
  local portableRoot = portable(root)
  assert(portableRoot ~= nil, 'H3 UI document root is not portable')
  return {
    h3ui = DOCUMENT_VERSION,
    root = portableRoot,
  }
end

local function decode(value, active)
  local valueType = type(value)
  if valueType ~= 'table' then
    if value == nil or valueType == 'boolean' or valueType == 'string' then return value end
    if valueType == 'number' then return assertFinite(value) end
    error('H3 UI document contains unsupported value type: ' .. valueType)
  end
  assert(merge.isPlainTable(value), 'H3 UI document values must be plain tables')

  active = active or {}
  if active[value] then error 'H3 UI document cannot contain table cycles' end
  active[value] = true

  local tag = value.__h3ui
  if tag ~= nil then
    local result
    if tag == 'token' then
      assert(type(value.path) == 'string' and value.path ~= '', 'H3 UI token document tag requires path')
      result = token.ref(value.path)
    elseif tag == 'unset' then
      result = constants.UNSET
    elseif tag == 'vector2' then
      assert(type(value.x) == 'number' and type(value.y) == 'number', 'H3 UI vector2 document tag requires x/y')
      result = openmwUtil().vector2(assertFinite(value.x, 'vector x'), assertFinite(value.y, 'vector y'))
    elseif tag == 'vector3' then
      assert(
        type(value.x) == 'number' and type(value.y) == 'number' and type(value.z) == 'number',
        'H3 UI vector3 document tag requires x/y/z'
      )
      result = openmwUtil().vector3(
        assertFinite(value.x, 'vector x'),
        assertFinite(value.y, 'vector y'),
        assertFinite(value.z, 'vector z')
      )
    elseif tag == 'vector4' then
      assert(
        type(value.x) == 'number' and type(value.y) == 'number' and type(value.z) == 'number'
          and type(value.w) == 'number',
        'H3 UI vector4 document tag requires x/y/z/w'
      )
      result = openmwUtil().vector4(
        assertFinite(value.x, 'vector x'),
        assertFinite(value.y, 'vector y'),
        assertFinite(value.z, 'vector z'),
        assertFinite(value.w, 'vector w')
      )
    elseif tag == 'color' then
      assert(
        type(value.r) == 'number' and type(value.g) == 'number' and type(value.b) == 'number'
          and (value.a == nil or type(value.a) == 'number'),
        'H3 UI color document tag requires r/g/b and optional a'
      )
      result = openmwUtil().color.rgba(
        assertFinite(value.r, 'color r'),
        assertFinite(value.g, 'color g'),
        assertFinite(value.b, 'color b'),
        assertFinite(value.a or 1, 'color a')
      )
    else
      error('Unknown H3 UI document tag: ' .. tostring(tag))
    end
    active[value] = nil
    return result
  end

  local result = {}
  for key, item in next, value do
    assert(
      type(key) == 'string' or type(key) == 'number' and key >= 1 and key == math.floor(key),
      'H3 UI document keys must be strings or positive integer array indexes'
    )
    result[key] = decode(item, active)
  end
  active[value] = nil
  return result
end

local function deserialize(input)
  assert(merge.isPlainTable(input), 'H3 UI document must be a plain table')
  assert(input.h3ui == DOCUMENT_VERSION, 'Unsupported H3 UI document version: ' .. tostring(input.h3ui))
  assert(merge.isPlainTable(input.root), 'H3 UI document requires root')
  local result = decode(input.root)
  assert(isComponent(result) or isRecipe(result), 'H3 UI document root must be a component or recipe spec')
  return result
end

local function root(input)
  if merge.isPlainTable(input) and input.h3ui ~= nil then return deserialize(input) end
  return input
end

local function newScope(publicComponents, recipes)
  local scope = {}

  function scope.component(name, options) return component(name, options) end
  function scope.recipe(name, options) return recipe(name, options) end
  function scope.token(path) return token.ref(path) end

  constructors(
    scope,
    publicComponents or {},
    recipes or {},
    component,
    recipe
  )

  return scope
end

return {
  DOCUMENT_VERSION = DOCUMENT_VERSION,
  component = component,
  deserialize = deserialize,
  document = document,
  isComponent = isComponent,
  isRecipe = isRecipe,
  newScope = newScope,
  portable = portable,
  recipe = recipe,
  root = root,
}
