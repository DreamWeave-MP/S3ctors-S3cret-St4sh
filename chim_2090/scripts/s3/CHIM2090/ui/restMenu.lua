local ambient = require('openmw.ambient')
local async = require('openmw.async')
local calendar = require('openmw_aux.calendar')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local s3lf = require('scripts.s3.lf')
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
  if core.contentFiles.has('Starwind.omwaddon') or core.contentFiles.has('StarwindRemasteredPatch.esm') then
    return '%H:%M, Day %d of %b, %Y BBY'
  else
    return '%H:%M, Day %d of %b, 3E%Y'
  end
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
    visible = false,
  },
  userData = {
    clickSound = 'sound/fx/menu click.wav',
    nearbyActorStats = {},
    doDrag = false,
    lastMousePos = nil,
    sleepInfoSize = util.vector2(.8, .15),
    majorSize = util.vector2(1, .3),
    minorSize = util.vector2(1, .125),
    HoursToHealString = 'You will need to sleep for %d hours to recover from your wounds.',
    RestOnGroundString = 'You will be sleeping on the ground. It won\'t be very comfortable.',
    OutsideBedString = 'You will be sleeping outside. It might actually be pretty nice.',
    BedString = 'You will be sleeping in a bed. It should be pretty comfortable.',
    OwnedBedString = 'You will be sleeping in your own bed. It will be very comfortable.',
    BedrollString = 'You will be sleeping on a bedroll. It won\'t be great, but much better than the floor.',
    WaitString = 'You cannot sleep here. You\'ll need to find a bed.',
    WaitNoHealString = 'Waiting does not heal your wounds.',
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
  RestMenu.startUpdateDate()
  return dateHeader
end

function RestMenu.startUpdateDate()
    RestMenu.userData.dateUpdate = time.runRepeatedly(function()
        local restMenu = I.s3ChimSleep.Menu
        if not restMenu.layout.props.visible then return end
        local dateHeader = RestMenu.getElementByName('dateHeader', restMenu.layout)
        dateHeader.props.text = calendar.formatGameTime(getDateStr())
        restMenu:update()
    end, 60, { initialDelay = 0, type = time.GameTime })
end

function RestMenu.updateSleepInfo(sleepInfo)
  local sleepInfoBox = RestMenu.getElementByName('sleepInfoBox', I.s3ChimSleep.Menu.layout)
  local newString = ''

  if sleepInfo.sleeping then
    if sleepInfo.sleepingOnGround then
      newString = RestMenu.userData.RestOnGroundString
    elseif sleepInfo.fromBedroll then
      if sleepInfo.isOutside then
        newString = RestMenu.userData.OutsideBedString
      else
        newString = RestMenu.userData.BedrollString
      end
    elseif sleepInfo.fromOwnedBed then
      newString = RestMenu.userData.OwnedBedString
    else
      newString = RestMenu.userData.BedString
    end
  else
    newString = RestMenu.userData.WaitString
  end

  if not sleepInfoBox.props.visible then
    sleepInfoBox.props.visible = true
    sleepInfoBox.props.relativeSize = RestMenu.userData.sleepInfoSize
  end

  sleepInfoBox.props.text = newString
end

--- Returns a text element describing
--- whether you can sleep and the quality of your sleep
--- @return ui.TYPE.Text
function RestMenu.SleepInfoString()
  local sleepInfo = RestMenu.TextBox(RestMenu.userData.RestString)
  sleepInfo.props.relativeSize = util.vector2(.8, .15)
  sleepInfo.props.multipline = true
  sleepInfo.props.wordWrap = true
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
  textAnswer = RestMenu.colorFromGMST('fontcolor_color_answer'),
  textAnswerOver = RestMenu.colorFromGMST('fontcolor_color_answer_over'),
  textAnswerPressed = RestMenu.colorFromGMST('fontcolor_color_answer_pressed'),
  highlightNormal = RestMenu.colorFromGMST('fontcolor_color_big_normal'),
  highlightOver = RestMenu.colorFromGMST('fontcolor_color_big_normal_over'),
  highlightPressed = RestMenu.colorFromGMST('fontcolor_color_big_normal_pressed'),
  journalNormal = RestMenu.colorFromGMST('FontColor_color_journal_link'),
  journalOver = RestMenu.colorFromGMST('FontColor_color_journal_link_over'),
  journalPressed = RestMenu.colorFromGMST('FontColor_color_journal_link_pressed'),
}

