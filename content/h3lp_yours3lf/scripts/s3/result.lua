---@omw-context none
---Rust-inspired Result type: Ok(value) and Err(error).
---
---Err accepts any non-nil error value, though strings are easiest to print.
---
--- Usage:
---  local Result = require 'scripts.s3.result'
---   local Ok, Err = Result.Ok, Result.Err
---
--- A Result is either a success (Ok) or a failure (Err). It forces you to
--- explicitly handle both cases rather than letting errors silently propagate
--- as nil returns or unchecked pcall results.
---
--- Construction:
---   local r = Ok(42)
---   local r = Err('something went wrong')
---
---  -- Wrap a fallible function (pcall-based). Only the first successful
---  -- return value is preserved.
---  local r = Result.try(fn, arg1, arg2)
---
--- Inspection:
---   r:is_ok()              --> bool
---   r:is_err()             --> bool
---
--- Extracting values:
---   r:unwrap()             --> value, or raises the error message
---   r:unwrap_or(default)   --> value, or default if Err
---   r:unwrap_err()         --> error message, or raises if Ok
---   r:expect(msg)          --> value, or raises msg .. ': ' .. err
---
--- Transforming:
---   r:map(fn)              --> Ok(fn(value)) if Ok, else propagates Err unchanged
---   r:map_err(fn)          --> Err(fn(err))  if Err, else propagates Ok unchanged
---   r:and_then(fn)         --> fn(value) if Ok (fn must return a Result), else Err
---   r:or_else(fn)          --> fn(err)   if Err (fn must return a Result), else Ok
---
--- Pattern matching (cleaner than chained if/else):
---   r:match({
---       ok  = function(value) ... end,
---       err = function(msg)   ... end,
---   })
---
--- Collecting multiple results (fails fast on first Err):
---   Result.all({ r1, r2, r3 })   --> Ok({ v1, v2, v3 }) or first Err
---
--- Notes:
---   - Results are plain tables; they are not protected from mutation.
---   - nil is a valid Ok value. Ok(nil):is_ok() == true.
---   - Result.all does not pack returned values. Ok(nil) entries produce nil
---     array slots; callers who care must avoid nil Ok values or handle sparse
---     arrays by normal Lua rules.

---@class ResultModule
---@field Ok fun(value: any): OkResult
---@field Err fun(err: any): ErrResult
---@field try fun(fn: function, ...: any): Result Wraps pcall; preserves only the first success return.
---@field all fun(results: Result[]): Result Converts all Ok values to Ok(array), or returns the first Err.

---@class Result
---@field is_ok fun(self: Result): boolean
---@field is_err fun(self: Result): boolean
---@field unwrap fun(self: Result): any
---@field unwrap_or fun(self: Result, default: any): any
---@field unwrap_err fun(self: Result): any
---@field expect fun(self: Result, msg: string): any
---@field map fun(self: Result, fn: fun(value: any): any): Result
---@field map_err fun(self: Result, fn: fun(err: any): any): Result
---@field and_then fun(self: Result, fn: fun(value: any): Result): Result
---@field or_else fun(self: Result, fn: fun(err: any): Result): Result
---@field match fun(self: Result, cases: ResultMatchCases): any
local Result = {}

---@class OkResult: Result

---@class ErrResult: Result

---@class ResultMatchCases
---@field ok? fun(value: any): any Required for Ok results; raises if missing.
---@field err? fun(err: any): any Required for Err results; raises if missing.

-- Sentinel to distinguish Ok(nil) from a missing value.
local NIL_SENTINEL = {}

-- Tag fields use unique table keys so they cannot be accidentally set.
local OK_TAG = {}
local ERR_TAG = {}

local OkMethods = {}
local ErrMethods = {}

local OkMeta = { __index = OkMethods }
local ErrMeta = { __index = ErrMethods }

---@param value any
---@return boolean
local function is_result(value)
    return type(value) == 'table'
        and (rawget(value, OK_TAG) ~= nil or rawget(value, ERR_TAG) ~= nil)
end

---@param self Result
---@return any
local function ok_value(self)
    local value = rawget(self, OK_TAG)
    if value == NIL_SENTINEL then return nil end
    return value
end

---Creates an Ok result. nil is accepted and preserved by unwrap/expect.
---@param value any nil is accepted and preserved by unwrap/expect.
---@return OkResult
function Result.Ok(value)
    return setmetatable({
        [OK_TAG] = value == nil and NIL_SENTINEL or value,
    }, OkMeta)
end

---Creates an Err result. Any non-nil error value is accepted.
---@param err any Raises if nil.
---@return ErrResult
function Result.Err(err)
    assert(err ~= nil, 'Err: error value must not be nil')
    return setmetatable({
        [ERR_TAG] = err,
    }, ErrMeta)
end

local Ok = Result.Ok
local Err = Result.Err

-- ---------------------------------------------------------------------------
-- Inspection
-- ---------------------------------------------------------------------------

---Returns true for Ok results.
---@return boolean is_ok
function OkMethods:is_ok() return true end

---Returns false for Err results.
---@return boolean is_ok
function ErrMethods:is_ok() return false end

---Returns false for Ok results.
---@return boolean is_err
function OkMethods:is_err() return false end

---Returns true for Err results.
---@return boolean is_err
function ErrMethods:is_err() return true end

