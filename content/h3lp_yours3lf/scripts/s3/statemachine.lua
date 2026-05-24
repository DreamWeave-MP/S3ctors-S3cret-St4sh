---@omw-context none
--- statemachine.lua
--- Finite state machine with named states, entry/exit callbacks,
--- deferred transitions, history, and optional transition validation.
---
--- Usage:
---   local StateMachine = require 'scripts.s3.statemachine'
---   local sm = StateMachine.new()
---
--- State definition (table form):
---   sm:state('name', {
---       on_enter = function(from) ... end,  -- called when entering this state
---       tick     = function(dt)   ... end,  -- called each tick while active
---       on_exit  = function(to)   ... end,  -- called when leaving this state
---   })
---
--- State definition (shorthand):
---   sm:state('name', fn)   -- equivalent to { tick = fn }
---
--- Transitions:
---  sm:transition(name)    -- queues a transition for the end of the current
---                          -- tick, or for the next tick if called outside
---                          -- tick(); multiple requests are last-request-wins
---   sm:jump(name)          -- immediate: takes effect right now (mid-tick)
---   sm:start(name)         -- alias for jump; used for initial state at boot
---   Transitioning to the current state restarts it: on_exit(name) then
---   on_enter(name) are called, and previous/current are updated normally.
---
--- Transition validation (optional, recommended in dev):
---   sm:allow('a', 'b')     -- declare that transitioning from a -> b is legal
---   sm:allow('*', 'error') -- wildcard: legal from any state
---   sm:validate(true)      -- enable enforcement; illegal transitions throw
---   sm:validate(false)     -- disable (default)
---   With validation enabled and no allow() rules registered, transitions are
---   allowed. Once any rules exist, only declared from -> to or wildcard rules
---   are allowed.
---
--- Query:
---   sm:current()           -- name of the current state
---   sm:previous()          -- name of the previous state (nil before first transition)
---   sm:is(name)            -- true if current state is name
---
--- Error state:
---   If a state named 'error' is registered, tick errors transition there
---   instead of propagating. on_enter receives (from, err_message).
---   If no 'error' state is registered, errors propagate normally.
---   Tick error transitions run the old state's on_exit('error') first.
---   on_enter/on_exit errors are not caught by the error state.
---
--- Callback errors:
---   on_exit errors abort the transition before the current state changes.
---   on_enter errors propagate after the current state has changed.
---
--- Public API summary:
---   StateMachine.new([opts])        create instance; opts = { validate = bool }
---   sm:state(name, fn|table)        register a state before start()
---   sm:allow(from, to)              declare a legal transition
---   sm:validate(bool)               enable/disable transition enforcement
---   sm:start(name)                  set initial state (immediate, calls on_enter)
---   sm:transition(name)             request deferred transition (end of tick)
---   sm:jump(name)                   immediate transition
---   sm:tick(dt)                     advance the machine by one tick
---   sm:current()                    current state name
---   sm:previous()                   previous state name
---   sm:is(name)                     bool: is current state `name`?

---@alias StateName string
---@alias StateTick fun(dt: any)
---@alias StateEnter fun(from: StateName?, err?: any)
---@alias StateExit fun(to: StateName)

---@class StateDefinition
---@field tick? StateTick
---@field on_enter? StateEnter
---@field on_exit? StateExit

---@class StateMachineOptions
---@field validate? boolean

---@class StateMachine
---@field _states table<string, StateDefinition>
---@field _allowed table<string, table<string, boolean>>?
---@field _validate boolean
---@field _current StateDefinition?
---@field _cur_name StateName?
---@field _prev StateName?
---@field _pending StateName?
---@field _ticking boolean
---@field start fun(self: StateMachine, name: StateName) Alias for jump().
local StateMachine = {}
StateMachine.__index = StateMachine

-- ---------------------------------------------------------------------------
-- Construction
-- ---------------------------------------------------------------------------

---Creates a state machine instance.
---@param opts? StateMachineOptions
---@return StateMachine machine
function StateMachine.new(opts)
    opts = opts or {}
    assert(opts.validate == nil or type(opts.validate) == 'boolean',
        'StateMachine.new: opts.validate must be a boolean')
    return setmetatable({
        _states   = {},   -- name -> { tick, on_enter, on_exit }
        _allowed  = nil,  -- { [from] = { [to] = true } } or nil if unused
        _validate = opts.validate == true,
        _current  = nil,  -- current state record
        _cur_name = nil,  -- current state name
        _prev     = nil,  -- previous state name
        _pending  = nil,  -- deferred transition target
        _ticking  = false,
    }, StateMachine)
end

-- ---------------------------------------------------------------------------
-- State registration
-- ---------------------------------------------------------------------------

---Registers a state before start(). Function shorthand registers a tick callback.
---@param name StateName Raises if not a string.
---@param def StateDefinition|StateTick Raises if not a state table or function.
---@return nil
function StateMachine:state(name, def)
    assert(type(name) == 'string', 'state name must be a string')
    assert(self._current == nil, 'state: states must be registered before start()')
    if type(def) == 'function' then
        def = { tick = def }
    end
    assert(type(def) == 'table', 'state must be a function or table')
    assert(def.tick     == nil or type(def.tick)     == 'function',
        ('state %q: tick must be a function'):format(name))
    assert(def.on_enter == nil or type(def.on_enter) == 'function',
        ('state %q: on_enter must be a function'):format(name))
    assert(def.on_exit  == nil or type(def.on_exit)  == 'function',
        ('state %q: on_exit must be a function'):format(name))
    self._states[name] = def
