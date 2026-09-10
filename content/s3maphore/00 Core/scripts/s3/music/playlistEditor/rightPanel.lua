---@module 'doc.s3maphoreTypes'
---@omw-context player
local Interfaces = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local Catalog = require 'scripts.s3.music.playlistCatalog'
local Conditions = require 'scripts.s3.music.playlistEditor.conditions'
local Constants = require 'scripts.omw.mwui.constants'
local Export = require 'scripts.s3.music.playlistEditor.export'
local PlaylistConditions = require 'scripts.s3.music.playlistConditions'
local PlaylistExport = require 'scripts.s3.music.playlistExport'
local Properties = require 'scripts.s3.music.playlistEditor.properties'
local Tracks = require 'scripts.s3.music.playlistEditor.tracks'

local vector2 = util.vector2
local RightPanel = {}
local PAGE_SIZE = 12
local ROW_HEIGHT = 24
local NEW_PLAYLIST_PRIORITIES = { Explore = 1000, Battle = 190, Special = 50 }

---@type S3maphorePlaylistEditorState
local state = {
  selectedId = nil,
  tab = 'Conditions',
  working = nil,
  exportText = nil,
  newMode = false,
  newCategory = 'Explore',
  newId = nil,
  trackInput = nil,
  conditionPickerPath = nil,
  conditionPickerMode = nil,
  conditionPage = 0,
  trackPage = 0,
  pickerPage = 0,
  trackPicker = false,
  trackSearch = '',
  saved = nil,
  readOnlyMessage = nil,
  pending = nil,
}
local element
local selectionHandler

local function text(value, textSize)
  return {
    type = ui.TYPE.Text,
    template = Interfaces.MWUI.templates.textNormal,
    props = {
      text = value,
      textSize = textSize or 14,
      textColor = Constants.normalColor,
    },
  }
end

local function button(label, callback)
  return {
    type = ui.TYPE.Text,
    template = Interfaces.MWUI.templates.textNormal,
    props = { text = label, textColor = Constants.normalColor },
    events = { mouseClick = async:callback(callback) },
  }
end

local function row(content)
  return {
    type = ui.TYPE.Flex,
    props = {
      horizontal = true,
      relativeSize = vector2(1, 0),
      size = vector2(0, ROW_HEIGHT),
      autoSize = false,
    },
    content = ui.content(content),
  }
end

local function input(value, callback)
  return {
    type = ui.TYPE.TextEdit,
    template = Interfaces.MWUI.templates.textEditLine,
    props = {
      text = value,
      relativeSize = vector2(1, 0),
      autoSize = true,
    },
    events = { textChanged = async:callback(callback) },
  }
end

local function exportInput(value, callback)
  return {
    type = ui.TYPE.TextEdit,
    template = Interfaces.MWUI.templates.textEditBox,
    props = {
      text = value,
      relativeSize = vector2(1, 1),
      autoSize = false,
      multiline = true,
    },
    events = { textChanged = async:callback(callback) },
  }
end

local function resetPages()
  state.conditionPage, state.trackPage, state.pickerPage = 0, 0, 0
  state.trackPicker, state.trackSearch = false, ''
end

local function dirty()
  local workingDirty = state.working ~= nil
    and (state.saved == nil or not Catalog.equals(state.working, state.saved))
  local newIdDirty = state.newMode and state.newId ~= nil and state.newId ~= ''
  return workingDirty or newIdDirty
end

local function pageControls(page, pageCount, setPage)
  if pageCount <= 1 then return {} end

  return {
    row {
      button('< Prev', function()
        if page > 0 then
          setPage(page - 1)
          RightPanel.rebuild()
        end
      end),
      text(string.format('  %d / %d  ', page + 1, pageCount)),
      button('Next >', function()
        if page + 1 < pageCount then
          setPage(page + 1)
          RightPanel.rebuild()
        end
      end),
    },
  }
end

