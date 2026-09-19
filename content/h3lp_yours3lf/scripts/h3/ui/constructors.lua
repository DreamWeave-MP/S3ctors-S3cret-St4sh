---@omw-context menu|player

local Assert, Error, GetMetatable, Next, RawGet, SetMetatable, StrFormat, ToString, Type =
  assert, error, getmetatable, next, rawget, setmetatable, string.format, tostring, type

local WeakKeys = { __mode = 'k' }
local ComponentNameCache = SetMetatable({}, WeakKeys)

---@param options? table
---@return table?
local function positionalChildren(options)
  if Type(options) ~= 'table' then return options end

  local count = #options

  if count == 0 then return options end

  Assert(
    options.children == nil and options.content == nil,
    'H3 UI accepts positional children or children/content, not both'
  )

  local children, result = {}, {}

  for index = 1, count do
    children[index] = options[index]
  end

  for key, value in Next, options do
    if Type(key) ~= 'number' or key > count then result[key] = value end
  end

  result.children = children

  return result
end

---@param name string
---@param component fun(name: string, options: table): openmw.ui.Layout
---@return H3UI.ComponentConstructor
local function componentConstructor(name, component)
  if name == 'text' then
    return
      ---@param options? H3UI.TextOptions|string|number
      ---@return openmw.ui.Layout
      function(options)
      local optionType = Type(options)

      if optionType == 'string' or optionType == 'number' then
        options = { text = ToString(options) }
      end

      ---@cast options table
      return component(name, positionalChildren(options) or {})
    end
  end

  if name == 'spacer' then
    return
      ---@param options? H3UI.SpacerOptions|number
      ---@param height? number
      ---@return openmw.ui.Layout
      function(options, height)
      if Type(options) == 'number' then
        local width = options
        options = { width = width, height = height or width }
      end

      ---@cast options table
      return component(name, positionalChildren(options) or {})
    end
  end

  return
    ---@param options? table
    ---@return openmw.ui.Layout
    function(options) return component(name, positionalChildren(options) or {}) end
end

---@param name string
---@param recipe fun(name: string, options: table): openmw.ui.Layout
---@return H3UI.RecipeConstructor
local function recipeConstructor(name, recipe)
  return
    ---@param options? table
    ---@return openmw.ui.Layout
    function(options) return recipe(name, positionalChildren(options) or {}) end
end

---@param target table
---@param components string[]
---@param recipes table<string, H3UI.Recipe>
---@param component fun(name: string, options: table): openmw.ui.Layout
---@param recipe fun(name: string, options: table): openmw.ui.Layout
---@return nil
local function install(target, components, recipes, component, recipe)
  local componentConstructors, recipeConstructors = {}, {}

  local componentNames = ComponentNameCache[components]
  if not componentNames then
    componentNames = {}

    for index = 1, #components do
      componentNames[components[index]] = true
    end

    ComponentNameCache[components] = componentNames
  end

  for index = 1, #components do
    local name = components[index]

    if RawGet(target, name) ~= nil then
      Error(StrFormat('H3 UI constructor collides with scope API: %s', name))
    end
  end

  for name in Next, recipes do
    if RawGet(target, name) ~= nil then
      Error(StrFormat('H3 UI constructor collides with scope API: %s', name))
    end

    if componentNames[name] then
      Error(StrFormat('H3 UI component collides with recipe API: %s', name))
    end
  end

  local previousMetatable = GetMetatable(target)
  local previousIndex = previousMetatable and previousMetatable.__index
  SetMetatable(target, {
    ---@param self table
    ---@param key string
    ---@return H3UI.LuaValue
    __index = function(self, key)
      local constructor = componentConstructors[key]
      if constructor then return constructor end

      constructor = recipeConstructors[key]
      if constructor then return constructor end

      if Type(key) == 'string' then
        if componentNames[key] then
          constructor = componentConstructor(key, component)
          componentConstructors[key] = constructor

          return constructor
        end

        if recipes[key] then
          constructor = recipeConstructor(key, recipe)
          recipeConstructors[key] = constructor

          return constructor
        end
      end

      if previousIndex then
        if Type(previousIndex) == 'function' then return previousIndex(self, key) end
        return previousIndex[key]
      end
    end,
  })
end

return install
