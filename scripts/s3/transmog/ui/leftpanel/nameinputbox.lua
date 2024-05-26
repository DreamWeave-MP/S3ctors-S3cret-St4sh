local const = require('scripts.s3.transmog.ui.common').const
local Object = require('scripts.s3.transmog.lib.object')

local async = require('openmw.async')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local NameInputBox = {
  type = ui.TYPE.TextEdit,
  events = {
    textChanged = async:callback(
      function (text, layout)
        layout.props.text = text
    end)
  },
  userData = {},
  props = {
    name = "Name Input",
    -- Can we flex this or something?
    size = util.vector2(384, 32),
    textSize = const.FONT_SIZE,
    textColor = const.TEXT_COLOR,
    textAlignH = ui.ALIGNMENT.Center,
    textAlignV = ui.ALIGNMENT.Center,
    autoSize = false,
  }
}

function NameInputBox.new(itemData)
  NameInputBox.props.text = itemData.record.name
  return Object:new(NameInputBox)
end

function NameInputBox:mogMenuEvent()
  self.props.text = ""
  I.transmogActions.MenuAliases()['confirm screen']:update()
end

return NameInputBox
