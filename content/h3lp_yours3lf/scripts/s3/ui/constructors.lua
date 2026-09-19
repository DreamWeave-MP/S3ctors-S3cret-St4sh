---@omw-context menu|player

local componentNameCache = setmetatable({}, { __mode = 'k' })

local function positionalChildren(options)
  if type(options) ~= 'table' or #options == 0 then return options end
  assert(
    options.children == nil and options.content == nil,
    'H3 UI accepts positional children or children/content, not both'
  )

  local count = #options
  local result = {}
  local children = {}
  for index = 1, count do children[index] = options[index] end
  for key, value in next, options do
    if type(key) ~= 'number' or key > count then result[key] = value end
  end
  result.children = children
  return result
end

local function componentConstructor(name, component)
  if name == 'text' then
    return function(options)
      if type(options) == 'string' or type(options) == 'number' then
        options = { text = tostring(options) }
      end
      return component(name, positionalChildren(options) or {})
    end
  end

  if name == 'spacer' then
    return function(options, height)
      if type(options) == 'number' then
        local width = options
        options = { width = width, height = height or width }
      end
      return component(name, positionalChildren(options) or {})
    end
  end

  return function(options) return component(name, positionalChildren(options) or {}) end
end

local function recipeConstructor(name, recipe)
  return function(options) return recipe(name, positionalChildren(options) or {}) end
end

local function install(target, components, recipes, component, recipe)
  local componentConstructors = {}
  local recipeConstructors = {}
  local componentNames = componentNameCache[components]
  if componentNames == nil then
    componentNames = {}
    for index = 1, #components do componentNames[components[index]] = true end
    componentNameCache[components] = componentNames
  end

  for index = 1, #components do
    local name = components[index]
    assert(rawget(target, name) == nil, 'H3 UI constructor collides with scope API: ' .. name)
  end
  for name in next, recipes do
    assert(rawget(target, name) == nil, 'H3 UI constructor collides with scope API: ' .. name)
    assert(not componentNames[name], 'H3 UI component collides with recipe API: ' .. name)
  end

  local previousMetatable = getmetatable(target)
  local previousIndex = previousMetatable and previousMetatable.__index
  setmetatable(target, {
    __index = function(self, key)
      local constructor = componentConstructors[key]
      if constructor then return constructor end

      constructor = recipeConstructors[key]
      if constructor then return constructor end

      if type(key) == 'string' then
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
        if type(previousIndex) == 'function' then return previousIndex(self, key) end
        return previousIndex[key]
      end
    end,
  })
end

return install
