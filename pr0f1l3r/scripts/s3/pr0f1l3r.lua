---@omw-context player
local input = require 'openmw.input'
local ui = require 'openmw.ui'

local TOP_N = 100
local TRACE_IR_LIMIT = 24
local TRACE_SNAP_LIMIT = 8
local TRACE_SNAP_SLOT_LIMIT = 24
local TRACE_DETAIL_LIMIT = 32
local TRACE_EVENT_LIMIT = 512
local TRACE_SIDEEXIT_LIMIT = 256
local TRACE_AGGREGATE_LIMIT = 256
local TRACE_RAW_LINE_LIMIT = 1024
local DEFAULT_CAPTURE_FRAMES = 300
local DEFAULT_PROFILE_FRAMES = 300
local JIT_DUMP_MODE = 'bi'

local function nullfunction() end
local tick = nullfunction

local collectgarbage, debug, io, os_clock, jit, jit_util, jit_vmdef, jit_v, jit_dump, tracePath, dumpPath, tmpFile
local bit_band, bit_rshift
local profilerJitOffOk, profilerJitOffErr
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
  jit                  = S.jit
  jit_util             = require 'jit.util'
  jit_vmdef            = require 'jit.vmdef'
  local okBit, bit     = pcall(require, 'bit')
  if okBit and bit then
    bit_band           = bit.band
    bit_rshift         = bit.rshift
  end
  jit_v                = require 'jit.v'
  jit_dump             = require 'jit.dump'
  tracePath            = S.os.tmpname()
  dumpPath             = S.os.tmpname()
  profilerJitOffOk, profilerJitOffErr = pcall(jit.off, true, true)
  require              = OMWRequire
end

local profilingFrame = 0
local activeRunId = '-'
local nextRunId = 0
local profilerMode = 'idle'
local currentPhase = '-'
local scenarioLabel
local traceAttached = false
local traceEventCount = 0
local traceEventTruncated = false
local traceEventOverflow = {}
local traceEventOverflowDistinct = 0
local traceEventOverflowDroppedOccurrences = 0
local traceDetailCount = 0
local traceDetailTruncated = false
local traceAborts = {}
local traceAbortsDistinct = 0
local traceAbortsDroppedOccurrences = 0
local sideExitLines = {}
local sideExitDistinct = 0
local sideExitDroppedOccurrences = 0
local sideExitCount = 0
local sideExitTruncated = false
local hotStats = {}

local function quoteValue(value)
  if value == nil then return nil end
  local s = tostring(value)
  if s == '' or s:find('%s') or s:find('"', 1, true) or s:find('\\', 1, true) then
    s = s:gsub('\\', '\\\\'):gsub('"', '\\"')
    return '"' .. s .. '"'
  end
  return s
end

local function field(name, value)
  local quoted = quoteValue(value)
  return quoted and (name .. '=' .. quoted) or false
end

