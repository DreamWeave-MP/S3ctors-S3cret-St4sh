---@omw-context player

local I = require 'openmw.interfaces'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2

local MusicManager = require 'scripts.s3.music.musicManager'

local WHITE_TEXTURE = ui.texture { path = 'white' }

local PANEL_COLORS = {
  left = util.color.rgb(1, 0, 0),
  top = util.color.rgb(0, 1, 0),
  bottom = util.color.rgb(0, 0, 1),
}

local M = {}

local function getPlaylistDisplayName(playlist)
  local meta = MusicManager.playlistMetadata.getPlaylistMetadata(playlist.id)
  return meta and meta.title or playlist.id
end

function M.makeCategorySection(name, playlists)
  local children = {
    {
      type = ui.TYPE.Text,
      template = I.MWUI.templates.textHeader,
      props = {
        text = name,
        textSize = 22,
      },
    },
  }

  for _, playlist in ipairs(playlists) do
    children[#children + 1] = {
      type = ui.TYPE.Text,
      template = I.MWUI.templates.textNormal,
      props = {
        text = '  ' .. getPlaylistDisplayName(playlist),
        textSize = 16,
      },
    }
  end

  return {
    type = ui.TYPE.Flex,
    props = {
      horizontal = false,
      relativeSize = vector2(1, 1 / 3),
      autoSize = false,
      arrange = ui.ALIGNMENT.Start,
    },
    content = ui.content(children),
  }
end

function M.makeLeftPanel(musicManager)
  return {
    name = 'S3maphore_PlaylistEditor_Left',
    props = {
      relativeSize = vector2(1 / 3, 1),
    },
    content = ui.content {
      {
        type = ui.TYPE.Image,
        props = {
          resource = WHITE_TEXTURE,
          color = PANEL_COLORS.left,
          relativeSize = vector2(1, 1),
          position = vector2(8, 8),
          size = vector2(-16, -16),
        },
        content = ui.content {
          {
            type = ui.TYPE.Flex,
            props = {
              horizontal = false,
              relativeSize = vector2(1, 1),
              autoSize = false,
            },
            content = ui.content {
              M.makeCategorySection('Explore', musicManager.explorePlaylists),
              M.makeCategorySection('Battle', musicManager.battlePlaylists),
              M.makeCategorySection('Special', musicManager.specialPlaylists),
            },
          },
        },
      },
    },
  }
end

function M.makeTopRightPanel()
  return {
    name = 'S3maphore_PlaylistEditor_TopRight',
    type = ui.TYPE.Image,
    props = {
      resource = WHITE_TEXTURE,
      color = PANEL_COLORS.top,
      relativeSize = vector2(1, 1 / 3),
    },
  }
end

function M.makeBottomRightPanel()
  return {
    name = 'S3maphore_PlaylistEditor_BottomRight',
    type = ui.TYPE.Image,
    props = {
      resource = WHITE_TEXTURE,
      color = PANEL_COLORS.bottom,
      relativeSize = vector2(1, 2 / 3),
    },
  }
end

---@type openmw.ui.Element?
local rootElement

function M.isVisible()
  return rootElement and rootElement.layout and rootElement.layout.props.visible ~= false
end

function M.show()
  if M.isVisible() then return end

  core.sendGlobalEvent 'S3maphorePlaylistEditorOpened'

  rootElement = ui.create {
    layer = 'HUD',
    name = 'S3maphore_PlaylistEditor',
    template = I.MWUI.templates.bordersThick,
    props = {
      relativeSize = vector2(0.75, 0.75),
      relativePosition = vector2(0.5, 0.5),
      anchor = vector2(0.5, 0.5),
    },
    content = ui.content {
      {
        template = I.MWUI.templates.bordersThick,
        props = {
          relativeSize = vector2(1, 1),
        },
        content = ui.content {
          {
            type = ui.TYPE.Flex,
            name = 'S3maphore_PlaylistEditor_Main',
            props = {
              horizontal = true,
              relativeSize = vector2(1, 1),
              autoSize = false,
            },
            content = ui.content {
              M.makeLeftPanel(MusicManager),
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
                  M.makeTopRightPanel(),
                  {
                    template = I.MWUI.templates.horizontalLine,
                    props = {
                      relativeSize = vector2(1, 0),
                    },
                  },
                  M.makeBottomRightPanel(),
                },
              },
            },
          },
        },
      },
    },
  }
end

function M.hide()
  if not M.isVisible() then return end

  core.sendGlobalEvent 'S3maphorePlaylistEditorClosed'

  assert(rootElement):destroy()
  rootElement = nil
end

function M.toggle()
  if M.isVisible() then
    M.hide()
  else
    M.show()
  end
end

return M
