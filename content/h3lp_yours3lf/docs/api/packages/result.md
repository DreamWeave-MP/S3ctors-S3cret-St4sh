---
title: Result
description: Represent success and failure explicitly without unchecked nil conventions.
weight: 36
extra:
  kind: api
---

{{ api_signature(value="require 'scripts.s3.result' → Result; Result.Ok(value) / Result.Err(error)") }}

Result is for functions where `nil` does not tell the caller enough. Return `Ok(value)` or `Err(reason)` and make the failure path explicit.

{% usage_note(title="Plain Lua values · Not a serializer") %}
Results are mutable tables with metatables and may contain arbitrary values. Do not put closures, engine userdata, or a Result object itself into save data unless your own save contract defines and reconstructs them.
{% end %}

## Construction and inspection

```lua
local Result = require 'scripts.s3.result'
local vfs = require 'openmw.vfs'

local function readConfig(path)
    local file, openError = vfs.open(path)
    if not file then return Result.Err(openError) end

    local contents, readError = file:read '*all'
    file:close()
    if not contents then return Result.Err(readError) end
    return Result.Ok(contents)
end

local config = readConfig('MyMod/config')
if config:is_ok() then
    applyConfig(config:unwrap())
else
    print('MyMod config unavailable:', config:unwrap_err())
end
```

`Result.Ok(nil)` is a successful result. `Result.Err(error)` requires a non-`nil` error value; strings are easiest to display, but other values are accepted.

| Method | Behavior |
| --- | --- |
| `is_ok()` / `is_err()` | Identify the variant. |
| `unwrap()` | Return the Ok value or raise with the Err value. |
| `unwrap_or(default)` | Return the Ok value or the supplied default. |
| `unwrap_err()` | Return the error or raise because the result is Ok. |
| `expect(message)` | Return the value or raise with the supplied message and error. |

## Transforming and matching

`map(fn)` transforms only Ok values and propagates Err unchanged. `map_err(fn)` transforms only errors and propagates Ok unchanged. `and_then(fn)` calls `fn(value)` for Ok values; `fn` must return a Result. `or_else(fn)` is the corresponding Err path and also requires a Result return.

```lua
local result = readConfig('MyMod/config')
    :map(function(contents) return contents:gsub('\r\n', '\n') end)
    :map_err(function(message) return 'MyMod config: ' .. tostring(message) end)

local contents, errorMessage = result:match {
    ok = function(value) return value end,
    err = function(message) return nil, message end,
}
```

`match` requires the handler for the active variant. Handler errors propagate normally.

## Utilities

`Result.try(fn, ...)` calls `fn` with `pcall` and returns `Ok(firstReturnValue)` on success or `Err(error)` on failure. Successful extra return values are discarded. A successful function with no return value produces `Ok(nil)`.

`Result.all(results)` walks the array with `ipairs`, stops at the first Err, and otherwise returns `Ok({ values... })`. It intentionally uses an ordinary array: `Ok(nil)` values become nil slots and positional nils are not packed.

Results allocate a table at construction and preserve referenced values without copying. Use ordinary returns when a two-variant contract adds no clarity.
