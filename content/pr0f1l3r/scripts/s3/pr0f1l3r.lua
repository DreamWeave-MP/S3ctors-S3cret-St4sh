local input = require 'openmw.input'
local ui = require 'openmw.ui'

local TOP_N = 35

local function nullfunction() end
local tick = nullfunction

local debug, io, jit_v, jit_dump, tmpPath, tmpFile
do
  ---@diagnostic disable-next-line: param-type-mismatch
  local S              = select 'sandbox.bypass'
  local OMWRequire     = require
  require              = S.require
  S.package.loaded.jit = S.jit
  debug                = S.debug
  io                   = S.io
  jit_v                = require 'jit.v'
  jit_dump             = require 'jit.dump'
  tmpPath              = S.os.tmpname()
  tmpFile              = S.io.open(tmpPath, 'w')
  require              = OMWRequire
end

local function readAndPrintFile(path, prefix)
  local f = io.open(path, 'r')
  if not f then return end
  for line in f:lines() do
    print(prefix .. line)
  end
  f:close()
end

local callCounts = {}
local function countingHook()
  local info = debug.getinfo(2, 'nfS')
  local name = (info.name and info.name ~= '') and info.name or tostring(info.func)
  local source = info.short_src or '?'
  local key = ('%s:%s %s'):format(source, info.linedefined or '?', name)
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

  local limit = math.min(TOP_N, #sorted)
  for i = 1, limit do
    print(('[JIT calls] %6d  %s'):format(sorted[i][2], sorted[i][1]))
  end
  if #sorted > limit then
    print(('[JIT calls] ... %d more entries omitted'):format(#sorted - limit))
  end

  callCounts = {}
end

local function closeTmpFile()
  if tmpFile then
    tmpFile:close()
    tmpFile = nil
  end
end

-- Keybinds:
--   F4:       full pipeline (jit.v → jit.dump → call counter)
--   F3:       standalone call counter only (300 frames)
--   Shift+F4: stop whatever is running early

-- Frame counter driving all profiling phases:
--   frames  1 – 100: jit.v on,  warming up
--   frames 101 – 200: jit.dump on for one more warm pass
--   frames 201 – 500: call counter sampling live onUpdate
--   frame  500:      all results dumped, profiling done

local profilingFrame = 0
local function tickProfiler()
  profilingFrame = profilingFrame + 1

  if profilingFrame == 1 then
    print '[JIT] ══════════════════ trace log (jit.v) ═════════'
    tmpFile:flush()
    tmpFile:seek('set', 0)
    jit_v.on(tmpPath)
  elseif profilingFrame == 100 then
    jit_v.off()
    tmpFile:flush()
    readAndPrintFile(tmpPath, '[JIT Trace] ')
    print '[JIT] ══════════════════ IR dump (jit.dump) ══════════'
    tmpFile:seek('set', 0)
    jit_dump.on('tbisrXT', tmpPath)
  elseif profilingFrame == 200 then
    jit_dump.off()
    tmpFile:flush()
    readAndPrintFile(tmpPath, '[JIT Dump] ')
    tmpFile:seek('set', 0)
    startCallCounter()
  elseif profilingFrame == 500 then
    stopCallCounter()
    closeTmpFile()
    tick = nullfunction
  end
end

return {
  engineHandlers = {
    onKeyPress = function(key)
      if key.code == input.KEY.F3 then
        if tick ~= nullfunction then
          ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
          return
        end

        profilingFrame = 0
        startCallCounter()

        tick = function()
          profilingFrame = profilingFrame + 1
          if profilingFrame == 300 then
            stopCallCounter()
            tick = nullfunction
          end
        end

      elseif key.code == input.KEY.F4 then
        if key.withShift then
          stopCallCounter()
          closeTmpFile()
          tick = nullfunction
        elseif tick ~= nullfunction then
          ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
        else
          profilingFrame = 0
          tick = tickProfiler
        end
      end
    end,
    onUpdate = function(_)
      tick()
    end,
  }
}
