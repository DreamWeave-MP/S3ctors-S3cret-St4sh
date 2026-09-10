---@module 'doc.s3maphoreTypes'
---@omw-context player

local Interfaces = require 'openmw.interfaces'
local core = require 'openmw.core'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local vector2 = util.vector2

local WHITE_TEXTURE = ui.texture { path = 'white' }

local DisplayTier = require 'scripts.s3.music.playlistEditor.displayTier'
local LeftPanel = require 'scripts.s3.music.playlistEditor.leftPanel'
local RightPanel = require 'scripts.s3.music.playlistEditor.rightPanel'

---@return number
local function menuAlpha()
  ---@diagnostic disable-next-line: undefined-field
  return ui._getMenuTransparency()
end

local PlaylistEditor = {}

function PlaylistEditor.makeLayout(leftElement, rightElement)
  return {
    layer = 'Windows',
    name = 'S3maphore_PlaylistEditor',
    template = Interfaces.MWUI.templates.bordersThick,
    props = {
      relativeSize = vector2(0.75, 0.75),
      relativePosition = vector2(0.5, 0.5),
      anchor = vector2(0.5, 0.5),
    },
    content = ui.content {
      {
        name = 'S3maphore_PlaylistEditor_Window',
        template = Interfaces.MWUI.templates.bordersThick,
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
                template = Interfaces.MWUI.templates.verticalLine,
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
                  rightElement,
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
local rightElement = RightPanel.getElement()
LeftPanel.setSelectionHandler(RightPanel.select)
RightPanel.setSelectionHandler(function(id, category)
  LeftPanel.setSelection(id, category)
  LeftPanel.rebuild()
end)

---@type openmw.ui.Element
local rootElement = ui.create(PlaylistEditor.makeLayout(leftElement, rightElement))
rootElement.layout.props.visible = false
rootElement:update()

function PlaylistEditor.init() ready = true end

function PlaylistEditor.isVisible() return rootElement.layout.props.visible end

function PlaylistEditor.refresh()
  if not PlaylistEditor.isVisible() then return end
  LeftPanel.rebuild()
  RightPanel.refresh()
end

function PlaylistEditor.show()
  if not ready or PlaylistEditor.isVisible() then return end
  core.sendGlobalEvent 'S3maphorePlaylistEditorOpened'
  Interfaces.UI.setMode(Interfaces.UI.MODE.Interface, { windows = {} })
  DisplayTier.refreshDisplayTier(ui.screenSize().y)
  LeftPanel.rebuild()
  RightPanel.refresh()
  rootElement.layout.props.visible = true
  rootElement:update()
end

function PlaylistEditor.hide()
  if not PlaylistEditor.isVisible() then return end
  if RightPanel.hasUnsavedChanges() then
    RightPanel.requestClose(PlaylistEditor.hide)
    return
  end
  core.sendGlobalEvent 'S3maphorePlaylistEditorClosed'
  Interfaces.UI.removeMode(Interfaces.UI.MODE.Interface)
  rootElement.layout.props.visible = false
  rootElement:update()
end

function PlaylistEditor.toggle()
  if not ready then return end
  if PlaylistEditor.isVisible() then
    PlaylistEditor.hide()
  else
    PlaylistEditor.show()
  end
end

function PlaylistEditor.onViewportResized(width, height) LeftPanel.onViewportResized(width, height) end

return PlaylistEditor