-- ---------------------------------------------------------------------------
-- Extraction
-- ---------------------------------------------------------------------------

---Returns the Ok value.
---@return any value
function OkMethods:unwrap()
    return ok_value(self)
end

---Raises with the Err value.
---@return nil Raises with the Err value.
function ErrMethods:unwrap()
    error('called unwrap() on Err: ' .. tostring(rawget(self, ERR_TAG)), 2)
end

---Returns the Ok value, ignoring the default.
---@param _default any Ignored for Ok results.
---@return any value
function OkMethods:unwrap_or(_default)
    return ok_value(self)
end

---Returns the supplied default for Err results.
---@param default any
---@return any default
function ErrMethods:unwrap_or(default)
    return default
end

---Raises because this is Ok.
---@return nil Raises because this is Ok.
function OkMethods:unwrap_err()
    error('called unwrap_err() on Ok', 2)
end

---Returns the Err value.
---@return any err
function ErrMethods:unwrap_err()
    return rawget(self, ERR_TAG)
end

---Returns the Ok value, ignoring the message.
---@param _msg string Ignored for Ok results.
---@return any value
function OkMethods:expect(_msg)
    return ok_value(self)
end

---Raises with msg and the Err value.
---@param msg string
---@return nil Raises with msg and the Err value.
function ErrMethods:expect(msg)
    error(msg .. ': ' .. tostring(rawget(self, ERR_TAG)), 2)
end

-- ---------------------------------------------------------------------------
-- Transformation
-- ---------------------------------------------------------------------------

---Maps an Ok value through fn and wraps it in Ok.
---@param fn fun(value: any): any
---@return OkResult
function OkMethods:map(fn)
    return Ok(fn(ok_value(self)))
end

---Propagates this Err unchanged.
---@param _fn fun(value: any): any Ignored for Err results.
---@return ErrResult self
function ErrMethods:map(_fn)
    return self
end

---Propagates this Ok unchanged.
---@param _fn fun(err: any): any Ignored for Ok results.
---@return OkResult self
function OkMethods:map_err(_fn)
    return self
end

---Maps an Err value through fn and wraps it in Err.
---@param fn fun(err: any): any
---@return ErrResult
function ErrMethods:map_err(fn)
    return Err(fn(rawget(self, ERR_TAG)))
end

---Chains an Ok value through fn, which must return a Result.
---@param fn fun(value: any): Result Must return a Result; raises otherwise.
---@return Result
function OkMethods:and_then(fn)
    local result = fn(ok_value(self))
    assert(is_result(result), 'and_then: function must return a Result')
    return result
end

---Propagates this Err unchanged.
---@param _fn fun(value: any): Result Ignored for Err results.
---@return ErrResult self
function ErrMethods:and_then(_fn)
    return self
end

---Propagates this Ok unchanged.
---@param _fn fun(err: any): Result Ignored for Ok results.
---@return OkResult self
function OkMethods:or_else(_fn)
    return self
end

---Chains an Err value through fn, which must return a Result.
---@param fn fun(err: any): Result Must return a Result; raises otherwise.
---@return Result
function ErrMethods:or_else(fn)
    local result = fn(rawget(self, ERR_TAG))
    assert(is_result(result), 'or_else: function must return a Result')
    return result
end

-- ---------------------------------------------------------------------------
-- Pattern matching
-- ---------------------------------------------------------------------------

---Calls cases.ok with the Ok value.
---@param cases ResultMatchCases Raises if ok handler is missing.
---@return any
function OkMethods:match(cases)
    assert(type(cases.ok) == 'function', 'match: missing ok handler')
    return cases.ok(ok_value(self))
end

---Calls cases.err with the Err value.
---@param cases ResultMatchCases Raises if err handler is missing.
---@return any
function ErrMethods:match(cases)
    assert(type(cases.err) == 'function', 'match: missing err handler')
    return cases.err(rawget(self, ERR_TAG))
end

-- ---------------------------------------------------------------------------
-- Tostring (useful for debug logging)
-- ---------------------------------------------------------------------------

---@param self OkResult
---@return string
OkMeta.__tostring = function(self)
    return ('Ok(%s)'):format(tostring(ok_value(self)))
end

---@param self ErrResult
---@return string
ErrMeta.__tostring = function(self)
    return ('Err(%s)'):format(tostring(rawget(self, ERR_TAG)))
end

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------

---Wraps a fallible function call.
---Returns Ok(first_return_value) or Err(error); successful extra returns are discarded.
---@param fn function Raises are captured as Err.
---@param ... any
---@return Result result Ok(first_return_value) or Err(error_value).
function Result.try(fn, ...)
    local ok, value = pcall(fn, ...)
    if ok then
        return Ok(value)
    end
    return Err(value)
end

---Collects a list of Results, failing fast on the first Err.
---Returns Ok({ values... }) if all are Ok, or the first Err encountered. This
---intentionally does not pack values: Ok(nil) entries become nil array slots.
---@param results Result[]
---@return Result result Ok(array) if all Ok, otherwise the first Err.
function Result.all(results)
    local values = {}
    for i, result in ipairs(results) do
        if result:is_err() then return result end
        values[i] = result:unwrap()
    end
    return Ok(values)
end

---@cast Result ResultModule
return Result
