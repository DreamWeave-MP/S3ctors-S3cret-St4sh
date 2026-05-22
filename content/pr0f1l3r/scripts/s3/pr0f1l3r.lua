local input = require 'openmw.input'
local ui = require 'openmw.ui'

local TOP_N = 100

local function nullfunction() end
local tick = nullfunction

local collectgarbage, debug, io, os_clock, jit_v, jit_dump, tmpPath, tmpFile
do
  ---@diagnostic disable-next-line: param-type-mismatch
  local S              = select 'sandbox.bypass'
  local OMWRequire     = require
  collectgarbage       = S.package.loaded.base.collectgarbage
  require              = S.require
  S.package.loaded.jit = S.jit
  debug                = S.debug
  io                   = S.io
  os_clock             = S.os.clock
  jit_v                = require 'jit.v'
  jit_dump             = require 'jit.dump'
  tmpPath              = S.os.tmpname()
  tmpFile              = S.io.open(tmpPath, 'w')
  require              = OMWRequire
end

local function readAndPrintFile(path, prefix, filter)
  local f = io.open(path, 'r')
  if not f then return end
  for line in f:lines() do
    if not filter or line:find(filter, 1, true) then
      print(prefix .. line)
    end
  end
  f:close()
end

-- ── call counter ─────────────────────────────────────────────────────────────

local callCounts = {}
local function countingHook()
  local info = debug.getinfo(2, 'nfS')
  local name = (info.name and info.name ~= '') and info.name or tostring(info.func)
  local source = info.short_src or '?'

  local caller = debug.getinfo(3, 'nS')
  local callerDesc = caller
      and ('%s:%s'):format(caller.short_src or '?', caller.linedefined or '?')
      or '?'

  local key = ('%s:%s %s  ← %s'):format(source, info.linedefined or '?', name, callerDesc)
  callCounts[key] = (callCounts[key] or 0) + 1
end

local function startCallCounter()
  print '[JIT] ══════════════ call counter: START ════════════'
  callCounts = {}
  debug.sethook(countingHook, 'c')
end

