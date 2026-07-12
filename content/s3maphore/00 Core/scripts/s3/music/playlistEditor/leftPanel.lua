---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2

local MusicManager = require 'scripts.s3.music.musicManager'

local Constants = require 'scripts.omw.mwui.constants'

local WINDOW_RELATIVE = vector2(0.75, 0.75)
local ROW_PX = 13
local TABS_PX = 24
local CONTROLS_PX = 20

local state = {
  selectedCategory = 'Explore',
  currentPage = 0,
  pageSize = 8,
}

---@param color openmw.util.Color
---@param factor number
---@return openmw.util.Color
local function darken(color, factor)
  local c = color:asRgb()
  return util.color.rgb(c.x * factor, c.y * factor, c.z * factor)
end

---@return number
local function computePageSize()
  local screen = ui.screenSize()
  local windowPx = screen.y * WINDOW_RELATIVE.y
  local listPx = windowPx - TABS_PX - CONTROLS_PX
  return math.max(1, math.floor(listPx / ROW_PX))
end

---@return number
local function computeInset()
  local y = ui.screenSize().y
  if y <= 720 then return 4 end
  if y >= 2160 then return 16 end
  return 8
end

--- Reads the per-side inset (border thickness) of an MWUI border template from
--- its slot size, so layout stays correct if another mod overrides the template.
---@param template openmw.ui.Template
---@return number
local function borderInset(template)
  local content = template and template.content
  if not content then return 0 end
  local slot = content[#content]
  if not slot or not slot.props or not slot.props.size then return 0 end
  return math.max(-slot.props.size.x, -slot.props.size.y, 0)
end

local function getPlaylistDisplayName(playlist)
  local meta = MusicManager.playlistMetadata.getPlaylistMetadata(playlist.id)
  return meta and meta.title or playlist.id
end

local function getCategoryPlaylists()
  if state.selectedCategory == 'Explore' then
    return MusicManager.explorePlaylists
  elseif state.selectedCategory == 'Battle' then
    return MusicManager.battlePlaylists
  else
    return MusicManager.specialPlaylists
  end
end

local function totalPages() return math.max(math.ceil(#getCategoryPlaylists() / state.pageSize), 1) end

local function pagePlaylists()
  local all = getCategoryPlaylists()
  local start = state.currentPage * state.pageSize + 1
  local finish = math.min(start + state.pageSize - 1, #all)

  local page = {}

  for i = start, finish do
    page[#page + 1] = all[i]
  end

  return page
end

local M = {}

local leftElement

local function rebuild()
  leftElement.layout = M.makeLayout()
  leftElement:update()
end

local function makeCategoryTab(name)
  local selected = name == state.selectedCategory
  local baseColor = selected and Constants.headerColor or darken(Constants.headerColor, 0.55)
  local hoverColor = selected and Constants.headerColor or darken(Constants.headerColor, 0.85)
  local events = {}
  if not selected then
    events.mouseClick = async:callback(function()
      state.selectedCategory = name
      state.currentPage = 0
      rebuild()
    end)
    events.focusGain = async:callback(function(_, layout)
      layout.props.textColor = hoverColor
      leftElement:update()
    end)
    events.focusLoss = async:callback(function(_, layout)
      layout.props.textColor = baseColor
      leftElement:update()
    end)
  end
  return {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textHeader,
    props = {
      text = name,
      textColor = baseColor,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
    },
    events = events,
  }
end

local function makeCategorySeparator()
  return {
    template = I.MWUI.templates.verticalLine,
    props = { relativeSize = vector2(0, 1) },
  }
end

function M.makeCategoryTabs()
  local tabBorder = borderInset(I.MWUI.templates.borders)
  ---@diagnostic disable-next-line: undefined-field
  local lineHeight = ui._getDefaultFontSize()
  return {
    ---@diagnostic disable-next-line: undefined-field
    template = I.MWUI.templates.borders,
    type = ui.TYPE.Flex,
    props = {
      horizontal = true,
      relativeSize = vector2(1, 0),
      autoSize = false,
      align = ui.ALIGNMENT.Center,
      size = vector2(0, math.ceil(lineHeight * 1.2) + tabBorder * 2),
    },
    content = ui.content {
      { external = { grow = 1 } },
      makeCategoryTab 'Explore',
      { external = { grow = 1 } },
      makeCategorySeparator(),
      { external = { grow = 1 } },
      makeCategoryTab 'Battle',
      { external = { grow = 1 } },
      makeCategorySeparator(),
      { external = { grow = 1 } },
      makeCategoryTab 'Special',
      { external = { grow = 1 } },
    },
  }
end

function M.makePlaylistPage()
  local playlists, items = pagePlaylists(), {}
  local rowHeight = state.pageSize > 0 and (1 / state.pageSize) or 1
  for i = 1, #playlists do
    local playlist = playlists[i]
    items[#items + 1] = {
      type = ui.TYPE.Text,
      template = I.MWUI.templates.textNormal,
      props = {
        relativeSize = vector2(1, rowHeight),
        text = '  ' .. getPlaylistDisplayName(playlist),
        textSize = 13,
        textColor = Constants.normalColor,
        textAlignV = ui.ALIGNMENT.Center,
      },
    }
  end
  return {
    type = ui.TYPE.Flex,
    props = {
      horizontal = false,
      relativeSize = vector2(1, 1),
      autoSize = false,
    },
    content = ui.content(items),
  }
end

function M.makePageControls()
  local tp = totalPages()
  local isFirst = state.currentPage <= 0
  local isLast = state.currentPage >= tp - 1

  return {
    type = ui.TYPE.Flex,
    props = { horizontal = true },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
          text = '< Prev',
          textSize = 13,
          textColor = isFirst and darken(Constants.normalColor, 0.4) or Constants.normalColor,
        },
        events = isFirst and {} or {
          mouseClick = async:callback(function()
            state.currentPage = state.currentPage - 1
            rebuild()
          end),
        },
      },
      {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
          text = '  ' .. (state.currentPage + 1) .. '/' .. tp .. '  ',
          textSize = 13,
          textColor = darken(Constants.normalColor, 0.8),
        },
      },
      {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
          text = 'Next >',
          textSize = 13,
          textColor = isLast and darken(Constants.normalColor, 0.4) or Constants.normalColor,
        },
        events = isLast and {} or {
          mouseClick = async:callback(function()
            state.currentPage = state.currentPage + 1
            rebuild()
          end),
        },
      },
    },
  }
