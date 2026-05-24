---@omw-context none
--- memoize.lua
--- Function memoization with configurable cache key extraction.
---
--- Basic usage (single argument, used directly as key):
---   local memoize = require 'scripts.s3.memoize'
---   local memoized = memoize(expensive_fn)
---   memoized('foo')   -- computes
---   memoized('foo')   -- returns cached result
---
--- Custom key function (multi-arg or complex args):
---   local memoized = memoize(fn, function(a, b) return a .. ':' .. b end)
---
--- With TTL (default: results expire N seconds after computation/storage):
---   local memoized = memoize(fn, nil, { ttl = 5.0 })
---   memoized:tick(dt)   -- age the cache; call from onUpdate
---   memoized(arg)       -- returns fresh or cached result
---   -- Cache hits do not refresh age, so hot entries still expire after 5s.
---
--- With access-refreshing TTL (expire N seconds after last access):
---   local memoized = memoize(fn, nil, { ttl = 5.0, refresh_on_hit = true })
---   memoized(arg)       -- cache hit resets this entry's age to 0
---
--- With a hard entry budget:
---   local memoized = memoize(fn, nil, { max_entries = 128 })
---   -- When a miss would grow past 128 live entries, the oldest live entry is evicted.
---
--- Manual invalidation:
---   memoized:invalidate(arg)       -- clear one key (uses key_fn)
---   memoized:invalidate_all()      -- clear everything
---
--- Stats (for debugging):
---   memoized:stats()   -- returns { hits, misses, size }
---
--- Notes:
---   - Cached nil return values are supported anywhere in multiple returns.
---   - Multiple return values and zero-return functions are supported.
---   - Nil first-argument keys, no-argument calls, and nil custom keys are
---     supported via an internal sentinel.
---  - The cache is a plain Lua table. By default only the first argument is
---    used as the cache key. Functions where later arguments affect the result
---    must provide a key_fn. For complex args, always supply a key_fn that
---    returns a stable string/number/table key.
---  - Cache hits do not allocate result tables; returned values are unpacked
---    through an internal reusable scratch array.
---  - Returned tables/userdata are cached by reference, not copied. Mutating a
---    cached return value mutates what future cache hits return.
---  - Without max_entries, TTL, or manual invalidation, cache growth is unbounded.
---    Use max_entries for a fixed live-entry budget in hot or player-driven paths.
---    max_entries eviction is FIFO by insertion age, not LRU; cache hits do not
---    refresh eviction order.
---  - TTL uses caller-supplied seconds passed to tick(dt). It is not tied to
---    OpenMW real time or simulation time unless you pass those deltas yourself.
---    By default TTL is time since write; set refresh_on_hit = true for time
---    since last access.
---  - tick(dt) expects non-negative caller-supplied dt; negative dt moves TTL
---    ages backward and is not useful.
---  - stats() allocates a table; don't call it in hot paths if avoiding
---    allocation is the point.

---@class MemoizeOptions
---@field ttl? number Seconds before cached entries expire when ticked.
---@field refresh_on_hit? boolean When true, cache hits reset entry age to 0.
---@field max_entries? integer Maximum live cache entries. Oldest live entry is evicted on overflow.

---@class MemoizeStats
---@field hits integer
---@field misses integer
---@field size integer

---@class Memoized
---@field _fn fun(...: any): any
---@field _key_fn? fun(...: any): any
---@field _cache table<any, MemoizeEntry>
---@field _ttl? number
---@field _refresh_on_hit boolean
---@field _max_entries? integer
---@field _size integer
---@field _oldest? MemoizeEntry
---@field _newest? MemoizeEntry
---@field _scratch any[]
---@field _scratch_n integer
---@field _hits integer
---@field _misses integer
---@overload fun(...: any): any

---@class MemoizeEntry
---@field key any
---@field values table<integer, any>
---@field n integer
---@field age number
---@field older? MemoizeEntry
---@field newer? MemoizeEntry

-- Sentinel to distinguish a cached nil from a missing entry.
local NIL = {}

-- Sentinel for nil/no-argument cache keys; nil cannot be used as a table key.
local NIL_KEY = {}

-- Unpack that works across LuaJIT (table.unpack not always available).
---@diagnostic disable-next-line: deprecated
local unpack = table.unpack or unpack

local function pack(...)
    return { n = select('#', ...), ... }
end

---@param self Memoized
---@param ... any
---@return any
local function cache_key(self, ...)
    local key
    if self._key_fn then
        key = self._key_fn(...)
    else
        key = (...) -- first argument is the default key
    end
    if key == nil then return NIL_KEY end
    return key
end

---@param results table
---@return table<integer, any>
local function store_values(results)
    local stored = {}
    for i = 1, results.n do
        stored[i] = results[i] == nil and NIL or results[i]
    end
    return stored
end

---@param self Memoized
---@param stored table<integer, any>
---@param n integer
---@return any ...
local function return_values(self, stored, n)
    local scratch = self._scratch
    local old_n = self._scratch_n
    if n == 0 then
        for i = 1, old_n do
            scratch[i] = nil
        end
        self._scratch_n = 0
        return
    end
    for i = 1, n do
        local value = stored[i]
        scratch[i] = value ~= NIL and value or nil
    end
    for i = n + 1, old_n do
        scratch[i] = nil
    end
    self._scratch_n = n

    return unpack(scratch, 1, n)
