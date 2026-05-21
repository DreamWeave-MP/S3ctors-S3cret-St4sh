---
--- OpenMW Lua Language Server Plugin
--- Enforces script context annotations and module availability.
---
--- Usage
--- ------
--- 1. Add to your LuaLS settings:
---      "runtime.plugin": "./content/cod3x/omw_context_plugin.lua"
---
--- 2. Near the top of each script file, declare its context:
---      ---@omw-context global
---    Valid values: global | local | player | menu | load | none
---    Use "none" for API-agnostic Lua files that intentionally avoid openmw.*.
---
--- How it works
--- ------------
--- When LLS processes a file, this plugin:
---   a) caches the file text and parsed context via OnSetText
---   b) scans for ---@omw-context <ctx> in that text
---   c) ignores ---@meta files and plugin/tooling files under /cod3x/
---   d) poisons missing/invalid context annotations with an undefined global,
---   e) poisons offending require('openmw.*') calls with an undefined global,
---      which makes LuaLS emit its built-in undefined-global diagnostic
---   f) blocks LuaLS module resolution for the same offending modules via
---      ResolveRequire returning {}
---
--- Context semantics (matches OpenMW docs @context convention)
--- -----------------------------------------------------------
---   global  : global scripts (one per game world)
---   local   : local scripts attached to any object (excludes player extras)
---   player  : player-specific scripts (superset of local; adds camera, input, ui, …)
---   menu    : main menu scripts (no in-world access)
---   load    : content file scripts (pre-game data loading)
---   none    : API-agnostic Lua files that intentionally require no openmw.* modules
---
--- NOTE on LLS plugin API compatibility
--- -------------------------------------
--- LuaLS 3.18.2-dev dispatches plugin globals such as OnSetText,
--- OnTransformAst, and ResolveRequire.  It does not dispatch OnDiagnostics
--- from a returned plugin table, so this file defines global hooks directly.
---
--- TODO (future work)
--- ------------------
---   * Instead of the hardcoded AVAILABILITY table, derive it at startup
---     by reading the @context annotations from the openmw/*.lua stubs,
---     so the map stays in sync automatically as new modules are added.
---   * If future LuaLS versions expose more plugin hooks, consider adding
---     editor actions for inserting or correcting ---@omw-context annotations.
---
-- ---------------------------------------------------------------------------
-- Availability map
-- ---------------------------------------------------------------------------
-- Derived from the @context annotations in files/lua_api/openmw/*.lua.
-- Each entry maps a fully-qualified module name to the set of contexts in
-- which it is available.
--
-- "local" in OpenMW's own @context notation means "all local scripts,
-- including the player script".  We therefore list both "local" and "player"
-- for those modules.  Modules whose LDT annotation says only "player" are
-- genuinely player-exclusive (camera, input, ui…).
--

local AVAILABILITY = {
    -- Available in all script contexts
    ["openmw.async"]          = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.core"]           = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.markup"]         = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.storage"]        = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.types"]          = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.util"]           = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.vfs"]            = { global = true, ["local"] = true, player = true, menu = true, load = true },

    -- Runtime contexts only
    ["openmw.interfaces"]     = { global = true, ["local"] = true, player = true, menu = true },

    -- Load only
    ["openmw.content"]        = { load = true },

    -- Global only
    ["openmw.world"]          = { global = true },

    -- Local + player (not global, not menu)
    ["openmw.animation"]      = { ["local"] = true, player = true },
    ["openmw.nearby"]         = { ["local"] = true, player = true },
    ["openmw.self"]           = { ["local"] = true, player = true },

    -- Player + menu (not plain local, not global)
    ["openmw.ambient"]        = { player = true, menu = true },
    ["openmw.input"]          = { player = true, menu = true },
    ["openmw.ui"]             = { player = true, menu = true },

    -- Player only
    ["openmw.camera"]         = { player = true },
    ["openmw.debug"]          = { player = true },
    ["openmw.postprocessing"] = { player = true },

    -- Menu only
    ["openmw.menu"]           = { menu = true },
}

local VALID_CONTEXTS = { global = true, ["local"] = true, player = true, menu = true, load = true, none = true }

local MISSING_CONTEXT_POISON = "__OMW_CONTEXT_ERROR_missing_omw_context_add_none_if_api_agnostic__"
local INVALID_CONTEXT_POISON = "__OMW_CONTEXT_ERROR_invalid_omw_context__"

local fileCache = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Extract the ---@omw-context value from a file's text.
--- Returns nil if the annotation is absent.
---@param text string
---@return string?
local function parseContext(text)
    return text:match("%-%-%-%s*@omw%-context%s+(%S+)")
end

--- Return true if a file is a LuaLS doc/meta annotation file.
---@param text string
---@return boolean
local function hasMetaAnnotation(text)
    return text:match("%-%-%-%s*@meta%f[%W]") ~= nil
end

--- Return true if context annotations should be enforced for this URI.
---@param uri string?
---@return boolean
local function isContextRequiredForUri(uri)
    if not uri or not uri:match("%.lua$") then
        return false
    end

    return uri:find("/cod3x/", 1, true) == nil
end

--- Return the line prefix before a Lua line comment, ignoring -- inside strings.
---@param line string
---@return string
local function stripLineComment(line)
    local quote = nil
    local escaped = false

    for i = 1, #line do
        local ch = line:sub(i, i)
        local nextCh = line:sub(i + 1, i + 1)

        if quote then
            if escaped then
                escaped = false
            elseif ch == "\\" then
                escaped = true
            elseif ch == quote then
                quote = nil
            end
        elseif ch == '"' or ch == "'" then
            quote = ch
        elseif ch == "-" and nextCh == "-" then
            return line:sub(1, i - 1)
        end
    end

    return line
end

--- Normalize a module name passed by LuaLS.
---@param moduleName string
---@return string
local function normalizeModuleName(moduleName)
    return (moduleName:gsub("/", "."))
end

--- Return true if a module is an OpenMW module require.
---@param moduleName string
---@return boolean
local function isOpenMwModule(moduleName)
    return moduleName == "openmw" or moduleName:match("^openmw%.") ~= nil
end

--- Build a readable undefined global name for LuaLS to diagnose.
---@param ctx string?
---@param moduleName string
---@return string
local function poisonName(ctx, moduleName)
    local contextPart
    if not ctx then
        contextPart = "missing_context"
    elseif VALID_CONTEXTS[ctx] then
        contextPart = ctx
    else
        contextPart = "unknown_context_" .. ctx:gsub("%W", "_")
    end

    local modulePart = moduleName:gsub("%W", "_")
    return "__OMW_CONTEXT_ERROR_" .. contextPart .. "_cannot_require_" .. modulePart .. "__"
end

--- Insert an undefined global for a missing or invalid context annotation.
---@param diffs table[]
---@param ctx string?
local function insertContextPoisonDiff(diffs, ctx)
    if ctx and VALID_CONTEXTS[ctx] then
        return
    end

    table.insert(diffs, {
        start = 1,
        finish = 0,
        text = "local _ = " .. (ctx and INVALID_CONTEXT_POISON or MISSING_CONTEXT_POISON) .. "\n",
    })
end

--- Return true if a require should be blocked/poisoned in this source context.
---@param ctx string?
---@param moduleName string
---@return boolean
local function shouldReject(ctx, moduleName)
    if not isOpenMwModule(moduleName) then
        return false
    end

    if not ctx or not VALID_CONTEXTS[ctx] then
        return true
    end

    if ctx == "none" then
        return true
    end

    local moduleCtxs = AVAILABILITY[moduleName]
    if not moduleCtxs then
        return false
    end

    return not moduleCtxs[ctx]
end

--- Match a require call starting at `pos` in `line`.
---@param line string
---@param pos integer
---@return table?
local function matchRequireAt(line, pos)
    local before = pos > 1 and line:sub(pos - 1, pos - 1) or ""
    if before:match("[%w_%.:]") then
        return nil
    end

    local rest = line:sub(pos)
    local afterKeyword = rest:sub(8, 8)
    if afterKeyword:match("[%w_]") then
        return nil
    end

    local argStart, moduleName, argFinish = rest:match('^require%s*%(%s*()"([^"]+)"()%s*%)')
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            paren = true,
        }
    end

    argStart, moduleName, argFinish = rest:match("^require%s*%(%s*()'([^']+)'()%s*%)")
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            paren = true,
        }
    end

    argStart, moduleName, argFinish = rest:match('^require%s+()"([^"]+)"()')
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            paren = false,
        }
    end

    argStart, moduleName, argFinish = rest:match("^require%s+()'([^']+)'()")
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            paren = false,
        }
    end

    return nil
end

--- Scan `text` for require('openmw.*') calls and build poison edits.
---@param text string
---@param ctx string?
---@return table[]
local function makePoisonDiffs(text, ctx)
    local diffs = {}
    local lineStart = 1

    for lineText in (text .. "\n"):gmatch("([^\n]*)\n") do
        if not lineText:match("^%s*%-%-") then
            local code = stripLineComment(lineText)
            local searchStart = 1

            while true do
                local requireStart = code:find("require", searchStart, true)
                if not requireStart then
                    break
                end

                local req = matchRequireAt(code, requireStart)
                if req and shouldReject(ctx, req.module) then
                    local replacement = poisonName(ctx, req.module)
                    if not req.paren then
                        replacement = "(" .. replacement .. ")"
                    end

                    table.insert(diffs, {
                        start = lineStart + req.start - 1,
                        finish = lineStart + req.finish - 1,
                        text = replacement,
                    })
                    searchStart = req.finish + 1
                else
                    searchStart = requireStart + 7
                end
            end
        end

        lineStart = lineStart + #lineText + 1
    end

    return diffs
end

-- ---------------------------------------------------------------------------
-- File text cache
-- ---------------------------------------------------------------------------
-- ResolveRequire receives the module and source URI, not the full source text.
-- OnSetText keeps the source context cache current for resolution decisions.

-- ---------------------------------------------------------------------------
-- LLS plugin hooks
-- ---------------------------------------------------------------------------

--- Called by LLS whenever a file's text is set or updated.
--- We cache context and return poison-pill edits for invalid OpenMW requires.
---@param uri  string
---@param text string
---@return table[]?   -- nil = don't modify the text
function OnSetText(uri, text)
    if isContextRequiredForUri(uri) then
        local ctx = parseContext(text)
        local isMeta = hasMetaAnnotation(text)
        fileCache[uri] = { context = ctx, meta = isMeta }

        if isMeta then
            return nil
        end

        local diffs = makePoisonDiffs(text, ctx)
        insertContextPoisonDiff(diffs, ctx)

        if #diffs > 0 then
            return diffs
        end
    elseif uri and uri:match("%.lua$") then
        fileCache[uri] = nil
    end

    return nil
end

--- Called by LLS when resolving require().
---@param rootUri string
---@param moduleName string
---@param sourceUri string
---@return table?
function ResolveRequire(rootUri, moduleName, sourceUri)
    moduleName = normalizeModuleName(moduleName)
    if not isOpenMwModule(moduleName) then
        return nil
    end

    if sourceUri and not isContextRequiredForUri(sourceUri) then
        return nil
    end

    local cached = sourceUri and fileCache[sourceUri]
    if not cached then
        return nil
    end

    if cached.meta then
        return nil
    end

    if shouldReject(cached.context, moduleName) then
        return {}
    end

    return nil
end