end

--- Compiled left-panel layout. No `layer` field: intended to be embedded in the
--- root editor element's content.
function M.makeLayout()
  state.pageSize = computePageSize()
  local inset = computeInset()
  return {
    name = 'S3maphore_PlaylistEditor_Left',
    props = {
      relativeSize = vector2(1 / 3, 1),
    },
    content = ui.content {
      {
        type = ui.TYPE.Flex,
        props = {
          horizontal = false,
          relativeSize = vector2(1, 1),
          autoSize = false,
          position = vector2(inset, inset),
          size = vector2(-inset * 2, -inset * 2),
        },
        content = ui.content {
          M.makeCategoryTabs(),
          {
            type = ui.TYPE.Flex,
            props = { size = vector2(0, 4) },
          },
          {
            ---@diagnostic disable-next-line: undefined-field
            template = I.MWUI.templates.borders,
            type = ui.TYPE.Flex,
            props = {
              horizontal = false,
              relativeSize = vector2(1, 1),
              autoSize = false,
            },
            external = { grow = 1 },
            content = ui.content {
              M.makePlaylistPage(),
              M.makePageControls(),
            },
          },
        },
      },
    },
  }
end

leftElement = ui.create(M.makeLayout())

function M.getElement()
  return leftElement
end

M.rebuild = rebuild

return M
