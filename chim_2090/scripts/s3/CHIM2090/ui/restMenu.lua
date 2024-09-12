local async = require('openmw.async')
local calendar = require('openmw_aux.calendar')
local ui = require('openmw.ui')
local util = require('openmw.util')

local I = require('openmw.interfaces')
local templates = I.MWUI.templates
local constants = require('scripts.omw.mwui.constants')

local Object = require('scripts.s3.CHIM2090.lib.object')

--- Returns a specific date string
--- for Starwind or Morrowind
--- @return string
local function getDateStr()
  return '%H:%M, Day %d of %b, %Y BBY'
end

--- The RestMenu class
--- @class RestMenu
--- @field layer string
--- @field type ui.TYPE
--- @field name string
--- @field template ui.Layout
--- @field props table
--- @field userData table
local RestMenu = {
  layer = 'Windows',
  type = ui.TYPE.Window,
  name = 's3ChimRestMenu',
  template = I.MWUI.templates.bordersThick,
  props = {
    anchor = util.vector2(.5, .5),
    position = util.vector2(0, 0),
    relativePosition = util.vector2(.5, .5),
    relativeSize = util.vector2(.25, .25),
    visible = true,
  },
  userData = {
    doDrag = false,
    lastMousePos = nil,
    minorSize = util.vector2(1, .125),
    majorSize = util.vector2(1, .35),
    RestString = 'Sleeping',
    WaitString = 'You cannot sleep here. You\'ll need to find a bed.',
  }
}

--- Returns a transparent black background
--- @return ui.TYPE.Image
function RestMenu.Background()
  return {
    type = ui.TYPE.Image,
    external = {
      stretch = 1,
      grow = 1,
    },
    props = {
      relativeSize = util.vector2(1, 1),
      resource = ui.texture { path = "white" },
      color = util.color.hex('000000'),
      alpha = .75,
    },
  }
end

--- Returns a container element with
--- all elements of the sleep frame
--- @return ui.TYPE.Flex
function RestMenu.WidgetBody()
  return {
    type = ui.TYPE.Flex,
    name = 'widgetBody',
    props = {
      arrange = ui.ALIGNMENT.Center,
      relativeSize = util.vector2(1, 1),
      autoSize = false,
    },
    content = ui.content {
      RestMenu.DateHeader(),
      { external = { grow = 1 } },
      RestMenu.SleepInfoString(),
      RestMenu.TimeSelectBody(),
      RestMenu.HoursToHeal(),
      RestMenu.BottomRowContainer(),
    }
  }
end

--- Returns a text element containing a
--- formatted date string for the current game time
--- @return ui.TYPE.Text
function RestMenu.DateHeader()
  local headerText = calendar.formatGameTime(getDateStr())
  local dateHeader = RestMenu.TextBox(headerText)
  dateHeader.props.relativeSize = RestMenu.userData.minorSize
  dateHeader.name = 'dateHeader'
  return dateHeader
end

--- Returns a text element describing
--- whether you can sleep and the quality of your sleep
--- @return ui.TYPE.Text
function RestMenu.SleepInfoString()
  local sleepInfo = RestMenu.TextBox(RestMenu.userData.RestString)
  sleepInfo.props.relativeSize = RestMenu.userData.minorSize
  sleepInfo.name = 'sleepInfoBox'
  return sleepInfo
end

--- Returns a container element with an interactive arrow
--- for either increasing or decreasing the time spent resting
--- @param left boolean: Whether the arrow should point left or right
--- @return ui.TYPE.Flex
function RestMenu.ArrowContainer(left)
  local arrowPath = 'textures/menu_scroll_' .. (left and 'left' or 'right') .. '.dds'
  local arrowName = left and 'increase' or 'decrese' .. 'SleepArrow'
  local containerName = arrowName .. 'Container'

  local arrow = {
    type = ui.TYPE.Image,
    name = arrowName,
    props = {
      resource = ui.texture { path = arrowPath },
      size = util.vector2(32, 32),
    },
  }

  return {
    type = ui.TYPE.Flex,
    name = containerName,
    props = {
      autoSize = false,
      relativeSize = util.vector2(0, 1),
      align = ui.ALIGNMENT.Center,
      arrange = left and ui.ALIGNMENT.End or ui.ALIGNMENT.Start,
    },
    external = { grow = 1, },
    content = ui.content {
      arrow
    }
  }
end

