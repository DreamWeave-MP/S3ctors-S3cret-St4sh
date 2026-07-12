---@omw-context player

local I = require 'openmw.interfaces'
local async = require 'openmw.async'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2

local MusicManager = require 'scripts.s3.music.musicManager'

local Constants = require 'scripts.omw.mwui.constants'

local WHITE_TEXTURE = ui.texture { path = 'white' }

---@return number
local function menuAlpha()
  ---@diagnostic disable-next-line: undefined-field
  return ui._getMenuTransparency()
end

---@param color openmw.util.Color
---@param factor number
---@return openmw.util.Color
local function darken(color, factor)
  local c = color:asRgb()
  return util.color.rgb(c.x * factor, c.y * factor, c.z * factor)
end

local WINDOW_RELATIVE = vector2(0.75, 0.75)
local ROW_PX = 13
local TABS_PX = 24
local CONTROLS_PX = 20

local state = {
  selectedCategory = 'Explore',
  currentPage = 0,
  pageSize = 8,
}

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

local M = {}

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

local function makeCategoryTab(name)
  local selected = name == state.selectedCategory
  return {
    type = ui.TYPE.Text,
    template = I.MWUI.templates.textHeader,
    props = {
      text = name,
      textColor = selected and Constants.headerColor or darken(Constants.headerColor, 0.55),
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
    },
    events = selected and {} or {
      onMouseClick = async:callback(function()
        state.selectedCategory = name
        state.currentPage = 0
        M.refresh()
      end),
    },
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
          onMouseClick = async:callback(function()
            state.currentPage = state.currentPage - 1
            M.refresh()
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
          onMouseClick = async:callback(function()
            state.currentPage = state.currentPage + 1
            M.refresh()
          end),
        },
      },
    },
  }
end

function M.makeLeftPanel()
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

function M.makeLayout()
  return {
    layer = 'Windows',
    name = 'S3maphore_PlaylistEditor',
    template = I.MWUI.templates.bordersThick,
    props = {
      relativeSize = vector2(0.75, 0.75),
      relativePosition = vector2(0.5, 0.5),
      anchor = vector2(0.5, 0.5),
    },
    content = ui.content {
      {
        name = 'S3maphore_PlaylistEditor_Window',
        template = I.MWUI.templates.bordersThick,
        props = {
          relativeSize = vector2(1, 1),
        },
        content = ui.content {
          {
            name = 'S3maphore_PlaylistEditor_Background',
            type = ui.TYPE.Image,
            props = {
              resource = WHITE_TEXTURE,
              color = util.color.rgb(0, 0, 0),
              alpha = menuAlpha(),
              relativeSize = vector2(1, 1),
            },
          },
          {
            type = ui.TYPE.Flex,
            name = 'S3maphore_PlaylistEditor_Main',
            props = {
              horizontal = true,
              relativeSize = vector2(1, 1),
              autoSize = false,
            },
            content = ui.content {
              M.makeLeftPanel(),
              {
                template = I.MWUI.templates.verticalLine,
                props = {
                  relativeSize = vector2(0, 1),
                },
              },
              {
                type = ui.TYPE.Flex,
                name = 'S3maphore_PlaylistEditor_Right',
                props = {
                  horizontal = false,
                  relativeSize = vector2(2 / 3, 1),
                  autoSize = false,
                },
                content = ui.content {
                  {
                    template = I.MWUI.templates.horizontalLine,
                    props = {
                      relativeSize = vector2(1, 0),
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  }
end

local ready = false

---@type openmw.ui.Element
local rootElement = ui.create(M.makeLayout())
rootElement.layout.props.visible = false
rootElement:update()

---@type openmw.ui.Element
local leftElement = rootElement.layout.content.S3maphore_PlaylistEditor_Window.content.S3maphore_PlaylistEditor_Main.content.S3maphore_PlaylistEditor_Left

function M.init()
  ready = true
end

function M.isVisible()
  return rootElement.layout.props.visible
end

local function updateLeftPanel()
  leftElement.content = M.makeLeftPanel().content
  rootElement:update()
end

function M.refresh()
  if not M.isVisible() then return end
  state.pageSize = computePageSize()
  if state.currentPage >= totalPages() then state.currentPage = totalPages() - 1 end
  updateLeftPanel()
end

function M.show()
  if not ready or M.isVisible() then return end
  core.sendGlobalEvent 'S3maphorePlaylistEditorOpened'
  I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
  state.pageSize = computePageSize()
  if state.currentPage >= totalPages() then state.currentPage = totalPages() - 1 end
  updateLeftPanel()
  rootElement.layout.props.visible = true
  rootElement:update()
end

function M.hide()
  if not M.isVisible() then return end
  core.sendGlobalEvent 'S3maphorePlaylistEditorClosed'
  I.UI.removeMode(I.UI.MODE.Interface)
  rootElement.layout.props.visible = false
  rootElement:update()
end

function M.toggle()
  if not ready then return end
  if M.isVisible() then
    M.hide()
  else
    M.show()
  end
end

return M
