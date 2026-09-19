---@omw-context none

local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/h3ui_chrome_library%.lua$' or '.'

package.path = root .. '/content/h3lp_yours3lf/?.lua;' .. package.path

package.preload['openmw.util'] = function()
  return {
    vector2 = function(x, y) return { x = x, y = y } end,
  }
end

local chromeAssets = require 'scripts.h3.ui.themes.chromeAssets'

local Error, IOOpen, TableConcat, ToString = error, io.open, table.concat, tostring

local function regionKey(region)
  return TableConcat({
    region.offset.x,
    region.offset.y,
    region.size.x,
    region.size.y,
    ToString(region.thickness),
    ToString(region.sourceBorder),
    ToString(region.center),
  }, ':')
end

local function assertSameGeometry(name, candidate, reference)
  if regionKey(candidate) ~= regionKey(reference) then Error('geometry drift in ' .. name) end
end

local order = chromeAssets.variantOrder
assert(#order > 0, 'material registry is empty')

local seenFamilies = {}
for index = 1, #order do
  local family = chromeAssets.variantFamily[order[index]]
  if not family then Error('material without family: ' .. order[index]) end
  seenFamilies[family] = true
end
local familyCount = 0
for _ in next, seenFamilies do
  familyCount = familyCount + 1
end
assert(familyCount > 0, 'no material families registered')

local reference = chromeAssets.h3ui.frame
for index = 1, #order do
  local stem = order[index]
  local entry = chromeAssets.material(stem)
  if not entry then Error('registry entry missing: ' .. stem) end
  assertSameGeometry(stem .. '.thin', entry.frame.thin, reference.thin)
  assertSameGeometry(stem .. '.thick', entry.frame.thick, reference.thick)
  assertSameGeometry(stem .. '.button', entry.frame.button, reference.button)
  assertSameGeometry(stem .. '.caption', entry.caption, chromeAssets.h3ui.frame.caption)
  assertSameGeometry(stem .. '.pinUp', entry.pin.up, chromeAssets.h3ui.frame.pinUp)
  assertSameGeometry(stem .. '.pinDown', entry.pin.down, chromeAssets.h3ui.frame.pinDown)
  assertSameGeometry(stem .. '.scrollUp', entry.scroll.up, chromeAssets.h3ui.scroll.up)
  assertSameGeometry(stem .. '.scrollDown', entry.scroll.down, chromeAssets.h3ui.scroll.down)
  assertSameGeometry(stem .. '.scrollLeft', entry.scroll.left, chromeAssets.h3ui.scroll.left)
  assertSameGeometry(stem .. '.scrollRight', entry.scroll.right, chromeAssets.h3ui.scroll.right)

  local path = root .. '/content/h3lp_yours3lf/textures/h3ui/chrome/' .. stem .. '.dds'
  local file = IOOpen(path, 'rb')
  if not file then Error('missing atlas file: ' .. path) end
  file:close()
end

local cachedA = chromeAssets.material(order[1])
local cachedB = chromeAssets.material(order[1])
assert(cachedA ~= nil and cachedA == cachedB, 'material spec is not cached')
assert(chromeAssets.material 'nope' == nil, 'unknown material resolves')

local function assertSourceBorder(name, region)
  if region.sourceBorder ~= region.thickness then Error('sourceBorder ~= thickness in ' .. name) end
end

local themes = { chromeAssets.h3ui, chromeAssets.morrowind, chromeAssets.starwind }
for index = 1, #themes do
  local theme = themes[index]
  for key, region in next, theme.frame do
    assertSourceBorder(key, region)
  end
end
for index = 1, #order do
  local stem = order[index]
  for key, region in next, chromeAssets.material(stem).frame do
    assertSourceBorder(stem .. '.' .. key, region)
  end
end

local l10nPath = root .. '/content/h3lp_yours3lf/l10n/H3/en.yaml'
local l10nFile = IOOpen(l10nPath, 'rb')
if not l10nFile then Error('missing l10n file: ' .. l10nPath) end
local l10n = l10nFile:read '*a'
l10nFile:close()
for index = 1, #order do
  local stem = order[index]
  if not l10n:find('H3UIChromeMaterial_' .. stem .. ':', 1, true) then
    Error('missing label: ' .. stem)
  end
end

print 'H3UI chrome library tests passed'
