---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local ceil, floor, max, min = math.ceil, math.floor, math.max, math.min

local vector2 = util.vector2

local MusicManager = require 'scripts.s3.music.musicManager'

local Constants = require 'scripts.omw.mwui.constants'

local DisplayTier = require 'scripts.s3.music.playlistEditor.displayTier'

local WINDOW_RELATIVE = vector2(0.75, 0.75)
local ROW_PX = 13
local TABS_PX = 24
local CONTROLS_PX = 20

local state = {
  selectedCategory = 'Explore',
  currentPage = 0,
  pageSize = 8,
}

local activeTab, clicked

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
  return max(1, floor(listPx / ROW_PX))
end

---@return number
local function computeInset()
  local tier = DisplayTier.getTier()
  if tier == DisplayTier.DisplayTier.Small then
    return 4
  elseif tier == DisplayTier.DisplayTier.Ultra then
    return 16
  end
  return 8
end

---@return number textSize
local function computePlaylistTextSize()
  ---@diagnostic disable-next-line: undefined-field
  local base = ui._getDefaultFontSize()
  local tier = DisplayTier.getTier()

  local minimum = 16

  if tier == DisplayTier.DisplayTier.Small then
    minimum = 14
  elseif tier == DisplayTier.DisplayTier.Ultra then
    minimum = 18
  end

  return max(minimum, ceil(base * 1.2))
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
  return max(-slot.props.size.x, -slot.props.size.y, 0)
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

local function totalPages() return max(ceil(#getCategoryPlaylists() / state.pageSize), 1) end

local function pagePlaylists()
  local all = getCategoryPlaylists()
  local start = state.currentPage * state.pageSize + 1
  local finish = min(start + state.pageSize - 1, #all)

  local page = {}

  for i = start, finish do
    page[#page + 1] = all[i]
  end

  return page
end

local LeftPanel = {}

local leftElement

local function rebuild()
  leftElement.layout = LeftPanel.makeLayout()
  leftElement:update()
end

local function makeCategoryTab(name)
  local selected = name == state.selectedCategory
  local baseColor = darken(Constants.headerColor, 0.55)
  local hoverColor = darken(Constants.headerColor, 0.85)
  local activeColor = darken(Constants.headerColor, 0.7)
  local color
  if selected then
    color = Constants.headerColor
  elseif name == activeTab then
    color = clicked and activeColor or hoverColor
  else
    color = baseColor
  end
  local events = {}
  if not selected then
    events.mousePress = async:callback(function()
      activeTab, clicked = name, true
      rebuild()
    end)
    events.mouseRelease = async:callback(function()
      state.selectedCategory = name
      state.currentPage = 0
      activeTab, clicked = name, false
      rebuild()
    end)
    events.focusGain = async:callback(function()
      activeTab, clicked = name, false
      rebuild()
    end)
    events.focusLoss = async:callback(function()
      activeTab, clicked = nil, false
      rebuild()
    end)
  end
  return {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textHeader,
    props = {
      text = name,
      textColor = color,
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

function LeftPanel.makeCategoryTabs()
  local tabBorder = borderInset(I.MWUI.templates.borders)

  ---@diagnostic disable-next-line: undefined-field
  local lineHeight = ui._getDefaultFontSize()

  return {
    template = I.MWUI.templates.borders,
    type = ui.TYPE.Flex,
    props = {
      horizontal = true,
      relativeSize = vector2(1, 0),
      autoSize = false,
      align = ui.ALIGNMENT.Center,
      size = vector2(0, ceil(lineHeight * 1.2) + tabBorder * 2),
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

function LeftPanel.makePlaylistPage()
  local playlists, items = pagePlaylists(), {}
  local rowHeight = state.pageSize > 0 and (1 / state.pageSize) or 1

  local playlistTextSize = computePlaylistTextSize()

  for i = 1, #playlists do
    local playlist = playlists[i]

    items[#items + 1] = {
      type = ui.TYPE.Text,
      template = I.MWUI.templates.textNormal,
      props = {
        relativeSize = vector2(1, rowHeight),
        text = '  ' .. getPlaylistDisplayName(playlist),
        textSize = playlistTextSize,
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

function LeftPanel.makePageControls()
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

function LeftPanel.makeLayout()
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
          align = ui.ALIGNMENT.Center,
          autoSize = false,
          horizontal = false,
          position = vector2(inset, inset),
          relativeSize = vector2(1, 1),
          size = vector2(-inset * 2, -inset * 2),
        },
        content = ui.content {
          LeftPanel.makeCategoryTabs(),
          { external = { grow = 0.025 } },
          {
            template = I.MWUI.templates.borders,
            type = ui.TYPE.Flex,
            props = {
              horizontal = false,
              relativeSize = vector2(1, 0.95),
              autoSize = false,
            },
            content = ui.content {
              LeftPanel.makePlaylistPage(),
              LeftPanel.makePageControls(),
            },
          },
        },
      },
    },
  }
end

leftElement = ui.create(LeftPanel.makeLayout())

function LeftPanel.getElement() return leftElement end

LeftPanel.rebuild = rebuild

function LeftPanel.onViewportResized(_, _) rebuild() end

return LeftPanel
