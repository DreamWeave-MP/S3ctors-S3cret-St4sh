---@omw-context all
---Deferred single-computation value. The factory is called on first access,
---then cached and not called again until reset() is called.
---
---Usage:
---  local lazy = require 'scripts.s3.lazy'
---
---  local getManager = lazy(function()
---      return buildExpensiveManager()
---  end)
---
---  -- Elsewhere, as many times as needed:
---  local m = getManager()   -- computed on first call, cached thereafter
---
---The returned callable also exposes:
---  getManager:computed()    -- true if the value has been computed
---  getManager:reset()       -- clear the cache; next call recomputes
---  getManager:peek()        -- return cached value or nil without computing
---
---peek() returns nil both before computation and when the cached value is
---actually nil; use computed() to distinguish those ambiguous cases.

---@class LazyValue
---@field computed fun(self: LazyValue): boolean True after the factory has run, even if it returned nil.
---@field peek fun(self: LazyValue): any? Cached value, or nil before computation; nil is ambiguous.
---@field reset fun(self: LazyValue) Clears the cache so the next call runs the factory again.
---@overload fun(): any

---Creates a lazily computed single-value callable.
---The factory runs on first call and then not again until reset() is called.
---@param fn fun(): any Raises from fn propagate on first computation.
---@return LazyValue lazy_value Callable object that computes at most once until reset.
local function lazy(fn)
    assert(type(fn) == 'function', 'lazy: factory must be a function')

    local computed = false
    local value = nil

    return setmetatable({}, {
        __call = function()
            if not computed then
                value = fn()
                computed = true
            end
            return value
        end,
        __index = {
            ---@return boolean
            computed = function() return computed end,
            ---@return any?
            peek = function() return value end,
            ---@return nil
            reset = function()
                computed = false
                value = nil
            end,
        },
    })
end

return lazy
