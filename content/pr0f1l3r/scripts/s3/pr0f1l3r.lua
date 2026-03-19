local input = require 'openmw.input'

local debug, jit_v, jit_dump
do
  ---@diagnostic disable-next-line: param-type-mismatch
  local S              = select 'sandbox.bypass'
  local OMWRequire     = require
  require              = S.require
  S.package.loaded.jit = S.jit
  debug                = S.debug
  jit_v                = require 'jit.v'
  jit_dump             = require 'jit.dump'
  require              = OMWRequire
end

local callCounts = {}
local function countingHook()
  local info      = debug.getinfo(2, 'nf')
  local key       = (info.name and info.name ~= '') and info.name or tostring(info.func)
  callCounts[key] = (callCounts[key] or 0) + 1
end

local function startCallCounter()
  print '[JIT] ══════════════ call counter: START ════════════'
  callCounts = {}
  debug.sethook(countingHook, 'c')
end

local function stopCallCounter()
  debug.sethook()
  print '[JIT] ══════════════ call counter: RESULTS ══════════'
  local sorted = {}
  for k, v in pairs(callCounts) do sorted[#sorted + 1] = { k, v } end
  table.sort(sorted, function(a, b) return a[2] > b[2] end)

  for _, pair in ipairs(sorted) do
    print(('[JIT calls] %6d  %s'):format(pair[2], pair[1]))
  end

  callCounts = {}
end

-- Frame counter driving all profiling phases:
--   frames  1– 100: jit.v on,  warming up handlePlayback
--   frames 101– 200: jit.dump on for one more warm pass
--   frames 201– 500: call counter sampling live onUpdate
--   frame  500:      all results dumped, profiling done

local profilingFrame = 0
local function tickProfiler()
  profilingFrame = profilingFrame + 1

  if profilingFrame == 1 then
    print '[JIT] ══════════════════ trace log (jit.v) ═════════'
    jit_v.on()
  elseif profilingFrame == 100 then
    jit_v.off()
    print '[JIT] ══════════════════ IR dump (jit.dump) ══════════'
    jit_dump.on('tbisrX')
  elseif profilingFrame == 200 then
    jit_dump.off()
    startCallCounter()
  elseif profilingFrame == 500 then
    stopCallCounter()
  end
end

local function nullfunction() end
local tick = nullfunction

return {
  engineHandlers = {
    onKeyPress = function(key)
      if key.code ~= input.KEY.F4 then return end

      if key.withShift then
        stopCallCounter()
        tick = nullfunction
      else
        startCallCounter()

        profilingFrame = 0
        tick = tickProfiler
      end
    end,
    onUpdate = function(_)
      tick()
    end,
  }
}
