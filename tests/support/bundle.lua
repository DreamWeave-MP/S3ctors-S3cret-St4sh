---@omw-context none

-- Stock Luau has no package, package.preload or debug.getinfo. Each bundle supplies them, wraps
-- every shipped module in a function that runs on its first require, as the engine loads it, and
-- reports failures against the original file and line.
--
-- Usage, from LuaJIT: luajit tests/support/bundle.lua <output directory> <suite>...

local Error, IOOpen, IOPopen, StrFormat, TableConcat =
  error, io.open, io.popen, string.format, table.concat

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/support/bundle%.lua$' or '.'

local PackageRoot = 'content/h3lp_yours3lf'
local ScriptsRoot = StrFormat('%s/scripts', PackageRoot)

local Prelude = [[
local package = { loaded = {}, path = '', preload = {} }
local modules = {}

local debug = setmetatable({
  getinfo = function() return { source = %q } end,
}, { __index = debug })

local function require(name)
  local loaded = package.loaded[name]
  if loaded ~= nil then return loaded end

  local loader = package.preload[name] or modules[name]
  if not loader then error(string.format("module '%%s' not found", name), 2) end

  local result = loader(name)
  if result ~= nil then
    package.loaded[name] = result
  elseif package.loaded[name] == nil then
    package.loaded[name] = true
  end

  return package.loaded[name]
end
]]

local Epilogue = [[
local SourceLines = { %s }

local function originalLocation(line)
  line = tonumber(line)
  for index = 1, #SourceLines, 3 do
    local first, last = SourceLines[index], SourceLines[index + 1]
    if line >= first and line <= last then
      return string.format('%%s:%%d:', SourceLines[index + 2], line - first + 1)
    end
  end
end

local ok, failure = xpcall(suite, function(message)
  if type(message) ~= 'string' then return message end
  return (message:gsub('[^%%s:]*%s:(%%d+):', originalLocation))
end)

if not ok then error(failure, 0) end
]]

local function shellQuote(value) return StrFormat('\'%s\'', (value:gsub('\'', '\'\\\'\''))) end

local function readFile(path)
  local file = IOOpen(path, 'rb') or Error(StrFormat('cannot read %s', path))
  local contents = file:read '*a'
  file:close()

  if contents:sub(-1) ~= '\n' then contents = StrFormat('%s\n', contents) end
  return contents
end

local function commandOutput(command)
  local pipe = IOPopen(command) or Error(StrFormat('cannot run %s', command))
  local output = pipe:read '*a'
  pipe:close()
  return output
end

local function physicalDirectory(path)
  local resolved =
    commandOutput(StrFormat('cd %s 2>/dev/null && pwd -P', shellQuote(path))):match '^(.-)\n$'
  return resolved or Error(StrFormat('output directory does not exist: %s', path))
end

local function moduleFiles()
  local listing = commandOutput(
    StrFormat(
      'cd %s && find %s -type f -name \'*.lua\' | LC_ALL=C sort',
      shellQuote(root),
      ScriptsRoot
    )
  )
  local files = {}

  for path in listing:gmatch '[^\n]+' do
    local name = path:sub(#PackageRoot + 2, -5):gsub('/', '.')
    files[#files + 1] = { name = name, path = path }
  end

  return files
end

local function lineCount(text)
  local _, count = text:gsub('\n', '')
  return count
end

local function bundle(suitePath, files)
  local suiteName = suitePath:match '[^/]+$'
  local prelude = StrFormat(Prelude, StrFormat('@%s', suitePath))
  local chunks = { prelude }
  local sourceLines = {}
  local line = lineCount(prelude)

  local function append(header, path, displayPath)
    local contents = readFile(path)
    local lines = lineCount(contents)

    chunks[#chunks + 1] = StrFormat('%s\n', header)
    chunks[#chunks + 1] = contents
    chunks[#chunks + 1] = 'end\n'

    sourceLines[#sourceLines + 1] = StrFormat('%d, %d, %q', line + 2, line + 1 + lines, displayPath)
    line = line + lines + 2
  end

  for index = 1, #files do
    local file = files[index]
    append(
      StrFormat('modules[%q] = function(...)', file.name),
      StrFormat('%s/%s', root, file.path),
      StrFormat('./%s', file.path)
    )
  end
  append('local function suite(...)', suitePath, suitePath)

  local namePattern = suiteName:gsub('%p', '%%%0')
  chunks[#chunks + 1] = StrFormat(Epilogue, TableConcat(sourceLines, ', '), namePattern)

  return suiteName, TableConcat(chunks)
end

local outputDirectory = arg[1]
  or Error 'usage: luajit tests/support/bundle.lua <output directory> <suite>...'
local physicalOutput = physicalDirectory(outputDirectory)
local physicalRoot = physicalDirectory(root)

if
  physicalOutput == physicalRoot
  or physicalOutput:sub(1, #physicalRoot + 1) == StrFormat('%s/', physicalRoot)
then
  Error(StrFormat('bundles must be written outside the repository: %s', physicalOutput))
end

local files = moduleFiles()

for index = 2, #arg do
  local suiteName, contents = bundle(arg[index], files)
  local outputPath = StrFormat('%s/%s', physicalOutput, suiteName)
  local output = IOOpen(outputPath, 'wb') or Error(StrFormat('cannot write %s', outputPath))
  output:write(contents)
  output:close()
end
