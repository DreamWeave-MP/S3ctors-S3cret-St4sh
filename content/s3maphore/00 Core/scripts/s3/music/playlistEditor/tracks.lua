---@omw-context player
local vfs = require 'openmw.vfs'

local find = string.find

return function(context)
  local state, button, input, paged, rebuild =
    context.state, context.button, context.input, context.paged, context.rebuild
  local trackPaths

  local function getTrackPaths()
    if trackPaths then return trackPaths end

    trackPaths = {}
    for path in vfs.pathsWithPrefix 'music/' do
      if
        path:match '%.flac$'
        or path:match '%.mp3$'
        or path:match '%.ogg$'
        or path:match '%.wav$'
        or path:match '%.xwm$'
      then
        trackPaths[#trackPaths + 1] = path
      end
    end
    table.sort(trackPaths)
    return trackPaths
  end

  local function pickerLayout()
    local search = state.trackSearch or ''
    local matches = {}
    local paths = getTrackPaths()

    for i = 1, #paths do
      local path = paths[i]
      if search == '' or find(path, search, 1, true) then matches[#matches + 1] = path end
    end

    local output = {
      context.text 'Track browser',
      input(state.trackSearch, function(value) state.trackSearch = value or '' end),
      button('Search', function()
        state.pickerPage = 0
        rebuild()
      end),
      button('Cancel', function()
        state.trackPicker = false
        state.trackSearch = ''
        state.pickerPage = 0
        rebuild()
      end),
    }
    local page = paged(#matches, state.pickerPage, function(first, last)
      local items = {}
      for i = first, last do
        local path = matches[i]
        items[#items + 1] = button(path, function()
          state.working.properties.tracks[#state.working.properties.tracks + 1] = path
          state.trackPicker = false
          state.trackSearch = ''
          state.pickerPage = 0
          rebuild()
        end)
      end
      return items
    end, function(value) state.pickerPage = value end)
    for i = 1, #page do
      output[#output + 1] = page[i]
    end
    return output
  end

  local function layout()
    if state.trackPicker then return pickerLayout() end

    local output = { context.text 'Tracks' }
    local trackPage = paged(#state.working.properties.tracks, state.trackPage, function(first, last)
      local page = {}
      for i = first, last do
        local index = i
        page[#page + 1] = context.row {
          context.text(string.format('%d. %s', index, state.working.properties.tracks[index])),
          button('Up', function()
            if index > 1 then
              local tracks = state.working.properties.tracks
              tracks[index], tracks[index - 1] = tracks[index - 1], tracks[index]
              rebuild()
            end
          end),
          button('Down', function()
            local tracks = state.working.properties.tracks
            if index < #tracks then
              tracks[index], tracks[index + 1] = tracks[index + 1], tracks[index]
              rebuild()
            end
          end),
          button('Remove', function()
            table.remove(state.working.properties.tracks, index)
            rebuild()
          end),
        }
      end
      return page
    end, function(value) state.trackPage = value end)
    for i = 1, #trackPage do
      output[#output + 1] = trackPage[i]
    end
    output[#output + 1] = input(state.trackInput or '', context.setTrackInput)
    output[#output + 1] = button('Add Track', function()
      if state.trackInput and state.trackInput ~= '' then
        state.working.properties.tracks[#state.working.properties.tracks + 1] = state.trackInput
        state.trackInput = ''
        rebuild()
      end
    end)
    output[#output + 1] = button('Browse Tracks', function()
      state.trackPicker = true
      state.pickerPage = 0
      rebuild()
    end)
    return output
  end

  return { layout = layout }
end