local function stopCallCounter(filter)
  debug.sethook()
  print('[JIT] ══════════════ call counter: RESULTS' ..
    (filter and (' [filter: %s]'):format(filter) or '') .. ' ══════════')
  local sorted = {}
  for k, v in pairs(callCounts) do
    if not filter or k:find(filter, 1, true) then
      sorted[#sorted + 1] = { k, v }
    end
  end
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

-- ── timing profiler (debug hook + os.clock) ──────────────────────────────────

local timings = {}
local timeStack = {}
local timingActive = false

local function timingHook(event)
  if event == 'call' then
    timeStack[#timeStack + 1] = os_clock()
  elseif event == 'return' then
    local n = #timeStack
    if n == 0 then return end
    local elapsed = os_clock() - timeStack[n]
    timeStack[n] = nil

    local info = debug.getinfo(2, 'nfS')
    local name = (info.name and info.name ~= '') and info.name or tostring(info.func)
    local source = info.short_src or '?'
    local key = ('%s:%s %s %s'):format(source, info.linedefined or '?', name, info.namewhat)
    timings[key] = (timings[key] or 0) + elapsed
  end
end

local function startTimingProfiler()
  print '[JIT] ══════════════════ timing profiler: START ═════════'
  timings = {}
  timeStack = {}
  debug.sethook(timingHook, 'cr')
  timingActive = true
end

local profilingFrame = 0
local function stopTimingProfiler(filter)
  if not timingActive then return end
  debug.sethook()
  timingActive = false

  print('[JIT] ══════════════ timing profiler: RESULTS' ..
    (filter and (' [filter: %s]'):format(filter) or '') .. ' ══════════')

  local sorted = {}
  for k, v in pairs(timings) do
    if not filter or k:find(filter, 1, true) then
      sorted[#sorted + 1] = { k, v }
    end
  end

  table.sort(sorted, function(a, b) return a[2] > b[2] end)

  local frames = profilingFrame > 0 and profilingFrame or 1
  local limit = math.min(TOP_N, #sorted)
  for i = 1, limit do
    local total = sorted[i][2] * 1000
    print(('[JIT time] %8.2fms total  %6.4fms/frame  %s'):format(total, total / frames, sorted[i][1]))
  end
  if #sorted > limit then
    print(('[JIT time] ... %d more entries omitted'):format(#sorted - limit))
  end

  timings = {}
  timeStack = {}
end

-- ── memory allocation profiler ───────────────────────────────────────────────

local memAllocs = {}
local memStack  = {}
local memActive = false

local function memHook(event)
  if event == 'call' then
    memStack[#memStack + 1] = collectgarbage('count')
  elseif event == 'return' then
    local n = #memStack
    if n == 0 then return end
    local delta = collectgarbage('count') - memStack[n]
    memStack[n] = nil

    if delta <= 0 then return end

    local info = debug.getinfo(2, 'nfS')
    local name = (info.name and info.name ~= '') and info.name or tostring(info.func)
    local source = info.short_src or '?'
    local key = ('%s:%s %s %s'):format(source, info.linedefined or '?', name, info.namewhat)
    memAllocs[key] = (memAllocs[key] or 0) + delta
  end
end

local function startMemProfiler()
  print '[JIT] ════════════════ memory profiler: START ═══════════'
  memAllocs = {}
  memStack  = {}
  collectgarbage('stop')
  debug.sethook(memHook, 'cr')
  memActive = true
end

local function stopMemProfiler(filter)
  if not memActive then return end
  debug.sethook()
  collectgarbage('restart')
  memActive = false

  print('[JIT] ════════════════ memory profiler: RESULTS' ..
    (filter and (' [filter: %s]'):format(filter) or '') .. ' ════════')

  local sorted = {}
  for k, v in pairs(memAllocs) do
    if not filter or k:find(filter, 1, true) then
      sorted[#sorted + 1] = { k, v }
    end
  end

  table.sort(sorted, function(a, b) return a[2] > b[2] end)

  local limit = math.min(TOP_N, #sorted)
  for i = 1, limit do
    print(('[JIT mem] %8.2f KB  %s'):format(sorted[i][2], sorted[i][1]))
  end
  if #sorted > limit then
    print(('[JIT mem] ... %d more entries omitted'):format(#sorted - limit))
  end

  memAllocs = {}
  memStack  = {}
end

-- ── file cleanup ──────────────────────────────────────────────────────────────

local function closeTmpFile()
  if tmpFile then
    tmpFile:close()
    tmpFile = nil
  end
end

-- ── keybinds ──────────────────────────────────────────────────────────────────
--   Shift+F3: timing profiler (300 frames, all scripts)
--   F3:       standalone call counter (300 frames, all scripts)
--   F4:       full pipeline (jit.v → jit.dump → call counter)
--   Ctrl+Shift+Z: memory allocation profiler (300 frames, all scripts)
--   Shift+F4: stop whatever is running early

-- ── full pipeline (F4) ────────────────────────────────────────────────────────
-- frames  1 – 100: jit.v on,  warming up
-- frames 101 – 200: jit.dump on for one more warm pass
-- frames 201 – 500: call counter sampling live onUpdate
-- frame  500:       all results dumped, profiling done

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
  interfaceName = 'pr0f1l3r',
  interface = {
    benchAll = function()
      stopCallCounter()
      profilingFrame = 0
      tick = tickProfiler
    end,
    bench = function(path)
      if tick ~= nullfunction then
        ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
        return
      end
      profilingFrame = 0
      startCallCounter()
      tick = function()
        profilingFrame = profilingFrame + 1
        if profilingFrame == 300 then
          stopCallCounter(path)
          tick = nullfunction
        end
      end
    end,
    benchTime = function(path)
      if tick ~= nullfunction then
        ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
        return
      end

      profilingFrame = 0
      startTimingProfiler()
      tick = function()
        profilingFrame = profilingFrame + 1
        if profilingFrame == 300 then
          stopTimingProfiler(path)
          tick = nullfunction
        end
      end
    end,
    benchMem = function(path)
      if tick ~= nullfunction then
        ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
        return
      end

      profilingFrame = 0
      startMemProfiler()
      tick = function()
        profilingFrame = profilingFrame + 1
        if profilingFrame == 300 then
          stopMemProfiler(path)
          tick = nullfunction
        end
      end
    end,
  },
  engineHandlers = {
    onKeyPress = function(key)
      if key.code == input.KEY.F3 and key.withShift then
        if tick ~= nullfunction then
          ui.showMessage '[JIT] already profiling — press Shift+F3 to stop'
          return
        end

        profilingFrame = 0
        startTimingProfiler()

        tick = function()
          profilingFrame = profilingFrame + 1
          if profilingFrame == 300 then
            stopTimingProfiler()
            tick = nullfunction
          end
        end
      elseif key.code == input.KEY.F3 then
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
      elseif key.code == input.KEY.Z and key.withShift and key.withCtrl then
        if tick ~= nullfunction then
          ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
          return
        end
        profilingFrame = 0
        startMemProfiler()
        tick = function()
          profilingFrame = profilingFrame + 1
          if profilingFrame == 300 then
            stopMemProfiler()
            tick = nullfunction
          end
        end
      elseif key.code == input.KEY.F4 then
        if key.withShift then
          stopCallCounter()
          stopTimingProfiler()
          stopMemProfiler()
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
