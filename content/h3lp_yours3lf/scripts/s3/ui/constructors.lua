---@omw-context menu|player

local util = require 'openmw.util'

local UtilVector2 = util.vector2

local function componentConstructor(name, component)
  if name == 'text' then
    return function(options)
      if type(options) == 'string' or type(options) == 'number' then
        options = { text = tostring(options) }
      end
      return component(name, options or {})
    end
  end

  if name == 'spacer' then
    return function(options, height)
      if type(options) == 'number' then
        local width = options
        options = { props = { size = UtilVector2(width, height or width) } }
      end
      return component(name, options or {})
    end
  end

  return function(options) return component(name, options or {}) end
end

local function recipeConstructor(name, recipe)
  return function(options) return recipe(name, options) end
end

local function install(target, components, recipes, component, recipe)
  local componentConstructors = {}
  local recipeConstructors = {}
  local componentNames = {}

  for index = 1, #components do
    local name = components[index]
    componentNames[name] = true
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
        for index = 1, #components do
          if components[index] == key then
            constructor = componentConstructor(key, component)
            componentConstructors[key] = constructor
            return constructor
          end
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