local function paged(itemCount, page, buildPage, setPage)
  local pageCount = math.max(math.ceil(itemCount / PAGE_SIZE), 1)
  page = math.min(page, pageCount - 1)
  setPage(page)

  local first = page * PAGE_SIZE + 1
  local last = math.min(first + PAGE_SIZE - 1, itemCount)
  local output = buildPage(first, last)

  local controls = pageControls(page, pageCount, setPage)
  for i = 1, #controls do
    output[#output + 1] = controls[i]
  end
  return output
end

local function beginNew()
  state.newMode = true
  state.newId = nil
  state.readOnlyMessage = nil
  state.exportText = nil
  state.conditionPickerPath = nil
  state.conditionPickerMode = nil
  resetPages()
  RightPanel.rebuild()
end

local function selectNow(id)
  state.selectedId = id
  state.exportText, state.newMode, state.conditionPickerPath, state.trackInput =
    nil, false, nil, nil
  state.conditionPickerMode = nil
  resetPages()
  state.readOnlyMessage = nil

  if not Catalog.canEdit(id) then
    local info = Catalog.info(id)
    state.working, state.saved = nil, nil
    state.readOnlyMessage = Catalog.documentDiagnostic()
      or info and info.diagnostic
      or info and info.transient and 'This playlist is runtime-only.'
      or 'This playlist has no editable source.'
  else
    state.working = Catalog.draft(id)
    state.saved = Catalog.copy(state.working)
  end

  if selectionHandler then selectionHandler(id, Catalog.categoryFor(id)) end
  RightPanel.rebuild()
end

local function deleteSavedEdits()
  local id = state.selectedId
  if not id or Catalog.documentDiagnostic() or not Catalog.entry(id) then return end

  Catalog.delete(id)
  if Catalog.info(id) then
    selectNow(id)
  else
    state.selectedId, state.working, state.saved = nil, nil, nil
    state.readOnlyMessage = nil
    RightPanel.rebuild()
  end
end

local function continuePending()
  local pending = state.pending
  state.pending = nil
  if not pending then return end

  if pending.kind == 'select' then
    selectNow(pending.id)
  elseif pending.kind == 'new' then
    beginNew()
  elseif pending.kind == 'close' then
    pending.callback()
  end
end

local function request(action)
  if dirty() then
    state.pending = action
    RightPanel.rebuild()
    return
  end

  if action.kind == 'select' then selectNow(action.id) end
  if action.kind == 'new' then beginNew() end
  if action.kind == 'close' then action.callback() end
end

local function unsavedLayout()
  local action = assert(state.pending)
  local destination = action.kind == 'close' and 'close the editor'
    or action.kind == 'new' and 'create a new playlist'
    or 'select another playlist'
  local actions = {}

  if state.working then
    actions[#actions + 1] = button('Save and Continue', function()
      if RightPanel.save() then continuePending() end
    end)
  end

  actions[#actions + 1] = button('Discard and Continue', function()
    local unsavedNewPlaylist = state.working ~= nil
      and state.saved == nil
      and Catalog.info(state.selectedId) == nil
    state.working, state.saved = nil, nil
    if unsavedNewPlaylist then state.selectedId = nil end
    continuePending()
  end)
  actions[#actions + 1] = button('Cancel', function()
    state.pending = nil
    RightPanel.rebuild()
  end)

  return {
    text 'Unsaved changes',
    text 'Save your changes before you continue, or discard them.',
    text 'Action: ' .. destination,
    row(actions),
  }
end

local function newPlaylistLayout()
  return {
    text 'New playlist',
    input(state.newId or '', function(value) state.newId = value or '' end),
    button('Category: ' .. state.newCategory, function()
      state.newCategory = state.newCategory == 'Explore' and 'Battle'
        or state.newCategory == 'Battle' and 'Special'
        or 'Explore'
      RightPanel.rebuild()
    end),
    row {
      button('Create', function()
        if
          state.newId
          and state.newId ~= ''
          and state.newId ~= 'Special'
          and Catalog.canCreate(state.newId)
        then
          state.selectedId, state.working, state.saved, state.newMode =
            state.newId, {
              kind = 'user',
              properties = { priority = NEW_PLAYLIST_PRIORITIES[state.newCategory], tracks = {} },
              condition = PlaylistConditions.serialize(PlaylistConditions.all {}),
            }, nil, false
          if selectionHandler then selectionHandler(state.selectedId, state.newCategory) end
          state.newId = nil
          state.readOnlyMessage = nil
          resetPages()
          RightPanel.rebuild()
        end
      end),
      button('Cancel', function()
        state.newId, state.newMode = nil, false
        RightPanel.rebuild()
      end),
    },
  }
end

local editors = {
  conditions = Conditions {
    state = state,
    PlaylistConditions = PlaylistConditions,
    Catalog = Catalog,
    button = button,
    input = input,
    row = row,
    text = text,
    paged = paged,
    rebuild = function() RightPanel.rebuild() end,
  },
  tracks = Tracks {
    state = state,
    button = button,
    input = input,
    row = row,
    text = text,
    paged = paged,
    rebuild = function() RightPanel.rebuild() end,
    setTrackInput = function(value) state.trackInput = value or '' end,
  },
  properties = Properties {
    state = state,
    Catalog = Catalog,
    button = button,
    input = input,
    row = row,
    text = text,
    rebuild = function() RightPanel.rebuild() end,
  },
  export = Export {
    state = state,
    button = button,
    exportInput = exportInput,
    text = text,
    rebuild = function() RightPanel.rebuild() end,
  },
}

function RightPanel.makeLayout()
  local content

  if state.pending then
    content = unsavedLayout()
  elseif state.newMode then
    content = newPlaylistLayout()
  elseif state.readOnlyMessage then
    content = {
      text(tostring(state.selectedId or 'Playlist unavailable'), 18),
      text(state.readOnlyMessage),
    }
    if Catalog.entry(state.selectedId) and not Catalog.documentDiagnostic() then
      content[#content + 1] = button('Delete Saved Edits', deleteSavedEdits)
    end
  elseif not state.selectedId or not state.working then
    content = {
      text 'Select a playlist.',
      button('New Playlist', function() request { kind = 'new' } end),
    }
  elseif state.exportText then
    content = editors.export.layout()
  elseif state.conditionPickerPath then
    content = editors.conditions.layout()
  else
    local working = assert(state.working)
    content = {
      row {
        text(tostring(state.selectedId), 18),
        { external = { grow = 1 } },
        button('New', function() request { kind = 'new' } end),
        button(dirty() and 'Save *' or 'Save', RightPanel.save),
        button(working.kind == 'override' and 'Revert' or 'Delete', RightPanel.revert),
        working.condition and button('Export', RightPanel.export)
          or text 'Custom condition cannot be exported',
      },
      row {
        button('Conditions', function()
          state.tab = 'Conditions'
          RightPanel.rebuild()
        end),
        button('Tracks', function()
          state.tab = 'Tracks'
          RightPanel.rebuild()
        end),
        button('Properties', function()
          state.tab = 'Properties'
          RightPanel.rebuild()
        end),
      },
    }

    local editor = state.tab == 'Conditions' and editors.conditions
      or state.tab == 'Tracks' and editors.tracks
      or editors.properties
    local body = editor.layout()
    for i = 1, #body do
      content[#content + 1] = body[i]
    end
  end

  return {
    type = ui.TYPE.Flex,
    props = {
      horizontal = false,
      relativeSize = vector2(1, 1),
      autoSize = false,
    },
    content = ui.content(content),
  }
end

function RightPanel.rebuild()
  if element then
    element.layout = RightPanel.makeLayout()
    element:update()
  end
end

function RightPanel.select(id)
  if state.selectedId == id then return true end
  if dirty() then
    state.pending = { kind = 'select', id = id }
    RightPanel.rebuild()
    return false
  end

  selectNow(id)
  return true
end

function RightPanel.save()
  if not state.selectedId or not state.working then return false end
  if not dirty() then return true end

  local entry = Catalog.delta(state.selectedId, state.working)
  if entry then
    Catalog.commit(state.selectedId, entry)
  else
    Catalog.delete(state.selectedId)
  end

  state.working = Catalog.draft(state.selectedId)
  state.saved = Catalog.copy(state.working)
  state.readOnlyMessage = nil
  if selectionHandler then
    selectionHandler(state.selectedId, Catalog.categoryFor(state.selectedId))
  end
  RightPanel.rebuild()
  return true
end

function RightPanel.revert()
  local id, hasSource = state.selectedId, Catalog.source(state.selectedId) ~= nil

  if state.saved == nil and not Catalog.entry(id) then
    state.selectedId, state.working = nil, nil
  else
    Catalog.delete(id)
    if hasSource then
      state.working = Catalog.draft(id)
      state.saved = Catalog.copy(state.working)
    else
      state.selectedId, state.working, state.saved = nil, nil, nil
    end
  end

  state.pending, state.readOnlyMessage = nil, nil
  resetPages()
  RightPanel.rebuild()
end

function RightPanel.export()
  state.exportText =
    PlaylistExport(state.selectedId, state.working, Catalog.source(state.selectedId))
  RightPanel.rebuild()
end

function RightPanel.refresh()
  if state.selectedId and not dirty() and not state.pending then
    selectNow(state.selectedId)
    return
  end

  RightPanel.rebuild()
end

function RightPanel.hasUnsavedChanges() return dirty() end

function RightPanel.requestClose(callback) request { kind = 'close', callback = callback } end

function RightPanel.setSelectionHandler(handler) selectionHandler = handler end

element = ui.create(RightPanel.makeLayout())

function RightPanel.getElement() return element end

return RightPanel