local function appendField(parts, name, value)
  local f = field(name, value)
  if f then parts[#parts + 1] = f end
end

local function baseFields(extra)
  local parts = {}
  appendField(parts, 'run', activeRunId)
  appendField(parts, 'frame', profilingFrame or 0)
  appendField(parts, 'mode', profilerMode)
  appendField(parts, 'phase', currentPhase)
  appendField(parts, 'scenario', scenarioLabel)
  if extra then
    for i = 1, #extra do
      if extra[i] then parts[#parts + 1] = extra[i] end
    end
  end
  return table.concat(parts, ' ')
end

local function printWithFields(prefix, extra, message)
  local fields = baseFields(extra)
  print(prefix .. ' ' .. fields .. (message and (' ' .. message) or ''))
end

printWithFields('[JIT]', {
  field('event', 'profiler-jit-off'), field('ok', profilerJitOffOk), field('error', profilerJitOffErr),
})

local function safeFuncInfo(func, pc)
  if type(func) ~= 'function' then return nil end
  local ok, info = pcall(jit_util.funcinfo, func, pc)
  if ok then return info end
  return nil
end

local function funcFields(func, pc)
  local parts = {}
  local info = safeFuncInfo(func, pc)
  appendField(parts, 'func', func and tostring(func) or nil)
  appendField(parts, 'pc', pc)
  if info then
    appendField(parts, 'source', info.source or info.short_src or info.loc)
    appendField(parts, 'linedefined', info.linedefined)
    appendField(parts, 'currentline', info.currentline)
    appendField(parts, 'line', info.currentline)
    appendField(parts, 'loc', info.loc)
    appendField(parts, 'ffid', info.ffid)
    appendField(parts, 'addr', info.addr and string.format('0x%x', info.addr) or nil)
  end
  return parts, info
end

local function traceError(err, info)
  if type(err) == 'number' then
    local fmt = jit_vmdef.traceerr and jit_vmdef.traceerr[err]
    if fmt then
      if fmt == 'NYI: bytecode %s' and type(info) == 'number' then
        info = string.sub(jit_vmdef.bcnames, 6 * info + 1, 6 * info + 6)
      elseif type(info) == 'function' then
        local fi = safeFuncInfo(info)
        info = (fi and (fi.loc or fi.source or fi.short_src)) or tostring(info)
      end
      local ok, message = pcall(string.format, fmt, info)
      if ok then return message end
    end
  end
  return err
end

local function tupleString(ok, ...)
  if not ok then return nil end
  local n = select('#', ...)
  if n == 0 then return nil end
  local parts = {}
  for i = 1, n do
    parts[i] = tostring(select(i, ...))
  end
  return table.concat(parts, ',')
end

local function pack(...)
  return { n = select('#', ...), ... }
end

local function filterText(row)
  local parts = {}
  for _, name in ipairs({
    'entry', 'source', 'name', 'func', 'caller_entry', 'caller_source', 'caller_name', 'caller_func'
  }) do
    if row[name] ~= nil then parts[#parts + 1] = tostring(row[name]) end
  end
  return table.concat(parts, ' ')
end

local function rowMatchesFilter(row, filter)
  return not filter or filterText(row):find(filter, 1, true) ~= nil
end

local function aggregateFuncRow(info)
  local name = (info.name and info.name ~= '') and info.name or tostring(info.func)
  local source = info.short_src or info.source or '?'
  return {
    source = source,
    linedefined = info.linedefined,
    currentline = info.currentline,
    line = info.currentline,
    func = info.func and tostring(info.func) or nil,
    name = name,
    namewhat = info.namewhat,
    entry = ('%s:%s %s %s'):format(source, info.linedefined or '?', name, info.namewhat or ''),
  }
end

local function aggregateFields(row)
  return {
    field('entry', row.entry),
    field('source', row.source),
    field('linedefined', row.linedefined),
    field('currentline', row.currentline),
    field('line', row.line),
    field('func', row.func),
    field('name', row.name),
    field('namewhat', row.namewhat),
  }
end

local function irName(opId)
  if not (jit_vmdef.irnames and opId) then return nil end
  local start = opId * 6 + 1
  local name = jit_vmdef.irnames:sub(start, start + 5):gsub('%s+$', '')
  return name ~= '' and name or nil
end

local function traceIrFields(tr, idx, m, ot, op1, op2, ridsp)
  local fields = { field('tr', tr), field('idx', idx), field('raw_m', m), field('raw_ot', ot), field('op1', op1), field('op2', op2), field('ridsp', ridsp) }
  if bit_band and bit_rshift and type(ot) == 'number' then
    local opId = bit_rshift(ot, 8)
    local typeId = bit_band(ot, 31)
    fields[#fields + 1] = field('op_id', opId)
    fields[#fields + 1] = field('op', irName(opId))
    fields[#fields + 1] = field('type_id', typeId)
  else
    fields[#fields + 1] = field('raw_words', tupleString(true, m, ot, op1, op2, ridsp))
  end
  return fields
end

local function printSnapTable(tr, idx, snap)
  local rawEntries = 0
  local maxEntryIdx = 1
  for key in pairs(snap) do
    if type(key) == 'number' and key >= 2 and key == math.floor(key) then
      rawEntries = rawEntries + 1
      if key > maxEntryIdx then maxEntryIdx = key end
    end
  end

  printWithFields('[JIT snap]', {
    field('tr', tr), field('idx', idx), field('ref', snap[0]),
    field('slots', snap[1]), field('raw_entries', rawEntries > 0 and rawEntries or nil),
  })

  local emitted = 0
  for entryIdx = 2, maxEntryIdx do
    local raw = snap[entryIdx]
    if raw ~= nil then
      if emitted >= TRACE_SNAP_SLOT_LIMIT then break end
      emitted = emitted + 1
      printWithFields('[JIT snap entry]', { field('tr', tr), field('idx', idx), field('entry_idx', entryIdx), field('raw', raw) })
    end
  end
  if rawEntries > emitted then
    printWithFields('[JIT snap entry]', { field('tr', tr), field('idx', idx), field('truncated', rawEntries - emitted), field('limit', TRACE_SNAP_SLOT_LIMIT) })
  end
end

local function printTraceDetails(tr)
  local ok, info = pcall(jit_util.traceinfo, tr)
  if ok and info then
    printWithFields('[JIT traceinfo]', {
      field('tr', tr), field('nins', info.nins), field('nk', info.nk),
      field('link', info.link), field('linktype', info.linktype),
      field('root', info.root), field('parent', info.parent), field('exit', info.exit),
    })

    local irLimit = math.min(TRACE_IR_LIMIT, info.nins or TRACE_IR_LIMIT)
    for i = 1, irLimit do
      local ir = pack(pcall(jit_util.traceir, tr, i))
      if not ir[1] or ir.n == 1 then break end
      printWithFields('[JIT ir]', traceIrFields(tr, i, ir[2], ir[3], ir[4], ir[5], ir[6]))
    end
    if info.nins and info.nins > irLimit then
      printWithFields('[JIT ir]', { field('tr', tr), field('truncated', info.nins - irLimit), field('limit', TRACE_IR_LIMIT) })
    end
  end

  for i = 0, TRACE_SNAP_LIMIT - 1 do
    local snap = pack(pcall(jit_util.tracesnap, tr, i))
    if not snap[1] or snap.n == 1 then
      if i == 0 then
        snap = pack(pcall(jit_util.tracesnap, tr, 1))
        if snap[1] and snap.n > 1 then
          if type(snap[2]) == 'table' then
            printSnapTable(tr, 1, snap[2])
          else
            printWithFields('[JIT snap]', { field('tr', tr), field('idx', 1), field('raw', tupleString(true, unpack(snap, 2, snap.n))) })
          end
        end
      end
      break
    end
    if type(snap[2]) == 'table' then
      printSnapTable(tr, i, snap[2])
    else
      printWithFields('[JIT snap]', { field('tr', tr), field('idx', i), field('raw', tupleString(true, unpack(snap, 2, snap.n))) })
    end
  end
end

local function recordTraceAbort(tr, func, pc, reason)
  local _, info = funcFields(func, pc)
  local key = table.concat({ tostring(tr or '?'), tostring(reason or '?'), tostring(func or '?'), tostring(info and (info.source or info.loc) or '?') }, '|')
  local row = traceAborts[key]
  if row then
    row.count = row.count + 1
  else
    if traceAbortsDistinct >= TRACE_AGGREGATE_LIMIT then
      traceAbortsDroppedOccurrences = traceAbortsDroppedOccurrences + 1
      return
    end
    traceAbortsDistinct = traceAbortsDistinct + 1
    traceAborts[key] = { count = 1, tr = tr, func = func and tostring(func), reason = reason, info = info }
  end
end

local function recordTraceOverflow(what, tr, func, pc, reason)
  local _, info = funcFields(func, pc)
  local source = info and (info.source or info.short_src or info.loc) or nil
  local key = table.concat({ tostring(what or '?'), tostring(reason or '?'), tostring(func or '?'), tostring(source or '?') }, '|')
  local row = traceEventOverflow[key]
  if row then
    row.count = row.count + 1
    row.last_tr = tr
  else
    if traceEventOverflowDistinct >= TRACE_AGGREGATE_LIMIT then
      traceEventOverflowDroppedOccurrences = traceEventOverflowDroppedOccurrences + 1
      return
    end
    traceEventOverflowDistinct = traceEventOverflowDistinct + 1
    traceEventOverflow[key] = { count = 1, event = what, tr = tr, last_tr = tr, func = func and tostring(func), reason = reason, info = info }
  end
end

local function printAggregateDropSummary(prefix, droppedOccurrences, limit)
  if droppedOccurrences > 0 then
    printWithFields(prefix, { field('dropped_occurrences', droppedOccurrences), field('limit', limit) })
  end
end

local function printTraceOverflowSummary()
  for _, row in pairs(traceEventOverflow) do
    local extra = {
      field('count', row.count), field('event', row.event), field('tr', row.tr), field('last_tr', row.last_tr),
      field('func', row.func), field('reason', row.reason),
    }
    if row.info then
      extra[#extra + 1] = field('source', row.info.source or row.info.short_src or row.info.loc)
      extra[#extra + 1] = field('linedefined', row.info.linedefined)
      extra[#extra + 1] = field('currentline', row.info.currentline)
      extra[#extra + 1] = field('line', row.info.currentline)
    end
    printWithFields('[JIT trace summary]', extra)
  end
  printAggregateDropSummary('[JIT trace summary]', traceEventOverflowDroppedOccurrences, TRACE_AGGREGATE_LIMIT)
  traceEventOverflow = {}
  traceEventOverflowDistinct = 0
  traceEventOverflowDroppedOccurrences = 0
end

local function traceCallback(what, tr, func, pc, otr, oex)
  local extra = { field('event', what), field('tr', tr) }
  local fields = funcFields(func, pc)
  for i = 1, #fields do extra[#extra + 1] = fields[i] end
  if what == 'abort' then
    local reason = traceError(otr, oex)
    extra[#extra + 1] = field('reason', reason)
    extra[#extra + 1] = field('abortcode', otr)
    recordTraceAbort(tr, func, pc, reason)
  elseif what == 'start' then
    extra[#extra + 1] = field('parent', otr)
    extra[#extra + 1] = field('exit', oex)
  elseif what ~= 'stop' then
    extra[#extra + 1] = field('arg1', otr)
    extra[#extra + 1] = field('arg2', oex)
  end
  if traceEventCount < TRACE_EVENT_LIMIT then
    traceEventCount = traceEventCount + 1
    printWithFields('[JIT trace]', extra)
  else
    if not traceEventTruncated then
      traceEventTruncated = true
      printWithFields('[JIT trace]', { field('truncated', true), field('limit', TRACE_EVENT_LIMIT) })
    end
    recordTraceOverflow(what, tr, func, pc, what == 'abort' and traceError(otr, oex) or nil)
  end
  if what == 'stop' and tr then
    if traceDetailCount < TRACE_DETAIL_LIMIT then
      traceDetailCount = traceDetailCount + 1
      printTraceDetails(tr)
    elseif not traceDetailTruncated then
      traceDetailTruncated = true
      printWithFields('[JIT traceinfo]', { field('truncated', true), field('limit', TRACE_DETAIL_LIMIT) })
    end
  end
end

local function attachTraceCollector()
  if traceAttached then return end
  jit.attach(traceCallback, 'trace')
  traceAttached = true
end

local function detachTraceCollector()
  if not traceAttached then return end
  jit.attach(traceCallback)
  traceAttached = false
end

local function printAbortSummary()
  for _, row in pairs(traceAborts) do
    local extra = { field('count', row.count), field('tr', row.tr), field('func', row.func), field('reason', row.reason) }
    if row.info then
      extra[#extra + 1] = field('source', row.info.source or row.info.short_src or row.info.loc)
      extra[#extra + 1] = field('linedefined', row.info.linedefined)
      extra[#extra + 1] = field('currentline', row.info.currentline)
      extra[#extra + 1] = field('line', row.info.currentline)
    end
    printWithFields('[JIT abort summary]', extra)
  end
  printAggregateDropSummary('[JIT abort summary]', traceAbortsDroppedOccurrences, TRACE_AGGREGATE_LIMIT)
  traceAborts = {}
  traceAbortsDistinct = 0
  traceAbortsDroppedOccurrences = 0
end

local function printSideExitSummary()
  for raw, row in pairs(sideExitLines) do
    printWithFields('[JIT sideexit summary]', { field('count', row.count), field('tr', row.tr), field('raw', raw) })
  end
  printAggregateDropSummary('[JIT sideexit summary]', sideExitDroppedOccurrences, TRACE_AGGREGATE_LIMIT)
  sideExitLines = {}
  sideExitDistinct = 0
  sideExitDroppedOccurrences = 0
end

local function printHotSummaries()
  for label, row in pairs(hotStats) do
    printWithFields('[JIT hot]', {
      field('label', label), field('count', row.count),
      field('ms', string.format('%.3f', row.ms * 1000)), field('frames', row.frames),
    })
  end
  hotStats = {}
end

local function printMeasurementNote(validFor, invalidFor, reason)
  printWithFields('[JIT measurement-note]', {
    field('event', 'measurement-note'), field('valid_for', validFor), field('invalid_for', invalidFor), field('reason', reason),
  })
end

local function beginRun(mode, opts)
  opts = opts or {}
  nextRunId = nextRunId + 1
  activeRunId = tostring(nextRunId)
  profilerMode = mode
  profilingFrame = 0
  traceAborts = {}
  traceAbortsDistinct = 0
  traceAbortsDroppedOccurrences = 0
  sideExitLines = {}
  sideExitDistinct = 0
  sideExitDroppedOccurrences = 0
  sideExitCount = 0
  sideExitTruncated = false
  hotStats = {}
  traceEventCount = 0
  traceEventTruncated = false
  traceEventOverflow = {}
  traceEventOverflowDistinct = 0
  traceEventOverflowDroppedOccurrences = 0
  traceDetailCount = 0
  traceDetailTruncated = false
  if opts.traceCollector then
    attachTraceCollector()
  else
    detachTraceCollector()
  end
  printWithFields('[JIT]', { field('event', 'run-start') })
end

local function endRun()
  if activeRunId == '-' then return end
  printHotSummaries()
  printTraceOverflowSummary()
  printAbortSummary()
  printSideExitSummary()
  printWithFields('[JIT]', { field('event', 'run-stop') })
  detachTraceCollector()
  activeRunId = '-'
  profilerMode = 'idle'
  currentPhase = '-'
end

local function recordSideExitLine(line)
  if not (line:find('---', 1, true) or line:find('abort') or line:find('flush') or line:find('blacklist')) then return end
  local tr = line:match('%[TRACE%s+(%d+)') or line:match('%[TRACE%s+(%-+%d*)')
  local row = sideExitLines[line]
  if row then
    row.count = row.count + 1
  else
    if sideExitDistinct >= TRACE_AGGREGATE_LIMIT then
      sideExitDroppedOccurrences = sideExitDroppedOccurrences + 1
    else
      sideExitDistinct = sideExitDistinct + 1
      sideExitLines[line] = { count = 1, tr = tr }
    end
  end
  if sideExitCount < TRACE_SIDEEXIT_LIMIT then
    sideExitCount = sideExitCount + 1
    printWithFields('[JIT sideexit]', { field('tr', tr), field('raw', line) })
  elseif not sideExitTruncated then
    sideExitTruncated = true
    printWithFields('[JIT sideexit]', { field('truncated', true), field('limit', TRACE_SIDEEXIT_LIMIT) })
  end
end

local function readAndPrintFile(path, prefix, filter, rawLineLimit)
  local f = io.open(path, 'r')
  if not f then return end
  local emitted = 0
  local omitted = 0
  for line in f:lines() do
    if not filter or line:find(filter, 1, true) then
      if prefix == '[JIT Trace]' then recordSideExitLine(line) end
      if not rawLineLimit or emitted < rawLineLimit then
        emitted = emitted + 1
        printWithFields(prefix, { field('raw', line) })
      else
        omitted = omitted + 1
      end
    end
  end
  f:close()
  if omitted > 0 then
    printWithFields(prefix, { field('omitted', omitted), field('limit', rawLineLimit) })
  end
end

-- ── call counter ─────────────────────────────────────────────────────────────

local callCounts = {}
local callCounterActive = false
local function countingHook()
  local info = debug.getinfo(2, 'nflS')
  local row = aggregateFuncRow(info)

  local caller = debug.getinfo(3, 'nflS')
  if caller then
    row.caller_source = caller.short_src or caller.source or '?'
    row.caller_linedefined = caller.linedefined
    row.caller_currentline = caller.currentline
    row.caller_line = caller.currentline or caller.linedefined
    row.caller_func = caller.func and tostring(caller.func) or nil
    row.caller_name = (caller.name and caller.name ~= '') and caller.name or tostring(caller.func)
    row.caller_namewhat = caller.namewhat
    row.caller_entry = ('%s:%s'):format(row.caller_source, row.caller_currentline or row.caller_linedefined or '?')
  else
    row.caller_entry = '?'
  end

  row.entry = ('%s  <- %s'):format(row.entry, row.caller_entry)
  local key = table.concat({ row.source or '?', tostring(row.linedefined or '?'), row.func or '?', row.name or '?', row.caller_source or '?', tostring(row.caller_currentline or row.caller_linedefined or '?') }, '|')
  local existing = callCounts[key]
  if existing then
    existing.count = existing.count + 1
  else
    row.count = 1
    callCounts[key] = row
  end
end

local function startCallCounter(mode, keepRun)
  if not keepRun then beginRun(mode or 'calls') end
  printMeasurementNote('call_counts', 'throughput', 'debug_hook')
  printWithFields('[JIT]', { field('event', 'call-counter-start') })
  callCounts = {}
  callCounterActive = true
  debug.sethook(countingHook, 'c')
end

local function stopCallCounter(filter, keepRun)
  if not callCounterActive then return end
  debug.sethook()
  callCounterActive = false
  printWithFields('[JIT]', { field('event', 'call-counter-results'), field('filter', filter) })
  local sorted = {}
  for _, row in pairs(callCounts) do
    if rowMatchesFilter(row, filter) then
      sorted[#sorted + 1] = row
    end
  end
  table.sort(sorted, function(a, b) return a.count > b.count end)

  local limit = math.min(TOP_N, #sorted)
  for i = 1, limit do
    local row = sorted[i]
    local fields = aggregateFields(row)
    fields[#fields + 1] = field('rank', i)
    fields[#fields + 1] = field('count', row.count)
    fields[#fields + 1] = field('caller_entry', row.caller_entry)
    fields[#fields + 1] = field('caller_source', row.caller_source)
    fields[#fields + 1] = field('caller_linedefined', row.caller_linedefined)
    fields[#fields + 1] = field('caller_currentline', row.caller_currentline)
    fields[#fields + 1] = field('caller_line', row.caller_line)
    fields[#fields + 1] = field('caller_func', row.caller_func)
    fields[#fields + 1] = field('caller_name', row.caller_name)
    fields[#fields + 1] = field('caller_namewhat', row.caller_namewhat)
    printWithFields('[JIT calls]', fields)
  end
  if #sorted > limit then
    printWithFields('[JIT calls]', { field('omitted', #sorted - limit), field('limit', limit) })
  end

  callCounts = {}
  if not keepRun then endRun() end
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

    local info = debug.getinfo(2, 'nflS')
    local row = aggregateFuncRow(info)
    local key = table.concat({ row.source or '?', tostring(row.linedefined or '?'), row.func or '?', row.name or '?' }, '|')
    local existing = timings[key]
    if existing then
      existing.elapsed = existing.elapsed + elapsed
    else
      row.elapsed = elapsed
      timings[key] = row
    end
  end
end

local function startTimingProfiler()
  beginRun('timing')
  printMeasurementNote('function_wall_time', 'throughput', 'debug_hook')
  printWithFields('[JIT]', { field('event', 'timing-start') })
  timings = {}
  timeStack = {}
  debug.sethook(timingHook, 'cr')
  timingActive = true
end

local function stopTimingProfiler(filter)
  if not timingActive then return end
  debug.sethook()
  timingActive = false

  printWithFields('[JIT]', { field('event', 'timing-results'), field('filter', filter) })

  local sorted = {}
  for _, row in pairs(timings) do
    if rowMatchesFilter(row, filter) then
      sorted[#sorted + 1] = row
    end
  end

  table.sort(sorted, function(a, b) return a.elapsed > b.elapsed end)

  local frames = profilingFrame > 0 and profilingFrame or 1
  local limit = math.min(TOP_N, #sorted)
  for i = 1, limit do
    local row = sorted[i]
    local total = row.elapsed * 1000
    local fields = aggregateFields(row)
    fields[#fields + 1] = field('rank', i)
    fields[#fields + 1] = field('total_ms', string.format('%.3f', total))
    fields[#fields + 1] = field('ms_per_frame', string.format('%.6f', total / frames))
    printWithFields('[JIT time]', fields)
  end
  if #sorted > limit then
    printWithFields('[JIT time]', { field('omitted', #sorted - limit), field('limit', limit) })
  end

  timings = {}
  timeStack = {}
  endRun()
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

    local info = debug.getinfo(2, 'nflS')
    local row = aggregateFuncRow(info)
    local key = table.concat({ row.source or '?', tostring(row.linedefined or '?'), row.func or '?', row.name or '?' }, '|')
    local existing = memAllocs[key]
    if existing then
      existing.kb = existing.kb + delta
    else
      row.kb = delta
      memAllocs[key] = row
    end
  end
end

local function startMemProfiler()
  beginRun('memory')
  printMeasurementNote('allocation_attribution', 'throughput', 'debug_hook')
  printWithFields('[JIT]', { field('event', 'memory-start') })
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

  printWithFields('[JIT]', { field('event', 'memory-results'), field('filter', filter) })

  local sorted = {}
  for _, row in pairs(memAllocs) do
    if rowMatchesFilter(row, filter) then
      sorted[#sorted + 1] = row
    end
  end

  table.sort(sorted, function(a, b) return a.kb > b.kb end)

  local limit = math.min(TOP_N, #sorted)
  for i = 1, limit do
    local row = sorted[i]
    local fields = aggregateFields(row)
    fields[#fields + 1] = field('rank', i)
    fields[#fields + 1] = field('kb', string.format('%.3f', row.kb))
    printWithFields('[JIT mem]', fields)
  end
  if #sorted > limit then
    printWithFields('[JIT mem]', { field('omitted', #sorted - limit), field('limit', limit) })
  end

  memAllocs = {}
  memStack  = {}
  endRun()
end

local function clearDebugHookBeforeJitCapture()
  local ok, hookFn, mask, count = pcall(debug.gethook)
  local hookExists = ok and hookFn ~= nil
  printWithFields('[JIT]', {
    field('event', 'debug-hook-before-jit-capture'),
    field('ok', ok),
    field('hook', ok and hookExists),
    field('mask', ok and mask or nil),
    field('count', ok and count or nil),
    field('error', not ok and hookFn or nil),
  })
  local clearOk, clearErr = pcall(debug.sethook)
  local resetCallCounter = callCounterActive
  local resetTiming = timingActive
  local resetMem = memActive
  printWithFields('[JIT]', {
    field('event', 'debug-hook-clear-before-jit-capture'),
    field('ok', clearOk),
    field('stale_call_counter', resetCallCounter),
    field('stale_timing', resetTiming),
    field('stale_memory', resetMem),
    field('error', clearErr),
  })

  local postOk, postHookFn, postMask, postCount = pcall(debug.gethook)
  local postHookExists = postOk and postHookFn ~= nil
  printWithFields('[JIT]', {
    field('event', 'debug-hook-after-jit-capture-clear'),
    field('ok', postOk),
    field('hook', postOk and postHookExists),
    field('mask', postOk and postMask or nil),
    field('count', postOk and postCount or nil),
    field('error', not postOk and postHookFn or nil),
  })
  if clearOk and postOk and not postHookExists then
    callCounterActive = false
    timingActive = false
    if memActive then collectgarbage('restart') end
    memActive = false
    timeStack = {}
    memStack = {}
  end
  if not ok then return false, 'debug_gethook_before_failed: ' .. tostring(hookFn) end
  if not clearOk then return false, 'debug_sethook_failed: ' .. tostring(clearErr) end
  if not postOk then return false, 'debug_gethook_after_failed: ' .. tostring(postHookFn) end
  if postHookExists then return false, 'debug_hook_still_active: ' .. tostring(postHookFn) end
  return true
end

-- ── file cleanup ──────────────────────────────────────────────────────────────

local function closeTmpFile()
  if tmpFile then
    tmpFile:close()
    tmpFile = nil
  end
end

local function resetTmpFile(path)
  closeTmpFile()
  tmpFile = io.open(path, 'w+')
  return tmpFile
end

local function stopRuntimeDumpers()
  pcall(jit_v.off)
  pcall(jit_dump.off)
end

local function flushJitTraces(reason)
  local ok, err = pcall(jit.flush)
  printWithFields('[JIT]', { field('event', 'jit-flush'), field('ok', ok), field('reason', reason), field('error', err) })
end

local function recordHot(label, elapsed, count)
  label = tostring(label or scenarioLabel or 'hot')
  local row = hotStats[label]
  if not row then
    row = { count = 0, ms = 0, frames = 0, lastFrame = -1 }
    hotStats[label] = row
  end
  row.count = row.count + (count or 1)
  row.ms = row.ms + (elapsed or 0)
  if row.lastFrame ~= profilingFrame then
    row.frames = row.frames + 1
    row.lastFrame = profilingFrame
  end
end

local function beginHot(_)
  return os_clock()
end

local function endHot(label, startClock, count)
  local elapsed = startClock and (os_clock() - startClock) or 0
  recordHot(label, elapsed, count)
  return elapsed
end

local function hot(label, fn, ...)
  local started = beginHot(label)
  local results = pack(xpcall(fn, debug.traceback, ...))
  endHot(label, started, 1)
  if not results[1] then error(results[2], 0) end
  return unpack(results, 2, results.n)
end

local tickProfiler
local tickThroughputWindow
local activeFrameLimit = DEFAULT_CAPTURE_FRAMES

local function startJitCaptureProfiler(frames)
  if tick ~= nullfunction then
    ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
    return
  end
  activeFrameLimit = tonumber(frames) or DEFAULT_CAPTURE_FRAMES
  stopRuntimeDumpers()
  beginRun('jit-capture', { traceCollector = true })
  printMeasurementNote('trace_ir', 'throughput', 'jit_dump_overhead')
  local hookClearOk, hookClearReason = clearDebugHookBeforeJitCapture()
  if not hookClearOk then
    printWithFields('[JIT]', {
      field('event', 'jit-capture-abort'),
      field('reason', 'debug_hook_active_or_uncertain'),
      field('detail', hookClearReason),
    })
    stopRuntimeDumpers()
    closeTmpFile()
    tick = nullfunction
    endRun()
    return
  end
  flushJitTraces('jit-capture-start')
  resetTmpFile(tracePath)
  closeTmpFile()
  resetTmpFile(dumpPath)
  closeTmpFile()
  printWithFields('[JIT]', { field('event', 'jit-v-start'), field('path', tracePath) })
  jit_v.on(tracePath)
  printWithFields('[JIT]', { field('event', 'jit-dump-start'), field('path', dumpPath), field('dump_mode', JIT_DUMP_MODE) })
  jit_dump.on(JIT_DUMP_MODE, dumpPath)
  tick = tickProfiler
end

local function startThroughputWindow(frames, label)
  if tick ~= nullfunction then
    ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
    return
  end
  activeFrameLimit = tonumber(frames) or DEFAULT_PROFILE_FRAMES
  if label then scenarioLabel = tostring(label) end
  stopRuntimeDumpers()
  beginRun('throughput-window')
  printMeasurementNote('stress_ops_sec', 'call_counts', 'no_debug_hook')
  tick = tickThroughputWindow
end

local function finishJitCapture()
  stopRuntimeDumpers()
  readAndPrintFile(tracePath, '[JIT Trace]', nil, TRACE_RAW_LINE_LIMIT)
  readAndPrintFile(dumpPath, '[JIT Dump]', nil, TRACE_RAW_LINE_LIMIT)
  closeTmpFile()
  tick = nullfunction
  endRun()
end

local function stopActiveProfiler()
  if profilerMode == 'jit-capture' then
    finishJitCapture()
    return
  end
  stopRuntimeDumpers()
  stopCallCounter(nil, true)
  stopTimingProfiler()
  stopMemProfiler()
  closeTmpFile()
  tick = nullfunction
  endRun()
end

-- ── keybinds ──────────────────────────────────────────────────────────────────
--   Shift+F3: timing hook sample only; debug hook poisons throughput (300 frames)
--   F3:       call counts only; debug hook poisons throughput (300 frames)
--   F4:       JIT capture only; jit.v/jit.dump overhead poisons throughput
--   Ctrl+Shift+Z: allocation attribution only; debug hook poisons throughput (300 frames)
--   Shift+F4: stop whatever is running early

-- ── JIT capture (F4) ──────────────────────────────────────────────────────────
-- Capture starts before the first profiled frame, after a best-effort trace flush.
-- No debug hook or call counter runs during this window.

function tickProfiler()
  profilingFrame = profilingFrame + 1

  if profilingFrame >= activeFrameLimit then
    finishJitCapture()
  end
end

function tickThroughputWindow()
  profilingFrame = profilingFrame + 1

  if profilingFrame >= activeFrameLimit then
    tick = nullfunction
    endRun()
  end
end

return {
  interfaceName = 'pr0f1l3r',
  interface = {
    benchAll = function()
      startJitCaptureProfiler()
    end,
    benchJit = function(frames)
      startJitCaptureProfiler(frames)
    end,
    benchTrace = function(frames)
      startJitCaptureProfiler(frames)
    end,
    benchWindow = function(frames, label)
      startThroughputWindow(frames, label)
    end,
    benchThroughput = function(frames, label)
      startThroughputWindow(frames, label)
    end,
    bench = function(path)
      if tick ~= nullfunction then
        ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
        return
      end
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

      startMemProfiler()
      tick = function()
        profilingFrame = profilingFrame + 1
        if profilingFrame == 300 then
          stopMemProfiler(path)
          tick = nullfunction
        end
      end
    end,
    setScenario = function(label)
      scenarioLabel = label and tostring(label) or nil
      printWithFields('[JIT]', { field('event', 'scenario-set') })
    end,
    clearScenario = function()
      scenarioLabel = nil
      printWithFields('[JIT]', { field('event', 'scenario-clear') })
    end,
    countHot = function(label, count)
      recordHot(label, 0, count or 1)
    end,
    beginHot = beginHot,
    endHot = endHot,
    hot = hot,
  },
  engineHandlers = {
    onKeyPress = function(key)
      if key.code == input.KEY.F3 and key.withShift then
        if tick ~= nullfunction then
          ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
          return
        end

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
          stopActiveProfiler()
        elseif tick ~= nullfunction then
          ui.showMessage '[JIT] already profiling — press Shift+F4 to stop'
        else
          startJitCaptureProfiler()
        end
      end
    end,
    onUpdate = function(_)
      currentPhase = 'onUpdate'
      tick()
      currentPhase = '-'
    end,
  }
}
