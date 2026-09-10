---@omw-context player
local ConditionRegistry = require 'scripts.s3.music.playlistConditions.registry'
local PlaylistConditions = {
  registry = ConditionRegistry,
  VERSION = 1,
  MAX_DEPTH = 64,
  MAX_NODES = 2048,
}
local metatable = {}
local operators = { eq = '==', ne = '~=', lt = '<', le = '<=', gt = '>', ge = '>=' }

local function fail(path, message) error('Playlist condition ' .. path .. ': ' .. message, 0) end

local function fields(value, allowed, path)
  if type(value) ~= 'table' then fail(path, 'expected table') end
  for k in pairs(value) do
    if not allowed[k] then fail(path, 'unexpected field ' .. tostring(k)) end
  end
end

local function array(value, path)
  if type(value) ~= 'table' then fail(path, 'expected array') end
  local count = 0
  for k in pairs(value) do
    if type(k) ~= 'number' or k < 1 or k % 1 ~= 0 then fail(path, 'invalid array key') end
    count = count + 1
  end
  if count > PlaylistConditions.MAX_NODES then fail(path, 'array too large') end
  for i = 1, count do
    if value[i] == nil then fail(path, 'sparse array') end
  end
  return count
end

local function literal(value, kind, path)
  if type(value) ~= kind then fail(path, 'expected ' .. kind) end
  if kind == 'number' and (value ~= value or math.abs(value) == math.huge) then
    fail(path, 'expected finite number')
  end
  if kind == 'string' and #value > 16384 then fail(path, 'string too long') end
  return value
end

local function list(value, path, lower)
  local result = {}
  for i = 1, array(value, path) do
    local s = literal(value[i], 'string', path .. '[' .. i .. ']')
    result[i] = lower and string.lower(s) or s
  end
  return result
end

local function argument(value, kind, path)
  if kind == 'hour' then
    literal(value, 'number', path)
    if value < 0 or value > 24 or value % 1 ~= 0 then
      fail(path, 'hour must be an integer from 0 to 24')
    end
    return value
  elseif kind == 'patterns' then
    fields(value, { allowed = true, disallowed = true }, path)
    return {
      allowed = list(value.allowed, path .. '.allowed', true),
      disallowed = list(value.disallowed, path .. '.disallowed', true),
    }
  end
  if kind == 'nameSet' or kind == 'stringList' or kind == 'lowerList' then
    return list(value, path, kind == 'nameSet' or kind == 'lowerList')
  end
  fail(path, 'unknown argument kind ' .. tostring(kind))
end

function PlaylistConditions.validate(input)
  local visiting, nodes = {}, 0
  local function visit(node, depth, path)
    nodes = nodes + 1
    if nodes > PlaylistConditions.MAX_NODES or depth > PlaylistConditions.MAX_DEPTH then
      fail(path, 'tree limit exceeded')
    end
    if type(node) ~= 'table' then fail(path, 'expected node') end
    if visiting[node] then fail(path, 'cycle') end
    visiting[node] = true
    local out = { kind = node.kind }
    if node.kind == 'and' or node.kind == 'or' then
      fields(node, { kind = true, children = true }, path)
      out.children = {}
      for i = 1, array(node.children, path .. '.children') do
        out.children[i] = visit(node.children[i], depth + 1, path .. '.children[' .. i .. ']')
      end
    elseif node.kind == 'not' then
      fields(node, { kind = true, child = true }, path)
      out.child = visit(node.child, depth + 1, path .. '.child')
    elseif node.kind == 'rule' then
      fields(node, { kind = true, id = true, args = true }, path)
      local spec = ConditionRegistry.rules[node.id]
      if not spec then fail(path, 'unknown rule ' .. tostring(node.id)) end
      if array(node.args, path .. '.args') ~= #spec.arguments then
        fail(path, 'wrong argument count')
      end
      out.id, out.args = node.id, {}
      for i = 1, #spec.arguments do
        local kind = spec.arguments[i]
        out.args[i] = argument(node.args[i], kind, path .. '.args[' .. i .. ']')
      end
    elseif node.kind == 'state' then
      fields(node, { kind = true, id = true, op = true, value = true }, path)
      local spec = ConditionRegistry.states[node.id]
      if not spec then fail(path, 'unknown state ' .. tostring(node.id)) end
      if
        not operators[node.op]
        or (spec.valueType ~= 'number' and node.op ~= 'eq' and node.op ~= 'ne')
      then
        fail(path, 'unsupported comparison')
      end
      out.id, out.op = node.id, node.op
      out.value = literal(node.value, spec.valueType, path .. '.value')
    else
      fail(path, 'unknown kind ' .. tostring(node.kind))
    end
    visiting[node] = nil
    return setmetatable(out, metatable)
  end
  return visit(input, 1, 'root')
