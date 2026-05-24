---@omw-context none
--- signal.lua
--- Signal / event emitter with priority ordering and safe deferred mutation.
---
--- A Signal is a named event that zero or more listeners can subscribe to.
--- Firing a signal calls all connected listeners in stable priority order.
--- Listener mutations made during fire() are deferred until the current dispatch
--- finishes, so the current listener list keeps running with existing semantics.
--- If a listener errors, internal cleanup still runs before the error is raised.
---
---Signal does not allocate, own, clear, or reuse payload tables during normal
---fire(). It passes exactly one argument, `data`, through as borrowed data for
---the duration of synchronous dispatch. Callers may reuse payload tables after
---fire() returns only when listeners do not retain references to those tables.
---If you fire a pooled table, listeners must treat it as read-only/borrowed and
---must not store it. If any listener may defer work, copy the data before returning.
---
--- Allocation notes:
---   - connect() and once() allocate listener entries and handles.
---   - Mutations during fire() allocate pending operation records.
---   - Ordinary fire() with stable listeners does not allocate, except for
---     once-listener cleanup and listener-error handling paths as implemented.
---
--- Basic usage:
---   local Signal = require 'scripts.s3.signal'
---
---   local onDamage = Signal.new()
---
---   local handle = onDamage:connect(function(data)
---       print('took', data.amount, 'damage from', data.source)
---   end)
---
---   onDamage:fire({ amount = 10, source = 'arrow' })
---
---   handle:disconnect()   -- remove this specific listener
---
--- Priority (lower number = called first, default 0):
---   onDamage:connect(fn, 50)    -- called after default-priority listeners
---   onDamage:connect(fn, -10)   -- called before them
---
--- One-shot listener (auto-disconnects after first fire):
---   onDamage:once(fn)
---
--- Firing with caller-owned payload reuse:
---   local eventData = {}
---   -- Re-populate before every fire; signal will borrow this table.
---   eventData.amount = 10
---   eventData.source = 'arrow'
---   onDamage:fire(eventData)
---   -- The table is yours to repopulate next tick if listeners did not retain it.
---
--- Blocking / pausing:
---   local sig = Signal.new()
---   sig:block()     -- listeners are not called while blocked
---   sig:unblock()   -- resume normal operation
---   sig:blocked()   -- returns bool
---
--- Disconnecting all listeners:
---   sig:disconnect_all()
---
--- Listener count:
---   sig:count()
---
--- Notes:
---  - Connecting, disconnecting, or clearing from within a listener is safe;
---    changes take effect after the current fire() completes. Disconnecting a
---    listener mid-fire does not remove it from the current dispatch pass.
---   - Firing a signal from within a listener of the same signal is detected
---     and raises an error (re-entrant fire).
---   - Listeners are called in stable priority order. Equal-priority listeners
---     are called in connection order.

---@alias SignalListener fun(data: any)

---@class SignalHandle
---@field _disconnect? fun()

---@class SignalListenerEntry
---@field fn SignalListener
---@field priority number
---@field once boolean
---@field id integer

---@class SignalPendingOp
---@field op 'add'|'remove'|'clear'
---@field entry? SignalListenerEntry
---@field id? integer

---@class Signal
---@field _listeners SignalListenerEntry[]
---@field _pending SignalPendingOp[]?
---@field _firing boolean
---@field _blocked boolean
---@field _next_id integer
local Signal = {}
Signal.__index = Signal

local traceback = debug.traceback

-- Handle returned to the caller on connect. Holds a disconnect closure.
local Handle = {}
Handle.__index = Handle

---Disconnects this handle's listener; no-op after the first disconnect.
---@return nil
function Handle:disconnect()
    if self._disconnect then
        self._disconnect()
        self._disconnect = nil
    end
end

-- ---------------------------------------------------------------------------
-- Construction
-- ---------------------------------------------------------------------------

---Creates a new signal with no listeners.
---@return Signal signal
function Signal.new()
    return setmetatable({
        _listeners  = {},   -- array of { fn, priority, once, id }
        _pending    = nil,  -- list of pending mutations during fire
        _firing     = false,
        _blocked    = false,
        _next_id    = 1,
    }, Signal)
end

-- ---------------------------------------------------------------------------
-- Internal: sorted insert
-- ---------------------------------------------------------------------------

---@param listeners SignalListenerEntry[]
---@param entry SignalListenerEntry
---@return nil
local function insert_sorted(listeners, entry)
    -- Binary search for the insertion point (stable: insert after equal-priority entries).
    local lo, hi = 1, #listeners
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        if listeners[mid].priority <= entry.priority then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    table.insert(listeners, lo, entry)
end

---@param listeners SignalListenerEntry[]
---@param id integer
---@return nil
local function remove_by_id(listeners, id)
    for i = #listeners, 1, -1 do
        if listeners[i].id == id then
            table.remove(listeners, i)
            return
        end
    end
