---@omw-context all
---Minimal single-inheritance class system.
---
---This is intentionally small: no mixins, no automatic super dispatch, no
---private fields, and no constructor return override. Classes are plain Lua
---tables with explicit inheritance through metatables.
---
---Usage:
---  local Class = require 'scripts.s3.class'
---
---Defining a class:
---  local Animal = Class.new()
---
---   function Animal:init(name)
---       self.name = name
---   end
---
---   function Animal:speak()
---       return self.name .. ' makes a noise'
---   end
---
--- Instantiation:
---   local a = Animal('Rex')   -- calls Animal:init(...)
---
--- Inheritance:
---   local Dog = Class.new(Animal)
---
---   function Dog:init(name)
---       Animal.init(self, name)   -- explicit super call
---       self.tricks = {}
---   end
---
---   function Dog:speak()
---       return self.name .. ' barks'
---   end
---
---   local d = Dog('Rex')
---   d:speak()         --> 'Rex barks'
---
--- Type checking:
---   Class.is(d, Dog)      --> true
---   Class.is(d, Animal)   --> true   (walks the inheritance chain)
---   Class.is(d, Other)    --> false
---
---   d:is_a(Dog)           --> true   (instance method form)
---
--- Introspection:
---   Class.super(Dog)      --> Animal (the parent class, or nil)
---   Class.class_of(d)     --> Dog    (the direct class of an instance)

---@class ClassModule
---@field new fun(base?: Class): Class
---@field is fun(instance: any, klass: Class): boolean
---@field class_of fun(instance: any): Class?
---@field super fun(cls: Class): Class?
local Class = {}

---@class Class: table
---@field __index table
---@field init? fun(self: table, ...: any)
---@field is_a fun(self: table, klass: Class): boolean
---@overload fun(...: any): table

-- Class tables are metatables for instances and track their superclass directly.
-- Classes may also have class-level metatables for inheritance and __call.

local CLASS_KEY = {} -- unique key to mark class tables
local SUPER_KEY = {} -- unique key to store parent class

---@param value any
---@return boolean
local function is_class(value)
    return type(value) == 'table' and rawget(value, CLASS_KEY) == true
end

---Creates a class table, optionally inheriting from a base class.
---@param base? Class Raises if non-nil and not a class created by this module.
---@return Class class Dynamic class table; subclass fields are intentionally not modeled.
function Class.new(base)
    assert(base == nil or is_class(base),
        'Class.new: base must be a Class or nil')

    local cls = {}
    cls.__index = cls
    cls[CLASS_KEY] = true
    cls[SUPER_KEY] = base

    -- Inherit from base by delegating __index up the chain.
    if base then
        setmetatable(cls, { __index = base })
    end

    -- Calling the class creates an instance.
    local mt = getmetatable(cls) or {}
    setmetatable(cls, mt)
    ---@param c Class
    ---@return table instance Dynamic instance table with class metatable `c`.
    mt.__call = function(c, ...)
        local instance = setmetatable({}, c)
        local init = c.init
        if init then
            init(instance, ...)
        end
        return instance
    end

    -- Instance method: instance:is_a(SomeClass)
    ---@param klass Class Raises if not a class created by this module.
    ---@return boolean
    function cls:is_a(klass)
        return Class.is(self, klass)
    end

    return cls
end

-- Walk the inheritance chain to check if `instance` is an instance of `klass`
-- or any ancestor.
---Returns true when instance belongs to klass or one of its subclasses.
---@param instance any
---@param klass Class Raises if not a class created by this module.
---@return boolean
function Class.is(instance, klass)
    assert(is_class(klass),
        'Class.is: klass must be a Class')
    local cls = getmetatable(instance)
    while is_class(cls) do
        if cls == klass then return true end
        cls = rawget(cls, SUPER_KEY)
    end
    return false
end

---Returns the direct class of an instance.
---@param instance any
---@return Class? class The direct class, or nil when the metatable is not a class.
function Class.class_of(instance)
    local cls = getmetatable(instance)
    if is_class(cls) then return cls end
    return nil
end

---Returns the parent class of a class, or nil for root classes.
---@param cls Class Raises if not a class created by this module.
---@return Class? parent
function Class.super(cls)
    assert(is_class(cls),
        'Class.super: argument must be a Class')
    return rawget(cls, SUPER_KEY)
end

return Class
