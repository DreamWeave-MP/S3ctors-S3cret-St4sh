---@omw-context menu|player
---@module 'scripts.h3.ui.spec'

local util = require 'openmw.util'

local constants = require 'scripts.h3.ui.constants'
local constructors = require 'scripts.h3.ui.constructors'
local merge = require 'scripts.h3.ui.merge'
local token = require 'scripts.h3.ui.token'

local Assert, Error, MathFloor, MathHuge, Next, RawGet, StrFormat, ToString, Type =
  assert, error, math.floor, math.huge, next, rawget, string.format, tostring, type

local ColorRGBA, UtilVector2, UtilVector3, UtilVector4 =
  util.color.rgba, util.vector2, util.vector3, util.vector4

local DOCUMENT_VERSION = 1

local RuntimeOnlyKeys = {
  events = true,
  invalidate = true,
  template = true,
  userData = true,
}

---@param kind string
---@param options? table
---@return table
local function assertConstructorOptions(kind, options)
  options = options or {}

  if not merge.isPlainTable(options) then
    Error(StrFormat('H3 UI %s options must be a plain table', kind))
  end

  if options.component ~= nil or options.recipe ~= nil then
    Error(StrFormat('H3 UI %s options cannot select another component or recipe', kind))
  end

  Assert(options.args == nil, 'H3 UI args are flat; move fields out of args')

  Assert(
    options.invalidate == nil,
    'H3 UI invalidation belongs to the scope, not individual components or recipes'
  )

  Assert(
    options.density == nil,
    'H3 UI density was removed; style spacing explicitly or through theme rules'
  )

  Assert(
    options.state == nil,
    'H3 UI instance state was removed; interactive state is component-owned'
  )

  return options
end

---@param kind 'component'|'recipe'
---@param name string
---@param options? table
---@return H3UI.Spec
local function named(kind, name, options)
  if Type(name) ~= 'string' or name == '' then
    Error(StrFormat('H3 UI %s name must be a string', kind))
  end

  options = assertConstructorOptions(kind, options)

  local result = {}
  local count = #options
  if count > 0 then
    Assert(
      options.children == nil and options.content == nil,
      'H3 UI specs accept positional children or children/content, not both'
    )

    local children = {}
    for index = 1, count do
      children[index] = options[index]
    end

    result.children = children
  end

  for key, value in Next, options do
    if Type(key) ~= 'number' or key > count then result[key] = value end
  end

  result[kind] = name

  return result
end

---@param name string
---@param options? table
---@return H3UI.Spec
local function component(name, options) return named('component', name, options) end
---@param name string
---@param options? table
---@return H3UI.Spec
local function recipe(name, options) return named('recipe', name, options) end

---@param value H3UI.LuaValue
---@return boolean
local function isComponent(value)
  if Type(value) ~= 'table' or not merge.isPlainTable(value) then return false end

  return Type(value.component) == 'string'
    and value.component ~= ''
    and value.recipe == nil
end

---@param value H3UI.LuaValue
---@return boolean
local function isRecipe(value)
  if Type(value) ~= 'table' or not merge.isPlainTable(value) then return false end

  return Type(value.recipe) == 'string'
    and value.recipe ~= ''
    and value.component == nil
end

---@param value number
---@param context? string
---@return number
local function assertFinite(value, context)
  Assert(
    value == value and value ~= MathHuge and value ~= -MathHuge,
    StrFormat(
      'H3 UI document cannot contain non-finite number%s',
      context and StrFormat(': %s', context) or ''
    )
  )

  return value
end

---@param value H3UI.SerializableUserdata
---@return table
local function portableUserdata(value)
  local typeInfo = value.__type
  local typeName = typeInfo and typeInfo.name

  if typeName == 'osg::Vec2f' then
    return {
      __h3ui = 'vector2',
      x = assertFinite(value.x, 'vector x'),
      y = assertFinite(value.y, 'vector y'),
    }
  end

  if typeName == 'osg::Vec3f' then
    return {
      __h3ui = 'vector3',
      x = assertFinite(value.x, 'vector x'),
      y = assertFinite(value.y, 'vector y'),
      z = assertFinite(value.z, 'vector z'),
    }
  end

  if typeName == 'osg::Vec4f' then
    return {
      __h3ui = 'vector4',
      x = assertFinite(value.x, 'vector x'),
      y = assertFinite(value.y, 'vector y'),
      z = assertFinite(value.z, 'vector z'),
      w = assertFinite(value.w, 'vector w'),
    }
  end

  if typeName == 'Misc::Color' then
    return {
      __h3ui = 'color',
      r = assertFinite(value.r, 'color r'),
      g = assertFinite(value.g, 'color g'),
      b = assertFinite(value.b, 'color b'),
      a = assertFinite(value.a, 'color a'),
    }
  end

  Error(StrFormat('H3 UI document cannot encode userdata type: %s', ToString(typeName)))