end

---@param self Memoized
---@param entry MemoizeEntry
---@return nil
local function link_entry(self, entry)
    if not self._max_entries then return end

    local newest = self._newest
    entry.older = newest
    entry.newer = nil
    if newest then
        newest.newer = entry
    else
        self._oldest = entry
    end
    self._newest = entry
end

---@param self Memoized
---@param entry MemoizeEntry
---@return nil
local function unlink_entry(self, entry)
    if not self._max_entries then return end

    local older = entry.older
    local newer = entry.newer
    if older then
        older.newer = newer
    else
        self._oldest = newer
    end
    if newer then
        newer.older = older
    else
        self._newest = older
    end
    entry.older = nil
    entry.newer = nil
end

---@param self Memoized
---@param key any
---@return nil
local function evict_key(self, key)
    local entry = self._cache[key]
    if not entry then return end

    unlink_entry(self, entry)
    self._cache[key] = nil
    self._size = self._size - 1
end

---@param self Memoized
---@param key any
---@param entry MemoizeEntry
---@return nil
local function store_entry(self, key, entry)
    entry.key = key
    self._cache[key] = entry
    self._size = self._size + 1
    link_entry(self, entry)

    local max_entries = self._max_entries
    while max_entries and self._size > max_entries do
        local oldest = self._oldest
        if not oldest then return end
        evict_key(self, oldest.key)
    end
end

local Memoized = {}
Memoized.__index = Memoized

---Creates a callable memoized wrapper around fn.
---@param fn fun(...: any): any Raises from fn propagate on cache miss; multiple returns are preserved dynamically.
---@param key_fn? fun(...: any): any Defaults to the first argument.
---@param opts? MemoizeOptions
---@return Memoized callable
local function make(fn, key_fn, opts)
    opts = opts or {}
    local ttl = opts.ttl -- nil = no expiry
    local refresh_on_hit = opts.refresh_on_hit == true
    local max_entries = opts.max_entries

    assert(type(fn) == 'function', 'memoize: fn must be a function')
    assert(key_fn == nil or type(key_fn) == 'function', 'memoize: key_fn must be a function')
    assert(ttl == nil or (type(ttl) == 'number' and ttl > 0), 'memoize: ttl must be a positive number')
    assert(max_entries == nil or (type(max_entries) == 'number'
        and max_entries >= 1 and math.floor(max_entries) == max_entries),
        'memoize: max_entries must be a positive integer')

    local self = setmetatable({
        _fn             = fn,
        _key_fn         = key_fn,
        _cache          = {}, -- key -> { values = {...}, n = count, age = 0 }
        _ttl            = ttl,
        _refresh_on_hit = refresh_on_hit,
        _max_entries    = max_entries,
        _size           = 0,
        _oldest         = nil,
        _newest         = nil,
        _scratch        = {},
        _scratch_n      = 0,
        _hits           = 0,
        _misses         = 0,
    }, Memoized)

    -- Return a callable that behaves like the original function.
    -- Method wrappers close over the real state table; colon calls on the
    -- callable must not write accounting fields onto the callable shell.
    local callable = {
        tick = function(_, dt) return self:tick(dt) end,
        invalidate = function(_, ...) return self:invalidate(...) end,
        invalidate_all = function(_) return self:invalidate_all() end,
        stats = function(_) return self:stats() end,
    }
    setmetatable(callable, {
        __call = function(_, ...)
            return self:_call(...)
        end,
        __index = self,
    })

    return callable
end

---Calls the wrapped function on misses, or returns cached values on hits.
---@param ... any
---@return any ... Cached or freshly computed return values; multiple returns are preserved dynamically.
function Memoized:_call(...)
    local key = cache_key(self, ...)
    local entry = self._cache[key]
    if entry then
        self._hits = self._hits + 1
        if self._refresh_on_hit then
            entry.age = 0
        end
        return return_values(self, entry.values, entry.n)
    end

    self._misses = self._misses + 1
    local results = pack(self._fn(...))
    local stored = store_values(results)

    store_entry(self, key, { values = stored, n = results.n, age = 0 })

    return return_values(self, stored, results.n)
end

---Advances the age of all cache entries and evicts expired entries.
---Call from onUpdate when using TTL-based memoization.
---@param dt number Non-negative elapsed seconds supplied by the caller; not validated.
---@return nil
function Memoized:tick(dt)
    local ttl = self._ttl
    if not ttl then return end

    local expired
    for key, entry in pairs(self._cache) do
        entry.age = entry.age + dt
        if entry.age >= ttl then
            expired = expired or {}
            expired[#expired + 1] = key
        end
    end

    if not expired then return end
    for i = 1, #expired do
        evict_key(self, expired[i])
    end
end

---Invalidates one cached entry.
---@param ... any Arguments passed to key_fn, or first argument used directly.
---@return nil
function Memoized:invalidate(...)
    evict_key(self, cache_key(self, ...))
end

---Invalidates all cached entries.
---@return nil
function Memoized:invalidate_all()
    self._cache = {}
    self._size = 0
    self._oldest = nil
    self._newest = nil
end

---Returns cache counters. Allocates a new table.
---@return MemoizeStats stats
function Memoized:stats()
    return { hits = self._hits, misses = self._misses, size = self._size }
end

return make
