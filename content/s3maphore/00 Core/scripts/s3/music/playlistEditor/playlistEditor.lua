---@omw-context player

local I = require 'openmw.interfaces'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2

local WHITE_TEXTURE = ui.texture { path = 'white' }

local DisplayTier = require 'scripts.s3.music.playlistEditor.displayTier'
local LeftPanel = require 'scripts.s3.music.playlistEditor.leftPanel'

---@return number
local function menuAlpha()
  ---@diagnostic disable-next-line: undefined-field
  return ui._getMenuTransparency()
end

local M = {}

function M.makeLayout(leftElement)
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
              leftElement,
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
local leftElement = LeftPanel.getElement()

---@type openmw.ui.Element
local rootElement = ui.create(M.makeLayout(leftElement))
rootElement.layout.props.visible = false
rootElement:update()

function M.init() ready = true end

function M.isVisible() return rootElement.layout.props.visible end

function M.refresh()
  if not M.isVisible() then return end
  LeftPanel.rebuild()
end

function M.show()
  if not ready or M.isVisible() then return end
  core.sendGlobalEvent 'S3maphorePlaylistEditorOpened'
  I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
  DisplayTier.refreshDisplayTier(ui.screenSize().y)
  LeftPanel.rebuild()
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

function M.onViewportResized(width, height) LeftPanel.onViewportResized(width, height) end

return M