local function updateButtonHighlight(highlightData)
  local layout = highlightData.layout
  local state = highlightData.state
  local colors = RestMenu.userData.colors

  if state == HighlightStates.DARK then
    layout.props.textColor = colors.textAnswer
    layout.props.textSize = constants.textHeaderSize - 1
  elseif state == HighlightStates.MEDIUM then
    layout.props.textColor = colors.textNormalOver
    layout.props.textSize = constants.textHeaderSize + 2
  elseif state == HighlightStates.NORMAL then
    layout.props.textColor = colors.textNormal
    layout.props.textSize = constants.textHeaderSize
  end

  if not highlightData.update then return end

  I.s3ChimSleep.Menu:update()
end

local function updateArrowHighlight(highlightData)
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

  if not highlightData.update then return end

  I.s3ChimSleep.Menu:update()
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

function RestMenu.updateLocalActorStats()
  RestMenu.userData.nearbyActorStats = {}
  for _, actor in pairs(nearby.actors) do
    RestMenu.userData.nearbyActorStats[actor.id] = s3lf.From(actor).health.current
    I.s3ChimSleep.Manager.debugLog('Added actor', actor.id, 'to nearbyActorStats')
  end
end

function RestMenu.refreshMenuState(newState)
  local sleepMenu = I.s3ChimSleep.Menu

  RestMenu.updateLocalActorStats()

  RestMenu.updateSleepInfo {
    fromBedroll = newState.fromBedroll,
    fromOwnedBed = newState.fromOwnedBed,
    isOutside = newState.isOutside,
    sleeping = newState.restOrWait,
    sleepingOnGround = newState.sleepingOnGround,
  }

  RestMenu.updateHoursToHeal {
    needsToHeal = s3lf.health.current < s3lf.health.base,
    sleepMultiplier = newState.sleepMultiplier,
    restOrWait = newState.restOrWait,
  }

  RestMenu.unhighlightAllButtons()

  local waitButton = RestMenu.getElementByName('waitButton', sleepMenu.layout)

  waitButton.props.text = newState.restOrWait and 'Sleep' or 'Wait'

  sleepMenu:update()
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
        updateArrowHighlight {
          state = HighlightStates.DARK,
          layout = layout,
        }
        if RestMenu.timeStopFn then RestMenu.timeStopFn() end
        RestMenu.timeStopFn = time.runRepeatedly(function()
            if not I.s3ChimSleep.Menu.layout.props.visible then RestMenu.timeStopFn() return end
            updateTime(left)
        end
          , .2
          , { initialDelay = 0 })
      end),
      mouseRelease = async:callback(function(_, layout)
        updateArrowHighlight {
          state = HighlightStates.MEDIUM,
          layout = layout,
          update = true,
        }
        ambient.playSoundFile(RestMenu.userData.clickSound)
        if RestMenu.timeStopFn then RestMenu.timeStopFn() end
      end),
      focusGain = async:callback(function(_, layout)
          updateArrowHighlight {
            state = HighlightStates.MEDIUM,
            layout = layout,
            update = true,
          }
      end),
      focusLoss = async:callback(function(_, layout)
        updateArrowHighlight {
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
          text = '1',
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
    },
    userData = {
      isFocused = false,
    },
  }
end