end

-- ---------------------------------------------------------------------------
-- Transition validation
-- ---------------------------------------------------------------------------

---Declares that transitioning from -> to is legal.
---`from` may be '*' to mean "from any state".
---@param from StateName|'*' Raises if not a string.
---@param to StateName Raises if not a string.
---@return nil
function StateMachine:allow(from, to)
    assert(type(from) == 'string', 'allow: from must be a string')
    assert(type(to)   == 'string', 'allow: to must be a string')
    if not self._allowed then self._allowed = {} end
    if not self._allowed[from] then self._allowed[from] = {} end
    self._allowed[from][to] = true
end

---Enables or disables transition validation.
---@param enabled boolean
---@return nil
function StateMachine:validate(enabled)
    assert(type(enabled) == 'boolean', 'validate: enabled must be a boolean')
    self._validate = enabled
end

---@param self StateMachine
---@param from StateName?
---@param to StateName
---@return nil
local function check_allowed(self, from, to)
    if not self._validate then return end
    local allowed = self._allowed
    -- Validation on but no rules = allow all. Once rules exist, only explicit
    -- from -> to or wildcard transitions are allowed.
    if not allowed then return end
    local from_rules = from and allowed[from] or nil
    local wildcard   = allowed['*']
    if not ((from_rules and from_rules[to]) or (wildcard and wildcard[to])) then
        error(('StateMachine: transition %q -> %q is not declared as allowed')
            :format(from or '(none)', to), 3)
    end
end

-- ---------------------------------------------------------------------------
-- Internal transition
-- ---------------------------------------------------------------------------

---@param self StateMachine
---@param to StateName Raises for unknown or disallowed transitions.
---@param err? any Passed to destination on_enter after tick error transitions.
---@return nil
local function do_transition(self, to, err)
    local next_state = self._states[to]
    assert(next_state, ('StateMachine: unknown state %q'):format(to))
    check_allowed(self, self._cur_name, to)

    local cur = self._current
    if cur and cur.on_exit then
        cur.on_exit(to)
    end

    local from     = self._cur_name
    self._prev     = from
    self._current  = next_state
    self._cur_name = to

    if next_state.on_enter then
        next_state.on_enter(from, err)
    end
end

-- ---------------------------------------------------------------------------
-- Public transition API
-- ---------------------------------------------------------------------------

---Queues transition until the end of the current tick(), or the next tick() if
---called outside tick(). Safe to call from inside a tick handler.
---If you need it now, use jump().
---@param name StateName Raises for unknown or disallowed transitions.
---@return nil
function StateMachine:transition(name)
    assert(type(name) == 'string', 'transition: name must be a string')
    assert(self._states[name], ('StateMachine: unknown state %q'):format(name))
    check_allowed(self, self._cur_name, name)
    self._pending = name
end

---Immediately transitions: on_exit/on_enter run right now.
---Use for start() and cases where on_enter must run before tick() returns.
---@param name StateName Raises for unknown or disallowed transitions.
---@return nil
function StateMachine:jump(name)
    assert(type(name) == 'string', 'jump: name must be a string')
    do_transition(self, name)
    self._pending = nil  -- cancel any pending deferred transition
end

-- Alias for jump; communicates intent at the call site.
StateMachine.start = StateMachine.jump

-- ---------------------------------------------------------------------------
-- Tick
-- ---------------------------------------------------------------------------

---Runs the current state's tick callback, then applies one queued transition.
---If a tick callback errors and an 'error' state exists, transitions there.
---@param dt any Passed through to the current state's tick callback.
---@return nil
function StateMachine:tick(dt)
    assert(self._current, 'StateMachine: call start() before tick()')
    assert(not self._ticking, 'StateMachine: re-entrant tick() detected')

    self._ticking = true

    local ok, err
    local tick_fn = self._current.tick
    if tick_fn then
        ok, err = pcall(tick_fn, dt)
    else
        ok = true
    end

    -- Collect and clear pending before any further work so that transitions
    -- triggered from on_enter during do_transition go through normally.
    local pending  = self._pending
    self._pending  = nil
    self._ticking  = false

    if not ok then
        if self._states['error'] then
            self._pending = nil
            do_transition(self, 'error', err)
        else
            error(err, 2)
        end
        return
    end

    if pending then
        do_transition(self, pending)
    end
end

-- ---------------------------------------------------------------------------
-- Query
-- ---------------------------------------------------------------------------

---Returns the current state name, or nil before start().
---@return StateName? current
function StateMachine:current()  return self._cur_name end
---Returns the previous state name, or nil before the first transition.
---@return StateName? previous
function StateMachine:previous() return self._prev     end
---Returns true when the current state name equals name.
---@param name StateName
---@return boolean is_current
function StateMachine:is(name)   return self._cur_name == name end

return StateMachine
