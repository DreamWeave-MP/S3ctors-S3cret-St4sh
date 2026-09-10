local source = debug.getinfo(1, 'S').source
local root = source:match '^@(.+)/tests/s3maphore_playlist_editor_conditions%.lua$' or '.'

package.path = root
  .. '/content/s3maphore/00 Core/?.lua;'
  .. root
  .. '/content/s3maphore/00 Core/?/init.lua;'
  .. package.path

local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local makeConditionsEditor = require 'scripts.s3.music.playlistEditor.conditions'

local state = {
  working = {},
  conditionPage = 0,
  pickerPage = 0,
  conditionPickerPath = nil,
  conditionPickerMode = nil,
}

local function text(value) return { kind = 'text', value = value } end

local function button(label, callback)
  return { kind = 'button', label = label, callback = callback }
end

local function input(value, callback) return { kind = 'input', value = value, callback = callback } end

local function row(content) return { kind = 'row', content = content } end

local function paged(itemCount, _, buildPage, setPage)
  setPage(0)
  return buildPage(1, itemCount)
end

local function findButton(value, label)
  if type(value) ~= 'table' then return end
  if value.kind == 'button' and value.label == label then return value end
  for key, child in pairs(value) do
    if key ~= 'callback' then
      local result = findButton(child, label)
      if result then return result end
    end
  end
end

local editor = makeConditionsEditor {
  state = state,
  Catalog = { source = function() return nil end },
  button = button,
  input = input,
  paged = paged,
  rebuild = function() end,
  row = row,
  text = text,
}

local function setCondition(condition)
  state.working.condition = PlaylistConditions.serialize(condition)
  state.conditionPickerPath, state.conditionPickerMode = nil, nil
end

setCondition(PlaylistConditions.all {
  PlaylistConditions.state('isInCombat', 'eq', true),
})
local notButton = findButton(editor.layout(), 'NOT')
assert(notButton, 'leaf did not expose arbitrary NOT wrapping')
notButton.callback()
local wrappedCondition = PlaylistConditions.deserialize(state.working.condition)
assert(wrappedCondition.children[1].kind == 'not')
assert(wrappedCondition.children[1].child.id == 'isInCombat')

setCondition(PlaylistConditions.all {
  PlaylistConditions.state('isInCombat', 'eq', true),
})
local replaceButton = findButton(editor.layout(), 'Replace')
assert(replaceButton, 'leaf did not expose replacement')
replaceButton.callback()
assert(state.conditionPickerMode == 'replace')
local pickerButton = findButton(editor.layout(), 'Cell: Cell name is exactly')
assert(pickerButton, 'replacement picker was not rendered')
pickerButton.callback()
local replacedCondition = PlaylistConditions.deserialize(state.working.condition)
assert(replacedCondition.children[1].kind == 'rule')
assert(replacedCondition.children[1].id == 'cellNameExact')
assert(state.conditionPickerPath == nil and state.conditionPickerMode == nil)

setCondition(PlaylistConditions.all {
  PlaylistConditions.all {},
})
local removeGroupButton = findButton(editor.layout(), 'Remove Group')
assert(removeGroupButton, 'nested group did not expose removal')
removeGroupButton.callback()
local removedGroupCondition = PlaylistConditions.deserialize(state.working.condition)
assert(#removedGroupCondition.children == 0, 'nested group was not removed')

print 'S3maphore playlist editor condition tests passed'