function RestMenu.updateHoursToHeal(healData)
  local menu = I.s3ChimSleep.Menu.layout
  if not menu.props.visible then return end

  local hoursToHeal = RestMenu.getElementByName('totalHoursToHeal', menu)
  local sleepInfoBox = RestMenu.getElementByName('sleepInfoBox', menu)
  local sleepTimeSelectionBox = RestMenu.getElementByName('sleepTimeSelection', menu)
  local untilHealedButton = RestMenu.getElementByName('untilHealedButton', menu)

  if not healData.needsToHeal then
    hoursToHeal.props.text = sleepInfoBox.props.text
    sleepInfoBox.props.visible = false
    sleepInfoBox.props.relativeSize = util.vector2(0, 0)
    sleepTimeSelectionBox.text = '1'
  elseif not healData.restOrWait then
    hoursToHeal.props.text = RestMenu.userData.WaitNoHealString
  else
    local healthPerHour = I.s3ChimDynamic.Manager.getSleepHealthRegenBase()
    local multiplier = healData.sleepMultiplier
    local healthToRecover = s3lf.health.base - s3lf.health.current

    local numHoursToHeal = healthToRecover / (healthPerHour * multiplier)
    numHoursToHeal = math.max(1, math.floor(numHoursToHeal + .5))
    numHoursToHeal = tostring(numHoursToHeal)

    hoursToHeal.props.text = RestMenu.userData.HoursToHealString:format(numHoursToHeal)
    sleepTimeSelectionBox.props.text = numHoursToHeal

    I.s3ChimSleep.Manager.debugLog('Hours to heal:', numHoursToHeal, 'Health per hour:', healthPerHour
                                   , 'Multiplier:', multiplier, 'Health to recover:', healthToRecover)
  end

  untilHealedButton.props.visible = healData.needsToHeal and healData.restOrWait
end

--- Returns a text element
--- describing how long it will take to heal via sleeping
--- @return ui.TYPE.Text
function RestMenu.HoursToHeal()
  local hoursToHeal = RestMenu.TextBox('')
  hoursToHeal.props.multiline = true
  hoursToHeal.props.wordWrap = true
  hoursToHeal.props.relativeSize = util.vector2(.75, .2)
  hoursToHeal.name = 'totalHoursToHeal'
  return hoursToHeal
end

local buttonHighlightEnter = async:callback(function(_, layout)
    if layout.userData.isFocused then return end

    updateButtonHighlight {
      state = HighlightStates.MEDIUM,
      layout = layout,
      update = true,
    }
    layout.userData.isFocused = true
end)

local buttonHighlightExit = async:callback(function(_, layout)
    if not layout.userData.isFocused then return end

    updateButtonHighlight {
      state = HighlightStates.NORMAL,
      layout = layout,
      update = true,
    }
    layout.userData.isFocused = false
end)

local function cancelEvent(clicked, layout)
    if clicked then
        updateButtonHighlight {
            state = HighlightStates.DARK,
            layout = layout,
            update = true,
        }
        layout.userData.isFocused = false
    else
        ambient.playSoundFile(RestMenu.userData.clickSound)
        I.UI.setMode()
    end
end

function RestMenu.unhighlightAllButtons()
  local layout = I.s3ChimSleep.Menu.layout
  for _, element in pairs({ 'waitButton', 'untilHealedButton', 'cancelButton' }) do
    local button = RestMenu.getElementByName(element, layout)
    button.userData.isFocused = false
    updateButtonHighlight {
      state = HighlightStates.NORMAL,
      layout = button,
    }
  end
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
  cancelButton.name = 'cancelButton'
  untilHealedButton.name = 'untilHealedButton'
  waitButton.name = 'waitButton'

  local events = {
    focusGain = buttonHighlightEnter,
    focusLoss = buttonHighlightExit,
  }

  cancelButton.events = {
    focusGain = buttonHighlightEnter,
    focusLoss = buttonHighlightExit,
    mousePress = async:callback(function(_, layout)
        cancelEvent(true, layout)
    end),
    mouseRelease = async:callback(function(_, layout)
        cancelEvent(false, layout)
    end),
  }

  waitButton.events = events
  untilHealedButton.events = events

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
    },
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