--- Returns a container element with a text box
--- showing how many hours you will sleep
--- @return ui.TYPE.Flex
function RestMenu.SleepTimeContainer()
  return {
    type = ui.TYPE.Flex,
    props = {
      relativeSize = util.vector2(0.2, 1),
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content {
      {
        type = ui.TYPE.Text,
        name = 'sleepTimeSelection',
        props = {
          text = '24',
          textAlignH = ui.ALIGNMENT.Center,
          textAlignV = ui.ALIGNMENT.Center,
          textColor = constants.normalColor,
          textSize = 48,
        },
      }
    },
  }
end

function RestMenu.TimeSelectBody()
  return {
    type = ui.TYPE.Flex,
    name = 'timeSelectBody',
    props = {
      arrange = ui.ALIGNMENT.Center,
      horizontal = true,
      autoSize = false,
      relativeSize = RestMenu.userData.majorSize,
    },
    content = ui.content {
      RestMenu.ArrowContainer(true),
      RestMenu.SleepTimeContainer(),
      RestMenu.ArrowContainer(false),
    }
  }
end

--- Returns a text element containing the input string
--- @param text string: The text to display
--- @return ui.TYPE.Text
function RestMenu.Button(text)
  return {
    template = templates.bordersThick,
    type = ui.TYPE.Text,
    props = {
      relativeSize = util.vector2(0.25, 1),
      text = text,
      textSize = constants.textHeaderSize,
      textColor = constants.normalColor,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      autoSize = false,
    }
  }
end

--- Returns a text element
--- describing how long it will take to heal via sleeping
--- @return ui.TYPE.Text
function RestMenu.HoursToHeal()
  local hoursToHeal = RestMenu.TextBox('You will need to sleep for '
                                       ..  'X'
                                       .. ' hours to recover from your wounds.')
  hoursToHeal.props.multiline = true
  hoursToHeal.props.wordWrap = true
  hoursToHeal.props.relativeSize = util.vector2(.75, .2)
  hoursToHeal.name = 'totalHoursToHeal'
  return hoursToHeal
end

--- Returns a container element with
--- interactive elements which allow the user to select
--- whether to rest or now
--- @return ui.TYPE.Flex
function RestMenu.BottomRowContainer()
  -- These will all need events corresponding to their actions
  local cancelButton = RestMenu.Button('Cancel')
  local waitButton = RestMenu.Button('Wait')
  local untilHealedButton = RestMenu.Button('Until Healed')

  return {
    type = ui.TYPE.Flex,
    name = 'selectionButtonRow',
    props = {
      relativeSize = RestMenu.userData.minorSize,
      horizontal = true,
      align = ui.ALIGNMENT.Center,
      arrange = ui.ALIGNMENT.Center,
      autoSize = false,
    },
    external = { grow = 1, stretch = 1 },
    content = ui.content {
      cancelButton,
      { external = { grow = 1, stretch = 1 } },
      untilHealedButton,
      { external = { grow = 1, stretch = 1 } },
      waitButton,
    }
  }

end

--- Just a simple text box, this is used in multiple places
--- @param text string: The text to display
--- @return ui.TYPE.Text
function RestMenu.TextBox(text)
  local textBox = {
    type = ui.TYPE.Text,
    props = {
      text = text,
      textColor = constants.normalColor,
      textSize = constants.textHeaderSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      autoSize = false,
    }
  }
  return textBox
end

RestMenu.startDrag = async:callback(function(coord)
  RestMenu.userData.doDrag = true
  RestMenu.userData.lastMousePos = coord.position
end)

RestMenu.stopDrag = async:callback(function()
    RestMenu.userData.doDrag = false
end)

RestMenu.drag = async:callback(function(coord, layout)
    if not RestMenu.userData.doDrag then return end
    local props = layout.props
    props.position = props.position - (RestMenu.userData.lastMousePos - coord.position)
    I.s3ChimSleep.Menu:update()
    RestMenu.userData.lastMousePos = coord.position
end)

RestMenu.events = {
  mousePress = RestMenu.startDrag,
  mouseRelease = RestMenu.stopDrag,
  mouseMove = RestMenu.drag,
}

--- Rest menu constructor
--- @return RestMenu
function RestMenu:new()
  local newUIObject = Object:new(self)

  for k, v in pairs(self) do
    newUIObject[k] = v
  end

  newUIObject.content = ui.content {
    RestMenu.Background(),
    RestMenu.WidgetBody(),
  }

  return newUIObject
end

--- Returns a ui layout with the input name
--- @param name string: The name of the element to find
--- @return ui.Layout
function RestMenu:getElementByName(name)
  for _, child in ipairs(self.content or {}) do
    if child.props and child.props.name == name then
      return child
    end
    local found = self:getElementByName(child, name)
    if found then return found end
  end
end

return RestMenu
