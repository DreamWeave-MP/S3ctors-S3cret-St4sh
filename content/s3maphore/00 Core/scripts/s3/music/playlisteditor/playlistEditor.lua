---@omw-context player

local I = require 'openmw.interfaces'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2

local WHITE_TEXTURE = ui.texture { path = 'white' }

local PANEL_COLORS = {
  left = util.color.rgb(1, 0, 0),
  top = util.color.rgb(0, 1, 0),
  bottom = util.color.rgb(0, 0, 1),
}

local M = {}

function M.makeLeftPanel()
  return {
    name = 'S3maphore_PlaylistEditor_Left',
    type = ui.TYPE.Image,
    props = {
      resource = WHITE_TEXTURE,
      color = PANEL_COLORS.left,
      relativeSize = vector2(1 / 3, 1),
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
              M.makeLeftPanel(),
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