end

local portableValue

---@param value table
---@return boolean
local function isRuntimeLayout(value)
  if isComponent(value) or isRecipe(value) then return false end

  if not RawGet(value, 'type') then return false end

  return not not (
    RawGet(value, 'props')
    or RawGet(value, 'content')
    or RawGet(value, 'events')
    or RawGet(value, 'template')
  )
end

---@param value table
---@param active table<table, boolean?>
---@return table
local function portableTable(value, active)
  if token.isRef(value) then return { __h3ui = 'token', path = value.path } end

  if constants.isUnset(value) then return { __h3ui = 'unset' } end

  Assert(RawGet(value, '__h3ui') == nil, 'H3 UI document field __h3ui is reserved')

  if active[value] then Error 'H3 UI document cannot contain table cycles' end

  active[value] = true
  local result = {}
  local count = #value
  local isSpec = isComponent(value) or isRecipe(value)

  if not isSpec and merge.isArray(value) then
    for index = 1, count do
      result[#result + 1] = portableValue(value[index], active)
    end

    active[value] = nil

    return result
  end

  if isSpec and count > 0 then
    Assert(
      value.children == nil and value.content == nil,
      'H3 UI portable specs cannot mix positional children with children/content'
    )

    local children = {}
    for index = 1, count do
      children[#children + 1] = portableValue(value[index], active)
    end

    if #children > 0 then result.children = children end
  end

  for key, item in Next, value do
    if Type(key) == 'string' then
      if RuntimeOnlyKeys[key] then
        -- Runtime ownership never crosses the document boundary, including nested descriptors.
      elseif not (isSpec and key == 'children' and count > 0) then
        result[key] = portableValue(item, active)
      end
    elseif Type(key) == 'number' and isSpec and key <= count then
      -- Positional spec children were canonicalized to `children` above.
    else
      Error(StrFormat('H3 UI document maps require string keys: %s', ToString(key)))
    end
  end

  active[value] = nil

  return result
end

---@param value H3UI.DocumentInputValue
---@param active table<table, boolean?>
---@return H3UI.DocumentValue
portableValue = function(value, active)
  local valueType = Type(value)

  if not value or valueType == 'boolean' or valueType == 'string' then return value end
  if valueType == 'number' then return assertFinite(value) end
  if valueType == 'function' or valueType == 'thread' then
    Error(StrFormat('H3 UI document cannot encode value type: %s', valueType))
  end
  if valueType == 'userdata' then
    ---@cast value H3UI.SerializableUserdata
    return portableUserdata(value)
  end

  if valueType ~= 'table' then
    Error(StrFormat('H3 UI document cannot encode value type: %s', valueType))
  end

  if not merge.isPlainTable(value) and not token.isRef(value) and not constants.isUnset(value) then
    Error 'H3 UI document cannot encode non-plain tables'
  end

  if merge.isPlainTable(value) and isRuntimeLayout(value) then
    Error 'H3 UI document cannot encode runtime layouts'
  end

  return portableTable(value, active)
end

---@param value H3UI.DocumentValue
---@return H3UI.DocumentValue
local function portable(value) return portableValue(value, {}) end

---@param root H3UI.Spec
---@return H3UI.Document
local function document(root)
  Assert(
    not (merge.isPlainTable(root) and root.h3ui ~= nil),
    'H3 UI document() expects a root spec, not an existing document'
  )

  Assert(
    isComponent(root) or isRecipe(root),
    'H3 UI document root must be a component or recipe spec'
  )

  local portableRoot = portable(root)

  return {
    h3ui = DOCUMENT_VERSION,
    root = portableRoot,
  }
end

---@param value H3UI.DocumentValue
---@param active? table<table, boolean?>
---@return H3UI.DocumentValue
local function decode(value, active)
  local valueType = Type(value)
  if valueType ~= 'table' then
    if not value or valueType == 'boolean' or valueType == 'string' then return value end

    if valueType == 'number' then return assertFinite(value) end

    Error(StrFormat('H3 UI document contains unsupported value type: %s', valueType))
  end

  Assert(merge.isPlainTable(value), 'H3 UI document values must be plain tables')

  active = active or {}
  if active[value] then Error 'H3 UI document cannot contain table cycles' end
  active[value] = true

  local tag = value.__h3ui
  if tag ~= nil then
    local result

    if tag == 'token' then
      Assert(
        Type(value.path) == 'string' and value.path ~= '',
        'H3 UI token document tag requires path'
      )

      result = token.ref(value.path)
    elseif tag == 'unset' then
      result = constants.UNSET
    elseif tag == 'vector2' then
      Assert(
        Type(value.x) == 'number' and Type(value.y) == 'number',
        'H3 UI vector2 document tag requires x/y'
      )

      result = UtilVector2(assertFinite(value.x, 'vector x'), assertFinite(value.y, 'vector y'))
    elseif tag == 'vector3' then
      Assert(
        Type(value.x) == 'number' and Type(value.y) == 'number' and Type(value.z) == 'number',
        'H3 UI vector3 document tag requires x/y/z'
      )

      result = UtilVector3(
        assertFinite(value.x, 'vector x'),
        assertFinite(value.y, 'vector y'),
        assertFinite(value.z, 'vector z')
      )
    elseif tag == 'vector4' then
      Assert(
        Type(value.x) == 'number'
          and Type(value.y) == 'number'
          and Type(value.z) == 'number'
          and Type(value.w) == 'number',
        'H3 UI vector4 document tag requires x/y/z/w'
      )

      result = UtilVector4(
        assertFinite(value.x, 'vector x'),
        assertFinite(value.y, 'vector y'),
        assertFinite(value.z, 'vector z'),
        assertFinite(value.w, 'vector w')
      )
    elseif tag == 'color' then
      Assert(
        Type(value.r) == 'number'
          and Type(value.g) == 'number'
          and Type(value.b) == 'number'
          and (value.a == nil or Type(value.a) == 'number'),
        'H3 UI color document tag requires r/g/b and optional a'
      )

      result = ColorRGBA(
        assertFinite(value.r, 'color r'),
        assertFinite(value.g, 'color g'),
        assertFinite(value.b, 'color b'),
        assertFinite(value.a or 1, 'color a')
      )
    else
      Error(StrFormat('Unknown H3 UI document tag: %s', ToString(tag)))
    end

    active[value] = nil

    return result
  end

  local result = {}
  for key, item in Next, value do
    Assert(
      Type(key) == 'string' or Type(key) == 'number' and key >= 1 and key == MathFloor(key),
      'H3 UI document keys must be strings or positive integer array indexes'
    )

    result[key] = decode(item, active)
  end

  active[value] = nil

  return result
end

---@param input H3UI.Document
---@return H3UI.Spec
local function deserialize(input)
  Assert(merge.isPlainTable(input), 'H3 UI document must be a plain table')

  Assert(
    input.h3ui == DOCUMENT_VERSION,
    StrFormat('Unsupported H3 UI document version: %s', ToString(input.h3ui))
  )

  Assert(merge.isPlainTable(input.root), 'H3 UI document requires root')

  local result = decode(input.root)

  Assert(
    isComponent(result) or isRecipe(result),
    'H3 UI document root must be a component or recipe spec'
  )

  ---@cast result H3UI.Spec
  return result
end

---@param input H3UI.Spec|H3UI.Document
---@return H3UI.Spec
local function root(input)
  if merge.isPlainTable(input) and input.h3ui ~= nil then return deserialize(input) end
  return input
end

---@param publicComponents string[]
---@param recipes table<string, H3UI.Recipe>
---@return H3UI.SpecScope
local function newScope(publicComponents, recipes)
  local scope = {}

  ---@param name string
  ---@param options? table
  ---@return H3UI.Spec
  function scope.component(name, options) return component(name, options) end
  ---@param name string
  ---@param options? table
  ---@return H3UI.Spec
  function scope.recipe(name, options) return recipe(name, options) end
  ---@param path string
  ---@return H3UI.TokenReference
  function scope.token(path) return token.ref(path) end

  constructors(scope, publicComponents or {}, recipes or {}, component, recipe)

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