end

---@param self Signal
---@param listeners SignalListenerEntry[]
---@param to_remove integer[]?
---@return nil
local function finish_fire(self, listeners, to_remove)
    self._firing = false

    if to_remove then
        for _, id in ipairs(to_remove) do
            remove_by_id(listeners, id)
        end
    end

    local pending = self._pending
    if pending then
        self._pending = nil
        for _, op in ipairs(pending) do
            if op.op == 'add' then
                insert_sorted(listeners, op.entry)
            elseif op.op == 'remove' then
                remove_by_id(listeners, op.id)
            elseif op.op == 'clear' then
                for i = #listeners, 1, -1 do
                    listeners[i] = nil
                end
            end
        end
    end
end

---@param entry SignalListenerEntry
---@param data any
---@return nil
local function call_listener(entry, data)
    entry.fn(data)
end

-- ---------------------------------------------------------------------------
-- Connect / disconnect
-- ---------------------------------------------------------------------------

---@param self Signal
---Connects a listener and returns a handle that can disconnect it.
---If called during fire(), the listener is added after the current dispatch.
---@param fn SignalListener Raises if not a function.
---@param priority? number Defaults to 0.
---@param once boolean
---@return SignalHandle
local function do_connect(self, fn, priority, once)
    assert(type(fn) == 'function', 'connect: listener must be a function')
    if priority == nil then priority = 0 end
    assert(type(priority) == 'number', 'Signal: priority must be a number')
    local id = self._next_id
    self._next_id = id + 1

    local entry = { fn = fn, priority = priority, once = once, id = id }

    if self._firing then
        -- Defer mutation until after current fire completes.
        if not self._pending then self._pending = {} end
        table.insert(self._pending, { op = 'add', entry = entry })
    else
        insert_sorted(self._listeners, entry)
    end

    local handle = setmetatable({}, Handle)
    handle._disconnect = function()
        if self._firing then
            if not self._pending then self._pending = {} end
            table.insert(self._pending, { op = 'remove', id = id })
        else
            local listeners = self._listeners
            remove_by_id(listeners, id)
        end
    end

    return handle
end

---Connects a listener that disconnects automatically after its first fire.
---If called during fire(), the listener is added after the current dispatch.
---@param fn SignalListener Raises if not a function.
---@param priority? number Defaults to 0.
---@return SignalHandle
function Signal:connect(fn, priority)
    return do_connect(self, fn, priority, false)
end

---@param fn SignalListener Raises if not a function.
---@param priority? number Defaults to 0.
---@return SignalHandle
function Signal:once(fn, priority)
    return do_connect(self, fn, priority, true)
end

---Disconnects all listeners.
---If called during fire(), clearing takes effect after the current dispatch.
---@return nil
function Signal:disconnect_all()
    if self._firing then
        if not self._pending then self._pending = {} end
        table.insert(self._pending, { op = 'clear' })
    else
        local listeners = self._listeners
        for i = #listeners, 1, -1 do
            listeners[i] = nil
        end
    end
end

-- ---------------------------------------------------------------------------
-- Fire
-- ---------------------------------------------------------------------------

---Fires this signal with exactly one caller-owned data argument.
---Listener mutations are deferred until dispatch completes; disconnecting during
---fire() does not affect the current pass. Pooled payloads are borrowed/read-only.
---@param data any Passed to every listener; raises on re-entrant fire.
---@return nil
function Signal:fire(data)
    if self._blocked then return end
    assert(not self._firing, 'Signal: re-entrant fire() detected')

    self._firing = true

    local listeners  = self._listeners
    local to_remove  = nil   -- ids of once-listeners to clean up

    local error_message = nil

    for i = 1, #listeners do
        local entry = listeners[i]
        if entry.once then
            if not to_remove then to_remove = {} end
            to_remove[#to_remove + 1] = entry.id
        end
        local ok, err = xpcall(call_listener, traceback, entry, data)
        if not ok then
            error_message = err
            break
        end
    end

    finish_fire(self, listeners, to_remove)

    if error_message then
        error(error_message, 0)
    end
end

-- ---------------------------------------------------------------------------
-- Block / unblock
-- ---------------------------------------------------------------------------

---Blocks future fire() calls until unblock() is called.
---@return nil
function Signal:block()   self._blocked = true  end
---Unblocks fire() calls.
---@return nil
function Signal:unblock() self._blocked = false end
---Returns whether this signal is currently blocked.
---@return boolean blocked
function Signal:blocked() return self._blocked  end

-- ---------------------------------------------------------------------------
-- Introspection
-- ---------------------------------------------------------------------------

---Returns the current number of connected listeners.
---@return integer count
function Signal:count()
    return #self._listeners
end

return Signal