end

local function equal(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= 'table' then return a == b end
  for k, v in pairs(a) do
    if not equal(v, b[k]) then return false end
  end
  for k in pairs(b) do
    if a[k] == nil then return false end
  end
  return true
end

metatable.__eq = equal
PlaylistConditions.equals = equal
PlaylistConditions.clone = PlaylistConditions.validate
function PlaylistConditions.all(children)
  return PlaylistConditions.validate { kind = 'and', children = children }
end

function PlaylistConditions.any(children)
  return PlaylistConditions.validate { kind = 'or', children = children }
end

function PlaylistConditions.not_(child)
  return PlaylistConditions.validate { kind = 'not', child = child }
end

function PlaylistConditions.rule(id, ...)
  return PlaylistConditions.validate { kind = 'rule', id = id, args = { ... } }
end

function PlaylistConditions.state(id, op, value)
  return PlaylistConditions.validate { kind = 'state', id = id, op = op, value = value }
end

local function plain(value)
  if type(value) ~= 'table' then return value end
  local out = {}
  for k, v in pairs(value) do
    out[k] = plain(v)
  end
  return out
end

function PlaylistConditions.serialize(ast)
  return { version = PlaylistConditions.VERSION, root = plain(PlaylistConditions.validate(ast)) }
end

local function migrateDocument(data)
  if data.version == PlaylistConditions.VERSION then return data end
  fail('document', 'unsupported version ' .. tostring(data.version))
end

function PlaylistConditions.deserialize(data)
  fields(data, { version = true, root = true }, 'document')
  data = migrateDocument(data)
  return PlaylistConditions.validate(data.root)
end

local function quote(s)
  return '"'
    .. s:gsub('[%z\1-\31\\"]', function(c)
      if c == '\\' then
        return '\\\\'
      elseif c == '"' then
        return '\\"'
      end
      return string.format('\\%03d', string.byte(c))
    end)
    .. '"'
end

local function lua(value)
  if type(value) == 'string' then return quote(value) end
  if type(value) ~= 'table' then return tostring(value) end
  local keys, parts = {}, {}
  for k in pairs(value) do
    keys[#keys + 1] = k
  end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b end
    return type(a) < type(b)
  end)
  for i = 1, #keys do
    local k = keys[i]
    parts[#parts + 1] = '[' .. lua(k) .. '] = ' .. lua(value[k])
  end
  return '{ ' .. table.concat(parts, ', ') .. ' }'
end

PlaylistConditions.literal = lua

local function generate(ast)
  local constants = {}
  local function expression(node)
    if node.kind == 'and' or node.kind == 'or' then
      if #node.children == 0 then return node.kind == 'and' and 'true' or 'false' end
      local parts = {}
      for i = 1, #node.children do
        parts[i] = expression(node.children[i])
      end
      return '(' .. table.concat(parts, node.kind == 'and' and ' and ' or ' or ') .. ')'
    elseif node.kind == 'not' then
      return '(not ' .. expression(node.child) .. ')'
    elseif node.kind == 'state' then
      local field = 'Playback.state.' .. node.id
      if node.op == 'eq' or node.op == 'ne' then
        return '(' .. field .. ' ' .. operators[node.op] .. ' ' .. lua(node.value) .. ')'
      end
      return '('
        .. field
        .. ' ~= nil and '
        .. field
        .. ' '
        .. operators[node.op]
        .. ' '
        .. lua(node.value)
        .. ')'
    end
    local args, spec = {}, ConditionRegistry.rules[node.id]
    for i = 1, #node.args do
      local arg = node.args[i]
      if spec.arguments[i] == 'nameSet' then
        local set = {}
        for j = 1, #arg do
          set[arg[j]] = true
        end
        arg = set
      end
      constants[#constants + 1] = 'local conditionArg' .. (#constants + 1) .. ' = ' .. lua(arg)
      args[i] = 'conditionArg' .. #constants
    end
    return '(not not Playback.rules.' .. node.id .. '(' .. table.concat(args, ', ') .. '))'
  end
  local result = expression(ast)
  return table.concat(constants, '\n'), 'function()\n  return ' .. result .. '\nend'
end

function PlaylistConditions.emit(ast) return generate(PlaylistConditions.validate(ast)) end

function PlaylistConditions.compile(ast, playback, loadCode)
  local declarations, callback = PlaylistConditions.emit(ast)
  loadCode = loadCode or require('openmw.util').loadCode
  local chunk = loadCode(declarations .. '\nreturn ' .. callback, { Playback = playback })
  return chunk()
end
return PlaylistConditions
