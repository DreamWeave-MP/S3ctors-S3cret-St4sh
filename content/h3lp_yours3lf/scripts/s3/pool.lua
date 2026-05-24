---@omw-context none
--- Advanced fixed-capacity object pool. Use pooling only for measured allocation
--- or GC pressure in hot paths; it is not a general convenience container.
--- Defaults recycle tables for cases like per-frame scratch data, temporary
--- accumulators, high-frequency synchronous event payloads, and large reusable
--- tables.
---
--- Pooled objects have a borrowed/manual lifetime. acquire() checks out an
--- object; release(obj) resets it and returns it to the pool. After release(obj),
--- callers must not read, write, store, or pass obj onward. If the pool is empty,
--- acquire() allocates a fresh object rather than erroring, so a temporarily
--- exhausted pool degrades gracefully to normal allocation. The pool can store
--- any non-nil Lua value if a suitable custom factory/reset pair is provided.
---
--- Good fits: per-frame scratch tables, temporary accumulators,
--- high-frequency synchronous event payloads, and large reusable tables.
--- Bad fits: rare events, long-lived state, immutable objects or userdata with
--- no useful reset, objects crossing async/deferred boundaries, and anything
--- retained by listeners or other consumers.
---
--- Usage:
---   local pool = require 'scripts.s3.pool'
---
---   -- Create a pool with up to 16 recycled tables:
---   local eventPool = pool.new(16)
---
---   -- Acquire a clean table, use it, then release:
---   local data = eventPool:acquire()
---   data.amount = 10
---   data.source = 'arrow'
---   signal:fire(data)
---   eventPool:release(data)   -- clears and returns to pool
---   -- This pattern is safe only if every listener consumes synchronously and
---   -- does not retain data. Deferred listeners must receive their own copy.
---
--- Custom table factory (pool creates tables of a specific shape):
---   local vecPool = pool.new(32, function()
---       return { x = 0, y = 0, z = 0 }
---   end)
---
--- Custom reset (called on release instead of the default table clear):
---   local vecPool = pool.new(32, factory, function(obj)
---       obj.x = 0; obj.y = 0; obj.z = 0
---   end)
---
--- Non-table objects require a custom reset, even if it is a no-op:
---   local userdataPool = pool.new(32, factory, function(_) end)
---
--- Introspection:
---   eventPool:available()    -- number of objects currently in the pool
---   eventPool:capacity()     -- maximum pool size
---   eventPool:allocated()    -- current pool-created objects: available + checked out
---   local available, in_use, allocated, capacity = eventPool:stats()
---                         -- returns four values directly to avoid table allocation
---
--- Notes:
---  - release() does NOT enforce that the object came from this pool and does
---    not detect double release. Double-releasing can put the same object into
---    the pool twice, allowing two later acquire() calls to hand out the same
---    object. in_use and allocated accounting assume correct acquire/release
---    pairing.
---  - release(nil) is invalid. Factories must not return nil, and callers must
---    not release nil.
---  - After release(obj), obj is no longer yours. Do not read, write, store, or
---    pass it to other code.
---   - release(obj) always calls reset(obj) before either retaining or
---     dropping the object. The pool retains released objects up to capacity;
---     extras are reset, then dropped (and GC'd normally), reducing allocated().
---   - The default factory and default reset are table-oriented. The default
---     reset clears the released table in place with a next()-based loop, not
---     the pool stack, so the table's internal array/hash structure is preserved.
---   - Factories must never return nil. Nil cannot be pushed into the pool stack.

---@class Pool
---@field _stack any[]
---@field _capacity integer
---@field _factory fun(): any
---@field _reset fun(obj: any)
---@field _allocated integer
---@field _uses_default_reset boolean
local Pool = {}
Pool.__index = Pool

---@return table
local function default_factory() return {} end

---@param obj table
---@return nil
local function default_reset(obj)
    local k = next(obj)
    while k ~= nil do
        obj[k] = nil
        k = next(obj)
    end
end

---@param self Pool
---@return any obj
local function new_object(self)
    local obj = self._factory()
    assert(obj ~= nil, 'pool: factory must not return nil')
    assert(not self._uses_default_reset or type(obj) == 'table',
        'pool: non-table objects require a custom reset')
    self._allocated = self._allocated + 1
    return obj
end

---Creates a fixed-capacity pool and pre-populates it with available objects.
---@param capacity integer Must be a positive integer; raises otherwise.
---@param factory? fun(): any Defaults to a new table factory.
---@param reset? fun(obj: any) Defaults to clearing table keys with next().
---@return Pool
function Pool.new(capacity, factory, reset)
    assert(type(capacity) == 'number' and capacity >= 1 and math.floor(capacity) == capacity,
        'pool: capacity must be a positive integer')
    local uses_default_reset = reset == nil
    factory = factory == nil and default_factory or factory
    reset   = reset == nil and default_reset or reset
    assert(type(factory) == 'function', 'pool: factory must be a function')
    assert(type(reset) == 'function', 'pool: reset must be a function')

    local self = setmetatable({
        _stack     = {},
        _capacity  = capacity,
        _factory   = factory,
        _reset     = reset,
        _allocated = 0,
        _uses_default_reset = uses_default_reset,
    }, Pool)

    -- Pre-populate the pool so the first burst of acquires doesn't allocate.
    for _ = 1, capacity do
        self._stack[#self._stack + 1] = new_object(self)
    end

    return self
end

---Acquires an object, allocating a fresh one if the pool is exhausted.
---@return any obj
function Pool:acquire()
    local stack = self._stack
    local n     = #stack
    if n > 0 then
        local obj = stack[n]
        stack[n]  = nil
        return obj
    end
    -- Pool exhausted: allocate fresh rather than blocking.
    return new_object(self)
end

---Releases an object after resetting it; release(nil) is invalid.
---No ownership or double-release check is performed.
---@param obj any No ownership check is performed; nil is invalid.
---@return nil
function Pool:release(obj)
    self._reset(obj)

    local stack = self._stack
    if #stack >= self._capacity then
        -- Pool full: object has been reset; drop it and let it be GC'd.
        self._allocated = self._allocated - 1
        return
    end

    stack[#stack + 1] = obj
end

---Returns the number of objects currently idle in the pool stack.
---@return integer available
function Pool:available() return #self._stack end

---Returns the maximum number of idle objects retained by the pool.
---@return integer capacity
function Pool:capacity() return self._capacity end

---Returns the current pool-created object count: available plus checked out.
---@return integer allocated
function Pool:allocated() return self._allocated end

---Returns pool counters directly to avoid allocating a stats table.
---@return integer available Number of objects currently idle in the pool stack.
---@return integer in_use Number of currently checked-out objects.
---@return integer allocated Current pool-created object count.
---@return integer capacity Maximum retained idle objects.
function Pool:stats()
    local available = #self._stack
    return available, self._allocated - available, self._allocated, self._capacity
end

return Pool
