local async = require('openmw.async')
local calendar = require('openmw_aux.calendar')
local core = require('openmw.core')
local time = require('openmw_aux.time')
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
  dateHeader.props.textColor = RestMenu.userData.colors.textHeader
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

local HighlightStates = {
  DARK = 0,
  MEDIUM = 1,
  NORMAL = 2,
}

function RestMenu.colorFromGMST(gmst)
  local colorString = core.getGMST(gmst)
  local numberTable = {}
  for numberString in colorString:gmatch("([^,]+)") do
    if #numberTable == 3 then break end
    local number = tonumber(numberString:match("^%s*(.-)%s*$"))
    if number then
      table.insert(numberTable, number / 255)
    end
  end

  if #numberTable < 3 then error('Invalid color GMST name: ' .. gmst) end

  return util.color.rgb(table.unpack(numberTable))
end

RestMenu.userData.colors = {
  textHeader = RestMenu.colorFromGMST('fontcolor_color_header'),
  textNormal = RestMenu.colorFromGMST('fontcolor_color_normal'),
  textNormalOver = RestMenu.colorFromGMST('fontcolor_color_normal_over'),
  textNormalPressed = RestMenu.colorFromGMST('fontcolor_color_normal_pressed'),
  highlightNormal = RestMenu.colorFromGMST('fontcolor_color_big_normal'),
  highlightOver = RestMenu.colorFromGMST('fontcolor_color_big_normal_over'),
  highlightPressed = RestMenu.colorFromGMST('fontcolor_color_big_normal_pressed'),
  journalNormal = RestMenu.colorFromGMST('FontColor_color_journal_link'),
  journalOver = RestMenu.colorFromGMST('FontColor_color_journal_link_over'),
  journalPressed = RestMenu.colorFromGMST('FontColor_color_journal_link_pressed'),
}

local function updateHighlight(highlightData)
  local layout = highlightData.layout
  local state = highlightData.state

  if state == HighlightStates.DARK then
    layout.props.color = RestMenu.userData.colors.highlightPressed
    layout.props.size = util.vector2(30, 30)
  elseif state == HighlightStates.MEDIUM then
    layout.props.color = RestMenu.userData.colors.highlightOver
    layout.props.size = util.vector2(40, 40)
  elseif state == HighlightStates.NORMAL then
    layout.props.color = RestMenu.userData.colors.highlightNormal
    layout.props.size = util.vector2(32, 32)
  end

  if highlightData.update then
    I.s3ChimSleep.Menu:update()
  end
end

local function updateTime(left)
  local menu = I.s3ChimSleep.Menu

  local mainLayout = menu.layout

  local hourBox = RestMenu.getElementByName('sleepTimeSelection', mainLayout)
  local hours = hourBox.props.text

  if left then
    hours = hours - 1 >= 1 and hours - 1 or 24
  else
    hours = math.max(1, (hours + 1) % 25)
  end

  hourBox.props.text = tostring(hours)

  menu:update()
end

--- Returns a container element with an interactive arrow
--- for either increasing or decreasing the time spent resting
--- @param left boolean: Whether the arrow should point left or right
--- @return ui.TYPE.Flex
function RestMenu.ArrowContainer(left)
  local arrowPath = 'textures/menu_scroll_' .. (left and 'left' or 'right') .. '.dds'
  local arrowName = (left and 'decrease' or 'increase') .. 'SleepArrow'
  local containerName = arrowName .. 'Container'

  local arrow = {
    type = ui.TYPE.Image,
    name = arrowName,
    props = {
      resource = ui.texture { path = arrowPath },
      size = util.vector2(32, 32),
      color = RestMenu.userData.colors.highlightNormal,
    },
    events = {
      mousePress = async:callback(function(_, layout)
        updateHighlight {
          state = HighlightStates.DARK,
          layout = layout,
        }
        if RestMenu.timeStopFn then RestMenu.timeStopFn() end
        RestMenu.timeStopFn = time.runRepeatedly(function() updateTime(left) end, .2, { initialDelay = 0 })
      end),
      mouseRelease = async:callback(function(_, layout)
        updateHighlight {
          state = HighlightStates.MEDIUM,
          layout = layout,
          update = true,
        }
        if RestMenu.timeStopFn then RestMenu.timeStopFn() end
      end),
      focusGain = async:callback(function(_, layout)
          updateHighlight {
            state = HighlightStates.MEDIUM,
            layout = layout,
            update = true,
          }
      end),
      focusLoss = async:callback(function(_, layout)
        updateHighlight {
          state = HighlightStates.NORMAL,
          layout = layout,
          update = true,
        }
      end),
    }
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
        type = ui.TYPE.TextEdit,
        name = 'sleepTimeSelection',
        external = { grow = 1, stretch = 1 },
        props = {
          text = '24',
          textAlignH = ui.ALIGNMENT.Center,
          textAlignV = ui.ALIGNMENT.Center,
          textColor = RestMenu.userData.colors.textNormal,
          textSize = 48,
        },
        events = {
          textChanged = async:callback(function(input, layout)
              local subInput = input:gsub('%D', '')
              local hours = tonumber(subInput) or 24
              local newHours = math.min(24, math.max(1, hours))
              layout.props.text = tostring(newHours)
              I.s3ChimSleep.Menu:update()
          end),
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
      textColor = RestMenu.userData.colors.textNormal,
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
      textColor = RestMenu.userData.colors.textNormal,
      textSize = constants.textHeaderSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      autoSize = false,
    }
  }
  return textBox
end

RestMenu.startDrag = async:callback(function(mouseEvent)
    if mouseEvent.button ~= 1 then return end
    RestMenu.userData.doDrag = true
    RestMenu.userData.lastMousePos = mouseEvent.position
end)

RestMenu.stopDrag = async:callback(function(mouseEvent)
    if mouseEvent.button ~= 1 then return end
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
function RestMenu.getElementByName(name, layout)
  for _, child in ipairs(layout.content or {}) do
    if child.name and child.name == name then
      return child
    end
    local found = RestMenu.getElementByName(name, child)
    if found then return found end
  end
end

return RestMenu:new()
